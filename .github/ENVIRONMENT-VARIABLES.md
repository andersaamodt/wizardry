# Environment Variable Overrides

This document lists all instances where spells expect environment variables to be overridden, with justifications for each.

## Declared Globals (from `spells/.imps/declare-globals`)

These are the only approved global environment variables in wizardry:

1. **`WIZARDRY_DIR`** - Installation root directory path
   - **Justification**: Required for spells to locate resources relative to install location
   - **Used by**: Core infrastructure for resource resolution

2. **`SPELLBOOK_DIR`** - User's personal spellbook directory
   - **Justification**: Required for coordinating custom spell storage across multiple spells
   - **Used by**: Spellbook management spells

3. **`MUD_DIR`** - MUD configuration directory
   - **Justification**: Required for MUD features to share room descriptions and settings
   - **Used by**: MUD feature spells

## Infrastructure Variables

### `WIZARDRY_LOG_LEVEL`
- **Location**: Used by logging imps (`info`, `debug`, `step`)
- **Purpose**: Controls verbosity of output (0=critical only, 1=info, 2=debug)
- **Justification**: Standard infrastructure variable for consistent logging across all spells
- **Status**: ✅ Approved - Infrastructure variable

## POSIX Standard Variables

The following POSIX standard variables are allowed for override:
- `PATH`, `HOME`, `IFS`, `CDPATH`, `PWD`, `OLDPWD`, `TERM`, `SHELL`, `USER`, `LOGNAME`, `TMPDIR`
- `LANG`, `LC_*`, `TZ`, `DISPLAY`, `EDITOR`, `PAGER`, `VISUAL`, `MAIL`, `PS1-4`, `COLUMNS`, `LINES`
- `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `SSHD_CONFIG` (platform-specific standards)

## Test Infrastructure Variables

The following are only used in test infrastructure:
- `WIZARDRY_TEST_HELPERS_ONLY`, `WIZARDRY_TMPDIR`, `WIZARDRY_SYSTEM_PATH`
- `BWRAP_*`, `SANDBOX_*`, `MACOS_SANDBOX_*`
- These are excluded from the linting check

## Configuration Variables Using Overrides (Legacy Pattern)

These use the pattern `var=${ENV_VAR:-default}` to allow optional override:

### User-facing Override Patterns
1. **`XDG_DATA_HOME`** (Standard)
   - Used in: `spells/arcane/jump-trash`, `spells/menu/cast`, `spells/menu/spell-menu`
   - Justification: XDG Base Directory Specification standard

2. **`TMPDIR`** (Standard)
   - Used in: Multiple spells for temporary file creation
   - Justification: POSIX standard for temporary directory location

3. **`SSHD_CONFIG`** (Platform-specific)
   - Used in: `spells/wards/ssh-barrier`
   - Justification: SSH daemon config location varies by platform

4. **`WIZARD`** (UI Mode)
   - Used in: `spells/cantrips/wizard-eyes`
   - Justification: Controls verbose output mode for debugging
   - Status: ⚠️ Could be replaced with `--verbose` flag

5. **`MUD_PLAYER`** (MUD Configuration)
   - Used in: `spells/translocation/open-portal`, `spells/translocation/open-teletype`, `spells/mud/select-player`
   - Justification: User's MUD identity for SSH connections
   - Status: ⚠️ Should probably be stored in MUD_DIR configuration file

### Test/Debug Override Patterns
1. **`MENU_LOOP_LIMIT`**
   - Used in: Various menu spells
   - Justification: Testing infinite loop prevention
   - Status: ✅ Approved for testing

2. **`ASK_CANTRIP_INPUT`**
   - Used in: `spells/cantrips/ask-text`, `spells/cantrips/ask-number`
   - Justification: Automated testing of interactive prompts
   - Status: ✅ Approved for testing

3. **`REQUIRE_COMMAND_ASSUME_YES`**
   - Used in: `spells/cantrips/require-command`
   - Justification: Non-interactive installation mode
   - Status: ⚠️ Should use `--yes` flag instead

4. **`AWAIT_KEYPRESS_DEVICE`**
   - Used in: `spells/cantrips/menu`
   - Justification: Override TTY device for testing
   - Status: ✅ Approved for testing

5. **Various helper path overrides** (Pattern: `*_PATH`, `*_HELPER`)
   - Used in: Multiple spells for test stubbing
   - Justification: Test isolation and mocking
   - Status: ✅ Approved for testing

### Install/Configuration Override Patterns
1. **`INSTALL_MENU_ROOT`**
   - Used in: `spells/menu/install-menu`
   - Justification: Alternative arcana directory for development
   - Status: ⚠️ Could use `--root` flag

2. **`CHECKBASHISMS`**
   - Used in: `spells/spellcraft/lint-magic`
   - Justification: Override checkbashisms command location
   - Status: ⚠️ Could use standard tool detection pattern

## Internal Variables (Lowercase)

The following patterns use lowercase for internal state and are compliant:
- `script_name`, `script_dir`, `markers_dir`, `contacts_dir`, etc.
- These do NOT expect environment override and follow project standards

## Recommendations

1. **Add to declare-globals**: `WIZARDRY_PLATFORM`, `WIZARDRY_RC_FILE`, `WIZARDRY_RC_FORMAT`, `WIZARDRY_MEMORIZE_TARGET`
2. **Refactor to flags**: `WIZARD`, `REQUIRE_COMMAND_ASSUME_YES`, `INSTALL_MENU_ROOT`
3. **Move to configuration files**: `MUD_PLAYER`
4. **Keep as-is**: Bootstrap spell DISTRO, color interface, test infrastructure, POSIX standards
