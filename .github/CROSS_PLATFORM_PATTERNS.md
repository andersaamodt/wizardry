# Cross-Platform Shell Patterns

**Purpose:** Centralize all cross-platform compatibility knowledge for POSIX shell scripts across Linux, macOS, BSD, and different shells.

**AI Directive:** ALWAYS document new cross-platform patterns, platform-specific quirks, or compatibility solutions here as you discover them.

## Supported Platforms

### Primary Targets
- **Linux:** Debian, Ubuntu, Arch, Fedora, NixOS, Alpine
- **macOS (Darwin):** 10.15+
- **BSD:** FreeBSD, OpenBSD (limited)

### Shell Compatibility
- **dash** (Debian/Ubuntu `/bin/sh`)
- **bash** (most Linux, macOS default shell)
- **zsh** (macOS Catalina+ default, interactive)
- **sh** (generic POSIX shell)

## Platform Detection

### Kernel Detection

```sh
# Basic platform detection
kernel=$(uname -s 2>/dev/null || printf 'unknown')
case $kernel in
    Darwin)  platform=mac ;;
    Linux)   platform=linux ;;
    FreeBSD) platform=bsd ;;
    OpenBSD) platform=bsd ;;
    *)       platform=unknown ;;
esac
```

### Distribution Detection (Linux)

```sh
# Using /etc/os-release (systemd-based)
if [ -f /etc/os-release ]; then
  . /etc/os-release
  distro=$ID  # debian, ubuntu, arch, fedora, etc.
fi

# Fallback methods
if [ -f /etc/debian_version ]; then
  distro=debian
elif [ -f /etc/redhat-release ]; then
  distro=redhat
elif [ -f /etc/arch-release ]; then
  distro=arch
fi
```

### Architecture Detection

```sh
# Get architecture
arch=$(uname -m 2>/dev/null || printf 'unknown')
case $arch in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    armv7l) arch=armv7 ;;
    i386|i686) arch=i386 ;;
esac
```

## Command Availability

### Check Command Existence

```sh
# POSIX-compliant command check
if command -v git >/dev/null 2>&1; then
  # git is available
fi

# Shorter (imp style)
command -v git >/dev/null 2>&1 || die "git required"

# WRONG: Not portable
which git              # Not in POSIX, varies by platform
hash git               # Builtin, but may print errors  
type git               # Not POSIX-compliant
[ -x /usr/bin/git ]    # Hard-coded path (breaks on macOS, NixOS)
```

### Platform-Specific Commands

| Command | Linux | macOS | BSD | Alternative |
|---------|-------|-------|-----|-------------|
| `realpath` | ✓ | ✗ | ✓ | `pwd -P` |
| `readlink -f` | ✓ | ✗ | ✗ | Manual resolution |
| `stat -c` | ✓ | ✗ | ✗ | `stat -f` on BSD/macOS |
| `date -d` | ✓ | ✗ | ✗ | `date -j` on BSD/macOS |
| `sed -i` | ✓ | Needs '' | ✓ | Use temp file |
| `find -executable` | ✓ | ✗ | ✗ | `find -perm` |
| `xargs -r` | ✓ | ✗ | ✗ | Check input first |

## Path Handling

### Absolute Path Resolution

```sh
# POSIX-compliant (no realpath dependency)
abs_path=$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")

# Directory path
abs_dir=$(cd "$dir" && pwd -P)

# Script's own directory
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
```

**Why CDPATH= ?** Prevents `cd` from echoing directory on some systems.

**Why pwd -P ?** Resolves symlinks (same as `realpath`).

### macOS Double-Slash Issue

**Problem:** macOS `TMPDIR` often ends with `/`, causing `//` in paths:

```sh
# macOS: TMPDIR=/var/folders/xy/z123/T/
tmpfile="$TMPDIR/myfile"  # /var/folders/xy/z123/T//myfile
```

**Solution:** Normalize paths

```sh
# Remove double slashes
path=$(printf '%s' "$path" | sed 's|//|/|g')

# Or prevent at creation
tmpfile="${TMPDIR%/}/myfile"
```

### Temporary Files and Directories

