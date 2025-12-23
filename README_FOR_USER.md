# READY FOR USER TESTING - Mac Terminal Issues

## What We've Built For You

You reported three Mac issues:
1. Terminal hangs on startup
2. Ctrl-C + 'menu' doesn't work  
3. 'menu' causes [Process completed]

We've built a **debug logging system** that will tell us exactly what's happening on your Mac.

## What You Need to Do

### Step 1: Add One Line to Your Shell RC File

Edit `~/.zshrc` (or `~/.bashrc` if you use bash):

```bash
export WIZARDRY_DEBUG=1
```

Put this **BEFORE** the line that sources invoke-wizardry. Your file should look like:

```bash
# Enable wizardry debugging
export WIZARDRY_DEBUG=1

# Source wizardry
. "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
```

Save the file.

### Step 2: Open a New Terminal

Close your current terminal and open a new one.

**If it hangs:**
- Wait 30-60 seconds
- Press Ctrl-C to abort
- The debug log will still be written

**If it doesn't hang:**
- Try running `menu`
- See if the issue still occurs

### Step 3: Share the Debug Log

The debug log is at: `~/.wizardry-debug.log`

Share this file along with:
1. Your macOS version: `sw_vers`
2. Your shell: `echo $SHELL` and `$SHELL --version`
3. Your terminal app (Terminal.app, iTerm2, etc.)
4. What happened:
   - Did it hang on open? (Y/N)
   - Could you Ctrl-C out? (Y/N)
   - Does 'menu' work? (Y/N)
   - Did 'menu' cause [Process completed]? (Y/N)

**To view the log:**
```bash
cat ~/.wizardry-debug.log
```

**Or copy to clipboard (on Mac):**
```bash
cat ~/.wizardry-debug.log | pbcopy
```

## What the Log Shows

The log contains detailed information about:
- Which spells and imps are being loaded (all ~300 of them)
- Whether each one succeeded or failed
- Summary statistics (total/success/failed counts)
- command_not_found_handle events
- Timestamps for everything

**Example log:**
```
[2025-12-23 10:51:20] invoke-wizardry: === Starting invoke-wizardry ===
[2025-12-23 10:51:20] invoke-wizardry: Shell: zsh
[2025-12-23 10:51:20] invoke-wizardry: Processing imp family: cond
[2025-12-23 10:51:20] invoke-wizardry: Sourcing imp: has -> _has
[2025-12-23 10:51:20] invoke-wizardry: ✓ Loaded imp: has
...
[2025-12-23 10:51:21] invoke-wizardry: Imp sourcing complete: total=144 success=141 skipped=3 failed=0
```

If it hangs, the **last line** will show exactly which file was being processed when it hung.

## Quick Test (Optional)

If you want to test without full debugging, you can temporarily disable the command_not_found_handle:

```bash
mkdir -p ~/.spellbook/.mud
echo "command-not-found=0" >> ~/.spellbook/.mud/config
```

Then open a new terminal and test. This will tell us if the problem is in the command_not_found_handle specifically.

## What Happens Next

Once we have your debug log, we'll:
1. **Identify the exact problem** - Which file, which operation
2. **Create a targeted fix** - Minimal, surgical change
3. **Test the fix** - Verify it works
4. **Update the code** - Push the fix
5. **Ask you to test** - Confirm it's fixed on your Mac

## Why This Approach?

Instead of guessing, we're **measuring**. The debug log will show us exactly what's happening on your Mac, which will lead to an exact fix.

## Documentation

For more details, see:
- **MAC_DEBUG_INSTRUCTIONS.md** - Detailed user instructions
- **INVESTIGATION_SUMMARY.md** - Technical deep-dive

## Remove Debug Mode Later

Once the issue is fixed, you can remove or comment out the debug line:

```bash
# export WIZARDRY_DEBUG=1  # Disabled - issue fixed
```

## Thank You!

Your debug log will help us make wizardry work perfectly on Mac. Thank you for your patience and for helping us identify the exact issue!

---

**Ready when you are!** Just add that one line, open a new terminal, and share the log file.
