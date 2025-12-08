# Skip-If-Compiled Test Analysis Report

## Executive Summary

This report analyzes all scripts with `skip-if-compiled` subtests in the wizardry repository. The doppelganger compilation system passes tests, but only because we're skipping many tests. This analysis identifies which scripts have the most skipped tests, categorizes the reasons for skipping, and provides specific recommendations for improving the system to reduce the number of skipped tests.

## Overview

- **Total skip-if-compiled occurrences:** 383 across all test files
- **Test files affected:** 50+ main spell tests and imp tests
- **Main categories of skips:**
  - Help output tests (22 files)
  - PATH manipulation/stub dependencies (10 files)
  - Sourcing behavior (6 files)
  - Empty string handling (3 files)
  - Terminal environment (2 files)

## Top 10 Most Useful Scripts (Ranked by Utility × Skip Count)

### 1. learn-spellbook (spellcraft)

**File:** `.tests/spellcraft/test-learn-spellbook.sh`  
**Skip count:** 3 / 18 tests  
**Utility Score:** 10 (development tool)

**Why tests fail when compiled:**
- **--help flag**: Test checks that `--help` displays usage information. Compiled spells may not preserve the exact help output format.

**Recommendations:**
- Ensure compile-spell preserves `show_usage()` functions exactly
- All 3 skipped tests could likely pass with proper help preservation

---

### 2. update-all (system)

**File:** `.tests/system/test-update-all.sh`  
**Skip count:** 8 / 9 tests  
**Utility Score:** 9 (system management)

**Why tests fail when compiled:**
- **--help flag**: Help text verification
- **Stub dependencies**: Tests create stub commands (apt, pkg-install) to verify dependency checking. Compiled spell inlines these, so stubs are never called.
- **Wizardry environment**: Some tests rely on ROOT_DIR or wizardry installation paths

**Recommendations:**
- Fix help preservation (1 test)
- Add environment variable overrides for package managers (5-6 tests)
- Some tests may legitimately need to remain skip-if-compiled

---

### 3. update-wizardry (system)

**File:** `.tests/system/test-update-wizardry.sh`  
**Skip count:** 4 / 8 tests  
**Utility Score:** 9 (system management)

**Why tests fail when compiled:**
- **Stub dependencies**: Tests stub `git` and `require-command` to test error paths
- **Wizardry environment**: This spell specifically updates the wizardry installation, so needs WIZARDRY_DIR

**Recommendations:**
- This spell may legitimately need wizardry context
- Consider if it should be marked COMPILED_UNSUPPORTED at the file level
- It's an infrastructure spell that doesn't make sense as standalone

---

### 4. main-menu (menu)

**File:** `.tests/menu/test-main-menu.sh`  
**Skip count:** 8 / 10 tests  
**Utility Score:** 4 (UI)

**Why tests fail when compiled:**
- **PATH manipulation**: Tests stub `menu` and `require-command` commands
- **Wizardry environment**: Tests verify menu entries point to wizardry spells

**Recommendations:**
- Menu spells are part of wizardry infrastructure
- These tests should probably remain skip-if-compiled
- Consider COMPILED_UNSUPPORTED marking for menu category

---

### 5. look (mud)

**File:** `.tests/mud/test-look.sh`  
**Skip count:** 10 / 11 tests  
**Utility Score:** 3 (theme/fun)

**Why tests fail when compiled:**
- **Stub dependencies**: All 10 tests stub `read-magic` to test different scenarios
- **Already has override**: Uses DETECT_MAGIC_READ_MAGIC but not consistently

**Recommendations:**
- Already has the right pattern with environment override
- Extend this pattern to all tests
- Could remove 8-9 skip-if-compiled calls

---

### 6. install-menu (menu)

**File:** `.tests/menu/test-install-menu.sh`  
**Skip count:** 7 / 8 tests  
**Utility Score:** 4 (UI)

