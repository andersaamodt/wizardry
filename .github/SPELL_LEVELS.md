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
banish 2         # Banish through levels 0-2 (arcane spells and basic MUD ready)
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
* banish - The validation spell itself
* detect-posix - POSIX toolchain validation
* detect-distro - OS distribution detection

### Imps Used by Level 0 Spells
**Note**: Level 0 assumes wizardry is installed. The banish spell itself can work with minimal dependencies for bootstrapping scenarios, but is designed for post-install validation.

#### Critical Infrastructure Imps
- `sys/invoke-wizardry` - Shell integration system (sources spells into shell)
- `sys/require-wizardry` - Check wizardry availability
- Basic output imps (`out/say`, `out/warn`, `out/die`)
- Basic conditional imps (`cond/has`, `cond/there`)

### Detection Capabilities (Optional)
If wizardry is already installed, Level 0 can use:
* detect-posix - Probe POSIX toolchain
* detect-distro - Detect Linux distribution
* verify-posix - Verify POSIX environment

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
* menu (fathom-terminal, fathom-cursor, move-cursor, await-keypress, cursor-blink, colors) - Interactive menu system

### Menu Dependencies (in dependency order)
* fathom-terminal - Measure terminal size
* fathom-cursor - Get cursor position  
* move-cursor - Move cursor to position
* await-keypress - Read keyboard input
* cursor-blink - Control cursor visibility
* colors - Terminal color codes
* main-menu - Top-level menu content (menu)

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

## Level 2: MUD Basics

**Purpose**: Basic MUD integration - directory navigation awareness and CD hook management.

### Assumptions
- [ ] Level 1 complete (menu works)
- [ ] Extended attributes supported (or fallback available)

### Self-Healing Actions
- Check extended attribute support  
- Offer to install xattr tools if missing

### Spells
* check-cd-hook - Check if CD hook is installed
* look (read-magic from Level 4) - Display location's title and description

### Additional Imps Introduced
- `fs/xattr-helper-usable` - Check extended attributes support
- `fs/xattr-list-keys` - List xattr keys
- `fs/xattr-read-value` - Read xattr value

### Tests
- `.tests/mud/test-check-cd-hook.sh`
- `.tests/mud/test-look.sh`

---

## Level 3: Navigation

**Purpose**: Bookmark-based navigation system for quick directory teleportation.

### Assumptions
- [ ] Level 2 complete (MUD basics work)
- [ ] Marker directory can be created

### Self-Healing Actions
- Create marker directory if missing

### Spells
* jump-to-marker - Teleport to bookmarks
* mark-location - Record location bookmarks

### Tests
- `.tests/translocation/test-jump-to-marker.sh`
- `.tests/translocation/test-mark-location.sh`

---

## Level 4: Arcane File Operations

**Purpose**: Core file and directory manipulation spells.

### Assumptions
- [ ] Level 3 complete (navigation works)
- [ ] File system is readable/writable
- [ ] Standard UNIX file utilities work (`cp`, `mv`, `rm`, `find`)

### Self-Healing Actions
- Verify file system permissions
- Check disk space for temporary operations
- Install missing file utilities if needed

### Spells
* copy - Copy files/directories
* trash - Move to trash (safe delete)
* jump-trash (trash) - Jump to trash directory
* forall - Execute command for each item
* read-magic - Read extended attributes
* file-list - List files with details

### Additional Imps Introduced
- `fs/backup` - Backup file before modification
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

## Level 5: Basic Cantrips

**Purpose**: Simple interactive spells for user input and basic operations.

### Assumptions
- [ ] Level 4 complete (file operations work)
- [ ] Terminal supports interactive input
- [ ] User can respond to prompts

### Self-Healing Actions
- Verify TTY is interactive
- Check terminal supports required features
- Fall back to simple prompts if needed

### Spells
* ask - Generic prompt
* ask-yn (ask) - Yes/no question
* ask-text (ask) - Text input
* list-files - List files in directory
* max-length - Find maximum line length
* move - Move file/directory
* up - Navigate up directory levels

### Additional Imps Introduced
- `input/select-input` - Select from options
- `lex/parse` - Parse command line
- `lex/from` - Extract from delimiter
- `lex/to` - Extract to delimiter

### Tests
- `.tests/cantrips/test-ask.sh`
- `.tests/cantrips/test-ask-yn.sh`
- `.tests/cantrips/test-ask-text.sh`
- `.tests/cantrips/test-list-files.sh`
- `.tests/cantrips/test-max-length.sh`
- `.tests/cantrips/test-move.sh`

---

## Level 6: Validation Helpers

**Purpose**: Input validation and requirement checking.

### Assumptions
- [ ] Level 5 complete (basic cantrips work)

### Spells
* validate-number - Validate numeric input
* validate-path - Validate file path
* require-command - Require command availability

