# Mac Install Issues - Handle-Command-Not-Found Toggle Solution

## Quick Start for Mac Users

If you're experiencing terminal hangs or issues with the `menu` command on Mac:

1. **Open a terminal** (after Ctrl-C to break out of hang if needed)
2. **Run**: `menu` (if it works) or directly: `mud-menu`
3. **Look for**: `[X] handle-command-not-found hook` in the menu
4. **Toggle it off**: Select the item to disable
5. **Open new terminal**: Test if the issue is resolved

## What This Does

The handle-command-not-found hook is what makes wizardry automatically load spells when you type a command that isn't already loaded. Disabling it means:

- ✅ Spells that are already loaded (pre-sourced by invoke-wizardry) will work
- ✅ Terminal won't hang from command_not_found_handle
- ❌ New spells added after startup won't auto-load
- ❌ Hotloading won't work

## Diagnostic Results

### If terminal STILL hangs with hook disabled:
**Problem is NOT in command_not_found_handle**

Likely causes:
- invoke-wizardry's main spell loading is slow/stuck
- Too many spells being loaded at startup
- word-of-binding has issues when sourced

Next steps:
- Add debug output to invoke-wizardry
- Time how long spell loading takes
- Check if specific spells are causing issues

### If terminal WORKS with hook disabled:
**Problem IS in command_not_found_handle or word-of-binding**

Likely causes:
- word-of-binding enters infinite loop
- parse spell has recursion issues
- command_not_found_handle is slow

Next steps:
- Add debug logging to word-of-binding
- Check for infinite recursion
- Verify recursion guard is working

## Technical Details

### Files Changed
- `spells/.imps/sys/invoke-wizardry` - Checks config before setting up handler
- `spells/menu/mud-menu` - Added toggle to menu
- `spells/.arcana/mud/toggle-command-not-found` - Toggle implementation
- `spells/mud/check-command-not-found-hook` - Status check

### How It Works

#### When Enabled (Default)
```bash
# invoke-wizardry runs at shell startup
# Checks ~/.spellbook/.mud/config
# Sees no command-not-found=0, defaults to enabled
# Sets up command_not_found_handle
# Now unknown commands trigger word-of-binding
```

#### When Disabled
```bash
# User toggles off in MUD menu
# Sets command-not-found=0 in ~/.spellbook/.mud/config
# invoke-wizardry runs at next shell startup
# Sees command-not-found=0, disables handler
# Skips setting up command_not_found_handle
# Unknown commands fail immediately with "command not found"
```

### Configuration File

Location: `~/.spellbook/.mud/config`

```bash
# When disabled:
command-not-found=0

# When enabled (or not configured):
# (no line present, or command-not-found=1)
```

## Testing

All functionality is tested:

```bash
# Run the tests
./.tests/.arcana/mud/test-toggle-command-not-found.sh

# Expected output:
# PASS toggle enables and disables
# PASS toggle is idempotent
# PASS invoke-wizardry respects toggle
# 3/3 tests passed
```

## For the User to Report

Please test and report back:

1. **With hook enabled** (default):
   - Does terminal hang? [ ]
   - Can you run `menu`? [ ]
   - What happens when you Ctrl-C? [ ]

2. **With hook disabled** (toggle it off):
   - Does terminal hang? [ ]
   - Can you run `menu`? [ ]
   - Do pre-loaded spells work? [ ]

3. **Additional info**:
   - macOS version: ______
   - Shell (zsh/bash): ______
   - Terminal app: ______

## Implementation Notes

✅ **COMPLETED**: Add handle-command-not-found toggle to MUD menu
✅ **COMPLETED**: Make toggle display [X] when enabled, [ ] when disabled  
✅ **COMPLETED**: Ensure invoke-wizardry respects the toggle value
✅ **COMPLETED**: Defaults to enabled (backward compatible)
✅ **COMPLETED**: Toggle does NOT need to install in rc (invoke-wizardry handles it)

⏳ **PENDING**: User testing on actual Mac to isolate the issue
⏳ **PENDING**: Add debug logging based on test results
⏳ **PENDING**: Fix the actual root cause once identified

## See Also

- `HANDLE_COMMAND_NOT_FOUND_TOGGLE.md` - Full technical documentation
- `.tests/.arcana/mud/test-toggle-command-not-found.sh` - Test suite
- `spells/.imps/sys/invoke-wizardry` - Implementation details
