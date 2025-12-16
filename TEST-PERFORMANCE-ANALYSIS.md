# Test Suite Performance Analysis

**Date:** December 16, 2024  
**Total Tests:** 354  
**Total Runtime:** 107.594 seconds (~1 minute 48 seconds)  
**Average Test Time:** 0.304 seconds

## Executive Summary

The wizardry test suite consists of 354 tests with significant performance variation. The top 3 tests account for approximately 60% of total test time:

1. **common-tests.sh** - 40.030s (37.2% of total time)
2. **test-install.sh** - 14.292s (13.3% of total time)
3. **spellcraft/test-doppelganger.sh** - 11.163s (10.4% of total time)

These three tests alone take **65.485 seconds out of 107.594 seconds total** (60.9%).

## Key Findings

### Performance Distribution

- **271 tests (76.6%)** complete in under 0.1 seconds (fast)
- **70 tests (19.8%)** take 0.1-0.5 seconds (acceptable)
- **4 tests (1.1%)** take 0.5-1.0 seconds (slow)
- **6 tests (1.7%)** take 1.0-5.0 seconds (very slow)
- **3 tests (0.8%)** take over 10 seconds (extremely slow)

### Slowest Tests (Top 20)

| Rank | Time (s) | Status | Test |
|------|----------|--------|------|
| 1 | 40.030 | PASS | common-tests.sh |
| 2 | 14.292 | FAIL | test-install.sh |
| 3 | 11.163 | PASS | spellcraft/test-doppelganger.sh |
| 4 | 3.081 | PASS | cantrips/test-logging-example.sh |
| 5 | 2.771 | PASS | system/test-verify-posix.sh |
| 6 | 2.046 | PASS | .imps/cond/test-newer.sh |
| 7 | 2.045 | PASS | .imps/cond/test-older.sh |
| 8 | 1.613 | PASS | system/test-test-magic.sh |
| 9 | 1.271 | PASS | spellcraft/test-lint-magic.sh |
| 10 | 0.808 | PASS | .imps/sys/test-invoke-wizardry.sh |
| 11 | 0.741 | PASS | cantrips/test-memorize.sh |
| 12 | 0.642 | PASS | divination/test-identify-room.sh |
| 13 | 0.569 | PASS | menu/test-mud-menu.sh |
| 14 | 0.409 | PASS | system/test-config.sh |
| 15 | 0.376 | PASS | .arcana/mud/test-toggle-all-mud.sh |
| 16 | 0.346 | PASS | mud/test-look.sh |
| 17 | 0.293 | PASS | menu/test-cast.sh |
| 18 | 0.273 | PASS | menu/test-install-menu.sh |
| 19 | 0.272 | PASS | translocation/test-mark-location.sh |
| 20 | 0.270 | PASS | psi/test-read-contact.sh |

## Analysis by Category

### Critical Performance Issues

#### 1. common-tests.sh (40.030s)

This is a structural test that validates cross-cutting concerns across all spells. It accounts for 37% of total test time.

**Likely causes:**
- Iterates through all spell files in the repository
- Performs multiple `find` operations across the entire spells/ directory
- Runs multiple validation checks per file
- May be doing redundant work

**Optimization opportunities:**
- Cache file listings rather than running multiple `find` operations
- Use parallel processing for independent checks
- Skip already-validated files when possible
- Consider splitting into smaller, more focused tests

#### 2. test-install.sh (14.292s, FAILED)

This test validates the wizardry installation process. It's both slow AND failing.

**Priority:** HIGH - Needs immediate attention for the failure, optimization secondary

**Likely causes:**
- Simulates full installation process
- May be creating/destroying directories
- Likely involves file I/O operations
- The failure suggests potential race conditions or cleanup issues

**Recommendations:**
1. Fix the test failure first
2. Use mocked/stubbed operations where possible
3. Consider splitting into unit tests vs integration tests
4. Cache common setup operations

#### 3. spellcraft/test-doppelganger.sh (11.163s)

Tests the doppelganger spell which likely involves code duplication detection.

**Note:** According to test-magic code, this test is normally skipped and "run via dedicated GitHub action" to avoid nearly doubling test run time. The profile ran it because no `--only` filter was used.

**Recommendation:**
- Keep current approach of running in separate CI job
- Document that it's intentionally excluded from normal test runs

### Moderate Performance Concerns

#### 4-9. Tests taking 1-3 seconds

These tests are individually reasonable but collectively add up:
- cantrips/test-logging-example.sh (3.081s)
- system/test-verify-posix.sh (2.771s)
- .imps/cond/test-newer.sh (2.046s)
- .imps/cond/test-older.sh (2.045s)
- system/test-test-magic.sh (1.613s)
- spellcraft/test-lint-magic.sh (1.271s)

**Common patterns:**
- Tests that validate code quality (verify-posix, lint-magic)
- Tests that check file timestamps (newer, older)
- Meta-tests that test the testing infrastructure (test-test-magic)

**Optimization opportunities:**
- The timestamp tests (newer/older) likely involve creating files and waiting - consider using touch with explicit timestamps instead of sleep
- Code quality checks might benefit from caching or incremental checks
- Consider if full integration tests are needed or if unit tests would suffice

## Optimization Recommendations

### Quick Wins (Low Effort, High Impact)

1. **Skip doppelganger by default** ✅ Already implemented in test-magic
   - Saves ~11 seconds per run
   - Keep in dedicated CI job

2. **Optimize common-tests.sh**
   - **Estimated savings:** 20-30 seconds
   - Cache file listings
   - Parallelize independent checks
   - Avoid redundant find operations

3. **Fix and optimize test-install.sh**
   - **Estimated savings:** 5-10 seconds
   - Fix the failure first
   - Mock expensive operations
   - Use temporary directories efficiently

