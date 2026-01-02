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

**CRITICAL Gotcha:** `set -e` in a function propagates to calling shell:

```sh
#!/bin/sh
# No set -e here

my_func() {
  set -e
  return 2
}

my_func
echo "Never prints"  # Script exits!
```

**Why:** When function with `set -e` returns non-zero, it triggers errexit in parent shell.

**Solutions:**
```sh
# 1. Conditional set -e (interactive-safe)
spell_name() {
  case "$0" in
    */spell-name) set -eu ;;  # Script mode
    *) set -u ;;              # Function mode
  esac
}

# 2. Protect call site
my_func || true
if my_func; then ...; fi

# 3. set -u only (safe for all contexts)
my_func() {
  set -u  # No errexit propagation
}
```

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

# Captures exit code
output=$(command 2>&1)
exit_code=$?

# Variable function calls (zsh compatibility)
_cmd="my_function"
result=$(eval "$_cmd arg1 arg2")  # Use eval for variable calls
```

**Gotcha:** Functions in variables need `eval` in some shells (zsh):

```sh
# May fail in zsh
_func="my_func"
$_func arg              # Direct call: works

result=$($_func arg)    # In subshell: may fail

# Solution: Use eval
result=$(eval "$_func arg")
```

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

### Pipes and Subshells

**Variable assignments in pipes are lost:**

```sh
# WRONG: grep runs in subshell
echo "test" | grep "test" && found=1
echo "$found"  # Empty! Variable not set in parent

# CORRECT: Avoid pipe for state changes
if echo "test" | grep -q "test"; then
  found=1
fi
```

**Function definitions in pipes are lost:**

```sh
# WRONG: word_of_binding runs in subshell
word_of_binding spell 2>&1 | grep "Loaded"
command -v spell  # Not found! Definition lost

# CORRECT: Load first, then check
word_of_binding spell >/dev/null 2>&1
if command -v spell >/dev/null 2>&1; then
  echo "Loaded"
fi
```

### Here Documents

```sh
# Unquoted: Variable expansion
cat <<EOF
Value: $var
EOF

# Quoted: Literal (no expansion)
cat <<'EOF'
Literal: $var
EOF

# Indented (tabs only, use <<-)
cat <<-EOF
	Indented
	Text
EOF

# To variable
var=$(cat <<'EOF'
Multi
Line
EOF
)
```

### For Loops

```sh
# Iterate words
for item in one two three; do
  echo "$item"
done

# Iterate files (glob)
for file in *.sh; do
  [ -f "$file" ] || continue  # Skip if no match
  process "$file"
done

# Iterate command output (careful with spaces)
for line in $(cat file); do  # SPLITS ON SPACES
  echo "$line"
done

# Better: Use while read
while IFS= read -r line; do
  echo "$line"
done < file
```

### While Loops and IFS

```sh
# Read lines preserving whitespace
while IFS= read -r line; do
  echo "$line"
done < file

# Read fields
while IFS=: read -r user pass uid gid gecos home shell; do
  echo "User: $user"
done < /etc/passwd

# Process command output
find . -name "*.sh" | while IFS= read -r file; do
  process "$file"
done
```

### Arithmetic

```sh
# POSIX arithmetic expansion
i=$((i + 1))
result=$((5 * 3 + 2))
is_even=$(((num % 2) == 0))

# Comparison returns 1/0
result=$((5 > 3))  # 1 (true)
result=$((5 < 3))  # 0 (false)

# No floating point in POSIX sh
# Use awk or bc for decimals
result=$(awk 'BEGIN{print 5.5 * 2}')
result=$(echo "5.5 * 2" | bc)
```

### Command Checks

```sh
# Check if command exists (POSIX)
if command -v git >/dev/null 2>&1; then
  # git is available
fi

# Shorter pattern (imp style)
command -v git >/dev/null 2>&1 || die "git required"

# WRONG: Not portable
which git           # Not POSIX, varies by platform
hash git            # Sets exit code, but may print errors
type git            # Not POSIX compliant
[ -x /usr/bin/git ] # Hard-coded path
```

### Output and Quoting

```sh
# Preferred: printf (portable, predictable)
printf '%s\n' "$msg"
printf '%d\n' "$num"
printf '%s %s\n' "$arg1" "$arg2"

# Avoid: echo (varies by shell)
echo "$msg"         # May interpret backslashes
echo -n "$msg"      # -n not portable

# Always quote variables
printf '%s\n' "$var"     # CORRECT
printf '%s\n' $var       # WRONG: word splitting
```

### Globbing

```sh
# Disable globbing temporarily
set -f
pattern="*.sh"
set +f

# Check if glob matches anything
for file in *.sh; do
  [ -e "$file" ] || break  # No match
  process "$file"
done

# Recursive glob (not POSIX, use find)
# ** doesn't work in POSIX sh
find . -name "*.sh" -type f
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

