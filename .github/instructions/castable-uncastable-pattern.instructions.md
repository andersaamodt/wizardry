# Castable/Uncastable Pattern Instructions

applyTo: "spells/**"

## CRITICAL: Self-Execute Pattern Architecture

### Castable Spells (Executed AND Sourced)

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
--help|--usage|-h) spell_name_usage; return 0 ;; esac

require-wizardry || return 1  # RETURN not exit - allows sourcing

set -eu
. env-clear
# Main logic
}

# Load castable (AFTER all functions)
if true; then
  _d=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
  _r=$(cd "$_d" && while [ ! -d "spells/.imps" ] && [ "$(pwd)" != "/" ]; do cd ..; done; pwd)
  _i="${WIZARDRY_DIR:-${_r}}/spells/.imps/sys"
  [ -f "$_i/castable" ] && . "$_i/castable"
fi
castable "$@"
```

**CRITICAL RULES:**
1. `--help` handler uses `return 0` (not `exit`) - enables sourcing
2. `require-wizardry || return 1` (not `exit`) - prevents shell kill
3. `set -eu` INSIDE function - protects function, not castable loading
4. `castable "$@"` AFTER all definitions
5. Always `return`, never `exit` in function body

**Conditional set -e for Interactive Use:**
When spell is frequently called from interactive shells and may return non-zero in normal operation:

```sh
spell_name() {
  case "$0" in
    */spell-name) set -eu ;;  # Script: full strict mode
    *) set -u ;;              # Function: only -u (prevents shell exit)
  esac
  # Rest of function
}
```

Use conditional pattern for: `banish`, `validate-spells`, `test-spell` (interactive tools)

### Uncastable Spells (Source-Only)

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
--help|--usage|-h) spell_name_usage; exit 0 ;; esac

# Load uncastable (BEFORE main logic)
if true; then
  _d=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
  _r=$(cd "$_d" && while [ ! -d "spells/.imps" ] && [ "$(pwd)" != "/" ]; do cd ..; done; pwd)
  _i="${WIZARDRY_DIR:-${_r}}/spells/.imps/sys"
  [ -f "$_i/uncastable" ] && . "$_i/uncastable"
fi
uncastable

require-wizardry || exit 1
spell_name() {
case "${1-}" in
--help|--usage|-h) spell_name_usage; return 0 ;; esac
set -eu
. env-clear
# Main logic
}
```

**Rules:** `--help` twice (top=exit, function=return), `uncastable` before `require-wizardry`, no `castable` call

## Quick Reference

| Context | Use | Why |
|---------|-----|-----|
| Function body | `return 0` | Exits function, not shell |
| Top-level | `exit 0` | Stops execution |
| Castable | `set -eu` inside function | Protects loading |
| Uncastable | `set -eu` inside function | Top help handler first |
| Imp (action) | `set -eu` at top | Simple, entire file |
| Imp (conditional) | NO `set -eu` | Returns exit codes |
| Interactive spell | Conditional `set -e` | Prevents shell kill |

## Common Mistakes

| Wrong | Right | Why |
|-------|-------|-----|
| `exit 0` in function | `return 0` | Exit kills shell when sourced |
| `require-wizardry \|\| exit 1` | `require-wizardry \|\| return 1` | Exit kills shell |
| `set -eu` before castable | `set -eu` in function | Vars may be unset during load |
| Duplicate `set -eu` in imp | ONE `set -eu` at top | Breaks invoke-wizardry |

## Function Calls in Command Substitution

When calling functions via variables in `$(...)`, use `eval`:

```sh
# CORRECT: Use eval for variable function calls
_cmd="validate_spells"
result=$(eval "$_cmd --flag $arg" 2>&1)

# WRONG: Direct expansion fails in some shells
result=$($_cmd --flag $arg)  # May fail in zsh
```

**Why:** POSIX-compliant, works across sh/bash/zsh/dash. Only use for controlled variables (not user input).

