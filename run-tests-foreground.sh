#!/bin/bash
# Run all Mocha/Selenium tests in foreground with visible Chrome browser
# Usage: ./run-tests-foreground.sh [optional: specific test file]

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TESTS_DIR="${TESTS_DIR:-$SCRIPT_DIR/test}"
REPORT_DIR="${REPORT_DIR:-$SCRIPT_DIR/report}"

# Ensure headless is off
unset HEADLESS
unset CI

mkdir -p "$REPORT_DIR"

if [ $# -gt 0 ]; then
    TEST_FILES="$@"
else
    TEST_FILES="$TESTS_DIR"/*.spec.js
fi

echo "Running tests from: $TESTS_DIR"
echo "Reports will be saved to: $REPORT_DIR"
echo "Browser: Chrome (visible)"
echo "---"

mocha $TEST_FILES \
    --reporter /usr/lib/nodejs/mochawesome \
    --reporter-options reportDir="$REPORT_DIR",reportFilename=test-results,json=true,html=true \
    --timeout 60000 \
    --slow 10000 \
    --exit

echo "---"
echo "Results: $REPORT_DIR/test-results.json"
echo "HTML report: $REPORT_DIR/test-results.html"
