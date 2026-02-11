#!/usr/bin/env python3
"""
Code Audit Script

Analyzes code for complexity, maintainability, and tech debt.

Usage:
    python code-audit.py src/
    python code-audit.py src/ --threshold 10
    python code-audit.py src/ --output audit-report.json
"""

import argparse
import ast
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class FunctionMetrics:
    """Metrics for a single function."""
    name: str
    file: str
    line: int
    lines_of_code: int = 0
    cyclomatic_complexity: int = 1
    parameters: int = 0
    nesting_depth: int = 0
    cognitive_complexity: int = 0


@dataclass
class FileMetrics:
    """Metrics for a single file."""
    path: str
    lines_of_code: int = 0
    functions: int = 0
    classes: int = 0
    imports: int = 0
    avg_complexity: float = 0.0
    max_complexity: int = 0
    issues: list[dict[str, Any]] = field(default_factory=list)


class ComplexityVisitor(ast.NodeVisitor):
    """AST visitor to calculate code complexity metrics."""

    def __init__(self, file_path: str):
        self.file_path = file_path
        self.functions: list[FunctionMetrics] = []
        self.current_function: FunctionMetrics | None = None
        self.nesting_level = 0

    def visit_FunctionDef(self, node: ast.FunctionDef) -> None:
        self._analyze_function(node)

    def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef) -> None:
        self._analyze_function(node)

    def _analyze_function(
        self,
        node: ast.FunctionDef | ast.AsyncFunctionDef
    ) -> None:
        metrics = FunctionMetrics(
            name=node.name,
            file=self.file_path,
            line=node.lineno,
            parameters=len(node.args.args),
        )

        # Calculate lines of code
        if node.end_lineno:
            metrics.lines_of_code = node.end_lineno - node.lineno + 1

        # Calculate cyclomatic complexity
        metrics.cyclomatic_complexity = self._calculate_complexity(node)

        # Calculate nesting depth
        metrics.nesting_depth = self._calculate_nesting(node)

        self.functions.append(metrics)
        self.generic_visit(node)

    def _calculate_complexity(self, node: ast.AST) -> int:
        """Calculate cyclomatic complexity."""
        complexity = 1  # Base complexity

        for child in ast.walk(node):
            # Decision points add complexity
            if isinstance(child, (ast.If, ast.While, ast.For, ast.AsyncFor)):
                complexity += 1
            elif isinstance(child, ast.ExceptHandler):
                complexity += 1
            elif isinstance(child, (ast.And, ast.Or)):
                complexity += 1
            elif isinstance(child, ast.comprehension):
                complexity += 1
                if child.ifs:
                    complexity += len(child.ifs)
            elif isinstance(child, ast.Assert):
                complexity += 1
            elif isinstance(child, ast.IfExp):  # Ternary
                complexity += 1

        return complexity

    def _calculate_nesting(self, node: ast.AST) -> int:
        """Calculate maximum nesting depth."""
        max_depth = 0

        def _walk(n: ast.AST, depth: int) -> None:
            nonlocal max_depth
            max_depth = max(max_depth, depth)

            for child in ast.iter_child_nodes(n):
                if isinstance(child, (ast.If, ast.While, ast.For,
                                     ast.AsyncFor, ast.With, ast.AsyncWith,
                                     ast.Try)):
                    _walk(child, depth + 1)
                else:
                    _walk(child, depth)

        _walk(node, 0)
        return max_depth