### Additional Imps Introduced
- `input/validate-command` - Validate command name
- `input/validate-name` - Validate file name
- `lex/and` - Logical AND
- `lex/or` - Logical OR

### Tests
- `.tests/cantrips/test-validate-number.sh` (if exists)
- `.tests/cantrips/test-validate-path.sh` (if exists)

---

## Level 7: Advanced Cantrips

**Purpose**: More complex user interaction spells that build on validation.

### Assumptions
- [ ] Level 6 complete (validation works)

### Spells
* ask-number (ask from Level 5, validate-number from Level 6) - Numeric input
* memorize - Add spell to shell rc

### Tests
- `.tests/cantrips/test-ask-number.sh`
- `.tests/cantrips/test-memorize.sh`

---

## Level 8: System Configuration

**Purpose**: System-level configuration management.

### Assumptions
- [ ] Level 7 complete (advanced cantrips work)
- [ ] Write access to config files

### Self-Healing Actions
- Create config directory if missing
- Set proper permissions on config files

### Spells
* config - Manage configuration
* logs - View wizardry logs
* package-managers - Manage packages

### Additional Imps Introduced
- `fs/config-get` - Get config value
- `fs/config-set` - Set config value
- `fs/config-has` - Check config key exists
- `fs/config-del` - Delete config key

### Tests
- `.tests/system/test-config.sh`
- `.tests/system/test-logs.sh`
- `.tests/system/test-package-managers.sh`

---

## Level 9: Testing Infrastructure

**Purpose**: Test execution and validation framework.

### Assumptions
- [ ] Level 8 complete (config works)
- [ ] Test infrastructure available

### Self-Healing Actions
- Verify test infrastructure

### Spells
* test-spell - Run single test
* test-magic (test-spell) - Run all tests
* logging-example - Tutorial for logging framework
* wizard-eyes - Enhanced spell inspection

### Additional Imps Introduced
- `test/*` - All test framework imps
- `sys/rc-add-line` - Add line to rc file
- `sys/rc-has-line` - Check if rc has line
- `sys/rc-remove-line` - Remove line from rc

### Tests
- `.tests/system/test-test-spell.sh`
- `.tests/system/test-test-magic.sh`

---

## Level 10: System Maintenance

**Purpose**: System updates and process management.

### Assumptions
- [ ] Level 9 complete (testing works)

### Spells
* update-wizardry - Update wizardry
* update-all (update-wizardry) - Update everything
* kill-process - Kill process by name

### Tests
- `.tests/system/test-update-wizardry.sh`
- `.tests/system/test-update-all.sh`
- `.tests/system/test-kill-process.sh`

---

## Level 11: Advanced System Tools

**Purpose**: Advanced system validation and demonstration.

### Assumptions
- [ ] Level 10 complete (system maintenance works)

### Spells
* demo-magic (multiple lower-level spells) - Demonstrate wizardry features
* verify-posix - Verify POSIX compliance
* wizard-cast - Execute spells with wizard powers

### Tests
- `.tests/system/test-demo-magic.sh`
- `.tests/system/test-verify-posix.sh`

---

## Level 12: Divination

**Purpose**: Detection and analysis spells for system information.

### Assumptions
- [ ] Level 11 complete (advanced system tools work)
- [ ] System information accessible

### Self-Healing Actions
- Install platform detection tools if missing
- Verify system information sources

### Spells
* detect-rc-file - Detect shell rc file
* detect-magic (read-magic from Level 4) - Detect file metadata
* identify-room (detect-magic) - Identify current directory as MUD room

### Additional Imps Introduced
- `sys/os` - Get operating system name
- `sys/term` - Get terminal type
- `text/detect-indent-char` - Detect indentation character
- `text/detect-indent-width` - Detect indentation width

### Tests
- `.tests/divination/test-detect-rc-file.sh`
- `.tests/divination/test-detect-magic.sh`
- `.tests/divination/test-identify-room.sh`

---

## Level 13: Advanced MUD Features

**Purpose**: Advanced MUD theme integration building on basic MUD (Level 2).

### Assumptions
- [ ] Level 12 complete (divination works)
- [ ] Extended attributes working (from Level 2)

### Spells
* decorate (look from Level 2, read-magic from Level 4) - Add decorative elements
* select-player - Select player/character
* check-command-not-found-hook - Check command-not-found hook

### Tests
- `.tests/mud/test-decorate.sh`
- `.tests/mud/test-select-player.sh`
- `.tests/mud/test-check-command-not-found-hook.sh`

---

## Level 14: Cryptography

**Purpose**: Cryptographic operations and hashing.

### Assumptions
- [ ] Level 13 complete (advanced MUD works)

### Spells
* hash - Generate cryptographic hashes
* evoke-hash (hash) - Interactive hash generation
* hashchant (hash) - Chained hash operations

