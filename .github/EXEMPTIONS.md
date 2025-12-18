# Wizardry Project Exemptions

Documents all deviations from project standards with justification.

## Summary

- **Style**: ✅ **353/353 files compliant** - All long-line and mixed tabs/spaces exemptions eliminated (2025-12-17)
- **Code Structure**: Conditional imps exempt from `set -eu`; imps exempt from `--help` (architectural decisions)
- **Function Discipline**: ✅ 0 spells with 4+ extra functions (57/57 spells refactored)
  - 6 spells with 2-3 extra functions remain (documented below) - functions used 2-20x each, acceptable per guidelines
- **Testing**: Bootstrap scripts can't use wizardry infrastructure (run before installation)
- **Non-Shell Files**: Systemd service files exempt from all shell checks (2 files)
- **CI**: No exemptions - all checks required
- **All-Caps Variables**: ✅ **COMPLETED** - All production spells use lowercase (Dec 2025). Only `.arcana/*` bootstrap scripts remain (exempt category)
- **Shebangs**: ✅ **STANDARDIZED** - All scripts use `#!/bin/sh` (38 files converted, 5 tutorials converted)

---

## 1. Style Exemptions

### Long Lines (>100 chars)

**Rule**: FAIL unless >60% quoted text (strings)

**Automatic Exemptions**: Error messages, prompts, help text (auto-detected by lint-magic)

**Hardcoded Exemptions**: ✅ NONE - All eliminated (2025-12-17)

**Previously Exempted** (resolved):
1. **`spells/.imps/cond/is` line 13** - Refactored to multi-line format while preserving case label structure
2. **`spells/divination/identify-room` lines 112, 263** - Refactored complex conditionals and split long directory lists

**How to Split Other Long Lines**:
- Pipelines → intermediate variables: `filtered=$(cmd1 | cmd2); result=$(echo "$filtered" | cmd3)`
- Conditionals → separate checks or intermediate variables
- Command chains → break at `&&`/`||`
- Long lists → use line continuations with backslash

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

### Test-Only Imps: Require `test-` or `stub-` Prefix

**Affected**: `spells/.imps/test/*`

**Reason**: Distinguish test infrastructure from production code

**Prefixes**:
- `test-` for test infrastructure and utilities
- `stub-` for test stubs that mimic system commands

### Stub Imps: May Use Flags

**Affected**: `spells/.imps/test/stub-*`

**Reason**: Stub imps mimic the interface of system commands they replace (e.g., `stty -g`, `fathom-cursor -y`). They must accept the same flags as the original commands to work as drop-in replacements in tests.

**Policy**: Only stub imps may use flags. Regular imps must use space-separated arguments.

### Test-Doppelganger: Skipped in Regular test-magic Runs

**Affected**: `.tests/spellcraft/test-doppelganger.sh`

**Test Runner**: `spells/system/test-magic`

**Reason**: The doppelganger test has its own dedicated GitHub action workflow and nearly doubles the test run time when included in the regular test suite. It compiles the entire wizardry repository and tests the compiled version, which is a comprehensive but time-consuming process.

**Behavior**:
- **Regular runs**: test-doppelganger is **skipped** automatically by test-magic
- **Explicit runs**: test-doppelganger can still be run via `test-magic --only spellcraft/test-doppelganger.sh`
- **CI**: Separate GitHub action runs test-doppelganger independently

**Implementation**: test-magic checks for the test path and skips it unless explicitly requested via the `--only` flag.

**Future**: This test will be re-enabled for regular runs once platform-specific testing infrastructure is in place to ensure users can run doppelganger on all supported platforms.

### Doppelganger: Flag and Positional Argument Limit Exemption

**Affected**: Compiled spells in doppelganger (when `WIZARDRY_TEST_COMPILED=1` is set)

**Tests**: `test_spells_have_limited_flags` and `test_spells_have_limited_positional_args` in `.tests/common-tests.sh`

**Reason**: Compiled spells inline all dependencies (imps) into a single file. When imps that have their own flags or arguments are inlined, those flags appear in the compiled spell's code, causing the compiled spell to incorrectly report having more flags than the original spell actually defines.

For example:
- A spell with 1 flag that uses an imp with 2 flags will appear to have 3 flags when compiled
- The inlined imp code contains case statements and if checks for its flags, which the test detects

