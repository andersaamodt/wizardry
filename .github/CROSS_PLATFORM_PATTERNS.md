# Cross-Platform Shell Patterns

**Purpose:** Centralize all cross-platform compatibility knowledge for POSIX shell scripts across Linux, macOS, BSD, and different shells.

**AI Directive:** ALWAYS document new cross-platform patterns, platform-specific quirks, or compatibility solutions here as you discover them.

## Supported Platforms

**Linux:** Debian, Ubuntu, Arch, Fedora, NixOS, Alpine  
**macOS:** 10.15+  
**BSD:** FreeBSD, OpenBSD (limited)  
**Shells:** dash, bash, zsh, sh

## Platform Detection

```sh
# Kernel
kernel=$(uname -s 2>/dev/null || printf 'unknown')
case $kernel in
    Darwin)  platform=mac ;;
    Linux)   platform=linux ;;
    FreeBSD|OpenBSD) platform=bsd ;;
esac

# Linux distro
[ -f /etc/os-release ] && . /etc/os-release && distro=$ID

# Architecture
arch=$(uname -m)
case $arch in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
esac
```

## Command Availability

```sh
# POSIX-compliant check
command -v git >/dev/null 2>&1 || die "git required"

# WRONG: Not portable
which git              # Not POSIX
[ -x /usr/bin/git ]    # Hard-coded path (breaks macOS, NixOS)
```

**Platform-specific commands:**

| Command | Linux | macOS | BSD | Alternative |
|---------|-------|-------|-----|-------------|
| `realpath` | ✓ | ✗ | ✓ | `pwd -P` |
| `readlink -f` | ✓ | ✗ | ✗ | Manual resolution |
| `stat -c` | ✓ | ✗ | ✗ | `stat -f` (BSD/macOS) |
| `sed -i` | ✓ | Needs '' | ✓ | Temp file |
| `find -executable` | ✓ | ✗ | ✗ | `find -perm /111` |

## Path Handling

```sh
# Absolute path (no realpath)
abs_path=$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)

# macOS double-slash fix (TMPDIR often ends with /)
path=$(printf '%s' "$path" | sed 's|//|/|g')
# Or: tmpfile="${TMPDIR%/}/myfile"

# Temp files/dirs
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/prefix.XXXXXX")
```

## File Operations

```sh
# Find executable (portable)
find . -type f -perm -100  # Owner executable: Linux, macOS, BSD
find . -type f -perm /111  # Any executable: Linux, macOS, BSD
# WRONG: find . -executable  # GNU-specific (not available on BSD/macOS)

# Stat (platform-dependent)
if stat -c '%Y' "$file" >/dev/null 2>&1; then
  mtime=$(stat -c '%Y' "$file")  # GNU
else
  mtime=$(stat -f '%m' "$file")  # BSD/macOS
fi

# Sed in-place (portable: use temp file)
tmpfile=$(mktemp)
sed 's/old/new/' file > "$tmpfile" && mv "$tmpfile" file
```

## Download and Clipboard

```sh
# Download (multi-tool fallback)
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$url" -o "$dest"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$dest" "$url"
fi

# Clipboard
if command -v pbcopy >/dev/null 2>&1; then
  pbcopy  # macOS
elif command -v xsel >/dev/null 2>&1; then
  xsel --clipboard --input  # Linux X11
elif command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard  # Linux X11
elif command -v wl-copy >/dev/null 2>&1; then
  wl-copy  # Linux Wayland
fi
```

## Package Management

```sh
# Multi-platform install
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update && sudo apt-get install -y "$pkg"  # Debian/Ubuntu
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y "$pkg"  # Fedora/RHEL 8+
elif command -v pacman >/dev/null 2>&1; then
  sudo pacman -S --noconfirm "$pkg"  # Arch
elif command -v brew >/dev/null 2>&1; then
  brew install "$pkg"  # macOS
fi
```

## Shell Quirks

| Feature | bash | dash | zsh | POSIX |
|---------|------|------|-----|-------|
| `[[  ]]` | ✓ | ✗ | ✓ | ✗ |
| Arrays | ✓ | ✗ | ✓ | ✗ |
| `local` | ✓ | ✗ | ✓ | ✗ |
| `$RANDOM` | ✓ | ✗ | ✓ | ✗ |

**$0 values:** Script execution = path, interactive = shell name (e.g., `bash`, `-zsh`), sourced = varies.

**zsh gotcha:** Functions in variables need `eval` in command substitution: `result=$(eval "$_cmd arg")`.

## PATH and Terminal

```sh
# Bootstrap PATH (macOS CI starts with empty PATH)
baseline_path="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
case ":${PATH-}:" in
  *":/usr/bin:"*|*":/bin:"*) ;;
  *) PATH="${baseline_path}${PATH:+:}${PATH-}" ;;
esac
export PATH

# Terminal detection
[ -t 0 ] && [ -t 1 ] && interactive=1

# Colors (if supported)
if [ -t 1 ] && [ "$TERM" != "dumb" ]; then
  red=$(tput setaf 1 2>/dev/null || printf '')
  reset=$(tput sgr0 2>/dev/null || printf '')
fi
```

## String Manipulation

```sh
# First/last character extraction (POSIX, no cut needed)
first_char=${string%"${string#?}"}     # Extract first character
rest=${string#?}                        # Everything after first char

# WRONG (not portable across all platforms):
first=$(printf '%s' "$string" | cut -c1)     # cut -c behavior varies
tail=$(printf '%s' "$string" | cut -c2-)     # may not work on some systems

# Newline detection (portable)
case "$value" in
  *"
"*)
    printf 'Value contains newlines\n' >&2
    exit 1
    ;;
esac

# WRONG (BSD wc includes leading spaces):
if [ "$(printf '%s' "$value" | wc -l)" != "0" ]; then  # Breaks on BSD/macOS
  ...
fi
```

## Common Pitfalls

| Issue | Platform | Solution |
|-------|----------|----------|
| `realpath` missing | macOS | Use `pwd -P` |
| `sed -i` needs arg | macOS | Use temp file |
| Double slashes | macOS | Normalize: `sed 's\|//\|/\|g'` |
| `find -executable` | macOS/BSD | Use `-perm -100` or `-perm /111` |
| Empty PATH | macOS CI | Set baseline first |
| SIGPIPE varies | bash/dash | bash may exit, dash ignores |
| `wc -l` output | BSD/macOS | Includes leading spaces, use `tr -d ' '` or case |
| `cut -c2-` behavior | Some systems | Use POSIX parameter expansion |

**Testing:** Test on Linux + macOS, with bash + dash, check `checkbashisms`.

## References

- POSIX.1-2017: https://pubs.opengroup.org/onlinepubs/9699919799/
- Bash Manual: https://www.gnu.org/software/bash/manual/
- Dash: http://gondor.apana.org.au/~herbert/dash/
- FreeBSD Handbook: https://docs.freebsd.org/
- macOS Command Line Tools: https://developer.apple.com/

## Document Maintenance

**ALWAYS add new cross-platform patterns here when discovered during development.**

Last updated: 2026-01-08
