# Spell Style Guide

This guide defines the format and code style for wizardry spells. All spells in `spells/` should follow these conventions to maintain consistency, readability, and cross-platform compatibility.

Use `vet-spell` to check spells for style compliance:

```sh
# Check all spells (core checks only)
vet-spell

# Check with full strict mode (includes usage function and help handler checks)
vet-spell --strict

# Check a specific spell
vet-spell --strict spells/category/spell-name
```

---

## Spell Structure

The recommended spell structure is:

```sh
#!/bin/sh

# Brief description of what this spell does.
# Additional context about usage or purpose (optional second line).

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

---

## Required Elements

These elements are enforced by `vet-spell` by default.

### 1. Shebang (Required)

Every spell must start with:

```sh
#!/bin/sh
```

Also acceptable: `#!/usr/bin/env sh`

Do not use `#!/bin/bash` or other interpreters. POSIX compliance is mandatory.

### 2. Opening Description Comment (Required)

Immediately after the shebang, include a brief description:

```sh
# This spell does X.
# Use it when Y (optional second line).
```

Guidelines:
- First line: What the spell does (one sentence)
- Second line (optional): When/why to use it
- Keep it to 1-2 lines maximum
- Start with "This spell..."

### 3. Strict Mode (Required)

Enable strict mode:

```sh
set -eu
```

- `-e`: Exit on error
- `-u`: Error on undefined variables

Note: `set -e` alone is also accepted, but `set -eu` is preferred.

---

## Recommended Elements

These elements are checked by `vet-spell --strict` but not enforced by default.

### 4. Usage Function (Recommended)

Define a `show_usage` or `usage` function with a heredoc:

```sh
show_usage() {
  cat <<'USAGE'
Usage: spell-name [options] [arguments]

Description of the spell and its arguments.
USAGE
}
```

Guidelines:
- Use single-quoted heredoc delimiter `'USAGE'` to prevent variable expansion
- First line: `Usage:` followed by synopsis
- Include all options and arguments
- The --help message **is** the spell's spec

### 5. Help Handler (Recommended)

Handle `--help`, `--usage`, and `-h` before `set -eu`:

```sh
case "${1-}" in
--help|--usage|-h)
  show_usage
  exit 0
  ;;
esac
```

Why before `set -eu`? So `${1-}` works when no arguments are provided.

---

## Imps (Short Spells)

Imps are brief utility spells that live in `spells/.imps/`. They have relaxed requirements:

- **No `--help` required**: The opening comment serves as their spec
- **Opening comment required**: Must describe what the imp does
- **Shebang required**: `#!/bin/sh`
- **Strict mode required**: `set -eu`

Example imp:

```sh
#!/bin/sh

# Print the current date in ISO 8601 format.

set -eu

date +%Y-%m-%d
```

---

## Code Style

### Variable Assignment

Use proper empty assignment syntax:

```sh
# CORRECT
var=''
var=""

# WRONG - creates variable with trailing space
var= 
```

### Variable Expansion

Always use proper expansion with defaults:

```sh
# CORRECT
value=${1-}              # Empty default
value=${1:-default}      # Non-empty default

# WRONG
value=$1                 # Fails with set -u if $1 unset
```

### Quoting

Always quote variables unless word splitting is intended:

```sh
# CORRECT
printf '%s\n' "$message"
path="$HOME/wizardry"

# WRONG
printf '%s\n' $message
path=$HOME/wizardry
```

### Functions

Keep functions minimal. Prefer linear, flat code flow:

```sh
# PREFERRED - linear flow
if [ -z "$input" ]; then
  printf 'Error: no input\n' >&2
  exit 1
fi
# continue with logic...

# AVOID - excessive function wrapping
validate_input() { ... }
process_input() { ... }
output_result() { ... }
validate_input "$1"
process_input "$1"
output_result
```

### Error Messages

Print errors to stderr with the spell name as prefix:

