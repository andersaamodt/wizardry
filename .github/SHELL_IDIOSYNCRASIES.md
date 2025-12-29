# Shell Idiosyncrasies and Gotchas in POSIX sh

This document captures the subtle and non-obvious behavior of POSIX sh that has caused issues in wizardry development.

## Issue 1: `set -e` Propagates Function Return Codes to Calling Shell

### The Problem

When a function contains `set -e` (errexit) and returns a non-zero exit code, it can cause the **calling shell** to exit, even if the calling shell doesn't have `set -e`.

### Reproduction

```sh
#!/bin/sh
# This script does NOT have set -e

my_func() {
  set -e  # Function enables errexit
  return 2
}

my_func
echo "This will NEVER print"
```

**Result**: The script exits with code 2 after `my_func` returns. The echo never executes.

### Why This Happens

From POSIX specification: When `set -e` is active and a command returns non-zero, the shell exits UNLESS:
1. The command is part of a conditional (`if`, `while`, `until`)
2. The command is part of an AND-OR list (`&&` or `||`)
3. The command's return value is inverted with `!`

When a function with `set -e` returns non-zero, that return propagates as a "command failure" to the calling context, triggering errexit behavior even in the parent shell.

### Solution

**For interactive functions** (functions that might be called from interactive shells):
```sh
my_func() {
  # Use conditional set -e based on execution context
  case "$0" in
    */my-script) set -eu ;;  # Script mode
    *) set -u ;;             # Function mode (no errexit)
  esac
  
  # Function body
}
```

