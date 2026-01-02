# POSIX Shell Code Patterns

**Purpose:** Centralize all obscure POSIX shell knowledge, quirks, and proven patterns. This is the authoritative reference for shell code patterns in wizardry.

**AI Directive:** ALWAYS document new shell patterns, quirks, or POSIX discoveries here as you encounter them during development.

## Critical POSIX sh Patterns

### Variable Handling

```sh
# Default values
var=${1-}              # Empty string if unset (most common)
var=${1:-default}      # "default" if unset OR empty
: "${VAR:=default}"    # Sets VAR to "default" if unset/empty (persists)

# Required with set -u
value=${required_var?Error: required_var not set}

# String manipulation (POSIX only)
${var#pattern}         # Remove shortest match from start
${var##pattern}        # Remove longest match from start
${var%pattern}         # Remove shortest match from end
${var%%pattern}        # Remove longest match from end

# Length
${#var}                # String length
```

### Function Naming and Hyphens

**CRITICAL:** POSIX sh doesn't support hyphens in function names.

```sh
# CORRECT: Underscore in function name
require_wizardry() { ... }
env_or() { ... }

# WRONG: Hyphen causes parse errors
require-wizardry() { ... }  # Syntax error
```

**Wizardry solution:** Imps define underscore functions, glosses provide hyphenated CLI commands.

### set -eu Behavior

**set -e (errexit):** Exit on command failure, UNLESS:
1. Command is in conditional (`if`, `while`, `until`)
2. Command is part of AND-OR list (`&&`, `||`)
3. Command return is inverted with `!`

**set -u (nounset):** Error on unset variable expansion

**CRITICAL:** `set -e` in function propagates to calling shell (exits parent even without `set -e`).

**Solutions:**
```sh
# Conditional set -e (interactive-safe)
spell_name() {
  case "$0" in
    */spell-name) set -eu ;;  # Script: strict mode
    *) set -u ;;              # Sourced: only nounset
  esac
}

# Protect call site
my_func || true
if my_func; then ...; fi
```

