# Compiled Spell Categorization

This document categorizes all wizardry spells and imps for standalone compilation testing.

## Categories

- **💎 Gem**: Highly useful standalone. These must work perfectly in compiled form.
- **✓ Included**: May have some standalone use. Get working if feasible.
- **✗ Excluded**: Core wizardry infrastructure. Not meaningful standalone.

## Categorization Methodology

### Gems (💎)
Spells that are immediately useful without wizardry installed:
- Utility scripts (file operations, text processing)
- Standalone tools (hash, copy, encryption)
- Self-contained functionality

### Included (✓)
Spells that could be useful but depend on wizardry conventions:
- Most imps (building blocks)
- Helper spells
- Spells with optional wizardry features

### Excluded (✗)
Spells that are inherently wizardry-specific:
- Menu infrastructure (cast, spell-menu)
- Installation/setup spells
- Spells that source other files or manage wizardry itself

## Spell Categories

### Gems (💎) - Priority Testing

**Crypto:**
- 💎 hash
- 💎 hashchant
- 💎 evoke-hash

**File Operations:**
- 💎 copy
- 💎 bind-tome
- 💎 unbind-tome

**Text Processing:**
- 💎 merge-yaml-text
- 💎 yaml-to-enchantment
- 💎 enchantment-to-yaml

**Utilities:**
- 💎 list-files (new cantrip)
- 💎 file-list
- 💎 priorities

### Included (✓) - Standard Testing

**Most Imps:**
- ✓ All imps in `cond/` (is, has, there, empty, full, etc.)
- ✓ All imps in `out/` (say, warn, die, fail, etc.)
- ✓ All imps in `str/` (string operations)
- ✓ All imps in `fs/` (filesystem operations)
- ✓ All imps in `paths/` (path operations)
- ✓ All imps in `sys/` except those excluded below
- ✓ All imps in `input/` (user input)
- ✓ All imps in `lex/` (parsing)

**Spellcraft:**
- ✓ compile-spell
- ✓ lint-magic
- ✓ scribe-spell
- ✓ learn-spell
- ✓ forget
- ✓ erase-spell

**Translocation:**
- ✓ jump-to-marker
- ✓ mark-location
- ✓ enchant-portkey
- ✓ follow-portkey
- ✓ open-portal
- ✓ open-teletype

**Arcane:**
- ✓ read-magic
- ✓ forall
- ✓ trash
- ✓ jump-trash

**Contacts:**
- ✓ read-contact
- ✓ list-contacts

**Divination:**
- ✓ identify-room
- ✓ look

**Enchant:**
- ✓ enchant
- ✓ disenchant

**Wards:**
- ✓ ssh-barrier

**PSI:**
- ✓ prioritize
- ✓ upvote
- ✓ get-priority
- ✓ get-new-priority

### Excluded (✗) - No Standalone Testing

**Menu Infrastructure:**
- ✗ cast (requires memorize spell as command)
- ✗ spell-menu (sources colors, requires memorize)
- ✗ select-player (menu system)

**Installation:**
- ✗ install-* (all installation spells)
- ✗ setup-* (setup scripts)

**Wizardry Management:**
- ✗ invoke-wizardry (sets up wizardry environment)
- ✗ require-wizardry (checks for wizardry)
- ✗ declare-globals (wizardry-specific)

**System Imps:**
- ✗ colors (sourced script with variables, not a function)

**Learning/Spellbook:**
- ✗ learn-spellbook (manages spellbook)
- ✗ learn (interactive learning)

**MUD:**
- ✗ mud (game infrastructure)
- ✗ decorate (MUD-specific)

## Testing Strategy

1. **Gems**: Must pass all tests, 100% success rate expected
2. **Included**: Best effort, aim for >90% success rate
3. **Excluded**: Don't test, explicitly skip in workflow

## Implementation

### Option 1: Metadata in Files (Recommended)
Add a comment tag in each spell/imp:
```sh
# STANDALONE: gem
# STANDALONE: included
# STANDALONE: excluded
```

### Option 2: Central Configuration
Maintain lists in `.github/standalone-categories.txt`:
```
gem: hash, copy, bind-tome, ...
included: is, has, say, warn, ...
excluded: cast, spell-menu, invoke-wizardry, ...
```

### Option 3: Directory Structure
Move files into subdirectories based on category (not recommended - breaks existing structure)

## Current Results

- **Total scripts**: 256
- **Compiled**: 256 (100%)
- **Standalone successful**: Testing in progress
- **Known issues**: `cast`, `spell-menu` (as expected per "Excluded" category)
