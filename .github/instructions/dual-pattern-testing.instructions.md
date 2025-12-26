# Dual-Pattern Testing Guide

## Overview

All spells should be tested with BOTH execution patterns:
1. **Direct execution**: `./spells/category/spell --help`
2. **Source-then-invoke**: Source invoke-wizardry, then call `spell --help` as a function

This ensures spells work correctly in both contexts.

## Clear, Organized Test Output

The dual-pattern framework provides well-organized output to make debugging easy:

### Test Result Format

Each test clearly indicates which execution pattern it's testing:
- `PASS #1 copy shows usage [exec]` - Direct execution test passed
- `FAIL #2 copy handles errors [src]: expected exit code 1` - Sourced test failed

The markers `[exec]` and `[src]` make it immediately clear which pattern failed.

### Failure Summary

When tests fail, you get an organized summary grouped by execution pattern:

```
5/10 tests passed (5 failed)

=== FAILURE SUMMARY BY EXECUTION PATTERN ===

--- Direct Execution Failures [exec] ---
  copy handles missing file
  menu validates arguments
  forall requires command

--- Source-Then-Invoke Failures [src] ---
  copy handles missing file
  read-magic parses enchantments

=== END FAILURE SUMMARY ===
```

This makes it easy to:
- **Identify patterns**: See if failures are specific to one execution mode
- **Copy failure lists**: Each section is formatted for easy copying
- **Prioritize fixes**: Fix pattern-specific issues vs universal issues

## Automatic Dual-Pattern Testing

The test framework provides automatic dual-pattern testing without modifying individual test files.

### Option 1: Use `_run_both_patterns` Wrapper

Instead of `_run_test_case`, use `_run_both_patterns` to automatically test both patterns:

```sh
# OLD (single pattern):
_run_test_case "spell shows usage" test_spell_usage

# NEW (both patterns):
_run_both_patterns "spell shows usage" test_spell_usage "spells/category/spell"
```

The third argument (spell path) is optional. If omitted, the framework attempts to extract it from `_run_spell` calls in the test function.

### Option 2: Use `WIZARDRY_TEST_BOTH_PATTERNS` Environment Variable

Set this variable to automatically run all tests with both patterns:

```sh
export WIZARDRY_TEST_BOTH_PATTERNS=1
./spells/system/test-magic
```

This makes `_run_test_case` internally use `_run_both_patterns` for all tests.

### Option 3: Explicit Source-Then-Invoke Tests

For tests that need fine-grained control, use `_run_sourced_spell` directly:

```sh
test_spell_via_sourcing() {
  _run_sourced_spell spell --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
}

_run_test_case "spell shows usage when sourced" test_spell_via_sourcing
```

## Castable vs Uncastable Spells

**Castable spells** (114 spells) - Can be invoked as functions after sourcing:
- Tested with BOTH direct execution and source-then-invoke
- Use `castable "$@"` at end of spell file

**Uncastable spells** (3 spells) - Must be sourced, not executed:
- `colors`, `move`, `jump-to-marker`
- Tested with source-then-invoke ONLY
- Use `uncastable` near top of spell file
- Direct execution should fail with helpful message

## Test Framework Behavior

The dual-pattern framework automatically:
1. Detects if a spell is castable or uncastable (by checking for `uncastable` in spell file)
2. For castable spells: Runs test twice (direct execution + sourced)
3. For uncastable spells: Runs test once (sourced only)
4. Provides clear test names: "test name (direct execution)" and "test name (sourced)"

## Migration Strategy

**Phase 1** (CURRENT): Add dual-pattern support to test framework
- ✅ Created `_run_both_patterns` helper
- ✅ Added `WIZARDRY_TEST_BOTH_PATTERNS` environment variable support
- ✅ All 117 spells now use `castable`/`uncastable`

**Phase 2** (IN PROGRESS): Update existing tests
- Convert high-priority test files to use `_run_both_patterns`
- Focus on core spells first (menu, copy, forall, etc.)
- 99/117 spell tests already have source-then-invoke variants added manually

**Phase 3** (FUTURE): Make dual-pattern testing the default
- Update `_run_test_case` to call `_run_both_patterns` by default
- Add opt-out mechanism for tests that legitimately only need one pattern
- Update all remaining test files

## Examples

### Simple Test With Automatic Dual-Pattern

```sh
#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_shows_usage() {
  _run_spell "spells/arcane/copy" --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
}

# Automatic dual-pattern testing
_run_both_patterns "copy shows usage" test_shows_usage "spells/arcane/copy"

_finish_tests
```

### Uncastable Spell Test (Source-Only)

```sh
test_colors_must_be_sourced() {
  _run_spell "spells/cantrips/colors"
  _assert_failure || return 1
  _assert_error_contains "must be sourced" || return 1
}

test_colors_defines_variables() {
  _run_sourced_spell colors
  _assert_success || return 1
  # Colors are now available as environment variables
}

# Only test sourcing for uncastable spells
_run_test_case "colors must be sourced (not executed)" test_colors_must_be_sourced
_run_test_case "colors defines color variables" test_colors_defines_variables

_finish_tests
```

## Benefits

1. **Comprehensive coverage**: All spells tested in both usage contexts
2. **No manual duplication**: Framework handles pattern variation automatically
3. **Easy migration**: Existing tests work unchanged, new tests get dual-pattern for free
4. **Clear test output**: Each pattern shows as separate test case
5. **Efficient**: Uncastable spells automatically skip direct execution test

## See Also

- `spells/.imps/test/boot/run-both-patterns` - Dual-pattern test wrapper
- `spells/.imps/test/boot/run-sourced-spell` - Source-then-invoke helper
- `spells/.imps/sys/castable` - Castable spell pattern
- `spells/.imps/sys/uncastable` - Uncastable spell pattern
