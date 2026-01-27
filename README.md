# MultiFlexi Zabbix Selenium Integration

Production-ready integration of Mocha/Selenium test results into Zabbix monitoring.

## Architecture

```
Mocha tests → JSON report → Zabbix agent → Zabbix server
```

- Tests run externally via systemd timer (not by Zabbix)
- Zabbix only reads results and evaluates health
- No browser execution on Zabbix server

## Installation

### From Debian Package

```bash
sudo dpkg -i multiflexi-zabbix-selenium_1.0.0_all.deb
sudo apt-get install -f  # Install dependencies
```

### Enable Automated Tests

```bash
sudo systemctl enable --now mocha-selenium-tests.timer
systemctl status mocha-selenium-tests.timer
```

### Configure Zabbix

1. Import template: `/usr/share/zabbix/templates/zabbix-template-mocha.yaml`
2. Assign template to monitored host
3. Wait for data collection (5-15 minutes)

## Manual Testing

```bash
# Test UserParameter
zabbix_agent2 -t mocha.tests[total]
zabbix_agent2 -t mocha.tests[failed]

# Run tests manually
sudo -u zabbix /usr/bin/mocha test/*.spec.js \
  --reporter mochawesome \
  --reporter-options reportDir=/var/lib/zabbix/mocha,reportFilename=test-results,json=true,html=false

# Check report
cat /var/lib/zabbix/mocha/test-results.json | jq .stats
```

## Monitoring Metrics

- `mocha.tests[total]` - Total test count
- `mocha.tests[passed]` - Passed tests
- `mocha.tests[failed]` - Failed tests
- `mocha.tests[pending]` - Skipped tests
- `mocha.tests[duration]` - Execution time (ms)
- `mocha.tests[age]` - Report timestamp
- `mocha.success_rate` - Calculated success percentage

## Triggers

- **Warning**: Any test failures
- **Average**: Results older than 1 hour
- **High**: Results older than 2 hours or success rate < 90%
- **Disaster**: Success rate < 50%

## Customization

### Change Test Interval

Edit `/etc/systemd/system/mocha-selenium-tests.timer`:

```ini
[Timer]
OnUnitActiveSec=30min  # Change from 15min to 30min
```

Then reload:

```bash
sudo systemctl daemon-reload
sudo systemctl restart mocha-selenium-tests.timer
```

### Custom Test Directory

Edit `/etc/systemd/system/mocha-selenium-tests.service`:

```ini
WorkingDirectory=/path/to/your/tests
```

## Troubleshooting

### No Data in Zabbix

```bash
# Check agent configuration
zabbix_agent2 -t mocha.tests[total]

# Check test execution
systemctl status mocha-selenium-tests.service
journalctl -u mocha-selenium-tests.service -n 50

# Check timer
systemctl list-timers mocha-selenium-tests.timer
```

### Permission Errors

```bash
sudo chown -R zabbix:zabbix /var/lib/zabbix/mocha
sudo chmod 755 /var/lib/zabbix/mocha
```

### Stale Results

Check if timer is active:

```bash
systemctl is-active mocha-selenium-tests.timer
systemctl start mocha-selenium-tests.timer
```

## Files

- `/usr/bin/zabbix-mocha-stats.sh` - Metrics extraction script
- `/etc/zabbix/zabbix_agent2.d/mocha.conf` - Zabbix UserParameters
- `/etc/systemd/system/mocha-selenium-tests.service` - Test execution service
- `/etc/systemd/system/mocha-selenium-tests.timer` - Periodic execution timer
- `/usr/share/zabbix/templates/zabbix-template-mocha.yaml` - Zabbix template
- `/var/lib/zabbix/mocha/` - Test results directory

## Requirements

- Debian/Ubuntu Linux
- Zabbix agent2
- Node.js with Mocha
- node-mochawesome package
- jq for JSON parsing

## License

See debian/copyright