**Behavior**:
- **Source repository**: Flag and argument limits are **enforced** (validates actual spell interfaces)
- **Doppelganger**: These checks are **skipped** when `WIZARDRY_TEST_COMPILED=1` is set (inlined code doesn't reflect spell interface)

**Implementation**: Both tests check for `WIZARDRY_TEST_COMPILED=1` and return early without checking, allowing the test suite to pass when running against compiled spells.

**Rationale**: The flag/argument complexity limits exist to enforce simple spell interfaces in the source code. Compiled spells are deployment artifacts, not source code, and the inlined implementation details don't reflect the actual interface complexity that users interact with.

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

**Status**: ✅ ALL REFACTORED - No remaining exemptions

**Removed/Obsolete**:
- `spellcraft/learn-spell` - Removed (obsolete with word-of-binding paradigm)
- `spellcraft/learn-spellbook` - Removed (replaced by simplified learn spell)
- `cantrips/assertions` - Removed (boot/ test imps already provide assertion functionality)


**Refactored** (52 spells - COMPLETED ✅):
- `spellcraft/lint-magic` (22→2) - Added word-of-binding wrapper function, maintains 0 extra functions beyond usage
- `menu/spellbook` (30→10→4→1) - Major refactor: created 3 reusable imps, inlined single-use functions, removed duplicate scribing functionality (now delegates to scribe-spell), reduced to 2 total functions
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
- `spellcraft/doppelganger` (4→1) - **Eliminated fallback functions (2025-12-17)** - Now uses wizardry imps (say, warn, success) as spells should assume wizardry is installed
- `spellcraft/forget` (6→2)
- `psi/read-contact` (5→4) - Kept 3 helpers (used 3x each)
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
- `divination/identify-room` (7→2) - **Inlined all single-use helpers**, uses detect-distro spell instead of inline platform detection
- `cantrips/cursor-blink` (4→1) - **Inlined trivial helpers** (cursor_blink_on, cursor_blink_off, supports_cursor_control)
- `crypto/hashchant` (4→1) - **Inlined all helpers** (helper_usable, apply_hash, apply_first_available)
- `cantrips/enable-service` (4→1) - **Inlined service helpers** (find_ask_text, run_systemctl, normalize_unit)
- `cantrips/disable-service` (4→1) - **Inlined service helpers** (find_ask_text, run_systemctl, normalize_unit)
- `cantrips/ask-text` (4→1) - **Inlined input logic** (select_input, prompt, read_line)
- `cantrips/ask-number` (4→1) - **Inlined input logic** (select_input, prompt, read_value)
- `arcane/jump-trash` (4→2) - **Inlined helpers** (get_trash_path, cli wrapper); kept jump_trash for sourcing
- `divination/detect-distro` (4→1) - **Inlined all helpers** (os_release_id, detect_uname, file_exists)
- `system/verify-posix` (4→2) - **Inlined collection functions**; kept record_failure (used 8x)
- `cantrips/ask-yn` (3→1) - **Inlined input logic** (select_input, prompt_and_read)
- `cantrips/require-command` (3→1) - **Inlined helpers** (find_install_spell, attempt_install)
- `cantrips/fathom-terminal` (3→2) - **Inlined single-use wrapper**; kept print_dimension (used 5x)
- `cantrips/remove-service` (3→2) - **Inlined find_ask_text**; kept require_privilege (used 4x)
- `enchant/yaml-to-enchantment` (3→2) - **Inlined set_attr**; kept resolve_helper (used 7x)

**Progress**: 57/57 spells refactored (100%) - 3 spells removed as obsolete

**Remaining acceptable cases** (6 spells with 2-3 extra functions):

**Spells with 3 extra functions:**
- `psi/read-contact` (5 functions total): handle_escapes (3x), card_lines (3x), nicer_name (3x) - vCard parsing logic, substantive domain-specific helpers
- `cantrips/menu` (5 functions total): cleanup (8x), render_row (4x), position_cursor_below_menu (3x) - core menu rendering

**Spells with 2 extra functions:**
- `cantrips/await-keypress` (4 functions total): restore_terminal (4x), codes_to_string (5x) - complex terminal state handling
- `menu/mud` (4 functions total): get_portal_location (2x), mud_display_menu (2x) - menu display pattern
- `menu/mud-settings` (4 functions total): has_player_key (2x), mud_settings_display_menu (2x) - menu display pattern
- `menu/main-menu` (4 functions total): is_mud_enabled (2x), main_menu_display_menu (2x) - menu display pattern

**Recently improved:**
- ✅ `menu/mud-menu` (3 functions total, 1 extra): Reduced from 3 extra functions to 1 (removed is_cd_hook_installed, kept is_feature_enabled used 20x)

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

## 7. Word-of-Binding / Wrapper Function Exemptions

### Spells Without Wrapper Functions

**Rule**: All spells must have a wrapper function matching their filename (the "incantation") for word-of-binding compatibility. This enables sourcing spells into the shell for efficient invocation.

**Exempted Categories**:

1. **Arcana spells** (`spells/.arcana/*`)
   - **Reason**: Arcana are installation and configuration scripts that are meant to be executed, not sourced. They manage system-level software installation and are not typically called from other spells.
   - **Status**: Wrapper functions not required for arcana

2. **Source-only spells** (`cantrips/colors`)
   - **Reason**: These spells are designed to be sourced (not executed) to set environment variables in the current shell. Wrapping them in a function would make the variables local to that function and inaccessible to the calling shell.
   - **Status**: Wrapper functions incompatible with sourcing behavior
   - **Example**: `colors` sets `RED`, `GREEN`, `RESET`, etc. as shell variables

**Test**: `test_spells_require_wrapper_functions` in `.tests/common-tests.sh`

**Implementation**: The test excludes paths matching `*/.arcana/*` and `cantrips/colors` from the wrapper function requirement.

**Future**: If specific arcana need to be sourceable (e.g., for testing or composition), they can be updated individually.

---

## 8. All-Caps Variable Assignments (Environment Variable Overrides)

### Policy

**Goal**: 0 all-caps variable assignments in spells. Use lowercase for local variables.

**Export Rule**: Variables should ONLY be exported if they are uppercase (environment variables). Lowercase variables should NEVER be exported.

**Rationale**: 
- All-caps variables in POSIX shell conventionally indicate environment variables
- Using all-caps for local variables creates confusion about scope and can shadow important environment variables
- Exporting lowercase variables violates the convention that exports are environment variables
- Local variables should be lowercase and never exported

**Test**: `test_no_allcaps_variable_assignments` in `.tests/common-tests.sh`

**Detection**: Checks for ALL all-caps variable assignments (not just `export` statements), catching patterns like `VAR=value` that might override environment variables.

**Code Style Rules**:
```sh
# CORRECT - lowercase local variable, not exported
distro=$(detect-distro)
output="$distro"

# CORRECT - uppercase environment variable, exported
export WIZARDRY_DIR=/path/to/wizardry

# WRONG - lowercase variable exported (violates convention)
export distro=linux  # ❌ Never do this

# WRONG - uppercase local variable (creates confusion)
DISTRO=linux  # ❌ Use lowercase unless exporting
```

### Allowed All-Caps Variables

All exemptions documented here for management and eventual elimination.

#### 1. Standard Environment Variables

**Allowed**: Modifying standard environment variables is acceptable when needed.

- `PATH` — Adding directories to search path
- `HOME` — Home directory (rarely modified)
- `TMPDIR` — Temporary directory location
- `IFS` — Field separator (inline with `read` command only)
- `CDPATH` — cd search path (setting to empty for predictable behavior)
- `SHELL`, `EDITOR`, `PAGER`, `VISUAL` — User preference variables

**Examples**:
```sh
PATH="$imps_dir:$PATH"  # Add imps to PATH
IFS= read -r line       # Inline IFS to preserve whitespace
CDPATH= cd "$dir"       # Disable CDPATH for reliable cd
```

#### 2. Package Manager Override Variables

**Allowed**: Used by `pkg-install` to allow callers to specify package names per platform.

- `NIX_PACKAGE`, `APT_PACKAGE`, `DNF_PACKAGE`, `YUM_PACKAGE`
- `ZYPPER_PACKAGE`, `PACMAN_PACKAGE`, `APK_PACKAGE`, `PKGIN_PACKAGE`, `BREW_PACKAGE`

**Context**: Install scripts in `.arcana/` use these to pass platform-specific package names to `pkg-install`.

**Example**:
```sh
export APT_PACKAGE="nodejs"
export DNF_PACKAGE="nodejs"
pkg-install node
```

#### 3. Declared Wizardry Globals

**Allowed**: These are the only project-wide globals (declared in `declare-globals` imp).

- `WIZARDRY_DIR` — Wizardry installation directory
- `SPELLBOOK_DIR` — User's personal spellbook directory
- `MUD_DIR` — MUD feature configuration directory

**Status**: Managed by `declare-globals` imp, must use `set -u` when accessed.

#### 4. RC Detection Variables

**Allowed**: Used by installation and configuration scripts for shell RC file detection.

- `WIZARDRY_PLATFORM` — Detected platform (linux, mac, etc.)
- `WIZARDRY_RC_FILE` — User's shell RC file path
- `WIZARDRY_RC_FORMAT` — RC file format/syntax

**Context**: Used during installation to add wizardry to user's PATH.

#### 5. Test Infrastructure Variables

**Allowed**: Used within test framework for test coordination.

- `TEST_FAILURE_REASON` — Why a test failed
- `TEST_SKIP_REASON` — Why a test was skipped
- `WIZARDRY_TMPDIR` — Test temporary directory
- `WIZARDRY_GLOBAL_SUBTEST_NUM` — Global subtest counter
- `WIZARDRY_TEST_COMPILED` — Flag indicating doppelganger testing
- `WIZARDRY_TEST_HELPERS_ONLY` — Flag for helper-only mode
- `WIZARDRY_SYSTEM_PATH` — System PATH for test isolation

**Context**: Test imps in `spells/.imps/test/` use these for coordination.

#### 6. Feature Flag Variables

**Allowed**: User-configurable feature flags and environment configuration.

- `WIZARDRY_LOG_LEVEL` — Logging verbosity (0=quiet, 1=info, 2=debug)
- `WIZARDRY_DISABLE_SANDBOX` — Disable bubblewrap sandboxing
- `WIZARDRY_BWRAP_WARNING` — Suppress bubblewrap warning
- `WIZARDRY_COLORS_AVAILABLE` — Terminal supports ANSI colors

**Context**: Users set these in their environment to configure wizardry behavior.

#### 7. Bootstrap/Installer Variables

**Allowed**: Variables used by bootstrap scripts before wizardry is fully installed.

- `ASSUME_YES` — Skip confirmation prompts (for automated installation)
- `FORCE_INSTALL` — Force reinstallation of components
- `ROOT_DIR` — Repository root (in install scripts and test-magic)

**Context**: `install` script and `.arcana/core/*` use these before imps are available.

#### 8. Sandbox-Related Variables

**Allowed**: Variables for platform-specific sandboxing configuration.

- `BWRAP_AVAILABLE`, `BWRAP_BIN`, `BWRAP_REASON` — Bubblewrap sandbox status
- `BWRAP_USE_UNSHARE`, `BWRAP_VIA_SUDO` — Bubblewrap configuration
- `MACOS_SANDBOX_AVAILABLE`, `SANDBOX_EXEC_BIN`, `SANDBOX_PLATFORM` — macOS sandbox
- `REAL_SUDO_BIN` — Real sudo path (when testing with stubs)

**Context**: Test infrastructure and security-sensitive operations use sandboxing.

#### 9. Color and Theme Variables

**Allowed**: ANSI escape sequences for terminal styling.

**Source**: Defined in `cantrips/colors` (meant to be sourced).

**Variables**:
- **Colors**: `RED`, `GREEN`, `BLUE`, `YELLOW`, `CYAN`, `WHITE`, `BLACK`, `PURPLE`, `GREY`/`GRAY`, `LIGHT_BLUE`
- **Bright Colors**: `BRIGHT_*` (e.g., `BRIGHT_RED`, `BRIGHT_GREEN`)
- **Backgrounds**: `BG_*` (e.g., `BG_BLACK`, `BG_RED`)
- **Formatting**: `RESET`, `BOLD`, `ITALICS`, `UNDERLINED`, `BLINK`, `INVERT`, `STRIKE`
- **Theme**: `THEME_WARNING`, `THEME_SUCCESS`, `THEME_ERROR`, `THEME_MUTED`, `THEME_HIGHLIGHT`, `THEME_HEADING`, `THEME_DIVIDER`, `THEME_CUSTOM`
- **Escape**: `ESC` — ASCII escape character (used to build sequences)

**Usage Pattern**:
```sh
# Option 1: Source colors
. colors
printf '%sError:%s Message\n' "$RED" "$RESET"

# Option 2: Inline definition (when colors unavailable)
RED=''
RESET=''
if has tput; then
  RED=$(tput setaf 1)
  RESET=$(tput sgr0)
fi
```

**Rationale**: Color variables are intentionally all-caps because:
1. They're meant to be sourced like environment variables
2. ANSI standard uses uppercase (e.g., terminal `$TERM`, `$COLORTERM`)
3. Makes colored output code more readable (inline variables stand out)

#### 10. Cantrip Configuration Variables

**Allowed**: Configuration variables for interactive cantrips.

- `AWAIT_KEYPRESS_KEEP_RAW` — Don't restore terminal after keypress (for chaining)

**Context**: Used by `await-keypress` for terminal state management.

#### 11. Grandfathered Variables (To Be Eliminated)

**Status**: ⚠️ Temporary exemptions in `.arcana/*` only. Production spells fully converted to lowercase.

**Action Required**: Convert remaining `.arcana/*` variables to lowercase in future refactoring.

**Progress Tracking**:

**✅ ELIMINATED from production spells (2025-12-17)**:
- `SCRIPT_DIR` → converted to `script_dir` (was in `system/config`)
- `SCRIPT_NAME` → already eliminated
- `SCRIPT_SOURCE` → already eliminated  
- `LOOK_SCRIPT_PATH` → converted to `look_script_path` (was in `mud/look`)
- `DISTRO` → converted to `distro` (was in `divination/detect-distro`)
- `IMPS_DIR` → converted to `imps_dir` (was in `system/config`)
- `ASK_TEXT_HELPER`, `ASK_TEXT`, `ASK_YN` → already eliminated
- `READ_MAGIC`, `SYSTEMCTL` → already eliminated
- `SERVICE_DIR`, `TTY_DEVICE` → already eliminated
- `MARKERS_DIR`, `CONTACTS_DIR`, `MUD_CONFIG`, `MUD_*` → already eliminated
- `MISSING_ATTR_MSG`, `IDENTIFY_*` → already eliminated
- `STATUS`, `VERBOSE`, `RUNNING_AS_SCRIPT` → already eliminated from production (STATUS remains in test infrastructure only)
- `ERROR`, `OUTPUT`, `KEY`, `HELPER`, `FILE`, `DIR` → already eliminated from production (ERROR/OUTPUT remain in test infrastructure only)
- `OS`, `RC_CANDIDATES`, `TORRC_PATHS` → already eliminated
- `IMPS_TEXT_DIR`, `CONFIG_FILE`, `FEATURES` → already eliminated
- `MIN_SUBTESTS_*`, `CLIPBOARD_MARKER` → already eliminated
- `RUN_CMD_WORKDIR`, `PS_NAMES`, `SCRIPT` → already eliminated from production (RUN_CMD_WORKDIR remains in test infrastructure only)
- `BITCOIN_VERSION_DEFAULT` → already eliminated

**Remaining in `.arcana/*` bootstrap/installation scripts** (exempt category):
- Various installation-specific variables in `.arcana/*` files
- These follow different conventions as bootstrap scripts (documented exemption in section 11)

**Test Infrastructure Variables** (properly exempt):
- `STATUS`, `ERROR`, `OUTPUT` in `spells/.imps/test/boot/run-cmd` — Test framework coordination
- `RUN_CMD_WORKDIR` in `spells/.imps/test/boot/run-spell-in-dir` — Test working directory control
- These are intentionally all-caps as they coordinate test execution and are part of test infrastructure

**Files Affected**: Only `.arcana/*` bootstrap/installation scripts remain (which are exempt from this check).

**Elimination Strategy**:
1. **Phase 1**: Document all current usage (✅ COMPLETE)
2. **Phase 2**: Convert production spells (✅ COMPLETE — 2025-12-17)
3. **Phase 3**: Tests enforce lowercase in production spells (✅ ACTIVE)
4. **Phase 4**: Future work - standardize `.arcana/*` scripts (deferred as they're exempt)

**Summary**: **All production spells now use lowercase variables.** Only `.arcana/*` bootstrap scripts (which are exempt) may still contain all-caps variables. The test suite enforces this policy going forward.

### Files Exempt from All-Caps Check

- `cantrips/colors` — Intentionally sets all-caps color variables for sourcing
- `spells/.imps/test/*` — Test infrastructure files
- `spells/.arcana/*` — Bootstrap/installation scripts (different context)

### Adding New All-Caps Variables

**Policy**: New all-caps variables are **PROHIBITED** unless:

1. They modify a standard environment variable (PATH, HOME, etc.)
2. They're in a bootstrap/installation script (`.arcana/*`)
3. They're in test infrastructure (`test/`)
4. They're color variables (rare, must be justified)

**Process**:
1. Justify why lowercase won't work
2. Document in EXEMPTIONS.md with justification
3. Add to test exemption list
4. Get PR approval

**Remember**: The goal is **0 all-caps variables** in production spells. Use lowercase for all local variables.

---

## Completed Exemptions Checklist

This section documents all exemptions that have been successfully resolved. Items are maintained here to prevent backsliding and to track project improvements over time.

### ✅ Style Exemptions (COMPLETED)

- [x] **Long Lines (>100 chars)** - All hardcoded exemptions eliminated (2025-12-17)
  - [x] `spells/.imps/cond/is` line 13 - Refactored to multi-line format
  - [x] `spells/divination/identify-room` lines 112, 263 - Refactored complex conditionals and split long directory lists
  - **Result**: 353/353 files compliant, 0 hardcoded exemptions

- [x] **Mixed Tabs/Spaces** - All files resolved (commit 4463607)
  - [x] 8 files converted to 2-space indentation
  - **Result**: Consistent indentation across entire codebase

### ✅ Shebang Standardization (COMPLETED 2025-12-11)

- [x] **Alternative Shebangs (`#!/usr/bin/env sh`)** - 38 files converted to `#!/bin/sh`
  - [x] Cantrips (10 files): `assertions`, `colors`, `cursor-blink`, `fathom-cursor`, `fathom-terminal`, `max-length`, `menu`, `move-cursor`, `require-command`, `require-wizardry`
  - [x] System/Menu (3 files): `divination/detect-distro`, `system/update-all`, `menu/install-menu`
  - [x] Arcana (25 files): All `.arcana/core/*` install/uninstall scripts (24 files), plus `tor/setup-tor`
  - **Reason**: Standardized on single shebang format across entire project

- [x] **Bash Tutorials (`#!/bin/bash`)** - 5 files converted to `#!/bin/sh`
  - [x] `tutorials/26_history.sh`
  - [x] `tutorials/28_distribution.sh`
  - [x] `tutorials/29_ssh.sh`
  - [x] `tutorials/30_git.sh`
  - [x] `tutorials/31_usability.sh`
  - **Reason**: Educational materials should exemplify project standards

### ✅ Function Discipline (COMPLETED)

- [x] **Spells with 4+ Additional Functions** - All 57 spells refactored to 0-3 additional functions
  - [x] Removed/obsolete spells (3): `spellcraft/learn-spell`, `spellcraft/learn-spellbook`, `cantrips/assertions`
  - [x] Major refactors (54 spells): Created reusable imps, inlined single-use functions, delegated to existing spells
  - **Result**: 0 spells with 4+ extra functions (was 57 violations)
  - **Remaining**: 6 spells with 2-3 extra functions (acceptable per guidelines)

### ✅ All-Caps Variables (COMPLETED December 2025)

- [x] **Production Spells** - All converted to lowercase for local variables
  - [x] `SCRIPT_DIR` → `script_dir`
  - [x] `LOOK_SCRIPT_PATH` → `look_script_path`
  - [x] `DISTRO` → `distro`
  - [x] `IMPS_DIR` → `imps_dir`
  - [x] All other local variables in production spells
  - **Result**: All production spells use lowercase. Only `.arcana/*` bootstrap scripts (exempt category) may use all-caps.

### ✅ Recent Improvements

- [x] **`menu/mud-menu`** - Reduced from 3 extra functions to 1 (2025-12-17)
  - Removed `is_cd_hook_installed` function
  - Kept `is_feature_enabled` (used 20x throughout the spell)
  - **Result**: Now compliant with guidelines (1 extra function is acceptable)

### Summary

**Total Exemptions Eliminated:**
- Style: 100% (all long lines and mixed indentation fixed)
- Shebangs: 43 files standardized to `#!/bin/sh`
- Function Discipline: 57 spells refactored from 4+ to 0-3 extra functions
- All-Caps Variables: All production spells converted to lowercase
- CI: 0 exemptions (all checks required)

**Current Status:**
- **0 unresolved style issues**
- **0 spells with 4+ extra functions**
- **0 all-caps variables in production spells**
- **6 spells with acceptable 2-3 extra functions** (within guidelines)


