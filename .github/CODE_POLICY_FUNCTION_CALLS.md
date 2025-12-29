# Code Policy: Function Calls in Command Substitution

## Problem

When calling functions stored in variables within command substitution `$(...)`, some shells (particularly zsh) may have issues with function scoping in subshells, leading to functions not being available or behaving unexpectedly.

## Standard Pattern

When calling a function stored in a variable within command substitution, use `eval`:

```sh
# CORRECT: Use eval for variable function calls in command substitution
_cmd="function_name"
result=$(eval "$_cmd arg1 arg2" 2>&1)
```

```sh
# INCORRECT: Direct variable expansion may fail in some shells
_cmd="function_name"
result=$($_cmd arg1 arg2 2>&1)  # May fail in zsh
```

## Rationale

- **POSIX-compliant**: `eval` is part of POSIX standard
- **Cross-shell compatible**: Works reliably in sh, bash, zsh, dash, ksh
- **Explicit indirection**: Makes it clear that variable expansion happens before execution
- **Minimal change**: Requires only wrapping the command in `eval`
- **No special cases**: Can be applied consistently across the entire codebase

## Examples

### Command Substitution with Variable Function Call

```sh
# Determine which command to use (function or file)
_validate_cmd="validate_spells"
if ! command -v validate_spells >/dev/null 2>&1; then
  _validate_cmd="${WIZARDRY_DIR}/spells/system/validate-spells"
fi

# Use eval when calling in command substitution
missing=$(eval "$_validate_cmd --missing-only $spell_list" 2>/dev/null || true)
```

### Direct Function Call (No eval needed)

```sh
# When calling function directly (not in command substitution), eval is not needed
validate_spells --help

# When function name is fixed (not in variable), eval is not needed
result=$(validate_spells --missing-only "$list")
```

### When eval is NOT needed

- Direct function calls: `my_function arg1 arg2`
- Command substitution with literal function name: `result=$(my_function arg1)`
- Variable function calls outside command substitution: `$_cmd arg1 arg2`

### When eval IS needed

- Variable function calls inside command substitution: `result=$(eval "$_cmd arg1")`
- Any variable command execution where the command might be a function

## Security Considerations

When using `eval`, ensure that:
1. The variable content is controlled (not user input)
2. Arguments are properly quoted if they contain spaces
3. The command variable is validated before use

```sh
# Good: Variable is set internally, arguments are safe
_cmd="validate_spells"
result=$(eval "$_cmd --flag $safe_var" 2>&1)

# Be careful with user input (not recommended)
# user_cmd="$1"  # Don't do this
# result=$(eval "$user_cmd")  # Dangerous!
```

## Testing

When implementing this pattern, test with multiple shells:
- POSIX sh (dash)
- bash
- zsh (the problematic case)
- Interactive vs script contexts

## Related Issues

This pattern addresses issues where:
- Functions loaded via word-of-binding are not available in command substitution subshells
- zsh-specific function scoping causes unexpected behavior
- Cross-shell compatibility is required

## Status

**Approved**: This is the standard pattern for wizardry codebase as of 2024-12-29.
