# Wizardry Project Exemptions

Documents all deviations from project standards with justification.

## Summary

- **Style**: 330/330 files compliant (2 hardcoded exemptions for doppelganger)
- **Code Structure**: Conditional imps exempt from `set -eu`; imps exempt from `--help`
- **Function Discipline**: 20 spells with 4+ functions (proto-libraries) - test FAILS to maintain visibility for refactoring
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

## 5. Function Discipline Exemptions

### Spells with 4+ Additional Functions (Proto-Libraries)

**Rule**: Spells should have `show_usage()` plus at most 1-3 additional helper functions. 4+ additional functions indicate a proto-library that needs decomposition into multiple spells and/or imps.

**Temporary Exemptions** (20 spells - TO BE REFACTORED):

**Spellcraft** (7 spells):
- `spellcraft/learn-spellbook` (24 additional) - Complex installation logic, needs decomposition
- `spellcraft/lint-magic` (21 additional) - Comprehensive linting tool, candidate for multiple spells
- `spellcraft/spell-menu` (17 additional) - Menu infrastructure, consider splitting
- `spellcraft/learn` (15 additional) - Learning system, needs refactoring
- `spellcraft/scribe-spell` (10 additional) - Spell creation wizard, consider multiple steps
- `spellcraft/learn-spell` (8 additional) - Learning logic, extract to imps
- `spellcraft/forget` (6 additional) - Forgetting logic, simplify or extract
- `spellcraft/doppelganger` (4 additional) - Compilation logic, marginal case

**Menu** (3 spells):
- `menu/spellbook` (30 additional) - Complex menu system, needs major decomposition
- `menu/mud-menu` (4 additional) - Menu logic, marginal case
- `menu/cast` (4 additional) - Menu logic, marginal case

**Enchant** (3 spells):
- `enchant/enchant` (10 additional) - Extended attribute manipulation, extract to imps
- `enchant/disenchant` (6 additional) - Attribute removal, simplify
- `enchant/enchantment-to-yaml` (4 additional) - Format conversion, marginal case

**Other** (7 spells):
- `mud/look` (11 additional) - MUD description system, consider multiple spells
- `translocation/jump-to-marker` (7 additional) - Teleportation logic, extract flavor text
- `arcane/read-magic` (8 additional) - Attribute reading, extract helper detection
- `arcane/trash` (6 additional) - Cross-platform trash, extract OS-specific helpers
- `psi/read-contact` (5 additional) - vCard parsing, extract format handlers
- `cantrips/start-service` (4 additional) - Service management, marginal case

**Action Required**: These spells should be refactored to:
1. Extract reusable logic into imps in `spells/.imps/`
2. Split into multiple smaller spells if handling multiple actions
3. Simplify linear flow by inlining single-use helpers

**Timeline**: Best-effort refactoring; test currently configured to FAIL to maintain visibility

---

## 6. CI Exemptions

**Status**: ✅ None - all checks required (no `continue-on-error` or `allow-failure`)

---

## Adding New Exemptions

1. Exhaust alternatives (logical splitting, helper functions)
2. Document: files, reason, justification, examples
3. Get PR approval
4. Update this file

---

## Resolved Exemptions

These exemptions have been resolved and are documented here to prevent backsliding.

### ✅ Alternative Shebangs: `#!/usr/bin/env sh` (Resolved 2025-12-11)

**Previously Affected** (38 files):
- **Cantrips** (10 files): `assertions`, `colors`, `cursor-blink`, `fathom-cursor`, `fathom-terminal`, `max-length`, `menu`, `move-cursor`, `require-command`, `require-wizardry`
- **System/Menu** (3 files): `divination/detect-distro`, `system/update-all`, `menu/install-menu`
- **Arcana** (25 files): All `.arcana/core/*` install/uninstall scripts (24 files), plus `tor/setup-tor`

**Resolution**: All files converted to standard `#!/bin/sh` shebang. Test infrastructure updated to only accept `#!/bin/sh` (with optional space after `#!`).

**Reason for Resolution**: Standardize on single shebang format across entire project. The standard `#!/bin/sh` is widely supported and the claimed portability benefits of `#!/usr/bin/env sh` were not compelling enough to maintain two shebang styles.

### ✅ Bash Tutorials: `#!/bin/bash` (Resolved 2025-12-11)

**Previously Affected** (5 files):
- `tutorials/26_history.sh`
- `tutorials/28_distribution.sh`
- `tutorials/29_ssh.sh`
- `tutorials/30_git.sh`
- `tutorials/31_usability.sh`

**Resolution**: All tutorial files converted to standard `#!/bin/sh` shebang.

**Reason for Resolution**: Educational materials should exemplify project standards. All 26 tutorials now use POSIX-compliant `#!/bin/sh`. Tutorials can still teach bash-specific concepts by noting them as non-portable extensions.

**Review**: Quarterly (next: 2026-03-10) | **Last Updated**: 2025-12-11
