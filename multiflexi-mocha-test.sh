#!/bin/bash
TIMESTAMP=$(cat /var/lib/zabbix/mocha/.timestamp); /usr/bin/mocha test/*.spec.js --reporter /usr/lib/nodejs/mochawesome --reporter-options reportDir=/var/lib/zabbix/mocha,reportFilename=test-results-$TIMESTAMP,json=true,html=false
