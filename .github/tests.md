# Testing Instructions

applyTo: ".tests/**"

## CRITICAL: Run `banish` Before Tests

**All CI workflows run `banish 8` before `test-magic`.** This validates the environment and catches issues early.

```sh
. spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose
```

**Why this pattern works:**
- **Early failure**: Environment issues fail fast before wasting time on tests
- **Self-healing**: `banish` auto-installs missing dependencies when possible
- **Visibility**: Platform/tool availability logged upfront in CI for debugging
- **Consistency**: Same validation across all platforms (Linux, macOS, containers)
- **Level 8**: Validates through Testing Infrastructure - sufficient for unit tests

**When running tests locally**, always source invoke-wizardry and run banish first:
```sh
. spells/.imps/sys/invoke-wizardry && banish 8 && test-spell category/test-name
```

## CRITICAL: Tests Are Required

**Every spell and imp MUST have a corresponding test file.** Tests are not optional.

## CRITICAL: Test-Driven Development

**Create realistic unit tests for every feature BEFORE writing or fixing code.**

Tests are the fastest path to working code for several reasons:
- Tests catch edge cases immediately that you might miss in manual testing
- Tests provide immediate feedback on whether your fix actually works
- Tests prevent regressions when making future changes
- Tests document expected behavior precisely
- Tests force you to think through all scenarios before implementation

**When debugging or adding features:**
1. Write tests that reproduce the bug or test the new feature FIRST
2. Run tests to verify they fail (proving the bug exists or feature is missing)
3. Fix the code
4. Run tests again to verify they pass
5. Only then report the fix as complete

**Never claim code works without running actual tests.** Manual testing misses edge cases.

## CRITICAL: Test File Location Must Mirror Spell Structure

**Test files MUST mirror the `spells/` directory structure exactly.** You CANNOT create test files without corresponding spells or imps.

**DO NOT create standalone test files for validation checks, linting, or project-wide tests.** These should be integrated into existing spells like `lint-magic` or `test-magic`.

### Test Naming Convention

**IMPORTANT:** Test files use `test-<name>.sh` format (all hyphens, NO underscores).

When you create:
- A new spell at `spells/category/spell-name`
- A new imp at `spells/.imps/family/imp-name`

You MUST also create:
- Test at `.tests/category/test-spell-name.sh` (note: `test-` prefix, not `test_`)
- Test at `.tests/.imps/family/test-imp-name.sh` (note: `test-` prefix, not `test_`)

**Examples:**
- Spell: `spells/cantrips/ask-yn` → Test: `.tests/cantrips/test-ask-yn.sh`
- Spell: `spells/arcane/read-magic` → Test: `.tests/arcane/test-read-magic.sh`
- Imp: `spells/.imps/out/say` → Test: `.tests/.imps/out/test-say.sh`

**Common Mistake:** Using `test_spell-name.sh` instead of `test-spell-name.sh` (underscores vs hyphens)

Failure to create tests will cause CI to fail with "uncovered spells/imps" errors.

## Stub Imps for Testing

**Reusable stubs are test imps, not inline scripts.**

Located in `spells/.imps/test/stub-*`, these provide consistent mocking across tests:
- `stub-fathom-cursor` - Mock cursor position detection
- `stub-fathom-terminal` - Mock terminal size detection
- `stub-move-cursor` - Mock cursor movement (no-op)
- `stub-cursor-blink` - Mock cursor visibility control
- `stub-stty` - Mock terminal settings

### Using Stub Imps

**CRITICAL**: Stub directory must be FIRST in PATH to override real commands.

```sh
# Create symlink directory for PATH override
stub_dir="$tmpdir/stubs"
mkdir -p "$stub_dir"

# Link to reusable stub imps (stub only what's necessary)
for stub in fathom-cursor fathom-terminal move-cursor; do
  ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
done

# CRITICAL: Put stub_dir FIRST in PATH so stubs override real commands
PATH="$stub_dir:$ROOT_DIR/spells/cantrips:...:$PATH" run_spell "spells/cantrips/menu"

# Or with export (preferred for complex tests)
export PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:...:$PATH"
_run_spell "spells/cantrips/menu"
```

### Stub Philosophy

**Stub the minimum necessary, test real wizardry:**
- ✅ **DO**: Stub terminal I/O (fathom-cursor, stty, move-cursor)
- ✅ **DO**: Use real wizardry spells and imps
- ✅ **DO**: Create reusable stub imps in `spells/.imps/test/`
- ❌ **DON'T**: Create inline stubs in test files
- ❌ **DON'T**: Stub wizardry internals (await-keypress, menu logic)
- ❌ **DON'T**: Rely on timeouts as a testing strategy

### Creating New Stub Imps

When adding a new stub, create it as a test imp:

