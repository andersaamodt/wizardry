# Compiled Spell Testing

This document explains how tests work with compiled spells and how to mark tests for compiled mode.

## Overview

Wizardry has two testing modes:

1. **Regular mode**: Tests run against spells in the full wizardry environment
2. **Compiled mode**: Tests run against standalone compiled spells (doppelganger)

## Marking Tests for Compiled Support

To mark a test as supported for compiled mode, add `# COMPILED_SUPPORTED` as the second line of the test file (after the shebang):

```sh
#!/bin/sh
# COMPILED_SUPPORTED
# Test description here
```

### When to Mark Tests as COMPILED_SUPPORTED

Mark a test as `COMPILED_SUPPORTED` if:

- ✅ The test only uses the spell's public interface (command-line args, stdin/stdout)
- ✅ The spell compiles successfully with all dependencies inlined
- ✅ The test doesn't rely on wizardry infrastructure (invoke-wizardry, require-wizardry, etc.)
- ✅ The test doesn't require wizardry environment variables beyond PATH
- ✅ The test doesn't source other spells or imps

Do NOT mark a test as `COMPILED_SUPPORTED` if:

- ❌ The test requires full wizardry environment
- ❌ The spell calls other spells as external commands (unless they're also inlined)
- ❌ The test uses wizardry-specific features (spell menus, memorization, etc.)
- ❌ The test requires complex sandboxing features

## Examples

### Good for Compiled Mode

```sh
#!/bin/sh
# COMPILED_SUPPORTED
# Test hash spell

test_hash_shows_usage() {
  _run_spell "spells/crypto/hash" --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
}
```

This test only checks `--help` output, which works in compiled mode.

### Not Good for Compiled Mode

```sh
#!/bin/sh
# Test cast spell (requires memorize, wizardry environment)

test_cast_memorized_spell() {
  memorize add "test-spell" "echo hello"
  _run_spell "spells/menu/cast"
  # ...
}
```

This test requires the full wizardry environment with memorization support.

## How It Works

### Test Discovery

The doppelganger workflow scans test files for the `# COMPILED_SUPPORTED` marker:

```bash
grep -q "^# COMPILED_SUPPORTED" "$test_file"
```

### Environment Setup

When `WIZARDRY_TEST_COMPILED=1` is set:

- Test bootstrap disables sandboxing (compiled spells run in minimal environment)
- Tests run against compiled spells in `/tmp/wizardry-doppelganger/`
- PATH includes only doppelganger directories

### Running Tests

```bash
# In doppelganger workflow
export WIZARDRY_TEST_COMPILED=1
export ROOT_DIR="/tmp/wizardry-doppelganger"
cd /tmp/wizardry-doppelganger
sh .tests/arcane/test-copy.sh
```

## Adding Compiled Support to Tests

1. **Review the test**: Ensure it only tests the spell's public interface
2. **Test compilation**: Verify the spell compiles with `compile-spell spell-name`
3. **Test standalone**: Run compiled spell manually to verify it works
4. **Add marker**: Add `# COMPILED_SUPPORTED` as second line
5. **Verify**: Run the test in compiled mode to ensure it passes

## Current Coverage

Tests marked with `COMPILED_SUPPORTED`:

- `.tests/arcane/test-copy.sh` - Copy spell (clipboard operations)
- `.tests/arcane/test-trash.sh` - Trash spell (file operations)
- `.tests/arcane/test-read-magic.sh` - Read-magic spell
- `.tests/crypto/test-hash.sh` - Hash spell (crypto operations)

## Future Work

- Add compiled support markers to more tests as spells are verified
- Create test helper to automatically detect if spell can run in compiled mode
- Add CI status badge showing compiled test coverage