### Tests
- `.tests/crypto/` - Crypto tests

---

## Level 15: SSH & Remote Access

**Purpose**: SSH management and remote translocation.

### Assumptions
- [ ] Level 14 complete (crypto works)
- [ ] SSH available

### Spells
* validate-ssh-key - Validate SSH key format
* enchant-portkey - Configure SSH connection
* follow-portkey (enchant-portkey) - Connect via SSH
* open-portal - Open remote session
* open-teletype - Connect to remote terminal
* reload-ssh - Reload SSH service
* restart-ssh - Restart SSH service

### Tests
- `.tests/translocation/` - SSH-related tests
- `.tests/cantrips/test-validate-ssh-key.sh`

---

## Level 16: Task Priorities

**Purpose**: Task priority management.

### Assumptions
- [ ] Level 15 complete (SSH works)

### Spells
* get-priority - Get priority value
* get-new-priority (get-priority) - Calculate new priority
* prioritize (get-priority) - Set task priority
* upvote (get-priority) - Increase priority

### Tests
- `.tests/priorities/` - Priority tests

---

## Level 17: Security Wards

**Purpose**: Security hardening and monitoring.

### Assumptions
- [ ] Level 16 complete (priorities work)

### Spells
* ssh-barrier (SSH spells from Level 15) - SSH security hardening

### Tests
- `.tests/wards/` - Security tests

---

## Level 18: Extended Attributes

**Purpose**: File attribute management and manipulation.

### Assumptions
- [ ] Level 17 complete (wards work)
- [ ] Extended attributes working (from Level 2)

### Spells
* enchant (read-magic from Level 4) - Add extended attributes
* disenchant (read-magic from Level 4) - Remove extended attributes
* enchantment-to-yaml (read-magic from Level 4) - Export attributes to YAML
* yaml-to-enchantment (read-magic from Level 4) - Import attributes from YAML

### Tests
- `.tests/enchant/` - Enchant tests

---

## Level 19: Process & System Info (PSI)

**Purpose**: Process management and contact information.

### Assumptions
- [ ] Level 18 complete (enchant works)

### Spells
* list-contacts - List contact information
* read-contact (list-contacts) - Read contact details

### Tests
- `.tests/psi/` - PSI tests

---

## Level 20: Spellcraft Development Tools

**Purpose**: Tools for spell development, linting, and management.

### Assumptions
- [ ] Level 19 complete (PSI works)

### Spells
* scribe-spell - Create new spell
* lint-magic - Lint spell code
* compile-spell - Compile spell
* learn - Learn spell syntax
* forget - Remove spell from memory
* erase-spell - Delete spell file
* doppelganger - Duplicate spell
* add-synonym - Add spell synonym
* edit-synonym (add-synonym) - Edit spell synonym
* delete-synonym (add-synonym) - Delete spell synonym
* reset-default-synonyms - Reset synonyms to defaults
* bind-tome - Bind spellbook
* unbind-tome (bind-tome) - Unbind spellbook
* merge-yaml-text - Merge YAML configurations

### Tests
- `.tests/spellcraft/` - All spellcraft tests

---

## Level 21: Core Menu Infrastructure

**Purpose**: Core menu system components that aggregate spells.

### Assumptions
- [ ] Level 20 complete (spellcraft works)
- [ ] Menu system from Level 1 works

### Spells
* spellbook-store - Spellbook storage backend
* spellbook (menu from Level 1, read-magic from Level 4) - Interactive spellbook browser
* cast (menu from Level 1, spellbook) - Cast menu interface
* spell-menu (menu from Level 1, spellbook) - Spell management menu

### Tests
- `.tests/menu/test-spellbook.sh`
- `.tests/menu/test-cast.sh`

---

## Level 22: System & Configuration Menus

**Purpose**: Menu interfaces for system configuration and management.

### Assumptions
- [ ] Level 21 complete (core menus work)

### Spells
* system-menu (menu from Level 1, config from Level 8) - System configuration menu
* install-menu (menu from Level 1) - Installation menu
* synonym-menu (menu from Level 1, add-synonym/edit-synonym/delete-synonym from Level 20) - Synonym management menu
* thesaurus (menu from Level 1) - Thesaurus spell lookup

### Tests
- `.tests/menu/test-system-menu.sh`

---

## Level 23: MUD Administration Menus

**Purpose**: Menu interfaces for MUD features and administration.

### Assumptions
- [ ] Level 22 complete (system menus work)

### Spells
* mud (menu from Level 1) - MUD features menu
* mud-menu (menu from Level 1, look from Level 2, decorate from Level 13) - MUD navigation menu
* mud-settings (menu from Level 1, config from Level 8) - MUD configuration menu
* mud-admin-menu (menu from Level 1) - MUD admin menu
* add-ssh-player (menu from Level 1) - Add SSH player
* new-player (menu from Level 1) - Create new player
* set-player (menu from Level 1) - Configure player

