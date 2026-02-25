# Installation Guide

## From VitexSoftware APT Repository (Recommended)

```bash
# Import GPG key
sudo curl -fsSL http://repo.vitexsoftware.com/KEY.gpg \
  -o /usr/share/keyrings/vitexsoftware-archive-keyring.gpg

# Add repository (replace DISTRO with your distribution codename, e.g. trixie, forky, bookworm)
sudo tee /etc/apt/sources.list.d/vitexsoftware.sources <<EOF
Types: deb
URIs: http://repo.vitexsoftware.com
Suites: DISTRO
Components: main
Signed-By: /usr/share/keyrings/vitexsoftware-archive-keyring.gpg
EOF

# Install
sudo apt update
sudo apt install multiflexi-zabbix-selenium
```

All dependencies will be resolved automatically.

## From Local Debian Package

```bash
sudo dpkg -i multiflexi-zabbix-selenium_*.deb
sudo apt-get install -f  # Install dependencies
```

## What Gets Installed

### Configuration Files
- `/etc/zabbix/zabbix_agent2.d/multiflexi-mocha.conf` - Zabbix UserParameters
- `/etc/systemd/system/mocha-selenium-tests.service` - Test execution service
- `/etc/systemd/system/mocha-selenium-tests.timer` - Periodic timer
- `/etc/default/multiflexi-mocha` - Environment (e.g., `TESTS_DIR`)

### Executables
- `/usr/bin/zabbix-mocha-stats.sh` - Metrics extraction script
- `/usr/bin/multiflexi-mocha-test.sh` - Test runner invoked by the service

### Templates
- `/usr/share/zabbix/templates/zabbix-template-mocha.yaml` - Zabbix template

### Data Directories
- `/var/lib/zabbix/mocha/` - Test results storage (owned by zabbix:zabbix)

## Post-Installation Steps

### 1. Configure Test Directory

Set `TESTS_DIR` in `/etc/default/multiflexi-mocha`:

```bash
sudo sed -i 's#^TESTS_DIR=.*#TESTS_DIR=/path/to/your/tests#' /etc/default/multiflexi-mocha
```

### 2. Enable Timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now mocha-selenium-tests.timer
```

### 3. Verify Installation

```bash
# Check timer status
systemctl status mocha-selenium-tests.timer

# Check Zabbix agent can read metrics
zabbix_agent2 -t mocha.tests[total]

# Run tests manually once
sudo systemctl start mocha-selenium-tests.service
journalctl -u mocha-selenium-tests.service -n 50
```

### 4. Import Zabbix Template

1. Login to Zabbix web interface
2. Go to Configuration → Templates
3. Click Import
4. Select `/usr/share/zabbix/templates/zabbix-template-mocha.yaml`
5. Import the template
6. Assign template to your monitored host

## Testing Without Installation

You can test the components without installing:

```bash
# Test the extraction script
./zabbix-mocha-stats.sh total

# Run tests with mochawesome (local)
mocha test/*.spec.js \
  --reporter mochawesome \
  --reporter-options reportDir=./report,reportFilename=test-results,json=true,html=false

# Or invoke the packaged runner script with custom TESTS_DIR
TESTS_DIR=$PWD/test ./multiflexi-mocha-test.sh

# Extract metrics from report
REPORT=./report/test-results.json
jq '.stats' "$REPORT"
```

## Uninstallation

```bash
# Remove package but keep configuration
sudo apt-get remove multiflexi-zabbix-selenium

# Remove package and all configuration/data
sudo apt-get purge multiflexi-zabbix-selenium
```

## Dependencies

The package automatically installs:
- `zabbix-agent2` - Zabbix monitoring agent
- `node-mochawesome` - Mocha reporter for JSON output
- `mocha` - JavaScript test framework
- `jq` - JSON processor

Recommended (one of):
- `chromium-driver` - WebDriver for Chromium
- `gecko-driver` - WebDriver for Firefox

## Troubleshooting

### Tests Not Running

```bash
# Check timer is active
systemctl is-active mocha-selenium-tests.timer

# Check service logs
journalctl -u mocha-selenium-tests.service -f

# Run manually to see errors
sudo -u zabbix mocha test/*.spec.js --reporter mochawesome --reporter-options json=true
```

### Permission Errors

```bash
sudo chown -R zabbix:zabbix /var/lib/zabbix/mocha
sudo chmod 755 /var/lib/zabbix/mocha
```

### Zabbix Agent Not Reading Data

```bash
# Restart agent to load new configuration
sudo systemctl restart zabbix-agent2

# Test UserParameter directly
zabbix_agent2 -t mocha.tests[total]

# Check if report exists
ls -l /var/lib/zabbix/mocha/test-results.json
```
