# Wizardry Spell Levels - Spiral Debug Organization

## Overview

This document organizes all wizardry spells into **Spell Levels** - a hierarchical structure where each level builds on the previous ones. This organization supports the enhanced `banish` spell, which can validate and test each level incrementally.

The spiral organization starts from the most fundamental prerequisites (Level 0) and spirals outward through increasingly complex and specialized spells. Each level includes:
- **Assumptions** to check
- **Spells** and their **imp dependencies**
- **Tests** corresponding to those spells

## Banish Integration

The `banish` spell integrates assumption-checking, self-healing, and testing:

```bash
banish           # Banish to level 0 (default) - validate system foundation
banish 0         # Same as above
banish 1         # Banish through levels 0-1 (menu core ready)
banish 2         # Banish through levels 0-2 (arcane spells ready)
banish N         # Banish through levels 0-N (full system validated)
```

Each `banish N` command:
1. Recursively runs previous levels (banish 2 → runs 0, 1, then 2)
2. Checks assumptions for that level
3. Offers to self-heal broken assumptions (with user confirmation)
4. Runs tests for spells at that level (with user confirmation)

---

## Level 0: System Foundation

**Purpose**: Validate the system foundation. This level checks the basic POSIX environment, detects OS information, verifies system-foundational assumptions, and confirms wizardry is properly installed. While this level can help diagnose pre-install issues, banish is designed to run AFTER wizardry is installed.

### Assumptions
- [ ] POSIX shell available (`sh`)
- [ ] Core POSIX utilities available: `printf`, `test`, `command`
- [ ] Path utilities: `dirname`, `basename`, `cd`, `pwd`
- [ ] File utilities: `cat`, `grep`, `find`, `sort`
- [ ] Text processing: `awk`, `sed`
- [ ] Temporary files: `mktemp`
- [ ] Standard PATH includes `/bin`, `/usr/bin`, etc.
- [ ] Either `curl` or `wget` available (for install)
- [ ] `tar` available (for install)
- [ ] Operating system detectable via `uname`
- [ ] Package manager available for self-healing
- [ ] Distribution identifiable (Linux only)

### Self-Healing Actions
- Detect operating system and distribution
- Install missing package manager if none found (platform-specific)
- Install missing core utilities via package manager (with user confirmation)
- Set baseline PATH if missing standard directories
- Report critical failures that cannot be auto-healed
- Offer to install missing recommended tools

### Spells
- `spells/system/banish` - The validation spell itself
- Detection spells used by banish level 0:
  - `spells/divination/detect-posix` - POSIX toolchain validation
  - `spells/divination/detect-distro` - OS distribution detection

### Imps Used by Level 0 Spells
**Note**: Level 0 assumes wizardry is installed. The banish spell itself can work with minimal dependencies for bootstrapping scenarios, but is designed for post-install validation.

### Detection Capabilities (Optional)
If wizardry is already installed, Level 0 can use:
- `spells/divination/detect-posix` - Probe POSIX toolchain
- `spells/divination/detect-distro` - Detect Linux distribution
- `spells/system/verify-posix` - Verify POSIX environment

### Tests
- `.tests/system/test-banish.sh` - Test banish level 0 functionality
- Manual verification: Can `./install` succeed after `banish 0`?
- Test OS detection on multiple platforms
- Test package manager detection
- Test self-healing with missing tools

---

## Level 1: Menu Core

**Purpose**: The interactive menu system - the primary user interface to wizardry. This is the minimum viable wizardry installation.

### Assumptions
- [ ] Wizardry is installed (WIZARDRY_DIR is set)
- [ ] invoke-wizardry available and sourceable
- [ ] Terminal supports ANSI escape codes
- [ ] TTY is readable/writable
- [ ] `stty` command available (for terminal control)

### Self-Healing Actions
- Install `stty` if missing (via pkg-install)
- Verify invoke-wizardry can be sourced
- Check terminal capabilities
- Fall back to basic menu if ANSI codes unavailable

### Core Spell
- `spells/cantrips/menu` - Interactive menu system

### Menu Dependencies (in dependency order)
1. `spells/cantrips/fathom-terminal` - Measure terminal size
2. `spells/cantrips/fathom-cursor` - Get cursor position  
3. `spells/cantrips/move-cursor` - Move cursor to position
4. `spells/cantrips/await-keypress` - Read keyboard input
5. `spells/cantrips/cursor-blink` - Control cursor visibility
6. `spells/cantrips/colors` - Terminal color codes
7. `spells/menu/main-menu` - Top-level menu content

### Imps Used by Level 1 Spells

