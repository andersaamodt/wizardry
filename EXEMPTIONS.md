# Test Function Exemptions

This document tracks all non-test functions (functions that don't start with `test_`) in the `.tests` directory. The goal is to progressively convert reusable stub creators into imps while documenting test-specific helpers that should remain as functions.

## Converted to Imps ✅

The following stub creator functions have been converted to imps in `spells/.imps/test/boot/`:

- `make_stub_menu` → `stub-menu` (was in 15 files)
- `make_stub_colors` → `stub-colors` (was in 6 files)
- `make_stub_exit_label` → `stub-exit-label` (was in 3 files)
- `make_stub_temp_file` → `stub-temp-file` (was in 1 file)
- `make_stub_cleanup_file` → `stub-cleanup-file` (was in 1 file)
- `make_stub_require` → `stub-require-command` (was in 9 files)
- `make_failing_menu` → `stub-failing-menu` (was in 3 files)
- `make_stub_bin` → `stub-bin-dir` (was in 2 files)

## Stub Creators (Should Become Imps)

These are duplicated stub creator functions that should be converted to imps:

### High Priority (6+ uses)
- **`write_stub_systemctl`** (6 uses) - in system/test-disable-service.sh, system/test-enable-service.sh, system/test-restart-service.sh, system/test-service-status.sh, system/test-start-service.sh, system/test-stop-service.sh
- **`write_stub_ask_text`** (6 uses) - in system/test-disable-service.sh, system/test-enable-service.sh, system/test-restart-service.sh, system/test-service-status.sh, system/test-start-service.sh, system/test-stop-service.sh
- **`create_xattr_stub`** (6 uses) - in .imps/mud/test-damage-file.sh, .imps/mud/test-get-life.sh, mud/test-lesser-heal.sh, mud/test-magic-missile.sh, mud/test-resurrect.sh, mud/test-stats.sh

### Medium Priority (3-5 uses)
- **`write_stub_sudo`** (5 uses) - in system/test-disable-service.sh, system/test-enable-service.sh, system/test-restart-service.sh, system/test-start-service.sh, system/test-stop-service.sh
- **`write_ask_text_stub`** (3 uses) - in system/test-install-service-template.sh, system/test-is-service-installed.sh, system/test-remove-service.sh

### Low Priority (2 uses)
- **`write_systemctl_stub`** (2 uses) - in system/test-install-service-template.sh, system/test-remove-service.sh
- **`write_require_command_stub`** (2 uses) - in menu/test-spell-menu.sh, menu/test-spellbook.sh
- **`write_memorize_command_stub`** (2 uses) - in menu/test-spell-menu.sh, menu/test-spellbook.sh
- **`make_status_stub`** (2 uses) - in .arcana/bitcoin/test-bitcoin-menu.sh, .arcana/bitcoin/test-wallet-menu.sh
- **`make_boolean_stub`** (2 uses) - in .arcana/bitcoin/test-bitcoin-menu.sh, .arcana/bitcoin/test-wallet-menu.sh
- **`make_failing_require`** (2 uses) - in menu/test-cast.sh, menu/test-main-menu.sh
- **`has_unit_section`** (2 uses) - in .arcana/bitcoin/test-bitcoin.service.sh, .arcana/tor/test-tor.service.sh
- **`has_service_section`** (2 uses) - in .arcana/bitcoin/test-bitcoin.service.sh, .arcana/tor/test-tor.service.sh
- **`has_install_section`** (2 uses) - in .arcana/bitcoin/test-bitcoin.service.sh, .arcana/tor/test-tor.service.sh

## Test-Specific Helpers (OK as Functions)

These functions are test-specific helpers with varying implementations or test logic. They should remain as functions within individual test files:

### Common Test Patterns (Highly Duplicated but Test-Specific)
- **`shows_help`** (79 uses) - Tests --help flag for various spells
- **`spell_has_content`** (54 uses) - Tests file has non-zero size
- **`spell_is_executable`** (51 uses) - Tests file is executable
- **`make_stub_dir`** (17 uses) - Creates temp directories (varying implementations)
- **`shows_usage_help`** (5 uses) - Tests --help usage output

### Test Utility Functions (2-4 uses)
- **`normalize_output`** (4 uses) - in .imps/menu/test-fathom-cursor.sh, .imps/menu/test-fathom-terminal.sh, .wizardry/test-spellbook-store.sh, cantrips/test-memorize.sh
- **`renders_usage_information`** (4 uses) - in .arcana/node tests
- **`wizardry_base_path`** (2 uses) - in mud/test-look.sh, translocation/test-jump-to-marker.sh
- **`tabbed`** (2 uses) - in .wizardry/test-spellbook-store.sh, cantrips/test-memorize.sh
- **`show_usage`** (2 uses) - in spellcraft/test-lint-magic.sh
- **`cast_env`** (2 uses) - in cantrips/test-memorize.sh, spellcraft/test-forget.sh
- **`run_memorize`** (2 uses) - in cantrips/test-memorize.sh, spellcraft/test-forget.sh
- **`rejects_invalid_args`** (2 uses) - in .wizardry/test-spellbook-store.sh, cantrips/test-memorize.sh
- **`prints_verbose_labels`** (2 uses) - in .imps/menu/test-fathom-cursor.sh, .imps/menu/test-fathom-terminal.sh

### Single-Use Test Functions (Not Listed Here)

All single-use functions (hundreds of them) are test case-specific implementations and should remain as-is. They are not included in this tracking document.

## Progress Tracking

**Total stub creators converted to imps:** 8  
**Remaining stub creators to convert:** ~20  
**Test-specific helpers (keep as functions):** ~150+

## Guidelines

### When to Create an Imp
- Function creates a stub/mock command or file
- Function is used in 2+ test files
- Function has consistent implementation across files

### When to Keep as Function
- Function tests specific spell behavior (shows_help, spell_has_content, etc.)
- Function has varying implementation by context
- Function is test case-specific logic
- Function is used in only 1 file

## See Also
- `.tests/common-tests.sh` - Contains the test that validates tests use imps for helpers
- `.github/imps.md` - Imp creation guidelines
- `.github/tests.md` - Test framework documentation
