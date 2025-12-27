# Castable/Uncastable Pattern Instructions

applyTo: "spells/**"

## CRITICAL: Self-Execute Pattern Architecture

### Castable Spells (Can be Executed AND Sourced)

**Structure (REQUIRED ORDER):**

```sh
#!/bin/sh

# Brief description

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
  return 0  # ← RETURN (not exit) - allows sourcing to work
  ;;
esac

require-wizardry || return 1  # ← RETURN (not exit) - allows sourcing to work

set -eu
. env-clear

# Main spell logic here
}

# Load castable imp for direct execution (AFTER all functions defined)
# CRITICAL: Always source, never use from PATH
# The imp must be sourced to define the castable function
if true; then  # Always source castable, ensures consistency
  _d=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
  _r=$(cd "$_d" && while [ ! -d "spells/.imps" ] && [ "$(pwd)" != "/" ]; do cd ..; done; pwd)
  _i="${WIZARDRY_DIR:-${_r}}/spells/.imps/sys"
  [ -f "$_i/castable" ] && . "$_i/castable"
fi

castable "$@"
```

**CRITICAL RULES:**

1. **--help handler BEFORE require-wizardry and set -eu**: Must use `return 0` (not `exit 0`) so sourcing works
2. **require-wizardry uses RETURN**: `require-wizardry || return 1` (not `exit 1`) so sourcing works
3. **set -eu INSIDE function**: Strict mode only applies to function body, not to castable loading
4. **castable AFTER all definitions**: Must be last thing in file
5. **Function uses RETURN**: Always `return`, never `exit` (except in error cases with `die`)

**Why This Works:**
- When executed: `castable` detects direct execution, calls `spell_name()` function
- When sourced: `castable` detects sourcing, just returns (leaves function defined)
- `require-wizardry || return 1` ensures wizardry is available without killing the shell
- Tests work: test-bootstrap adds all imps to PATH before running spells

### Uncastable Spells (Source-Only)

**Structure (REQUIRED ORDER):**

```sh
#!/bin/sh

# Brief description

spell_name_usage() {
cat <<'USAGE'
Usage: . spell-name [args]
Description.
USAGE
}

case "${1-}" in
--help|--usage|-h)
  spell_name_usage
  exit 0  # ← EXIT (not return) - must exit when executed with --help
  ;;
esac

# Load uncastable imp for direct execution (BEFORE main logic)
# CRITICAL: Always source, never use from PATH
# The imp must be sourced to define the uncastable function
if true; then  # Always source uncastable, ensures consistency
  _d=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
  _r=$(cd "$_d" && while [ ! -d "spells/.imps" ] && [ "$(pwd)" != "/" ]; do cd ..; done; pwd)
  _i="${WIZARDRY_DIR:-${_r}}/spells/.imps/sys"
  [ -f "$_i/uncastable" ] && . "$_i/uncastable"
fi

uncastable

require-wizardry || exit 1

spell_name() {
case "${1-}" in
--help|--usage|-h)
  spell_name_usage
  return 0  # ← RETURN when inside function
  ;;
esac

set -eu
. env-clear

# Main spell logic here
}
```

**CRITICAL RULES:**

1. **--help handler TWICE**: Once at top level (before uncastable), once in function
2. **Top-level --help uses EXIT**: So `./spell --help` works and exits
3. **Function --help uses RETURN**: So sourcing works correctly
4. **uncastable BEFORE require-wizardry**: Must error before trying to load wizardry
5. **require-wizardry OUTSIDE function**: Needed for top-level execution path
6. **NO castable call**: Uncastable spells don't self-execute the function

**Why This Works:**
- When executed with --help: Top-level handler catches it, exits cleanly
- When executed without --help: `uncastable` detects execution, prints error, exits
- When sourced: `uncastable` detects sourcing, returns (function gets defined)

## Return vs Exit Rules

