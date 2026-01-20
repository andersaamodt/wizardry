# Handle-Command-Not-Found Toggle Implementation

## Summary

Added a toggleable handle-command-not-found hook to the MUD menu, allowing users to enable/disable the `command_not_found_handle` functionality that auto-loads spells when commands are not found.

## Purpose

This toggle allows Mac users experiencing terminal hangs or issues with the `menu` command to disable the handle-command-not-found hook and isolate whether it's causing the problem.

## Files Added

1. **`spells/.arcana/mud/toggle-command-not-found`**
   - Toggle spell that enables/disables the hook
   - Manages `command-not-found` setting in `~/.spellbook/.mud/config`
   - Defaults to enabled for backward compatibility

2. **`spells/mud/check-command-not-found-hook`**
   - Check spell that returns exit code 0 if enabled, 1 if disabled
   - Used by mud-menu to show [X] or [ ] status

3. **`.tests/.arcana/mud/test-toggle-command-not-found.sh`**
   - Comprehensive tests covering toggle functionality
   - Tests default-enabled behavior
   - Tests invoke-wizardry respecting the toggle
   - All 3 tests passing

## Files Modified

1. **`spells/.imps/sys/invoke-wizardry`**
   - Added config check before setting up `command_not_found_handle`
   - Defaults to enabled if not configured
   - Only sets up handler if `command-not-found` is not explicitly disabled

2. **`spells/menu/mud-menu`**
   - Added handle-command-not-found toggle to menu
   - Shows [X] when enabled, [ ] when disabled
   - Menu now has both cd hook and handle-command-not-found toggles

## How It Works

### Default Behavior
- **Enabled by default** (backward compatible with existing installations)
- When not configured, behaves as if `command-not-found=1`
- invoke-wizardry sets up `command_not_found_handle` as normal

### When Disabled
1. User toggles off in MUD menu
2. Sets `command-not-found=0` in `~/.spellbook/.mud/config`
3. On next shell startup, invoke-wizardry reads config
4. Sees `command-not-found=0` and skips setting up `command_not_found_handle`
5. Unknown commands will fail immediately with "command not found"
6. word-of-binding will NOT be called for missing commands

### When Re-Enabled
1. User toggles on in MUD menu
2. **Removes** `command-not-found` line from config (restores default)
3. On next shell startup, invoke-wizardry reads config
4. Sees no explicit disable, uses default enabled behavior
5. Sets up `command_not_found_handle` as normal

## Usage for Mac Debugging

### Step 1: Access MUD Menu
```bash
# After install, open a new terminal and run:
menu
# Then select "MUD"
```

### Step 2: Toggle Handle-Command-Not-Found
```bash
# In the MUD menu, you'll see:
# [ ] handle-command-not-found hook
# or
# [X] handle-command-not-found hook

# Select it to toggle on/off
```

### Step 3: Test in New Terminal
```bash
# Open a new terminal window to test the change
# Try running 'menu' or other wizardry commands

# If terminal still hangs:
# - Problem is NOT in command_not_found_handle
# - Look at invoke-wizardry itself or word-of-binding

# If terminal works with hook disabled:
# - Problem IS in command_not_found_handle
# - Check word-of-binding for infinite loops
# - Check parse spell if it's being called
```

## Configuration File Location

`~/.spellbook/.mud/config`

Format:
```
command-not-found=0  # Disabled
```

Or no line present (default enabled)

## Testing

Run the tests:
```bash
.tests/.arcana/mud/test-toggle-command-not-found.sh
```

All 3 tests should pass:
- toggle enables and disables
- toggle is idempotent  
- invoke-wizardry respects toggle

## Integration with Invoke-Wizardry

In `invoke-wizardry` at lines 179-254:

1. Reads `~/.spellbook/.mud/config`
2. Checks for `command-not-found=0`
3. If found, sets `_iw_cnf_enabled=0`
4. If not found, defaults to `_iw_cnf_enabled=1`
5. Only sets up `command_not_found_handle` if `_iw_cnf_enabled=1`

This means:
- Users can disable the feature to isolate Mac hanging issues
- Feature is enabled by default (backward compatible)
- Clean integration with existing config system

## Next Steps for Mac Issue Investigation

With this toggle in place, users can:

1. **Test with hook disabled**
   - If terminal still hangs: Problem is in invoke-wizardry's main loading
   - If terminal works: Problem is in command_not_found_handle or word-of-binding

2. **Add debug output to word-of-binding**
   - Log when it's called
   - Log what command it's looking for
   - Log whether it finds the spell
   - Check for infinite loops

3. **Add debug output to invoke-wizardry**
   - Log how many spells/imps are being loaded
   - Time the loading process
   - Check for stuck sourcing operations

4. **Check parse spell**
   - If word-of-binding falls back to parse
   - parse might have recursion issues
   - Check if parse is calling itself infinitely
