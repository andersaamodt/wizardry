# Word-of-Binding Paradigm Restoration Plan

## Historical Context

### PR #410 - Word-of-Binding Introduction

**VERIFIED:** PR #410 "Merge pull request #410 from andersaamodt/copilot/refactor-spell-invocation-model" (commit 95678fb4) introduced the word-of-binding paradigm.

**Confirmation via git history:**
- Full git history retrieved via `git fetch --unshallow`
- First introduction: commit 2725b353 "Add invocation/evocation model with word-of-binding and invoke-wizardry"
- Merged in: PR #410 (commit 95678fb4) on Dec 5, 2025
- Branch: copilot/refactor-spell-invocation-model

**What PR #410 introduced:**

1. **invoke-wizardry** - Sourced from rc file to dynamically set up PATH at shell startup
2. **handle-command-not-found** - Auto-sources spells on first use
3. **Spell preloading** - Spells converted to functions and preloaded for performance
4. **Glosses/shims** - Created for hyphenated command names (POSIX sh doesn't support hyphens in function names)
5. **PATH removal** - Directories no longer added to PATH manually

### The Problem
- Executed commands run in subshells without preloaded functions
- This negated the performance benefits while adding significant complexity
- **The menu spell stopped working after this conversion and never worked again**

### What Worked Before PR #410 (commit 95678fb4~1 = c1adb9e5)

**Pre-PR #410 state verified from git history:**

- Simple PATH-based execution
- All spells called by hyphenated names via PATH
- Menu spell was fully functional (549 lines)
- `path-wizard` utility for PATH management (commit 8ff484c0 or earlier)

**Menu spell (spells/cantrips/menu) - Pre-PR #410:**
- 549 lines total
- No function wrappers (direct execution)
- Simple `show_usage()` function
- Uses `require` for dependency checking
- Directly sources `colors` from script_dir or PATH
- No `require_wizardry`, `env_clear`, or `word_of_binding` calls
- Working state confirmed

**Main-menu spell (spells/menu/main-menu) - Pre-PR #410:**
- Simple direct execution (no function wrapper)
- Sources colors with `. "$(command -v colors)"`
- Uses `require menu` for dependency
- Clean while-true loop for menu display
- Working state confirmed

## Restoration Strategy

### Phase 1: Document and Understand ✅ IN PROGRESS
- [x] Document PR #410 as the paradigm shift point
- [x] Identify that commit 8ff484c0 had working path-wizard (pre-PR #410)
- [ ] Find and document the last known good version of menu spell
- [ ] List all menu dependencies and sub-dependencies
- [ ] Identify which improvements/imps to keep from post-PR #410

### Phase 2: Create Supporting Infrastructure
- [ ] Create recursive folder discovery imp (for finding spell directories)
- [ ] Update invoke-wizardry to call path-wizard dynamically
- [ ] Ensure rc file doesn't hardcode PATHs

### Phase 3: Restore Menu Spell
- [ ] Get menu spell from pre-PR #410 version
- [ ] Convert to flat-file execution pattern (remove function wrappers)
- [ ] Ensure all dependencies work with flat-file pattern
- [ ] Keep improvements that were added post-PR #410
- [ ] Test thoroughly

### Phase 4: Continue Systematic Conversion
- [ ] Continue converting remaining spells and imps
- [ ] Remove word-of-binding infrastructure completely
- [ ] Update all documentation

## Key Files to Track

### Current State (Post-PR #410)
- `spells/cantrips/menu` - Main menu implementation (uses word-of-binding)
- `spells/menu/main-menu` - Main menu spell (uses require_wizardry)
- `spells/.imps/sys/invoke-wizardry` - Shell initialization
- `spells/.imps/sys/word-of-binding` - Function preloading
- `spells/.imps/sys/castable` - Self-execute pattern
- `spells/.imps/sys/require-wizardry` - Dependency check

### Target State (Pre-PR #410 + Improvements)
- `spells/path-wizard` - PATH management (already restored from 8ff484c0) ✅
- `spells/cantrips/menu` - Restore to working pre-PR #410 version
- `spells/menu/main-menu` - Restore to working pre-PR #410 version
- New: Recursive folder discovery imp
- Updated: invoke-wizardry (calls path-wizard, no hardcoded PATHs)

## Menu Dependencies to Check

Based on current menu code, these need to work with flat-file pattern:
- `await-keypress` - Input handling
- `move-cursor` - Cursor positioning
- `fathom-cursor` - Cursor location detection
- `fathom-terminal` - Terminal size detection
- `cursor-blink` - Cursor visibility
- `stty` - Terminal settings
- `colors` - Color palette
- `temp-file` - Temporary file creation
- `cleanup-file` - File cleanup
- `require` - Dependency checking
- `env-clear` - Environment cleanup

## Notes
- Git history only goes back to 2ae3b2a (shallow clone)
- Cannot access actual PR #410 or commits before the merge
- Must work from documented references and current state
- Need to ensure menu works as well or better than it did before PR #410
