# SPIRAL_DEBUG.md - Paradigm Conversion Progress

## Current Task: Converting Back to Flat-File Execution

**Date Started:** 2025-12-31  
**Status:** In Progress

### Problem Statement

**Word-of-binding paradigm issues:**
- Function preloading for performance
- Glosses/shims for hyphenated commands  
- invoke-wizardry for shell initialization
- **Critical issue:** Executed commands run in subshells without preloaded functions (negated performance benefits)
- **Menu spell stopped working** and never worked again after this paradigm shift

**Decision:** Return to the old, simple PATH-based paradigm (pre-word-of-binding) while preserving good changes made since then.

### What to Keep vs Remove

✅ **KEEP:**
- Banish paradigm and levels-based organization
- New testing infrastructure improvements
- Demo-magic improvements
- Synonyms system (convert to aliases)
- Parser (leave in passthrough mode)

❌ **REMOVE:**
- Self-execute pattern (castable/uncastable)
- Function wrapping in spells and imps
- word-of-binding infrastructure
- invoke-wizardry preloading
- generate-glosses system
- Glossary directory system

📝 **SIMPLIFY:**
- Spells: unwrap functions, inline usage text at standard location
- Imps: remove function wrappers, keep as simple scripts
- PATH: use original `path-wizard` (renamed to `learn-spellbook`)
- Synonyms: generate aliases not glosses
- Function count: most spells go from 2 functions → 0 functions

### 💡 CRITICAL INSIGHT: Standard Element Order = Robust Help

**Standard order matters for robustness:**

1. Shebang (`#!/bin/sh`)
2. Opening comment (brief)
3. **Usage block (inline heredoc - user-facing docs)**
4. **`--help` handler (BEFORE `set -eu`!)**
5. `set -eu` strict mode
6. Main logic

**Why `--help` before `set -eu`?**
- ✅ Help works even if wizardry is NOT installed
- ✅ Help works even if dependencies are MISSING
- ✅ Help works even if something goes WRONG
- ✅ Users can ALWAYS get help without errors

### Restored Infrastructure: `learn-spellbook`

The original path-wizard utility (now learn-spellbook) that worked well before word-of-binding:
- Simple add/remove interface: `learn-spellbook add <directory>`
- Modifies shell init files (`.bashrc`, `.bash_profile`, `.profile` fallback for NixOS)
- Works across all tested platforms (Linux, macOS, NixOS, BSD)
- No complex generation or multi-mode operation

---

## Conversion Progress Tracker

### Phase 1: Understanding ✅ COMPLETE
- [x] Explored repository structure
- [x] Understood current paradigm (word-of-binding, glosses, castable)
- [x] Identified what to keep vs remove

### Phase 2: Documentation ✅ COMPLETE
- [x] Counted files needing conversion: 189 spells, 201 imps

### Phase 3: Spell Conversion ✅ COMPLETE
- [x] Remove self-execute pattern from all spells (110 files)
- [x] Unwrap spell functions (110 files)
- [x] Convert all spell categories to flat-file pattern

### Phase 4-12: Remaining Work
- [ ] Unwrap imp functions (~201 files) - Imps already use simple pattern
- [ ] Remove word-of-binding infrastructure
- [ ] PATH-based architecture with learn-spellbook
- [ ] Convert synonyms to aliases
- [ ] Update tests and EXEMPTIONS.md
- [ ] Final verification

---

## Implementation Notes

### Conversion Pattern

**Example: `spells/arcane/forall`** (73 → 30 lines, 58% reduction)

**Key conversion steps:**
1. Rename usage function to `show_usage()`
2. Move help handler before `set -eu`, change `return 0` → `exit 0`
3. Remove wrapper function, extract main logic to top level
4. Delete `require_wizardry || return 1` and `env_clear`
5. Remove castable loading block (~30 lines)
6. Change all `return` → `exit` in main flow
7. Replace imp calls with POSIX where practical

### Files Converted So Far

**15 of 107 spells (14%)** - Average 40% code reduction

**Categories Complete:**
- ✅ arcane (6/6): copy, file-list, forall, jump-trash, read-magic, trash
- ✅ crypto (3/3): evoke-hash, hash, hashchant  
- ✅ priorities (4/4): get-priority, upvote, get-new-priority, prioritize
- 🔄 enchant (1/4): enchantment-to-yaml
- 🔄 wards (1/2): ssh-barrier

**Infrastructure Updated:**
- ✅ invoke-wizardry: Simplified to PATH-based (~300 lines removed)
- ✅ learn-spellbook: Recursive PATH management for all spell/imp directories
- ✅ banish: Moved from system/ to wards/ category

**Line Reductions:**
- invoke-wizardry: ~300 lines
- arcane: 178 lines
- crypto: 150 lines
- priorities: 224 lines
- enchant: 37 lines
- **Total: ~889 lines removed**

**Remaining:** 92 spells + imps + tests + documentation

### Priority Order

1. Infrastructure (remove castable, update PATH, remove word-of-binding)
2. Core spells (menu system, system management)
3. Imps by category (out/, cond/, sys/)
4. Remaining spells (batches of 10-20)

---

## Special Note: Menu Restoration

**Menu spell worked before word-of-binding and hasn't worked since.**

