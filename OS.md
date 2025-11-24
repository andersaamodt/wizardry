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

### Package Manager Detection

Different distributions use different package managers. Detect and use the appropriate one:

```sh
# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
    pkg_manager="apt-get"
    update_cmd="apt-get update"
    install_cmd="apt-get install -y"
elif command -v dnf >/dev/null 2>&1; then
    pkg_manager="dnf"
    update_cmd="dnf makecache"  # or "dnf check-update || [ $? -eq 100 ]"
    install_cmd="dnf install -y"
elif command -v pacman >/dev/null 2>&1; then
    pkg_manager="pacman"
    update_cmd="pacman -Sy"
    install_cmd="pacman -S --noconfirm"
elif command -v brew >/dev/null 2>&1; then
    pkg_manager="brew"
    update_cmd="brew update"
    install_cmd="brew install"
else
    printf '%s\n' "No supported package manager found" >&2
    exit 1
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
normalized_destination=$(printf '%s' "$destination" | sed 's|//|/|g')
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
    pbcopy < "$file" || exit 1
elif command -v xsel >/dev/null 2>&1; then
    # Linux alternative 1
    xsel --clipboard --input < "$file" || exit 1
elif command -v xclip >/dev/null 2>&1; then
    # Linux alternative 2
    xclip -selection clipboard < "$file" || exit 1
else
    printf '%s\n' "No clipboard utility available" >&2
    exit 1
fi
```

**Common platform-specific commands**:

| Purpose | macOS | Linux | Fallback |
|---------|-------|-------|----------|
| Clipboard copy | `pbcopy` | `xsel`, `xclip` | Error message |
| Clipboard paste | `pbpaste` | `xsel -o`, `xclip -o` | Error message |
| Open file/URL | `open` | `xdg-open` | Browser name |
| Package manager | `brew` | `apt-get`, `dnf`, `pacman`, `zypper` | Manual install |
| Service manager | `launchctl` | `systemctl`, `service` | Manual start |
| Process list | `ps aux` | `ps aux` (same) | `ps -ef` |
| Find process | `pgrep` | `pgrep` (same) | `ps | grep` |

**Best practices**:
1. Always provide fallbacks where possible
2. Use `command -v` to check availability
3. Add `|| exit 1` to propagate errors
4. Print helpful error messages suggesting installation
5. Document platform requirements in `--help`

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
temp_file=$(printf '%s' "$temp_file" | sed 's|//|/|g')
```

### Cleanup with Traps

Always clean up temporary files, even if the script exits early:

```sh
cleanup_temp() {
  # Clean up temporary directory
  if [ -n "${TEMP_DIR-}" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}

# Register cleanup for all exit conditions
trap 'cleanup_temp' EXIT HUP INT TERM

# Create temp directory
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/script.XXXXXX") || exit 1

# Script continues... cleanup happens automatically on exit
```

## Network Operations

### Downloading Files with Fallback

**Problem**: Not all systems have both `curl` and `wget`. Some distributions include only one.

**Solution**: Try both commands with fallback:

```sh
download_file() {
  dest=$1
  url=$2
  
  # Try curl first (more common on macOS)
  if command -v curl >/dev/null 2>&1; then
    if curl -fsSL "$url" -o "$dest"; then
      return 0
    fi
  fi
  
  # Fall back to wget (more common on Linux)
  if command -v wget >/dev/null 2>&1; then
    if wget -qO "$dest" "$url"; then
      return 0
    fi
  fi
  
  # Neither available
  printf '%s\n' "Error: Neither curl nor wget is available" >&2
  return 1
}

# Usage
if ! download_file "$dest_file" "$url"; then
  exit 1
fi
```

**curl flags explained**:
- `-f`: Fail silently on HTTP errors
- `-s`: Silent mode (no progress bar)
- `-S`: Show errors even in silent mode
- `-L`: Follow redirects
- `-o`: Output to file

**wget flags explained**:
- `-q`: Quiet mode (no output)
- `-O`: Output to file (use `-O-` for stdout)

### Checking Internet Connectivity

```sh
# Simple connectivity check
if command -v curl >/dev/null 2>&1; then
  if ! curl -fsSL --max-time 5 "https://example.com" >/dev/null 2>&1; then
    printf '%s\n' "No internet connection" >&2
    exit 1
  fi
elif command -v wget >/dev/null 2>&1; then
  if ! wget -q --timeout=5 --spider "https://example.com" 2>/dev/null; then
    printf '%s\n' "No internet connection" >&2
    exit 1
  fi
fi
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
1. `~/.bashrc`
2. `~/.bash_profile`
3. `~/.profile`

**Note:** Wizardry uses shell rc files on NixOS instead of modifying `configuration.nix` or `home.nix`. This provides a simpler, safer installation that doesn't require understanding NixOS's declarative configuration system. Users who prefer to manage their PATH through NixOS configuration files can do so manually.

## Text Processing

### Using `sed` for Path Manipulation

```sh
# Normalize double slashes
path=$(printf '%s' "$path" | sed 's|//|/|g')

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

## Interactive Input and Prompts

### Detecting Interactive Terminal

**Problem**: Scripts need to know if they're running interactively or in a pipeline/CI environment.

**Solution**: Use `test -t` to check if stdin is a terminal:

```sh
if [ -t 0 ]; then
  # stdin is a terminal - interactive mode
  printf '%s' "Enter value: " >&2
  read -r user_input
else
  # stdin is NOT a terminal - use default or fail
  printf '%s\n' "No interactive input; using default" >&2
  user_input="$default_value"
fi
```

### Safe Read with Prompts

```sh
# Prompt for user input
prompt_user() {
  prompt_text=$1
  default_value=$2
  
  if [ -t 0 ]; then
    # Interactive: show prompt on stderr so it's visible even if stdout captured
    printf '%s: [%s] ' "$prompt_text" "$default_value" >&2
    IFS= read -r input
    if [ -z "$input" ]; then
      printf '%s\n' "$default_value"
    else
      printf '%s\n' "$input"
    fi
  else
    # Non-interactive: use default
    printf '%s\n' "$default_value"
  fi
}

# Usage
install_dir=$(prompt_user "Install directory?" "$HOME/.local")
```

### Yes/No Prompts

```sh
ask_yes_no() {
  question=$1
  default=${2:-no}  # Default to "no" if not specified
  
  if [ ! -t 0 ]; then
    # Non-interactive: use default
    case $default in
      yes|y|Y) return 0 ;;
      *) return 1 ;;
    esac
  fi
  
  printf '%s [y/N] ' "$question" >&2
  read -r answer
  
  case $answer in
    y|Y|yes|Yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# Usage
