# Cross-Platform Shell Patterns

**Purpose:** Centralize all cross-platform compatibility knowledge for POSIX shell scripts across Linux, macOS, BSD, and different shells.

**AI Directive:** ALWAYS document new cross-platform patterns, platform-specific quirks, or compatibility solutions here as you discover them.

**Related Documentation:**
- **FULL_SPEC.md** - Canonical specification
- **SHELL_CODE_PATTERNS.md** - POSIX shell patterns and best practices
- **EXEMPTIONS.md** - Documented exceptions
- **LESSONS.md** - Debugging insights

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

## Native Desktop Build Tooling

- Treat native desktop compilation prerequisites as separate installables so platform-specific failures stay isolated and fixable.
- For Linux Wizardry desktop builds, the host path needs `cc`, `pkg-config`, GTK3 development headers, and WebKitGTK 4.1 development headers. Native workspace builds need GTK4 development headers.
- For macOS Wizardry desktop builds, Swift Package Manager and the Xcode Command Line Tools cover Swift, Clang, framework headers, `codesign`, `sips`, and `iconutil` on normal developer machines.
- When installing `appimagetool` as a downloaded `.AppImage`, install a small wrapper named `appimagetool` that sets `APPIMAGE_EXTRACT_AND_RUN=1` and then executes the downloaded AppImage. This avoids a hard dependency on FUSE support on target Linux machines.

## Sandbox Feature Detection

- Treat `pocket-dimension` availability as a capability probe, not just a command lookup. On Linux-class hosts such as Android/Termux, `test-magic` should run `pocket-dimension --strict --check` and fall back with a warning when `bwrap` is missing or unusable.

## Android Automation

- Prefer Termux's official `RUN_COMMAND` intent plus pushed scripts and pulled result artifacts over synthesized terminal keystrokes; use `adb`/Maestro UI input only for wake, unlock, app recovery, or other device-state normalization.
- For host-driven Termux runs, push a stable runner script and a generated payload script to shared storage, execute them in background Termux context, and wait on explicit `stdout.txt`, `stderr.txt`, and `exit-code.txt` artifacts instead of scraping screenshots or terminal transcripts.
- Treat Termux `RUN_COMMAND` as a capability probe, not a guarantee from app presence alone; if the device refuses the intent or never writes result artifacts, fall back to launching Termux and typing the pre-pushed runner script while keeping the same artifact-based result contract.
- When a Termux-side Tor onion service is publishing Android wireless debugging, resolve the adb TLS port on the phone itself with `getprop service.adb.tls.port` and forward `127.0.0.1:$PORT`; do not freeze a host-discovered Wi-Fi endpoint into the phone's Tor config.
- Keep Android transport validation (`firewalled-adb`, `firewalled-maestro`, Tor forwarding, private adb server setup) separate from workflow validation so Wizardry behavior tests can assume a working lane once the transport layer has passed.
- Planned improvement: add a single recovery flow that wakes the phone, unlocks it, dismisses stray UI state, and returns to a known-ready automation state before any higher-level Android smoke run.
- Planned improvement: standardize a prepared Android fixture with Termux, `allow-external-apps=true`, storage permission, and any recurring helper packages or scripts already installed so repeated validation does not rebuild baseline state.
- Planned improvement: add a first-class on-device smoke spell that composes transport checks, Termux script push/run/pull, and cleanup into one repeatable Android support gate.
- Planned improvement: prefer a Termux companion API or other explicit bridge only when the official `RUN_COMMAND` path cannot cover the needed workflow without UI typing.

## Package Management

- Termux does not provide Debian's `devscripts` package. Install the published
  `checkbashisms` Perl script into `$PREFIX/bin` and rewrite its interpreter to
  `#!/usr/bin/env perl` so it resolves Termux's userland Perl.
- Create static scanner configuration once per `verify-posix` run. Recreating
  and deleting it for every spell turns Termux filesystem latency into a
  multi-minute validation bottleneck.

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

