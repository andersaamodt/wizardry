# Best Practices from Wizardry Codebase

This document extracts proven patterns and practices discovered in the wizardry codebase that should guide AI assistants when working with the project.

## Self-Execute Pattern for Invocable Spells

**Pattern**: Spells that define functions can be both sourced AND executed directly using a self-execute guard.

**Why**: This allows spells to be invoked (sourced) for performance OR executed as standalone scripts.

**Implementation**:

```sh
#!/bin/sh
# Brief description

spell_name() {
  # Function body
}

# Self-execute when run directly (not sourced)
case "$0" in
  */spell-name) spell_name "$@" ;; esac
```

**Examples in codebase**:
- `spells/arcane/forall`
- `spells/.imps/out/say`
- `spells/.imps/cond/has`

**Key points**:
- The guard checks if `$0` matches the script name pattern
- When sourced, `$0` is the parent script, so the function is defined but not executed
- When run directly, `$0` matches and the function executes
- This is critical for the `invoke-wizardry` system that sources spells for performance

## PATH Baseline Pattern for Bootstrap Scripts

**Pattern**: Set a baseline PATH BEFORE `set -eu` in bootstrap scripts.

**Why**: On some platforms (especially macOS in CI), PATH may be empty or incomplete, causing immediate failure when trying to use basic commands like `dirname`, `cd`, or `pwd`.

**Implementation**:

```sh
#!/bin/sh

# Set baseline PATH BEFORE set -eu
baseline_path="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
case ":${PATH-}:" in
  *":/usr/bin:"*|*":/bin:"*)
    # Already has at least one standard directory
    ;;
  *)
    # PATH is empty or missing standard directories, prepend baseline
    PATH="${baseline_path}${PATH:+:}${PATH-}"
    ;;
esac
export PATH

set -eu

# Rest of script...
```

**Examples in codebase**:
- `spells/.imps/test/test-bootstrap`
- Bootstrap scripts in `spells/install/core/`

**Key points**:
- Check if PATH already contains standard directories before modifying
- Prepend baseline, don't replace (preserve existing PATH entries)
- Do this BEFORE `set -eu` to avoid failures from empty variable expansion
- Use `${PATH:+:}` to conditionally add colon only if PATH is non-empty

## env-clear Sourcing Pattern

**Pattern**: Source `env-clear` near the top of spells (after help handler, before main logic).

**Why**: Prevents the environment variable antipattern by clearing non-essential env vars while preserving wizardry globals and system variables.

**Implementation**:

```sh
#!/bin/sh
# Brief description

show_usage() {
  cat <<'USAGE'
Usage: spell-name [args]
Description.
USAGE
}

case "${1-}" in
--help|--usage|-h)
  show_usage
  exit 0
  ;;
esac

require-wizardry || exit 1

set -eu
. env-clear  # Source env-clear after set -eu

# Main logic...
```

**Examples in codebase**:
- `spells/arcane/forall`
- `spells/cantrips/menu`

**Key points**:
- Source AFTER `set -eu` (env-clear handles its own mode switching)
- Source AFTER `require-wizardry` check
- Source BEFORE main logic
- env-clear preserves wizardry globals, system vars, and test infrastructure
- In test mode (`WIZARDRY_TEST_HELPERS_ONLY=1`), env-clear is a no-op

## Function Discipline Guidelines

**Pattern**: Limit the number of internal functions in spells to maintain readability.

**Why**: A spell is a scroll—readable from top to bottom. Too many functions indicate the action is conceptually fractured and should be refactored.

**Guidelines**:
- `show_usage()` is required (except for imps)
- **0-1 additional helper function**: Freely allowed (the "spell-heart helper")
- **2 additional functions**: Acceptable with warning (must be invoked from multiple paths, not suitable as imps)
- **3 additional functions**: Marginal case with strong warning
- **4+ additional functions**: Indicates proto-library, must decompose into multiple spells and/or imps

**Rationale**: Multiple internal subroutines indicate the spell should be split into smaller spells or shared logic should be extracted to imps.

**Examples of good discipline**:
- `spells/arcane/forall` - One usage function, flat main logic
- Most imps - Zero or one function, extremely focused

**Refactoring strategies when limits are exceeded**:
1. Split complex spells into multiple smaller spells
2. Extract reusable logic to imps in `spells/.imps/`
3. Use composition - small spells that pipe together
4. Create a dedicated menu for complex workflows

## Test Helper Pattern: Stub Imps

**Pattern**: Create reusable stub imps in `spells/.imps/test/stub-*` for mocking.

**Why**: Avoids inline stub definitions that clutter test files. Provides consistent mocking across all tests.

**Implementation**:

```sh
# File: spells/.imps/test/stub-example
#!/bin/sh
# stub-example - test stub for example command
# Example: stub-example arg1

_stub_example() {
  # Stub implementation
  printf 'mocked-output\n'
}

# Self-execute when run directly (not sourced)
case "$0" in
  */stub-example) _stub_example "$@" ;; esac
```

**Usage in tests**:

```sh
# Create symlink directory for PATH override
stub_dir="$tmpdir/stubs"
mkdir -p "$stub_dir"

# Link to reusable stub imps (stub only what's necessary)
for stub in fathom-cursor fathom-terminal move-cursor; do
  ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
done

# Run with stubs in PATH (stubs override real commands)
PATH="$stub_dir:$ROOT_DIR/spells/cantrips:...:$PATH" run_spell "spells/cantrips/menu"
```

**Examples in codebase**:
- `spells/.imps/test/stub-fathom-cursor`
- `spells/.imps/test/stub-fathom-terminal`
- `spells/.imps/test/stub-move-cursor`
- `spells/.imps/test/stub-cursor-blink`
- `spells/.imps/test/stub-stty`

**Key principles**:
- **Stub the minimum necessary** - typically just terminal I/O
- **Test real wizardry** - don't stub internal wizardry logic
- **Reusable stubs are test imps** - not inline scripts
- Create symlinks to stub imps, don't copy them
- Make stub imps executable: `chmod +x spells/.imps/test/stub-*`

## Test Naming Convention

**Pattern**: Test files use `test-<name>.sh` format (all hyphens, NO underscores).

**Why**: Consistent naming makes tests discoverable and matches spell naming conventions.

**Examples**:
- Spell: `spells/cantrips/ask-yn` → Test: `.tests/cantrips/test-ask-yn.sh`
- Spell: `spells/arcane/read-magic` → Test: `.tests/arcane/test-read-magic.sh`
- Imp: `spells/.imps/out/say` → Test: `.tests/.imps/out/test-say.sh`

**Common mistake**: Using `test_spell-name.sh` instead of `test-spell-name.sh` (underscores vs hyphens)

**Rule**: Replace the spell/imp filename with `test-<filename>.sh` in the mirrored directory.

## Test Bootstrap Pattern

**Pattern**: Tests locate the repository root and source `test-bootstrap` for framework functions.

**Why**: Provides consistent test environment across all tests regardless of where they're run from.

**Implementation**:

```sh
#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test cases...

_run_test_case "description" test_function
_finish_tests
```

**What test-bootstrap provides**:
- Sets up PATH with all wizardry spells and imps
- Exports `ROOT_DIR` pointing to repository root
- Exports `WIZARDRY_IMPS_PATH` for tests that need minimal PATH
- Exports `WIZARDRY_SYSTEM_PATH` for essential utilities
- Creates `WIZARDRY_TMPDIR` for temporary files
- Provides test helper functions (`_run_spell`, `_assert_success`, etc.)
- Handles platform detection and sandbox setup

**Key points**:
- Always disable `CDPATH` when locating directories: `CDPATH= cd --`
- Walk upward until finding `test-bootstrap` or reaching root
- Source, don't execute: `. "$test_root/spells/.imps/test/test-bootstrap"`

## Descriptive, Not Imperative Error Messages

**Pattern**: Error messages describe what went wrong, they don't tell the user what to do.

**Why**: Aligns with wizardry's self-healing philosophy—spells should fix problems, not demand users fix them.

**Implementation**:

```sh
# CORRECT - describes the problem
die "spell-name: sshfs not found"
warn "spell-name: configuration file missing"
die "spell-name: file path required"

# WRONG - tells user what to do (imperative)
die "Please install sshfs"
warn "You must create a configuration file"
die "Error: file argument required"
```

**Key principles**:
- State facts about what's wrong, not commands to fix it
- Prefix with spell name for attribution
- After detecting a problem, attempt to fix it automatically
- Only exit with error when actual work failed, not fixable problems

**Examples from codebase**:
- Output imps (`die`, `warn`, `fail`) follow this pattern
- All modern spells use descriptive error messages

## require-wizardry Pattern

**Pattern**: Use `require-wizardry` to ensure wizardry is available before using imps or spells.

**Why**: Provides consistent error handling when wizardry isn't installed or in PATH.

**Implementation**:

```sh
#!/bin/sh
# Brief description

show_usage() {
  cat <<'USAGE'
Usage: spell-name [args]
Description.
USAGE
}

case "${1-}" in
--help|--usage|-h)
  show_usage
  exit 0
  ;;
esac

# Check wizardry availability before proceeding
require-wizardry || exit 1

set -eu
. env-clear

# Now safe to use wizardry imps and spells
say "Hello from wizardry!"
```

