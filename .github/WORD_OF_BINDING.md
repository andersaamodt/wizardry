# word-of-binding: Spell Loading Architecture

## Overview

`word-of-binding` is the core dispatcher that loads and invokes wizardry spells on-demand. It implements two distinct loading strategies based on spell structure:

1. **BIND**: For spells with functions (99% of spells)
2. **EVOKE**: For functionless spells (legacy/rare)

## How It Works

### Detection

word-of-binding checks if a spell has a "true-name" function:

```sh
spell_name=$(basename "$spell_file")
true_name=$(echo "$spell_name" | sed 's/-/_/g')  # ask-yn → ask_yn

if grep -qE "^[[:space:]]*${true_name}[[:space:]]*\(\)" "$spell_file"; then
  # Has function → BIND path
else
  # No function → EVOKE path
fi
```

### BIND Path (Function-Based Spells)

**Used by**: 115 out of 116 spells (99%)

**Process**:
1. Extract ONLY function definitions using awk (ignores top-level code)
2. Eval extracted functions in current shell
3. Create hyphenated wrapper if spell name has hyphens
4. Call the true-name function with arguments

**Example** (`spells/cantrips/ask-yn`):
```sh
#!/bin/sh

ask_yn() {
  # Spell logic here
}

# Standard castable pattern (NOT extracted by awk)
if true; then
  _d=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
  _r=$(cd "$_d" && while [ ! -d "spells/.imps" ] && [ "$(pwd)" != "/" ]; do cd ..; done; pwd)
  _i="${WIZARDRY_DIR:-${_r}}/spells/.imps/sys"
  [ -f "$_i/castable" ] && . "$_i/castable"
fi
castable "$@"
```

When loaded via word-of-binding:
```sh
word_of_binding ask-yn  # Extracts and evals ask_yn() function
# Creates: ask_yn() function and ask-yn() wrapper
# User can call either: ask-yn or ask_yn
```

**Advantages**:
- Functions persist in shell (fast subsequent calls)
- No subprocess overhead after initial load
- Enables shell features like tab completion

### EVOKE Path (Functionless Spells)

**Used by**: 1 out of 116 spells (<1%)

**Process**:
1. Execute spell file directly in subshell
2. Pass all arguments
3. Return exit code

**Example** (hypothetical):
```sh
#!/bin/sh
# Legacy functionless spell
echo "Direct execution"
exit 0
```

When loaded via word-of-binding:
```sh
word_of_binding legacy-spell  # Executes script directly
# No function created, runs in subshell each time
```

## Integration with command_not_found_handler

### Flow

1. User types unknown command (e.g., `banish`)
2. Shell triggers `command_not_found_handler`
3. Handler calls `word_of_binding --run banish`
4. word-of-binding determines: BIND or EVOKE
5. Spell executes
6. Exit code determines success/failure

### Current Implementation

```sh
# From spells/.imps/sys/invoke-wizardry
command_not_found_handler() {
  # Load word-of-binding once
  if [ "${_WIZARDRY_WOB_LOADED-}" != "1" ]; then
    WIZARDRY_SOURCE_WORD_OF_BINDING=1 . "$WIZARDRY_DIR/spells/.imps/sys/word-of-binding"
    _WIZARDRY_WOB_LOADED=1
  fi
  
  # Try to load and run spell
  if command -v word_of_binding >/dev/null 2>&1 \
    && word_of_binding --run "$@" 2>/dev/null; then
    return 0  # Success
  fi
  
  # Command truly not found OR spell failed
  printf '%s: command not found\n' "$1" >&2
  return 127
}
```

### Important Behavior

**The `2>/dev/null` redirects stderr**, so:
- Spell stdout appears normally ✓
- Spell stderr is suppressed ✗
- Exit code determines handler success

**Exit code handling**:
- Exit 0 → Handler returns 0 (success)
- Exit 1+ → Handler prints "command not found" and returns 127

This means **spells that run but fail** (like banish validation failure) will show "command not found" even though they executed.

## Pre-Loading vs On-Demand

### Pre-Loaded Spells

invoke-wizardry pre-loads essential spells at startup:
```sh
for _spell_name in menu await-keypress move-cursor fathom-cursor fathom-terminal \
                   require-command cursor-blink colors; do
  word_of_binding "$_spell_name"  # BIND (no --run)
done
```

**Result**: Functions available immediately, no command_not_found_handler needed.

### On-Demand Spells

All other spells (like `banish`) loaded when first invoked:
```sh
% banish  # Not in PATH, triggers command_not_found_handler
→ word_of_binding --run banish
→ Binds banish() function and runs it
→ Function persists for future calls
```

## Standard Spell Pattern

All modern spells should use this pattern:

```sh
#!/bin/sh

spell_name_usage() {
  cat <<'USAGE'
Usage: spell-name [args]
Description.
USAGE
}

spell_name() {
  case "${1-}" in
  --help|--usage|-h)
    spell_name_usage
    return 0  # RETURN not exit
    ;;
  esac
  
  require-wizardry || return 1  # RETURN not exit
  
  set -eu
  . env-clear
  
  # Main logic here
}

# Standard castable loading (AFTER functions)
if true; then
  _d=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
  _r=$(cd "$_d" && while [ ! -d "spells/.imps" ] && [ "$(pwd)" != "/" ]; do cd ..; done; pwd)
  _i="${WIZARDRY_DIR:-${_r}}/spells/.imps/sys"
  [ -f "$_i/castable" ] && . "$_i/castable"
fi

castable "$@"
```

**Key points**:
- Use `return` not `exit` (allows sourcing)
- Function wraps all logic
- castable at end handles self-execution
- word-of-binding extracts function, ignores bottom code

## Common Issues and Solutions

### Issue: "command not found" after spell runs

**Cause**: Spell returns non-zero exit code (failure)

**Solution**: This is expected behavior. Handler can't distinguish between:
- Spell doesn't exist
- Spell exists but failed

If spell output appeared, it ran successfully (even if validation failed).

### Issue: Duplicate output

**Cause**: Old spells had custom self-execute patterns with fallbacks

**Solution**: Use standard castable pattern (see above)

### Issue: Spell not loading

**Causes**:
1. WIZARDRY_DIR not set
2. Spell file not executable
3. Spell name doesn't match function name

**Solution**: Ensure:
```sh
export WIZARDRY_DIR=/path/to/wizardry
chmod +x spell_file
# Spell 'ask-yn' must have 'ask_yn()' function
```

## Testing word-of-binding

```sh
# Test BIND path
export WIZARDRY_DIR=/path/to/wizardry
WIZARDRY_SOURCE_WORD_OF_BINDING=1 . spells/.imps/sys/word-of-binding

word_of_binding banish  # Loads banish() function
command -v banish  # Should show: banish is a shell function

word_of_binding --run banish  # Loads AND runs banish
```

## Statistics (Current Codebase)

- **Total spells**: 116
- **Function-based (BIND)**: 115 (99.1%)
- **Functionless (EVOKE)**: 1 (0.9%)
- **Pre-loaded spells**: 8
- **On-demand spells**: 108

## See Also

- `.github/instructions/castable-uncastable-pattern.instructions.md` - Standard patterns
- `spells/.imps/sys/word-of-binding` - Implementation
- `spells/.imps/sys/castable` - Self-execute helper
- `spells/.imps/sys/invoke-wizardry` - Shell integration
