# POSIX Cross-Platform Compatibility Guide

This document collates cross-platform knowledge from the Wizardry project to help maintain POSIX-compliant, cross-platform shell scripts. All patterns described here have been battle-tested in our spells.

## Supported Platforms

Wizardry targets POSIX-compliant systems:
- **Linux distributions**: Debian, Ubuntu, Arch, Fedora, NixOS
- **macOS** (Darwin kernel)
- **BSD variants** (limited support)

## Core POSIX Principles

### 1. Use `#!/bin/sh` Not `#!/bin/bash`

Always use POSIX sh, not bash-specific features:
```sh
#!/bin/sh
# NOT #!/bin/bash
```

### 2. Enable Strict Error Handling

```sh
set -eu
# -e: exit on error
# -u: exit on undefined variable
```

## Platform Detection

### Detecting the Operating System

Use `uname` to detect the kernel:

```sh
# Simple detection
if uname 2>/dev/null | grep -q 'Darwin'; then
    platform=mac
fi

# Or use uname -s
kernel=$(uname -s 2>/dev/null || printf 'unknown')
case $kernel in
    Darwin)
        platform=mac
        ;;
    Linux)
        platform=linux
        ;;
    *)
        platform=unknown
        ;;
esac
```

### Detecting Linux Distributions

Check distribution-specific files:

```sh
if [ -f /etc/NIXOS ] || grep -qi 'ID=nixos' /etc/os-release 2>/dev/null; then
    distro=nixos
elif [ -f /etc/debian_version ]; then
    distro=debian
elif [ -f /etc/arch-release ]; then
    distro=arch
elif [ -f /etc/fedora-release ]; then
    distro=fedora
fi
```

## Path Handling and Resolution

### macOS TMPDIR Double-Slash Issue

**Critical Issue**: On macOS, `$TMPDIR` typically ends with a trailing slash (e.g., `/var/folders/xx/yyy/T/`). When concatenating paths, this creates double slashes: `$TMPDIR/subdir` becomes `/var/folders/xx/yyy/T//subdir`.

**Solution**: Always normalize paths with `sed 's|//|/|g'`:

```sh
# When building paths that might have double slashes
destination=$(pwd -P)
destination=$(printf '%s\n' "$destination" | sed 's|//|/|g')

# When comparing paths
current=$(pwd -P | sed 's|//|/|g')
normalized_destination=$(echo "$destination" | sed 's|//|/|g')
if [ "$current" = "$normalized_destination" ]; then
    # paths match
fi
```

**When to normalize**:
1. After concatenating `$TMPDIR` with other paths
2. After using `pwd -P` in path comparisons
3. Before storing paths in files for later comparison
4. When displaying paths to users (optional, for aesthetics)

### Resolving Paths to Absolute Form

Use `pwd -P` to resolve symlinks and get canonical paths:

```sh
# Get absolute path of current directory
destination=$(pwd -P)

# Get absolute path of a file/directory
destination="$(cd "$(dirname "$1")" && pwd -P)/$(basename "$1")"

# Get script's own directory
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
```

**Important**: Always disable `CDPATH` when resolving paths:
```sh
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
```

### Home Directory Expansion

Shell does NOT expand `~` in variables. Handle it explicitly:

```sh
case $path in
    "~/"*)
        # Expand tilde to $HOME
        if [ -n "${HOME-}" ]; then
            path="$HOME/${path#"~/"}"
        fi
        ;;
esac
```

### Avoiding `realpath` and `readlink`

**Problem**: `realpath` is not POSIX-standard and may not be available on all systems. `readlink` behavior varies between GNU and BSD versions.

**Solution**: Use `pwd -P` instead:

```sh
# Instead of: realpath "$file"
# Use:
abs_path="$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")"
```

## Command Availability Checking

### Always Use `command -v`, Not `which`

```sh
# CORRECT: POSIX-compliant
if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$file"
fi

# WRONG: which is not POSIX and behaves differently across systems
if which pbcopy >/dev/null; then
    # Don't do this
fi
```

### Platform-Specific Command Fallbacks

