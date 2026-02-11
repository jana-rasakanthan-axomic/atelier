#!/usr/bin/env bash
# Run pytest with standardized flags and error handling
# Usage: run-tests.sh [pytest-args]
# Examples:
#   run-tests.sh                    # Run all tests
#   run-tests.sh tests/unit/        # Run specific directory
#   run-tests.sh -k test_user       # Run matching tests
#   run-tests.sh --coverage         # Generate coverage report
#   run-tests.sh --verbose          # Verbose output
#   run-tests.sh --fail-fast        # Stop on first failure

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Support flags
COVERAGE=false
VERBOSE=false
FAIL_FAST=false
PYTEST_ARGS=()

# Parse custom flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --coverage)
      COVERAGE=true
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --fail-fast|-x)
      FAIL_FAST=true
      shift
      ;;
    -h|--help)
      echo "Usage: run-tests.sh [options] [pytest-args]"
      echo ""
      echo "Options:"
      echo "  --coverage        Generate coverage report (JSON + terminal)"
      echo "  --verbose, -v     Verbose test output"
      echo "  --fail-fast, -x   Stop on first test failure"
      echo "  -h, --help        Show this help message"
      echo ""
      echo "Examples:"
      echo "  run-tests.sh                      # Run all tests"
      echo "  run-tests.sh tests/unit/          # Run specific directory"
      echo "  run-tests.sh -k test_user         # Run tests matching pattern"
      echo "  run-tests.sh --coverage           # Run with coverage"
      echo "  run-tests.sh --verbose --coverage # Verbose with coverage"
      exit 0
      ;;
    *)
      # Add to pytest args
      PYTEST_ARGS+=("$1")
      shift
      ;;
  esac
done

# Check if pytest is available
if ! command -v pytest &> /dev/null; then
  echo -e "${RED}Error: pytest not found${NC}"
  echo "Install pytest: pip install pytest pytest-asyncio"
  exit 1
fi

# Build pytest command with base flags
CMD=(pytest)

# Add output formatting (default: concise)
if [[ "$VERBOSE" == "true" ]]; then
  CMD+=("-vv" "--tb=long")
else
  CMD+=("--tb=short" "-q")
fi

# Add fail-fast flag
if [[ "$FAIL_FAST" == "true" ]]; then
  CMD+=("-x")
fi

# Add coverage flags
if [[ "$COVERAGE" == "true" ]]; then
  # Check if pytest-cov is available
  if ! python -c "import pytest_cov" &> /dev/null; then
    echo -e "${YELLOW}Warning: pytest-cov not found, coverage disabled${NC}"
    echo "Install: pip install pytest-cov"
  else
    CMD+=("--cov=src" "--cov-report=term-missing:skip-covered" "--cov-report=json")
  fi
fi

# Add user-provided args
if [[ ${#PYTEST_ARGS[@]} -gt 0 ]]; then
  CMD+=("${PYTEST_ARGS[@]}")
fi

# Print command being run (for transparency)
echo "Running: ${CMD[*]}"
echo ""

# Run tests and capture exit code
set +e
"${CMD[@]}"
EXIT_CODE=$?
set -e

# Output results with color
echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
  echo -e "${GREEN}Tests passed${NC}"

  # Show coverage location if generated
  if [[ "$COVERAGE" == "true" && -f coverage.json ]]; then
    echo ""
    echo "Coverage report saved: coverage.json"

    # Extract coverage percentage if jq is available
    if command -v jq &> /dev/null && [[ -f coverage.json ]]; then
      COVERAGE_PCT=$(jq -r '.totals.percent_covered_display' coverage.json 2>/dev/null || echo "N/A")
      echo -e "Coverage: ${GREEN}${COVERAGE_PCT}%${NC}"
    fi
  fi
else
  echo -e "${RED}Tests failed (exit code: $EXIT_CODE)${NC}"

  # Provide helpful hints based on exit code
  case $EXIT_CODE in
    1)
      echo ""
      echo "Hint: Test failures detected. Review output above for details."
      ;;
    2)
      echo ""
      echo "Hint: Test collection error. Check for syntax errors or import issues."
      ;;
    3)
      echo ""
      echo "Hint: Internal pytest error. Check pytest version and configuration."
      ;;
    4)
      echo ""
      echo "Hint: pytest command line usage error. Check your arguments."
      ;;
    5)
      echo ""
      echo "Hint: No tests collected. Check test discovery patterns."
      ;;
  esac
fi

exit $EXIT_CODE
