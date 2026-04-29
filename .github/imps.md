# Imps Instructions

applyTo: "spells/.imps/**"

## Imp Definition

- Imps live in `spells/.imps/`.
- Imps are reusable micro-helpers or non-user-facing scripts.
- Spells are user-facing commands with `--help`.
- Imps are internal helpers or endpoints users should not call directly.
- Most imps are small, flat scripts.
- Complex imps are allowed when they are non-user-facing infrastructure.
- CGI imps stay in `.imps/cgi/` for web server routing.
- CGI imps may be 100-300+ lines and may use functions when internal routing/state requires it.

## Creating New Imps

- Imp location: `spells/.imps/family/imp-name`
- Test location: `.tests/.imps/family/test-imp-name.sh`
- Every imp needs a behavior test.
- Run tests and report actual pass/fail counts.
- See `.github/tests.md` for test patterns.

## Imp Requirements

### Required Elements
- **Shebang**: `#!/bin/sh` (POSIX only)
- **Opening comment**: Brief description of what it does

### Strict Mode

- Use exactly one `set -eu` in action imps.
- Never duplicate `set -eu`; duplicate strict-mode lines break invoke-wizardry and can hang terminals.
- Action families normally use `set -eu`: `fs/`, `out/`, `paths/`, `pkg/`, `str/`, `sys/`, `text/`, `input/`, `lang/`.
- Conditional imps use no `set -eu` because nonzero exit codes mean false, not failure.
- Conditional families include `cond/`, `lex/`, and `menu/`.
- Structural common tests enforce strict-mode rules.

### Relaxed Rules (compared to spells)
- No `--help` required: the opening comment is the spec.
- No usage function required.

## Imp Template

### Conditional Imp (returns exit code for flow control)
```sh
#!/bin/sh
# imp-name ARG - test if something is true
# Example: imp-name "value" && echo "yes"

# Note: No set -eu because this is a conditional imp (returns exit codes for flow control)

[ "$1" = "expected" ]
```

### Action Imp (performs action, uses strict mode)
```sh
#!/bin/sh
# imp-name ARG1 ARG2 - brief description of what it does
# Example: imp-name "value1" "value2"

set -eu

printf '%s %s\n' "$1" "$2"
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
- `app/` — Application validation helpers
- `cgi/` — **CGI web endpoints** (can be complex, non-user-facing)
- `cond/` — Conditional tests (`has`, `there`, `is`, `yes`, `no`, etc.)
- `fmt/` — Formatting utilities
- `fs/` — Filesystem operations
- `hook/` — Hook system helpers
- `input/` — User input handling
- `lang/` — Language/grammar helpers
- `lex/` — Lexical parsing utilities
- `menu/` — Menu system helpers
- `mud/` — MUD game mechanics
- `out/` — Output formatting and error handling
- `paths/` — Path manipulation
- `pkg/` — Package manager abstraction
- `str/` — String operations
- `sys/` — System utilities
- `test/` — Test-only imps (prefixed `test-`)
- `text/` — Text processing

### Special: CGI Family

- `cgi/` contains web endpoints and server-sent events handlers.
- `cgi/` files must stay in `.imps/cgi/` for web server routing.
- `cgi/` files can exceed typical imp size limits.
- `cgi/` files may use functions for internal structure.
- Examples: `blog-*`, `chat-*`, `http-*`, `sse-*`, `drag-drop-upload`.

## Error Handling and Output Imps

The `out/` family provides standardized error handling and output helpers. See `.github/logging.md` for complete documentation.

### Core Error Handling

| Imp | Purpose | Exit Code | Example |
|-----|---------|-----------|---------|
| `die` | Print error and exit | 1 (or custom) | `die "fatal error"` or `die 2 "usage error"` |
| `usage-error` | Print usage error | 2 | `usage-error "spell-name" "missing argument"` |
| `fail` | Print error, return failure | 1 | `has git \|\| fail "git required"` |
| `warn` | Print warning (no exit) | — | `warn "something unexpected"` |

### Semantic Output

| Imp | Purpose | Log Level | Example |
|-----|---------|-----------|---------|
| `say` | Normal output | Always | `say "File copied"` |
| `success` | Success message | Always | `success "Installation complete"` |
| `info` | Informational message | >= 1 | `info "Processing files..."` |
| `step` | Multi-step process | >= 1 | `step "Installing dependencies..."` |
| `debug` | Debug information | >= 2 | `debug "Variable: $var"` |

Set log level with `WIZARDRY_LOG_LEVEL` (default is 0).

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

## Signal Handling and Cleanup

The `sys/` family provides signal handling helpers for consistent cleanup:

| Imp | Purpose | Example |
|-----|---------|---------|
| `on-exit` | Register cleanup on exit/interrupt | `on-exit cleanup-file "$tmpfile"` |
| `clear-traps` | Clear all signal traps | `clear-traps` |

### Usage Pattern

```sh
#!/bin/sh
set -eu

tmpfile=$(temp-file)
on-exit cleanup-file "$tmpfile"

# Work with tmpfile...
# Cleanup happens automatically on EXIT, HUP, INT, or TERM
```

For complex cleanup:

```sh
cleanup() {
  cleanup-file "$tmpfile"
  cleanup-dir "$tmpdir"
}

on-exit cleanup
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

# Note: No set -eu because this is a conditional imp (returns exit codes for flow control)

case "$1" in
  *"$2"*) exit 0 ;;
  *) exit 1 ;;
esac
```

### Conditional: Path existence check
```sh
#!/bin/sh
# there PATH - test if path exists (any type)
# Example: there /etc/passwd && echo "found"

# Note: No set -eu because this is a conditional imp (returns exit codes for flow control)

[ -e "$1" ]
```

### Action: Print message
```sh
#!/bin/sh
# say MESSAGE - print message to stdout with newline
# Example: say "Hello world"

set -eu

printf '%s\n' "$*"
```

## Stub Imps

Imps used for mocking in tests must be prefixed with `stub-`:
- Location: `spells/.imps/test/`
- Purpose: Reusable test stubs for terminal I/O, system commands
- Naming: `stub-{command-name}` (e.g., `stub-fathom-cursor`, `stub-stty`)
- Usage: Tests create symlinks to these, not inline stub scripts

**Philosophy**: Stub the bare minimum (terminal I/O), test real wizardry for everything else.