```sh
printf '%s\n' "spell-name: error message here." >&2
exit 1
```

Include actionable guidance when possible:

```sh
printf '%s\n' "spell-name: dependency missing." >&2
printf '%s\n' "Run 'menu' to install wizardry dependencies." >&2
exit 1
```

### Temporary Files

Use `mktemp` with proper cleanup:

```sh
tmp_file=$(mktemp "${TMPDIR:-/tmp}/spell-name.XXXXXX") || exit 1
# ... use tmp_file ...
rm -f "$tmp_file"
```

### Command Substitution

Use `$()` syntax, not backticks:

```sh
# CORRECT
result=$(command)

# WRONG
result=`command`
```

### Exit Codes

- `0`: Success
- `1`: General error
- `2`: Usage error (wrong arguments)

---

## POSIX Compliance

All spells must pass `checkbashisms`. Avoid:

- `[[ ]]` - use `[ ]` instead
- `read -d` - not POSIX
- `$'string'` - ANSI-C quoting not portable
- `{1..10}` - brace expansion not POSIX
- `local` - use plain variable assignment
- `source` - use `.` instead
- Arrays - not available in POSIX sh

### Portable Patterns

```sh
# String contains (instead of [[ =~ ]])
case "$string" in
  *substring*)
    # contains substring
    ;;
esac

# Default value
value=${1:-default}

# Conditional assignment
: "${VAR:=default}"
```

---

## Cross-Platform Considerations

### Path Handling

Don't assume paths exist on all systems:

```sh
# CORRECT - use command -v
if command -v tool >/dev/null 2>&1; then
  tool "$@"
fi

# WRONG - assume path
if [ -x /usr/bin/tool ]; then
  /usr/bin/tool "$@"
fi
```

### Color Support

Load colors gracefully with fallback:

```sh
if colors_path=$(command -v colors 2>/dev/null); then
  # shellcheck disable=SC1090
  . "$colors_path"
else
  RESET=''
  BLUE=''
fi
```

---

## Documentation

### Spell Headers

Model header:

```sh
#!/bin/sh

# This spell displays a location's extended attributes as a description.
# It can prompt to memorize itself so the `look` incantation stays available.
```

### Help Text

Model help:

```sh
show_usage() {
  cat <<'USAGE'
Usage: look [path]

Display a location's name and description extended attributes using read-magic,
offering to memorize the spell into your shell rc for persistent availability.
Defaults to the current directory when no path is supplied.
USAGE
}
```

---

## Testing

Every spell should have a corresponding test file:

- Location: `tests/<category>/test_<spell-name>.sh`
- Pattern: Source `test_common.sh`, use `run_test_case`, call `finish_tests`
- Coverage: Test `--help`, success cases, error cases

Example:

```sh
#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

test_help() {
  run_spell "spells/category/spell-name" --help
  assert_success && assert_output_contains "Usage:"
}

run_test_case "spell prints usage" test_help
finish_tests
```

---

## Model Spells

Study these spells as templates:

1. **`spells/arcane/look`** - Excellent help, error handling, self-installation
2. **`spells/spellcraft/forall`** - Minimal, focused, well-documented
3. **`spells/cantrips/menu`** - Complex but well-structured

---

## Checklist

Before submitting a spell, verify:

- [ ] Shebang is `#!/bin/sh`
- [ ] Opening description comment exists (1-2 lines)
- [ ] `show_usage` function exists (unless it's an imp)
- [ ] Help handler handles `--help`, `--usage`, `-h` (unless it's an imp)
- [ ] `set -eu` is present
- [ ] Variables are properly quoted
- [ ] Empty variables use `var=''` not `var= `
- [ ] Errors go to stderr with spell name prefix
- [ ] Passes `checkbashisms`
- [ ] Test file exists at `tests/<category>/test_<spell-name>.sh`

---

*May your spells cast true!* 🧙‍♂️✨
