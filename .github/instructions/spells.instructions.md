# Spell Style Instructions

applyTo: "spells/**"

## Spell Template

```sh
#!/bin/sh

# Brief description of what this spell does.
# Additional context (optional second line).

show_usage() {
  cat <<'USAGE'
Usage: spell-name [options] [arguments]

Description of what the spell does and how to use it.
USAGE
}

case "${1-}" in
--help|--usage|-h)
  show_usage
  exit 0
  ;;
esac

set -eu

# Main spell logic here
```

## Required Elements

1. **Shebang**: `#!/bin/sh` (POSIX only)
2. **Opening comment**: 1-2 lines describing what it does
3. **Strict mode**: `set -eu`

## Recommended Elements

1. **`show_usage()` function** with single-quoted heredoc `'USAGE'`
2. **Help handler** before `set -eu` for `--help`, `--usage`, `-h`

## Code Style

### Variables
```sh
# CORRECT
var=''
value=${1-}              # Empty default
value=${1:-default}      # Non-empty default

# WRONG
var= 
value=$1                 # Fails with set -u
```

### Quoting
Always quote variables unless word splitting is intended:
```sh
printf '%s\n' "$message"
path="$HOME/wizardry"
```

### Error Messages
Print to stderr with spell name prefix—descriptive, not imperative:
```sh
# CORRECT
printf '%s\n' "spell-name: sshfs not found." >&2

# WRONG
printf '%s\n' "Please install sshfs." >&2
```

### Functions
Prefer linear, flat code flow over excessive function wrapping.

### Exit Codes
- `0`: Success
- `1`: General error
- `2`: Usage error

## Complexity Guidelines

Signs a spell needs refactoring:
- More than 2-3 optional flags
- Multiple modes or usage lines
- More than 5-10 lines of help text
- Complex nested conditionals

Solutions:
- Split into multiple smaller spells
- Move shared logic to imps in `spells/.imps/`
- Use composition (small spells that pipe together)

## POSIX Compliance

Avoid bash-isms:
- Use `[ ]` not `[[ ]]`
- Use `.` not `source`
- Use `=` not `==` for string comparison
- No `local` keyword
- No arrays
- Use `$()` not backticks
