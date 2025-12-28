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
4. Runs tests for spells at that level (automatically, no prompt)

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
**Note**: Level 0 assumes wizardry is installed. Critical infrastructure imps: `sys/invoke-wizardry`, `sys/require-wizardry`, `out/say`, `out/warn`, `out/die`, `cond/has`, `cond/there`

### Detection Capabilities (Optional)
If wizardry is already installed, Level 0 can use:
* detect-posix - Probe POSIX toolchain
* detect-distro - Detect Linux distribution
* verify-posix - Verify POSIX environment

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
Core system: `sys/require-wizardry`, `sys/require`, `sys/castable`, `sys/env-clear`, `sys/on-exit`, `sys/clear-traps`

Conditional: `cond/has`, `cond/there`, `cond/is`, `cond/empty`, `cond/nonempty`

Output: `out/say`, `out/warn`, `out/die`, `out/fail`, `out/info`, `out/step`, `out/success`, `out/debug`

Filesystem: `fs/temp-file`, `fs/temp-dir`, `fs/cleanup-file`, `fs/cleanup-dir`

Input: `input/tty-save`, `input/tty-restore`, `input/tty-raw`, `input/read-line`

String: `str/contains`, `str/trim`, `str/equals`, `str/starts`, `str/ends`

Path: `paths/here`, `paths/parent`, `paths/file-name`, `paths/abs-path`

Menu-specific: `menu/is-submenu`, `menu/is-integer`, `menu/category-title`, `menu/exit-label`

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
`fs/xattr-helper-usable`, `fs/xattr-list-keys`, `fs/xattr-read-value`

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
`fs/backup`, `menu/detect-trash`, `text/read-file`, `text/write-file`, `text/lines`, `text/each`

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
`input/select-input`, `lex/parse`, `lex/from`, `lex/to`

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
`input/validate-command`, `input/validate-name`, `lex/and`, `lex/or`

---

## Level 7: Advanced Cantrips

**Purpose**: More complex user interaction spells that build on validation.

### Assumptions
- [ ] Level 6 complete (validation works)

### Spells
* ask-number (ask from Level 5, validate-number from Level 6) - Numeric input
* memorize - Add spell to shell rc

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
`fs/config-get`, `fs/config-set`, `fs/config-has`, `fs/config-del`

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
`test/*`, `sys/rc-add-line`, `sys/rc-has-line`, `sys/rc-remove-line`

---

## Level 10: System Maintenance

**Purpose**: System updates and process management.

### Assumptions
- [ ] Level 9 complete (testing works)

### Spells
* update-wizardry - Update wizardry
* update-all (update-wizardry) - Update everything
* kill-process - Kill process by name

---

## Level 11: Advanced System Tools

**Purpose**: Advanced system validation and demonstration.

### Assumptions
- [ ] Level 10 complete (system maintenance works)

### Spells
* demo-magic (multiple lower-level spells) - Demonstrate wizardry features
* verify-posix - Verify POSIX compliance
* wizard-cast - Execute spells with wizard powers

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
`sys/os`, `sys/term`, `text/detect-indent-char`, `text/detect-indent-width`

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

---

## Level 14: Cryptography

**Purpose**: Cryptographic operations and hashing.

### Assumptions
- [ ] Level 13 complete (advanced MUD works)

### Spells
* hash - Generate cryptographic hashes
* evoke-hash (hash) - Interactive hash generation
* hashchant (hash) - Chained hash operations

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

---

## Level 17: Security Wards

**Purpose**: Security hardening and monitoring.

### Assumptions
- [ ] Level 16 complete (priorities work)

### Spells
* ssh-barrier (SSH spells from Level 15) - SSH security hardening

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

---

## Level 19: Process & System Info (PSI)

**Purpose**: Process management and contact information.

### Assumptions
- [ ] Level 18 complete (enchant works)

### Spells
* list-contacts - List contact information
* read-contact (list-contacts) - Read contact details

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
