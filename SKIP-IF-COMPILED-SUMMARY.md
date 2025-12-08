# Skip-If-Compiled Analysis - Quick Summary

## Your Question
You asked for:
1. A list of the most useful scripts with skip-if-compiled subtests (ranked)
2. For the top 10, explain why the tests fail when compiled

## Answer

### Top 10 Most Useful Scripts (Ranked by Utility × Skip Count)

| Rank | Script | Category | Skips | Why Tests Fail |
|------|--------|----------|-------|----------------|
| 1 | learn-spellbook | spellcraft | 3/18 | --help flag not preserved |
| 2 | update-all | system | 8/9 | --help, stub deps, needs WIZARDRY_DIR |
| 3 | update-wizardry | system | 4/8 | Stubs git/require-command, needs WIZARDRY_DIR |
| 4 | main-menu | menu | 8/10 | PATH stubs, needs ROOT_DIR (infrastructure) |
| 5 | look | mud | 10/11 | Stubs read-magic (already has override pattern!) |
| 6 | install-menu | menu | 7/8 | Needs ROOT_DIR for install scripts (infrastructure) |
| 7 | detect-magic | divination | 4/11 | Stubs read-magic (already has override pattern!) |
| 8 | jump-trash | arcane | 4/6 | --help + sourcing (sourcing is legitimate limit) |
| 9 | spell-menu | menu | 6/6 | Stubs memorize, needs wizardry (infrastructure) |
| 10 | compile-spell | spellcraft | 2/4 | --help + self-compilation complexity |

### Detailed Reasons for Each

#### 1. learn-spellbook (spellcraft)
**Why it fails:** Tests check `--help` flag output. Compiled spells may not preserve help text correctly.
**Can we fix it?** YES - This is a compiler bug. Fix help preservation → remove all 3 skips.

#### 2. update-all (system)
**Why it fails:** 
- Help flag (1 test) - compiler bug
- Stubs package managers like apt, pkg-install (5-6 tests) - inlined dependencies
- Uses ROOT_DIR (2 tests) - needs wizardry paths

**Can we fix it?** MOSTLY - Fix help + add environment overrides → remove 6-7 skips.

#### 3. update-wizardry (system)
**Why it fails:** Stubs git and require-command. This spell updates wizardry itself.

**Can we fix it?** MAYBE NOT - Infrastructure spell that needs wizardry context. Should probably be COMPILED_UNSUPPORTED.

#### 4. main-menu (menu)
**Why it fails:** Stubs menu command, uses ROOT_DIR to find wizardry spells.

**Can we fix it?** NO - This is part of wizardry infrastructure. Should be COMPILED_UNSUPPORTED.

#### 5. look (mud)
**Why it fails:** All 10 tests stub the `read-magic` command to test different scenarios.

**Can we fix it?** YES! - Already has DETECT_MAGIC_READ_MAGIC override pattern. Extend to all tests → remove 8-9 skips.

#### 6. install-menu (menu)
**Why it fails:** Uses ROOT_DIR to find install scripts in wizardry.

**Can we fix it?** NO - Infrastructure spell. Should be COMPILED_UNSUPPORTED.

#### 7. detect-magic (divination)
**Why it fails:** Stubs read-magic command.

**Can we fix it?** YES! - Already has DETECT_MAGIC_READ_MAGIC override. Apply consistently → remove all 4 skips.

#### 8. jump-trash (arcane)
**Why it fails:** 
- Help flag (1 test) - compiler bug
- Sourcing tests (2 tests) - tests that spell can be sourced as function
- Uses ROOT_DIR (1 test)

**Can we fix it?** PARTIALLY - Fix help (1 skip). Sourcing is legitimate limitation (2 skips stay).

#### 9. spell-menu (menu)
**Why it fails:** Stubs memorize command, relies on wizardry memorization system.

**Can we fix it?** NO - Infrastructure spell dependent on wizardry. Should be COMPILED_UNSUPPORTED.

#### 10. compile-spell (spellcraft)
**Why it fails:** 
- Help flag (1 test) - compiler bug
- Self-compilation test (1 test) - meta complexity

**Can we fix it?** YES - Fix help (1 skip). Self-compilation is genuinely complex but might be doable.

## Big Picture: Can We Skip Fewer Tests?

**YES!** We can significantly reduce skips by fixing 3 main issues:

### Issue 1: --help Flag (22 files affected)
**Problem:** Compiled spells don't preserve help text correctly.

**Fix:** Update compile-spell to preserve `show_usage()` functions exactly.

**Impact:** Remove ~22-30 skips (HIGH PRIORITY)

### Issue 2: Stubbed Dependencies (10+ files affected)
**Problem:** Tests stub external commands, but compiled spells inline them.

**Fix:** Add environment variable overrides like DETECT_MAGIC_READ_MAGIC.

**Impact:** Remove ~20-30 skips (HIGH PRIORITY)

### Issue 3: Empty Argument Handling (3 files affected)
**Problem:** Compiled spells handle empty strings differently.

**Fix:** Preserve argument validation logic in compiler.

**Impact:** Remove ~5-10 skips (HIGH PRIORITY)

### Infrastructure Spells (Can't Fix)
**Problem:** Some spells (menu/, update-wizardry) need wizardry installation.

**Fix:** Mark these as COMPILED_UNSUPPORTED at file level.

**Impact:** Clarify ~20-30 legitimate skips (DOCUMENTATION)

### Sourcing Tests (Can't Fix)
**Problem:** Some tests source spells as functions. Compiled = executable.

**Fix:** None - this is a legitimate limitation.

**Impact:** ~10-15 legitimate skips (DOCUMENTATION)

## Overall Potential

**Current:** 383 skip-if-compiled occurrences

**Fixable:** 50-70 skips (13-18% improvement)

**Legitimate:** 40-65 skips (should stay)

**Target:** 290-320 skips after fixes

**Bottom Line:** With focused effort on help flags and environment overrides, we can remove 17-25% of skips and have much better confidence in compiled spells.

## See Full Report

Read `SKIP-IF-COMPILED-ANALYSIS.md` for:
- Detailed analysis of each script
- Specific code examples
- Implementation plan with phases
- Testing strategy
- Effort estimates
