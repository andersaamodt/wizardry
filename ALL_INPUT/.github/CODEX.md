# Codex Instructions

This file provides OpenAI Codex with project-specific guidance. Codex discovers and reads this file automatically.

## Project Overview

Wizardry is a collection of POSIX shell scripts themed as magical spells for the terminal. See `README.md` for full details.

## Tech Stack

- **Language**: POSIX sh only (`#!/bin/sh`)
- **Style checker**: `lint-magic` and `checkbashisms`
- **Testing**: `.tests/` directory with `test_common.sh` framework

## Essential Commands

```sh
# Check spell style compliance
lint-magic --strict spells/category/spell-name

# Run tests
.tests/common-tests.sh  # or use spells/system/test-magic

# Check POSIX compliance
checkbashisms spells/category/spell-name
```

## Code Standards

### Always
- Use `#!/bin/sh` shebang (never `#!/bin/bash`)
- Use `set -eu` for strict error handling
- Quote all variables: `"$var"`
- Use `[ ]` not `[[ ]]` for tests
- Use `=` not `==` for string comparison
- Use `printf` not `echo`
- Use `command -v` not `which`

### Never
- Bash-isms: arrays, `local`, `source`, `[[ ]]`, `$RANDOM`
- Imperative error messages ("Please install X")
- Global variables (use parameters/stdout)
- Unquoted variables

## File Structure

```
spells/           # Main spell scripts
spells/.imps/     # Micro-helper scripts (imps)
.tests/           # Test files mirroring spells/ structure
```

## Spell Template

```sh
#!/bin/sh

# Brief description of what this spell does.

show_usage() {
  cat <<'USAGE'
Usage: spell-name [options] [arguments]

Description of what the spell does.
USAGE
}

case "${1-}" in
--help|--usage|-h)
  show_usage
  exit 0
  ;;
esac

set -eu

# Main logic here
```

## Imp Template (for spells/.imps/)

```sh
#!/bin/sh
# imp-name ARG1 ARG2 - brief description

set -eu

# Implementation (1-10 lines, no functions)
```

## Cross-Platform Patterns

```sh
# Command availability
if command -v tool >/dev/null 2>&1; then tool "$@"; fi

# Path resolution (not realpath)
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)

# Temporary files
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/prefix.XXXXXX")
```

## References

- See `.AGENTS.md` for detailed style guide
- See `README.md` for project principles
- See `.github/instructions/` for topic-specific guidance