Check for platform-specific tools in order of preference:

```sh
# Clipboard tools: prefer platform-native, then fallback
if command -v pbcopy >/dev/null 2>&1; then
    # macOS native
    pbcopy < "$file"
elif command -v xsel >/dev/null 2>&1; then
    # Linux alternative 1
    xsel --clipboard --input < "$file"
elif command -v xclip >/dev/null 2>&1; then
    # Linux alternative 2
    xclip -selection clipboard < "$file"
else
    echo "No clipboard utility available" >&2
    exit 1
fi
```

## Temporary Files and Directories

### Creating Temp Directories

```sh
# POSIX-compliant temp directory creation
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/prefix.XXXXXX")

# In tests, use WIZARDRY_TMPDIR
tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/case.XXXXXX")
```

### Handling TMPDIR

```sh
# Always provide fallback if TMPDIR is unset
: "${TMPDIR:=/tmp}"

# When using TMPDIR in paths, normalize double slashes (see Path Handling above)
temp_file="$TMPDIR/myfile.txt"
temp_file=$(echo "$temp_file" | sed 's|//|/|g')
```

## Shell RC File Detection

Different platforms use different shell configuration files:

### macOS
1. `~/.zshrc` (default shell since macOS Catalina)
2. `~/.zprofile`
3. `~/.bash_profile`

### Linux (Debian, Ubuntu, Arch, Fedora)
1. `~/.bashrc`
2. `~/.profile`

### NixOS
1. `~/.config/nixpkgs/configuration.nix`
2. `~/.bashrc`
3. `~/.bash_profile`

## Text Processing

### Using `sed` for Path Manipulation

```sh
# Normalize double slashes
path=$(echo "$path" | sed 's|//|/|g')

# Use | as delimiter for paths (not /)
# WRONG: sed 's/old/new/g'  # breaks with paths containing /
# RIGHT: sed 's|old|new|g'   # works with paths
```

### Using `awk`

```sh
# Get specific field
pid=$(ps -ax | awk '{print $1}' | head -1)

# Random line selection (seed random number generator first)
random_line=$(cat file.txt | awk 'BEGIN{srand();}{lines[NR]=$0}END{print lines[int(rand()*NR)+1];}')
```

### Using `printf` Not `echo`

**Problem**: `echo` behavior varies across shells, especially with escape sequences.

```sh
# CORRECT: printf is consistent
printf '%s\n' "$variable"
printf '0x%x\n' "$number"

# RISKY: echo may interpret escape sequences
echo "$variable"  # OK for simple cases, but prefer printf
```

## File Tests

### Standard File Tests

```sh
# Check if file exists and is a regular file
if [ -f "$path" ]; then
    # file exists
fi

# Check if directory exists
if [ -d "$path" ]; then
    # directory exists
fi

# Check if path exists (file, directory, or other)
if [ -e "$path" ]; then
    # something exists at this path
fi

# Check if file is executable
if [ -x "$path" ]; then
    # file is executable
fi
```

## Error Handling

### Exit Codes

```sh
# Success
exit 0

# Failure (use non-zero)
exit 1

# Check command success
if command; then
    # succeeded
else
    # failed
fi

# Short-circuit patterns
command || exit 1  # exit if command fails
command && next    # run next only if command succeeds
```

### Error Messages

```sh
# Send errors to stderr
echo "Error: something went wrong" >&2

# Or use printf
printf '%s\n' "Error: something went wrong" >&2
```

## Environment Variables

### Safe Variable Access

```sh
# Provide default if unset
: "${VARIABLE:=default_value}"

# Use variable with fallback
value=${VARIABLE:-default}

# Check if variable is set
if [ -n "${VARIABLE-}" ]; then
    # variable is set and non-empty
fi

if [ -z "${VARIABLE-}" ]; then
    # variable is unset or empty
fi
```

### Exporting Variables

```sh
# Export for child processes
export PATH="$PATH:/new/path"
export VARIABLE="value"

# Local variable (not exported)
local_var="value"
```

## Functions

### Defining POSIX-Compatible Functions

