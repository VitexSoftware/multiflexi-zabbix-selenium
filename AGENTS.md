# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a **Debian package project** that integrates Mocha/Selenium test results with Zabbix monitoring. The package does NOT contain tests themselves—it provides the infrastructure to monitor tests that run elsewhere.

**Critical architectural principle**: Zabbix never executes tests or browsers. Tests run via systemd timer → write JSON reports → Zabbix reads and evaluates.

## Architecture Flow

```
systemd timer → Mocha tests → mochawesome JSON report → Zabbix UserParameter script → Zabbix agent2 → Zabbix server
```

### Key Components

1. **zabbix-mocha-stats.sh**: Bash script that extracts metrics from mochawesome JSON using `jq`. Called by Zabbix agent via UserParameter.

2. **mocha.conf**: Zabbix agent2 UserParameter configuration that maps `mocha.tests[*]` keys to the extraction script.

3. **mocha-selenium-tests.service**: systemd oneshot service running as `zabbix` user. Uses atomic writes (timestamped files + symlink) to prevent race conditions.

4. **mocha-selenium-tests.timer**: Triggers service every 15 minutes with `OnUnitActiveSec`.

5. **zabbix-template-mocha.yaml**: Zabbix 6.0+ template with items (total/passed/failed/pending/duration/age), calculated item (success_rate), and triggers.

### Data Flow Details

- Tests write to: `/var/lib/zabbix/mocha/test-results-<timestamp>.json`
- Symlink points to: `/var/lib/zabbix/mocha/test-results.json` (what Zabbix reads)
- Old reports auto-cleanup after 7 days via `ExecStartPost` find command

## Package Build Commands

```bash
# Build Debian package
dpkg-buildpackage -us -uc -b

# Package output location
ls ../multiflexi-zabbix-selenium_*.deb

# Verify package contents
dpkg -c ../multiflexi-zabbix-selenium_*.deb

# Check package metadata
dpkg-deb --info ../multiflexi-zabbix-selenium_*.deb
```

## Testing Without Installation

```bash
# Test extraction script locally (requires jq)
./zabbix-mocha-stats.sh total

# Run mocha with mochawesome locally
mocha test/*.spec.js \
  --reporter mochawesome \
  --reporter-options reportDir=./report,reportFilename=test-results,json=true,html=false

# Extract metrics from local report
jq '.stats' ./report/test-results.json

# Test extraction script on local report
REPORT=./report/test-results.json bash -c 'jq -r ".stats.tests" "$REPORT"'
```

## Post-Installation Testing

```bash
# Test Zabbix UserParameter
zabbix_agent2 -t mocha.tests[total]
zabbix_agent2 -t mocha.tests[failed]

# Run service manually
sudo systemctl start mocha-selenium-tests.service
journalctl -u mocha-selenium-tests.service -n 50

# Check timer status
systemctl status mocha-selenium-tests.timer
systemctl list-timers mocha-selenium-tests.timer
```

## Critical Implementation Details

### Atomic Report Writing
The service uses a three-step atomic write to prevent Zabbix reading partial/corrupt JSON:
1. Write to timestamped file: `test-results-1234567890.json`
2. Create/update symlink: `test-results.json → test-results-1234567890.json`
3. Zabbix always reads the symlink (atomic operation)

### WorkingDirectory Configuration
The systemd service's `WorkingDirectory` is hardcoded to the development path. When packaging for different deployments:
- This MUST be updated to point to the actual test location
- Or tests should be placed in a standard location like `/usr/share/multiflexi-zabbix-selenium/tests`

### Permission Model
- Service runs as `zabbix` user (not root)
- `/var/lib/zabbix/mocha/` owned by `zabbix:zabbix`
- Extraction script must be readable by zabbix user
- Test files must be readable by zabbix user

## Debian Packaging Notes

### File Installation Mapping (debian/install)
- Root-level files → installed to system paths
- No build step—files copied as-is
- Scripts must be executable in source tree (chmod +x)

### Post-Installation Hooks
- `debian/postinst`: Sets directory ownership, reloads systemd, restarts zabbix-agent2
- `debian/postrm`: Cleanup on purge, daemon-reload on remove
- Timer is NOT auto-enabled (manual: `systemctl enable --now mocha-selenium-tests.timer`)

### Dependencies
- Runtime: `zabbix-agent2`, `node-mochawesome`, `mocha`, `jq`
- Build: `debhelper-compat (= 13)` only
- Recommends: `chromium-driver | gecko-driver` (not required by package, needed for actual Selenium tests)

## Modifying the Integration

### Adding New Metrics
1. Update `zabbix-mocha-stats.sh` with new case statement
2. Add corresponding item in `zabbix-template-mocha.yaml`
3. Ensure mochawesome JSON structure supports the metric
4. Rebuild package

### Changing Test Frequency
Modify `OnUnitActiveSec` in `mocha-selenium-tests.timer`, not the service file.

### Supporting Different Test Frameworks
The extraction script is tightly coupled to mochawesome's JSON structure (`.stats.tests`, `.stats.passes`, etc.). To support other reporters:
- Either convert their JSON to mochawesome format
- Or rewrite extraction script for their schema
- Zabbix side (template) remains unchanged if metric names stay the same

## Common Pitfalls

1. **Using /usr/local/bin**: debhelper's `dh_usrlocal` will fail. Use `/usr/bin` instead.

2. **Duplicate compat specification**: Don't use both `debian/compat` file and `debhelper-compat` in control—choose one (prefer control).

3. **Forgetting chmod +x**: Source files must be executable before packaging. dpkg-buildpackage doesn't set this automatically.

4. **Timer depends on WorkingDirectory**: If tests aren't at the hardcoded path, service will fail silently. Always check `journalctl` after enabling timer.

5. **Race conditions in parallel test runs**: The atomic write pattern prevents this, but if you modify the service to run tests in parallel (don't), you'll need per-instance report files.

## Zabbix Template Import

Template is YAML format (Zabbix 6.0+). Import via UI or CLI:

```bash
# Via Zabbix CLI (if available)
zabbix_import.py -f /usr/share/zabbix/templates/zabbix-template-mocha.yaml

# Manual: UI → Configuration → Templates → Import
```

UUIDs in template are static for consistency across imports. Don't change them unless creating a derivative template.