| Context | $0 Value | Example |
|---------|----------|---------|
| Script execution | Script path | `/path/to/script` |
| Interactive shell | Shell name | `bash`, `-zsh`, `sh` |
| Sourced in function | Parent script | `/path/to/parent.sh` |
| sh -c 'cmd' | `sh` | Always `sh` |

**Use for context detection:**
```sh
case "$0" in
  */script-name) # Executed as script
    ;;
  *) # Sourced or function
    ;;
esac
```

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

| Code | Meaning | Use |
|------|---------|-----|
| 0 | Success | Command completed successfully |
| 1 | General error | Generic failure |
| 2 | Usage error | Invalid arguments |
| 126 | Not executable | Command cannot execute |
| 127 | Not found | Command not found |
| 130 | Ctrl-C | Interrupted (SIGINT) |
| 141 | SIGPIPE | Pipe closed early |

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

### Inline Script Error Context

```sh
# Show script name and line in errors
die() {
  printf '%s:%d: %s\n' "${0##*/}" "${LINENO-}" "$*" >&2
  exit 1
}
```

### Heredoc Functions

```sh
show_usage() {
  cat <<'USAGE'
Usage: command [options]
Description here.
USAGE
}
```

**Quote delimiter (`'USAGE'`) to prevent variable expansion.**

### Field Splitting Control

```sh
# Save and restore IFS
old_ifs=$IFS
IFS=:
read -r field1 field2
IFS=$old_ifs

# One-liner
IFS=: read -r field1 field2
```

### Safe File Removal

```sh
# Check before removing
[ -n "$tmpfile" ] && [ -f "$tmpfile" ] && rm -f "$tmpfile"

# Remove directory safely
[ -n "$tmpdir" ] && [ -d "$tmpdir" ] && rm -rf "$tmpdir"
```

### Process Substitution Alternative

```sh
# Bash: diff <(cmd1) <(cmd2)
# POSIX: Use named pipes or temp files
tmp1=$(mktemp) tmp2=$(mktemp)
cmd1 > "$tmp1"
cmd2 > "$tmp2"
diff "$tmp1" "$tmp2"
rm -f "$tmp1" "$tmp2"
```

## Wizardry-Specific Patterns

### Require Wizardry

```sh
# Before set -eu, at spell start
case "${1-}" in
--help|--usage|-h) show_usage; exit 0 ;; esac

require_wizardry || return 1  # Use return, not exit
set -eu
```

### Imp Self-Execute

```sh
#!/bin/sh
# imp-name ARG - description

set -eu  # For action imps (omit for conditional imps)

_imp_name() {
  # Implementation
}

# Self-execute pattern
case "$0" in
  */imp-name) _imp_name "$@" ;; esac
```

### Castable Spell Pattern

```sh
#!/bin/sh

spell_name() {
  case "${1-}" in
  --help|-h) spell_name_usage; return 0 ;; esac
  
  require_wizardry || return 1
  set -eu
  . env_clear
  
  # Main logic
}

# Load castable
if true; then
  _d=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
  _r=$(cd "$_d" && while [ ! -d "spells/.imps" ] && [ "$(pwd)" != "/" ]; do cd ..; done; pwd)
  _i="${WIZARDRY_DIR:-${_r}}/spells/.imps/sys"
  [ -f "$_i/castable" ] && . "$_i/castable"
fi
castable "$@"
```

## Quick Reference

### Common Mistakes

| Wrong | Right | Why |
|-------|-------|-----|
| `$var` | `"$var"` | Always quote to prevent word splitting |
| `value=$1` | `value=${1-}` | Fails with `set -u` if no arg |
| `[ $a == $b ]` | `[ "$a" = "$b" ]` | Quote vars, use `=` not `==` |
| `if [[ -f $file ]]` | `if [ -f "$file" ]` | Use `[ ]`, quote variable |
| `exit 1` in function | `return 1` | exit kills shell when sourced |
| `function foo()` | `foo()` | `function` keyword is bash-ism |
| `local var=val` | `var=val` | `local` not in POSIX |
| `echo -e "\n"` | `printf '\n'` | echo flags not portable |
| `which cmd` | `command -v cmd` | which not in POSIX |

### Testing Checklist

- [ ] No bash-isms (`checkbashisms` clean)
- [ ] All variables quoted
- [ ] Variables have defaults (`${1-}`)
- [ ] Use `return` in functions, not `exit`
- [ ] `set -eu` in correct location
- [ ] Works both sourced and executed (if applicable)
- [ ] Test in `/bin/sh`, dash, bash

## References

- POSIX.1-2017 Shell Command Language: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
- Rich's sh tricks: https://www.etalabs.net/sh_tricks.html
- Suckless sh POSIX: https://suckless.org/coding_style/

## Document Maintenance

**ALWAYS add new patterns here when discovered during development.**

Last updated: 2026-01-02
