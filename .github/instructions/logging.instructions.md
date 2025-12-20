# Logging and Output Standards

applyTo: "spells/**"

## Overview

Wizardry uses a standardized logging and output framework through the `out/` family of imps. This provides consistent messaging, error handling, and verbosity control across all spells.

## Log Levels

Wizardry respects the `WIZARDRY_LOG_LEVEL` environment variable:

- `0` (default): Critical messages only (`say`, `warn`, `die`, `fail`, `success`)
- `1`: Include informational messages (`info`, `step`)
- `2` or higher: Include debug messages (`debug`)

Set the log level:
```sh
export WIZARDRY_LOG_LEVEL=1  # Show info and step messages
export WIZARDRY_LOG_LEVEL=2  # Show all messages including debug
```

## Output Imps

### Core Output Imps

| Imp | Purpose | Output | Exit | Respect Log Level |
|-----|---------|--------|------|-------------------|
| `say` | Normal output | stdout | No | No (always shown) |
| `warn` | Warning message | stderr | No | No (always shown) |
| `die` | Fatal error | stderr | Yes (code 1 or custom) | No (always shown) |
| `fail` | Error return | stderr | No (returns 1) | No (always shown) |
| `usage-error` | Usage error | stderr | No (returns 2) | No (always shown) |

### Semantic Output Imps

| Imp | Purpose | Output | Exit | Respect Log Level |
|-----|---------|--------|------|-------------------|
| `success` | Success message | stdout | No | No (always shown) |
| `info` | Informational message | stdout | No | Yes (level >= 1) |
| `step` | Step in multi-step process | stdout | No | Yes (level >= 1) |
| `debug` | Debug information (prefixed with "DEBUG:") | stderr | No | Yes (level >= 2) |

### Utility Output Imps

| Imp | Purpose |
|-----|---------|
| `ok` | Run command silently (suppress all output) |
| `quiet` | Alias for `ok` |
| `else` | Output stdin if non-empty, else default value |
| `first-of` | Output first non-empty value |

## Usage Examples

### Basic Output

```sh
# Always shown - basic output
say "File copied successfully"

# Always shown - success message
success "Installation complete"

# Shown only if WIZARDRY_LOG_LEVEL >= 1
info "Processing 10 files..."
step "Installing dependencies..."

# Shown only if WIZARDRY_LOG_LEVEL >= 2
# Debug output includes "DEBUG:" prefix for easy identification
debug "Variable value: $my_var"
# Output: DEBUG: Variable value: test
```

### Error Handling

```sh
# Print warning (does not exit)
warn "File not found, using default"

# Fatal error with default exit code 1
die "Installation failed"

# Fatal error with custom exit code
die 2 "Invalid argument"

# Conditional error (returns 1, does not exit)
has git || fail "git required"

# Usage error (returns 2)
usage-error "$spell_name" "unknown option: $opt"
```

### Multi-Step Processes

```sh
#!/bin/sh
set -eu

info "Starting installation process"

step "Downloading package..."
download_package

step "Extracting files..."
extract_files

step "Configuring..."
configure

success "Installation complete"
```

### Debug Output

```sh
#!/bin/sh
set -eu

debug "Entering function: process_file"
debug "Input file: $file_path"
debug "Working directory: $(pwd)"

# Process file...

debug "Function complete"
```

## Signal Handling and Cleanup

### Cleanup on Exit/Interrupt

Use `on-exit` to register cleanup commands:

```sh
#!/bin/sh
set -eu

tmpfile=$(temp-file)
on-exit cleanup-file "$tmpfile"

# Work with tmpfile...
# Cleanup happens automatically on exit, interrupt, or error
```

### Clear Signal Traps

Use `clear-traps` to remove all signal handlers:

```sh
#!/bin/sh
set -eu

on-exit cleanup-file "$tmpfile"

# Do some work...

# Clear trap before exit (if cleanup already done)
clear-traps
```

### Standard Trap Pattern

For more complex cleanup:

```sh
#!/bin/sh
set -eu

cleanup() {
  cleanup-file "$tmpfile"
  cleanup-dir "$tmpdir"
}

on-exit cleanup

# Rest of script...
```

## Message Format Guidelines

### Descriptive, Not Imperative

Error messages should describe what went wrong, not tell the user what to do:

```sh
# CORRECT - describes the problem
die "spell-name: sshfs not found"
warn "spell-name: configuration file missing"

# WRONG - tells user what to do
die "Please install sshfs"
warn "You must create a configuration file"
```

### Spell Name Prefix

Error and warning messages should include the spell name:

```sh
warn "my-spell: configuration file not found"
die "my-spell: required argument missing"
```

### Self-Healing

When possible, spells should fix problems instead of just reporting them:

```sh
# Check for prerequisite
if ! has git; then
  info "git not found, installing..."
  pkg-install git || die "my-spell: could not install git"
fi
```

## Bootstrap Scripts Exception

The `install` script and scripts in `spells/install/core/` are bootstrap scripts that run before wizardry is fully installed. These scripts:

- Cannot use wizardry imps
- Must define their own output functions inline
- Should follow the same semantic patterns but with self-contained implementations

## Migration Guide

### Replacing Direct Output

```sh
# OLD
printf '%s\n' "Processing files..."
printf '%s\n' "Error: file not found" >&2

# NEW  
info "Processing files..."
warn "spell-name: file not found"
```

### Replacing Inline Error Functions

```sh
# OLD
error_msg() {
  printf '%s\n' "$*" >&2
  exit 1
}
error_msg "Installation failed"

# NEW
die "spell-name: installation failed"
```

### Adding Verbosity

```sh
# OLD - always prints
printf '%s\n' "Debug info: $var"

# NEW - respects log level
debug "Debug info: $var"
```

### Standardizing Cleanup

```sh
# OLD
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT HUP INT TERM

# NEW
tmpfile=$(temp-file)
on-exit cleanup-file "$tmpfile"
```

## Testing Output Imps

When writing tests for spells that use output imps:

```sh
# Test that info respects log level
WIZARDRY_LOG_LEVEL=1 run_spell "my-spell"
assert_output_contains "Processing files"

# Test that debug is hidden by default
run_spell "my-spell"
[ -z "$ERROR" ] || fail "expected no debug output"
```

## See Also

- `.github/instructions/spells.instructions.md` - Spell style guide
- `.github/instructions/imps.instructions.md` - Imp guidelines
- `spells/.imps/out/` - Output imp implementations
- `spells/.imps/sys/on-exit` - Signal handling
- `spells/.imps/sys/clear-traps` - Clear signal traps
