# Testing Instructions

applyTo: ".tests/**"

## CRITICAL: Tests Are Required

**Every spell and imp MUST have a corresponding test file.** Tests are not optional.

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

_stub_example() {
  # Stub implementation
  printf 'mocked-output\n'
}

# Self-execute when run directly (not sourced)
# CRITICAL: Match both stub name AND unprefixed name (for symlinks)
case "$0" in
  */example|*/stub-example) _stub_example "$@" ;; esac
```

Make it executable: `chmod +x spells/.imps/test/stub-example`

Then use it in tests via symlink, not by copying or inlining the stub code.

**CRITICAL**: The case pattern MUST match both `*/stub-example` (direct execution) and `*/example` (symlink execution). This allows tests to create symlinks without the `stub-` prefix.

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

## Dual-Pattern Testing

**All castable spells should be tested both ways:**
1. **Direct execution**: `./spells/category/spell --help`
2. **Source-then-invoke**: Via `_run_sourced_spell spell --help`

**Use `_run_both_patterns` wrapper:**
```sh
# Automatically tests both patterns
_run_both_patterns "spell shows usage" test_spell_usage "spells/category/spell"
```

**Or use environment variable:**
```sh
export WIZARDRY_TEST_BOTH_PATTERNS=1  # Makes all tests dual-pattern
./spells/system/test-magic
```

**Uncastable spells** (colors, move, jump-to-marker): Only test sourced pattern.

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
