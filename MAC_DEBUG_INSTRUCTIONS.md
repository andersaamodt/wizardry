# Mac Terminal Issues - Debug Instructions

## Problem
After installing wizardry on Mac, you're experiencing:
1. Terminal hangs on startup
2. Ctrl-C then typing 'menu' doesn't work
3. 'menu' command causes [Process completed] (terminal crashes)

## Debug Strategy

We've added comprehensive debug logging to identify the root cause. The logs will help us pinpoint exactly which spell/imp is causing issues, or if it's the command_not_found_handle triggering incorrectly.

## How to Enable Debug Mode

### Step 1: Enable Debug Logging

Add this line to your shell RC file (`.zshrc` or `.bashrc`) **BEFORE** the invoke-wizardry line:

```bash
export WIZARDRY_DEBUG=1
```

Your RC file should look like this:

```bash
# Enable wizardry debug logging
export WIZARDRY_DEBUG=1

# Source wizardry
. "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
```

### Step 2: Open a New Terminal

Close your current terminal and open a new one. This will:
- Start the wizardry initialization process
- Log everything to `~/.wizardry-debug.log`
- If it hangs, you can Ctrl-C and check the log

### Step 3: Check the Debug Log

```bash
# View the entire log
cat ~/.wizardry-debug.log

# Or view just the last 50 lines
tail -50 ~/.wizardry-debug.log

# Or follow the log in real-time (in another terminal if hanging)
tail -f ~/.wizardry-debug.log
```

### Step 4: Try Running Menu

If the terminal doesn't hang on startup, try running:

```bash
menu
```

Then check the debug log again to see what happened.

## What the Debug Log Shows

The log contains detailed information about:

1. **Startup Phase**:
   - Shell type detected (bash/zsh)
   - WIZARDRY_DIR detection
   - PATH configuration

2. **Imp Loading Phase** (first ~100 files):
   - Each imp family being processed
   - Each imp being sourced
   - Success/failure for each imp
   - Summary: `total=X success=Y skipped=Z failed=W`

3. **Spell Loading Phase** (next ~200 files):
   - Each spell category being processed
   - Each spell being sourced
   - Success/failure for each spell
   - Summary: `total=X success=Y skipped=Z failed=W`

4. **command_not_found_handle Phase**:
   - Whether it's enabled or disabled
   - Shell type (bash/zsh)

5. **Command Not Found Events** (if triggered):
   - When a command is not found
   - Which handlers are tried (word-of-binding, parse)
   - Whether they succeed or fail
   - Final outcome (command found or not)

## Interpreting the Log

### If Terminal Hangs on Startup

The last few lines will show exactly which file was being sourced when it hung:

```
Sourcing imp: some-imp-name -> _some_imp_name
```

or

```
Sourcing spell: some-spell-name -> some_spell_name
```

**Action**: Report the last imp/spell that was being sourced.

### If Menu Command Fails

Look for lines like:

```
CNF: command not found: menu
CNF: trying word-of-binding for: menu
CNF: word-of-binding failed for: menu
```

This shows that `menu` is not loaded (alias not created) and command_not_found_handle is trying to find it.

**Action**: Check if menu appears in the spell loading summary. It should be in the `spells/menu` category.

### If Menu Causes [Process Completed]

Look for:
1. Whether menu was successfully loaded
2. Error messages in the command_not_found_handle section
3. Recursion warnings

## Disabling Debug Mode

Once you've captured the log, you can disable debug mode by removing or commenting out the WIZARDRY_DEBUG line:

```bash
# export WIZARDRY_DEBUG=1  # Disabled - debugging complete
```

## Sharing Results

Please share:
1. The complete `~/.wizardry-debug.log` file
2. Your macOS version
3. Your shell (`echo $SHELL`)
4. Your Terminal app (Terminal.app, iTerm2, etc.)
5. Exact symptoms (which of the 3 issues you're experiencing)

## Quick Tests Without Full Debug

If you want to test without full debug logging, you can:

### Test 1: Disable command_not_found_handle

This will tell us if the issue is in the command_not_found_handle:

```bash
# Create config directory if it doesn't exist
mkdir -p ~/.spellbook/.mud

# Disable the hook
echo "command-not-found=0" >> ~/.spellbook/.mud/config

# Open new terminal and test
```

If terminal works normally with this disabled, the issue is in command_not_found_handle or word-of-binding.

### Test 2: Check if invoke-wizardry completes

```bash
# In a terminal that has wizardry loaded (even if hanging), try:
type menu
type say
type has

# These should show "menu is an alias for menu"
# If they show "not found", invoke-wizardry didn't complete
```

## Additional Diagnostic Commands

```bash
# Check if wizardry directory is set
echo $WIZARDRY_DIR

# Check if spellbook exists
ls -la ~/.spellbook

# Check config
cat ~/.spellbook/.mud/config

# List all aliases (to see if wizardry spells are aliased)
alias | grep -E "(menu|say|has|die)"

# Check if functions are defined
type _say
type menu
```

## Expected Behavior (When Working)

When wizardry works correctly on Mac:

1. Opening a new terminal takes 2-10 seconds (first time may be slower)
2. You see your shell prompt
3. Typing `menu` opens the wizardry menu
4. Typing `say "hello"` prints "hello"
5. No error messages or hangs
6. Debug log shows all imps/spells loaded successfully
7. command_not_found_handle is installed (if not disabled)

## What We're Looking For

The debug log will help us identify:

1. **Which specific file causes the hang** - Last file in log before hang
2. **Whether aliases are being created** - Look for "✓ Loaded" vs "✗ Failed to alias"
3. **If command_not_found_handle is triggering for aliased commands** - Should not happen
4. **If word-of-binding or parse are failing with errors** - Should return 127 cleanly
5. **Timing issues** - How long each phase takes

Once we have this information, we can make targeted fixes to the specific problematic areas.