#### Core System Imps
- `sys/require-wizardry` - Check wizardry availability
- `sys/require` - Check command/spell availability
- `sys/castable` - Make spell both executable and sourceable
- `sys/env-clear` - Clear environment variables
- `sys/on-exit` - Register cleanup on exit
- `sys/clear-traps` - Clear signal traps

#### Conditional Imps  
- `cond/has` - Check if command exists
- `cond/there` - Check if path exists
- `cond/is` - Generic conditional check
- `cond/empty` - Check if string/file is empty
- `cond/nonempty` - Check if string/file is non-empty

#### Output Imps
- `out/say` - Print message to stdout
- `out/warn` - Print warning to stderr
- `out/die` - Print error and exit
- `out/fail` - Print error and return failure
- `out/info` - Print informational message
- `out/step` - Print step in process
- `out/success` - Print success message
- `out/debug` - Print debug message

#### Filesystem Imps
- `fs/temp-file` - Create temporary file
- `fs/temp-dir` - Create temporary directory
- `fs/cleanup-file` - Remove file safely
- `fs/cleanup-dir` - Remove directory safely

#### Input Imps
- `input/tty-save` - Save terminal state
- `input/tty-restore` - Restore terminal state
- `input/tty-raw` - Set terminal to raw mode
- `input/read-line` - Read line of input

#### String Imps
- `str/contains` - Check if string contains substring
- `str/trim` - Trim whitespace from string
- `str/equals` - Test string equality
- `str/starts` - Check if string starts with prefix
- `str/ends` - Check if string ends with suffix

#### Path Imps
- `paths/here` - Get current directory
- `paths/parent` - Get parent directory
- `paths/file-name` - Get file name from path
- `paths/abs-path` - Get absolute path

#### Menu-specific Imps
- `menu/is-submenu` - Check if entry is a submenu
- `menu/is-integer` - Check if value is integer
- `menu/category-title` - Format category title
- `menu/exit-label` - Format exit menu label

### Tests
- `.tests/cantrips/test-menu.sh` - Menu functionality
- `.tests/cantrips/test-await-keypress.sh` - Keyboard input
- `.tests/cantrips/test-fathom-cursor.sh` - Cursor position
- `.tests/cantrips/test-fathom-terminal.sh` - Terminal size
- `.tests/cantrips/test-move-cursor.sh` - Cursor movement
- `.tests/cantrips/test-cursor-blink.sh` - Cursor visibility
- `.tests/cantrips/test-colors.sh` - Color codes
- `.tests/menu/test-main-menu.sh` - Main menu content
- All imp tests in `.tests/.imps/` for imps listed above

---

## Level 2: Arcane Spells (File Operations)

**Purpose**: Core file and directory manipulation spells used throughout wizardry.

### Assumptions
- [ ] Level 1 complete (menu works)
- [ ] File system is readable/writable
- [ ] Standard UNIX file utilities work (`cp`, `mv`, `rm`, `find`)

### Self-Healing Actions
- Verify file system permissions
- Check disk space for temporary operations
- Install missing file utilities if needed

### Spells
- `spells/arcane/copy` - Copy files/directories
- `spells/arcane/trash` - Move to trash (safe delete)
- `spells/arcane/jump-trash` - Jump to trash directory
- `spells/arcane/forall` - Execute command for each item
- `spells/arcane/read-magic` - Read extended attributes
- `spells/arcane/file-list` - List files with details

### Additional Imps Introduced
- `fs/backup` - Backup file before modification
- `fs/xattr-helper-usable` - Check extended attributes support
- `fs/xattr-list-keys` - List xattr keys
- `fs/xattr-read-value` - Read xattr value
- `menu/detect-trash` - Detect trash directory location
- `text/read-file` - Read file contents
- `text/write-file` - Write file contents
- `text/lines` - Split text into lines
- `text/each` - Process each line

### Tests
- `.tests/arcane/test-copy.sh`
- `.tests/arcane/test-trash.sh`
- `.tests/arcane/test-jump-trash.sh`
- `.tests/arcane/test-forall.sh`
- `.tests/arcane/test-read-magic.sh`
- `.tests/arcane/test-file-list.sh`

---

## Level 3: Cantrips (User Interaction)

**Purpose**: Simple interactive spells for user input and basic operations.

### Assumptions
- [ ] Level 2 complete (arcane spells work)
- [ ] Terminal supports interactive input
- [ ] User can respond to prompts

### Self-Healing Actions
- Verify TTY is interactive
- Check terminal supports required features
- Fall back to simple prompts if needed

