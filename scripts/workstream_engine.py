#!/usr/bin/env python3
"""Workstream engine for deterministic ticket lifecycle management.

Manages workstream state in .claude/workstreams/status.json.

Usage:
    workstream_engine.py create <source_file>                    Parse PRD/plan and create tickets
    workstream_engine.py status                                  Print ticket status table
    workstream_engine.py next                                    Return next unblocked ticket
    workstream_engine.py depends <ticket_id> <depends_on_id>     Add dependency between tickets
    workstream_engine.py update <ticket_id> <status>             Update ticket status

Exit codes: 0 success, 1 no tickets available, 2 error
"""

import argparse
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

STATUS_DIR = Path(".claude/workstreams")
STATUS_FILE = STATUS_DIR / "status.json"
VALID_STATUSES = ("pending", "in_progress", "done", "blocked")
PRIORITY_ORDER = {"critical": 0, "high": 1, "medium": 2, "low": 3}


def timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_status() -> dict[str, Any]:
    if STATUS_FILE.exists():
        return json.loads(STATUS_FILE.read_text())
    return {"version": "1.0", "created": timestamp(), "project": "",
            "workstreams": {}, "tickets": {}, "phases": {},
            "critical_path": [], "dependency_graph": {}}


def save_status(data: dict[str, Any]) -> None:
    STATUS_DIR.mkdir(parents=True, exist_ok=True)
    tmp = STATUS_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, indent=2) + "\n")
    tmp.rename(STATUS_FILE)


def detect_cycle(graph: dict[str, list[str]]) -> list[str] | None:
    """Return cycle path if one exists, else None."""
    WHITE, GRAY, BLACK = 0, 1, 2
    color: dict[str, int] = {n: WHITE for n in graph}
    parent: dict[str, str | None] = {n: None for n in graph}

    def dfs(node: str) -> list[str] | None:
        color[node] = GRAY
        for dep in graph.get(node, []):
            if dep not in color:
                continue
            if color[dep] == GRAY:
                cycle = [dep, node]
                cur = node
                while cur != dep:
                    cur = parent[cur]  # type: ignore[assignment]
                    if cur is None:
                        break
                    cycle.append(cur)
                cycle.reverse()
                return cycle
            if color[dep] == WHITE:
                parent[dep] = node
                result = dfs(dep)
                if result is not None:
                    return result
        color[node] = BLACK
        return None

    for node in graph:
        if color[node] == WHITE:
            result = dfs(node)
            if result is not None:
                return result
    return None


def compute_depth(graph: dict[str, list[str]]) -> dict[str, int]:
    """Dependency depth per ticket. Depth 0 = no dependencies."""
    depth: dict[str, int] = {}
    def get(node: str) -> int:
        if node in depth:
            return depth[node]
        deps = [d for d in graph.get(node, []) if d in graph]
        depth[node] = 0 if not deps else 1 + max(get(d) for d in deps)
        return depth[node]
    for node in graph:
        get(node)
    return depth


def compute_phases(graph: dict[str, list[str]]) -> dict[str, list[str]]:
    depths = compute_depth(graph)
    phases: dict[int, list[str]] = defaultdict(list)
    for ticket, d in depths.items():
        phases[d].append(ticket)
    return {str(k + 1): sorted(v) for k, v in sorted(phases.items())}


def parse_source_file(path: Path) -> list[dict[str, Any]]:
    """Extract tickets from a PRD/plan markdown file."""
    content = path.read_text()
    tickets: list[dict[str, Any]] = []
    # Pattern: ## PROJ-101: Summary
    matches = list(re.finditer(r"^#{2,3}\s+([A-Z]+-\d+)[:\s]+(.+)$", content, re.MULTILINE))
    if matches:
        for i, m in enumerate(matches):
            end = matches[i + 1].start() if i + 1 < len(matches) else len(content)
            body = content[m.end():end]
            pri = re.search(r"priority:\s*(critical|high|medium|low)", body, re.I)
            dep = re.search(r"blocked_by:\s*\[([^\]]*)\]", body)
            area = re.search(r"area:\s*(\w+)", body, re.I)
            blocked = [b.strip().strip("'\"") for b in dep.group(1).split(",") if b.strip()] if dep else []
            tickets.append({"id": m.group(1), "summary": m.group(2).strip(),
                            "area": area.group(1) if area else "",
                            "priority": pri.group(1).lower() if pri else "medium",
                            "blocked_by": blocked, "blocks": []})
    else:
        # Fallback: treat each H2 as a ticket
        skip = {"overview", "introduction", "summary", "references", "appendix", "changelog", "table of contents"}
        prefix = path.stem.upper()[:4]
        for i, m in enumerate(re.finditer(r"^##\s+(.+)$", content, re.MULTILINE)):
            if m.group(1).strip().lower() in skip:
                continue
            tickets.append({"id": f"{prefix}-{(i + 1) * 100 + 1}", "summary": m.group(1).strip(),
                            "area": "", "priority": "medium", "blocked_by": [], "blocks": []})
    return tickets


