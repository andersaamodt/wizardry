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

### Phase 1: Minimize invoke-wizardry

**Goal**: Strip invoke-wizardry down to only load the core imps and spells needed for menu to work.

**Changes to make**:
1. Comment out all non-essential imp families (keep only: cond, out, sys)
2. Comment out all spell loading except menu and its dependencies
3. Comment out user spell loading
4. Comment out invoke-thesaurus
5. Comment out cd hook
6. Reduce diagnostic output to critical errors only

**Dependencies for menu**:
- Imps: cond/has, out/say, out/die, out/warn, sys/require, sys/require-wizardry, sys/castable, sys/env-clear
- Helper spells: await-keypress, move-cursor, fathom-cursor, fathom-terminal, cursor-blink, colors
- Temp file management: temp-file, cleanup-file

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
