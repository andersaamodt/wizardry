# Testing Instructions

applyTo: ".tests/**"

## CRITICAL: Tests Are Required

**Every spell and imp MUST have a corresponding test file.** Tests are not optional.

When you create:
- A new spell at `spells/category/spell-name`
- A new imp at `spells/.imps/family/imp-name`

You MUST also create:
- Test at `.tests/category/test_spell-name.sh`
- Test at `.tests/.imps/family/test_imp-name.sh`

Failure to create tests will cause CI to fail with "uncovered spells/imps" errors.

## CRITICAL: Test Result Accuracy

**NEVER report test success without actually running the tests.**

- ❌ **WRONG**: "All tests pass" (without running them)
- ❌ **WRONG**: "Tests should pass" (guessing/assuming)
- ❌ **WRONG**: "I expect tests to succeed" (speculation)
- ✅ **CORRECT**: Run the test file, then report actual output: "5/5 tests passed"
- ✅ **CORRECT**: If tests not run: "Tests created but not yet verified"

**Always run tests after creating or modifying them:**
```sh
cd /home/runner/work/wizardry/wizardry && .tests/category/test-spell-name.sh
```

Only report test results you have personally verified by executing the test file. Include the actual pass/fail counts in your reports.

## Test File Location

Test files mirror the `spells/` directory structure:
- Spell: `spells/category/spell-name`
- Test: `.tests/category/test_spell-name.sh`

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

Use complete PATH isolation with symlinks for essential utilities:

```sh
stubdir="$tmpdir/stubs"
mkdir -p "$stubdir"

# Create test stub
cat <<'STUB' >"$stubdir/xsel"
#!/bin/sh
cat >"${CLIPBOARD_FILE:?}"
STUB
chmod +x "$stubdir/xsel"

# Symlink essential utilities
for util in sh sed cat printf test env basename dirname; do
  util_path=$(command -v "$util" 2>/dev/null) || continue
  [ -x "$util_path" ] && ln -sf "$util_path" "$stubdir/$util"
done

# Run with isolated PATH
PATH="$stubdir" run_spell "spells/category/spell"
```

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