def cmd_create(source_file: str) -> int:
    path = Path(source_file)
    if not path.is_file():
        print(f"Error: Source file not found: {source_file}", file=sys.stderr)
        return 2
    tickets = parse_source_file(path)
    if not tickets:
        print(f"Error: No tickets found in {source_file}", file=sys.stderr)
        return 2
    ids = [t["id"] for t in tickets]
    dupes = set(tid for tid in ids if ids.count(tid) > 1)
    if dupes:
        print(f"Error: Duplicate ticket IDs: {', '.join(dupes)}", file=sys.stderr)
        return 2

    data = load_status()
    data["created"] = timestamp()
    graph: dict[str, list[str]] = {}
    for t in tickets:
        graph[t["id"]] = t["blocked_by"]
        data["tickets"][t["id"]] = {
            "summary": t["summary"], "area": t["area"], "workstream": "",
            "phase": 1, "depth": 0, "status": "pending", "priority": t["priority"],
            "blocked_by": t["blocked_by"], "blocks": t["blocks"],
            "plan_status": "none", "build_status": "none",
            "pr_number": None, "pr_status": None, "retry_count": 0}

    cycle = detect_cycle(graph)
    if cycle:
        print(f"Error: Dependency cycle detected: {' -> '.join(cycle)}", file=sys.stderr)
        return 2
    # Compute reverse deps, depths, phases
    for tid, deps in graph.items():
        for dep in deps:
            if dep in data["tickets"] and tid not in data["tickets"][dep]["blocks"]:
                data["tickets"][dep]["blocks"].append(tid)
    depths = compute_depth(graph)
    for tid, d in depths.items():
        if tid in data["tickets"]:
            data["tickets"][tid]["depth"] = d
            data["tickets"][tid]["phase"] = d + 1
    data["dependency_graph"] = dict(graph)
    data["phases"] = compute_phases(graph)
    save_status(data)

    print(f"Created {len(tickets)} tickets from {source_file}")
    for t in tickets:
        dep_str = f" (blocked by: {', '.join(t['blocked_by'])})" if t["blocked_by"] else ""
        print(f"  {t['id']}: {t['summary']}{dep_str}")
    return 0


def cmd_status() -> int:
    if not STATUS_FILE.exists():
        print("No workstream state found. Run 'create' first.", file=sys.stderr)
        return 1
    data = load_status()
    tickets = data.get("tickets", {})
    if not tickets:
        print("No tickets tracked.")
        return 1

    by_phase: dict[int, list[tuple[str, dict]]] = defaultdict(list)
    for tid, info in tickets.items():
        by_phase[info.get("phase", 1)].append((tid, info))

    print("Workstream Status")
    print("=" * 70)
    for p in sorted(by_phase):
        print(f"\nPhase {p}")
        print(f"  {'Ticket':<14} {'Summary':<30} {'Status':<12} {'Build':<10} {'Blocked By'}")
        for tid, info in sorted(by_phase[p]):
            print(f"  {tid:<14} {info.get('summary','')[:28]:<30} {info.get('status','pending'):<12} "
                  f"{info.get('build_status','none'):<10} {', '.join(info.get('blocked_by',[])) or '--'}")

    total = len(tickets)
    done = sum(1 for t in tickets.values() if t.get("status") == "done")
    prog = sum(1 for t in tickets.values() if t.get("status") == "in_progress")
    print(f"\nSummary: {total} tickets | {done} done | {prog} in-progress | {total - done - prog} pending")
    crit = data.get("critical_path", [])
    if crit:
        print(f"Critical path: {' -> '.join(crit)}")
    return 0


