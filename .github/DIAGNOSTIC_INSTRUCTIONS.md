# Diagnostic Instructions for Mac Hang Issue

## What I've Done

I've added **unconditional diagnostic output** to invoke-wizardry. Every critical step now prints a message to stderr (your screen) so we can see EXACTLY where it's hanging.

## What You Need to Do

1. **Pull the latest changes** from this branch
2. **Open a new terminal** on your Mac
3. **Watch the output carefully** - you'll see messages like:
   ```
   [invoke-wizardry] SCRIPT LOADED - Starting execution
   [invoke-wizardry] Setting baseline PATH
   [invoke-wizardry] PATH setup complete
   ...
   ```
4. **Note the LAST message** you see before it hangs
5. **Report back** with that last message

## Expected Output

If everything works, you should see about 20-30 diagnostic messages ending with:
```
[invoke-wizardry] FINISHED - invoke-wizardry complete
```

If it hangs, you'll see it stop at a specific message, like:
```
[invoke-wizardry] About to call _invoke_wizardry function
```
(and then nothing more)

## What Each Message Means

| Message | What's Happening |
|---------|------------------|
| `SCRIPT LOADED` | File successfully sourced, starting execution |
| `Setting baseline PATH` | Setting up PATH for macOS |
| `PATH setup complete` | PATH is configured |
| `Permissive mode set` | Shell mode set to permissive (set +eu) |
| `Checking for recursive sourcing` | Checking if already loaded |
| `First invocation, continuing` | Not a duplicate load, proceeding |
| `Defining _invoke_wizardry function` | Defining the main function |
| `About to call _invoke_wizardry function` | About to run main setup |
| `INSIDE _invoke_wizardry function` | Main function executing |
| `FINISHED` | Complete! |

## Two Separate Issues Found

### Issue 1: Mac Indefinite Hang
- **Status**: Needs your diagnostic output to pinpoint
- **Solution**: Once we know where it hangs, I can fix that specific location

### Issue 2: NixOS Syntax Error  
- **Error**: `bash: eval: line 230: syntax error near unexpected token 'fi'`
- **Cause**: Complex escaped quotes in command_not_found_handle eval blocks
- **Solution**: Will simplify or remove the problematic eval statements
- **Note**: This is separate from the Mac hang

## Why This Will Help

The diagnostic output shows us EXACTLY which line of code is hanging. For example:

- If it stops at "Setting baseline PATH" → PATH variable expansion is hanging
- If it stops at "About to call _invoke_wizardry function" → Function definition has an issue
- If it gets to "INSIDE" but hangs there → Main function body has the problem
- If it never shows "SCRIPT LOADED" → Shell can't even parse the file

## After You Report

Once you tell me the last message, I'll:
1. Identify the exact hanging code
2. Fix or work around that specific issue
3. Test the fix
4. Push an update for you to test

## Note About Debug Logs

The new version also has better debug logging. If you want even MORE details:

1. Add to your `.zshrc` BEFORE the invoke-wizardry line:
   ```zsh
   export WIZARDRY_DEBUG=1
   ```

2. After it hangs (or completes), check:
   ```sh
   cat ~/.wizardry-debug.log | head -100
   ```

But the stderr diagnostic output should be enough to pinpoint the issue!
