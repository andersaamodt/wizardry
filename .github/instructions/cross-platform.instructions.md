# Cross-Platform Compatibility Instructions

applyTo: "spells/**,.tests/**"

**PRIMARY REFERENCE:** `.github/CROSS_PLATFORM_PATTERNS.md`

This file provides quick-reference cross-platform patterns. For comprehensive cross-platform compatibility knowledge, see **CROSS_PLATFORM_PATTERNS.md**.

## Documentation Hierarchy

1. **FULL_SPEC.md** - Canonical specification (what/constraints)
2. **SHELL_CODE_PATTERNS.md** - POSIX shell patterns and best practices (how/idioms)
3. **CROSS_PLATFORM_PATTERNS.md** - Cross-platform exceptions (compatibility) ← **PRIMARY SOURCE**
4. **EXEMPTIONS.md** - Documented exceptions
5. **LESSONS.md** - Debugging insights

## Supported Platforms

- Linux: Debian, Ubuntu, Arch, Fedora, NixOS, Alpine
- macOS (Darwin) 10.15+
- BSD: FreeBSD, OpenBSD (limited)

## Quick Patterns

### Command Availability

```sh
# CORRECT
command -v tool >/dev/null 2>&1 || die "tool required"

# WRONG
which tool              # Not POSIX
[ -x /usr/bin/tool ]    # Hard-coded path
```

### Path Resolution

```sh
# Use pwd -P, not realpath
abs_path="$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")"

# Disable CDPATH for predictable cd
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
```

### Common Pitfalls (Bash-isms)

| Bash-ism | POSIX Alternative |
|----------|-------------------|
| `[[ ]]` | `[ ]` |
| `==` | `=` |
| `source` | `.` |
| Arrays | Space-separated strings |
| `local` | Plain variable assignment |

## For Complete Patterns

See **`.github/CROSS_PLATFORM_PATTERNS.md`** for:
- Platform detection patterns
- Command availability fallbacks
- File operations (find, stat, sed variations)
- Download and clipboard operations
- PATH handling (especially macOS)
- Temporary file patterns
- And much more...