```sh
# Portable temp directory
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/prefix.XXXXXX")

# Portable temp file
tmpfile=$(mktemp "${TMPDIR:-/tmp}/prefix.XXXXXX")

# Cleanup on exit
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM
```

**Note:** Some systems need at least 6 X's in template.

## File Operations

### Find Command

```sh
# Executable files (portable)
find . -type f -perm /111  # Works on Linux, macOS, BSD

# WRONG: Not portable to macOS/BSD
find . -type f -executable  # GNU-specific

# Name pattern (portable)
find . -name "*.sh" -type f

# Multiple patterns
find . \( -name "*.sh" -o -name "*.bash" \) -type f

# Exclude directories
find . -name ".git" -prune -o -type f -print
```

### Stat Command

```sh
# File modification time
# Linux (GNU stat)
mtime=$(stat -c '%Y' "$file")

# macOS/BSD
mtime=$(stat -f '%m' "$file")

# Portable solution
if stat -c '%Y' "$file" >/dev/null 2>&1; then
  # GNU stat
  mtime=$(stat -c '%Y' "$file")
else
  # BSD stat
  mtime=$(stat -f '%m' "$file")
fi
```

### Sed In-Place Editing

```sh
# Linux (GNU sed)
sed -i 's/old/new/' file

# macOS/BSD (requires backup extension)
sed -i '' 's/old/new/' file

# Portable solution: Use temp file
tmpfile=$(mktemp)
sed 's/old/new/' file > "$tmpfile"
mv "$tmpfile" file

# Or detect platform
if sed --version >/dev/null 2>&1; then
  # GNU sed
  sed -i 's/old/new/' file
else
  # BSD sed
  sed -i '' 's/old/new/' file
fi
```

### Readlink

```sh
# Resolve symlink (Linux)
target=$(readlink -f "$link")

# macOS doesn't have -f flag
# Portable alternative
target=$(cd "$(dirname "$link")" && pwd -P)/$(basename "$link")

# Or loop for multi-level symlinks
resolve_link() {
  _target=$1
  while [ -L "$_target" ]; do
    _dir=$(dirname "$_target")
    _target=$(readlink "$_target")
    case $_target in
      /*) ;;  # Absolute path
      *) _target="$_dir/$_target" ;;  # Relative path
    esac
  done
  printf '%s\n' "$_target"
}
```

## Date and Time

### Date Command

```sh
# Parse date string
# Linux (GNU date)
timestamp=$(date -d "2024-01-01" +%s)

# macOS/BSD
timestamp=$(date -j -f "%Y-%m-%d" "2024-01-01" +%s)

# Portable: Use specific format
current_date=$(date +%Y-%m-%d)
current_time=$(date +%H:%M:%S)
timestamp=$(date +%s)  # Unix timestamp (portable)
```

## Download Tools

### Multi-Tool Fallback

```sh
# Try curl, then wget, then fail
download() {
  _url=$1
  _dest=$2
  
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$_url" -o "$_dest" || return 1
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$_dest" "$_url" || return 1
  elif command -v fetch >/dev/null 2>&1; then
    # BSD fetch
    fetch -qo "$_dest" "$_url" || return 1
  else
    return 1
  fi
}
```

## Clipboard Operations

### Platform-Specific Clipboard

```sh
# Copy to clipboard (multi-platform)
copy_to_clipboard() {
  if command -v pbcopy >/dev/null 2>&1; then
    # macOS
    pbcopy
  elif command -v xsel >/dev/null 2>&1; then
    # Linux (X11) - xsel
    xsel --clipboard --input
  elif command -v xclip >/dev/null 2>&1; then
    # Linux (X11) - xclip
    xclip -selection clipboard
  elif command -v wl-copy >/dev/null 2>&1; then
    # Linux (Wayland)
    wl-copy
  else
    return 1
  fi
}

# Usage
printf '%s' "text" | copy_to_clipboard
```

## Package Management

### Multi-Platform Package Installation