**Strategy:**
1. Find commit where word-of-binding was introduced
2. Get menu spell from just before that commit
3. Convert to flat-file execution pattern
4. Ensure all dependencies work
5. Test thoroughly

---

## Completion Checklist

- [ ] All spells are flat files with inline code
- [ ] All imps are simple executable scripts
- [ ] PATH includes all spell and imp directories
- [ ] Synonyms work as shell aliases
- [ ] No word-of-binding infrastructure remains
- [ ] **Menu spell works correctly**
- [ ] Tests pass completely
- [ ] EXEMPTIONS.md updated
- [ ] Documentation accurate

---

## Conversion Session Log (2026-01-03)

### Session 1: Initial Conversion Wave
Systematic conversion of all spells to flat-file format (PR #800).

### Conversion Pattern Applied
```sh
# BEFORE (word-of-binding):
spell_usage() { cat <<'USAGE' ... USAGE }
spell() {
  case "${1-}" in --help) spell_usage; return 0 ;; esac
  require_wizardry || return 1
  set -eu
  env_clear
  # logic with underscore imps
}
castable "$@"

# AFTER (flat):
case "${1-}" in
--help|--usage|-h)
  cat <<'USAGE'
  ...
  USAGE
  exit 0
  ;;
esac
set -eu
# logic with hyphenated imps or POSIX
```

### Key Changes Per Spell
1. Remove wrapper function (e.g., `copy()` → inline code)
2. Move `--help` before `set -eu`, change `return 0` → `exit 0`
3. Remove `require_wizardry || return 1` line
4. Remove `env_clear` call
5. Remove castable loading block (~30 lines)
6. Change all `return` → `exit` in main flow
7. Convert imp calls: `has` → `command -v`, `say` → `printf`, `die`/`warn` → `printf ... >&2; exit`

### Session 2: Continuation (2026-01-03 19:00-19:45 UTC)

**Progress:** 35 spells converted (from 23 to 35)
**Categories completed:**
- ✅ enchant (4/4): disenchant, enchant, yaml-to-enchantment, enchantment-to-yaml
- ✅ mud (4/4): check-cd-hook, choose-player, decorate, look
- ✅ translocation (6/6): jump-to-marker, follow-portkey, enchant-portkey, mark-location, open-portal, open-teletype
- 🔄 system (4/6): logs, config, kill-process, package-managers
- 🔄 divination (4/5): detect-distro, detect-magic, detect-posix, detect-rc-file

**Commits this session:**
1. `1c8a92e` - enchant category (3 spells)
2. `1c04b3b` - mud category (4 spells)
3. `96a611f` - detect-distro
4. `46ab8dc` - jump-to-marker (source-only spell)
5. `25fd20a` - translocation category (5 spells)
6. `0ef68d7` - system category (4 spells)
7. `5e70154` - detect-magic
8. `8457c53` - detect-posix (bootstrap spell)
9. `[current]` - detect-rc-file

**Line reductions:**
- enchant: ~107 lines removed
- mud: ~193 lines removed
- translocation: ~227 lines removed
- system: ~161 lines removed
- divination: ~152 lines removed (so far)
- **Total this session: ~840 lines removed**

**Special cases handled:**
- Source-only spells (jump-to-marker): Removed uncastable infrastructure, kept `return 0 2>/dev/null || exit 0` pattern
- Bootstrap spells (detect-posix): Preserved inline helpers, removed castable wrapper
- Spells with internal helpers (detect-rc-file): Kept helper functions, removed outer wrapper

### Session 3: Continuation - SPELL CONVERSION COMPLETE (2026-01-03 19:50-21:00 UTC)

**Progress:** All 110 spells converted (100% complete) ✅

**Categories completed:**
- ✅ divination (5/5): identify-room
- ✅ system (6/6): pocket-dimension, update-all
- ✅ wards (1/1): banish
- ✅ cantrips (34/34): ALL 34 cantrips
- ✅ spellcraft (15/15): ALL 15 spells
- ✅ menu (22/22): ALL 22 menu spells (including subdirectories)

**Commits this session:**
1. `a1853cb` - divination and system categories (3 spells)
2. `5770d45` - wards/banish (1 spell)
3. `987f99d` - cantrips/ask + SPIRAL_DEBUG update (1 spell)
4. `23bb3bb` - All cantrips (33 spells)
5. `d0ab20c` - spellcraft and menu (37 spells) - CONVERSION COMPLETE

**Line reductions this session:**
- divination: 4 lines
- system: 77 lines
- wards: 46 lines
- cantrips: ~1,563 lines
- spellcraft: ~725 lines
- menu: ~1,001 lines
- **Total this session: ~3,416 lines removed**

**Automation:**
- Created Python conversion script for efficiency
- Batch processed 70+ spells with consistent quality
- Fixed usage output redirections programmatically

**All Spells Now Converted:**
- arcane (6), crypto (3), priorities (4), enchant (4), mud (4)
- translocation (6), divination (5), system (6), wards (1)
- cantrips (34), spellcraft (15), menu (22)
- **Total: 110/110 spells (100%)**

### Next Steps
- Remove word-of-binding infrastructure
- Update PATH to include spell directories directly
- Run comprehensive test suite
- Update documentation