**Workaround in caller** (when you can't control the function):
```sh
my_func || true  # Prevents exit
# or
if my_func; then
  # handle success
fi
```

### Related POSIX Behavior

This is documented in POSIX.1-2017, Shell Command Language, Section 2.8.1:
> "If the exit status of a command is tested, that command shall be exempt from the -e option."

But when a function returns without being tested, it's NOT exempt.

## Issue 2: `set -u` Does NOT Cause Shell Exit on Function Return

### The Finding

Unlike `set -e`, the `set -u` (nounset) flag does NOT cause the calling shell to exit when a function returns non-zero.

### Test

```sh
#!/bin/sh

my_func() {
  set -u
  return 2
}

my_func
echo "This WILL print"  # Works fine
echo "Exit code: $?"   # Shows 2
```

**Result**: Script continues normally. The function's return code is captured, and execution continues.

### Implication

Using `set -u` alone in functions is safe for interactive use. It won't brick the terminal.

## Issue 3: Command Substitution Exit Codes Can Be Misleading

### The Problem

When piping command substitution output, the exit code reflects the **pipe status**, not the command's exit code.

### Example

```sh
my_func() {
  return 2
}

# Exit code is lost due to pipe
my_func 2>&1 | head -1
echo "Exit code: $?"  # Shows 0 (from head), not 2 (from my_func)

# Exit code preserved without pipe
my_func
echo "Exit code: $?"  # Shows 2
```

### Solution

Capture exit code before piping:
```sh
my_func 2>&1
exit_code=$?
echo "Exit code: $exit_code"  # Shows actual 2
```

Or use variables:
```sh
output=$(my_func 2>&1)
exit_code=$?
```

## Issue 4: Subshells in Pipes Lose Variable Assignments

### The Problem

Commands in a pipeline run in subshells, so variable assignments are lost.

### Example

```sh
# WRONG: grep runs in subshell, can't set variables
word_of_binding my-spell 2>&1 | grep "Loaded" && loaded=1

# After the pipe, the function wasn't actually loaded in parent shell!
command -v my_spell  # Not found!
```

### Explanation

In `cmd1 | cmd2`, both commands may run in subshells (implementation-dependent). Any functions defined, variables set, or state changes in those subshells are lost after the pipe completes.

### Solution

```sh
# CORRECT: Load first, then check output separately
word_of_binding my-spell >/dev/null 2>&1
if command -v my_spell >/dev/null 2>&1; then
  echo "Loaded successfully"
fi
```

## Issue 5: `$0` Behavior Varies by Execution Context

### Values of `$0`

| Context | Value of `$0` | Example |
|---------|---------------|---------|
| Direct script execution | `/path/to/script` | `./spells/system/banish` |
| Sourced in interactive shell | Shell name | `zsh`, `-bash`, `sh` |
| Function called from script | Parent script path | `/path/to/parent.sh` |
| sh -c 'command' | `sh` | Always `sh` |

### Using `$0` for Context Detection

```sh
case "$0" in
  */script-name)
    # Executed as script
    set -eu
    ;;
  *)
    # Sourced or called as function
    set -u
    ;;
esac
```

### Gotcha: Interactive Shell Variations

- bash: `$0` is `-bash` (with dash) for login shells
- zsh: `$0` is `zsh` normally, `-zsh` for login shells
- dash: `$0` is `dash`

Pattern `*/script-name` reliably matches only direct execution.

## Issue 6: Functions in Command Substitution (zsh vs sh)

### The Problem

In some shells (particularly zsh with certain options), functions may not be available in subshells created by command substitution `$(...)`.

### Investigation

Testing shows this works in POSIX sh/dash/bash:
```sh
my_func() { echo "test"; }
result=$(my_func)  # Works fine
```

However, in zsh with specific configurations or when functions are loaded via complex sourcing mechanisms, this can fail.

### Solution: Use `eval` for Variable Function Calls

When calling a function stored in a variable within command substitution:

```sh
# PROBLEM: May fail in zsh
_cmd="my_function"
result=$($_cmd arg1 arg2)

# SOLUTION: Use eval
_cmd="my_function"
result=$(eval "$_cmd arg1 arg2")
```

### Why This Works

`eval` explicitly evaluates the command string in the current shell context before the subshell is created, ensuring the function reference is properly resolved.

### When NOT Needed

```sh
# Direct function name (no variable): eval not needed
result=$(my_function arg1 arg2)

# Function called outside command substitution: eval not needed
$_cmd arg1 arg2
```

## Issue 7: SIGPIPE Handling in Pipelines

### Expected Behavior

When you pipe to `head` or similar commands that close their input early:

```sh
large_output() {
  for i in 1 2 3 4 5 6 7 8 9 10; do
    echo "Line $i"
  done
}

large_output | head -1  # Expect SIGPIPE on line 2
```

### POSIX sh vs bash

- **POSIX sh/dash**: SIGPIPE is ignored by default in non-interactive scripts
- **bash**: SIGPIPE can cause script exit depending on version and flags

### Impact on Functions with `set -e`

If `set -e` is active and a command receives SIGPIPE (exit code 141), the shell may exit.

### Solution

For commands that might be piped:
```sh
large_output 2>/dev/null || true  # Suppress SIGPIPE exit
```

## Issue 8: Return vs Exit in Functions

### The Rule

| Context | Use | Behavior |
|---------|-----|----------|
| Inside function | `return N` | Exits function with code N |
| Outside function (top level) | `exit N` | Exits entire script/shell |
| Function that might be sourced | `return N` | Safe - won't kill shell |
| Function that might be sourced | `exit N` | DANGEROUS - kills shell! |

### Why This Matters

When a spell can be both executed AND sourced (as a function):

```sh
# WRONG: Will kill interactive shell
my_spell() {
  if [ error ]; then
    exit 1  # Kills the user's terminal!
  fi
}

# CORRECT: Returns error code
my_spell() {
  if [ error ]; then
    return 1  # Safe
  fi
}
```

## Best Practices Summary

1. **For spells used interactively**: Use conditional `set -e`
   ```sh
   case "$0" in */spell-name) set -eu ;; *) set -u ;; esac
   ```

2. **For variable function calls in command substitution**: Use `eval`
   ```sh
   result=$(eval "$_cmd args")
   ```

3. **Always use `return` in functions**, never `exit` (unless certain it's script-only)

4. **Don't pipe word-of-binding or similar**: It runs in subshell, loses definitions

5. **Test both execution contexts**: Script mode and function mode

6. **Document shell-specific workarounds**: Note when something is for zsh, bash, etc.

## Testing Methodology

When testing shell behavior:

```sh
# Test basic behavior
sh test.sh

# Test with different shells
dash test.sh
bash test.sh
zsh test.sh  # If available

# Test both contexts
./spell-name  # Direct execution
sh -c '. ./spell-name; spell_name'  # As function
```

## References

- POSIX.1-2017 Shell Command Language: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
- Bash Manual: https://www.gnu.org/software/bash/manual/
- Dash Documentation: http://gondor.apana.org.au/~herbert/dash/
- Zsh Manual: https://zsh.sourceforge.io/Doc/

## Document History

- 2024-12-29: Initial documentation based on banish debugging session