```sh
# Detect and use platform package manager
pkg_install() {
  _pkg=$1
  
  if command -v apt-get >/dev/null 2>&1; then
    # Debian/Ubuntu
    sudo apt-get update && sudo apt-get install -y "$_pkg"
  elif command -v yum >/dev/null 2>&1; then
    # RHEL/CentOS/Fedora (old)
    sudo yum install -y "$_pkg"
  elif command -v dnf >/dev/null 2>&1; then
    # Fedora/RHEL 8+
    sudo dnf install -y "$_pkg"
  elif command -v pacman >/dev/null 2>&1; then
    # Arch
    sudo pacman -S --noconfirm "$_pkg"
  elif command -v brew >/dev/null 2>&1; then
    # macOS Homebrew
    brew install "$_pkg"
  elif command -v pkg >/dev/null 2>&1; then
    # FreeBSD
    sudo pkg install -y "$_pkg"
  else
    return 1
  fi
}
```

## Shell-Specific Quirks

### Bash vs Dash vs Zsh

| Feature | bash | dash | zsh | POSIX sh |
|---------|------|------|-----|----------|
| `[[  ]]` | ✓ | ✗ | ✓ | ✗ |
| Arrays | ✓ | ✗ | ✓ | ✗ |
| `local` | ✓ | ✗ | ✓ | ✗ |
| `source` | ✓ | ✗ | ✓ | ✗ (use `.`) |
| `echo -e` | ✓ | ✗ | ✓ | ✗ |
| `$RANDOM` | ✓ | ✗ | ✓ | ✗ |
| `$(< file)` | ✓ | ✗ | ✓ | ✗ |
| `{1..10}` | ✓ | ✗ | ✓ | ✗ |

### $0 in Different Shells

| Shell | Interactive | Script | Sourced |
|-------|-------------|--------|---------|
| bash | `bash` or `-bash` | `/path/to/script` | `/path/to/script` |
| zsh | `zsh` or `-zsh` | `/path/to/script` | `zsh` |
| dash | `dash` | `/path/to/script` | `dash` |

**Implication:** Use pattern matching (`*/script-name`) not exact match.

### Function Calls in Command Substitution (zsh)

**Problem:** zsh may not export functions to subshells in some configurations.

```sh
# May fail in zsh
_func="my_function"
result=$($_func arg)

# Solution: Use eval
result=$(eval "$_func arg")
```

## PATH Initialization

### Bootstrap PATH Setup

**Problem:** macOS GitHub Actions starts with empty PATH.

**Solution:** Set baseline before `set -eu`:

```sh
#!/bin/sh

# Set baseline PATH (BEFORE set -eu)
baseline_path="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
case ":${PATH-}:" in
  *":/usr/bin:"*|*":/bin:"*) 
    # PATH already has basics
    ;;
  *) 
    # PATH empty or missing basics
    PATH="${baseline_path}${PATH:+:}${PATH-}"
    ;;
esac
export PATH

set -eu
# Rest of script
```

### macOS Homebrew Paths

```sh
# Check common Homebrew locations
for brew_prefix in /opt/homebrew /usr/local; do
  if [ -d "$brew_prefix/bin" ]; then
    PATH="$brew_prefix/bin:$PATH"
    break
  fi
done
```

## Terminal Handling

### Terminal Detection

```sh
# Check if running in terminal
if [ -t 0 ] && [ -t 1 ]; then
  # stdin and stdout are TTY
  interactive=1
fi

# Check terminal type
case "$TERM" in
  dumb|unknown)
    # No color/formatting
    ;;
  *)
    # Can use colors
    ;;
esac
```

### Terminal Size

```sh
# Get terminal dimensions
if command -v tput >/dev/null 2>&1; then
  cols=$(tput cols)
  lines=$(tput lines)
fi

# Fallback
cols=${COLUMNS:-80}
lines=${LINES:-24}
```

### Colors and Formatting

```sh
# ANSI colors (if terminal supports)
if [ -t 1 ] && [ "$TERM" != "dumb" ]; then
  # Use tput (portable)
  red=$(tput setaf 1 2>/dev/null || printf '')
  green=$(tput setaf 2 2>/dev/null || printf '')
  reset=$(tput sgr0 2>/dev/null || printf '')
else
  red='' green='' reset=''
fi

printf '%s%s%s\n' "$green" "Success" "$reset"
```