if ask_yes_no "Proceed with installation?" yes; then
  echo "Installing..."
else
  echo "Cancelled"
  exit 1
fi
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

## Critical Environment Setup

### PATH Initialization Order

**Critical Issue**: On some CI environments (particularly macOS GitHub Actions), `PATH` may be completely empty or missing essential directories. If you use `set -eu` before establishing a baseline `PATH`, the script will fail immediately when trying to use basic commands like `dirname`, `cd`, or `pwd`.

**Solution**: Always initialize `PATH` BEFORE `set -eu`:

```sh
#!/bin/sh
# CRITICAL: Set baseline PATH BEFORE set -eu
baseline_path="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
case ":${PATH-}:" in
  *":/usr/bin:"*|*":/bin:"*) 
    # Already has at least one standard directory
    ;;
  *) 
    # PATH is empty or missing standard directories
    PATH="${baseline_path}${PATH:+:}${PATH-}"
    ;;
esac
export PATH

# NOW it's safe to enable strict error checking
set -eu
```

**When this matters**:
- CI/CD environments that start with minimal PATH
- Bootstrap scripts that run before the environment is fully set up
- Test harnesses that need to work in isolated environments
- Any script that might run in an empty environment

### Preserving System PATH in Tests

When tests intentionally restrict `PATH` to test fallback behavior, internal test helpers may fail to find essential utilities. Save the system PATH for internal use:

```sh
# Save full system PATH before tests modify it
WIZARDRY_SYSTEM_PATH="$PATH"
export WIZARDRY_SYSTEM_PATH

# Later, test helpers can use it internally
run_cmd() {
  # Use saved system PATH for internal operations
  PATH="$WIZARDRY_SYSTEM_PATH" mktemp -d /tmp/test.XXXXXX
  # ... rest of function
}
```

## Line Endings and Git Configuration

### Cross-Platform Line Ending Issues

**Problem**: Windows uses CRLF (`\r\n`) while Unix/Linux/macOS use LF (`\n`). Mixed line endings can cause scripts to fail with cryptic errors like "command not found" or "unexpected end of file".

**Solution**: Use `.gitattributes` to enforce consistent line endings:

```gitattributes
# .gitattributes
# Enforce LF line endings for all text files
* text=auto eol=lf

# Shell scripts must have LF
*.sh text eol=lf
spells/** text eol=lf
install text eol=lf

# Explicitly declare files as text
*.md text eol=lf
*.txt text eol=lf
*.json text eol=lf
*.yaml text eol=lf
*.yml text eol=lf
```

