# Migration Guide: Adopting the Logging Framework

This guide helps migrate existing spells to use the new standardized logging framework.

## Quick Reference

### Replace Direct Output

```sh
# OLD: Direct printf to stdout
printf '%s\n' "Processing files..."

# NEW: Use info for informational messages
info "Processing files..."

# OLD: Direct printf to stderr
printf '%s\n' "Warning: configuration missing" >&2

# NEW: Use warn for warnings
warn "spell-name: configuration missing"
```

### Replace Custom Error Functions

```sh
# OLD: Custom error function
error_exit() {
  printf '%s\n' "$*" >&2
  exit 1
}
error_exit "Installation failed"

# NEW: Use die
die "spell-name: installation failed"
```

### Add Verbosity Levels

```sh
# OLD: Always print debug info
printf '%s\n' "Debug: variable=$var"

# NEW: Respect log level
debug "variable=$var"
# Only shown when WIZARDRY_LOG_LEVEL >= 2
```

### Standardize Cleanup

```sh
# OLD: Manual trap
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT HUP INT TERM

# NEW: Use on-exit with cleanup-file
tmpfile=$(temp-file)
on-exit cleanup-file "$tmpfile"
```

## Step-by-Step Migration

### Step 1: Identify Output Patterns

Look for these patterns in your spell:
- Direct `printf` calls
- Custom error/info/debug functions
- Direct `>&2` redirects
- Manual trap statements

### Step 2: Choose Appropriate Imps

| Current Pattern | New Imp | When to Use |
|----------------|---------|-------------|
| Normal output | `say` | User-facing output (always shown) |
| Success message | `success` | Completion messages (always shown) |
| Info message | `info` | Process information (level >= 1) |
| Step indicator | `step` | Multi-step processes (level >= 1) |
| Debug output | `debug` | Debugging info (level >= 2) |
| Warning | `warn` | Non-fatal issues (always shown) |
| Fatal error | `die` | Fatal errors that exit (always shown) |
| Error return | `fail` | Non-fatal errors that return 1 |
| Usage error | `usage-error` | Argument/usage errors (return 2) |

### Step 3: Update Error Messages

Make error messages descriptive, not imperative:

```sh
# WRONG: Tells user what to do
die "Please install git"
warn "You must set EDITOR"

# RIGHT: Describes what's wrong
die "spell-name: git not found"
warn "spell-name: EDITOR not set"
```

### Step 4: Add Signal Handling

If your spell creates temporary resources:

```sh
# At the top, after set -eu
tmpfile=$(temp-file)
tmpdir=$(temp-dir)

# Register cleanup
cleanup() {
  cleanup-file "$tmpfile"
  cleanup-dir "$tmpdir"
}
on-exit cleanup

# Or for single resource
on-exit cleanup-file "$tmpfile"
```

### Step 5: Test with Different Log Levels

```sh
# Test at level 0 (default)
./my-spell

# Test at level 1 (info/step shown)
WIZARDRY_LOG_LEVEL=1 ./my-spell

# Test at level 2 (debug shown)
WIZARDRY_LOG_LEVEL=2 ./my-spell
```

## Example Migration

### Before

```sh
#!/bin/sh
set -eu

error() {
  printf '%s\n' "ERROR: $*" >&2
  exit 1
}

info() {
  printf '%s\n' "INFO: $*"
}

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT HUP INT TERM

if ! command -v git >/dev/null; then
  error "git not installed"
fi

info "Starting process"
printf '%s\n' "Processing file..."
info "Process complete"
```

### After

```sh
#!/bin/sh
set -eu

# Cleanup
tmpfile=$(temp-file)
on-exit cleanup-file "$tmpfile"

# Check prerequisites
has git || die "my-spell: git not found"

# Process with appropriate verbosity
info "Starting process"
step "Processing file..."
success "Process complete"
```

## Testing Your Migration

1. **Run the spell** at different log levels
2. **Test error conditions** to ensure errors are descriptive
3. **Test cleanup** by interrupting with Ctrl-C
4. **Run vet-spell** to check style compliance
5. **Update tests** to use new patterns

## Common Patterns

### Multi-Step Process

```sh
info "Starting installation"

step "Step 1: Downloading package"
download_package
debug "Downloaded to: $pkg_path"

step "Step 2: Extracting files"
extract_files
debug "Extracted $(count_files) files"

step "Step 3: Configuring"
configure

success "Installation complete"
```

### Error Handling

```sh
# Check prerequisite
has curl || die "my-spell: curl not found"

# Try operation
if ! download_file "$url" "$dest"; then
  die "my-spell: download failed"
fi

# Conditional warning
if [ ! -f "$config" ]; then
  warn "my-spell: configuration file missing, using defaults"
fi
```

### Cleanup on Error

```sh
tmpfile=$(temp-file)
on-exit cleanup-file "$tmpfile"

# If any command fails, cleanup runs automatically
download_file "$url" "$tmpfile" || die "my-spell: download failed"
process_file "$tmpfile" || die "my-spell: processing failed"

# On success, cleanup still runs
success "Operation complete"
```

## Bootstrap Script Exception

The `install` script and scripts in `spells/install/core/` are bootstrap scripts that run before wizardry is installed. These scripts:

- Cannot use wizardry imps
- Must define their own output functions inline
- Should follow the same semantic patterns but with self-contained implementations

Example from `install`:

```sh
info_msg() {
  printf '%s==>%s %s\n' "$BOLD$CYAN" "$RESET" "$*"
}

success_msg() {
  printf '%s✓%s %s\n' "$BOLD$GREEN" "$RESET" "$*"
}
```

This is acceptable and necessary for bootstrap scripts only.

## Need Help?

- See `.github/instructions/logging.instructions.md` for complete documentation
- See `spells/cantrips/logging-example` for a working example
- Run `logging-example --help` for usage examples

## Summary

The logging framework provides:
- ✅ Consistent output across all spells
- ✅ User-controllable verbosity
- ✅ Clear error messages
- ✅ Standardized cleanup
- ✅ Self-documenting code
