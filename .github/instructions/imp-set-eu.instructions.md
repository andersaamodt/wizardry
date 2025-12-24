# Imp set -eu Standard

applyTo: "spells/.imps/**"

## CRITICAL RULE: Only ONE `set -eu` Per Imp

**NEVER put `set -eu` twice in an imp file.** This causes terminal hangs when invoke-wizardry sources the imp.

### The Problem

When invoke-wizardry sources imps during shell initialization, it runs in **permissive mode** (`set +eu`). If an imp has `set -eu` outside its function definition (e.g., before the `case` statement), it switches the parent shell from permissive to strict mode, causing subsequent operations to fail or hang.

### Correct Pattern (Action Imp)

```sh
#!/bin/sh
# imp-name ARG - description
set -eu              # ← ONE set -eu at the top

_imp_name() {
  # Function body
}

# Self-execute when run directly (not sourced)
case "$0" in
  */imp-name) _imp_name "$@" ;; esac  # ← NO set -eu here!
```

### WRONG Pattern (Causes Hang)

```sh
#!/bin/sh
# imp-name ARG - description
set -eu              # ← First set -eu

_imp_name() {
  # Function body
}

# Self-execute when run directly (not sourced)
set -eu              # ← ❌ DUPLICATE! This breaks invoke-wizardry!
case "$0" in
  */imp-name) _imp_name "$@" ;; esac
```

### Conditional Imps (No set -eu at all)

Conditional imps that return exit codes for flow control should NOT use `set -eu`:

```sh
#!/bin/sh
# has COMMAND - test if command exists
# Example: has git && git status

_has() {
  command -v "$1" >/dev/null 2>&1
}

# Self-execute when run directly (not sourced)
case "$0" in
  */has) _has "$@" ;; esac
```

### Testing

The test `.tests/spellcraft/test-no-duplicate-set-eu.sh` automatically checks ALL imps for duplicate `set -eu` statements. This test will fail CI if any imp violates this rule.

Run it with:
```sh
.tests/spellcraft/test-no-duplicate-set-eu.sh
```

### Why This Matters

- **macOS**: Terminal hangs on startup after install
- **All platforms**: Breaks invoke-wizardry's permissive mode, causing unpredictable failures
- **Menu doesn't work**: If sourcing fails, the `menu` command isn't available

### Summary

✅ **DO**: One `set -eu` at the top (action imps only)  
❌ **DON'T**: Duplicate `set -eu` before case statement  
✅ **DO**: No `set -eu` for conditional imps  
✅ **DO**: Run `test-no-duplicate-set-eu.sh` to verify
