# Parse Loop Debug History

## Final Root Cause (2025-12-31)

**Primary bug:** Zsh doesn't perform word splitting by default in for-loops. Fixed by enabling `SH_WORD_SPLIT`.

**Secondary bug:** `castable` checked `_WIZARDRY_SOURCING_SPELL` but `word-of-binding` sets `_WIZARDRY_LOADING_SPELLS=1`. When loading level 3 spells (fathom-cursor, etc.), castable didn't skip execution, causing spell functions to run with hyphenated command calls → parse loop.

**Solution:** 
- Enable SH_WORD_SPLIT in invoke-wizardry for zsh
- Fix castable to check `_WIZARDRY_LOADING_SPELLS`
- Add comprehensive logging to track execution

## Current Status

### Working
- ✅ Word splitting fixed (all imps/spells load correctly)
- ✅ Castable variable check fixed
- ✅ Invoke-wizardry completes level 0-3 loading
- ✅ All function preloading succeeds
- ✅ Logging shows exact execution flow

### Still Hanging
- ⏳ Background gloss generation process hangs
- ⏳ Foreground shell completion may be affected
- ⏳ Terminal title shows parse loop indicators

### Next Steps
1. Add logging to generate-glosses background process
2. Investigate what triggers parse during background execution
3. Verify env-clear doesn't interfere with background jobs
4. Test with WIZARDRY_DEBUG_LEVEL on macOS

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

### Dec 31: Parse Loop Hunt
- **08:00** - Loop occurring during level 3 spell loading
- **09:00** - Added comprehensive logging to invoke-wizardry
- **09:30** - Identified hang at "Loading spell: fathom-cursor" 
- **10:00** - Discovered castable variable mismatch bug
- **10:30** - Fixed castable to check _WIZARDRY_LOADING_SPELLS
- **11:00** - Still hanging - foreground AND background processes
- **Current** - Need to investigate background process behavior

## Key Lessons

1. **Variable names matter**: Mismatch between castable check and word-of-binding caused hours of debugging
2. **Logging is essential**: Without detailed logging, would never have found the exact hang point
3. **Test incrementally**: Each fix revealed another layer of the problem
4. **Zsh differences**: Word splitting and shell-specific behaviors cause subtle bugs
5. **Background processes**: Async operations complicate debugging (can't see stderr easily)

## Architecture Notes

### Function Loading
- word-of-binding sources spell files with _WIZARDRY_LOADING_SPELLS=1
- Spells end with `castable "$@"` 
- Castable MUST check _WIZARDRY_LOADING_SPELLS to skip execution during load
- If castable doesn't skip, spell function runs during sourcing → calls hyphenated commands → parse loop

### Gloss System
- Glossary prepended to PATH
- Each gloss: `exec parse "spell-name" "$@"`
- parse removes glossary from PATH, finds real command
- Background generation must not trigger parse loops

### Parse Loop Indicators
- macOS terminal title shows "parse parse parse..."
- Process hangs indefinitely
- No error messages (just loops)
- Only visible through process monitoring or terminal title

## For Future AI Agents

**When investigating parse loops:**
1. Add logging at every step (function entry, command calls, returns)
2. Check what variables word-of-binding/castable use
3. Verify underscore vs hyphenated names in ALL function calls
4. Look for background processes that might trigger loops
5. Test with minimal configuration first
