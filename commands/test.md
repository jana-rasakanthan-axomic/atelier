---
name: test
description: Run tests using profile-configured test runner
model_hint: haiku
allowed-tools: Read, Grep, Glob, Bash(${profile.tools.test_runner.command}:*)
---

# /test

Run tests using the profile-configured test runner.

## Input Formats

- `/test` - Run full test suite (default: `all` mode)
- `/test all` - Run full test suite explicitly
- `/test file path/to/test_file.py` - Run a single test file
- `/test file path/to/test_file.py::test_name` - Run a specific test
- `/test coverage` - Run with coverage reporting
- `/test verbose` - Run with verbose output
- `/test failed` - Re-run only previously failed tests (if supported)
- `/test --filter "pattern"` - Run tests matching a pattern

## When to Use

- Verifying changes work before committing
- Checking for regressions after edits
- Running coverage to find untested code
- Quick feedback during development

## When NOT to Use

- Tests are failing and you need fixes -> use `/fix tests`
- Writing new tests -> use `/build` (TDD workflow)
- Need full quality gate (lint + types + tests) -> use `/build` or `/fix`

---

## Profile Resolution

Before running tests, resolve the active profile to determine the test runner.

| Setting | Profile Key | Example Values |
|---------|-------------|----------------|
| Full suite | `${profile.tools.test_runner.command}` | `pytest`, `flutter test`, `jest` |
| Single file | `${profile.tools.test_runner.single_file}` | `pytest {file} -v`, `flutter test {file}` |
| Coverage | `${profile.tools.test_runner.coverage}` | `pytest --cov`, `flutter test --coverage` |
| Verbose | `${profile.tools.test_runner.verbose}` | `pytest -v`, `jest --verbose` |

---

## Workflow (3 Stages)

### Stage 0: Resolve Profile

1. Resolve active profile
2. Load test runner configuration
3. Verify test runner is available
4. Check for Makefile `test` target (preferred for `all` mode)

---

### Stage 1: Run Tests

**Mode Resolution:**

| Mode | Command | Fallback |
|------|---------|----------|
| `all` (default) | `make test` (if available) or `${profile.tools.test_runner.command}` | -- |
| `file <path>` | `${profile.tools.test_runner.single_file}` with `{file}` replaced | Append path to base command |
| `coverage` | `${profile.tools.test_runner.coverage}` | Warn if not configured |
| `verbose` | `${profile.tools.test_runner.verbose}` | Append verbose flag to base command |
| `failed` | Runner-specific re-run flag (e.g., `pytest --lf`) | Warn if not supported |
| `--filter` | Runner-specific filter (e.g., `pytest -k "{pattern}"`) | Warn if not supported |

Capture full output for parsing in Stage 2.

---

### Stage 2: Report

Parse test output and present actionable results.

**Extract from output:** total tests, passed, failed, skipped, errors, duration.

**If all pass:** Report summary table (total, passed, skipped, duration).

**If failures:** Report summary table plus a table of failed tests with test name, file location, error type, and brief message. Include suggested next steps: `/fix tests`, `/test failed`, `/test verbose`.

**If coverage mode:** Append coverage summary table (module, statements, covered, missing, coverage percentage).

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Test runner not found | Report which command was attempted, suggest checking profile or installing runner |
| No tests found | Report, show test directory pattern from profile, suggest checking naming conventions |
| Test runner crashes (non-test error) | Distinguish from test failures, show raw error, suggest checking environment |
| Makefile target fails | Fall back to direct profile command, report both outputs |
| Single file not found | Report path, search for similar files with Glob, suggest closest match |
| `failed` mode not supported | Report limitation, suggest running specific failing test file instead |

## Integration

| Command | Relationship |
|---------|--------------|
| `/build` | Runs tests as part of TDD workflow |
| `/fix tests` | Fix failing tests identified by `/test` |
| `/commit` | Commit after tests pass |

## Scope Limits

- Runs tests only -- does not modify code
- Does not run linter or type checker (use `/fix` or `/build` for full quality gates)
- Timeout: inherits from test runner configuration
- For long-running suites, consider `file` mode for targeted feedback
