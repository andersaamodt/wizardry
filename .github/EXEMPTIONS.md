# Wizardry Project Exemptions

Documents all deviations from project standards with justification.

## Summary

- **Style**: 330/330 files compliant (2 hardcoded exemptions for doppelganger)
- **Code Structure**: Conditional imps exempt from `set -eu`; imps exempt from `--help`
- **Function Discipline**: 10 spells with 4+ functions (proto-libraries) - test FAILS to maintain visibility for refactoring
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

### Doppelganger Compilation: Skip Lists

**File**: `spells/spellcraft/compile-spell`

**Reason**: When compiling standalone scripts, certain imp names must be excluded from inlining to prevent incorrect replacements

#### Common English Words Skip List

**Affected imps** (lines 104-107):
- `is` - Too common as English word (e.g., "this is")
- `fail` - Commonly used as variable name (e.g., `fail=0`)
- `empty` - Too common in error messages (e.g., "must not be empty")

**Reason**: These words appear frequently in strings and variable names. Inlining them would cause incorrect replacements like "must not be empty" → "must not be _empty".

**Policy**: Only add words causing real compilation issues. Each addition prevents legitimate imp inlining if that imp exists.

#### Interactive Imps Skip List

**Affected imps** (line 112):
- `ask-number`, `ask-yn`, `ask-text`
- `await-keypress`
- `select-input`, `read-line`
- `tty-*` (all tty-prefixed imps)

**Reason**: Interactive I/O code must remain external for test stubbing. Inlining prevents tests from intercepting user input.

**Policy**: All interactive terminal I/O imps must remain external.

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

**Temporary Exemptions** (3 spells - TO BE REFACTORED):

**Arcana** (1 spell):
- `.arcana/mud/cd` (14 additional) - MUD navigation system, needs refactoring

**Other** (2 spells):
- `menu/spellbook` (10 additional) - Menu infrastructure
- `system/update-all` (10 additional) - Update system
- `system/test-magic` (15 additional) - Test runner

**Removed/Obsolete**:
- `spellcraft/learn-spell` - Removed (obsolete with word-of-binding paradigm)
- `spellcraft/learn-spellbook` - Removed (replaced by simplified learn spell)
- `cantrips/assertions` - Removed (boot/ test imps already provide assertion functionality)


**Refactored** (38 spells - COMPLETED ✅):
- `spellcraft/lint-magic` (21→0) - Inlined all 21 functions (100% reduction, show_usage only)
- `menu/spellbook` (30→10) - Major refactor, created 3 reusable imps
- `spellcraft/learn-spell` (8→1) - Inlined warn and detect_env_once - **NOW REMOVED (obsolete)**
- `spellcraft/scribe-spell` (10→1) - Inlined helpers, removed learn-spellbook dependency
- `spellcraft/learn` (15→0) - Dramatically simplified to copy/link spells to spellbook
- `spellcraft/learn-spellbook` (24→REMOVED) - Obsolete with word-of-binding, replaced by learn
- `cantrips/assertions` (4→REMOVED) - Test library removed, boot/ test imps already exist
- `menu/spell-menu` (17→1) - Major refactor
- `.arcana/bitcoin/install-bitcoin` (11→0) - Refactored
- `.arcana/tor/install-tor` (9→0) - Refactored
- `mud/look` (11→1) - Refactored
- `.arcana/core/install-clipboard-helper` (4→2) - Inlined single-use functions
- `.arcana/core/uninstall-core` (4→2) - Inlined detect_platform and core_dependencies
- `.arcana/lightning/lightning-status` (4→0) - Fully inlined
- `.arcana/node/node-status` (4→0) - Fully inlined
- `cantrips/start-service` (4→1)
- `cantrips/stop-service` (4→1)
- `cantrips/restart-service` (4→1)
- `cantrips/service-status` (4→1)
- `cantrips/fathom-cursor` (4→3)
- `cantrips/require-wizardry` (4→2)
- `cantrips/install-service-template` (6→2)
- `cantrips/memorize` (8→2)
- `cantrips/spellbook-store` (7→2)
- `cantrips/await-keypress` (7→2)
- `cantrips/menu` (14→2) - Flattened navigation and rendering flow
- `menu/cast` (4→1)
- `menu/mud-menu` (4→3)
- `spellcraft/doppelganger` (4→4) - fallback functions
- `spellcraft/forget` (6→2)
- `psi/read-contact` (5→3)
- `arcane/trash` (6→1)
- `arcane/read-magic` (8→1)
- `enchant/enchantment-to-yaml` (4→1)
- `enchant/disenchant` (6→2)
- `enchant/enchant` (10→1)
- `translocation/jump-to-marker` (7→2)
- `.arcana/bitcoin/bitcoin-status` (4→1)
- `.arcana/bitcoin/uninstall-bitcoin` (7→1)
- `.arcana/tor/configure-tor` (6→1)
- `.arcana/mud/mud-config` (5→4)

**Action Required**: Remaining 4 spells (plus several in arcana/) should be refactored to:
1. Extract reusable logic into imps in `spells/.imps/`
2. Split into multiple smaller spells if handling multiple actions
3. Simplify linear flow by inlining single-use helpers

**Progress**: 37/39 spells refactored (95%) - 3 spells removed as obsolete

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
