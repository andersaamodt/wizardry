# Menu Navigation Debug Testing

## Problem
After installing wizardry and sourcing invoke-wizardry, the menu renders correctly but:
- Arrow keys do nothing
- Enter key just reprints the menu without executing the selected command

## Debug Version Installed
The latest commit includes debug logging to help diagnose this issue.

## Testing Instructions

### 1. Open a fresh terminal
Start a new terminal window to ensure invoke-wizardry is freshly loaded from your shell RC file.

### 2. Enable debug flags
```bash
export WIZARDRY_DEBUG_AWAIT=1
export WIZARDRY_DEBUG_MENU=1
```

### 3. Run menu
```bash
menu
```

### 4. Test key presses
Press the following keys in order and note what happens:
1. **Down arrow** - Should move selection down
2. **Up arrow** - Should move selection up  
3. **Enter** - Should execute the selected command

### 5. Capture the debug output
The debug flags will cause additional output to appear on stderr showing:
- How `await-keypress` resolves the `require-command` dependency
- Whether the `dd` command check passes
- What byte codes are read from the terminal when you press keys
- What string value `await-keypress` returns for each keypress
- What string value `menu` receives from `await-keypress`

## Example Expected Debug Output

When working correctly, you should see output like this:

```
[await-keypress] Found require-command via command -v
[await-keypress] dd check passed
[await-keypress] Read codes: 27 91 66
[await-keypress] Returning: down
[menu] await-keypress returned: "down"
```

Where:
- `27 91 66` is the escape sequence for down arrow (ESC [ B)
- `await-keypress` correctly interprets this as "down"
- `menu` receives "down" and should move the selection

## What We're Looking For

1. **Does require-command resolve?**
   - Should see: `[await-keypress] Found require-command via command -v`
   - OR: `[await-keypress] Using REQUIRE_COMMAND=...`
   - If you see: `[await-keypress] Fallback require_cmd=...` - this might be a problem

2. **Does dd check pass?**
   - Should see: `[await-keypress] dd check passed`
   - If you see: `[await-keypress] require-command dd check failed` - this is the problem

3. **Are key codes being read?**
   - When you press down arrow, should see codes like: `27 91 66` or `27 79 66`
   - When you press up arrow, should see codes like: `27 91 65` or `27 79 65`
   - When you press Enter, should see codes like: `10` or `13`
   - If you see: `[await-keypress] No codes read, returning empty` - this is the problem

4. **Are keys being interpreted correctly?**
   - Down arrow codes should map to: `[await-keypress] Returning: down`
   - Up arrow codes should map to: `[await-keypress] Returning: up`
   - Enter codes should map to: `[await-keypress] Returning: enter`
   - If the interpretation is wrong, that's the problem

5. **Is menu receiving the correct values?**
   - Should see: `[menu] await-keypress returned: "down"` (or "up", "enter")
   - If menu receives empty string or wrong value, that's the problem

## Sharing Results

Please share:
1. The complete debug output from running menu with debug flags enabled
2. Specifically note which keys you pressed and what happened (or didn't happen)
3. Any error messages that appeared

## Disabling Debug Output

To turn off debug output after testing:
```bash
unset WIZARDRY_DEBUG_AWAIT
unset WIZARDRY_DEBUG_MENU
```

Or just close the terminal and open a new one.
