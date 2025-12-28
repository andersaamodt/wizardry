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

**Important:** Wizardry uses TWO mechanisms to make spells available:

1. **Pre-loading (for menu and essential spells)**: These are loaded as persistent functions when your shell starts
2. **Hotloading (for other spells)**: These are loaded on-demand when you first use them

The `menu` command MUST be pre-loaded to work efficiently. If pre-loading fails, hotloading cannot compensate - you'll get "command not found".

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