### Spells
- `spells/cantrips/ask` - Generic prompt
- `spells/cantrips/ask-yn` - Yes/no question
- `spells/cantrips/ask-number` - Numeric input
- `spells/cantrips/ask-text` - Text input
- `spells/cantrips/list-files` - List files in directory
- `spells/cantrips/max-length` - Find maximum line length
- `spells/cantrips/move` - Move file/directory
- `spells/cantrips/memorize` - Add spell to shell rc

### Additional Imps Introduced
- `input/select-input` - Select from options
- `input/validate-command` - Validate command name
- `input/validate-name` - Validate file name
- `lex/parse` - Parse command line
- `lex/from` - Extract from delimiter
- `lex/to` - Extract to delimiter
- `lex/and` - Logical AND
- `lex/or` - Logical OR

### Tests
- `.tests/cantrips/test-ask.sh`
- `.tests/cantrips/test-ask-yn.sh`
- `.tests/cantrips/test-ask-number.sh`
- `.tests/cantrips/test-ask-text.sh`
- `.tests/cantrips/test-list-files.sh`
- `.tests/cantrips/test-max-length.sh`
- `.tests/cantrips/test-move.sh`
- `.tests/cantrips/test-memorize.sh`

---

## Level 4: System Spells (Configuration & Testing)

**Purpose**: System-level configuration, testing, and verification spells.

### Assumptions
- [ ] Level 3 complete (cantrips work)
- [ ] Write access to config files
- [ ] Test infrastructure available

### Self-Healing Actions
- Create config directory if missing
- Set proper permissions on config files
- Verify test infrastructure

### Spells
- `spells/system/config` - Manage configuration
- `spells/system/test-magic` - Run all tests
- `spells/system/test-spell` - Run single test
- `spells/system/demonstrate-wizardry` - Demo system
- `spells/system/verify-posix` - Verify POSIX compliance
- `spells/system/logs` - View wizardry logs
- `spells/system/update-wizardry` - Update wizardry
- `spells/system/update-all` - Update everything
- `spells/system/kill-process` - Kill process by name
- `spells/system/package-managers` - Manage packages

### Additional Imps Introduced
- `fs/config-get` - Get config value
- `fs/config-set` - Set config value
- `fs/config-has` - Check config key exists
- `fs/config-del` - Delete config key
- `sys/rc-add-line` - Add line to rc file
- `sys/rc-has-line` - Check if rc has line
- `sys/rc-remove-line` - Remove line from rc
- `test/*` - All test framework imps

### Tests
- `.tests/system/test-config.sh`
- `.tests/system/test-test-magic.sh`
- `.tests/system/test-test-spell.sh`
- `.tests/system/test-demonstrate-wizardry.sh`
- `.tests/system/test-verify-posix.sh`
- `.tests/system/test-logs.sh`
- `.tests/system/test-update-wizardry.sh`
- `.tests/system/test-update-all.sh`
- `.tests/system/test-kill-process.sh`
- `.tests/system/test-package-managers.sh`

---

## Level 5: Divination Spells (Detection & Analysis)

**Purpose**: Detection and analysis spells for system information.

### Assumptions
- [ ] Level 4 complete (system spells work)
- [ ] System information accessible
- [ ] Platform-specific tools available

### Self-Healing Actions
- Install platform detection tools if missing
- Verify system information sources
- Fall back to generic detection if needed

### Spells
- `spells/divination/detect-posix` - Detect POSIX tools
- `spells/divination/detect-distro` - Detect OS distribution
- `spells/divination/detect-rc-file` - Detect shell rc file
- `spells/divination/detect-magic` - Detect file metadata

### Additional Imps Introduced
- `sys/os` - Get operating system name
- `sys/term` - Get terminal type
- `text/detect-indent-char` - Detect indentation character
- `text/detect-indent-width` - Detect indentation width

### Tests
- `.tests/divination/test-detect-posix.sh`
- `.tests/divination/test-detect-distro.sh`
- `.tests/divination/test-detect-rc-file.sh`
- `.tests/divination/test-detect-magic.sh`

---

## Level 6: MUD Spells (Multi-User Dungeon Features)

**Purpose**: Fantasy MUD-themed features - rooms, items, navigation.

### Assumptions
- [ ] Level 5 complete (divination works)
- [ ] Extended attributes supported (or fallback available)
- [ ] User wants MUD features enabled

### Self-Healing Actions
- Check extended attribute support
- Offer to install xattr tools if missing
- Set up MUD directory structure
- Configure CD hook if desired

### Spells
- All spells in `spells/mud/`
- CD hook integration
- Command-not-found hook integration

### Tests
- All tests in `.tests/mud/`

---

## Level 7: Specialized Spells (Domain-Specific)

**Purpose**: Specialized functionality for specific use cases.