```sh
# File: spells/.imps/test/stub-example
#!/bin/sh
# stub-example - test stub for example command
# Example: stub-example arg1

set -eu

# Stub implementation
printf 'mocked-output\n'
```

Make it executable: `chmod +x spells/.imps/test/stub-example`

Then use it in tests via symlink, not by copying or inlining the stub code.

## socat-Based Interactive Testing

**For true interactive testing, use socat with real pseudo-TTY allocation.**

### Why socat?

- **Real PTY**: Allocates actual pseudo-TTY, not pipes or mocks
- **Raw input**: Send raw escape bytes for arrow keys, control keys, etc.
- **POSIX only**: No Tcl, expect, tmux, screen, or foreign languages
- **Transcript-based**: Capture output, normalize, then assert

### socat Test Helpers

Located in `spells/.imps/test/`:

- `run-with-pty COMMAND [ARGS]` - **Recommended** - Run command in real PTY with symbolic keys
- `socat-pty COMMAND [ARGS]` - Advanced PTY allocation
- `socat-send-keys KEYS` - Convert symbolic keys to raw escape bytes
- `socat-normalize-output` - Strip ANSI codes and carriage returns from output

### run-with-pty Helper (Recommended)

**Simplest way to run commands in real PTY via socat:**

```sh
test_menu_navigation() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  # Use PTY_KEYS for symbolic key input (converted to escape sequences)
  PTY_KEYS="down down enter" run_cmd run-with-pty \
    menu "Select option:" \
    "First%cmd1" "Second%cmd2" "Third%cmd3"
  
  assert_success || return 1
  assert_output_contains "cmd2" || return 1  # Selected second item
}
```

**Environment variables:**
- `PTY_KEYS` - Symbolic key names converted to escape sequences (e.g., "up down enter")
  - Recommended for arrow keys, enter, etc.
  - More readable than raw bytes
  - Converts to actual terminal escape sequences
- `PTY_INPUT` - Raw bytes to send (e.g., "text\n")
  - Use for simple text input
- If neither provided, defaults to single newline

**Supported symbolic keys:**
- `enter` → `\r` (carriage return)
- `up`, `down`, `left`, `right` → Arrow escape sequences (`\033[A`, `\033[B`, etc.)
- `escape`/`esc`, `tab`, `space`, `backspace`
- Any other text → literal characters

**Example with terminal query stubs:**
```sh
test_with_stubs() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Stub terminal queries for CI compatibility
  for stub in fathom-cursor fathom-terminal; do
    ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
  done
  
  # Arrow keys go through real PTY as escape sequences!
  PTY_KEYS="up enter" run_cmd env \
    PATH="$stub_dir:$PATH" \
    run-with-pty \
    menu "Test:" "A%cmd1" "B%cmd2"
  
  assert_success
}
```

### socat Testing Pattern (Advanced)

```sh
test_interactive_feature() {
  tmpdir=$(make_tempdir)
  
  # Run command with real PTY via socat
  # Output is captured automatically
  output=$("$ROOT_DIR/spells/.imps/test/socat-pty" \
    "$ROOT_DIR/spells/cantrips/ask-yn" "Proceed?")
  
  # Normalize output (strip ANSI codes, carriage returns)
  normalized=$(printf '%s' "$output" | socat-normalize-output)
  
  # Assert on normalized transcript
  case "$normalized" in
    *"Proceed?"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="expected prompt in output"
      return 1
      ;;
  esac
}
```

### socat Key Conversion

`socat-send-keys` converts symbolic names to raw escape bytes:

- `enter` → `\r` (carriage return)
- `up` → `ESC[A`
- `down` → `ESC[B`
- `left` → `ESC[D`
- `right` → `ESC[C`
- `escape` or `esc` → `ESC`
- `tab` → `\t`
- `space` → ` `
- `backspace` → `\010`
- Any other text → literal characters

Example:
```sh
# Send arrow down, then enter
keys=$(socat-send-keys down enter)
```

### socat Requirements

- **Installation**: `banish 8` checks for socat and auto-installs if missing
- **Manual install**: Via core menu or `spells/.arcana/core/install-socat`
- **Fail loudly**: Tests fail if socat unavailable, never degrade to mocks

### socat vs Stub Philosophy

**When to use socat:**
- Testing real interactive behavior (menu navigation, prompts with real TTY)
- Validating cursor movements, colors, screen updates
- Integration testing of interactive spells

**When to use stubs:**
- Unit testing non-interactive logic
- Testing error conditions without TTY complexity
- Fast, isolated tests of specific functions

**Key principle**: Never mock interactive behavior. Use real PTY via socat or skip the test.

## CRITICAL: Test Result Accuracy

**NEVER report test success without actually running the tests.**

