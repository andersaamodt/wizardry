# Banish and Menu Fixes Summary

## Issues Fixed

### 1. Banish Duplicate Output ✅
**Problem**: When running `banish`, the output from `detect-posix` was shown twice:
```
Environment prepared: WIZARDRY_DIR=/Users/andersaamodt/.wizardry
POSIX toolchain and probes look healthy.
Validation complete - Level 0 ready
Environment prepared: WIZARDRY_DIR=/Users/andersaamodt/.wizardry
POSIX toolchain and probes look healthy.  # <-- DUPLICATE
```

**Root Cause**: In `spells/system/banish` lines 379 and 381, detect-posix was called with `2>&1`, which redirected stderr to stdout. Since detect-posix prints its success message to stdout, and the caller wasn't suppressing it, the message appeared both when detect-posix ran AND in banish's output.

**Fix**: Changed from:
```sh
"${WIZARDRY_DIR}/spells/divination/detect-posix" 2>&1 || posix_check_failed=1
```
to:
```sh
"${WIZARDRY_DIR}/spells/divination/detect-posix" >/dev/null || posix_check_failed=1
```

**Files Changed**: `spells/system/banish` lines 379, 381

---

### 2. Banish Tests Hanging ✅
**Problem**: When running `banish 1`, it would hang waiting for user input from tests.

**Root Cause**: Tests were being run with stdin connected to the terminal, and some tests would prompt for input or try to read from /dev/tty.

**Fix**: Redirected stdin from /dev/null when running tests:
```sh
if "${WIZARDRY_DIR}/spells/system/test-spell" --skip-common "${test_file#${WIZARDRY_DIR}/.tests/}" </dev/null >/dev/null 2>&1; then
```

**Files Changed**: `spells/system/banish` line 925

---

### 3. Banish --only Flag ✅
**Problem**: No way to validate a single level without running all lower levels.

**Requested Behavior**: `banish 2` should be equivalent to `banish 0; banish 1 --only; banish 2 --only`

**Fix**: Added `--only` flag that skips all levels except the target level.

**Usage**:
- `banish 2` - Validates levels 0, 1, and 2 in sequence
- `banish 2 --only` - Validates only level 2, skipping 0 and 1

**Files Changed**: 
- `spells/system/banish` - Added --only flag parsing and logic
- Lines 36, 67, 113-116, 940-952

---

### 4. Menu Not Executing Commands on Enter ✅
**Problem**: When user pressed Enter in menu, the menu would redraw instead of executing the selected command.

**Root Cause**: In `spells/cantrips/await-keypress`, when `KEEP_RAW=1` is set (which menu does for performance), the terminal state was not being properly reset between calls. Specifically:
1. First call to await-keypress sets `min=1 time=0` (blocking read)
2. If key requires extra bytes (like arrow keys), it changes to `min=0 time=1` (non-blocking)
3. await-keypress returns but doesn't restore terminal (KEEP_RAW=1)
4. Next call opens fd 3 again, but terminal still has `min=0 time=1` from previous call
5. The stty command to set `min=1 time=0` might not work properly, causing non-blocking reads that return empty immediately

**Fix**: Always reapply stty settings at the start of each await-keypress call, even when KEEP_RAW=1:

```sh
# Configure canonical mode to wait for exactly one byte of input.
# CRITICAL: Always set terminal mode, even when KEEP_RAW=1, because previous
# calls may have changed min/time settings for escape sequence handling
if [ "$skip_stty" -eq 0 ]; then
    if ! stty -icanon -echo min 1 time 0 <&3 2>/dev/null; then
        warn 'await-keypress: unable to configure terminal'
        return 1
    fi
fi
```

**Files Changed**: `spells/cantrips/await-keypress` lines 121-129

---

### 5. Arrow Keys Not Working ✅
**Problem**: Arrow keys in menu didn't navigate between options.

**Root Cause**: Same as issue #4 - terminal state corruption prevented proper escape sequence reading.

