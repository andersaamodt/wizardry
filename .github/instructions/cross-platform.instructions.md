# Cross-Platform Compatibility Instructions

applyTo: "spells/**,.tests/**"

## Supported Platforms

- Linux: Debian, Ubuntu, Arch, Fedora, NixOS
- macOS (Darwin)
- BSD variants (limited)

## Platform Detection

```sh
kernel=$(uname -s 2>/dev/null || printf 'unknown')
case $kernel in
    Darwin) platform=mac ;;
    Linux)  platform=linux ;;
    *)      platform=unknown ;;
esac
```

## Critical Patterns

### Command Availability
```sh
# CORRECT
if command -v tool >/dev/null 2>&1; then tool "$@"; fi

# WRONG
if which tool >/dev/null; then ...
if [ -x /usr/bin/tool ]; then ...
```

### Path Resolution
```sh
# Use pwd -P, not realpath
abs_path="$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")"

# Disable CDPATH
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)

# Normalize double slashes (macOS TMPDIR issue)
path=$(printf '%s' "$path" | sed 's|//|/|g')
```

### Temporary Files
```sh
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/prefix.XXXXXX")
```

### Download with Fallback
```sh
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest" || exit 1
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url" || exit 1
fi
```

### Clipboard Operations
```sh
if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$file" || exit 1
elif command -v xsel >/dev/null 2>&1; then
    xsel --clipboard --input < "$file" || exit 1
elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard < "$file" || exit 1
fi
```

## PATH Initialization

For bootstrap scripts, set baseline PATH BEFORE `set -eu`:

```sh
#!/bin/sh
baseline_path="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
case ":${PATH-}:" in
  *":/usr/bin:"*|*":/bin:"*) ;;
  *) PATH="${baseline_path}${PATH:+:}${PATH-}" ;;
esac
export PATH

set -eu
```

## Common Pitfalls

| Bash-ism | POSIX Alternative |
|----------|-------------------|
| `[[ ]]` | `[ ]` |
| `==` | `=` |
| `source` | `.` |
| `$RANDOM` | `awk 'BEGIN{srand();print int(rand()*N)}'` |
| Arrays | Space-separated strings |
| `local` | Plain variable assignment |

## Line Endings

Use `.gitattributes` to enforce LF line endings:
```
* text=auto eol=lf
*.sh text eol=lf
spells/** text eol=lf
```
