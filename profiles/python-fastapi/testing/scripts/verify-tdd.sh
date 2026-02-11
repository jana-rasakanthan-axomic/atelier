#!/bin/bash
#
# verify-tdd.sh - Verify TDD workflow was followed
#
# Checks that test files were created/modified before implementation files
# by examining git history or file timestamps.
#
# Usage:
#   verify-tdd.sh <test_file> <impl_file>
#   verify-tdd.sh --git <test_file> <impl_file>
#   verify-tdd.sh --check-red <test_file>
#
# Examples:
#   verify-tdd.sh tests/unit/api/asset/test_service.py src/api/asset/service.py
#   verify-tdd.sh --git tests/unit/api/asset/test_service.py src/api/asset/service.py
#   verify-tdd.sh --check-red tests/unit/api/asset/test_service.py

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}OK${NC} $1"
}

print_error() {
    echo -e "${RED}FAIL${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARN${NC} $1"
}

# Check if test file fails (RED phase verification)
check_red_phase() {
    local test_file=$1

    if [ ! -f "$test_file" ]; then
        print_error "Test file does not exist: $test_file"
        exit 1
    fi

    echo "Running test to verify RED phase..."
    echo "Command: pytest $test_file -v --tb=short"
    echo ""

    # Run pytest and capture exit code
    if pytest "$test_file" -v --tb=short 2>/dev/null; then
        print_error "TDD VIOLATION: Tests PASS but should FAIL in RED phase"
        echo ""
        echo "Tests should fail before implementation exists."
        echo "If tests pass, either:"
        echo "  1. Implementation already exists (not TDD)"
        echo "  2. Tests are not testing new behavior"
        echo ""
        echo "Fix: Delete tests and start over with proper TDD"
        exit 1
    else
        print_success "RED phase confirmed - tests fail as expected"
        echo ""
        echo "You may now proceed to implement code (GREEN phase)"
        exit 0
    fi
}

# Check timestamp order (test before impl)
check_timestamp_order() {
    local test_file=$1
    local impl_file=$2

    if [ ! -f "$test_file" ]; then
        print_error "Test file does not exist: $test_file"
        exit 1
    fi

    if [ ! -f "$impl_file" ]; then
        print_success "Implementation file does not exist yet - TDD workflow correct"
        exit 0
    fi

    # Get modification times (macOS and Linux compatible)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        test_time=$(stat -f %m "$test_file")
        impl_time=$(stat -f %m "$impl_file")
    else
        test_time=$(stat -c %Y "$test_file")
        impl_time=$(stat -c %Y "$impl_file")
    fi

    if [ "$test_time" -lt "$impl_time" ]; then
        print_success "TDD workflow verified: test file created before implementation"
        echo "  Test: $test_file (modified first)"
        echo "  Impl: $impl_file (modified after)"
        exit 0
    else
        print_warning "Possible TDD violation: implementation modified after test"
        echo "  Test: $test_file"
        echo "  Impl: $impl_file"
        echo ""
        echo "This may be fine if you were fixing implementation after tests."
        echo "Use --git flag for more accurate git-based verification."
        exit 0
    fi
}

# Check git history order (test commit before impl commit)
check_git_order() {
    local test_file=$1
    local impl_file=$2

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not a git repository"
        exit 1
    fi

    if [ ! -f "$test_file" ]; then
        print_error "Test file does not exist: $test_file"
        exit 1
    fi

    if [ ! -f "$impl_file" ]; then
        print_success "Implementation file does not exist yet - TDD workflow correct"
        exit 0
    fi

    # Get first commit that added each file
    test_first_commit=$(git log --diff-filter=A --format="%H" -- "$test_file" | tail -1)
    impl_first_commit=$(git log --diff-filter=A --format="%H" -- "$impl_file" | tail -1)

    if [ -z "$test_first_commit" ]; then
        print_warning "Test file not yet committed to git"
        echo "  Cannot verify TDD workflow via git history"
        exit 0
    fi

    if [ -z "$impl_first_commit" ]; then
        print_success "Implementation file not yet committed - TDD workflow in progress"
        exit 0
    fi

    # Compare commit timestamps
    test_commit_time=$(git show -s --format=%ct "$test_first_commit")
    impl_commit_time=$(git show -s --format=%ct "$impl_first_commit")

    if [ "$test_commit_time" -le "$impl_commit_time" ]; then
        print_success "TDD workflow verified via git history"
        echo "  Test first committed: $(git show -s --format='%ci' $test_first_commit)"
        echo "  Impl first committed: $(git show -s --format='%ci' $impl_first_commit)"
        exit 0
    else
        print_error "TDD VIOLATION detected in git history"
        echo "  Implementation was committed before tests!"
        echo ""
        echo "  Impl committed: $(git show -s --format='%ci' $impl_first_commit)"
        echo "  Test committed: $(git show -s --format='%ci' $test_first_commit)"
        echo ""
        echo "This violates TDD principles. Tests should be committed first."
        exit 1
    fi
}

# Show usage
show_usage() {
    echo "verify-tdd.sh - Verify TDD workflow was followed"
    echo ""
    echo "Usage:"
    echo "  verify-tdd.sh <test_file> <impl_file>     Check file timestamps"
    echo "  verify-tdd.sh --git <test_file> <impl_file>  Check git history"
    echo "  verify-tdd.sh --check-red <test_file>     Verify tests fail (RED phase)"
    echo ""
    echo "Examples:"
    echo "  verify-tdd.sh tests/unit/api/asset/test_service.py src/api/asset/service.py"
    echo "  verify-tdd.sh --check-red tests/unit/api/asset/test_service.py"
    echo ""
    echo "Exit codes:"
    echo "  0 - TDD workflow verified"
    echo "  1 - TDD violation detected or error"
}

# Main
case "${1:-}" in
    --help|-h)
        show_usage
        exit 0
        ;;
    --check-red)
        if [ -z "${2:-}" ]; then
            print_error "Missing test file argument"
            show_usage
            exit 1
        fi
        check_red_phase "$2"
        ;;
    --git)
        if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
            print_error "Missing file arguments"
            show_usage
            exit 1
        fi
        check_git_order "$2" "$3"
        ;;
    *)
        if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
            print_error "Missing file arguments"
            show_usage
            exit 1
        fi
        check_timestamp_order "$1" "$2"
        ;;
esac