This ensures all developers and CI systems check out files with the correct line endings regardless of their platform.

## Shell Script Portability Beyond POSIX

### Avoiding Heredocs in Different Shells

**Problem**: Heredoc syntax, especially with quotes and variables, can behave differently across shell implementations (bash, dash, macOS sh). Certain quote combinations can cause "unexpected EOF" errors on some platforms.

**Example of Problematic Code**:
```sh
# This can fail on some shells (macOS sh, dash)
message=$(cat <<'HEREDOC'
Line one
Line two with ${variable}
HEREDOC
)
```

**Solutions**:

1. **Use case statements instead**:
```sh
# Instead of heredoc with multiple options
case $selection in
  1) message="Option one" ;;
  2) message="Option two" ;;
  3) message="Option three" ;;
esac
```

2. **Use printf for multi-line strings**:
```sh
# Instead of heredoc
printf '%s\n' \
  "Line one" \
  "Line two" \
  "Line three"
```

3. **Use modulo arithmetic for selections**:
```sh
# Select message based on count
index=$((count % 3))
case $index in
  0) message="First message" ;;
  1) message="Second message" ;;
  2) message="Third message" ;;
esac
```

### Error Propagation in Pipelines

**Problem**: Shell pipelines and command substitutions can hide errors if not properly handled. A failed command might not cause the script to exit even with `set -e`.

**Solution**: Explicitly check and propagate exit codes:

```sh
# WRONG: exit code not checked
pbcopy < "$file"

# CORRECT: ensure non-zero exit propagates
pbcopy < "$file" || exit 1

# CORRECT: check command substitution results
if output=$(command 2>&1); then
  echo "Success: $output"
else
  echo "Failed" >&2
  exit 1
fi
```

**In clipboard operations**:
```sh
# Ensure clipboard commands fail properly
if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$file" || exit 1
elif command -v xsel >/dev/null 2>&1; then
    xsel --clipboard --input < "$file" || exit 1
else
    printf '%s\n' "No clipboard utility available" >&2
    exit 1
fi
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

### PATH Handling in Tests: Complete Isolation Strategy

**Problem**: On macOS, system commands like `pbcopy` may interfere with tests designed to verify fallback behavior. Setting `PATH="$stubdir:$PATH"` still allows the test to find system commands.

**Solution**: Use complete PATH isolation with symlinks for essential utilities:

```sh
# Create isolated stub directory
stubdir="$tmpdir/stubs"
mkdir -p "$stubdir"

# Create test-specific stub
cat <<'STUB' >"$stubdir/xsel"
#!/bin/sh
cat >"${CLIPBOARD_FILE:?}"
STUB
chmod +x "$stubdir/xsel"

# Create symlinks to essential POSIX utilities
# This allows the spell and test harness to work without finding system commands
for util in sh sed cat printf test env basename dirname; do
  util_path=$(command -v "$util" 2>/dev/null) || continue
  if [ -x "$util_path" ]; then
    ln -sf "$util_path" "$stubdir/$util"
  fi
done

# Use completely restricted PATH (no system paths)
PATH="$stubdir" run_spell "spells/spellcraft/copy" "$file"
```

**Key principles**:
1. Use `PATH="$stubdir"` not `PATH="$stubdir:$PATH"` for complete isolation
2. Symlink essential utilities (`sh`, `sed`, `cat`, `printf`, `test`, `env`, `basename`, `dirname`)
3. Omit any commands you want to test fallback behavior for (e.g., `pbcopy`, `xsel`, `xclip`)
4. Different platforms have utilities in different locations (`/bin` vs `/usr/bin`)

### Platform Differences in Standard Utility Locations

**Problem**: On Linux, many utilities are in `/usr/bin` (e.g., `/usr/bin/cat`), but on macOS, essential utilities like `cat` are in `/bin` (e.g., `/bin/cat`). Tests that set `PATH="/usr/bin"` will fail on macOS with "command not found" errors.

**Solution**: Include both `/bin` and `/usr/bin` when setting PATH in tests:

```sh
# WRONG: Only works on Linux
PATH="/usr/bin" run_spell "spells/system/update-all"

# CORRECT: Works on Linux and macOS
PATH="/bin:/usr/bin" run_spell "spells/system/update-all"