**Why tests fail when compiled:**
- **Wizardry environment**: Tests rely on ROOT_DIR to find install scripts
- **Infrastructure spell**: Part of wizardry installation system

**Recommendations:**
- This is an infrastructure spell
- Tests should remain skip-if-compiled
- Consider COMPILED_UNSUPPORTED at file level

---

### 7. detect-magic (divination)

**File:** `.tests/divination/test-detect-magic.sh`  
**Skip count:** 4 / 11 tests  
**Utility Score:** 7 (useful inspection)

**Why tests fail when compiled:**
- **Stub dependencies**: Tests stub `read-magic` command
- **Already has override**: Uses DETECT_MAGIC_READ_MAGIC environment variable

**Recommendations:**
- Already has the right pattern!
- Tests should be able to pass with environment override
- Could remove all 4 skip-if-compiled calls

---

### 8. jump-trash (arcane)

**File:** `.tests/arcane/test-jump-trash.sh`  
**Skip count:** 4 / 6 tests  
**Utility Score:** 7 (useful core feature)

**Why tests fail when compiled:**
- **--help flag**: Help text verification
- **Sourcing behavior**: Tests that source the spell and call `jump_trash` function
- **Wizardry environment**: Some tests use ROOT_DIR

**Recommendations:**
- Help test can be fixed (1 test)
- Sourcing tests should remain skip-if-compiled (legitimate limitation)
- 1-2 tests could potentially be fixed

---

### 9. spell-menu (menu)

**File:** `.tests/menu/test-spell-menu.sh`  
**Skip count:** 6 / 6 tests  
**Utility Score:** 4 (UI)

**Why tests fail when compiled:**
- **Stub dependencies**: Tests stub `memorize` command
- **Wizardry environment**: All tests rely on wizardry infrastructure

**Recommendations:**
- Infrastructure spell that depends on memorization system
- Tests should remain skip-if-compiled
- Consider COMPILED_UNSUPPORTED at file level

---

### 10. compile-spell (spellcraft)

**File:** `.tests/spellcraft/test-compile-spell.sh`  
**Skip count:** 2 / 4 tests  
**Utility Score:** 10 (development tool)

**Why tests fail when compiled:**
- **--help flag**: Help text verification
- **Self-compilation**: One test compiles compile-spell itself (meta!)

**Recommendations:**
- Help test can be fixed (1 test)
- Self-compilation test is legitimately complex
- Could remove 1 skip-if-compiled call

---

## Analysis of Failure Patterns

### Pattern 1: Help Flag Tests (22 files, HIGH PRIORITY)

**Problem:** Many tests check `--help` output, but compiled spells may not preserve exact help behavior.

**Root Cause:** The compile-spell process may not preserve help handling correctly, or help text gets modified during compilation.

**Why This Matters:** Help flags are a basic feature - users expect `--help` to work on compiled spells.

**Recommendation:** 
- Verify compile-spell preserves `show_usage()` functions exactly
- Test that compiled spells respond correctly to `--help`, `--usage`, and `-h`
- This should be a compiler bug fix, not a test limitation

**Potential Impact:** Could remove ~22-30 skip-if-compiled calls

---

### Pattern 2: Stub Dependency Tests (10+ files, HIGH PRIORITY)

**Problem:** Tests create stub commands in PATH to test error handling. Compiled spells inline dependencies, making stubs unreachable.

**Root Cause:** compile-spell inlines all detected dependencies. This is correct for distribution but makes testing difficult.

**Why This Matters:** We need to test error paths and alternative behaviors.

**Recommendation:**
- Use environment variable overrides (like DETECT_MAGIC_READ_MAGIC)
- Pattern: `SPELL_NAME_DEPENDENCY_CMD` environment variables
- Already done for some spells - extend to others
- Keep truly interactive commands external (ask-yn, read-line, etc.) - already done

**Potential Impact:** Could remove ~20-30 skip-if-compiled calls

---