### Tests
- `.tests/menu/test-mud-menu.sh`

---

## Level 24: Domain-Specific Menus

**Purpose**: Menu interfaces for specialized domains (network, services, priorities, etc.).

### Assumptions
- [ ] Level 23 complete (MUD menus work)

### Spells
* network-menu (menu from Level 1) - Network operations menu
* services-menu (menu from Level 1, service spells from Level 25) - Service management menu
* shutdown-menu (menu from Level 1) - Shutdown options menu
* priority-menu (menu from Level 1, prioritize/get-priority from Level 16) - Priority management menu
* priorities (menu from Level 1, priority-menu) - Priority task menu
* users-menu (menu from Level 1) - User management menu
* profile-tests (menu from Level 1, test-magic from Level 9) - Test profiling menu

### Tests
- `.tests/menu/` - Domain menu tests

---

## Level 25: System Service Management

**Purpose**: System service installation and management.

### Assumptions
- [ ] Level 24 complete (domain menus work)

### Spells
* install-service-template - Service template installer
* is-service-installed - Check service status
* enable-service (is-service-installed) - Enable system service
* disable-service (is-service-installed) - Disable system service
* start-service (is-service-installed) - Start system service
* stop-service (is-service-installed) - Stop system service
* restart-service (stop-service, start-service) - Restart system service
* service-status (is-service-installed) - View service status
* remove-service (disable-service, stop-service) - Remove system service

### Tests
- Service-related tests in `.tests/cantrips/`

---

## Level 26: Optional Arcana & Third-Party Integrations

**Purpose**: Optional third-party software integrations.

### Assumptions
- [ ] Level 25 complete (services work)

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
    ├── menu, terminal control, colors
    └── Core imps (require, has, say, die, temp-file, etc.)
        │
Level 2: MUD Basics (2 spells)
    ├── check-cd-hook, look
    └── Extended attribute imps
        │
Level 3: Navigation (2 spells)
    ├── jump-to-marker, mark-location
    └── Bookmark system
        │
Level 4: Arcane File Operations (6 spells)
    ├── copy, trash, forall, read-magic, file-list
    └── File manipulation imps
        │
Level 5: Basic Cantrips (7 spells)
    ├── ask, ask-yn, ask-text, list-files, move
    └── Basic user interaction
        │
Level 6: Validation (3 spells)
    ├── validate-number, validate-path, require-command
    └── Input validation
        │
Level 7: Advanced Cantrips (2 spells)
    ├── ask-number, memorize
    └── Builds on validation
        │
Level 8: System Configuration (3 spells)
    ├── config, logs, package-managers
    └── Config management
        │
Level 9: Testing (4 spells)
    ├── test-spell, test-magic, logging-example
    └── Test framework
        │
Level 10: System Maintenance (3 spells)
    ├── update-wizardry, update-all, kill-process
    └── System updates
        │
Level 11: Advanced System (3 spells)
    ├── demo-magic, verify-posix, wizard-cast
    └── Advanced validation
        │
Level 12: Divination (3 spells)
    ├── detect-rc-file, detect-magic, identify-room
    └── System detection
        │
Level 13: Advanced MUD (3 spells)
    ├── decorate, select-player, check-command-not-found-hook
    └── MUD features
        │
Level 14-19: Specialized Domains
    ├── Crypto, SSH, Priorities, Wards, Enchant, PSI
    └── Domain-specific functionality
        │
Level 20: Spellcraft (14 spells)
    ├── All spell development tools
    └── Development framework
        │
Level 21-24: Menus (4 levels, ~27 spells)
    ├── Core menus, system menus, MUD menus, domain menus
    └── High-level aggregation
        │
Level 25: Services (9 spells)
    ├── Service management
    └── System integration
        │
Level 26: Arcana
    └── Optional third-party integrations
```

---

## Usage Examples

```bash
# Prepare system for wizardry install
banish 0

# Prepare system and verify menu works
banish 1

# MUD basics (just cd-hook and look)
banish 2

# Navigation (just jump-to-marker and mark-location)
banish 3

# Through arcane file operations
banish 4

# Through basic cantrips
banish 5

# Through validation helpers
banish 6

# Through advanced cantrips
banish 7

# Through system configuration
banish 8

# Through testing infrastructure
banish 9

# Through system maintenance
banish 10

# Through all specialized domains
banish 20

# Through all menus
banish 24

# Through services
banish 25

# Full system validation (all levels including arcana)
banish 26

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

1. **Parse level argument** - Default to 0, support 0-26
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
- **Level aliases** - `banish core` = `banish 1`, `banish full` = `banish 26`
