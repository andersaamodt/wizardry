# Parse Loop Debug History

## FINAL SOLUTION (2025-12-31 13:00 UTC)

**Root Cause DEFINITIVELY Found:** Glosses used `exec parse "command"` but `exec` cannot execute shell functions - only actual executable files. When a gloss tried to run, it failed with "parse: not found" because `parse` was only loaded as a function, not available in PATH.

**Problem Flow:**
1. User runs `main-menu` (preloaded function)
2. `main-menu` calls `require menu "..."`
3. `require` checks `command -v require-command`
4. Finds gloss `/path/.glossary/require-command`
5. Gloss tries `exec parse "require-command" "$@"`
6. **`exec` fails** - cannot execute functions, only files
7. Shell hangs with "parse: not found"

**Solution Applied:**
- Modified `generate-glosses` to use **full path** to parse executable
- Changed from: `exec parse "cmd" "$@"`
- Changed to: `exec "$WIZARDRY_DIR/spells/.imps/lex/parse" "cmd" "$@"`
- This ensures glosses can always find parse regardless of PATH state

**Status:** ✅ **FIXED**
- All 6 generate-glosses tests pass
- 12/12 require tests pass
- Verified: glosses execute without hanging
- Verified: main-menu scenario works without timeout

## Previous Root Causes (Already Fixed)

**Primary bug:** Zsh doesn't perform word splitting by default in for-loops. Fixed by enabling `SH_WORD_SPLIT`.

**Secondary bug:** `castable` checked `_WIZARDRY_SOURCING_SPELL` but `word-of-binding` sets `_WIZARDRY_LOADING_SPELLS=1`. When loading level 3 spells (fathom-cursor, etc.), castable didn't skip execution, causing spell functions to run with hyphenated command calls → parse loop.

**Solutions:** 
- Enable SH_WORD_SPLIT in invoke-wizardry for zsh
- Fix castable to check `_WIZARDRY_LOADING_SPELLS`
- Add comprehensive logging to track execution

## Debug Timeline

### Dec 28-29: Initial Investigation
- Discovered menu not working after fresh install
- Tried hotloading, PATH-only approaches
- Settled on hybrid preload + gloss system

### Dec 30: Glossary System Implementation
- Created generate-glosses spell
- Implemented parse imp with recursion prevention
- Added async background gloss generation
- Found BSD/GNU find compatibility issues (fixed with find-executable imp)

### Dec 31: Parse Loop Hunt - RESOLVED
- **08:00** - Loop occurring during level 3 spell loading
- **09:00** - Added comprehensive logging to invoke-wizardry
- **09:30** - Identified hang at "Loading spell: fathom-cursor" 
- **10:00** - Discovered castable variable mismatch bug
- **10:30** - Fixed castable to check _WIZARDRY_LOADING_SPELLS
- **11:00** - Still hanging - foreground AND background processes
- **13:00** - **FOUND ROOT CAUSE**: Glosses use `exec parse` but exec can't execute functions!
- **13:15** - **FIXED**: Changed glosses to use full path to parse executable
- **13:30** - **VERIFIED**: All tests pass, no more hangs

## Key Lessons

1. **Variable names matter**: Mismatch between castable check and word-of-binding caused hours of debugging
2. **Logging is essential**: Without detailed logging, would never have found the exact hang point
3. **Test incrementally**: Each fix revealed another layer of the problem
4. **Zsh differences**: Word splitting and shell-specific behaviors cause subtle bugs
5. **Background processes**: Async operations complicate debugging (can't see stderr easily)
6. **exec vs functions**: `exec` cannot execute shell functions - only actual executable files!
7. **PATH assumptions**: Don't assume functions will be in PATH - use full paths for exec

## Architecture Notes

### Function Loading
- word-of-binding sources spell files with _WIZARDRY_LOADING_SPELLS=1
- Spells end with `castable "$@"` 
- Castable MUST check _WIZARDRY_LOADING_SPELLS to skip execution during load
- If castable doesn't skip, spell function runs during sourcing → calls hyphenated commands → parse loop

### Gloss System (UPDATED)
- Glossary prepended to PATH
- Each gloss: `exec "$WIZARDRY_DIR/spells/.imps/lex/parse" "spell-name" "$@"`
- **CRITICAL**: Must use full path to parse because exec cannot execute functions
- parse removes glossary from PATH, finds real command
- Background generation creates ~390 glosses for all spells, imps, and synonyms

### Parse Loop Indicators
- macOS terminal title shows "parse parse parse..."
- Process hangs indefinitely
- No error messages (just loops)
- Only visible through process monitoring or terminal title
- **Or**: "parse: not found" error when exec fails to find parse

## For Future AI Agents

**When investigating parse loops:**
1. Add logging at every step (function entry, command calls, returns)
2. Check what variables word-of-binding/castable use
3. Verify underscore vs hyphenated names in ALL function calls
4. Look for background processes that might trigger loops
5. Test with minimal configuration first
