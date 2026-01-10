# Best Practices from Wizardry Codebase

applyTo: "spells/**,.tests/**"

**PRIMARY REFERENCE:** `.github/SHELL_CODE_PATTERNS.md`

This file provides quick-reference patterns from the wizardry codebase. For comprehensive POSIX shell patterns, idioms, and performance optimizations, see **SHELL_CODE_PATTERNS.md**.

## Documentation Hierarchy

1. **FULL_SPEC.md** - Canonical specification (what/constraints)
2. **SHELL_CODE_PATTERNS.md** - POSIX shell patterns and best practices (how/idioms) ← **PRIMARY SOURCE**
3. **CROSS_PLATFORM_PATTERNS.md** - Cross-platform exceptions (compatibility)
4. **EXEMPTIONS.md** - Documented exceptions
5. **LESSONS.MD** - Debugging insights

## Quick Patterns

### Flat Linear Script Pattern

```sh
#!/bin/sh
# Brief description

case "${1-}" in
--help|--usage|-h) show_usage; exit 0 ;; esac

set -eu

# Main logic (flat, linear - no function wrappers)
```

### Error Messages (Descriptive, Not Imperative)

```sh
# ✓ RIGHT
die "spell-name: sshfs not found"

# ✗ WRONG  
die "Please install sshfs"
```

### Variable Defaults (For set -u)

```sh
value=${1-}              # Empty if unset
value=${1:-default}      # "default" if unset OR empty
```

### Conditional Imps (No set -eu)

```sh
#!/bin/sh
# has COMMAND - test if exists
# Note: No set -eu (returns exit codes for flow control)
command -v "$1" >/dev/null 2>&1
```

### Test Naming

**Pattern:** `test-<name>.sh` (hyphens, NOT underscores)

- `spells/cantrips/ask-yn` → `.tests/cantrips/test-ask-yn.sh`
- `spells/.imps/out/say` → `.tests/.imps/out/test-say.sh`

## For Complete Patterns

See **`.github/SHELL_CODE_PATTERNS.md`** for:
- Performance optimizations (basename replacement, etc.)
- Variable handling patterns
- Aliases and sourced scripts  
- Function naming constraints
- set -eu behavior details
- Exit code handling
- Signal traps and cleanup
- And much more...
