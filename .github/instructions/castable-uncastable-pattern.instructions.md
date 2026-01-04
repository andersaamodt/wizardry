# Castable/Uncastable Pattern Instructions

applyTo: "spells/**"

## DEPRECATED: This file contains outdated information

**The self-execute pattern with function wrappers is NO LONGER USED.**

All spells and imps should be flat, linear scripts without function wrappers.

See `.github/instructions/spells.instructions.md` and `.github/instructions/imps.instructions.md` for current patterns.

## Current Pattern (Flat Linear Scripts)

### Standard Spell Pattern

```sh
#!/bin/sh
# Brief description

spell_name_usage() {
  cat <<'USAGE'
Usage: spell-name [args]
Description.
USAGE
}

case "${1-}" in
--help|--usage|-h)
  spell_name_usage
  exit 0
  ;;
esac

set -eu

# Main logic here (flat, linear code)
```

**Key Points:**
1. Usage function defined at top (if the spell calls it)
2. Help handler before `set -eu`
3. `set -eu` after help handler
4. Main logic is flat and linear (no function wrappers)
5. Use `exit` (not `return`) - these are scripts, not functions

### Imp Pattern (Action)

```sh
#!/bin/sh
# imp-name ARG - brief description

set -eu

_imp_name() {
  # Implementation
}

case "$0" in
  */imp-name) _imp_name "$@" ;; esac
```

### Imp Pattern (Conditional - NO set -eu)

```sh
#!/bin/sh
# imp-name ARG - test if condition

_imp_name() {
  # Return 0 for true, 1 for false
}

case "$0" in
  */imp-name) _imp_name "$@" ;; esac
```

## Historical Note

The castable/uncastable pattern with function wrappers and `castable "$@"` / `uncastable` calls was previously used but has been deprecated in favor of simpler flat, linear scripts.
