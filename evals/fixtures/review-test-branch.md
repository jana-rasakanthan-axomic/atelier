# Review Test Branch Fixture

Describes what a test branch should contain so someone can set one up to run the self-review loop test (`evals/procedures/self-review-loop-test.md`).

---

## Purpose

Provide a reproducible branch with **deliberate, known quality issues** that `/review --self --loop` should detect, fix, and converge on.

## Branch Setup

1. Create a branch from main:
   ```bash
   git checkout -b eval/self-review-test main
   ```

2. Add the issues described below across 2-3 source files appropriate for your active profile.

3. Commit the deliberately flawed code:
   ```bash
   git add -A && git commit -m "eval: add review test fixture with deliberate issues"
   ```

## Required Issues (inject all of these)

### Lint Errors (3-4 issues)

- Unused import or variable
- Line exceeding max length (e.g., 120+ characters)
- Missing trailing newline at end of file
- Inconsistent indentation (mix tabs and spaces, or wrong indent level)

### Missing Tests (2-3 issues)

- A public function or endpoint with **zero test coverage**
- An edge case (empty input, null value) with no test
- An error path (exception, error response) with no test

### Style Violations (2-3 issues)

- Function or variable with non-idiomatic naming (e.g., `camelCase` in a Python file, `snake_case` in a TypeScript file)
- Missing docstring or JSDoc on a public function
- Magic number used without a named constant

### Structural Issues (1-2 issues)

- A function exceeding 30 lines that should be decomposed
- Duplicated logic across two functions that could be extracted

## Total Issue Count

Target **8-12 deliberate issues** across all categories. This should allow convergence within the 5-iteration budget while providing enough signal to validate the loop machinery.

## Validation

Before running the eval, manually confirm the issues exist:

```bash
# Lint should report errors
${profile.linter} <files>

# Tests should have gaps (coverage report)
${profile.test_runner} --coverage <files>
```

## Notes

- Keep the fixture small: 2-3 files, under 200 lines total. Large fixtures slow iteration and obscure signal.
- Issues should be **unambiguous** -- the self-review loop should not need subjective judgment to identify them.
- Avoid issues that require external context (missing config files, broken imports from other packages) since those cannot be fixed by code edits alone.
