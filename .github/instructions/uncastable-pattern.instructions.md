# Uncastable Pattern Instructions

applyTo: "spells/**"

## What is "Uncastable"?

**Uncastable** spells are those that MUST be sourced (not executed) to work correctly. This is required for spells that modify the calling shell's state, such as:
- Changing the current directory (`cd`)
- Setting environment variables
- Defining shell functions or aliases

## Standard Uncastable Pattern

All source-only spells must use this exact pattern immediately after the `--help` handler:

```sh
# Uncastable: Must be sourced, not executed
_spell_sourced=0
if eval '[ -n "${ZSH_VERSION+x}" ]' 2>/dev/null; then
  case "${ZSH_EVAL_CONTEXT-}" in
    *:file) _spell_sourced=1 ;;
  esac
else
  _spell_base=${0##*/}
  case "$_spell_base" in
    sh|dash|bash|zsh|ksh|mksh) _spell_sourced=1 ;;
    spell-name) _spell_sourced=0 ;;
    *) _spell_sourced=1 ;;
  esac
fi

if [ "$_spell_sourced" -eq 0 ]; then
  printf '%s\n' "spell-name: must be sourced, not executed" >&2
  printf '%s\n' "Usage: . spell-name" >&2
  exit 1
fi
unset _spell_sourced _spell_base
```

### Pattern Requirements

1. **Comment marker**: First line must be exactly `# Uncastable: Must be sourced, not executed`
2. **Variable prefix**: Use a unique prefix for variables (e.g., `_jt_` for jump-trash, `_jtm_` for jump-to-marker)
3. **Spell name**: Replace `spell-name` with the actual spell name in THREE places:
   - In the case statement matching `${0##*/}`
   - In the error message
   - In the usage message
4. **Placement**: Must come after `--help` handler, before `set -eu`

### Example: jump-trash

```sh
#!/bin/sh

# This spell teleports you to your system trash directory.
# Must be sourced (not executed) to change your shell's directory.

case "${1-}" in
--help|--usage|-h)
  cat << 'USAGE'
Usage: . jump-trash

Teleport to your system trash directory.
This spell must be sourced (note the dot) to change your current directory.
USAGE
  exit 0
  ;;
esac

# Uncastable: Must be sourced, not executed
_jt_sourced=0
if eval '[ -n "${ZSH_VERSION+x}" ]' 2>/dev/null; then
  case "${ZSH_EVAL_CONTEXT-}" in
    *:file) _jt_sourced=1 ;;
  esac
else
  _jt_base=${0##*/}
  case "$_jt_base" in
    sh|dash|bash|zsh|ksh|mksh) _jt_sourced=1 ;;
    jump-trash) _jt_sourced=0 ;;
    *) _jt_sourced=1 ;;
  esac
fi

if [ "$_jt_sourced" -eq 0 ]; then
  printf '%s\n' 'Use "jump trash" to invoke this spell, as it is uncastable directly.' >&2
  exit 1
fi
unset _jt_sourced _jt_base

set -eu
. env-clear

# Main spell logic...
```

## When to Use

Use the uncastable pattern when a spell MUST modify the calling shell's environment:

| Use Case | Needs Uncastable? | Reason |
|----------|-------------------|--------|
| Change directory (`cd`) | ✅ Yes | Must affect caller's shell |
| Set environment variables | ✅ Yes | Must persist in caller's shell |
| Define shell functions | ✅ Yes | Must be available in caller's shell |
| Print output | ❌ No | Can be executed normally |
| Process files | ❌ No | Can be executed normally |
| Run commands | ❌ No | Can be executed normally |

## Common Mistakes

❌ **Wrong - Using old uncastable imp:**
```sh
if ! . uncastable; then
  exit 1
fi
```

❌ **Wrong - Missing comment marker:**
```sh
_jt_sourced=0
if eval '[ -n "${ZSH_VERSION+x}" ]' 2>/dev/null; then
  # ... pattern continues
```

❌ **Wrong - Incorrect variable prefix:**
```sh
# Using generic names that could conflict
sourced=0
base=${0##*/}
```

❌ **Wrong - Wrong spell name:**
```sh
case "$_jt_base" in
  sh|dash|bash|zsh|ksh|mksh) _jt_sourced=1 ;;
  wrong-name) _jt_sourced=0 ;;  # Should be jump-trash!
```

✅ **Correct:**
```sh
# Uncastable: Must be sourced, not executed
_jt_sourced=0
if eval '[ -n "${ZSH_VERSION+x}" ]' 2>/dev/null; then
  case "${ZSH_EVAL_CONTEXT-}" in
    *:file) _jt_sourced=1 ;;
  esac
else
  _jt_base=${0##*/}
  case "$_jt_base" in
    sh|dash|bash|zsh|ksh|mksh) _jt_sourced=1 ;;
    jump-trash) _jt_sourced=1 ;;
    *) _jt_sourced=1 ;;
  esac
fi

if [ "$_jt_sourced" -eq 0 ]; then
  printf '%s\n' 'jump-trash: must be sourced, not executed' >&2
  printf '%s\n' 'Usage: . jump-trash' >&2
  exit 1
fi
unset _jt_sourced _jt_base
```

## Testing

Tests should verify both sourced and executed behavior:

```sh
test_help() {
  run_spell "spells/arcane/jump-trash" --help
  assert_success && assert_output_contains "Usage:"
}

test_cds_when_sourced() {
  run_cmd sh -c "
    . '$ROOT_DIR/spells/arcane/jump-trash'
    pwd
  "
  assert_success || return 1
  assert_output_contains "teleport to the trash" || return 1
}
```

## Why This Pattern?

**Transparency**: The inline pattern makes it immediately clear what the spell does without needing to trace through imp dependencies.

**Standardization**: All source-only spells use the exact same pattern in the exact same location.

**POSIX Compliance**: The pattern works reliably across all POSIX-compliant shells (sh, dash, bash, zsh, etc.)

**Testability**: Automated tests can verify the pattern is correctly implemented.

## Historical Note

The `uncastable` imp has been deprecated in favor of this inline pattern. The imp approach was less transparent and required passing information to the imp, which defeated its original purpose of being "smart enough" to detect on its own.
