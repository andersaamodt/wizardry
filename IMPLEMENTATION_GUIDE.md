# Parallel Test Execution - Implementation Guide

This document provides concrete steps to implement parallel test execution for the macOS test suite.

## Quick Reference

**Goal**: Reduce macOS test time from ~10 minutes to ~2 minutes
**Method**: Split tests into 5 parallel shards using GitHub Actions matrix strategy
**Changes**: Single workflow file modification (`.github/workflows/tests.yml`)
**Risk**: Low (workflow-only, easy rollback)

## Step-by-Step Implementation

### Step 1: Profile Current Test Suite

Before creating shards, measure actual test durations to balance workload.

```bash
# Run test suite with timing
cd /home/runner/work/wizardry/wizardry

# Method 1: Time entire suite
time ./spells/system/test-magic --verbose 2>&1 | tee /tmp/test-profile.log

# Method 2: Time individual categories (more useful for balancing)
for pattern in "cantrips/*" "menu/*" ".imps/test/*" ".imps/sys/*" \
               ".imps/out/*" ".imps/fs/*" "spellcraft/*" "system/*"; do
  echo "=== Testing $pattern ==="
  time ./spells/system/test-magic --only "$pattern" 2>&1 | tee -a /tmp/test-profile.log
done

# Analyze results
grep "^real" /tmp/test-profile.log
```

**Expected output** (example):
```
cantrips/*: real 1m45s
menu/*: real 2m10s
.imps/test/*: real 2m30s
.imps/sys/*: real 1m20s
...
```

### Step 2: Design Balanced Shards

Based on profiling data, create 5 shards with roughly equal duration.

**Proposed shard distribution** (adjust based on actual profiling):

```yaml
# Shard 1: ~2 minutes (user interaction spells)
pattern: "cantrips/* priorities/*"
tests: 39 (35 cantrips + 4 priorities)

# Shard 2: ~2.5 minutes (menu + test infrastructure)
pattern: "menu/* .imps/test/*"
tests: 66 (22 menu + 44 .imps/test)

# Shard 3: ~2 minutes (system imps)
pattern: ".imps/sys/* .imps/out/* .imps/pkg/*"
tests: 51 (26 sys + 19 out + 6 pkg)

# Shard 4: ~2 minutes (filesystem and text)
pattern: ".imps/fs/* .imps/text/* .imps/cond/*"
tests: 49 (17 fs + 16 text + 16 cond)

# Shard 5: ~2.5 minutes (everything else)
pattern: "*"  # All remaining tests
tests: ~176 (but excludes tests from shards 1-4 due to --only flag)
```

**Note**: Shard 5 uses wildcard pattern but won't re-run tests from other shards because each shard is independent.

### Step 3: Update Workflow Configuration

Edit `.github/workflows/tests.yml` to add matrix strategy for macOS.

**Before** (current sequential approach):
```yaml
aab-macos:
  name: macOS unit tests
  runs-on: macos-latest
  env:
    WIZARDRY_OS_LABEL: mac
  steps:
    - name: Checkout
      uses: actions/checkout@v4
    - name: Ensure installer spells are executable
      run: chmod +x spells/.arcana/mud/install-mud spells/.arcana/tor/setup-tor spells/.imps/fs/xattr-helper-usable spells/.imps/fs/xattr-list-keys spells/.imps/fs/xattr-read-value
    - name: Run unit tests
      run: ./spells/system/test-magic --verbose
```

**After** (parallel execution):
```yaml
aab-macos:
  name: macOS unit tests (shard ${{ matrix.shard.id }}/5)
  runs-on: macos-latest
  env:
    WIZARDRY_OS_LABEL: mac
  strategy:
    fail-fast: false  # Don't cancel other shards if one fails
    matrix:
      shard:
        - id: 1
          name: "User Interaction"
          patterns: "cantrips/* priorities/* wards/* enchant/*"
        - id: 2
          name: "Menu & Test Infrastructure"
          patterns: "menu/* .imps/test/*"
        - id: 3
          name: "System & Output Imps"
          patterns: ".imps/sys/* .imps/out/* .imps/pkg/*"
        - id: 4
          name: "Filesystem & Text"
          patterns: ".imps/fs/* .imps/text/* .imps/cond/*"
        - id: 5
          name: "Remaining Tests"
          patterns: "spellcraft/* system/* arcane/* translocation/* crypto/* divination/* mud/* psi/* .imps/str/* .imps/lex/* .imps/input/* .imps/paths/* .arcana/*"
  steps:
    - name: Checkout
      uses: actions/checkout@v4
    
    - name: Ensure installer spells are executable
      run: chmod +x spells/.arcana/mud/install-mud spells/.arcana/tor/setup-tor spells/.imps/fs/xattr-helper-usable spells/.imps/fs/xattr-list-keys spells/.imps/fs/xattr-read-value
    
    - name: Run test shard ${{ matrix.shard.id }} (${{ matrix.shard.name }})
      run: |
        echo "=== Running shard ${{ matrix.shard.id }}: ${{ matrix.shard.name }} ==="
        echo "Patterns: ${{ matrix.shard.patterns }}"
        
        # Run test-magic with --only for each pattern in this shard
        exit_code=0
        for pattern in ${{ matrix.shard.patterns }}; do
          echo ""
          echo "Testing pattern: $pattern"
          if ! ./spells/system/test-magic --only "$pattern" --verbose; then
            echo "FAILED: Pattern $pattern"
            exit_code=1
          fi
        done
        
        exit $exit_code
```