**macOS bash gotcha:** macOS ships with bash 3.2 (2007) due to GPLv3 licensing. This version has parsing issues with case statements inside command substitution when patterns contain variables. Solution: Define case logic in a function outside the command substitution.

```sh
# BREAKS on macOS bash 3.2:
result=$(
  while read -r line; do
    case "$line" in
      $pattern) printf '%s\n' "$line" ;;
    esac
  done
)

# WORKS everywhere:
_matches() {
  case "$1" in
    $2) return 0 ;;
    *) return 1 ;;
  esac
}

for line in $input; do
  _matches "$line" "$pattern" && printf '%s\n' "$line"
done
```

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

- Treat Termux as a first-class Linux startup-file target: when selecting an rc file for Wizardry PATH exports, prefer `~/.bashrc` before generic shell fallbacks so Android installs land in the startup file Termux users actually inherit by default.
- When seeding a fallback baseline `PATH` on Termux, append `/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin` after the existing `/data/data/com.termux/files/usr/bin` entry instead of prepending it; Android `/bin/*` wrappers can shadow healthier Termux userland tools such as `df`.

## Terminal Size Detection

```sh
# Prefer the controlling tty directly when size is needed inside command substitution
tty_size=$(stty size </dev/tty 2>/dev/null || printf '')
set -- $tty_size
lines=$1
cols=$2
```

**Why:** Some terminals depend on environment-provided terminfo paths, and helpers like `tput` can fail once stdout is a pipe inside command substitution. Querying `/dev/tty` avoids that coupling.

## ANSI Color Detection

```sh
# Treat empty tput output as inconclusive, not as "no color"
colors=$(tput colors 2>/dev/null || printf '')
case ${colors:-} in
  0|-*) disable_palette ;;
esac
```

**Why:** A capable terminal can still render ANSI escapes even when terminfo lookup is unavailable in the current shell environment. Only an explicit zero or negative `tput colors` result should disable the palette automatically.

## String Manipulation

```sh
# Character extraction - POSIX parameter expansion (RECOMMENDED - no subprocesses)
first_char=${string%"${string#?}"}     # Extract first character  
rest=${string#?}                        # Everything after first char

# Case-preserving capitalization (recommended pattern for case conversion)
upper=$(printf '%s' "$string" | tr 'a-z' 'A-Z')
first_upper=${upper%"${upper#?}"}      # Extract first char from uppercase
tail=${string#?}                        # Extract tail from original
capitalized="${first_upper}${tail}"     # Combine: First uppercase + rest original case

# Alternative: awk substr() (works but spawns subprocess, may have issues with multi-line awk on macOS sh)
first_char=$(printf '%s' "$string" | awk '{print substr($0,1,1)}')
rest=$(printf '%s' "$string" | awk '{print substr($0,2)}')

# Alternative: sed (portable but slower, may have multi-byte char issues)
first_char=$(printf '%s' "$string" | sed 's/^\(.\).*/\1/')
rest=$(printf '%s' "$string" | sed 's/^.//')

# AVOID: dd (has buffering issues on BSD/macOS)
first=$(printf '%s' "$string" | dd bs=1 count=1 2>/dev/null)  # Fails on macOS

# WRONG (not portable - cut behavior varies on macOS):
first=$(printf '%s' "$string" | cut -c1)     # cut -c behavior varies
tail=$(printf '%s' "$string" | cut -c2-)     # may not work on macOS

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
| `cut -c` behavior | macOS | Use POSIX parameter expansion `${var%"${var#?}"}` |
| `dd` buffering | macOS/BSD | Use POSIX parameter expansion instead |
| Multi-line awk in `$()` | macOS sh | Use single-line awk or avoid awk in command substitution |
| Case in `$()` | macOS bash 3.2 | Move case statement to function outside `$()` |

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
