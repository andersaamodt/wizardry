# Testing the Zsh WIZARDRY_DIR Detection Fix

## What Was Fixed

The `invoke-wizardry` script now correctly detects its own location when sourced by zsh, fixing the error:
```
invoke-wizardry: ERROR - WIZARDRY_DIR not found
zsh: command not found: menu
```

## How to Test

### Option 1: Quick Test (Recommended)

Open a **new terminal window** on macOS and run:

```sh
menu
```

**Expected result:** The wizardry menu should appear without any errors.

**If it works:** ✅ The fix is working!

### Option 2: Manual Verification

1. Open a new terminal window
2. Check that WIZARDRY_DIR is set:
   ```sh
   echo $WIZARDRY_DIR
   ```
   **Expected:** Should show the path to your wizardry installation (e.g., `/Users/yourusername/.wizardry`)

3. Verify the menu command is available:
   ```sh
   command -v menu
   ```
   **Expected:** Should show `menu` (as a function or alias)

4. Test the menu:
   ```sh
   menu --help
   ```
   **Expected:** Should show the menu usage information

### Option 3: Test Fresh Installation

If you want to test the complete installation flow:

```sh
# Reinstall wizardry
cd /path/to/wizardry/repository
./install

# When prompted, choose to reinstall
# Then open a new terminal and test:
menu
```

## What Changed Technically

The fix changes how `invoke-wizardry` detects the sourced file path in zsh:

**Before:**
```sh
elif [ -n "${ZSH_VERSION-}" ]; then
  _iw_script_path="$0"  # ❌ Wrong! $0 = "zsh" when sourced
```

**After:**
```sh
elif [ -n "${ZSH_VERSION-}" ]; then
  # In zsh, use %x expansion to get sourced file path
  _iw_script_path=$(eval 'printf "%s" "${(%):-%x}"' 2>/dev/null) || :
  # Fallback to %N if %x didn't work
  if [ -z "$_iw_script_path" ]; then
    _iw_script_path=$(eval 'printf "%s" "${(%):-%N}"' 2>/dev/null) || :
  fi
```

The `${(%):-%x}` expansion is zsh's standard way to get the path of the currently sourced file.

## Troubleshooting

If you still see the error after the fix:

1. **Check your .zshrc:**
   ```sh
   grep invoke-wizardry ~/.zshrc
   ```
   Should show a line like:
   ```sh
   . "/Users/yourusername/.wizardry/spells/.imps/sys/invoke-wizardry" # wizardry: wizardry-init
   ```

2. **Verify the file exists:**
   ```sh
   ls -la ~/.wizardry/spells/.imps/sys/invoke-wizardry
   ```

3. **Test sourcing directly:**
   ```sh
   . ~/.wizardry/spells/.imps/sys/invoke-wizardry
   echo $WIZARDRY_DIR
   ```

4. **Check for multiple installations:**
   ```sh
   # This should only show one path
   find ~ -name "invoke-wizardry" -type f 2>/dev/null | grep -v ".git"
   ```

## Reporting Results

Please report back whether the fix works by commenting on the PR or issue with:

- ✅ **Works** - menu command available, no errors
- ❌ **Still broken** - include the exact error message
- ⚠️ **Partial** - some features work, some don't (describe what)

Include your system info:
```sh
echo "Zsh version: $(zsh --version)"
echo "macOS version: $(sw_vers -productVersion)"
echo "WIZARDRY_DIR: ${WIZARDRY_DIR:-not set}"
```
