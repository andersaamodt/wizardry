# Imps Instructions

applyTo: "spells/.imps/**"

## What Are Imps?

Imps are micro-helper scripts—the smallest semantic building blocks in wizardry. They live in `spells/.imps/` and abstract common shell patterns into readable, well-documented microscripts.

## Imp Requirements

### Required Elements
- **Shebang**: `#!/bin/sh` (POSIX only)
- **Opening comment**: Brief description of what it does
- **Strict mode**: `set -eu`

### Relaxed Rules (compared to spells)
- **No `--help` required**: The opening comment serves as the imp's spec
- **No `show_usage()` required**: Keep imps minimal

## Imp Template

```sh
#!/bin/sh
# imp-name ARG1 ARG2 - brief description of what it does
# Example: imp-name "value1" "value2" && echo "success"

set -eu

# Implementation (usually 1-10 lines)
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
- `str/` — String operations
- `fs/` — Filesystem operations
- `sys/` — System utilities
- `input/` — User input handling
- `out/` — Output formatting
- `test/` — Test-only imps (prefixed `test-`)

## Example Imps

### String contains check
```sh
#!/bin/sh
# contains HAYSTACK NEEDLE - test if string contains substring
# Example: contains "$PATH" "/usr/local/bin" && echo "found"

set -eu

case "$1" in
*"$2"*) exit 0 ;;
*) exit 1 ;;
esac
```

### Path existence check
```sh
#!/bin/sh
# exists PATH - test if path exists (file or directory)

set -eu

[ -e "$1" ]
```

## Test-Only Imps

Imps used only in tests must be prefixed with `test-`:
- Location: `spells/.imps/test/`
- Purpose: Test stubs, fixtures, helpers
- Not for production use
