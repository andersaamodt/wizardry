# Wizardry Project Exemptions

Documents all deviations from project standards with justification.

## Summary

- **Style**: 330/330 files compliant (2 hardcoded exemptions for doppelganger)
- **Shebang**: `#!/usr/bin/env sh` accepted alongside `#!/bin/sh` (38 files); tutorials may use bash (5 files)
- **Code Structure**: Conditional imps exempt from `set -eu`; imps exempt from `--help`
- **Testing**: Bootstrap scripts can't use wizardry infrastructure
- **Non-Shell Files**: Systemd service files exempt from all shell checks (2 files)
- **CI**: No exemptions - all checks required

---

## 1. Style Exemptions

### Long Lines (>100 chars)

**Rule**: FAIL unless >60% quoted text (strings)

**Automatic Exemptions**: Error messages, prompts, help text (auto-detected by lint-magic)

**Hardcoded Exemptions** (2 files, 2 lines):

1. **`spells/.imps/cond/is` line 13** (156 chars)
   - Case: `empty) if [...]; elif [...]; else ...; fi ;;`
   - Reason: Doppelganger's compile-spell expects case labels on single line
   - Splitting breaks: `empty` → incorrectly renamed to `_empty`

2. **`spells/divination/identify-room` line 260** (~180 chars)
   - Pattern: `case $dir in *dir1*|*dir2*|...|*dirN*) ... ;; esac`
   - Reason: Same doppelganger compilation issue as above

**How to Split Other Long Lines**:
- Pipelines → intermediate variables: `filtered=$(cmd1 | cmd2); result=$(echo "$filtered" | cmd3)`
- Conditionals → separate checks
- Command chains → break at `&&`/`||`

### Mixed Tabs/Spaces

**Status**: ✅ RESOLVED - 8 files converted to 2-space indentation (commit 4463607)

### Alternative Shebangs: `#!/usr/bin/env sh`

**Rule**: Standard shebang is `#!/bin/sh`

**Accepted Alternative**: `#!/usr/bin/env sh` is explicitly allowed by `lint-magic` and test infrastructure

**Affected** (38 files):
- **Cantrips** (11 files): `assertions`, `colors`, `cursor-blink`, `fathom-cursor`, `fathom-terminal`, `max-length`, `menu`, `move-cursor`, `require-command`, `require-wizardry`
- **System/Menu** (3 files): `divination/detect-distro`, `system/update-all`, `menu/install-menu`
- **Arcana** (24 files): All `.arcana/core/*` install/uninstall scripts, plus arcana menus and helpers

**Reason**: `#!/usr/bin/env sh` provides better portability on systems where `/bin/sh` may not exist or points to a restricted shell (e.g., NixOS, some BSD variants). The `env` approach searches `PATH` for `sh`, making scripts work across diverse UNIX-like systems.

**Validation**: Both shebangs are recognized as valid POSIX in:
- `spells/spellcraft/lint-magic` (line checks)
- `.tests/common-tests.sh` (`is_posix_shell_script` function)

---

## 2. Code Structure Exemptions

### Conditional Imps: No `set -eu`

**Affected**: `spells/.imps/cond/`, `spells/.imps/lex/`, `spells/.imps/menu/`

**Reason**: Return exit codes for flow control (if/&&/||); `set -e` would treat false as error

**Example**:
```sh
#!/bin/sh
# has CMD - test if command available
_has() { command -v "$1" >/dev/null 2>&1; }
case "$0" in */has) _has "$@" ;; esac

# Usage: has git || die "git required"
```

### Imps: No `--help` Required

**Affected**: All `spells/.imps/*`

**Reason**: Micro-helpers; opening comment serves as spec; `--help` would bloat them

---

## 3. Testing Exemptions

### Bootstrap Scripts: No Wizardry Imps

**Affected**: `install`, `spells/install/core/*`

**Reason**: Run before wizardry installed; must be self-contained

### Test-Only Imps: Require `test-` Prefix

**Affected**: `spells/.imps/test/*`

**Reason**: Distinguish test infrastructure from production code

---

## 4. Non-Shell File Exemptions

### Systemd Service Files

**Affected** (2 files):
- `spells/.arcana/bitcoin/bitcoin.service`
- `spells/.arcana/tor/tor.service`

**Reason**: Systemd unit files, not shell scripts; exempt from all shell-specific checks (shebang, `set -eu`, `show_usage`, `--help`)

**Validation**: `lint-magic` and test infrastructure skip files matching `*.service` pattern

---

## 5. Tutorial Exemptions

### Bash Tutorials: `#!/bin/bash` Allowed

**Affected** (5 files):
- `tutorials/26_history.sh`
- `tutorials/28_distribution.sh`
- `tutorials/29_ssh.sh`
- `tutorials/30_git.sh`
- `tutorials/31_usability.sh`

**Reason**: Educational tutorials demonstrating bash-specific features; not production spells

**Standards Relaxed**:
- May use `#!/bin/bash` instead of `#!/bin/sh`
- No `show_usage()` function required
- No `--help` handler required
- No `set -eu` required
- May use underscores in filenames

**Note**: 21 other tutorials follow POSIX standards with `#!/bin/sh`

---

## 6. CI Exemptions

**Status**: ✅ None - all checks required (no `continue-on-error` or `allow-failure`)

---

## Adding New Exemptions

1. Exhaust alternatives (logical splitting, helper functions)
2. Document: files, reason, justification, examples
3. Get PR approval
4. Update this file

**Review**: Quarterly (next: 2026-03-10) | **Last Updated**: 2025-12-11
