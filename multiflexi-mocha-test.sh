#!/bin/bash
set -euo pipefail

# Directory containing *.spec.js tests; override via TESTS_DIR env
TESTS_DIR=${TESTS_DIR:-/usr/share/multiflexi-zabbix-selenium/tests}

TIMESTAMP=$(cat /var/lib/zabbix/mocha/.timestamp)
/usr/bin/mocha "$TESTS_DIR"/*.spec.js \
	--reporter /usr/lib/nodejs/mochawesome \
	--reporter-options reportDir=/var/lib/zabbix/mocha,reportFilename=test-results-$TIMESTAMP,json=true,html=false