def analyze_file(file_path: Path) -> FileMetrics | None:
    """Analyze a single Python file."""
    try:
        content = file_path.read_text()
        tree = ast.parse(content)
    except SyntaxError:
        return None
    except Exception:
        return None

    metrics = FileMetrics(path=str(file_path))
    metrics.lines_of_code = len(content.splitlines())

    # Count top-level items
    for node in ast.iter_child_nodes(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            metrics.functions += 1
        elif isinstance(node, ast.ClassDef):
            metrics.classes += 1
        elif isinstance(node, (ast.Import, ast.ImportFrom)):
            metrics.imports += 1

    # Analyze functions
    visitor = ComplexityVisitor(str(file_path))
    visitor.visit(tree)

    if visitor.functions:
        complexities = [f.cyclomatic_complexity for f in visitor.functions]
        metrics.avg_complexity = sum(complexities) / len(complexities)
        metrics.max_complexity = max(complexities)

    # Identify issues
    for func in visitor.functions:
        if func.cyclomatic_complexity > 10:
            metrics.issues.append({
                "type": "high_complexity",
                "function": func.name,
                "line": func.line,
                "value": func.cyclomatic_complexity,
                "threshold": 10,
                "severity": "high" if func.cyclomatic_complexity > 15 else "medium"
            })

        if func.lines_of_code > 50:
            metrics.issues.append({
                "type": "long_function",
                "function": func.name,
                "line": func.line,
                "value": func.lines_of_code,
                "threshold": 50,
                "severity": "high" if func.lines_of_code > 100 else "medium"
            })

        if func.parameters > 5:
            metrics.issues.append({
                "type": "too_many_parameters",
                "function": func.name,
                "line": func.line,
                "value": func.parameters,
                "threshold": 5,
                "severity": "medium"
            })

        if func.nesting_depth > 3:
            metrics.issues.append({
                "type": "deep_nesting",
                "function": func.name,
                "line": func.line,
                "value": func.nesting_depth,
                "threshold": 3,
                "severity": "medium"
            })

    if metrics.lines_of_code > 500:
        metrics.issues.append({
            "type": "long_file",
            "line": 1,
            "value": metrics.lines_of_code,
            "threshold": 500,
            "severity": "medium"
        })

    return metrics


def analyze_directory(
    directory: Path,
    exclude_patterns: list[str] | None = None
) -> list[FileMetrics]:
    """Analyze all Python files in directory."""
    if exclude_patterns is None:
        exclude_patterns = ["test_", "_test.py", "conftest.py", "__pycache__"]

    results = []

    for py_file in directory.rglob("*.py"):
        # Skip excluded patterns
        if any(p in str(py_file) for p in exclude_patterns):
            continue

        metrics = analyze_file(py_file)
        if metrics:
            results.append(metrics)

    return results


def generate_report(
    metrics: list[FileMetrics],
    complexity_threshold: int = 10
) -> dict[str, Any]:
    """Generate comprehensive audit report."""
    total_loc = sum(m.lines_of_code for m in metrics)
    total_functions = sum(m.functions for m in metrics)
    total_classes = sum(m.classes for m in metrics)

    all_issues = []
    for m in metrics:
        for issue in m.issues:
            issue["file"] = m.path
            all_issues.append(issue)

    # Sort issues by severity
    severity_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
    all_issues.sort(key=lambda x: severity_order.get(x.get("severity", "low"), 3))

    # Count by type
    issue_types: dict[str, int] = {}
    for issue in all_issues:
        t = issue["type"]
        issue_types[t] = issue_types.get(t, 0) + 1

    # Find most complex files
    complex_files = sorted(
        metrics,
        key=lambda m: m.max_complexity,
        reverse=True
    )[:10]

    return {
        "summary": {
            "total_files": len(metrics),
            "total_lines_of_code": total_loc,
            "total_functions": total_functions,
            "total_classes": total_classes,
            "total_issues": len(all_issues),
            "issues_by_severity": {
                "high": len([i for i in all_issues if i.get("severity") == "high"]),
                "medium": len([i for i in all_issues if i.get("severity") == "medium"]),
                "low": len([i for i in all_issues if i.get("severity") == "low"]),
            }
        },
        "issue_types": issue_types,
        "issues": all_issues,
        "complex_files": [
            {
                "file": f.path,
                "max_complexity": f.max_complexity,
                "avg_complexity": round(f.avg_complexity, 2),
                "lines": f.lines_of_code,
            }
            for f in complex_files
        ],
        "thresholds": {
            "complexity": complexity_threshold,
            "function_lines": 50,
            "file_lines": 500,
            "parameters": 5,
            "nesting": 3,
        }
    }


def print_report(report: dict[str, Any]) -> None:
    """Print audit report to console."""
    print("=" * 60)
    print("CODE AUDIT REPORT")
    print("=" * 60)

    summary = report["summary"]
    print(f"\nProject Summary:")
    print(f"  Files: {summary['total_files']}")
    print(f"  Lines of Code: {summary['total_lines_of_code']}")
    print(f"  Functions: {summary['total_functions']}")
    print(f"  Classes: {summary['total_classes']}")

    print(f"\nIssues Found: {summary['total_issues']}")
    by_severity = summary["issues_by_severity"]
    print(f"  High: {by_severity['high']}")
    print(f"  Medium: {by_severity['medium']}")
    print(f"  Low: {by_severity['low']}")

    if report["issue_types"]:
        print("\nIssues by Type:")
        for issue_type, count in report["issue_types"].items():
            print(f"  {issue_type}: {count}")

    if report["complex_files"]:
        print("\nMost Complex Files:")
        for f in report["complex_files"][:5]:
            print(f"  {f['file']}: complexity={f['max_complexity']}, "
                  f"lines={f['lines']}")

    if report["issues"]:
        print("\nTop Issues to Address:")
        for issue in report["issues"][:10]:
            severity = issue.get("severity", "medium").upper()
            file_path = issue.get("file", "unknown")
            line = issue.get("line", 0)
            issue_type = issue["type"]
            value = issue.get("value", "")
            threshold = issue.get("threshold", "")
            print(f"  [{severity}] {file_path}:{line} - {issue_type} "
                  f"(value: {value}, threshold: {threshold})")

    print("\n" + "=" * 60)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit Python code for complexity and maintainability"
    )
    parser.add_argument(
        "directory",
        help="Directory to analyze"
    )
    parser.add_argument(
        "--threshold",
        type=int,
        default=10,
        help="Complexity threshold (default: 10)"
    )
    parser.add_argument(
        "--output",
        help="Output JSON report to file"
    )
    parser.add_argument(
        "--exclude",
        nargs="+",
        default=["test_", "_test.py", "conftest.py", "__pycache__"],
        help="Patterns to exclude"
    )

    args = parser.parse_args()

    directory = Path(args.directory)
    if not directory.exists():
        print(f"Error: Directory not found: {directory}")
        return 1

    if not directory.is_dir():
        print(f"Error: Not a directory: {directory}")
        return 1

    metrics = analyze_directory(directory, args.exclude)

    if not metrics:
        print("No Python files found to analyze")
        return 1

    report = generate_report(metrics, args.threshold)

    if args.output:
        with open(args.output, "w") as f:
            json.dump(report, f, indent=2)
        print(f"Report saved to: {args.output}")

    print_report(report)

    # Exit with error if high severity issues found
    high_issues = report["summary"]["issues_by_severity"]["high"]
    return 1 if high_issues > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
