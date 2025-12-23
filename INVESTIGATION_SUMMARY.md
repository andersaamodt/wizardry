# Mac Terminal Issues - Investigation Summary

## Problem Statement
Three interconnected issues reported on Mac after wizardry installation:
1. **Terminal hangs on startup** - Suggests infinite loop in invoke-wizardry or command_not_found_handle
2. **Ctrl-C + 'menu' doesn't work** - Related to issue #1, terminal unable to recover
3. **'menu' causes [Process completed]** - Terminal crashes when menu command fails

## Investigation Approach

Rather than guessing at the cause, we've implemented a comprehensive debug logging system that will help us identify the **exact** problem on Mac.

## What We've Built

### 1. Debug Logging System (`WIZARDRY_DEBUG=1`)

**Location**: `spells/.imps/sys/invoke-wizardry`  
**Output**: `~/.wizardry-debug.log`  
**Activation**: Set `export WIZARDRY_DEBUG=1` before sourcing invoke-wizardry

**What Gets Logged**:
- Shell startup (type, PATH, WIZARDRY_DIR detection)
- Each imp family and individual imp being sourced (144 imps)
- Success/failure/skip status for each imp
- Each spell category and individual spell being sourced (200+ spells)
- Success/failure/skip status for each spell
- Summary statistics (total/success/skipped/failed counts)
- command_not_found_handle setup and configuration
- Every command_not_found event with timestamp
- word-of-binding and parse invocations and results
- Final hooks (invoke-thesaurus, cd hook)

**Example Log Output**:
```log
[2025-12-23 10:51:20] invoke-wizardry: === Starting invoke-wizardry ===
[2025-12-23 10:51:20] invoke-wizardry: Shell: 
[2025-12-23 10:51:20] invoke-wizardry: PATH: /usr/local/bin:/usr/bin:/bin...
[2025-12-23 10:51:20] invoke-wizardry: Entering _invoke_wizardry function
[2025-12-23 10:51:20] invoke-wizardry: WIZARDRY_DIR already set: /Users/.../.wizardry
[2025-12-23 10:51:20] invoke-wizardry: Starting imp sourcing from: .../.wizardry/spells/.imps
[2025-12-23 10:51:20] invoke-wizardry: Processing imp family: cond
[2025-12-23 10:51:20] invoke-wizardry: Sourcing imp: has -> _has
[2025-12-23 10:51:20] invoke-wizardry: ✓ Loaded imp: has
...
[2025-12-23 10:51:21] invoke-wizardry: Imp sourcing complete: total=144 success=141 skipped=3 failed=0
[2025-12-23 10:51:21] invoke-wizardry: Starting spell sourcing from: .../.wizardry/spells
[2025-12-23 10:51:21] invoke-wizardry: Processing spell category: arcane
[2025-12-23 10:51:21] invoke-wizardry: Sourcing spell: forall -> forall
[2025-12-23 10:51:21] invoke-wizardry: ✓ Loaded spell: forall
...
```

### 2. User Instructions (`MAC_DEBUG_INSTRUCTIONS.md`)

Complete guide for Mac users covering:
- How to enable debug mode
- How to read and interpret the log
- What to look for in different scenarios
- Quick diagnostic tests
- Expected vs actual behavior
- What information to share

### 3. Enhanced Error Handling

Added robust error handling throughout invoke-wizardry:
- Each source wrapped with success/failure tracking
- Aliases failures logged (not silently ignored)
- Function definition verified after sourcing
- Permissive mode restored even on failure
- Debug output for command_not_found_handle events

## What We Know So Far

### Safety Mechanisms Already in Place
✅ Recursion prevention for invoke-wizardry (`_WIZARDRY_INVOKED` flag)  
✅ Recursion guard for command_not_found_handle (`_WIZARDRY_IN_CNF_HANDLER`)  
✅ Permissive mode (`set +eu`) restored after each source  
✅ Error suppression on risky operations (`2>/dev/null`)  
✅ Command existence checks before aliasing (`command -v`)  

### Potential Root Causes (Hypotheses)

Listed in order of likelihood based on code analysis:

1. **Specific spell/imp hangs on macOS** (most likely)
   - One of ~300 files has macOS-specific issue
   - Could be an incompatible shell feature
   - Could be a missing dependency
   - **Debug log will show**: Last file being sourced before hang

2. **Alias creation fails on macOS shell**  
   - macOS zsh/bash has different alias behavior
   - Aliases silently fail, functions not accessible
   - menu command not found because alias wasn't created
   - **Debug log will show**: "✗ Failed to alias" messages

3. **command_not_found_handle triggers for loaded commands**
   - Functions are defined but shell doesn't recognize them
   - Every command goes through CNF handler
   - Handler gets overwhelmed or enters subtle loop
   - **Debug log will show**: CNF events for "menu", "say", etc.