### Medium-Term Improvements

1. **Parallelize test execution**
   - Current: sequential execution of 354 tests
   - Proposed: parallel execution with job pool
   - **Estimated savings:** 50-70% reduction with 4-8 parallel jobs
   - Would require: job control, output synchronization, shared resource locking

2. **Optimize file timestamp tests**
   - Tests: test-newer.sh, test-older.sh
   - Current: Likely using sleep or file operations
   - Proposed: Use touch with explicit timestamps
   - **Estimated savings:** 2-3 seconds

3. **Cache common test setup**
   - Many tests likely do similar setup (creating temp dirs, etc.)
   - Consider shared fixtures or cached test environments
   - **Estimated savings:** 5-10 seconds

### Long-Term Considerations

1. **Test categorization**
   - Unit tests (fast, isolated)
   - Integration tests (moderate speed, some dependencies)
   - System tests (slow, full integration)
   - Allow running different test suites based on need

2. **Incremental testing**
   - Only run tests for changed components
   - Full test suite for releases/merges
   - Would require: dependency tracking

3. **Test infrastructure improvements**
   - Consider a test framework that supports parallelization
   - Add test result caching
   - Implement smart test selection

## Current Status

The test suite is reasonably fast for its size:
- **Average test time: 0.304 seconds** is quite good
- **76.6% of tests complete in under 0.1 seconds** shows efficient test design
- **Total runtime of ~108 seconds** for 354 tests is manageable

However, there's significant opportunity for improvement:
- **Top 3 tests account for 60% of runtime**
- Optimizing these alone could reduce total time by 40-50%
- Parallelization could reduce total time by 50-70%

## Detailed Analysis of Slow Tests

### common-tests.sh (40 seconds)

This test file runs **19 structural validation tests** across the entire spellbook:
1. No duplicate spell names
2. Menu spells require menu command
3. Spells have standard help handlers
4. Warning about full paths to spells
5. Test files have matching spells
6. Tests rely only on imps for helpers
7. Scripts using declared globals have set -u
8. declare-globals has exactly 3 globals
9. No undeclared globals exported
10. No global declarations outside declare-globals
11. No pseudo-globals stored in rc files
12. Imps follow one-function-or-zero rule
13. Imps have opening comments
14. Bootstrap spells have identifying comment
15. Spells follow function discipline
16. No function name collisions
17. Spells have true name functions
18. Spells have limited flags
19. Spells have limited positional arguments

**Why it's slow:**
- Each test performs multiple `find` operations across `spells/` directory
- Many tests iterate through every spell file (hundreds of files)
- File content is read and parsed multiple times per spell
- No caching between tests - same files read repeatedly

**Performance breakdown (estimated):**
- File discovery (find operations): ~5-10s
- File reading and parsing: ~20-25s
- Validation logic: ~5-10s

**Key optimization opportunities:**
1. **Cache file list** - Run find once, use cached list for all tests
2. **Batch file processing** - Read each file once, run all applicable checks
3. **Parallelize independent checks** - Many tests are independent
4. **Use faster tools** - Consider using `fd` instead of `find` where available

### test-install.sh (14 seconds, FAILED)

This test validates the wizardry installation process. It includes:
- Full installation simulation in isolated fixtures
- NixOS configuration handling
- MUD feature installation
- Multiple installation scenarios (with/without MUD, different platforms)

**Why it's slow:**
- Creates complete test fixtures (file systems, tools, stubs)
- Runs the actual install script multiple times
- Involves file I/O, directory creation/deletion
- Tests interactive prompts (simulated input/output)

**Why it's failing:**
The test appears to hang during execution, likely due to:
- Waiting for input that isn't being provided
- A subprocess that doesn't complete
- Race condition in cleanup or setup

**Priority:** The failure needs investigation before optimization.

### spellcraft/test-doppelganger.sh (11 seconds)

Tests code duplication detection across the codebase.

**Current status:**
- Already excluded from regular test runs (test-magic skips it by default)
- Runs in dedicated GitHub Action to avoid doubling test suite time
- This is the correct approach - no changes needed

**Note:** The profile ran this test because no filter was applied. In normal CI/development workflow, this test is skipped.

## Immediate Action Items

1. ✅ **Profile created** - We now have baseline performance data
2. ✅ **Analysis complete** - Identified root causes of slow tests
3. 🔴 **Investigate test-install.sh failure** (HIGH PRIORITY)
   - Determine why test hangs
   - Fix or skip problematic test case
   - Re-run profile after fix
4. 🟡 **Optimize common-tests.sh** (HIGH IMPACT - saves ~20-30s)
   - Implement file list caching
   - Batch file processing
   - Consider parallelization
5. 🟢 **Document performance expectations** (set CI time budgets)
6. 🟢 **Add performance regression detection** (alert on significant slowdowns)

## Tools Added

**New Spell:** `spells/system/profile-tests`

This spell provides detailed performance profiling of the test suite:
- Times each test individually
- Generates sorted performance reports
- Shows distribution statistics
- Can filter by test pattern
- Outputs to file or stdout

**Usage:**
```bash
# Profile all tests
profile-tests

# Profile specific category
profile-tests --only "arcane/*"

# Save to file
profile-tests --output performance-report.txt
```

## Conclusion

The wizardry test suite has good baseline performance but significant optimization potential. The immediate focus should be:

1. **Fix failing test** (test-install.sh)
2. **Optimize the slowest test** (common-tests.sh - 40s)
3. **Consider parallelization** for long-term improvement

With these changes, we could reduce test suite time from ~108 seconds to:
- **~70-80 seconds** with optimizations (35% improvement)
- **~20-30 seconds** with parallelization (70-80% improvement)

The majority of tests (76.6%) are already fast, indicating good test design practices across the codebase.