```sh
# CORRECT: POSIX style
my_function() {
    arg1=$1
    arg2=$2
    # function body
    return 0
}

# WRONG: bash-style (uses 'function' keyword)
function my_function() {
    # Don't do this in POSIX scripts
}
```

## Process Management

### Background Processes

```sh
# Run in background
long_command &
pid=$!

# Wait for background process
wait "$pid"
```

## Sandboxing Considerations

### Linux: bubblewrap

Tests use bubblewrap for sandboxing on Linux. Not available on macOS by default.

### macOS: sandbox-exec

macOS has `sandbox-exec`, but it's disabled by default in Wizardry tests due to compatibility issues. Enable with `WIZARDRY_ENABLE_MACOS_SANDBOX=1`.

### Disabling Sandbox

For debugging or compatibility:
```sh
export WIZARDRY_DISABLE_SANDBOX=1
```

## Common Pitfalls

### 1. Bash-isms to Avoid

```sh
# WRONG: bash arrays
array=(one two three)

# WRONG: [[ ]] test construct
if [[ "$var" == "value" ]]; then

# WRONG: $RANDOM
random=$RANDOM

# CORRECT: Use POSIX equivalents
# - Use space-separated strings or multiple variables
# - Use [ ] with = for string comparison
# - Use awk or other tools for random numbers
```

### 2. Quoting Variables

```sh
# ALWAYS quote variable expansions to prevent word splitting
if [ "$variable" = "value" ]; then
    echo "$variable"
fi

# Exception: When word splitting is intentional
for item in $space_separated_list; do
    # intentional word splitting
done
```

### 3. Portable `test` Syntax

```sh
# Use = for string comparison (not ==)
if [ "$a" = "$b" ]; then

# Use -eq for numeric comparison
if [ "$num" -eq 5 ]; then

# Multiple conditions
if [ "$a" = "x" ] && [ "$b" = "y" ]; then
if [ "$a" = "x" ] || [ "$b" = "y" ]; then
```

## Testing Practices

### Test Helpers

Use `test_common.sh` helpers:

```sh
# Run a spell
run_spell "spells/path/to/spell" arg1 arg2

# Assert success/failure
assert_success || return 1
assert_failure || return 1

# Assert output contains string
assert_output_contains "expected text" || return 1
assert_error_contains "error text" || return 1

# Create temp directory for test
tmpdir=$(make_tempdir)
```

### PATH Handling in Tests

Tests manipulate `PATH` to inject stubs:

```sh
# Create stub directory
stubdir="$tmpdir/stubs"
mkdir -p "$stubdir"

# Create stub
cat <<'STUB' >"$stubdir/pbcopy"
#!/bin/sh
cat >"${CLIPBOARD_FILE:?}"
STUB
chmod +x "$stubdir/pbcopy"

# Use stub
PATH="$stubdir:$PATH" run_spell "spells/spellcraft/copy" "$file"
```

## Summary Checklist

When writing cross-platform spells:

- [ ] Use `#!/bin/sh` and `set -eu`
- [ ] Use `command -v` not `which`
- [ ] Use `[ ]` not `[[ ]]`
- [ ] Quote all variable expansions: `"$var"`
- [ ] Use `=` not `==` for string comparisons
- [ ] Use `printf` instead of `echo` for reliable output
- [ ] Normalize paths with `sed 's|//|/|g'` when needed (especially on macOS)
- [ ] Use `pwd -P` for absolute paths, not `realpath`
- [ ] Disable `CDPATH` when using `cd` for path resolution: `CDPATH= cd`
- [ ] Provide fallbacks for platform-specific commands
- [ ] Handle `$HOME` and `~/` expansion explicitly
- [ ] Use `${TMPDIR:-/tmp}` with fallback
- [ ] Send errors to stderr: `>&2`
- [ ] Test on multiple platforms (Linux and macOS at minimum)

## References

- POSIX Shell Command Language: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
- Wizardry's `README.md` for project principles
- Wizardry's `tests/test_common.sh` for testing patterns
- Individual spell implementations in `spells/` directory
