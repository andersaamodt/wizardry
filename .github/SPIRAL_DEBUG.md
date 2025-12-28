# Spiral Debug Process

## Problem Statement

Ever since switching to the invoke-wizardry / handle-command-not-found / word-of-binding paradigm, we haven't gotten invoke-wizardry working properly. Specifically, the 'menu' command doesn't work after install in a fresh terminal window.

This document tracks the spiral debug process: commenting out code to strip down to a bare minimum core, getting that working, then gradually re-enabling features.

## Core Components (Must Work)

These are the essential components that MUST work before we proceed:

1. **install** - The installation script
2. **invoke-wizardry** - Shell initialization that sources spells/imps
3. **handle-command-not-found** / **word-of-binding** - Fallback for commands not found
4. **cd hook** - Directory change hook for MUD features
5. **menu** - The interactive menu system

## Debugging Phases

### Phase 0: Initial State Assessment

- **Date**: 2025-12-28
- **Status**: Starting spiral debug
- **Current Issues**:
  - invoke-wizardry has extensive diagnostic output but may be hanging
  - Tests are taking too long to complete (stopped after 30s)
  - Menu may not be available after fresh install

### Phase 1: Minimize invoke-wizardry to word-of-binding + minimal pre-loading

**Goal**: Strip invoke-wizardry down to:
1. Pre-load menu and its imp dependencies (for immediate availability)
2. Set up command_not_found_handle with word-of-binding for hotloading everything else

**The hybrid paradigm** (pre-load + hotload):
1. **Pre-load**: menu spell + essential imps it needs (has, say, die, warn, require, etc.)
2. **Hotload**: Everything else loads on-demand via word-of-binding
3. command_not_found_handle calls word-of-binding when a command isn't found
4. word-of-binding finds the spell/imp and either sources or executes it

**Pre-loaded components**:
- **Imps**: require, require-wizardry, castable, env-clear, temp-file, cleanup-file, has, die, warn, fail, say
- **Spells**: menu, await-keypress, move-cursor, fathom-cursor, fathom-terminal, cursor-blink, colors

**Hotloaded** (via command_not_found_handle):
- All other spells and imps load on first use

**Changes made**:
1. Removed 900+ lines of diagnostic output
2. Removed full spell/imp pre-loading loops
3. Added minimal pre-loading for menu + its dependencies
4. Kept command_not_found_handle setup for hotloading
5. Deferred: invoke-thesaurus, cd hook, user spell loading

**Why this is better**:
- Menu available immediately (pre-loaded)
- Everything else loads on-demand (performant)
- More UNIXy: on-demand loading via command-not-found hook
- Simpler: ~250 lines vs 1000+ lines

### Phase 2: Test Minimal Install

**Goal**: Verify that a minimal install works and menu is accessible in a fresh shell.

**Test Steps**:
1. Run install script
2. Open new shell (source the rc file)
3. Try to run `menu` command
4. Verify it works

### Phase 3: Add Back Features Incrementally

After Phase 2 works, add back one feature at a time:

1. **First**: Re-enable full imp loading (all families)
2. **Second**: Re-enable full spell loading
3. **Third**: Re-enable invoke-thesaurus (synonyms)
4. **Fourth**: Re-enable cd hook
5. **Fifth**: Re-enable user spell loading

Test after each addition to identify what breaks.

### Phase 4: Optimize and Clean Up

After all features work:
1. Remove excessive diagnostic output
2. Optimize loading performance
3. Update tests to match new architecture
4. Document the final working pattern

## Changes Log

### 2025-12-28: Initial Document Creation

- Created this document to track the spiral debug process
- Identified core components that must work
- Outlined debugging phases

### 2025-12-28: Phase 1 Implementation (Multiple Attempts)

- **First attempt (WRONG)**: Created PATH-only approach - but this was the OLD paradigm we moved away from
- **Second attempt (INCOMPLETE)**: Created hotload-only (no pre-loading) - but we need BOTH
- **Final implementation (CORRECT)**: Hybrid approach with pre-load + hotload
  - Pre-loads menu + essential imps (has, say, die, warn, require, castable, etc.)
  - Sets up command_not_found_handle for hotloading everything else
  - Uses AWK extraction + eval for pre-loading (same as original, just minimal set)
- **Test results**: 
  - ✅ invoke-wizardry sources successfully
  - ✅ menu function pre-loaded and available
  - ✅ Essential imps (_has, _say, _die, _warn) pre-loaded
  - ✅ command_not_found_handle defined for hotloading
  - ✅ menu --help works immediately
- **Next**: User will manually test in real terminal before Phase 2

### 2025-12-28: Fix menu colors loading when colors is preloaded

- **Issue**: menu was calling `. colors` when `colors` was preloaded as a function, leading to `no such file or directory: colors` after a fresh install.
- **Fix**: menu now sources the colors file when `command -v colors` returns a path, otherwise it invokes the already-loaded `colors` function.
- **Next**: Re-test `menu` in a fresh terminal after install.

### 2025-12-28: Hotload main-menu when menu has no entries

- **Issue**: `menu` in a fresh shell returned "no menu entries provided" because `main-menu` was not preloaded and the `has` check never invoked word-of-binding.
- **Fix**: when no entries are passed, `menu` now attempts to load and run `main-menu` via word-of-binding before erroring.
- **Next**: Re-test `menu` in a fresh terminal after install.

## Testing Strategy

For each phase, we will:
1. Make the code changes
2. Test manually with a fresh install
3. Verify the core functionality works
4. Document results here
5. Proceed to next phase only if current phase succeeds

## Success Criteria

The spiral debug is complete when:
1. ✅ install completes without errors
2. ✅ invoke-wizardry loads without hanging
3. ✅ Opening a new terminal makes menu available
4. ✅ menu command works correctly
5. ✅ cd hook works (if enabled)
6. ✅ word-of-binding can load spells on demand

## Notes

- Focus on getting the bare minimum working first
- Don't worry about test failures initially - we'll fix tests after core works
- Document every change so we can track what breaks what