### Pattern 3: Sourcing Tests (6 files, LOW PRIORITY - LEGITIMATE)

**Problem:** Tests source spells as shell functions. Compiled spells are standalone executables.

**Root Cause:** Sourcing is fundamentally incompatible with standalone compilation.

**Why This Matters:** Some spells (like jump-trash) are designed to be sourced to change the current shell's directory.

**Recommendation:**
- These tests should remain skip-if-compiled - this is a legitimate limitation
- Document which spells support sourcing vs. standalone execution
- Users need to know which spells require sourcing

**Potential Impact:** These ~10-15 skips are legitimate and should remain

---

### Pattern 4: Wizardry Environment Tests (Multiple files, MEDIUM PRIORITY)

**Problem:** Tests rely on WIZARDRY_DIR, ROOT_DIR, or other wizardry installation paths.

**Root Cause:** Some spells are infrastructure tools that genuinely need wizardry context. Others just use it for testing convenience.

**Why This Matters:** Distinguishes between spells that should be standalone vs. infrastructure-only.

**Recommendation:**
- **Infrastructure spells** (update-wizardry, install-menu, spell-menu): Mark COMPILED_UNSUPPORTED at file level
- **Refactorable spells**: Remove dependency on wizardry paths
- Use relative paths or detection logic where possible

**Potential Impact:** 
- ~20-30 legitimate infrastructure skips (should stay)
- ~10-15 unnecessary skips that could be fixed

---

### Pattern 5: Empty String/Argument Tests (3 files, HIGH PRIORITY)

**Problem:** Tests verify behavior with empty string arguments (`""`). May fail due to compilation differences.

**Root Cause:** Argument parsing in compiled vs. source form may differ.

**Why This Matters:** Empty argument handling is basic validation that should work everywhere.

**Recommendation:**
- Ensure compile-spell preserves argument validation logic exactly
- Test compiled spells with empty arguments explicitly
- This is likely a compiler bug

**Potential Impact:** Could remove ~5-10 skip-if-compiled calls

---

### Pattern 6: Terminal Environment Tests (2 files, MEDIUM PRIORITY)

**Problem:** Tests manipulate TERM variable to test terminal capability detection.

**Root Cause:** Compiled spells may inline terminal detection code differently.

**Why This Matters:** Spells should handle different terminals correctly.

**Recommendation:**
- Ensure terminal detection code is preserved correctly when inlined
- Test compiled spells with TERM=dumb, TERM=xterm, etc.
- Source of colors imp should compile correctly

**Potential Impact:** Could remove ~5 skip-if-compiled calls

---

## Recommendations Summary

### High Priority (Can significantly reduce skips)

#### 1. Fix --help Preservation (22 files affected)

**Action Items:**
- [ ] Verify compile-spell preserves `show_usage()` functions
- [ ] Test that `--help`, `--usage`, `-h` all work
- [ ] Add compiler tests for help flag handling
- [ ] Document expected behavior

**Estimated Impact:** Remove 22-30 skip-if-compiled calls  
**Effort:** Medium (compiler fix)

---

#### 2. Add Environment Variable Overrides (10+ files affected)

**Action Items:**
- [ ] Document pattern: `SPELL_NAME_DEPENDENCY_CMD` for testability
- [ ] Add overrides to spells that call external commands
- [ ] Update tests to use overrides instead of PATH stubs
- [ ] Examples: DETECT_MAGIC_READ_MAGIC (already done)

**Estimated Impact:** Remove 20-30 skip-if-compiled calls  
**Effort:** Low-Medium (pattern already exists)

---

#### 3. Fix Empty Argument Handling (3+ files affected)

**Action Items:**
- [ ] Test compile-spell with empty string arguments
- [ ] Verify argument validation is preserved
- [ ] Add explicit compiler tests for edge cases

**Estimated Impact:** Remove 5-10 skip-if-compiled calls  
**Effort:** Low (likely simple fix)

---

