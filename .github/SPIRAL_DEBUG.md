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

### Phase 3-12: Remaining Work
- [ ] Remove self-execute pattern (~217 files)
- [ ] Unwrap spell functions (~189 files)
- [ ] Unwrap imp functions (~201 files)
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

**10 of 390 files (2.6%)** - Average 45% code reduction, projected ~5,800 line savings

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
