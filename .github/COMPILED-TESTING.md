# Compiled Spell Testing

This document explains how tests work with compiled spells and how to mark tests that don't support compiled mode.

## Overview

Wizardry has two testing modes:

1. **Regular mode**: Tests run against spells in the full wizardry environment
2. **Compiled mode**: Tests run against standalone compiled spells (doppelganger)

**By default, ALL tests run in both modes.** Only mark tests as unsupported if they genuinely cannot work with compiled spells.

## Marking Tests as COMPILED_UNSUPPORTED

To mark a test as **not supported** for compiled mode, add `# COMPILED_UNSUPPORTED: reason` as the second line:

```sh
#!/bin/sh
# COMPILED_UNSUPPORTED: requires full wizardry environment with memorization
# Test description here
```

**The reason is required.** It documents why the test cannot run in compiled mode.

### When to Mark Tests as COMPILED_UNSUPPORTED

Mark a test as `COMPILED_UNSUPPORTED` **only if**:

- ❌ The test requires wizardry infrastructure (invoke-wizardry, require-wizardry, etc.)
- ❌ The spell calls other spells as external commands that aren't inlined
- ❌ The test uses wizardry-specific features (spell menus, memorization, etc.)
- ❌ The test requires complex wizardry environment setup
- ❌ The spell genuinely cannot be compiled (by design)

### Default: Tests Run in Compiled Mode

Do **NOT** mark tests as unsupported if:

- ✅ The test only uses the spell's public interface (command-line args, stdin/stdout)
- ✅ The spell compiles successfully with all dependencies inlined
- ✅ The test works with minimal PATH and environment
- ✅ The test doesn't require special wizardry features

## Examples

### No Marker Needed (Default Behavior)

```sh
#!/bin/sh
# Test hash spell - runs in both modes by default

test_hash_shows_usage() {
  _run_spell "spells/crypto/hash" --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
}
```

This test runs in both regular and compiled mode automatically.

### Marked as Unsupported (With Justification)

```sh
#!/bin/sh
# COMPILED_UNSUPPORTED: requires memorize command and wizardry environment
# Test cast spell

test_cast_memorized_spell() {
  memorize add "test-spell" "echo hello"
  _run_spell "spells/menu/cast"
  # ...
}
```

This test is skipped in compiled mode because it requires the full wizardry environment with memorization.

### Marking Individual Subtests

If only some subtests are unsupported, add comments within the test:

```sh
#!/bin/sh
# Test my-spell

test_basic_usage() {
  # This works in compiled mode
  _run_spell "spells/my-spell" --help
  _assert_success || return 1
}

test_advanced_feature() {
  # COMPILED_UNSUPPORTED: requires wizardry-specific feature
  if [ "${WIZARDRY_TEST_COMPILED-0}" = "1" ]; then
    return 0  # Skip in compiled mode
  fi
  
  # Complex wizardry-specific test here
  # ...
}

_run_test_case "basic usage" test_basic_usage
_run_test_case "advanced feature" test_advanced_feature
```

## How It Works

### Test Discovery

The doppelganger workflow runs **all tests by default**, skipping only those marked:

```bash
# Skip test if marked unsupported
if grep -q "^# COMPILED_UNSUPPORTED" "$test_file"; then
  continue  # Skip this test
fi

# Otherwise, run the test
sh "$test_file"
```

### Environment Setup

When `WIZARDRY_TEST_COMPILED=1` is set:

- Test bootstrap disables sandboxing (compiled spells run in minimal environment)
- Tests run against compiled spells in `/tmp/wizardry-doppelganger/`
- PATH includes only doppelganger directories
- Subtests can check `${WIZARDRY_TEST_COMPILED-0}` to skip unsupported cases

### Running Tests

```bash
# In doppelganger workflow - all tests run by default
export WIZARDRY_TEST_COMPILED=1
export ROOT_DIR="/tmp/wizardry-doppelganger"
cd /tmp/wizardry-doppelganger

# This runs unless marked COMPILED_UNSUPPORTED
sh .tests/arcane/test-copy.sh
```

## Marking Tests as Unsupported

1. **Verify necessity**: Can the test really not work with compiled spells?
2. **Add marker**: Add `# COMPILED_UNSUPPORTED: reason` as second line
3. **Document reason**: Always explain why (e.g., "requires memorization system")
4. **Consider alternatives**: Can you make it work instead?

### Good Reasons for COMPILED_UNSUPPORTED

- "requires memorize command as external dependency"
- "uses spell-menu which requires wizardry infrastructure"
- "tests invoke-wizardry functionality"
- "requires sourcing colors for terminal output"
- "spell is wizardry infrastructure by design"

### Bad Reasons (Fix the Test Instead)

- "haven't tested yet" → Test it!
- "might not work" → Try it first
- "uses other spells" → They may be inlined automatically
- "needs PATH setup" → Compiled mode handles this

## Current Status

**Default**: All tests run against compiled spells

**Exceptions**: Tests marked with `COMPILED_UNSUPPORTED` are skipped

**Coverage**: Growing as more spells are verified to work standalone

## Checking Compiled Mode in Tests

Individual subtests can check if running in compiled mode:

```sh
test_wizard_specific_feature() {
  # Skip this subtest in compiled mode
  if [ "${WIZARDRY_TEST_COMPILED-0}" = "1" ]; then
    return 0  # Pass (skip)
  fi
  
  # Wizardry-specific test here
  # ...
}
```

## Testing Your Changes

Before marking a test as unsupported:

1. **Compile the spell**: `compile-spell spell-name > /tmp/spell && chmod +x /tmp/spell`
2. **Test manually**: `env -i PATH="/usr/bin:/bin" /tmp/spell --help`
3. **Run the test**: Set `WIZARDRY_TEST_COMPILED=1` and run the test
4. **Only mark unsupported if genuinely necessary**

## Future Work

- Continue running all tests by default against compiled spells
- Mark only truly unsupported tests with justification
- Improve compile-spell to handle more edge cases
- Reduce number of unsupported tests over time

