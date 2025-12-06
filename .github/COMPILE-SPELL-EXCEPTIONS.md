# Compile-Spell Compilation Exceptions

This document lists all spells that cannot be compiled to run standalone, with justifications for each exception.

## Category 1: Spells That Require Wizardry By Design (40 spells)

These spells fundamentally depend on wizardry being installed and configured. They manage wizardry itself or require the full wizardry environment.

### Wizardry Management Spells
- `bind-tome` - Creates tome archives of spell directories; requires wizardry structure
- `unbind-tome` - Extracts tome archives; requires wizardry structure  
- `cast` - Executes memorized spells from spellbook; requires spellbook infrastructure
- `compile-spell` - Self-reference; requires wizardry to compile other spells
- `erase-spell` - Removes spells from spellbook; requires spellbook infrastructure
- `forget` - Removes spell from memory; requires spellbook infrastructure
- `learn-spellbook` - Learns entire spellbooks; requires wizardry's learning system
- `memorize` - Adds spells to cast menu; requires spellbook infrastructure
- `scribe-spell` - Creates new custom spells in spellbook; requires wizardry structure

### Menu System Spells  
- `install-menu` - Displays arcana installation menu; requires wizardry ecosystem
- `main-menu` - Root wizardry menu; requires full wizardry environment
- `mud-admin-menu` - MUD administration menu; requires wizardry+MUD environment
- `mud-menu` - MUD interaction menu; requires wizardry+MUD environment
- `priority-menu` - Priority voting menu; requires wizardry database
- `services-menu` - System services menu; requires wizardry configuration
- `shutdown-menu` - System shutdown menu; requires wizardry configuration
- `spell-menu` - Spell selection menu; requires spellbook
- `spellbook` - Personal grimoire interface; requires spellbook infrastructure
- `system-menu` - System management menu; requires wizardry configuration
- `users-menu` - User management menu; requires wizardry+system integration

### MUD & Portkey Spells
- `enchant-portkey` - Creates bookmarks to remote locations; requires wizardry extended attributes
- `follow-portkey` - Teleports to portkey location; requires wizardry extended attributes
- `identify-room` - Identifies MUD room metadata; requires wizardry+MUD integration
- `jump-to-marker` - Jumps to marked location; requires wizardry extended attributes
- `look` - MUD "look" command; requires MUD environment
- `mark-location` - Marks current location; requires wizardry extended attributes
- `mud` - Main MUD client; requires full MUD+wizardry environment
- `mud-settings` - MUD configuration; requires wizardry+MUD environment
- `open-portal` - Creates persistent SSH connections; requires wizardry portal management
- `open-teletype` - Opens terminal sessions; requires wizardry session management
- `select-player` - Selects MUD player character; requires MUD database

### Priority & Metadata Spells
- `get-new-priority` - Gets next priority number; requires wizardry priority database
- `get-priority` - Retrieves priority value; requires wizardry priority database
- `prioritize` - Sets priority value; requires wizardry priority database
- `upvote` - Increases priority; requires wizardry priority database

### File Enhancement Spells
- `copy` - Copies file to clipboard with fallback installation; requires wizardry package management
- `decorate` - Adds decorative metadata; requires wizardry extended attributes
- `enchantment-to-yaml` - Converts extended attributes to YAML; requires wizardry formats
- `read-magic` - Reads file metadata; requires wizardry extended attributes
- `yaml-to-enchantment` - Converts YAML to extended attributes; requires wizardry formats

## Category 2: Spells Calling Other Full Spells (4 spells)

These spells invoke other full spells (not just imps), making compilation impractical without inlining entire spell trees.

- `ask-number` - Calls validation spells; would need to inline multiple spell dependencies
- `logs` - Calls system logging spells; complex spell chain
- `move-cursor` - Calls cursor manipulation spells; complex interactive logic
- `network-menu` - Calls network configuration spells; menu system with spell callbacks

## Category 3: Successfully Standalone (7 spells)

These spells already work without any dependencies:

