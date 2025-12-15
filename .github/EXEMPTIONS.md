# Wizardry Project Exemptions

Documents all deviations from project standards with justification.

## Summary

- **Style**: 330/330 files compliant (2 hardcoded exemptions for doppelganger)
- **Code Structure**: Conditional imps exempt from `set -eu`; imps exempt from `--help`
- **Function Discipline**: 2 spells with 4+ functions (proto-libraries) - test FAILS to maintain visibility for refactoring
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

### Explicit Mode Requirement (set -e or set +e)

**Required**: All spells must explicitly declare their error handling mode

**Options**:
- `set -eu` (strict mode) - Recommended for most spells; exit on errors and undefined variables
- `set +eu` (permissive mode) - For sourceable files that would affect user's shell options

**Pattern for sourceable spells**:
```sh
#!/bin/sh
# Handle --help when run directly
case "${1-}" in
--help|--usage|-h) show_usage; exit 0 ;; esac

# Explicitly use permissive mode - this file is sourced into user's shell
set +eu

function_to_override() { ... }
```

**No Exemptions**: All scripts must be explicit; lint-magic checks for `set -e` or `set +e` pattern

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

### Doppelganger: Function Name Collision Check Exemption

**Affected**: Compiled spells in doppelganger (when `WIZARDRY_TEST_COMPILED=1` is set)

**Test**: `test_no_function_name_collisions` in `.tests/common-tests.sh`

**Reason**: Compiled spells are standalone executables that inline all dependencies. When multiple spells use the same imp (e.g., `_has`, `_there`, `_detect_indent_width`), that imp's function gets inlined into each compiled spell, creating duplicate function definitions across different files. This is expected and acceptable because:

1. **Standalone design**: Each compiled spell is an independent executable with all dependencies inlined
2. **No sourcing**: Compiled spells never source each other, so function name collisions cannot occur at runtime
3. **Intentional duplication**: The same imp function must appear in multiple compiled files to make each one self-contained

**Behavior**:
- **Source repository**: Collision check is **enforced** (detects genuine collisions where spells might source each other)
- **Doppelganger**: Collision check is **skipped** when `WIZARDRY_TEST_COMPILED=1` is set (duplicates are expected)

**Implementation**: The collision test checks for `WIZARDRY_TEST_COMPILED=1` and returns early without checking for duplicates, allowing the test suite to pass when running against compiled spells.

**Example Duplicates** (expected in doppelganger):
```
Function _has collision: hash (inlined from has imp) and ask-yn (inlined from has imp)
Function _there collision: multiple spells (inlined from there imp)
Function _detect_indent_width collision: make-indent (inlined) and detect-indent-width (inlined)
```

These are not errors - they demonstrate that compile-spell correctly inlines dependencies to create standalone executables.

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

**Temporary Exemptions** (1 spell - TO BE REFACTORED):

**Remaining** (1 spell):
- `menu/spellbook` (10 additional) - Menu infrastructure (reduced from 30→10)

**Refactored** (1 spell - COMPLETED ✅):
- `system/update-all` (10→1) - Inlined all helpers, using existing imps (step, must has, etc.)

**Removed/Obsolete**:
- `spellcraft/learn-spell` - Removed (obsolete with word-of-binding paradigm)
- `spellcraft/learn-spellbook` - Removed (replaced by simplified learn spell)
- `cantrips/assertions` - Removed (boot/ test imps already provide assertion functionality)


**Refactored** (40 spells - COMPLETED ✅):
- `spellcraft/lint-magic` (22→2) - Added word-of-binding wrapper function, maintains 0 extra functions beyond usage
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
- `system/test-magic` (15→2) - **Word-of-binding compliant** - Wrapped main logic in function, maintains 2 functions total (usage + main)
- `.arcana/mud/cd` (15→2) - **MASSIVELY SIMPLIFIED** - Uses settings file + word-of-binding pattern, 2 functions total (usage + hook), 34 lines (was 401!)
- `system/update-all` (10→1) - **Inlined all helpers**, using existing imps (step, must has, etc.)

**Action Required**: Remaining 1 spell should be refactored to:
1. Extract reusable logic into imps in `spells/.imps/` (only if used by 2+ spells)
2. Split into multiple smaller spells if handling multiple actions
3. Simplify linear flow by inlining single-use helpers

**Progress**: 41/42 spells refactored (98%) - 3 spells removed as obsolete

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
