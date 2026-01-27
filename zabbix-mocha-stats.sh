#!/bin/bash
# Zabbix UserParameter script for Mocha test results
# Returns test statistics from mochawesome JSON report

REPORT="/var/lib/zabbix/mocha/test-results.json"

case "$1" in
    total)
        jq -r '.stats.tests' "$REPORT" 2>/dev/null || echo 0
        ;;
    passed)
        jq -r '.stats.passes' "$REPORT" 2>/dev/null || echo 0
        ;;
    failed)
        jq -r '.stats.failures' "$REPORT" 2>/dev/null || echo 0
        ;;
    pending)
        jq -r '.stats.pending' "$REPORT" 2>/dev/null || echo 0
        ;;
    duration)
        jq -r '.stats.duration' "$REPORT" 2>/dev/null || echo 0
        ;;
    age)
        if [ -f "$REPORT" ]; then
            stat -c %Y "$REPORT" 2>/dev/null || echo 0
        else
            echo 0
        fi
        ;;
    *)
        echo "ZBX_NOTSUPPORTED"
        exit 1
        ;;
esac
