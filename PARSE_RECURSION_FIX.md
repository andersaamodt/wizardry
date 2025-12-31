# Parse Recursion Loop Fix

## Problem

When users called spells via glosses (e.g., `main-menu`), they would encounter infinite recursion or "command not found" errors. The symptom was described as "parse parse parse..." recursive loop.

## Root Cause

The glossary-based interception paradigm works as follows:

1. **Gloss creation**: `generate-glosses` creates wrapper scripts in `~/.spellbook/.glossary/` for each spell:
   ```sh
   #!/bin/sh
   exec "$WIZARDRY_DIR/spells/.imps/lex/parse" "main-menu" "$@"
   ```

2. **PATH prepending**: The glossary directory is prepended to PATH, so all commands go through glosses first

3. **Parse execution**: When a gloss runs, it calls parse with the spell name

4. **The problem**: Parse would remove the glossary from PATH to avoid recursion, but then couldn't find the spell because:
   - Spell directories are NOT in PATH (only glossary is)
   - Parse could only find commands already in PATH
   - Result: Either "command not found" or finding the gloss again (recursion)

## Solution

Enhanced `parse` to intelligently resolve commands in this priority order:

### 1. Preloaded Functions (Priority 1)
```sh
# Convert hyphen to underscore: main-menu → main_menu
_func_name=$(printf '%s' "$_parse_cmd" | tr '-' '_')

# Check if function exists and call it
if type "$_func_name" | grep -q "function"; then
  "$_func_name" "$@"
  return $?
fi
```

**Why this works**: When `invoke-wizardry` preloads spells as functions, they're available in the current shell. Parse checks for these functions first.

### 2. Commands in PATH (Priority 2)
```sh
# Remove glossary from PATH to avoid recursion
_gloss_dir="${SPELLBOOK_DIR:-${HOME}/.spellbook}/.glossary"
PATH=$(printf '%s' "$PATH" | sed "s|$_gloss_dir:||g" ...)

# Check if command exists in modified PATH
if command -v "$_parse_cmd" >/dev/null 2>&1; then
  "$_parse_cmd" "$@"
  return $?
fi
```

**Why this works**: System commands and user-installed tools are found here.

### 3. Wizardry Spell Files (Priority 3 - NEW)
```sh
# Search for spell in WIZARDRY_DIR
for _spell_dir in cantrips menu arcane divination system ...; do
  if [ -f "$_wizardry_dir/spells/$_spell_dir/$_parse_cmd" ]; then
    "$_wizardry_dir/spells/$_spell_dir/$_parse_cmd" "$@"
    return $?
  fi
done

# Fallback: search all directories
_spell_file=$(find "$_wizardry_dir/spells" -type f -name "$_parse_cmd" -print -quit)
if [ -n "$_spell_file" ]; then
  "$_spell_file" "$@"
  return $?
fi
```

**Why this works**: When glosses are invoked, they execute in a new process without preloaded functions. Parse now searches WIZARDRY_DIR to find the actual spell files.

## Execution Flow Examples

### Case 1: User calls function directly (normal usage)
```
User types: main_menu
Shell: Finds main_menu function (preloaded by invoke-wizardry)
Result: Function executes directly ✓
```

### Case 2: Gloss invoked when function is preloaded
```
Gloss: exec parse "main-menu"
Parse: Checks for main_menu function → FOUND (in current shell)
Parse: Calls main_menu function directly
Result: Function executes ✓
```

### Case 3: Gloss invoked when function NOT preloaded
```
Gloss: exec parse "main-menu" (new process, no functions)
Parse: Checks for main_menu function → NOT FOUND
Parse: Checks PATH (with glossary removed) → NOT FOUND
Parse: Searches WIZARDRY_DIR → FOUND at spells/menu/main-menu
Parse: Executes spell file directly
Result: Spell file executes ✓
```

### Case 4: System command called via gloss
```
Gloss: exec parse "ls"
Parse: Checks for ls function → NOT FOUND
Parse: Checks PATH (with glossary removed) → FOUND (/bin/ls)
Parse: Executes /bin/ls
Result: System command executes ✓
```

## Recursion Prevention

Parse includes multiple layers of recursion prevention:

1. **WIZARDRY_PARSE_DEPTH tracking**: Increments on each parse call, returns error at depth ≥ 5
2. **Glossary removal from PATH**: Prevents finding glosses when searching for commands
3. **Self-reference handling**: Special case for `parse "parse"` returns help text
4. **Spell file execution**: Breaks recursion by executing the actual file instead of gloss

## Testing

Created comprehensive test suite in `.tests/.imps/lex/test-parse-gloss-recursion.sh`:

- ✅ Parse finds spell files in WIZARDRY_DIR
- ✅ Parse handles self-reference (parse "parse")
- ✅ Parse recursion depth limit works
- ✅ Parse returns 127 for missing commands

All tests passing (4/4).

## Debug Mode

Set `WIZARDRY_DEBUG=1` to see parse execution flow:

```sh
export WIZARDRY_DEBUG=1
main-menu --help
```

Output:
```
[parse] DEBUG: Calling preloaded function: main_menu
```

Or if function not available:
```
[parse] DEBUG: Command not in PATH, searching WIZARDRY_DIR for spell: main-menu
[parse] DEBUG: Found spell in menu: /path/to/spells/menu/main-menu
[parse] DEBUG: Executing spell file: /path/to/spells/menu/main-menu
```

## Benefits

1. **No more infinite recursion**: Parse can always find the target spell
2. **Backward compatible**: Existing functionality unchanged
3. **Performance**: Preloaded functions are fastest (Priority 1)
4. **Fallback safety**: Even without preloaded functions, spells work
5. **Debug visibility**: Clear debug output shows resolution path

## Files Changed

- `spells/.imps/lex/parse` - Enhanced command resolution logic
- `.tests/.imps/lex/test-parse-gloss-recursion.sh` - New test suite