### Medium Priority (Moderate improvement)

#### 4. Clarify Infrastructure vs. Standalone Spells (Multiple files)

**Action Items:**
- [ ] Mark infrastructure spells as COMPILED_UNSUPPORTED at file level
  - [ ] install-menu
  - [ ] spell-menu
  - [ ] main-menu
  - [ ] update-wizardry (maybe)
  - [ ] Other menu/ spells
- [ ] Refactor spells that shouldn't need wizardry paths
- [ ] Document which spells are infrastructure-only

**Estimated Impact:** Clarify 20-30 legitimate skips vs. 10-15 fixable ones  
**Effort:** Medium (requires design decisions)

---

#### 5. Improve Terminal Environment Handling (2 files)

**Action Items:**
- [ ] Test colors imp compilation
- [ ] Verify TERM-based detection works correctly
- [ ] Test with dumb, xterm, xterm-256color

**Estimated Impact:** Remove ~5 skip-if-compiled calls  
**Effort:** Low-Medium

---

### Low Priority (Legitimate limitations)

#### 6. Document Sourcing Limitations

**Action Items:**
- [ ] Document which spells require sourcing (jump-trash, etc.)
- [ ] Keep these tests as skip-if-compiled
- [ ] Add user documentation about sourcing vs. standalone

**Estimated Impact:** Clarify ~10-15 legitimate skips  
**Effort:** Low (documentation only)

---

## Estimated Overall Impact

**Current State:**
- Total skip-if-compiled: ~383 occurrences
- Main spell tests: ~200 skips
- Imp tests: ~180 skips

**Potential Reduction:**
- High priority fixes: 50-70 skips removed (13-18% improvement)
- Medium priority fixes: 15-25 additional skips removed (4-7% improvement)
- **Total potential:** 65-95 skips removed (~17-25% improvement)

**Remaining Legitimate Skips:**
- Sourcing tests: ~10-15 skips
- Infrastructure spells: ~20-30 skips
- Other legitimate limitations: ~10-20 skips
- **Total legitimate:** ~40-65 skips

**Final Target:** ~290-320 skip-if-compiled occurrences after fixes

---

## Implementation Priority

### Phase 1: Quick Wins (High Priority)
1. Fix --help flag handling in compile-spell
2. Add environment variable overrides to 5-10 high-value spells
3. Fix empty argument handling

**Timeline:** 1-2 weeks  
**Impact:** 50-70 fewer skips

### Phase 2: Infrastructure Clarity (Medium Priority)
1. Mark infrastructure spells as COMPILED_UNSUPPORTED
2. Refactor spells that don't need wizardry paths
3. Fix terminal environment handling

**Timeline:** 2-3 weeks  
**Impact:** 15-25 fewer skips + better organization

### Phase 3: Documentation (Low Priority)
1. Document sourcing requirements
2. Update COMPILED-TESTING.md with patterns
3. Add developer guide for testable compilation

**Timeline:** 1 week  
**Impact:** Better clarity, no skip reduction

---

## Testing Strategy

For each fix:

1. **Identify affected tests:** Find all tests with specific pattern
2. **Fix the root cause:** Update compile-spell or spell code
3. **Verify compiled behavior:** Manually test compiled spell
4. **Remove skip-if-compiled:** Update test to run in both modes
5. **Run both test modes:** Verify tests pass compiled and uncompiled
6. **Document pattern:** Update guidelines for future spells

---

## Conclusion

The doppelganger system is functional but overly conservative with skipped tests. By addressing the high-priority issues (help flags, environment overrides, argument handling), we can significantly reduce the number of skipped tests while maintaining test coverage.

The key insight is distinguishing between:
- **Fixable issues:** Compiler bugs or missing features (60-90 skips)
- **Legitimate limitations:** Sourcing, infrastructure spells (40-65 skips)

With focused effort on the fixable issues, we can achieve 17-25% fewer skips and have much better confidence in the doppelganger system.
