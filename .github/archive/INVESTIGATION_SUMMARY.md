# Investigation Summary: "menu: command not found" Issue

## Problem Statement

After installing wizardry on macOS, opening a new terminal window results in:
```
menu: command not found
```

Despite no errors appearing during shell initialization.

## Investigation Findings

### 1. Pre-loading Works in Tests ✓

The `menu` spell IS being pre-loaded successfully in all automated tests:
- Test: "menu is pre-loaded as function" **PASSES**
- Test: "invoke-wizardry works when sourced from rc file" **PASSES**  
- Manual testing confirms menu function is defined after sourcing invoke-wizardry

### 2. Hotloading is for User Spellbooks Only

The hotloading mechanism (command_not_found_handle + word-of-binding) is designed for **user spellbooks** (`~/.spellbook`), not for core wizardry spells.

**Current implementation (Spiral Debug Phase 1):**
- Menu and its dependencies are pre-loaded
- Other core spells use hotloading (temporary measure)
- User spellbooks use hotloading

**Future implementation:**
- ALL wizardry spells will be pre-loaded
- ONLY user spellbooks will use hotloading

**How hotloading works:**
1. User types unknown command (e.g., `my-custom-spell`)
2. Shell triggers `command_not_found_handle`
3. Handler executes `word-of-binding my-custom-spell` in a **subshell**
4. word-of-binding loads spell from ~/.spellbook, calls it, subshell exits
5. Function is **not persisted** (re-loaded on each use)

**Implication:** Core wizardry spells like `menu` cannot rely on hotloading - they must be pre-loaded.

### 3. The Issue Is Environment-Specific

Since tests pass but users report failures, the issue must be:
- macOS/zsh specific behavior
- User environment interference
- RC file configuration issues
- Path or permission problems

## Solution Implemented

### Debug Mode (Primary Fix)

Added `WIZARDRY_DEBUG=1` support to invoke-wizardry:

```bash
# Add to RC file before invoke-wizardry line:
export WIZARDRY_DEBUG=1
```

Output shows exactly what's happening:
```
[invoke-wizardry] Starting wizardry initialization
[invoke-wizardry] WIZARDRY_DIR=/Users/username/.wizardry
[invoke-wizardry] Pre-loading essential imps
[invoke-wizardry] Pre-loading essential spells
[invoke-wizardry] Loading spell: menu
[invoke-wizardry]   ✓ Loaded: menu    <-- or ✗ Failed: menu
[invoke-wizardry] Setting up command_not_found handlers
[invoke-wizardry]   ✓ bash command_not_found_handle configured
[invoke-wizardry] Wizardry initialization complete
```

### Comprehensive Troubleshooting Guide

Created `.github/TROUBLESHOOTING.md` with:
- Step-by-step debugging instructions
- Common failure scenarios and solutions
- Explanation of pre-loading vs hotloading
- Manual workarounds
- What to include when reporting issues

### Test Improvements

- Fixed test for recursion guard variable (`_WIZARDRY_IN_CNF`)
- Removed obsolete cd function test (MUD features are now separate)
- All relevant tests pass

## Architecture Clarification

### Current (Spiral Debug Phase 1)

**Minimal Pre-loading:**
- Menu and its dependencies are pre-loaded as persistent functions
- Essential imps needed by menu are pre-loaded
- This is the minimal viable setup for Phase 1

**Hotloading:**
- Currently used for other wizardry spells (temporary during spiral debug)
- Intended for user spellbooks in `~/.spellbook`
- Does not persist functions (re-loads on each use)

### Future (Post-Spiral Debug)

**Full Pre-loading:**
- ALL wizardry spells will be pre-loaded
- Functions persist for entire shell session

**Hotloading:**
- ONLY for user spellbooks in `~/.spellbook`
- Provides on-demand execution of custom user spells

## Possible Root Causes

Based on the investigation, likely causes for user-reported failures:

### 1. Double Sourcing
- User has invoke-wizardry in both `.zprofile` AND `.zshrc`
- Second sourcing is blocked by `_WIZARDRY_INVOKED` guard
- Functions from first sourcing might be cleared before second attempt

### 2. Shell Configuration Interference
- User's `.zshrc` has `hash -r` or similar that clears functions
- User has aliases or functions that shadow wizardry commands
- User's environment modifies function scope somehow

### 3. File System Issues
- Permissions on wizardry files
- Path contains special characters or spaces
- WIZARDRY_DIR detection fails in zsh

### 4. AWK Compatibility
- macOS awk behaves differently than GNU awk
- AWK extraction fails silently (was hidden by `2>/dev/null || :`)
- Now visible in debug mode

### 5. zsh-Specific Behavior
- zsh function scoping differs from bash
- zsh expansion ${(%):-%x} fails
- zsh treats eval'd functions differently

## Next Steps

### For Users Experiencing the Issue:

1. **Enable debug mode** - Add `export WIZARDRY_DEBUG=1` before invoke-wizardry line
2. **Open new terminal** - Collect the debug output
3. **Check for failures** - Look for `✗ Failed:` messages
4. **Report findings** - Include debug output in issue report

### For Repository Maintainers:

1. **Wait for debug output** from users experiencing the issue
2. **Identify patterns** - What's common across failure reports?
3. **Add specific fixes** based on identified root cause
4. **Consider enhancements**:
   - Self-healing: If menu fails to load, try again with verbose errors
   - Validation: Add a self-test that runs after invoke-wizardry
   - Fallback: Provide alternative loading mechanism for problem cases

## Files Changed

1. `spells/.imps/sys/invoke-wizardry` - Added debug mode
2. `.tests/.imps/sys/test-invoke-wizardry.sh` - Fixed tests
3. `.github/TROUBLESHOOTING.md` - Created troubleshooting guide

## Verification

All tests pass:
```
✓ menu is pre-loaded as function
✓ invoke-wizardry works when sourced from rc file
✓ invoke-wizardry maintains permissive shell mode
✓ command_not_found_handle has recursion guard
```

Manual testing confirms:
- Debug mode works correctly
- menu is loaded successfully in test environments
- Troubleshooting guide is comprehensive

## Conclusion

The debug mode and troubleshooting guide provide users with tools to:
1. Diagnose their specific failure
2. Work around the issue temporarily
3. Report actionable information

This moves us from "it doesn't work" to "here's exactly where it's failing" which enables targeted fixes.