4. **word-of-binding or parse crashes/loops**
   - These are called from command_not_found_handle
   - If they crash (not just return 127), terminal dies
   - Could have infinite recursion despite guards
   - **Debug log will show**: CNF events, recursion warnings

5. **Sourcing errors accumulate on macOS**
   - Multiple spells fail to source on macOS
   - Cumulative effect causes problems
   - Functions missing that other code expects
   - **Debug log will show**: Multiple "✗ Failed to source" entries

## Testing on Mac - User Instructions

### Step 1: Enable Debug Logging

Edit your `~/.zshrc` (or `~/.bashrc`) and add **before** the invoke-wizardry line:

```bash
export WIZARDRY_DEBUG=1
```

Your RC file should look like:
```bash
# Enable wizardry debug logging  
export WIZARDRY_DEBUG=1

# Source wizardry
. "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
```

### Step 2: Open New Terminal

Close current terminal, open a new one. If it hangs:
- Wait ~30 seconds
- Press Ctrl-C to abort
- Log will still be written

### Step 3: Collect Debug Log

```bash
cat ~/.wizardry-debug.log
```

### Step 4: Share Information

Please provide:
1. **Complete `~/.wizardry-debug.log` file**
2. **macOS version**: `sw_vers`
3. **Shell**: `echo $SHELL` and `$SHELL --version`
4. **Terminal app**: Terminal.app, iTerm2, etc.
5. **Symptoms**:
   - Does terminal hang on open? (Y/N)
   - Can you Ctrl-C out of the hang? (Y/N)
   - Does typing 'menu' work after Ctrl-C? (Y/N)
   - Does 'menu' cause [Process completed]? (Y/N)

## Interpreting Results

### Scenario A: Terminal Hangs on Startup

**What to look for**: Last line in log before hang
```
[timestamp] invoke-wizardry: Sourcing spell: problematic-spell -> problematic_spell
```

**Action**: We'll investigate that specific spell for macOS incompatibility

### Scenario B: Terminal Starts But Menu Fails

**What to look for**: Was menu successfully loaded?
```bash
grep "menu" ~/.wizardry-debug.log
```

Should show:
```
✓ Loaded spell: menu
```

If it shows `✗ Failed to alias` or `✗ Failed to source`, we know the problem.

**Also check**: command_not_found events
```bash
grep "CNF:" ~/.wizardry-debug.log
```

Should NOT show CNF events for "menu" if it was loaded successfully.

### Scenario C: Menu Causes [Process completed]

**What to look for**: 
1. Was menu loaded? (check logs as above)
2. Are there CNF events when you run menu?
3. Are there errors or recursion warnings?

## Quick Diagnostic Tests (Without Full Debug)

### Test 1: Disable command_not_found_handle

```bash
mkdir -p ~/.spellbook/.mud
echo "command-not-found=0" >> ~/.spellbook/.mud/config
# Open new terminal and test
```

If this fixes the problem, issue is in command_not_found_handle or word-of-binding.

### Test 2: Check if Functions Were Defined

```bash
type menu
type _say
type _has
```

Should show functions or aliases. If "not found", invoke-wizardry didn't complete.

### Test 3: Check Aliases

```bash
alias | grep menu
alias | grep say
```

Should show: `menu='menu'` or similar.

## What Happens Next

Once we have the debug log:

1. **Identify exact failure point** - Which file? Which operation?
2. **Reproduce the issue** - Try to recreate on our systems
3. **Implement targeted fix** - Minimal, surgical changes
4. **Add macOS-specific handling** if needed
5. **Re-test with debug logging** to verify fix
6. **Disable debug mode** once working

## Additional Safety Improvements (Future)

Based on what we learn, we may add:
- Timeout/watchdog for sourcing operations
- Better error recovery from failed sources
- macOS-specific code paths
- Lazy loading (don't source all 300 files at startup)
- Incremental sourcing with progress indicator

## Why This Approach?

Previous attempts to fix Mac issues addressed different problems (profile file cleanup). Those fixes were correct but didn't address the terminal hanging issue because we didn't have visibility into what was actually happening.

With debug logging:
- ✅ We'll know **exactly** which file causes problems
- ✅ We'll know **exactly** where the hang occurs
- ✅ We'll know if it's sourcing, aliasing, or command_not_found
- ✅ We can make a **targeted, minimal fix**
- ✅ We can verify the fix works

This is the difference between guessing and knowing. The debug log will tell us the truth.

## Contact

Once you have the debug log, please share it along with the system information mentioned above. The log will help us make a precise, targeted fix for the specific issue you're experiencing on Mac.
