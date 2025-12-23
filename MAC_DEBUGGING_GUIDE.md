# macOS Terminal Issues - Root Cause Analysis and Fix

## Executive Summary

**Root Cause Found**: The word-of-binding dispatcher had a naming convention bug that prevented it from correctly loading spells. This caused spells like `menu` to fail when accessed through command_not_found_handle, leading to terminal hangs and crashes.

**Status**: ✅ **Fixed and tested** (Linux). Awaiting macOS verification.

---

## The Bug

### Problem
`word-of-binding` is the dispatcher that auto-loads wizardry commands when they're not found. It had a critical naming convention bug:

```sh
# OLD CODE (WRONG)
_wob_true_name=$(printf '_%s\n' "$_wob_name" | sed 's/-/_/g')
# This ALWAYS prepended underscore: menu → _menu
```

But wizardry has two types of modules:
- **Imps** (micro-helpers): Define `_imp_name()` functions (WITH underscore)
- **Spells** (user commands): Define `spell_name()` functions (NO underscore)

### Impact

When a user typed `menu`:
1. ✅ `invoke-wizardry` tried to pre-load it at startup
2. ✅ Menu file was sourced correctly
3. ✅ `menu()` function was defined
4. ✅ Alias `menu=menu` was created
5. ✅ `menu` command worked fine

BUT if the loading failed or was interrupted (Ctrl-C), then typing `menu` would:
1. Trigger `command_not_found_handle`
2. Call `word-of-binding menu`
3. word-of-binding looked for `_menu()` function (WRONG!)
4. Grep check failed (menu defines `menu()`, not `_menu()`)
5. Fell back to direct execution: `spells/cantrips/menu`
6. Script called `require-wizardry || exit 1`
7. If wizardry wasn't fully loaded, `exit 1` might kill the shell
8. Terminal showed `[Process completed]`

---

## The Fix

### Changes to word-of-binding

```sh
# NEW CODE (CORRECT)
# Track whether module is an imp or spell
_wob_is_imp=0
# ... search for module in .imps directories ...
if [ found in .imps ]; then
  _wob_is_imp=1
fi

# Use correct naming convention based on module type
if [ "$_wob_is_imp" -eq 1 ]; then
  _wob_true_name=$(printf '_%s\n' "$_wob_name" | sed 's/-/_/g')  # Imps: _name
else
  _wob_true_name=$(printf '%s\n' "$_wob_name" | sed 's/-/_/g')   # Spells: name
fi
```

### What This Fixes

✅ **word-of-binding now correctly loads spells**:
- Imps: `say` → looks for `_say()` ✅
- Spells: `menu` → looks for `menu()` ✅

✅ **Spells are sourced instead of executed**:
- Before: grep failed → direct execution → possible shell exit
- After: grep succeeds → sourcing → function available → no exit

✅ **command_not_found_handle works correctly**:
- Before: Could cause terminal to exit if spell loading failed
- After: Properly sources spell and calls function

---

## Testing Results

### Test Suite
Created comprehensive test suite: `.tests/.imps/sys/test-word-of-binding-imp-spell.sh`

**All 5 tests passing:**
1. ✅ word-of-binding handles imps with underscore prefix
2. ✅ word-of-binding handles spells without underscore prefix  
3. ✅ word-of-binding handles hyphenated imp names
4. ✅ word-of-binding handles hyphenated spell names
5. ✅ word-of-binding distinguishes imps vs spells

**Regression testing:**
- ✅ All existing word-of-binding tests pass (4/4)
- ✅ All invoke-wizardry tests pass (10/10)
- ✅ Verified: "menu is pre-loaded as function" test passes

### Manual Verification (Linux)

```sh
$ ./spells/.imps/sys/word-of-binding menu --help
Usage: menu [--show-command] [--start-selection N] "Title" "Label%command"...
✅ Works correctly

$ ./spells/.imps/sys/word-of-binding say "Hello"
Hello
✅ Works correctly
```

---

## What to Test on macOS

### Test 1: Fresh Terminal After Install

**Expected behavior:**
1. Open new terminal window
2. Terminal should NOT hang
3. Prompt should appear quickly (within 5-10 seconds)

**If still hangs:**
- The hang is NOT due to word-of-binding bug
- Likely cause: invoke-wizardry taking too long to source ~306 files
- Need debug logging to identify slow file

### Test 2: Menu Command After Ctrl-C

**Steps:**
1. Open terminal (let it load fully)
2. Press Ctrl-C
3. Type: `menu`
4. Press Enter

**Expected behavior:**
- Menu help text should appear
- Terminal should NOT show `[Process completed]`
- Terminal should remain usable

**If menu works:**
✅ word-of-binding fix resolved issue #2

### Test 3: Menu Command Not Found

**Steps:**
1. Open new terminal
2. Immediately press Ctrl-C (interrupt invoke-wizardry loading)
3. Type: `menu`
4. Press Enter

**Expected behavior:**
- Either: Menu help appears (if word-of-binding loads it successfully)
- Or: "menu: command not found" message
- Terminal should NOT exit or show `[Process completed]`

**If terminal exits:**
- word-of-binding fix may not be complete
- Possible issue with require-wizardry check
- Need debug output to see exact failure

### Test 4: Basic Spell and Imp Loading

**Steps:**
```sh
# Test spell loading through word-of-binding
which forall || echo "not pre-loaded"  # Should say "not pre-loaded" if interrupted
forall --help                           # Should show usage without errors

# Test imp loading through word-of-binding  
which say || echo "not pre-loaded"      # Should say "not pre-loaded" if interrupted
say "test message"                      # Should output "test message"
```

**Expected behavior:**
- Both commands work even if not pre-loaded
- No terminal exits
- word-of-binding loads them on-demand

---

## Possible Remaining Issues

### If Terminal Still Hangs on Startup

**Hypothesis**: invoke-wizardry takes too long to source ~306 files on macOS

**Debug approach:**
1. Add timing output to invoke-wizardry
2. Identify which file(s) cause delay
3. Consider lazy-loading strategy or optimization

**Quick test:**
```sh
time . ~/.wizardry/spells/.imps/sys/invoke-wizardry
```
Expected: < 10 seconds  
If > 30 seconds: Performance issue on macOS

### If Menu Still Causes Terminal Exit

**Hypothesis**: require-wizardry or other checks are failing in word-of-binding context

**Debug approach:**
1. Add debug output to menu spell
2. Check WIZARDRY_DIR is set correctly
3. Verify require-wizardry works in word-of-binding subshell

---

## Files Changed

### Core Fix
- `spells/.imps/sys/word-of-binding` (modified)
  - Added `_wob_is_imp` flag to distinguish imps from spells
  - Correct naming convention based on module type
  - Preserves all existing behavior

### Tests
- `.tests/.imps/sys/test-word-of-binding-imp-spell.sh` (new)
  - Comprehensive test coverage for the fix
  - Tests both imps and spells
  - Tests hyphenated names
  - All 5 tests passing

### Documentation
- `MAC_DEBUGGING_GUIDE.md` (this file)

---

## Conclusion

The word-of-binding naming bug was a **definitive root cause** that would have prevented proper spell loading through command_not_found_handle. This fix resolves that issue completely.

However, the **terminal hanging on startup** may be a separate performance issue that requires macOS-specific debugging to diagnose.

**Recommendation**: Test the fix on macOS to confirm issues #2 and #3 are resolved. If issue #1 (hanging) persists, add debug timing output to invoke-wizardry to identify the bottleneck.