- `cursor-blink` - Pure POSIX shell; no dependencies
- `detect-distro` - Pure POSIX shell; detects Linux distribution
- `file-list` - Pure POSIX shell; lists files
- `forall` - Pure POSIX shell; applies command to list
- `hashchant` - Pure POSIX shell; generates repeated hashes  
- `package-managers` - Pure POSIX shell; detects package managers
- `read-contact` - Pure POSIX shell; reads contact files

## Category 4: Compilable with Imp Inlining (52 spells)

These spells use only simple imps (no spell dependencies) and can be compiled standalone with enhanced compiler:

### Simple Imp Users
- `ask`, `ask-text`, `ask-yn` - Use basic imps: say, warn, fail
- `assertions` - Uses: say, warn, die
- `await-keypress` - Uses: say
- `colors` - Uses: say
- `detect-magic`, `detect-rc-file` - Use: say, warn
- `disable-service`, `enable-service`, `start-service`, `stop-service` - Use: say, warn, die
- `disenchant`, `enchant` - Use: say, warn
- `evoke-hash`, `hash` - Use: warn (hash uses very minimal imps)
- `fathom-cursor`, `fathom-terminal` - Use: say
- `install-service-template`, `is-service-installed`, `remove-service`, `restart-service`, `service-status` - Use: say, warn, die
- `jump-trash`, `trash` - Use: say, warn
- `kill-process` - Uses: say, warn
- `learn`, `learn-spell` - Use: say, warn, die, info, step
- `lint-magic` - Uses: say, warn, die, info
- `list-contacts` - Uses: say
- `logging-example` - Uses: say, info, step, debug, success, warn, die (demonstration spell)
- `max-length` - Uses: say
- `menu` - Uses: say, warn, info (complex but compilable)
- `merge-yaml-text` - Uses: say, warn
- `move` - Uses: say, warn
- `priorities` - Uses: say, warn
- `reload-ssh`, `restart-ssh`, `ssh-barrier` - Use: say, warn, die
- `require-command`, `require-wizardry` - Use: warn, die (bootstrap-related)
- `spellbook-store` - Uses: say, warn
- `test-magic` - Uses: say, warn, info, step (test framework)
- `up`, `update-all`, `update-wizardry` - Use: say, warn, info, step
- `validate-number`, `validate-path`, `validate-ssh-key` - Use: warn, die

## Summary

| Category | Count | Compilable |
|----------|-------|------------|
| Requires Wizardry By Design | 40 | ❌ No - by design |
| Calls Other Full Spells | 4 | ❌ No - too complex |
| Already Standalone | 7 | ✅ Yes - works now |
| Compilable with Imp Inlining | 52 | ✅ Yes - with enhancement |
| **Total** | **103** | **59 potential (57%)** |

## Path to 100% Compilation

To reach maximum compilation rate:

1. **Enhance compiler to inline simple imps** (52 spells → standalone)
   - Inline single-word imps: say, warn, die, fail, info, step, debug, success
   - Inline conditional imps: is, has, there, gone, empty, nonempty, given, full
   - Inline simple utility imps: norm-path, clip-copy, temp-file, cleanup-file
   - Replace hyphenated calls with function calls
   - Remove require-wizardry lines

2. **Leave by-design exceptions** (40 spells remain wizardry-dependent)
   - These fundamentally require wizardry infrastructure
   - Compiling them standalone defeats their purpose
   - They manage wizardry itself or require its environment

3. **Document spell-calling exceptions** (4 spells remain complex)
   - Inlining entire spell trees is impractical
   - Better handled through modular design

## Expected Final State

With enhanced compilation:
- **59 spells (57%) work standalone** (7 current + 52 compilable)
- **44 spells (43%) remain wizardry-dependent** (40 by-design + 4 spell-callers)

This is the practical limit. The remaining 43% are either:
- By design (wizardry management, menus, MUD, priorities)
- Too complex (calling full spell dependency trees)
- More useful within wizardry than standalone

Going beyond 57% would require either:
- Reimplementing wizardry infrastructure in each compiled spell (defeats purpose)
- Creating a compiled wizardry runtime library (different project scope)
- Breaking spell modularity (poor engineering)

The 57% standalone rate represents the logical limit for compile-spell.