def cmd_next() -> int:
    if not STATUS_FILE.exists():
        print("No workstream state found. Run 'create' first.", file=sys.stderr)
        return 1
    tickets = load_status().get("tickets", {})
    if not tickets:
        print("No tickets available.", file=sys.stderr)
        return 1

    candidates = []
    for tid, info in tickets.items():
        if info.get("status") != "pending":
            continue
        if all(tickets.get(d, {}).get("status") == "done" for d in info.get("blocked_by", [])):
            candidates.append((tid, info))
    if not candidates:
        print("No unblocked tickets available.", file=sys.stderr)
        return 1

    candidates.sort(key=lambda x: (PRIORITY_ORDER.get(x[1].get("priority", "medium"), 2),
                                    x[1].get("phase", 999), x[0]))
    tid, info = candidates[0]
    print(json.dumps({"ticket": tid, "summary": info.get("summary", ""),
                       "priority": info.get("priority", "medium"),
                       "phase": info.get("phase", 1),
                       "blocked_by": info.get("blocked_by", [])}, indent=2))
    return 0


def cmd_depends(ticket_id: str, depends_on_id: str) -> int:
    if not STATUS_FILE.exists():
        print("No workstream state found. Run 'create' first.", file=sys.stderr)
        return 2
    data = load_status()
    tickets = data.get("tickets", {})

    for tid in (ticket_id, depends_on_id):
        if tid not in tickets:
            print(f"Error: Ticket not found: {tid}", file=sys.stderr)
            return 2
    if ticket_id == depends_on_id:
        print(f"Error: A ticket cannot depend on itself: {ticket_id}", file=sys.stderr)
        return 2

    blocked_by = tickets[ticket_id].get("blocked_by", [])
    if depends_on_id in blocked_by:
        print(f"Dependency already exists: {ticket_id} blocked by {depends_on_id}")
        return 0

    blocked_by.append(depends_on_id)
    tickets[ticket_id]["blocked_by"] = blocked_by
    blocks = tickets[depends_on_id].get("blocks", [])
    if ticket_id not in blocks:
        blocks.append(ticket_id)
        tickets[depends_on_id]["blocks"] = blocks

    graph = data.get("dependency_graph", {})
    graph[ticket_id] = blocked_by
    data["dependency_graph"] = graph

    cycle = detect_cycle(graph)
    if cycle:
        blocked_by.remove(depends_on_id)
        if ticket_id in blocks:
            blocks.remove(ticket_id)
        graph[ticket_id] = blocked_by
        print(f"Error: Would create cycle: {' -> '.join(cycle)}", file=sys.stderr)
        return 2

    depths = compute_depth(graph)
    for tid, d in depths.items():
        if tid in tickets:
            tickets[tid]["depth"] = d
            tickets[tid]["phase"] = d + 1
    data["phases"] = compute_phases(graph)
    save_status(data)
    print(f"Added dependency: {ticket_id} blocked by {depends_on_id}")
    return 0


def cmd_update(ticket_id: str, status: str) -> int:
    if status not in VALID_STATUSES:
        print(f"Error: Invalid status '{status}'. Valid: {', '.join(VALID_STATUSES)}", file=sys.stderr)
        return 2
    if not STATUS_FILE.exists():
        print("No workstream state found. Run 'create' first.", file=sys.stderr)
        return 2
    data = load_status()
    tickets = data.get("tickets", {})
    if ticket_id not in tickets:
        print(f"Error: Ticket not found: {ticket_id}", file=sys.stderr)
        return 2
    old = tickets[ticket_id].get("status", "pending")
    tickets[ticket_id]["status"] = status
    save_status(data)
    print(f"Updated {ticket_id}: {old} -> {status}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Workstream engine: deterministic ticket lifecycle management",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Exit codes: 0 success, 1 no tickets, 2 error")
    parser.add_argument("subcommand", choices=["create", "status", "next", "depends", "update"])
    parser.add_argument("args", nargs="*")
    args = parser.parse_args()

    if args.subcommand == "create":
        if len(args.args) != 1:
            print("Error: create requires exactly one source file", file=sys.stderr)
            return 2
        return cmd_create(args.args[0])
    if args.subcommand == "status":
        return cmd_status()
    if args.subcommand == "next":
        return cmd_next()
    if args.subcommand == "depends":
        if len(args.args) != 2:
            print("Error: depends requires <ticket_id> <depends_on_id>", file=sys.stderr)
            return 2
        return cmd_depends(args.args[0], args.args[1])
    if args.subcommand == "update":
        if len(args.args) != 2:
            print("Error: update requires <ticket_id> <status>", file=sys.stderr)
            return 2
        return cmd_update(args.args[0], args.args[1])
    return 2


if __name__ == "__main__":
    sys.exit(main())