### Step 4: Alternative Simpler Approach (Recommended)

For easier maintenance, use a simpler pattern without loops:

```yaml
aab-macos:
  name: macOS tests (shard ${{ matrix.shard }}/5)
  runs-on: macos-latest
  env:
    WIZARDRY_OS_LABEL: mac
  strategy:
    fail-fast: false
    matrix:
      include:
        - shard: 1
          pattern: "cantrips/*"
        - shard: 2  
          pattern: "menu/*"
        - shard: 3
          pattern: ".imps/*"
        - shard: 4
          pattern: "spellcraft/* system/* arcane/*"
        - shard: 5
          pattern: "translocation/* crypto/* divination/* mud/* psi/* priorities/* wards/* enchant/* .arcana/*"
  steps:
    - name: Checkout
      uses: actions/checkout@v4
    
    - name: Ensure installer spells are executable
      run: chmod +x spells/.arcana/mud/install-mud spells/.arcana/tor/setup-tor spells/.imps/fs/xattr-helper-usable spells/.imps/fs/xattr-list-keys spells/.imps/fs/xattr-read-value
    
    - name: Run test shard ${{ matrix.shard }}
      run: ./spells/system/test-magic --only "${{ matrix.pattern }}" --verbose
```

**Important**: `test-magic --only` supports multiple patterns. When you pass multiple patterns separated by spaces, it will run all matching tests.

### Step 5: Test Locally

Before pushing, verify the shard patterns work correctly:

```bash
# Test each shard pattern locally
./spells/system/test-magic --only "cantrips/*" --verbose
./spells/system/test-magic --only "menu/*" --verbose  
./spells/system/test-magic --only ".imps/*" --verbose
./spells/system/test-magic --only "spellcraft/* system/* arcane/*" --verbose
./spells/system/test-magic --only "translocation/* crypto/* divination/* mud/* psi/* priorities/* wards/* enchant/* .arcana/*" --verbose

# Verify no tests are missed or duplicated
# Run all shards and count total tests
```

### Step 6: Validate Coverage

Ensure all tests are covered by at least one shard:

```bash
#!/bin/sh
# validation script (run locally)

total_tests=$(./spells/system/test-magic --list | wc -l)
echo "Total tests: $total_tests"

# Count tests in each shard
shard1=$(./spells/system/test-magic --list --only "cantrips/*" | wc -l)
shard2=$(./spells/system/test-magic --list --only "menu/*" | wc -l)
shard3=$(./spells/system/test-magic --list --only ".imps/*" | wc -l)
shard4=$(./spells/system/test-magic --list --only "spellcraft/* system/* arcane/*" | wc -l)
shard5=$(./spells/system/test-magic --list --only "translocation/* crypto/* divination/* mud/* psi/* priorities/* wards/* enchant/* .arcana/*" | wc -l)

shard_total=$((shard1 + shard2 + shard3 + shard4 + shard5))
echo "Shard 1: $shard1"
echo "Shard 2: $shard2"
echo "Shard 3: $shard3"
echo "Shard 4: $shard4"
echo "Shard 5: $shard5"
echo "Shard total: $shard_total"

if [ "$shard_total" -ne "$total_tests" ]; then
  echo "ERROR: Mismatch! Some tests missing or duplicated."
  exit 1
else
  echo "SUCCESS: All tests covered exactly once."
fi
```

### Step 7: Deploy and Monitor

1. **Create feature branch**:
   ```bash
   git checkout -b optimize/parallel-macos-tests
   git add .github/workflows/tests.yml
   git commit -m "Parallelize macOS tests into 5 shards"
   git push
   ```

2. **Open PR** and observe first CI run

3. **Monitor shard durations**:
   - Check GitHub Actions UI for actual times
   - Verify all shards complete in <3 minutes
   - Look for any shard significantly slower than others

4. **Adjust if needed**:
   - If one shard is much slower, rebalance
   - If all shards are fast, consider reducing to 3-4 shards

### Step 8: Extend to Other Platforms (Optional)

If successful on macOS, apply same strategy to other slow platforms:

```yaml
# Ubuntu example (if needed)
ubuntu:
  name: Ubuntu tests (shard ${{ matrix.shard }}/5)
  runs-on: ubuntu-latest
  strategy:
    fail-fast: false
    matrix:
      include:
        - shard: 1
          pattern: "cantrips/*"
        # ... same as macOS ...
```

**Note**: Only parallelize platforms that are actually slow (>5 minutes). Fast platforms (<2 minutes) don't benefit from parallelization.

