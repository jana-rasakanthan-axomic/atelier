#!/usr/bin/env python3
"""
Coverage Analysis Script

Parses pytest coverage reports and identifies gaps.

Usage:
    python analyze-coverage.py coverage.json --threshold 80
    python analyze-coverage.py coverage.json --output report.json
    python analyze-coverage.py coverage.json --priority-only
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def load_coverage_report(path: str) -> dict[str, Any]:
    """Load coverage.json from pytest-cov."""
    with open(path) as f:
        return json.load(f)


def calculate_overall_coverage(report: dict[str, Any]) -> float:
    """Calculate overall coverage percentage."""
    totals = report.get("totals", {})
    covered = totals.get("covered_lines", 0)
    total = totals.get("num_statements", 1)
    return round((covered / total) * 100, 2)


def get_uncovered_lines(report: dict[str, Any]) -> dict[str, list[int]]:
    """Extract uncovered lines per file."""
    files = report.get("files", {})
    uncovered = {}

    for file_path, data in files.items():
        missing = data.get("missing_lines", [])
        if missing:
            uncovered[file_path] = missing

    return uncovered


def prioritize_gaps(
    uncovered: dict[str, list[int]],
    priority_patterns: dict[str, str] | None = None
) -> list[dict[str, Any]]:
    """
    Prioritize coverage gaps by importance.

    Default priorities:
    - P0: Error handling, authentication, critical paths
    - P1: Business logic, services
    - P2: Utilities, helpers
    - P3: Configuration, constants
    """
    if priority_patterns is None:
        priority_patterns = {
            "P0": ["error", "auth", "security", "exception"],
            "P1": ["service", "repository", "handler"],
            "P2": ["util", "helper", "route"],
            "P3": ["config", "constant", "model"],
        }

    gaps = []

    for file_path, lines in uncovered.items():
        file_lower = file_path.lower()

        # Determine priority
        priority = "P2"  # Default
        for p, patterns in priority_patterns.items():
            if any(pattern in file_lower for pattern in patterns):
                priority = p
                break

        gaps.append({
            "file": file_path,
            "lines": lines,
            "line_count": len(lines),
            "priority": priority,
        })

    # Sort by priority then by line count
    priority_order = {"P0": 0, "P1": 1, "P2": 2, "P3": 3}
    gaps.sort(key=lambda x: (priority_order[x["priority"]], -x["line_count"]))

    return gaps


def get_coverage_by_directory(report: dict[str, Any]) -> dict[str, float]:
    """Calculate coverage percentage per directory."""
    files = report.get("files", {})
    dir_stats: dict[str, dict[str, int]] = {}

    for file_path, data in files.items():
        # Get directory (use first two levels)
        parts = Path(file_path).parts
        if len(parts) >= 2:
            directory = str(Path(parts[0]) / parts[1])
        else:
            directory = parts[0] if parts else "root"

        if directory not in dir_stats:
            dir_stats[directory] = {"covered": 0, "total": 0}

        dir_stats[directory]["covered"] += data.get("covered_lines", 0)
        dir_stats[directory]["total"] += data.get("num_statements", 0)

    coverage_by_dir = {}
    for directory, stats in dir_stats.items():
        if stats["total"] > 0:
            coverage_by_dir[directory] = round(
                (stats["covered"] / stats["total"]) * 100, 2
            )

    return dict(sorted(coverage_by_dir.items(), key=lambda x: x[1]))


def generate_report(
    report: dict[str, Any],
    threshold: float = 80.0
) -> dict[str, Any]:
    """Generate comprehensive coverage analysis report."""
    overall = calculate_overall_coverage(report)
    uncovered = get_uncovered_lines(report)
    gaps = prioritize_gaps(uncovered)
    by_directory = get_coverage_by_directory(report)

    status = "PASS" if overall >= threshold else "FAIL"

    # Count by priority
    priority_counts = {"P0": 0, "P1": 0, "P2": 0, "P3": 0}
    for gap in gaps:
        priority_counts[gap["priority"]] += 1

    return {
        "overall_coverage": overall,
        "target": threshold,
        "status": status,
        "priority_counts": priority_counts,
        "by_directory": by_directory,
        "gaps": gaps,
        "summary": {
            "total_files_with_gaps": len(gaps),
            "total_uncovered_lines": sum(g["line_count"] for g in gaps),
            "critical_gaps": priority_counts["P0"],
            "high_priority_gaps": priority_counts["P1"],
        }
    }


def print_report(analysis: dict[str, Any], verbose: bool = False) -> None:
    """Print coverage analysis to console."""
    print("=" * 60)
    print("COVERAGE ANALYSIS REPORT")
    print("=" * 60)

    # Overall status
    status_emoji = "✅" if analysis["status"] == "PASS" else "❌"
    print(f"\nOverall Coverage: {analysis['overall_coverage']}%")
    print(f"Target: {analysis['target']}%")
    print(f"Status: {status_emoji} {analysis['status']}")

    # Summary
    summary = analysis["summary"]
    print(f"\nGap Summary:")
    print(f"  Files with gaps: {summary['total_files_with_gaps']}")
    print(f"  Uncovered lines: {summary['total_uncovered_lines']}")
    print(f"  Critical (P0): {summary['critical_gaps']}")
    print(f"  High (P1): {summary['high_priority_gaps']}")

    # Coverage by directory
    print("\nCoverage by Directory:")
    for directory, coverage in analysis["by_directory"].items():
        indicator = "✅" if coverage >= analysis["target"] else "⚠️"
        print(f"  {indicator} {directory}: {coverage}%")

    # Priority gaps
    if analysis["gaps"]:
        print("\nPriority Gaps:")
        for priority in ["P0", "P1", "P2", "P3"]:
            priority_gaps = [g for g in analysis["gaps"] if g["priority"] == priority]
            if priority_gaps:
                print(f"\n  {priority} ({len(priority_gaps)} files):")
                for gap in priority_gaps[:5]:  # Show top 5 per priority
                    print(f"    - {gap['file']} ({gap['line_count']} lines)")
                if len(priority_gaps) > 5:
                    print(f"    ... and {len(priority_gaps) - 5} more")

    print("\n" + "=" * 60)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Analyze pytest coverage report"
    )
    parser.add_argument(
        "coverage_file",
        help="Path to coverage.json"
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=80.0,
        help="Coverage threshold percentage (default: 80)"
    )
    parser.add_argument(
        "--output",
        help="Output JSON report to file"
    )
    parser.add_argument(
        "--priority-only",
        action="store_true",
        help="Only show P0 and P1 gaps"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show detailed output"
    )

    args = parser.parse_args()

    # Check file exists
    if not Path(args.coverage_file).exists():
        print(f"Error: Coverage file not found: {args.coverage_file}")
        print("\nGenerate with: pytest --cov=src --cov-report=json")
        return 1

    try:
        report = load_coverage_report(args.coverage_file)
        analysis = generate_report(report, args.threshold)

        if args.priority_only:
            analysis["gaps"] = [
                g for g in analysis["gaps"]
                if g["priority"] in ["P0", "P1"]
            ]

        if args.output:
            with open(args.output, "w") as f:
                json.dump(analysis, f, indent=2)
            print(f"Report saved to: {args.output}")

        print_report(analysis, args.verbose)

        # Exit with error if below threshold
        return 0 if analysis["status"] == "PASS" else 1

    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in coverage file: {e}")
        return 1
    except KeyError as e:
        print(f"Error: Missing expected key in coverage report: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
