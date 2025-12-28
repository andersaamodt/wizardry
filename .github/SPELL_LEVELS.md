# Wizardry Spell Levels - Spiral Debug Organization

## Overview

This document organizes all wizardry spells into **Spell Levels** - a hierarchical structure where each level builds on the previous ones. This organization supports the enhanced `banish` spell, which can validate and test each level incrementally.

The spiral organization starts from the most fundamental prerequisites (Level 0) and spirals outward through increasingly complex and specialized spells. Each level includes:
- **Assumptions** to check (with corresponding check scripts)
- **Spells** at that level
- **New imps** introduced at that level

## Banish Integration

The `banish` spell integrates assumption-checking, self-healing, and testing:

```bash
banish           # Banish to level 0 (default) - validate POSIX foundation
banish 0         # Same as above
banish 1         # Banish through levels 0-1 (wizardry installed)
banish 2         # Banish through levels 0-2 (menu ready)
banish N         # Banish through levels 0-N (full system validated)
```

Each `banish N` command:
1. Recursively runs previous levels (banish 2 → runs 0, 1, then 2)
2. Checks assumptions for that level using corresponding check scripts
3. Offers to self-heal broken assumptions (with user confirmation)
4. Runs tests for spells at that level (automatically, no prompt)

---

## Level 0: POSIX & Platform Foundation

**Purpose**: Validate POSIX environment and platform detection capabilities.

### Assumptions
- [ ] POSIX shell available (`sh`) - *detect-posix*
- [ ] Core POSIX utilities: `printf`, `test`, `command` - detect-posix
- [ ] Path utilities: `dirname`, `basename`, `cd`, `pwd` - detect-posix
- [ ] File utilities: `cat`, `grep`, `find`, `sort` - detect-posix  
- [ ] Text processing: `awk`, `sed` - detect-posix
- [ ] Temporary files: `mktemp` - detect-posix
- [ ] Standard PATH includes `/bin`, `/usr/bin` - detect-posix
- [ ] Either `curl` or `wget` available - detect-posix
- [ ] `tar` available - detect-posix
- [ ] Operating system detectable via `uname` - detect-distro
- [ ] Package manager available - detect-distro
- [ ] Distribution identifiable (Linux only) - detect-distro

### Spells
* detect-posix
* detect-distro
* verify-posix

### Imps Introduced
None (bootstrap level)

---

## Level 1: Wizardry Installation

**Purpose**: Wizardry core infrastructure and shell integration.

### Assumptions
- [ ] Wizardry is installed (WIZARDRY_DIR is set) - *check-wizardry-installed*
- [ ] invoke-wizardry available and sourceable - *check-invoke-wizardry*
- [ ] Wizardry globals properly set - *check-wizardry-globals*

### Spells
* banish

### Imps Introduced
`sys/invoke-wizardry`, `sys/require-wizardry`, `sys/require`, `sys/castable`, `sys/env-clear`, `sys/on-exit`, `sys/clear-traps`, `cond/has`, `cond/there`, `cond/is`, `cond/empty`, `cond/nonempty`, `out/say`, `out/warn`, `out/die`, `out/fail`, `out/info`, `out/step`, `out/success`, `out/debug`, `fs/temp-file`, `fs/temp-dir`, `fs/cleanup-file`, `fs/cleanup-dir`, `input/tty-save`, `input/tty-restore`, `input/tty-raw`, `input/read-line`, `str/contains`, `str/trim`, `str/equals`, `str/starts`, `str/ends`, `paths/here`, `paths/parent`, `paths/file-name`, `paths/abs-path`

---

## Level 2: Menu System

**Purpose**: Interactive menu system - primary user interface to wizardry.

### Assumptions
- [ ] Level 1 complete - banish
- [ ] Terminal supports ANSI escape codes - *check-terminal-ansi*
- [ ] TTY is readable/writable - *check-tty*
- [ ] `stty` command available - detect-posix

### Spells
* menu
* fathom-terminal
* fathom-cursor
* move-cursor
* await-keypress
* cursor-blink
* colors
* main-menu

### Imps Introduced
`menu/is-submenu`, `menu/is-integer`, `menu/category-title`, `menu/exit-label`

---

## Level 3: MUD Basics

**Purpose**: Basic MUD integration - directory navigation awareness and CD hook management.

### Assumptions
- [ ] Level 2 complete - banish
- [ ] Extended attributes supported or fallback available - *check-xattr-support*

### Spells
* check-cd-hook
* look (read-magic from Level 5)

### Imps Introduced
`fs/xattr-helper-usable`, `fs/xattr-list-keys`, `fs/xattr-read-value`

---

## Level 4: Navigation

**Purpose**: Bookmark-based navigation system for quick directory teleportation.

### Assumptions
- [ ] Level 3 complete - banish
- [ ] Marker directory can be created - *check-marker-directory*