## Troubleshooting

### Problem: Shard Imbalance

**Symptom**: One shard takes 5 minutes, others complete in 1 minute.

**Solution**: Rebalance by moving categories between shards.

```yaml
# Before (imbalanced)
- shard: 3
  pattern: ".imps/*"  # Too many tests

# After (balanced)  
- shard: 3
  pattern: ".imps/sys/* .imps/out/*"
  
# Add new shard 6
- shard: 6
  pattern: ".imps/fs/* .imps/text/* .imps/cond/*"
```

### Problem: Tests Run Multiple Times

**Symptom**: Total test count across shards exceeds actual test count.

**Solution**: Ensure patterns don't overlap.

```yaml
# Wrong (overlap)
- shard: 1
  pattern: "cantrips/*"
- shard: 2
  pattern: "*"  # This includes cantrips too!

# Correct (no overlap)
- shard: 1
  pattern: "cantrips/*"
- shard: 2  
  pattern: "menu/* spellcraft/* system/*"  # Explicit patterns
```

### Problem: Some Tests Never Run

**Symptom**: Total test count across shards is less than actual test count.

**Solution**: Add catch-all shard or enumerate all categories.

```yaml
# Add catch-all as last shard
- shard: 5
  pattern: "*"  # Catches anything not in shards 1-4
```

**Note**: This only works if previous shards use `--only` (they run independently).

### Problem: Shard Failures Are Hard to Debug

**Symptom**: Failure in "Shard 3" isn't specific enough.

**Solution**: Add descriptive names and better logging.

```yaml
matrix:
  include:
    - shard: 3
      name: "Filesystem & System Imps"
      pattern: ".imps/fs/* .imps/sys/*"

steps:
  - name: Run ${{ matrix.name }} (shard ${{ matrix.shard }})
    run: |
      echo "=== Shard ${{ matrix.shard }}: ${{ matrix.name }} ==="
      echo "Pattern: ${{ matrix.pattern }}"
      ./spells/system/test-magic --only "${{ matrix.pattern }}" --verbose
```

## Performance Tuning

### Optimize Shard Count

**Too few shards** (2-3):
- ✅ Less overhead
- ❌ Limited speedup

**Too many shards** (10+):
- ❌ More overhead  
- ❌ Diminishing returns
- ❌ More complex to maintain

**Sweet spot** (4-6):
- ✅ Good speedup
- ✅ Manageable complexity
- ✅ Easy to balance

**Recommendation**: Start with 5, adjust based on results.

### Reduce Per-Shard Overhead

Each shard has setup overhead (checkout, chmod, etc.). Minimize:

```yaml
# Cache dependencies if any
- name: Cache test setup
  uses: actions/cache@v3
  with:
    path: ~/.cache/wizardry
    key: ${{ runner.os }}-test

# Combine setup steps
- name: Setup
  run: |
    chmod +x spells/.arcana/mud/install-mud spells/.arcana/tor/setup-tor
    # Other setup...
```

### Consider Test Timeout Tuning

If tests are slow due to timeouts, reduce default:

```yaml
- name: Run tests with shorter timeout
  env:
    WIZARDRY_TEST_TIMEOUT: 120  # Default is 180
  run: ./spells/system/test-magic --only "${{ matrix.pattern }}" --verbose
```

## Monitoring Dashboard

Create a simple tracking document:

```markdown
# macOS Test Performance Tracking

## Week of 2024-12-22

### Shard Durations (PR #XXX)
- Shard 1: 1m 45s ✅
- Shard 2: 2m 30s ✅
- Shard 3: 1m 20s ✅
- Shard 4: 1m 55s ✅
- Shard 5: 2m 10s ✅

**Total wall-clock time**: 2m 30s (longest shard)
**Total CI minutes**: 9m 50s (sum of all shards)
**Improvement**: 75% faster (10m → 2.5m)

### Issues
- None

### Actions
- Consider merging shards 3 and 4 (both fast)
- Monitor shard 2 (slowest, but acceptable)
```

## Rollback Plan

If parallel execution causes problems:

```bash
# Revert workflow changes
git revert <commit-hash>
git push

# Or directly edit workflow to restore sequential execution
# Remove strategy/matrix, restore single job
```

**Time to rollback**: <5 minutes

## Success Criteria

After implementation, verify:

✅ All 5 shards complete in parallel
✅ Longest shard is <3 minutes
✅ Total wall-clock time <3 minutes  
✅ All tests still pass (same coverage)
✅ No flaky tests introduced
✅ Easy to understand in GitHub UI

## Next Steps

After successful implementation:

1. **Week 1**: Monitor and adjust shard balance
2. **Week 2**: Apply to other platforms if needed
3. **Week 3**: Consider performance optimizations
4. **Month 2**: Evaluate if further improvements needed (tiered testing)

## References

- GitHub Actions Matrix Strategy: https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs
- `test-magic --only` documentation: `./spells/system/test-magic --help`
- Workflow file: `.github/workflows/tests.yml`
