# Code Policy: Managing set -eu in Interactive Functions

## Problem

When a function uses `set -eu` and returns a non-zero exit code, if that return is not explicitly handled by the caller, the calling shell may exit. This is particularly problematic for functions designed to be called from interactive shells, as it causes the terminal to exit unexpectedly.

## Root Cause

The `-e` flag (errexit) causes the shell to exit when a command returns non-zero. When set inside a function:
1. If the function returns non-zero (via `return 1` or `return 2`)
2. And the caller doesn't handle it (no `|| true`, no `if` statement)
3. The shell exits (manifests as `[Process completed]` in terminal)

Interactive shells don't typically use `set -e`, so they can't handle functions that internally use it.

## Standard Pattern

For spells that can be both executed as scripts AND called as interactive functions, use conditional `set -e`:

```sh
spell_name() {
  case "${1-}" in
  --help|--usage|-h)
    show_usage
    return 0
    ;;
  esac
  
  # Conditional strictness based on execution context
  case "$0" in
    */spell-name)
      # Executed as script - use full strict mode
      set -eu
      ;;
    *)
      # Called as function (sourced) - only undefined variable protection
      # This prevents interactive shell exit while maintaining safety
      set -u
      ;;
  esac
  
  # Rest of function implementation
  # ...
}
```

## When to Use Each Pattern

### Pattern 1: Conditional set -e (for interactive + script use)

Use for spells that:
- Are commonly called from interactive shells
- May return non-zero exit codes in normal operation
- Need to work in both script and interactive contexts

Examples: `banish`, `validate-spells`, `test-spell`

```sh
spell_name() {
  case "$0" in
    */spell-name) set -eu ;;  # Script mode
    *) set -u ;;              # Function mode
  esac
  # ...
}
```

### Pattern 2: Always set -eu (for script-only use)

Use for spells that:
- Are primarily executed as scripts
- Are not typically called from interactive shells
- Should exit on any error

Examples: `install`, build scripts, CI scripts

```sh
spell_name() {
  set -eu
  # ...
}
```

### Pattern 3: Only set -u (for function-only use)

Use for:
- Imps (always sourced, never executed)
- Library functions
- Helper functions

```sh
my_helper() {
  set -u
  # ...
}
```

## Rationale

- **Maintains strictness where appropriate**: Scripts still get full `set -eu` protection
- **Prevents interactive shell exit**: Functions won't kill the user's terminal
- **POSIX-compliant**: Uses only standard shell features
- **Architectural fix**: Addresses the root cause, not just symptoms
- **Consistent pattern**: Can be applied across the entire codebase

## How $0 Detection Works

The `$0` variable contains:
- **When executed as script**: `/path/to/spell-name` (matches `*/spell-name`)
- **When called as function**: Shell name (`zsh`, `bash`, `-zsh`) or parent script name (doesn't match)

This reliable distinction allows us to detect execution context.

## Examples

### Before (Problematic)

```sh
banish() {
  set -eu  # Always strict
  
  # ... validation logic ...
  
  if [ "$invalid" ]; then
    return 2  # Shell exits! ❌
  fi
}

# In interactive shell:
% banish invalid_arg
[Process completed]  # Terminal exits!
```

### After (Fixed)

```sh
banish() {
  case "$0" in
    */banish) set -eu ;;  # Script mode
    *) set -u ;;          # Function mode
  esac
  
  # ... validation logic ...
  
  if [ "$invalid" ]; then
    return 2  # Shell continues ✓
  fi
}

# In interactive shell:
% banish invalid_arg
Error: invalid argument
% # Shell is still running ✓
```

## Error Handling Best Practices

When using `set -eu` (script mode), ensure:

1. **All commands that may fail have error handling**:
   ```sh
   command_that_might_fail || return 1
   ```

2. **Command substitutions have fallbacks**:
   ```sh
   result=$(command 2>/dev/null || true)
   ```

3. **Optional operations are wrapped**:
   ```sh
   if command -v optional_tool >/dev/null 2>&1; then
     optional_tool
   fi
   ```

## Testing

Test both execution modes:

```sh
# Test as script
./spells/system/spell-name args

# Test as function (via word-of-binding)
. spells/.imps/sys/word-of-binding
word_of_binding spell-name
spell-name args
```

Verify:
- Script mode: Should exit on errors (when appropriate)
- Function mode: Should return error codes without exiting shell

## Related Patterns

### Explicit Error Handling (Alternative)

Instead of disabling `-e` in function mode, handle all errors explicitly:

```sh
spell_name() {
  set -eu
  
  # Wrap all potentially failing operations
  if ! operation1; then
    return 1
  fi
  
  if ! operation2; then
    return 1
  fi
}
```

This works but is more verbose and error-prone. The conditional `set -e` pattern is preferred.

## Status

**Approved**: This is the standard pattern for wizardry codebase as of 2024-12-29.

**Migration**: Existing spells should be updated to use this pattern when:
- They are used interactively
- They exhibit shell exit behavior
- During regular maintenance
