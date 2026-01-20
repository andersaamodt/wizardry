# Wizardry Spell Levels

**Canonical Source:** `spells/.imps/sys/spell-levels` imp

**Purpose:** This document provides human-readable documentation of the spell level hierarchy used by `banish`, `test-magic`, and `demo-magic` spells.

## Spell Level Organization

Wizardry organizes all spells and imps into 28 levels (0-27), where each level builds on previous ones. This hierarchical organization enables incremental validation and testing.

### How Levels Are Used

- **`banish N`**: Validates system state through levels 0-N recursively
- **`test-magic`**: Can test spells by level or run all tests
- **`demo-magic`**: Demonstrates features organized by level

## The 28 Spell Levels

### Level 0: POSIX & Platform Foundation
**Spells:** detect-distro, detect-posix, verify-posix  
**Imps:** (none - bootstrap level)  
**Purpose:** Validate POSIX environment and platform detection

### Level 1: Banish & Validation Infrastructure  
**Spells:** banish, validate-spells  
**Imps:** cond/*, out/*, sys/spell-levels, text/count-words, text/pluralize  
**Purpose:** Core validation and output infrastructure

### Level 2: Installation Infrastructure
**Spells:** (none - infrastructure level)  
**Imps:** declare-globals, fs/cleanup-*, fs/temp-*, input/*, paths/*, str/*, sys/*  
**Purpose:** File operations, path handling, string operations, system utilities

### Level 3: Glossary & Parsing
**Spells:** generate-glosses  
**Imps:** fs/find-executable, lex/parse  
**Purpose:** Command glossary and multi-word command parsing

### Level 4: Menu System
**Spells:** await-keypress, colors, main-menu, menu  
**Imps:** menu/*  
**Purpose:** Interactive menu infrastructure

### Level 5: Extended Attributes
**Spells:** disenchant, enchant, enchantment-to-yaml, yaml-to-enchantment  
**Imps:** (none)  
**Purpose:** File metadata management

### Level 6: Task Priorities
**Spells:** deprioritize, get-card, get-new-priority, get-priority, priorities, prioritize, upvote  
**Imps:** (none)  
**Purpose:** Task priority management

### Level 7: Navigation
**Spells:** blink, go-up, jump-to-marker, mark-location  
**Imps:** (none)  
**Purpose:** Directory navigation and bookmarks

### Level 8: MUD Basics
**Spells:** check-cd-hook, look  
**Imps:** fs/xattr-*  
**Purpose:** MUD theme foundation

### Level 9: Arcane File Operations
**Spells:** copy, file-list, forall, jump-trash, read-magic, trash  
**Imps:** fs/backup, fs/clip-*, menu/detect-trash, text/*  
**Purpose:** Core file manipulation and text operations

### Level 10: Basic Cantrips
**Spells:** ask, ask-number, ask-text, ask-yn, list-files, max-length, memorize, move  
**Imps:** input/*, lex/*  
**Purpose:** User input and basic utilities

### Level 11: System Configuration
**Spells:** config, learn-spellbook, logs, package-managers  
**Imps:** fs/config-*, pkg/*  
**Purpose:** Configuration and package management

### Level 12: Testing Infrastructure
**Spells:** pocket-dimension, spellbook-store, test-magic, test-spell, wizard-eyes  
**Imps:** sys/rc-*, test/*  
**Purpose:** Test framework and sandboxing

### Level 13: System Maintenance
**Spells:** kill-process, update-all, update-wizardry  
**Imps:** fs/backup-nix-config  
**Purpose:** System updates and process management

### Level 14: Advanced System Tools
**Spells:** demo-magic, wizard-cast  
**Imps:** (none)  
**Purpose:** Demonstration and advanced diagnostics

### Level 15: Divination
**Spells:** detect-magic, detect-rc-file, identify-room  
**Imps:** lang/possessive, sys/os, sys/term, text/detect-*  
**Purpose:** Detection and analysis

### Level 16: Advanced MUD Features
**Spells:** choose-player, damage-file, decorate, magic-missile  
**Imps:** (none)  
**Purpose:** Extended MUD functionality

### Level 17: Cryptography
**Spells:** evoke-hash, hash, hashchant  
**Imps:** (none)  
**Purpose:** Cryptographic operations

### Level 18: SSH & Remote Access
**Spells:** enchant-portkey, follow-portkey, open-portal, open-teletype, validate-ssh-key  
**Imps:** (none)  
**Purpose:** Remote access and SSH management

### Level 19: Security Wards
**Spells:** ssh-barrier  
**Imps:** fs/sed-inplace  
**Purpose:** Security hardening

### Level 20: Process & System Info (PSI)
**Spells:** check, get-checked, list-contacts, read-contact, rename-interactive, uncheck  
**Imps:** (none)  
**Purpose:** Process info and contact management

### Level 21: Spellcraft Development Tools
**Spells:** add-synonym, bind-tome, compile-spell, delete-synonym, doppelganger, edit-synonym, erase-spell, forget, learn, lint-magic, merge-yaml-text, reset-default-synonyms, scribe-spell, unbind-tome  
**Imps:** (none)  
**Purpose:** Development and spell management tools

### Level 22: Core Menu Infrastructure
**Spells:** cast, spell-menu, spellbook  
**Imps:** (none)  
**Purpose:** Core menu system components

### Level 23: System & Configuration Menus
**Spells:** install-menu, synonym-menu, system-menu, thesaurus  
**Imps:** (none)  
**Purpose:** System configuration menus

### Level 24: MUD Administration Menus
**Spells:** add-ssh-player, mud, mud-admin-menu, mud-menu, mud-settings, new-player, set-player  
**Imps:** (none)  
**Purpose:** MUD administration interfaces

### Level 25: Domain-Specific Menus
**Spells:** network-menu, priority-menu, profile-tests, services-menu, shutdown-menu, users-menu  
**Imps:** (none)  
**Purpose:** Specialized domain menus

### Level 26: System Service Management
**Spells:** disable-service, enable-service, install-service-template, is-service-installed, reload-ssh, remove-service, restart-service, restart-ssh, service-status, start-service, stop-service  
**Imps:** (none)  
**Purpose:** System service control

### Level 27: Arcana & Extensions
**Spells:** (dynamically loaded from .arcana/)  
**Imps:** (none)  
**Purpose:** Optional third-party integrations

## Usage Examples

```bash
# Validate POSIX foundation only
banish 0

# Validate through menu system (default)
banish 3

# Validate through testing infrastructure
banish 12

# Validate entire system including arcana
banish 27
```

## Updating This Document

**DO NOT manually edit this file.** The canonical source is `spells/.imps/sys/spell-levels`. When spell levels change:

1. Update `spells/.imps/sys/spell-levels` imp
2. Regenerate this document from the imp
3. Update `banish` spell if level semantics change

This ensures documentation stays synchronized with the code.