| Context | Correct | Wrong | Why |
|---------|---------|-------|-----|
| Inside function | `return 0` | `exit 0` | Exit terminates shell, return exits function |
| Top-level script | `exit 0` | `return 0` | Return only works in functions |
| Help in function | `return 0` | `exit 0` | Must return so sourcing works |
| Help at top level | `exit 0` | `return 0` | Must exit to stop execution |
| Error in function | `die "msg"` or `return 1` | Inconsistent | Use die for fatal, return for recoverable |

## set -eu Placement Rules

| Pattern | Placement | Why |
|---------|-----------|-----|
| **Castable spell** | Inside function | Loading castable shouldn't fail on unset vars |
| **Uncastable spell** | Inside function | Top-level help handler runs before set -eu |
| **Imp (action)** | Top of file | Imps are simple, strict mode for entire file |
| **Imp (conditional)** | NEVER | Conditionals return exit codes for flow control |
| **Bootstrap script** | After PATH setup | Need to set PATH before strict mode |

## Common Mistakes to Avoid

### ❌ WRONG: castable spell with exit in function
```sh
spell_name() {
  case "$1" in
    --help) usage; exit 0 ;; esac  # ← WRONG! Kills shell when sourced
  require-wizardry || exit 1  # ← WRONG! Kills shell when sourced
  set -eu
  # logic
}
castable "$@"
```

### ✅ CORRECT: castable spell with return in function
```sh
spell_name() {
  case "$1" in
    --help) usage; return 0 ;; esac  # ← CORRECT
  require-wizardry || return 1  # ← CORRECT - returns without killing shell
  set -eu
  # logic
}
castable "$@"
```

### ❌ WRONG: set -eu before castable loading
```sh
set -eu  # ← WRONG! Will fail if WIZARDRY_DIR not set
if ! command -v castable >/dev/null 2>&1; then
  _i="${WIZARDRY_DIR:-${_r}}/spells/.imps/sys"  # Fails with set -u
  [ -f "$_i/castable" ] && . "$_i/castable"
fi
```

### ✅ CORRECT: set -eu inside function only
```sh
spell_name() {
  set -eu  # ← CORRECT: Only applies to function
  # logic
}
# Loading code runs without strict mode
if ! command -v castable >/dev/null 2>&1; then
  _i="${WIZARDRY_DIR:-${_r}}/spells/.imps/sys"
  [ -f "$_i/castable" ] && . "$_i/castable"
fi
```

### ❌ WRONG: require-wizardry with exit instead of return
```sh
spell_name() {
  require-wizardry || exit 1  # ← WRONG! exit kills shell when sourced
  set -eu
  # logic
}
```

### ✅ CORRECT: require-wizardry with return
```sh
spell_name() {
  require-wizardry || return 1  # ← CORRECT - returns without killing shell
  set -eu
  . env-clear
  # logic
}
```

## Testing Implications

1. **test-bootstrap sets up PATH**: All imps are available as commands in tests
2. **WIZARDRY_TEST_HELPERS_ONLY=1**: Set by test-bootstrap, makes imps work in test mode
3. **Direct execution works**: Spells can be tested with `./spells/category/spell` or `_run_spell`
4. **No inline imp loading in tests**: Tests already have full PATH with all imps
5. **Castable/uncastable guarantee parity**: If function works, direct execution works

## Quick Reference

**Castable spell checklist:**
- [ ] Usage function defined
- [ ] Main function defined with `spell_name()` 
- [ ] Help handler uses `return 0` (not `exit`)
- [ ] `require-wizardry || return 1` INSIDE function (uses return, not exit)
- [ ] `set -eu` INSIDE function
- [ ] `. env-clear` INSIDE function
- [ ] Castable loading code AFTER all functions (uses `if true; then`)
- [ ] `castable "$@"` at end of file

**Uncastable spell checklist:**
- [ ] Usage function defined
- [ ] Top-level help handler uses `exit 0`
- [ ] Uncastable loading code BEFORE main logic
- [ ] `uncastable` call BEFORE `require-wizardry`
- [ ] `require-wizardry || exit 1` OUTSIDE function
- [ ] Main function defined
- [ ] Function help handler uses `return 0`
- [ ] `set -eu` INSIDE function
- [ ] NO `castable` call at end
