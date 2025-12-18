# Interactive Spells Documentation

This document provides a comprehensive list of all interactive spells in wizardry that require special care when testing to prevent hanging.

## Why This Matters

Interactive spells can hang during testing if:
1. Error functions (die/fail/usage-error) are called in conditional blocks without `|| return 1`
2. Input operations (read, await-keypress, menu) aren't properly stubbed
3. Test-specific code is added to spells (violates clean code principles)

## Root Cause: set -e in Conditional Contexts

When die/fail/usage-error is called inside if/case/while blocks, shell's `set -e` is disabled for that command. The non-zero exit doesn't stop execution, causing scripts to continue and potentially hang on read operations.

**Fix pattern**:
```sh
while [ "$#" -gt 0 ]; do
  case $1 in
    -*) usage-error "spell-name" "unknown option: $1" || return 1 ;;
  esac
done
```

## Testing Requirements

1. **Stub await-keypress** for menu-based spells - use `stub-await-keypress` imp
2. **Stub user input** for prompting spells - use environment variables or stdin redirection
3. **Add `|| return 1`** after die/fail/usage-error in conditional blocks (while, if, case)
4. **Use real wizardry** with minimal stubs (terminal I/O + input layer only)
5. **Never add test-specific code to spells** (e.g., MENU_LOOP_LIMIT)

## Interactive Spell Categories

### Menu-Based Spells (17)

These spells use the `menu` system and require `await-keypress` stubbing:

1. `spells/.arcana/bitcoin/bitcoin-menu`
2. `spells/.arcana/bitcoin/wallet-menu`
3. `spells/.arcana/core/core-menu`
4. `spells/.arcana/lightning/lightning-menu`
5. `spells/.arcana/lightning/lightning-wallet-menu`
6. `spells/.arcana/mud/toggle-mud-menu`
7. `spells/.arcana/node/node-menu`
8. `spells/.arcana/rust/rust-menu`
9. `spells/.arcana/spellbook/spellbook-menu`
10. `spells/system/menu` - Main menu implementation
11. Menu test spells that use the menu system

**Testing**: Use `stub-await-keypress` to simulate keypresses. See `.tests/cantrips/test-menu.sh` for examples.

### Prompting/Input Spells (14)

These spells prompt users for input and require input stubbing or environment variable overrides:

1. `spells/cantrips/ask-number` - Prompts for numeric input
2. `spells/cantrips/ask-yn` - Prompts for yes/no
3. `spells/.arcana/bitcoin/configure-bitcoin`
4. `spells/.arcana/bitcoin/install-bitcoin`
5. `spells/.arcana/bitcoin/repair-bitcoin-permissions`
6. `spells/.arcana/bitcoin/uninstall-bitcoin`
7. `spells/.arcana/core/install-core`
8. `spells/.arcana/core/uninstall-core`
9. `spells/.arcana/lightning/install-lightning`
10. `spells/.arcana/node/install-node`
11. `spells/.arcana/node/uninstall-node`
12. `spells/.arcana/import-arcanum`
13. `spells/.arcana/mud/install-mud`
14. Various configure-* and install-* spells

**Testing**: Use environment variables (e.g., `ASK_CANTRIP_INPUT`) or stdin redirection to provide input. See `.tests/cantrips/test-ask-*.sh` for examples.

### Interactive Editors (4)

These spells have complex interactive editing operations:

1. `spells/spellcraft/disenchant` - Interactive file attribute editor
2. `spells/spellcraft/erase-spell` - Delete spell with confirmation
3. `spells/spellcraft/scribe-spell` - Create new spell interactively
4. `spells/arcane/jump-trash` - Interactive directory navigation and trash management

**Testing**: These require careful stubbing of both terminal I/O and user input. They may use read operations, menu systems, or custom input handling.

### System and Utility Spells (18)

These spells have interactive components or can hang if error handling is incorrect:

1. `spells/arcane/trash` - Move files to trash (can hang on usage errors)
2. `spells/.arcana/mud/handle-command-not-found` - Interactive command suggestions
3. `spells/.arcana/core/core-status` - May have interactive prompts
4. Various system configuration spells

**Testing**: These may not be fully interactive but can still hang if error handling is incorrect in conditional blocks. Ensure all die/fail/usage-error calls in conditional contexts use `|| return 1`.

## Reusable Stub Imps

Located in `spells/.imps/test/stub-*`:

- `stub-await-keypress` - Returns "enter" for keypresses
- `stub-fathom-cursor` - Mock cursor position detection  
- `stub-fathom-terminal` - Mock terminal size detection
- `stub-move-cursor` - Mock cursor movement (no-op)
- `stub-cursor-blink` - Mock cursor visibility control
- `stub-stty` - Mock terminal settings

**Usage in tests**:
```sh
# Create symlink directory
stub_dir="$tmpdir/stubs"
mkdir -p "$stub_dir"

# Link to reusable stub imps
for stub in await-keypress fathom-cursor fathom-terminal; do
  ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
done

# Run with stubs in PATH
PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:...:$PATH" \
  run_spell "spells/cantrips/menu"
```

## Fixed Spells

These spells have been fixed to prevent hanging:

1. `menu` - 4 die calls fixed (commit 01f3c09)
2. `ask-number` - 4 die calls fixed (commit 01f3c09)
3. `erase-spell` - 4 calls fixed (commit a669489)
4. `scribe-spell` - 27 fail calls fixed (commit a669489)
5. `trash` - 2 usage-error calls fixed

**Total**: 39 error calls fixed across 5 spells

## Testing Philosophy

- ✅ Stub the bare minimum (terminal I/O + interactive input layer only)
- ✅ Test real wizardry (use actual spells and imps, not mocks)
- ✅ Reusable stubs (create stub imps in `spells/.imps/test/`, not inline scripts)
- ✅ Fix root causes (add `|| return 1`, don't mask with timeouts or test-specific code)
- ❌ No test-specific code in spells (violates clean code principles)
- ❌ No timeout reliance (proper stubbing prevents hangs)

## References

- `.github/instructions/tests.instructions.md` - Stub imp usage guide
- `.github/instructions/testing-environment.md` - Interactive testing patterns
- `.github/instructions/imps.instructions.md` - Stub imp prefix policy
- `EXEMPTIONS.md` - Documented exemptions including stub imp --flags usage

## Summary

This project contains **53+ interactive spells** that require special testing considerations. The key to preventing test hangs is:

1. Understand that `set -e` is disabled in conditional contexts
2. Always add `|| return 1` after error functions in conditional blocks
3. Stub only the minimum necessary (terminal I/O + input layer)
4. Test real wizardry, not mocked implementations
5. Never add test-specific code to spells

When in doubt, check how menu, ask-number, erase-spell, scribe-spell, and trash were fixed as reference patterns.
