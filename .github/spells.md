# Spell Style Instructions

applyTo: "spells/**"

## Spell Rules

- Standalone Wizardry-style shell projects use `spells/`, `spells/.imps/`, and mirrored `.tests/` paths.
- Do not substitute `bin/` + `lib/` for Wizardry-style shell tools.
- Every spell needs a matching test: `spells/category/spell-name` -> `.tests/category/test-spell-name.sh`.
- Spell tests cover `--help`, success cases, error cases, and relevant adversarial cases.
- Run tests and report actual pass/fail counts.
- See `.github/tests.md` for test patterns.

## Spell Template

```sh
#!/bin/sh

# Brief description of what this spell does.
# Additional context (optional second line).

case "${1-}" in
--help|--usage|-h)
  cat <<'USAGE'
Usage: spell-name [options] [arguments]

Description of what the spell does and how to use it.
USAGE
  exit 0
  ;;
esac

set -eu

# Main spell logic here
```

## Required Elements

- `#!/bin/sh` shebang.
- Opening comment with 1-2 lines describing the spell.
- Inline help handler for `--help`, `--usage`, and `-h`.
- Help handler before `set -eu`.
- Exactly one `set -eu` before main logic.

## Code Style

### Function Naming

- Usage/help text is inline in the help `case`, not in a function.
- Helper functions use `snake_case`.
- Helper functions do not use leading underscores.
- Function names cannot contain hyphens.

```sh
detect_os() { ... }
validate_name() { ... }
show_usage() { ... }  # Use inline heredoc instead!
_jump() { ... }
_helper_function() { ... }
my-function() { ... }
```

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

### Output and Logging

Use the output imps from `out/` for consistent messaging. See `.github/logging.md` for complete documentation.

```sh
# Always shown - basic output
say "File copied successfully"
success "Installation complete"

# Respects WIZARDRY_LOG_LEVEL (shown when >= 1)
info "Processing files..."
step "Installing dependencies..."

# Respects WIZARDRY_LOG_LEVEL (shown when >= 2)
debug "Variable value: $var"

# Errors and warnings (always shown)
warn "spell-name: configuration missing"
die "spell-name: installation failed"
die 2 "spell-name: invalid argument"
usage-error "$spell_name" "unknown option: $opt"
has git || fail "git required"
```

### Signal Handling and Cleanup

Use `on-exit` and `clear-traps` for consistent cleanup:

```sh
tmpfile=$(temp-file)
on-exit cleanup-file "$tmpfile"

# Work with tmpfile...
# Cleanup happens automatically on exit/interrupt
```

### Error Messages
Print to stderr with spell name prefix—descriptive, not imperative:
```sh
# CORRECT
die "spell-name: sshfs not found"
warn "spell-name: configuration missing"

# WRONG
die "Please install sshfs"
warn "You must create a configuration file"
```

### Functions

- Prefer linear, flat code flow.
- Usage/help text is inline in the help case, not in `show_usage()`.
- 0-1 helper functions: freely allowed (the "spell-heart helper")
- 2 additional functions: acceptable with warning (must be invoked from multiple paths, not suitable as imps)
- 3 additional functions: marginal case with strong warning
- 4+ additional functions: indicates proto-library, must decompose into multiple spells and/or imps

### Exit Codes
- `0`: Success
- `1`: General error
- `2`: Usage/argument error
- `126`: Command cannot execute
- `127`: Command not found
- `130`: Interrupted (Ctrl-C)

## Complexity Guidelines

Signs a spell needs refactoring:
- More than 2-3 optional flags
- Multiple modes or usage lines
- More than 5-10 lines of help text
- Complex nested conditionals
- **4+ helper functions (proto-library)**

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
