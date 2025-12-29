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
- **Imps**: all imps up through level 2 (from `spells/.imps/sys/spell-levels`)
- **Spells**: all spells up through level 2 (from `spells/.imps/sys/spell-levels`)

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
  - ✅ Essential imps (has, say, die, warn) pre-loaded
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

### 2025-12-28: Enforce menu preloading (no fallback)

- **Issue**: `menu` could resolve to `word-of-binding` without arguments in a fresh shell when the preloaded menu function was missing, leading to "word-of-binding: command name required".
- **Fix**: removed the fallback wrapper and now fail fast if the menu spell is not preloaded during invoke-wizardry.
- **Next**: Re-test `menu` in a fresh terminal after install; if it fails, continue stripping down invoke-wizardry to find the preloading break.

### 2025-12-28: Phase 1a - Strip confounders, verify menu binding explicitly

- **Goal**: Prove whether `menu` is actually bound as a shell function after invoke-wizardry runs, without command-not-found interference.
- **Changes**:
  - Removed fallback menu sourcing (no workaround).
  - Added debug logging of menu binding (`whence`/`type`) when `WIZARDRY_DEBUG=1`.
  - Added `WIZARDRY_SPIRAL_MINIMAL=1` to skip command-not-found handlers so only preloading is tested.
- **Local tests (container)**:
  - `zsh -c 'source spells/.imps/sys/invoke-wizardry; whence -v menu; menu --help'` → menu is a function, help prints.
  - `WIZARDRY_DEBUG=1 WIZARDRY_SPIRAL_MINIMAL=1 zsh -c 'source spells/.imps/sys/invoke-wizardry; whence -v menu; menu --help'` → menu bound and callable with CNF disabled.
  - Diagnostic: `command_not_found_handler` always receives args; when calling `word_of_binding "$@"`, `word_of_binding` sees the command name. The error `word-of-binding: command name required` happens **before** CNF output, so it is not caused by CNF.
- **Working hypothesis**:
  - The observed `word-of-binding: command name required` implies that the `menu` *command* is directly invoking `word-of-binding` with no arguments. That only happens if `menu` resolves to an executable wrapper (or script) that calls `word-of-binding` without args, or if `menu` isn't bound as a function at all.
  - Next step is to test in a fresh terminal:
    1. Set `WIZARDRY_DEBUG=1 WIZARDRY_SPIRAL_MINIMAL=1` and open a new shell.
    2. Run: `type menu` (bash) or `whence -v menu` (zsh) and record the output.
    3. Run `menu --help` and confirm whether it uses the function or hits the error.
    4. If it fails, capture: `command -v menu`, `alias menu`, and the output of `type menu`/`whence -v menu`.

### 2025-12-28: Preload via word-of-binding bind-only

- **Changes**:
  - Switched `word-of-binding` to bind-only by default (no alias creation; no execution unless `--run` is used).
  - Updated `invoke-wizardry` to source `word-of-binding` and preload menu + essential imps/spells using bind-only calls.
  - Updated command-not-found handlers to call `word_of_binding --run` when executing missing commands.
  - Updated `menu` to call `word_of_binding --run main-menu` when no entries are provided.
  - Added a hard failure if `word-of-binding` cannot be sourced (preloading cannot proceed).
- **Local tests (container, bash)**:
  - `bash -lc 'source spells/.imps/sys/invoke-wizardry; type menu'` → menu is a function.
  - `bash -lc 'source spells/.imps/sys/invoke-wizardry; menu --help | head -n 3'` → usage text prints.
  - `bash -lc 'source spells/.imps/sys/invoke-wizardry; command -v word_of_binding'` → function available.
  - Note: full interactive menu run requires a TTY; not exercised in this container.

### 2025-12-28: Preload all level 0-2 spells and imps

- **Change**: `invoke-wizardry` now preloads every spell and imp defined through level 2 using `spells/.imps/sys/spell-levels`.
- **Why**: keeps the preload set aligned with spell level definitions while still supporting the spiral debug minimal boot.

### 2025-12-28: Remove leading underscores from imp true-names

- **Changes**:
  - Renamed all imp true-names to drop the leading underscore (imps now match spells: `imp-name` → `imp_name()`).
  - Updated `word-of-binding` to use the same true-name mapping for spells and imps.
  - Updated `invoke-wizardry`, menu, and tests to use `word_of_binding` (no leading underscore) and the new imp function names.
  - Hardened `has`/`require` to treat hyphenated command names as underscore function names when checking availability.

### 2025-12-28: Fix menu navigation - preloaded spells cannot use $0

- **Issue**: Menu was printing correctly but arrow keys did nothing and Enter just reprinted the menu.
- **Root cause**: 
  - When spells are preloaded as functions via `word_of_binding`, `$0` refers to the shell name (e.g., `zsh`), not the script path
  - Several preloaded spells (`await-keypress`, `fathom-cursor`, `fathom-terminal`, `require-command`, `menu`) used `$0` for path resolution
  - Path resolution failed, causing dependency lookups to fail
  - `await-keypress` couldn't properly initialize, returned empty values to menu
  - Menu loop continued with empty `$key`, slept 0.05s, and repeated (no navigation)
- **Fix**:
  - Changed all affected spells to use `command -v` for dependency resolution instead of `$0` path resolution
  - Pattern matches what `require` imp already does successfully
  - Works in both modes: direct execution and preloaded as function
  - Delayed path computation in `require-command` until actually needed
  - Optimized `menu` colors loading to avoid unnecessary `$0` usage when preloaded
- **Files changed**:
  - `spells/cantrips/await-keypress` - Fixed require-command resolution
  - `spells/cantrips/fathom-cursor` - Fixed require-command resolution
  - `spells/cantrips/fathom-terminal` - Fixed require-command resolution
  - `spells/cantrips/menu` - Optimized colors loading
  - `spells/cantrips/require-command` - Delayed $0 usage
- **Testing**:
  - Existing tests pass: `test-await-keypress.sh`, `test-fathom-cursor.sh`, `test-fathom-terminal.sh`
  - invoke-wizardry successfully preloads all spells
  - `menu --help` works correctly after preloading
  - All dependency checks pass when preloaded
- **Next**: User should test menu navigation in actual terminal to confirm arrow keys work

### 2025-12-28: Add debug logging for menu navigation issue

- **Issue**: Menu still not responding to arrow keys or Enter after previous fixes
- **Changes**: Added debug logging to `await-keypress` and `menu` to diagnose what's happening
- **Debug flags**:
  - `WIZARDRY_DEBUG_AWAIT=1` - Shows await-keypress internal state
  - `WIZARDRY_DEBUG_MENU=1` - Shows keys received by menu
- **Testing instructions**:
  ```bash
  # In your terminal, set debug flags and run menu:
  export WIZARDRY_DEBUG_AWAIT=1
  export WIZARDRY_DEBUG_MENU=1
  menu
  
  # Then try pressing:
  # 1. Down arrow key
  # 2. Up arrow key  
  # 3. Enter key
  
  # Capture the debug output and share it
  ```
- **What to look for**:
  - Does `await-keypress` show "Found require-command"?
  - Does `await-keypress` show "dd check passed"?
  - Does `await-keypress` show "Read codes: ..." when you press keys?
  - What does `await-keypress` return for arrow keys? (should be "up" or "down")
  - What does `await-keypress` return for Enter? (should be "enter")
  - What does menu receive? Does it match what await-keypress returns?

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