### Categories

#### Cryptography (`spells/crypto/`)
- Password management
- Encryption/decryption
- Key generation

#### Translocation (`spells/translocation/`)
- SSH management
- Remote file operations
- Network mounting

#### Priorities (`spells/priorities/`)
- Task management
- Priority scheduling
- Time tracking

#### Wards (`spells/wards/`)
- Security monitoring
- Permission management
- Access control

#### Enchant (`spells/enchant/`)
- File attribute management
- Metadata manipulation
- Extended attributes

#### PSI (`spells/psi/`)
- Process management
- System monitoring
- Performance analysis

#### Spellcraft (`spells/spellcraft/`)
- Spell development tools
- Linting and validation
- Spell creation helpers

### Tests
- All tests in respective `.tests/` subdirectories

---

## Level 8: Optional Arcana (Third-Party Integrations)

**Purpose**: Optional third-party software integrations.

### Spells
- All spells in `spells/.arcana/`
- Bitcoin integration
- Tor integration
- Lightning network
- SimpleX chat
- Node.js tools
- And more...

### Tests
- Tests in `.tests/.arcana/` (where applicable)
- Many arcana spells are install-only

---

## Level 9: Service Management

**Purpose**: System service installation and management.

### Spells
- `spells/cantrips/install-service-template` - Service template
- `spells/cantrips/enable-service` - Enable system service
- `spells/cantrips/disable-service` - Disable system service
- `spells/cantrips/is-service-installed` - Check service status

### Tests
- Service-related tests in `.tests/cantrips/`

---

## Testing Strategy

Each level's tests should be run in order:

1. **Unit tests** - Test individual spells in isolation
2. **Integration tests** - Test spell interactions within level
3. **Cross-level tests** - Test dependencies across levels
4. **Smoke tests** - Quick validation all core features work

The `banish` spell automates this by running all tests for levels 0 through N when `banish N` is executed.

---

## Dependency Graph Summary

```
Level 0: Pre-Install Foundation
    └── POSIX tools, environment setup
        │
Level 1: Menu Core
    ├── menu (core UI)
    ├── await-keypress, fathom-*, move-cursor, cursor-blink
    ├── colors, main-menu
    └── Core imps (require, has, say, die, temp-file, etc.)
        │
Level 2: Arcane Spells
    ├── copy, trash, forall, read-magic, file-list
    └── File/xattr imps
        │
Level 3: Cantrips
    ├── ask-*, list-files, move, memorize
    └── Input/validation imps
        │
Level 4: System Spells
    ├── config, test-magic, test-spell, update-*
    └── Config/rc/test imps
        │
Level 5: Divination
    ├── detect-posix, detect-distro, detect-rc-file
    └── Detection imps
        │
Level 6: MUD Features
    ├── MUD-specific spells
    └── Extended attributes, hooks
        │
Level 7: Specialized
    ├── crypto, translocation, priorities, wards, enchant, psi, spellcraft
    └── Domain-specific imps
        │
Level 8: Arcana
    ├── Third-party integrations
    └── Optional install scripts
        │
Level 9: Services
    └── Service management spells
```

---

## Usage Examples

```bash
# Prepare system for wizardry install
banish 0

# Prepare system and verify menu works
banish 1

# Prepare system, menu, and arcane spells
banish 2

# Prepare everything through system spells
banish 4

# Full system validation
banish 9

# Verbose mode shows all checks and tests
banish --verbose 2

# Skip tests, just check assumptions
banish --no-tests 3

# Skip self-healing prompts, just report
banish --no-heal 1
```

---

## Implementation Notes

### Banish Enhancement TODO

1. **Parse level argument** - Default to 0, support 0-9
2. **Recursive execution** - Level N runs 0..(N-1) first
3. **Assumption checking** - Per-level assumption validation
4. **Interactive self-healing** - Prompt user before fixes
5. **Test execution** - Run level-appropriate tests
6. **Progress reporting** - Show what's being checked/fixed
7. **Error handling** - Graceful failures with helpful messages
8. **Logging** - Record what was checked/fixed/tested

### Backward Compatibility

- `banish` with no arguments remains level 0 (current behavior)
- `banish --verbose` continues to work
- `banish --wizardry-dir DIR` continues to work
- All existing flags honored at all levels

---

## Future Enhancements

- **Auto-detect needed level** - Analyze which spells are used, suggest level
- **Partial re-banish** - Re-run only failed assumptions
- **Banish report** - Generate HTML/markdown report of system state
- **CI integration** - Use banish levels in CI pipelines
- **Level aliases** - `banish core` = `banish 1`, `banish full` = `banish 9`
