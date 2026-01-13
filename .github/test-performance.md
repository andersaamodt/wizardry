# Test Performance Analysis

## Overview

This document analyzes the performance of the wizardry test suite and documents optimization efforts.

**Date**: 2025-12-22  
**Total Tests**: 381 test files  
**Full Suite Runtime**: ~10+ minutes (exceeds 10min timeout)

## Profiling Infrastructure

### New --profile Flag

Added `--profile` flag to `test-magic` spell to enable performance analysis:

```sh
./spells/system/test-magic --profile [--only PATTERN]
```

**Output includes**:
- Timing for each test execution
- Top 20 slowest tests
- Duration distribution (< 1s, 1-5s, 5-10s, 10-30s, > 30s)
- Total and average execution times

## Performance Findings

### Slowest Tests

| Test | Duration | Notes |
|------|----------|-------|
| `common-tests.sh` | ~64-66s | Structural checks across all 116 spells |
| `test-install.sh` | >120s | Installation testing with 44 test cases |
| `test-tutorials.sh` | Unknown | Not profiled yet |

### Fast Tests

Most individual spell tests complete in **< 1 second**.

Sample timings:
- `.imps/out/test-say.sh`: 0s
- `.imps/cond/test-has.sh`: 0s
- `arcane/test-forall.sh`: 0s
- `cantrips/test-ask-yn.sh`: 0-1s
- `crypto/test-hash.sh`: 0s

## Identified Bottlenecks

### 1. common-tests.sh (64s)

**What it does**: Runs 37 structural/behavioral checks across all spells
- No duplicate spell names
- Help handler standards
- Function discipline (4+ functions)
- Flag/argument limits  
- Variable naming conventions
- set -eu requirements
- And 30+ more checks

**Why it's slow**:
- Iterates over all 116 spell files multiple times
- Uses `find`, `grep`, `awk` extensively on each spell
- Already optimized with file list caching (line 86-93)

**Potential optimizations**:
- Combine multiple checks into single file traversal
- Pre-parse all files once, cache results
- Parallel processing of independent checks

### 2. test-install.sh (>120s)

**What it does**: Tests the main `install` script with 44 test cases

**Why it's slow**:
- Creates test fixtures for each test case
- May invoke external commands
- Complex installation logic testing

**Potential optimizations**:
- Reuse fixtures across tests
- Mock expensive operations
- Parallelize independent test cases

## Usage Examples

### Profile All Tests
```sh
./spells/system/test-magic --profile
```

### Profile Specific Category
```sh
./spells/system/test-magic --profile --only 'arcane/*'
```

### Profile Single Test
```sh
./spells/system/test-magic --profile --only 'common-tests.sh'
```

### Profile and Save Results
```sh
./spells/system/test-magic --profile 2>&1 | tee profile-$(date +%Y%m%d).txt
```

## References

- Profiling implementation: `spells/system/test-magic` lines 104-107, 243-253, 319-326
- Test exemption: `.github/EXEMPTIONS.md` (test-magic 4-flag exemption)
- Common tests optimization: `.tests/common-tests.sh` lines 86-93 (file list caching)
