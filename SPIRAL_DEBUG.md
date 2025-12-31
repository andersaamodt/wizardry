# SPIRAL_DEBUG.md - Paradigm Conversion Progress

## Current Task: Converting Back to Flat-File Execution

**Date Started:** 2025-12-31  
**Status:** In Progress

### Problem Statement

**PR #410** introduced the word-of-binding paradigm (~200 PRs ago) with these changes:
- Function preloading for performance
- Glosses/shims for hyphenated commands  
- invoke-wizardry for shell initialization
- handle-command-not-found for auto-sourcing spells
- But: executed commands run in subshells without preloaded functions!
- Result: Negated the performance benefits
- **Critical issue:** Menu spell stopped working after PR #410 and never worked again

**Decision:** Return to the old, simple PATH-based paradigm (pre-PR #410) while preserving good changes made since then.

**Reference:** See `WORD_OF_BINDING_RESTORATION.md` for complete historical context and restoration plan.

### What to Keep
✅ **KEEP:**
- Banish paradigm and levels-based organization
- Banish-style output for testing
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

### What Changes
📝 **SIMPLIFY:**
- Spells: unwrap functions, inline usage text
- Imps: remove function wrappers, keep as simple scripts
- PATH: use original `path-wizard` for PATH management
- Synonyms: generate aliases not glosses
- Function count: most spells go from 2 functions → 0 functions

### Restored Infrastructure: `path-wizard`
✅ **Restored:** `spells/path-wizard` (original version from commit 8ff484c0)

The original path-wizard utility that worked well before word-of-binding:
- Simple add/remove interface: `path-wizard add <directory>`
- Modifies `.bashrc` file directly
- Works across all tested platforms
- No complex generation or multi-mode operation
- Direct PATH manipulation that users can understand

**Usage:**
```sh
# Add a directory to PATH:
path-wizard add /some/directory

# Remove a directory from PATH:
path-wizard remove /some/directory

# Add current directory:
path-wizard add
```

This restores the proven, simple PATH management that worked well before the paradigm shift.

---

## Conversion Progress Tracker

### Phase 1: Understanding ✅ COMPLETE
- [x] Explored repository structure
- [x] Understood current paradigm (word-of-binding, glosses, castable)
- [x] Identified what to keep vs remove
- [x] Created comprehensive plan

### Phase 2: Documentation ✅ COMPLETE
- [x] Updated SPIRAL_DEBUG.md with conversion plan
- [x] Created conversion example documentation
- [x] Counted files needing conversion:
  - 189 spell files
  - 201 imp files  
  - 119 files with castable references
  - 155 imps with self-execute pattern

### Phase 3: Remove Self-Execute Pattern
- [ ] Count total files to modify
- [ ] Remove castable/uncastable imps
- [ ] Remove from all spells (~117 files)
- [ ] Remove from all imps (~100+ files)
- [ ] Verify basic execution still works

### Phase 4: Unwrap Spell Functions
- [ ] Create standard usage text format
- [ ] Convert usage functions to inline text
- [ ] Unwrap main spell logic
- [ ] Test sample spells
- [ ] Apply to all spells

### Phase 5: Unwrap Imp Functions
- [ ] Remove function definitions
- [ ] Convert to pure scripts
- [ ] Update calls from source to execute
- [ ] Test sample imps

### Phase 6: Remove Word-of-Binding
- [ ] Remove invoke-wizardry
- [ ] Remove word-of-binding imp
- [ ] Remove generate-glosses
- [ ] Remove glossary directory
- [ ] Clean up spell-levels if unused

### Phase 7: PATH-Based Architecture
- [x] **Created `path-wizard` utility** - Generates PATH setup for flat-file execution ✅
- [ ] Update install script PATH setup
- [ ] Add spell directories recursively
- [ ] Add imp directories recursively
- [ ] Remove glossary from PATH
- [ ] Test that commands work
- [ ] Add spell directories recursively
- [ ] Add imp directories recursively
- [ ] Remove glossary from PATH
- [ ] Test that commands work

### Phase 8: Synonyms to Aliases
- [ ] Keep synonym files
- [ ] Create alias generation logic
- [ ] Update RC file setup
- [ ] Test alias functionality

### Phase 9: Keep Parser
- [ ] Verify parse works standalone
- [ ] Ensure passthrough mode
- [ ] Update any references

### Phase 10: Update Tests
- [ ] Update test-bootstrap
- [ ] Remove function loading
- [ ] Add PATH setup
- [ ] Fix test failures
- [ ] Run full test suite

### Phase 11: Update EXEMPTIONS.md
- [ ] Recount functions per spell
- [ ] Update function discipline section
- [ ] Remove word-of-binding exemptions
- [ ] Document remaining helper functions

### Phase 12: Final Verification
- [ ] Full test suite passes
- [ ] Install script works
- [ ] Menu functionality works
- [ ] Documentation complete
- [ ] Ready for review

---

## Implementation Notes

## Implementation Strategy

### Current Approach
Due to the massive scale (390+ files), this conversion will be done in phases across multiple sessions.

### Conversion Pattern Established

**Example Converted: `spells/arcane/forall`**

OLD (73 lines):
- Had wrapper function `forall()`
- Used `require-wizardry || return 1`
- Used `env-clear`
- Used `say` imp
- Had complex castable loading (30 lines)
- Used `return` for exits

NEW (30 lines):
- Direct execution (no wrapper)
- Simple `show_usage()` function
- Uses `printf` instead of `say`
- Uses `exit` not `return`
- No castable code
- **58% reduction in lines!**

### Key Conversion Steps Per Spell

1. **Rename usage function:** `spell_name_usage()` → `show_usage()`
2. **Move help handler:** Before `set -eu`, change `return 0` → `exit 0`
3. **Remove wrapper:** Extract main logic from `spell_name()` function to top level
4. **Remove dependencies:**
   - Delete `require_wizardry || return 1`
   - Delete `env_clear` or `env-clear`
5. **Remove castable:** Delete entire castable loading block (~30 lines)
6. **Change returns to exits:** All `return` → `exit` in main flow
7. **Replace imp calls:** Where practical, replace with POSIX equivalents:
   - `say "text"` → `printf '%s\n' "text"`
   - `die "msg"` → `printf 'msg\n' >&2; exit 1`
   - Keep complex imps that provide real value

### Imp Conversion Pattern

OLD:
```sh
imp_name() {
  # implementation
}
case "$0" in
  */imp-name) imp_name "$@" ;; esac
```

NEW:
```sh
# Just the implementation, no function wrapper
# Direct execution
```

### Priority Order for Conversion

1. **Infrastructure First** (Phase 3-7):
   - Remove castable/uncastable imps
   - Update PATH setup in install script
   - Remove invoke-wizardry, word-of-binding, generate-glosses
   - Convert synonyms to aliases

2. **Core Spells** (small batch):
   - menu system spells
   - System management spells
   - Most commonly used utilities

3. **Imps by Category**:
   - out/ - output helpers (say, die, warn, etc.)
   - cond/ - conditionals (has, is, there, etc.)
   - sys/ - system helpers
   - Remaining families

4. **Remaining Spells** (bulk conversion):
   - Can be done in batches of 10-20
   - Test after each batch
   - May span multiple PR sessions

### Files Converted So Far

**Spells (2 of 189):**
- [x] `spells/arcane/forall` - 73 → 30 lines (-59%)
- [x] `spells/arcane/file-list` - 80 → 35 lines (-56%)

**Imps (8 of 201):**
- [x] `spells/.imps/out/say` - 13 → 5 lines (-62%)
- [x] `spells/.imps/out/die` - 18 → 11 lines (-39%)
- [x] `spells/.imps/out/warn` - 13 → 6 lines (-54%)
- [x] `spells/.imps/out/fail` - 14 → 7 lines (-50%)
- [x] `spells/.imps/out/info` - 17 → 9 lines (-47%)
- [x] `spells/.imps/cond/has` - 23 → 18 lines (-22%)
- [x] `spells/.imps/cond/is` - 30 → 26 lines (-13%)
- [x] `spells/.imps/cond/there` - 12 → 7 lines (-42%)

**Totals:**
- **Converted:** 10 of 390 files (2.6%)
- **Remaining:** 187 spells, 193 imps
- **Average code reduction:** ~45%

**Line Count Savings:**
- Spells: 153 → 65 lines (58% reduction, 88 lines saved)
- Imps: 163 → 103 lines (37% reduction, 60 lines saved)
- **Total saved:** 148 lines across 10 files
- **Projected total savings:** ~5,800 lines when complete!

---

### Next Steps
1. Start Phase 3: count files and remove castable pattern
2. Test incrementally after each major change
3. Keep tests passing throughout conversion

### Challenges Anticipated
- Large number of files to modify (~200+)
- Must maintain backwards compatibility during transition
- Tests may need significant updates
- PATH setup must be correct for all platforms

### Key Files to Modify
- All spells in `spells/*/` directories
- All imps in `spells/.imps/*/` directories  
- `install` script
- `spells/.imps/sys/invoke-wizardry` (remove)
- `spells/.imps/sys/word-of-binding` (remove)
- `spells/.imps/sys/castable` (remove)
- `spells/.imps/sys/uncastable` (remove)
- `spells/system/generate-glosses` (remove)
- Test infrastructure in `.tests/`
- `.github/EXEMPTIONS.md`

---

## Historical Context (Old Paradigm Debug - ARCHIVED)

<details>
<summary>Click to expand old glossary generation debugging (no longer relevant)</summary>

The previous paradigm attempted to preload spells as functions for performance. This section documents the debugging process that led to fixing zsh compatibility issues. This is now superseded by the return to flat-file execution.

### Root Causes Found (Historical)
1. **Zsh word splitting:** Required `setopt SH_WORD_SPLIT` 
2. **Function inheritance:** Zsh doesn't pass functions to background jobs
3. **Gloss generation:** Needed complex workarounds for function availability

### Why We're Moving Away
The complexity of maintaining function preloading (special handling for zsh, background jobs, gloss generation) outweighed the performance benefits, especially since executed commands don't inherit the preloaded functions anyway.

</details>

---

## Completion Checklist

When this conversion is complete:
- [ ] All spells are flat files with inline code
- [ ] All imps are simple executable scripts
- [ ] PATH includes all spell and imp directories
- [ ] Synonyms work as shell aliases
- [ ] No word-of-binding infrastructure remains
- [ ] Tests pass completely
- [ ] EXEMPTIONS.md reflects new function counts
- [ ] Documentation is accurate and complete

### Special Note: Menu Restoration

User has requested special handling for the menu spell:
- The menu spell worked before the word-of-binding paradigm was introduced (PR #410)
- It has not worked correctly since that conversion
- Need to restore menu and all its dependencies to pre-word-of-binding version
- Keep any improvements/new imps that were added since then
- The restoration should be from the same era as path-wizard (commit 8ff484c0) or earlier

**Menu restoration strategy:**
1. Find the exact commit where word-of-binding was introduced
2. Get the menu spell from just before that commit
3. Convert it to flat-file execution pattern (remove any function wrappers)
4. Ensure all menu dependencies work with flat-file pattern
5. Test thoroughly

**invoke-wizardry changes:**
- Instead of hardcoding PATHs in rc file, invoke-wizardry should call path-wizard
- This allows flexible discovery of spell folders each time
- RC file doesn't need updates when spell folders change
- Use recursive algorithm to discover all spell folders

**New imp needed:**
- Create simple folder/file recursion imp for discovering spell directories