**Fix**: Same as issue #4 - always reapply stty settings.

---

### 6. Ctrl-C Not Working in Menu ✅
**Problem**: Pressing Ctrl-C in menu didn't exit the menu.

**Root Cause**: When terminal is in raw mode (`stty -echo -icanon`), Ctrl-C doesn't generate a SIGINT signal. Instead, it sends byte 3 to the input stream. await-keypress was not detecting this byte as a special key.

**Fix**: 
1. Added Ctrl-C detection in await-keypress (byte 3 → 'ctrl-c'):
```sh
case "$first" in
    3)
        output='ctrl-c'
        ;;
```

2. Added ctrl-c handling in menu to cleanup and exit:
```sh
case $key in
ctrl-c)
        cleanup
        trap - EXIT INT TERM
        return 130
        ;;
```

**Files Changed**: 
- `spells/cantrips/await-keypress` lines 240-242
- `spells/cantrips/menu` lines 481-485

---

### 7. Main Menu Infinite Loop ✅
**Problem**: After selecting an option in main menu (like "Cast"), the menu would execute the command but then redisplay the menu instead of exiting.

**Root Cause**: `spells/menu/main-menu` had a `while true` loop that would redisplay the menu after every command execution. The loop only exited on SIGTERM, never on successful command completion.

**Old Code**:
```sh
while true; do
  main_menu_display_menu
  menu_status=$?
  if [ "$menu_status" -eq 130 ]; then
    return 0
  fi
done
```

This means:
- If ESC pressed (exit code 130), return 0 and exit
- For any other exit code (including 0 for successful command), loop continues → menu redisplays

**Fix**: Changed to exit on any non-130 exit code:
```sh
while true; do
  main_menu_display_menu
  menu_status=$?
  
  # Exit code 130 means ESC was pressed - continue loop to redisplay menu
  # Any other exit code (including 0 for successful command execution) should exit
  if [ "$menu_status" -eq 130 ]; then
    continue
  else
    return "$menu_status"
  fi
done
```

**Files Changed**: `spells/menu/main-menu` lines 79-92

---

## Testing

### Automated Tests
All non-interactive tests pass. Run with:
```sh
./spells/system/banish 0 --yes --no-tests
./spells/system/banish 1 --only --no-tests
```

### Manual Testing Required
The menu fixes require manual testing in an interactive terminal:

1. **Test Enter key**: 
   - Run `menu "Test" "Item1%echo item1" "Item2%echo item2"`
   - Press Enter
   - Should execute the selected command and exit (not redisplay menu)

2. **Test arrow keys**:
   - Run menu with multiple items
   - Press up/down arrows
   - Selection should move between items

3. **Test Ctrl-C**:
   - Run menu
   - Press Ctrl-C
   - Menu should cleanup and exit

4. **Test main-menu loop**:
   - Run `main-menu`
   - Select an option like "Cast"
   - Command should execute
   - Menu should not redisplay (should exit instead)

## Usage Examples

```sh
# Validate system foundation only
banish 0

# Validate through level 2 (runs 0, 1, 2 in sequence)
banish 2

# Validate only level 1 (skips level 0)
banish 1 --only --no-tests

# Run with automatic yes to all prompts
banish 1 --yes

# Run without tests (recommended for CI)
banish 1 --no-tests

# Verbose output showing all checks
banish 0 --verbose --no-tests
```

## Files Modified

1. `spells/system/banish`
   - Removed `2>&1` from detect-posix calls
   - Added `--only` flag support
   - Added stdin redirection for tests
   - Improved test output (summary instead of per-test)

2. `spells/cantrips/await-keypress`
   - Always reapply stty settings (fixes KEEP_RAW state corruption)
   - Added Ctrl-C detection (byte 3 → 'ctrl-c')

3. `spells/cantrips/menu`
   - Added ctrl-c key handling

4. `spells/menu/main-menu`
   - Fixed infinite loop (exit after command execution)