# EVEN BETTER: Use stub directory with symlinks
PATH="$stubdir:/bin:/usr/bin" run_spell "spells/system/update-all"
```

**Common utility locations**:
- **Linux**: Most in `/usr/bin`, some in `/bin`
- **macOS**: Core utilities in `/bin`, others in `/usr/bin`
- **Both need**: When restricting PATH, include both directories

### Path Normalization in Test Assertions

**Problem**: Tests compare paths from spell output against expected paths, but macOS's `TMPDIR` trailing slash and symlink resolution can cause mismatches.

**Solution**: Normalize paths in test assertions the same way spells normalize them:

```sh
# Create test directory
workdir=$(make_tempdir)  # Already normalized by make_tempdir

# Resolve symlinks as the spell does
workdir_resolved=$(cd "$workdir" && pwd -P | sed 's|//|/|g')

# Use resolved path in assertions
run_spell_in_dir "$workdir" "spells/translocation/mark-location"
assert_output_contains "Location marked at $workdir_resolved"

# For marker files, write resolved paths
printf '%s\n' "$destination_resolved" >"$marker_file"
```

**When to normalize in tests**:
1. After creating temp directories (done automatically by `make_tempdir`)
2. Before comparing against spell output that uses `pwd -P`
3. When writing paths to files that will be compared later
4. When asserting output contains a path

### Testing Marker and State Files

**Problem**: Spells that store paths in marker files (like `mark-location` and `jump-to-marker`) need to store and compare canonicalized paths. Tests must account for this.

**Solution**: Always resolve and normalize paths before writing to marker files:

```sh
# Write resolved path to marker file
destination_resolved=$(cd "$destination" && pwd -P | sed 's|//|/|g')
printf '%s\n' "$destination_resolved" >"$marker_file"

# Test will now match spell's comparison
run_spell "spells/translocation/jump-to-marker" "$marker_file"
assert_output_contains "You land in $destination_resolved"
```

## Summary Checklist

When writing cross-platform spells:

- [ ] Set baseline `PATH` BEFORE `set -eu` in bootstrap scripts and test harnesses
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
- [ ] Add `|| exit 1` to critical commands to propagate errors
- [ ] Handle `$HOME` and `~/` expansion explicitly
- [ ] Use `${TMPDIR:-/tmp}` with fallback
- [ ] Send errors to stderr: `>&2`
- [ ] Avoid heredocs with complex quoting; use case statements or printf
- [ ] Use `.gitattributes` to enforce LF line endings
- [ ] Include both `/bin` and `/usr/bin` when setting PATH in tests
- [ ] Resolve and normalize paths in test assertions to match spell behavior
- [ ] Create symlinks for essential utilities in test stub directories
- [ ] Test on multiple platforms (Linux and macOS at minimum)

## Cross-Platform Testing Strategy

### Test Environment Requirements

1. **PATH Isolation**: Tests should be able to run with minimal PATH
2. **Temp Directory**: Use normalized temp directories from `make_tempdir`
3. **Platform Detection**: Tests should work on both Linux and macOS
4. **Stub Creation**: Use symlinks for essential utilities, stubs for tested commands
5. **Path Normalization**: Always normalize paths before assertions

### Example: Comprehensive Cross-Platform Test

```sh
#!/bin/sh
# Example test demonstrating cross-platform best practices

. "$(dirname "$0")/../test_common.sh"

test_cross_platform_spell() {
  # Create isolated test environment
  tmpdir=$(make_tempdir)  # Already normalized
  
  # Create stub directory
  stubdir="$tmpdir/stubs"
  mkdir -p "$stubdir"
  
  # Create test stub
  cat <<'STUB' >"$stubdir/testcmd"
#!/bin/sh
printf 'success\n'
STUB
  chmod +x "$stubdir/testcmd"
  
  # Symlink essential utilities for both Linux and macOS
  for util in sh sed cat printf test env basename dirname; do
    util_path=$(command -v "$util" 2>/dev/null) || continue
    if [ -x "$util_path" ]; then
      ln -sf "$util_path" "$stubdir/$util"
    fi
  done
  
  # Run spell with isolated PATH
  PATH="$stubdir:/bin:/usr/bin" run_spell "spells/example/spell"
  assert_success || return 1
  
  # Normalize paths before assertion (for macOS compatibility)
  expected_path=$(printf '%s' "$tmpdir/output" | sed 's|//|/|g')
  assert_output_contains "$expected_path" || return 1
}

run_test_case "spell works cross-platform" test_cross_platform_spell
```

## References

- POSIX Shell Command Language: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
- Wizardry's `README.md` for project principles
- Wizardry's `tests/test_common.sh` for testing patterns
- Individual spell implementations in `spells/` directory