### Spells
* jump-to-marker
* mark-location

### Imps Introduced
None

---

## Level 5: Arcane File Operations

**Purpose**: Core file and directory manipulation spells.

### Assumptions
- [ ] Level 4 complete - banish
- [ ] File system is readable/writable - *check-filesystem-rw*
- [ ] Standard UNIX file utilities work (`cp`, `mv`, `rm`, `find`) - detect-posix
- [ ] Sufficient disk space - *check-disk-space*

### Spells
* copy
* trash
* jump-trash (trash)
* forall
* read-magic
* file-list

### Imps Introduced
`fs/backup`, `menu/detect-trash`, `text/read-file`, `text/write-file`, `text/lines`, `text/each`

---

## Level 6: Basic Cantrips

**Purpose**: Simple interactive spells for user input and basic operations.

### Assumptions
- [ ] Level 5 complete - banish
- [ ] Terminal supports interactive input - *check-tty-interactive*
- [ ] User can respond to prompts - *check-tty-interactive*

### Spells
* ask
* ask-yn (ask)
* ask-text (ask)
* list-files
* max-length
* move
* up

### Imps Introduced
`input/select-input`, `lex/parse`, `lex/from`, `lex/to`

---

## Level 7: Validation Helpers

**Purpose**: Input validation and requirement checking.

### Assumptions
- [ ] Level 6 complete - banish

### Spells
* validate-number
* validate-path
* require-command

### Imps Introduced
`input/validate-command`, `input/validate-name`, `lex/and`, `lex/or`

---

## Level 8: Advanced Cantrips

**Purpose**: More complex user interaction spells that build on validation.

### Assumptions
- [ ] Level 7 complete - banish

### Spells
* ask-number (ask from Level 6, validate-number from Level 7)
* memorize

### Imps Introduced
None

---

## Level 9: System Configuration

**Purpose**: System-level configuration management.

### Assumptions
- [ ] Level 8 complete - banish
- [ ] Write access to config files - *check-config-writable*

### Spells
* config
* logs
* package-managers

### Imps Introduced
`fs/config-get`, `fs/config-set`, `fs/config-has`, `fs/config-del`

---

## Level 10: Testing Infrastructure

**Purpose**: Test execution and validation framework.

### Assumptions
- [ ] Level 9 complete - banish
- [ ] Test infrastructure available - *check-test-infrastructure*

### Spells
* test-spell
* test-magic (test-spell)
* logging-example
* wizard-eyes

### Imps Introduced
`test/*`, `sys/rc-add-line`, `sys/rc-has-line`, `sys/rc-remove-line`

---

## Level 11: System Maintenance

**Purpose**: System updates and process management.

### Assumptions
- [ ] Level 10 complete - banish

### Spells
* update-wizardry
* update-all (update-wizardry)
* kill-process

### Imps Introduced
None

---

## Level 12: Advanced System Tools

**Purpose**: Advanced system validation and demonstration.

### Assumptions
- [ ] Level 11 complete - banish

### Spells
* demo-magic
* verify-posix
* wizard-cast

### Imps Introduced
None

---

## Level 13: Divination

**Purpose**: Detection and analysis spells for system information.

### Assumptions
- [ ] Level 12 complete - banish
- [ ] System information accessible - detect-posix

### Spells
* detect-rc-file
* detect-magic (read-magic from Level 5)
* identify-room (detect-magic)

### Imps Introduced
`sys/os`, `sys/term`, `text/detect-indent-char`, `text/detect-indent-width`

---

## Level 14: Advanced MUD Features

**Purpose**: Advanced MUD theme integration building on basic MUD (Level 3).

### Assumptions
- [ ] Level 13 complete - banish
- [ ] Extended attributes working - check-xattr-support

### Spells
* decorate (look from Level 3, read-magic from Level 5)
* select-player
* check-command-not-found-hook

### Imps Introduced
None

---

## Level 15: Cryptography

**Purpose**: Cryptographic operations and hashing.

### Assumptions
- [ ] Level 14 complete - banish

### Spells
* hash
* evoke-hash (hash)
* hashchant (hash)

### Imps Introduced
None

---

## Level 16: SSH & Remote Access

**Purpose**: SSH management and remote translocation.

### Assumptions
- [ ] Level 15 complete - banish
- [ ] SSH available - detect-posix

### Spells
* validate-ssh-key
* enchant-portkey
* follow-portkey (enchant-portkey)
* open-portal
* open-teletype
* reload-ssh
* restart-ssh

### Imps Introduced
None

---

## Level 17: Task Priorities

**Purpose**: Task priority management.

### Assumptions
- [ ] Level 16 complete - banish

### Spells
* get-priority
* get-new-priority (get-priority)
* prioritize (get-priority)
* upvote (get-priority)

### Imps Introduced
None

---

## Level 18: Security Wards

**Purpose**: Security hardening and monitoring.