- ❌ **WRONG**: "All tests pass" (without running them)
- ❌ **WRONG**: "Tests should pass" (guessing/assuming)
- ❌ **WRONG**: "I expect tests to succeed" (speculation)
- ✅ **CORRECT**: Run the test file, then report actual output: "5/5 tests passed"
- ✅ **CORRECT**: If tests not run: "Tests created but not yet verified"

**Always run tests after creating or modifying them:**

**Recommended (faster for individual spells):**
```sh
# test-spell runs BOTH the spell's test file AND common structural tests by default
cd /home/runner/work/wizardry/wizardry && ./spells/system/test-spell category/test-spell-name.sh

# Skip common tests if only debugging a specific test failure
cd /home/runner/work/wizardry/wizardry && ./spells/system/test-spell --skip-common category/test-spell-name.sh
```

**Alternative (direct execution):**
```sh
cd /home/runner/work/wizardry/wizardry && .tests/category/test-spell-name.sh
```

**Why use test-spell?**
- Automatically runs common structural/behavioral tests on the spell being tested
- Much faster than running `test-magic` on all tests when you only changed one spell
- Provides complete test coverage for a single spell (both specific and common tests)
- AI agents should prefer `test-spell` for individual spell testing as it completes faster

Only report test results you have personally verified by executing the test file. Include the actual pass/fail counts in your reports.

## Test File Location and Naming

**CRITICAL RULE: Test files MUST correspond to actual spells or imps.** The `.tests/` directory structure must exactly mirror the `spells/` directory structure.

❌ **WRONG**: Creating `.tests/spellcraft/test-no-duplicate-set-eu.sh` when there's no `spells/spellcraft/no-duplicate-set-eu` spell
✅ **CORRECT**: Integrating validation checks into existing spells like `lint-magic`

Test files mirror the `spells/` directory structure with `test-` prefix (all hyphens):

| Spell Path | Test Path | Correct |
|------------|-----------|---------|
| `spells/category/spell-name` | `.tests/category/test-spell-name.sh` | ✅ Correct |
| `spells/category/spell-name` | `.tests/category/test_spell-name.sh` | ❌ Wrong (underscore) |
| `spells/.imps/family/imp-name` | `.tests/.imps/family/test-imp-name.sh` | ✅ Correct |
| `spells/.imps/family/imp-name` | `.tests/.imps/family/test_imp-name.sh` | ❌ Wrong (underscore) |

**Pattern:** Replace the spell/imp filename with `test-<filename>.sh` in the mirrored directory.

## Test Template

### Basic Test Template

```sh
#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

test_help() {
  run_spell "spells/category/spell-name" --help
  assert_success && assert_output_contains "Usage:"
}

run_test_case "spell prints usage" test_help
finish_tests
```

### Interactive Test Template (socat)

For spells that require real TTY interaction:

```sh
#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

test_interactive_prompt() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat for real PTY testing"
    return 0
  fi
  
  tmpdir=$(make_tempdir)
  
  # Run spell with real PTY via socat
  output=$("$ROOT_DIR/spells/.imps/test/socat-pty" \
    "$ROOT_DIR/spells/category/spell-name" "arg1")
  
  # Normalize output (strip ANSI, CR)
  normalized=$(printf '%s' "$output" | socat-normalize-output)
  
  # Assert on normalized transcript
  assert_output_contains "expected text" || return 1
}

run_test_case "spell shows interactive prompt" test_interactive_prompt
finish_tests
```

## Test Helpers

```sh
# Run a spell
run_spell "spells/path/to/spell" arg1 arg2

# Assertions
assert_success || return 1
assert_failure || return 1
assert_output_contains "expected text" || return 1
assert_error_contains "error text" || return 1

# Create temp directory
tmpdir=$(make_tempdir)
```

## PATH Isolation for Tests

**Use real wizardry with minimal stubs:**

```sh
# Create symlink directory for stub imps
stub_dir="$tmpdir/stubs"
mkdir -p "$stub_dir"

# Link to reusable stub imps (terminal I/O only)
for stub in fathom-cursor fathom-terminal stty; do
  ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
done

# Symlink essential system utilities
for util in sh sed cat printf test env basename dirname; do
  util_path=$(command -v "$util" 2>/dev/null) || continue
  [ -x "$util_path" ] && ln -sf "$util_path" "$stub_dir/$util"
done

# Run with stubs overriding only what's necessary
PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:...:$PATH" run_spell "spells/category/spell"
```

**Key principle**: Stub the bare minimum (terminal I/O), test real wizardry for everything else.

## Cross-Platform Testing

- Include both `/bin` and `/usr/bin` when setting PATH
- Normalize paths before assertions: `$(pwd -P | sed 's|//|/|g')`
- Use `make_tempdir` which handles normalization

## Test Coverage

Every test should cover:
1. `--help` output
2. Success cases
3. Error cases
4. Platform-specific fallbacks if applicable