## File Permissions

### Execute Bit Detection

```sh
# Check if file is executable
if [ -x "$file" ]; then
  # File is executable
fi

# Find executable files (portable)
find . -type f -perm /111

# WRONG: GNU-specific
find . -type f -executable
```

### Setting Permissions

```sh
# Make executable (portable)
chmod +x "$file"

# Octal permissions (portable)
chmod 755 "$file"

# Recursive (portable)
chmod -R 644 dir/
```

## Signal Handling

### SIGPIPE Differences

**Linux/dash:** SIGPIPE often ignored in scripts
**bash:** SIGPIPE can exit script depending on version

```sh
# Protect from SIGPIPE
large_output | head -1 || true

# Or redirect stderr
large_output 2>/dev/null | head -1
```

## User/Group Management

### User Detection

```sh
# Current user
user=$(whoami 2>/dev/null || id -un)

# User ID
uid=$(id -u)

# Check if root
if [ "$(id -u)" -eq 0 ]; then
  # Running as root
fi
```

### Home Directory

```sh
# Prefer $HOME
home=${HOME:-$(cd ~ && pwd -P)}

# Expand tilde (not automatic in POSIX)
expand_tilde() {
  _path=$1
  case $_path in
    ~/*) printf '%s%s' "$HOME" "${_path#\~}" ;;
    ~) printf '%s' "$HOME" ;;
    *) printf '%s' "$_path" ;;
  esac
}
```

## Process Management

### Background Jobs

```sh
# Start background job
long_task &
pid=$!

# Wait for specific job
wait $pid

# Wait for all background jobs
wait

# Check if process exists
if kill -0 "$pid" 2>/dev/null; then
  # Process is running
fi
```

## Wizardry-Specific Patterns

### Platform-Specific Spell Behavior

```sh
# Detect platform and adjust
case "$(uname -s)" in
  Darwin)
    clipboard_cmd=pbcopy
    open_cmd=open
    ;;
  Linux)
    clipboard_cmd=xclip
    open_cmd=xdg-open
    ;;
  *)
    die "Unsupported platform"
    ;;
esac
```

### Cross-Platform Testing

```sh
# Test on multiple shells
for shell in sh dash bash; do
  if command -v "$shell" >/dev/null 2>&1; then
    "$shell" test-script.sh || exit 1
  fi
done

# Test both execution modes
./spell-name --help      # Direct execution
. ./spell-name --help    # Sourced
```

## Common Cross-Platform Pitfalls

| Issue | Platform | Solution |
|-------|----------|----------|
| `realpath` missing | macOS | Use `pwd -P` |
| `sed -i` needs arg | macOS | Use `sed -i ''` or temp file |
| Double slashes in paths | macOS | Normalize with `sed 's\|//\|/\|g'` |
| `find -executable` | macOS/BSD | Use `find -perm /111` |
| Empty PATH | macOS CI | Set baseline path first |
| `date -d` | macOS/BSD | Use `date -j` or portable formats |
| `stat` format | All | Detect GNU vs BSD |
| Line endings | Windows | Use `.gitattributes` |
| Case-sensitive fs | macOS optional | Test both |

## Testing Checklist

- [ ] Test on Linux (Debian/Ubuntu preferred)
- [ ] Test on macOS if using file operations
- [ ] Test with both bash and dash
- [ ] Test with empty PATH (macOS CI scenario)
- [ ] Use portable commands only
- [ ] Check `checkbashisms` output
- [ ] Verify path handling with spaces
- [ ] Test in both TTY and non-TTY

## References

- POSIX.1-2017: https://pubs.opengroup.org/onlinepubs/9699919799/
- Bash Manual: https://www.gnu.org/software/bash/manual/
- Dash: http://gondor.apana.org.au/~herbert/dash/
- FreeBSD Handbook: https://docs.freebsd.org/
- macOS Command Line Tools: https://developer.apple.com/

## Document Maintenance

**ALWAYS add new cross-platform patterns here when discovered during development.**

Last updated: 2026-01-02