### Assumptions
- [ ] Level 17 complete - banish

### Spells
* ssh-barrier (SSH spells from Level 16)

### Imps Introduced
None

---

## Level 19: Extended Attributes

**Purpose**: File attribute management and manipulation.

### Assumptions
- [ ] Level 18 complete - banish
- [ ] Extended attributes working - check-xattr-support

### Spells
* enchant (read-magic from Level 5)
* disenchant (read-magic from Level 5)
* enchantment-to-yaml (read-magic from Level 5)
* yaml-to-enchantment (read-magic from Level 5)

### Imps Introduced
None

---

## Level 20: Process & System Info (PSI)

**Purpose**: Process management and contact information.

### Assumptions
- [ ] Level 19 complete - banish

### Spells
* list-contacts
* read-contact (list-contacts)

### Imps Introduced
None

---

## Level 21: Spellcraft Development Tools

**Purpose**: Tools for spell development, linting, and management.

### Assumptions
- [ ] Level 20 complete - banish

### Spells
* scribe-spell
* lint-magic
* compile-spell
* learn
* forget
* erase-spell
* doppelganger
* add-synonym
* edit-synonym (add-synonym)
* delete-synonym (add-synonym)
* reset-default-synonyms
* bind-tome
* unbind-tome (bind-tome)
* merge-yaml-text

### Imps Introduced
None

---

## Level 22: Core Menu Infrastructure

**Purpose**: Core menu system components that aggregate spells.

### Assumptions
- [ ] Level 21 complete - banish
- [ ] Menu system from Level 2 works - menu

### Spells
* spellbook-store
* spellbook (menu from Level 2, read-magic from Level 5)
* cast (menu from Level 2, spellbook)
* spell-menu (menu from Level 2, spellbook)

### Imps Introduced
None

---

## Level 23: System & Configuration Menus

**Purpose**: Menu interfaces for system configuration and management.

### Assumptions
- [ ] Level 22 complete - banish

### Spells
* system-menu (menu from Level 2, config from Level 9)
* install-menu (menu from Level 2)
* synonym-menu (menu from Level 2, add-synonym/edit-synonym/delete-synonym from Level 21)
* thesaurus (menu from Level 2)

### Imps Introduced
None

---

## Level 24: MUD Administration Menus

**Purpose**: Menu interfaces for MUD features and administration.

### Assumptions
- [ ] Level 23 complete - banish

### Spells
* mud (menu from Level 2)
* mud-menu (menu from Level 2, look from Level 3, decorate from Level 14)
* mud-settings (menu from Level 2, config from Level 9)
* mud-admin-menu (menu from Level 2)
* add-ssh-player (menu from Level 2)
* new-player (menu from Level 2)
* set-player (menu from Level 2)

### Imps Introduced
None

---

## Level 25: Domain-Specific Menus

**Purpose**: Menu interfaces for specialized domains (network, services, priorities, etc.).

### Assumptions
- [ ] Level 24 complete - banish

### Spells
* network-menu (menu from Level 2)
* services-menu (menu from Level 2, service spells from Level 26)
* shutdown-menu (menu from Level 2)
* priority-menu (menu from Level 2, prioritize/get-priority from Level 17)
* priorities (menu from Level 2, priority-menu)
* users-menu (menu from Level 2)
* profile-tests (menu from Level 2, test-magic from Level 10)

### Imps Introduced
None

---

## Level 26: System Service Management

**Purpose**: System service installation and management.

### Assumptions
- [ ] Level 25 complete - banish

### Spells
* install-service-template
* is-service-installed
* enable-service (is-service-installed)
* disable-service (is-service-installed)
* start-service (is-service-installed)
* stop-service (is-service-installed)
* restart-service (stop-service, start-service)
* service-status (is-service-installed)
* remove-service (disable-service, stop-service)

### Imps Introduced
None

---

## Level 27: Optional Arcana & Third-Party Integrations

**Purpose**: Optional third-party software integrations.

### Assumptions
- [ ] Level 26 complete - banish

### Spells
All spells in `spells/.arcana/`

### Imps Introduced
None

---
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
# Prepare POSIX foundation
banish 0

# Prepare wizardry installation
banish 1

# Prepare menu system
banish 2

# MUD basics (just cd-hook and look)
banish 3

# Navigation (just jump-to-marker and mark-location)
banish 4

# Through arcane file operations
banish 5

# Through basic cantrips
banish 6

# Through validation helpers
banish 7

# Through advanced cantrips
banish 8

# Through system configuration
banish 9

# Through testing infrastructure
banish 10

# Through system maintenance
banish 11

# Through all specialized domains
banish 21

# Through all menus
banish 25

# Through services
banish 26

# Full system validation (all levels including arcana)
banish 27

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

1. **Parse level argument** - Default to 0, support 0-27
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
- **Level aliases** - `banish core` = `banish 2`, `banish full` = `banish 27`