**Key points**:
- Place AFTER help handler (help should work without wizardry)
- Place BEFORE `set -eu` (so `||` works correctly)
- Place BEFORE sourcing `env-clear` or using any imps
- The check exits gracefully with helpful message if wizardry isn't found

**Examples in codebase**:
- `spells/arcane/forall`
- `spells/cantrips/menu`
- Most modern spells

## Variable Default Patterns

**Pattern**: Always provide defaults for variable expansion with `set -u` enabled.

**Why**: `set -u` causes script to exit if accessing undefined variables, but we often want empty defaults.

**Implementation**:

```sh
set -eu

# Empty default (most common)
value=${1-}              # Empty string if $1 unset
name=${NAME-}            # Empty string if NAME unset

# Non-empty default
value=${1:-default}      # "default" if $1 unset OR empty
path=${PATH:-/usr/bin}   # "/usr/bin" if PATH unset OR empty

# Conditional assignment (set only if unset)
: "${VAR:=default}"      # Sets VAR to "default" if unset or empty
```

**Difference between `-` and `:-`**:
- `${var-default}`: Use default only if var is unset (empty string is kept)
- `${var:-default}`: Use default if var is unset OR empty

**Common usage**:
- Use `${1-}` for optional positional arguments
- Use `${VAR-}` for optional environment variables
- Use `${VAR:-default}` when you want to treat empty as unset

## Conditional Imps Don't Use set -eu

**Pattern**: Imps that return exit codes for flow control should NOT use `set -eu`.

**Why**: These imps are designed for use in `if` statements and `&&`/`||` chains where non-zero exit codes indicate false, not error.

**Implementation**:

```sh
#!/bin/sh
# has COMMAND - test if command exists on PATH
# Example: has git && git status

_has() {
  command -v "$1" >/dev/null 2>&1
}

# Self-execute when run directly (not sourced)
case "$0" in
  */has) _has "$@" ;; esac
```

**Families that don't use set -eu**:
- `cond/` - Conditional tests (`has`, `there`, `is`, `yes`, `no`, `empty`, `nonempty`)
- `lex/` - Parsing helpers that signal success/failure via exit code
- Menu helpers that return true/false

**Action imps DO use set -eu**:
- `out/` - Output and error handling (`say`, `die`, `warn`, `fail`)
- `fs/` - Filesystem operations
- `sys/` - System utilities that perform actions
- Most other imp families

## Spell Help Text Best Practices

**Pattern**: Keep help text brief and scannable (2-5 lines after `Usage:` line).

**Why**: Help text should be a quick reference, not complete documentation. Users can read source for details.

**Good example**:

```sh
show_usage() {
  cat <<'USAGE'
Usage: look [path]

Display a location's name and description extended attributes using read-magic,
offering to memorize the spell into your shell rc for persistent availability.
Defaults to the current directory when no path is supplied.
USAGE
}
```

**Signs help needs refactoring**:
- More than 10 lines in usage block
- Multiple `Usage:` lines for different modes
- Argument descriptions longer than one line
- Need for a table of options

**Refactoring when help is too complex**:
- Split into multiple smaller spells
- Move complexity to helper imps
- Use subcommands (separate spells) instead of flags
- Provide sensible defaults to reduce options needed

## Command-Line Spell Invocation in Menus

**Pattern**: Use spell names, not full paths, when building menu items.

**Why**: After wizardry is installed, all spells are on PATH. Using names keeps menus cleaner and location-independent.

**Implementation**:

```sh
# CORRECT - use spell name
cd_hook="[ ] CD hook%toggle-cd"
system="System Menu%system-menu"

# AVOID - full paths
cd_hook="[ ] CD hook%$SCRIPT_DIR/../install/mud/toggle-cd"
system="System Menu%$SCRIPT_DIR/system-menu"
```

**Key point**: Since menus are only accessible after installation, PATH is guaranteed to include all spells.

## Summary

These patterns emerged from real code in the wizardry repository and represent proven solutions to common challenges:

1. **Self-execute pattern** - Makes spells both invocable and executable
2. **PATH baseline** - Ensures bootstrap scripts work on minimal systems
3. **env-clear sourcing** - Prevents environment variable pollution
4. **Function discipline** - Keeps spells readable and maintainable
5. **Stub imps** - Provides consistent, reusable test mocking
6. **Test naming** - Consistent `test-<name>.sh` convention
7. **Test bootstrap** - Unified test environment setup
8. **Descriptive errors** - Self-healing philosophy in messages
9. **require-wizardry** - Consistent dependency checking
10. **Variable defaults** - Safe patterns with `set -u`
11. **Conditional imps** - No strict mode for flow control helpers
12. **Brief help text** - Scannable, not exhaustive
13. **Spell invocation** - Names, not paths, in menus

These practices should guide all new code and be applied when refactoring existing code.
