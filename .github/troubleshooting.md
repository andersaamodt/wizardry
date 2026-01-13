# Wizardry Troubleshooting Guide

## "menu: command not found" after installation

If you've installed wizardry but `menu` doesn't work when you open a new terminal, follow these steps:

### 1. Verify Installation

Check that invoke-wizardry is in your shell RC file:

**For zsh (macOS default):**
```bash
grep -n "invoke-wizardry" ~/.zprofile ~/.zshrc
```

**For bash:**
```bash
grep -n "invoke-wizardry" ~/.bashrc ~/.bash_profile
```

You should see a line like:
```
. "/Users/yourname/.wizardry/spells/.imps/sys/invoke-wizardry" # wizardry: wizardry-init
```

### 2. Enable Debug Mode

Add this line to your shell RC file BEFORE the invoke-wizardry line:
```bash
export WIZARDRY_DEBUG=1
```

Then open a new terminal. You should see diagnostic output like:
```
[invoke-wizardry] Starting wizardry initialization
[invoke-wizardry] WIZARDRY_DIR=/Users/yourname/.wizardry
[invoke-wizardry] Pre-loading essential imps
[invoke-wizardry] Pre-loading essential spells
[invoke-wizardry] Loading spell: menu
[invoke-wizardry]   ✓ Loaded: menu
...
[invoke-wizardry] Wizardry initialization complete
```

### 3. Common Issues

#### Issue: "Already invoked, skipping" message

**Cause:** invoke-wizardry is being sourced twice (from both `.zprofile` and `.zshrc`)

**Solution:** Remove the duplicate source line from one of the files. On macOS, keep it in `.zprofile` only.

#### Issue: No debug output at all

**Cause:** invoke-wizardry isn't being sourced

**Solutions:**
- Make sure you opened a **new** terminal window (not just a new tab)
- Check the file path in the source line is correct
- Try sourcing it manually: `. ~/.wizardry/spells/.imps/sys/invoke-wizardry`

#### Issue: "✗ Failed: menu" in debug output

**Cause:** The menu spell failed to load

**Solutions:**
- Check file permissions: `ls -l ~/.wizardry/spells/cantrips/menu`
- Try loading manually: `export WIZARDRY_DIR=~/.wizardry && . ~/.wizardry/spells/.imps/sys/invoke-wizardry`
- Check for syntax errors: `sh -n ~/.wizardry/spells/cantrips/menu`

#### Issue: menu works in debug mode but not normally

**Cause:** Something in your environment is interfering

**Solutions:**
- Check for conflicting aliases: `alias | grep menu`
- Check for functions that might override: `type menu`
- Try with a clean environment: `env -i HOME=$HOME SHELL=$SHELL $SHELL -l`

### 4. Understanding the Loading Mechanism

**Current (Spiral Debug Phase 1):** Wizardry uses a minimal pre-loading approach:

1. **Pre-loading (menu and dependencies only)**: Menu and its helper spells are loaded as persistent functions when your shell starts
2. **Hotloading (for user spellbooks)**: Custom spells in `~/.spellbook` are loaded on-demand via command_not_found_handle

**Future (Post-Spiral Debug):** All wizardry spells will be pre-loaded, and hotloading will only apply to user spellbooks.

**Important:** The `menu` command MUST be pre-loaded to work. If pre-loading fails, you'll get "command not found".

### 5. Manual Workaround

If all else fails, you can invoke spells using word-of-binding directly:

```bash
export WIZARDRY_DIR=~/.wizardry
~/.wizardry/spells/.imps/sys/word-of-binding menu
```

### 6. Getting Help

If none of these steps help, please file an issue with:
- Your OS and shell version (`uname -a` and `$SHELL --version`)
- The debug output from step 2
- The contents of your RC file (with sensitive info removed)
- The output of: `ls -la ~/.wizardry/spells/.imps/sys/invoke-wizardry`

---

## macOS Privacy Popup When Running test-magic

### Issue: macOS requests permission to access Apple Music/Media Library

When running `test-magic` on macOS, you may see a system popup asking:
```
"Terminal" would like to access Apple Music, your music and video activity, and your media library.
```

### Cause

This is **not a wizardry bug** but rather macOS's privacy protection system being overly cautious. 

When `test-magic` runs, it uses the `find` command to scan all files in the wizardry repository (the `spells/` directory and `.tests/` directory). macOS's privacy protection monitors file system access and may interpret this scanning activity as potentially accessing media files, even though wizardry is only scanning its own repository files (shell scripts, not media).

### Why "Apple Music" specifically?

macOS uses heuristics to determine what permission to request. When it sees widespread file scanning, it may assume the application wants to access media files and requests the broadest relevant permission (Music/Media Library) as a precaution.

### Solutions

1. **Allow the access (Recommended)**: Click "OK" to grant Terminal access. This won't actually give wizardry access to your music—it just allows Terminal to scan files without triggering this popup again.

2. **Deny the access**: Click "Don't Allow". `test-magic` will still work, but you may see the popup again in the future.

3. **Manually grant permission**: Go to System Preferences → Security & Privacy → Privacy → Files and Folders (or Media & Apple Music) and grant Terminal full disk access.

### Why This Happens

- `test-magic` scans the repository using `find spells -type f` to discover all spell files
- It also scans `.tests/` directory to find test files
- macOS monitors these file operations and triggers privacy prompts
- This is a macOS security feature, not a wizardry issue

### Does wizardry access my music?

**No.** Wizardry only scans its own installation directory (`~/.wizardry/spells` and `~/.wizardry/.tests`). It never accesses your Music library, iTunes, or any media files. The permission request is a false positive from macOS's heuristic-based privacy system.
