# Imps Instructions

applyTo: "spells/.imps/**"

## What Are Imps?

Imps are micro-helper scripts—the smallest semantic building blocks in wizardry. They live in `spells/.imps/` and abstract common shell patterns into readable, well-documented microscripts.

## Imp Requirements

### Required Elements
- **Shebang**: `#!/bin/sh` (POSIX only)
- **Opening comment**: Brief description of what it does

### Strict Mode (`set -eu`)

Imps that perform **actions** (produce output, modify state) should use `set -eu`.

**Conditional imps** that return exit codes for flow control do **NOT** use `set -eu`:
- `cond/` family — `has`, `there`, `is`, `yes`, `no`, `empty`, `nonempty`, etc.
- `lex/` family — parsing helpers that signal success/failure via exit code
- `menu/` family — menu helpers that return true/false

This exception exists because conditional imps are designed to be used in `if` statements and `&&`/`||` chains, where non-zero exit codes indicate false rather than error.

### Relaxed Rules (compared to spells)
- **No `--help` required**: The opening comment serves as the imp's spec
- **No `show_usage()` required**: Keep imps minimal

## Imp Template

### Conditional Imp (returns exit code for flow control)
```sh
#!/bin/sh
# imp-name ARG - test if something is true
# Example: imp-name "value" && echo "yes"

_imp_name() {
  [ "$1" = "expected" ]
}

# Self-execute when run directly (not sourced)
case "$0" in
  */imp-name) _imp_name "$@" ;; esac
```

### Action Imp (performs action, uses strict mode)
```sh
#!/bin/sh
# imp-name ARG1 ARG2 - brief description of what it does
# Example: imp-name "value1" "value2"

set -eu

_imp_name() {
  printf '%s %s\n' "$1" "$2"
}

# Self-execute when run directly (not sourced)
case "$0" in
  */imp-name) _imp_name "$@" ;; esac
```

## Imp Qualities

- **Does exactly one thing**: Single responsibility
- **No functions**: Keep flat and linear
- **Self-documenting name**: Novices can understand without looking it up
- **Hyphenated names**: Use hyphens for multi-word names
- **Space-separated arguments**: No `--flags`, just positional args
- **Cross-platform**: Abstract OS differences behind clean interface

## Demon Families

Imps are organized in folders ("demon families") by function:
- `cond/` — Conditional tests (`has`, `there`, `is`, `yes`, `no`, etc.)
- `str/` — String operations
- `fs/` — Filesystem operations
- `sys/` — System utilities
- `input/` — User input handling
- `out/` — Output formatting and error handling
- `test/` — Test-only imps (prefixed `test-`)

## Error Handling Imps

The `out/` family provides standardized error handling helpers:

| Imp | Purpose | Exit Code | Example |
|-----|---------|-----------|---------|
| `die` | Print error and exit | 1 (or custom) | `die "fatal error"` or `die 2 "usage error"` |
| `usage-error` | Print usage error | 2 | `usage-error "spell-name" "missing argument"` |
| `fail` | Print error, return failure | 1 | `has git \|\| fail "git required"` |
| `warn` | Print warning (no exit) | — | `warn "something unexpected"` |

### Usage Patterns

```sh
# Fatal error - exits script
die "spell-name: critical failure"

# Fatal error with custom exit code
die 2 "spell-name: invalid argument"

# Usage/argument error (exit code 2)
usage-error "$spell_name" "unknown option: $opt"

# Conditional failure
has git || fail "git required"

# Warning (continues execution)
warn "spell-name: deprecated feature used"
```

### Error Message Style

Error messages must be **descriptive, not imperative**:

```sh
# CORRECT - describes what went wrong
die "spell-name: sshfs not found."
die "spell-name: file path required."

# WRONG - tells user what to do
die "Please install sshfs."
die "You must provide a file path."
```

## Example Imps

### Conditional: String contains check
```sh
#!/bin/sh
# contains HAYSTACK NEEDLE - test if string contains substring
# Example: contains "$PATH" "/usr/local/bin" && echo "found"

_contains() {
  case "$1" in
    *"$2"*) return 0 ;;
    *) return 1 ;;
  esac
}

case "$0" in
  */contains) _contains "$@" ;; esac
```

### Conditional: Path existence check
```sh
#!/bin/sh
# there PATH - test if path exists (any type)
# Example: there /etc/passwd && echo "found"

_there() {
  [ -e "$1" ]
}

case "$0" in
  */there) _there "$@" ;; esac
```

### Action: Print message
```sh
#!/bin/sh
# say MESSAGE - print message to stdout with newline
# Example: say "Hello world"

set -eu

_say() {
  printf '%s\n' "$*"
}

case "$0" in
  */say) _say "$@" ;; esac
```

## Test-Only Imps

Imps used only in tests must be prefixed with `test-`:
- Location: `spells/.imps/test/`
- Purpose: Test stubs, fixtures, helpers
- Not for production use