**Note:** `set -u` alone is safe (doesn't propagate exit).

### Return vs Exit

| Context | Use | Effect |
|---------|-----|--------|
| Function body | `return N` | Exits function only |
| Top level | `exit N` | Exits script/shell |
| Sourced function | `return N` | Safe |
| Sourced function | `exit N` | KILLS SHELL |

**Rule:** Always use `return` in functions that might be sourced.

### Case Statements

```sh
# Multiple patterns
case "$var" in
  pattern1|pattern2) ... ;;
  *) ... ;;  # Default
esac

# Glob patterns
case "$file" in
  *.sh|*.bash) ... ;;
  */bin/*) ... ;;
esac

# Command-line argument handling
case "${1-}" in
  --help|-h) show_help; return 0 ;;
  --*) die "unknown option: $1" ;;
esac
```

### Self-Execute Pattern

**Makes script work both sourced and executed:**

```sh
#!/bin/sh

spell_name() {
  # Function body
}

# Self-execute when run directly
case "$0" in
  */spell-name) spell_name "$@" ;; esac
```

**Why:** `$0` is script path when executed, shell name when sourced. Pattern `*/spell-name` matches only execution.

### Command Substitution

```sh
# Preferred (nestable)
result=$(command arg)

# Variable function calls (zsh compatibility)
_cmd="my_function"
result=$(eval "$_cmd arg1 arg2")  # Use eval in subshells

# Direct calls work without eval
result=$(my_function arg)  # OK
$_cmd arg                  # OK (not in subshell)
```

**Gotcha:** Functions stored in variables need `eval` in command substitution (zsh).

### Test Operators

```sh
# File tests
[ -e path ]    # Exists (any type)
[ -f path ]    # Regular file
[ -d path ]    # Directory
[ -x path ]    # Executable
[ -r path ]    # Readable
[ -w path ]    # Writable
[ -s path ]    # Non-empty file

# String tests
[ -z "$s" ]    # Empty string
[ -n "$s" ]    # Non-empty string
[ "$a" = "$b" ]   # Equal (use =, not ==)
[ "$a" != "$b" ]  # Not equal

# Integer tests (limited in POSIX)
[ "$a" -eq "$b" ]  # Equal
[ "$a" -ne "$b" ]  # Not equal
[ "$a" -lt "$b" ]  # Less than
[ "$a" -gt "$b" ]  # Greater than
[ "$a" -le "$b" ]  # Less or equal
[ "$a" -ge "$b" ]  # Greater or equal

# Logical operators
[ cond1 ] && [ cond2 ]   # AND (preferred)
[ cond1 ] || [ cond2 ]   # OR (preferred)
[ cond1 -a cond2 ]       # AND (avoid, deprecated)
[ cond1 -o cond2 ]       # OR (avoid, deprecated)
[ ! cond ]               # NOT
```

**CRITICAL:** Always use `[ ]`, never `[[ ]]` (bash-ism). Use `=` not `==` for string comparison.

### Pipes and Exit Codes

**Exit code lost in pipes:**
```sh
my_func 2>&1 | head -1
echo $?  # Shows 0 (from head), not my_func's code

# Fix: Capture before pipe
output=$(my_func 2>&1)
exit_code=$?
```

**Variables/functions lost in pipes (run in subshells):**
```sh
# WRONG: Variable not set in parent
echo "test" | grep "test" && found=1

# WRONG: Function not loaded in parent
word_of_binding spell 2>&1 | grep "Loaded"

# CORRECT: Don't pipe state changes
word_of_binding spell >/dev/null 2>&1
command -v spell >/dev/null 2>&1 && echo "Loaded"
```

### Here Documents

```sh
# Variable expansion
cat <<EOF
Value: $var
EOF

# Literal (quote delimiter)
cat <<'EOF'
Literal: $var
EOF

# Indented (tabs only)
cat <<-EOF
	Text
EOF
```

### For Loops

```sh
# Iterate words
for item in one two three; do echo "$item"; done

# Iterate files (check for no-match)
for file in *.sh; do
  [ -f "$file" ] || continue
  process "$file"
done

# Avoid: for line in $(cat file)  # Splits on ALL whitespace
# Use: while read instead
```

### While Loops and IFS

```sh
# Read lines preserving whitespace
while IFS= read -r line; do echo "$line"; done < file

# Read fields (colon-separated)
while IFS=: read -r user pass uid gid; do
  echo "User: $user"
done < /etc/passwd
```

### Arithmetic

```sh
# POSIX arithmetic
i=$((i + 1))
result=$((5 * 3 + 2))
is_even=$(((num % 2) == 0))  # Returns 1 (true) or 0 (false)

# No floating point - use awk/bc
result=$(awk 'BEGIN{print 5.5 * 2}')
```

### Command Checks

```sh
# POSIX-compliant
command -v git >/dev/null 2>&1 || die "git required"

# WRONG: Not portable
which git              # Not POSIX
hash git               # May print errors
[ -x /usr/bin/git ]    # Hard-coded path
```

### Output and Quoting

```sh
# Use printf (portable)
printf '%s\n' "$msg"

# Avoid echo (varies by shell, -n not portable)

# Always quote variables
printf '%s\n' "$var"     # CORRECT
printf '%s\n' $var       # WRONG: word splitting
```

### Globbing

```sh
# Disable temporarily
set -f; pattern="*.sh"; set +f

# Check for matches
for file in *.sh; do
  [ -e "$file" ] || break
  process "$file"
done

# Recursive: use find (** not POSIX)
```

### Signal Handling

```sh
# Trap signals for cleanup
cleanup() {
  rm -f "$tmpfile"
}
trap cleanup EXIT HUP INT TERM

# Clear all traps
trap - EXIT HUP INT TERM

# Ignore signal
trap '' HUP
```

### Path Manipulation

```sh
# Basename and dirname (external commands)
name=$(basename "$path")
dir=$(dirname "$path")

# POSIX parameter expansion (inline)
name=${path##*/}    # Basename
dir=${path%/*}      # Dirname

# Disable CDPATH (avoids cd echoing path)
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)

# Resolve symlinks
real_path=$(cd "$(dirname "$path")" && pwd -P)/$(basename "$path")
```

### $0 Behavior

| Context | $0 Value |
|---------|----------|
| Script execution | `/path/to/script` |
| Interactive shell | `bash`, `-zsh`, `sh` |
| Sourced function | Parent script or shell name |

**Context detection:**
```sh
case "$0" in
  */script-name) # Executed
    ;;
  *) # Sourced
    ;;
esac
```

**Gotcha:** Login shells prefix with `-` (e.g., `-bash`, `-zsh`).

### POSIX vs Bash-isms

| Bash-ism | POSIX Alternative | Notes |
|----------|-------------------|-------|
| `[[ ]]` | `[ ]` | Use single brackets |
| `==` | `=` | In `[ ]` tests |
| `source` | `.` | Dot command |
| `$RANDOM` | `awk 'BEGIN{srand();print int(rand()*N)}'` | No random in POSIX |
| `local var` | `var=...` | No local, use naming convention |
| `${arr[@]}` | Space-separated string | No arrays |
| `function foo()` | `foo()` | Just use `foo()` |
| `echo -e` | `printf` | echo flags not portable |
| `&>file` | `>file 2>&1` | Redirect both streams |
| `<<<` | here-doc or pipe | Here-strings not POSIX |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Usage error |
| 126 | Not executable |
| 127 | Not found |
| 130 | Ctrl-C (SIGINT) |
| 141 | SIGPIPE |

**Note:** SIGPIPE handling varies (bash may exit, dash ignores in scripts).

### Subshell vs Command Substitution vs Background

```sh
# Subshell: Runs in new process, changes lost
( cd /tmp && ls )
pwd  # Still in original directory

# Command substitution: Captures output
result=$(cd /tmp && ls)

# Background: Runs async
long_task &
pid=$!  # Capture PID
wait $pid  # Wait for completion
```

## Advanced Patterns

```sh
# Error with context
die() {
  printf '%s:%d: %s\n' "${0##*/}" "${LINENO-}" "$*" >&2
  exit 1
}

# Heredoc function (quote delimiter for literal)
show_usage() { cat <<'USAGE'
Usage text
USAGE
}

# IFS control
old_ifs=$IFS; IFS=:; read -r f1 f2; IFS=$old_ifs

# Safe removal
[ -n "$tmpfile" ] && [ -f "$tmpfile" ] && rm -f "$tmpfile"
```

## Wizardry Patterns

```sh
# Require wizardry (before set -eu)
case "${1-}" in
--help|-h) show_usage; exit 0 ;; esac
require_wizardry || return 1
set -eu

# Imp self-execute
_imp_name() { ...; }
case "$0" in */imp-name) _imp_name "$@" ;; esac

# Castable spell (sourced + executed)
spell_name() { ...; }
# Load castable, then: castable "$@"
```

## Quick Reference

| Wrong | Right | Why |
|-------|-------|-----|
| `$var` | `"$var"` | Quote to prevent word splitting |
| `value=$1` | `value=${1-}` | Fails with `set -u` if no arg |
| `[ $a == $b ]` | `[ "$a" = "$b" ]` | Quote vars, use `=` not `==` |
| `exit 1` in func | `return 1` | exit kills shell when sourced |
| `echo -e` | `printf` | echo flags not portable |
| `which cmd` | `command -v cmd` | which not in POSIX |

**Testing:** Check with `checkbashisms`, test in `/bin/sh`, dash, bash.

## References

- POSIX.1-2017 Shell Command Language: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
- Rich's sh tricks: https://www.etalabs.net/sh_tricks.html
- Suckless sh POSIX: https://suckless.org/coding_style/

## Document Maintenance

**ALWAYS add new patterns here when discovered during development.**

Last updated: 2026-01-02
