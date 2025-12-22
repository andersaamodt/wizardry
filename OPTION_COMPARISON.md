# Test Optimization Options - Detailed Comparison

## Executive Summary

| Option | Speed Gain | CI Cost | Complexity | Risk | Recommendation |
|--------|-----------|---------|------------|------|----------------|
| **1. Parallel Execution** | ⭐⭐⭐⭐⭐ (3-4x) | +25% | Low | Low | ✅ **Primary** |
| **2. Tiered Testing** | ⭐⭐⭐⭐ (4-5x) | -50% | Medium | Medium | ⚠️ Secondary |
| **3. Hybrid (1+2)** | ⭐⭐⭐⭐⭐ (5-8x) | Neutral | High | Medium | 💡 Future |
| **4. Smart Selection** | ⭐⭐⭐⭐⭐⭐ (10x+) | -80% | Very High | High | ❌ Not recommended |
| **5. Performance Opt** | ⭐⭐ (1.2-1.5x) | Same | Medium | Low | ✅ Complementary |

## Detailed Time & Cost Analysis

### Current State: Sequential Testing
```
macOS Job (sequential):
├─ Test 1-76:   ~2 min  (cantrips, menu)
├─ Test 77-152: ~2 min  (.imps/test, .imps/sys)
├─ Test 153-228: ~2 min  (.imps/out, .imps/fs, .imps/text)
├─ Test 229-304: ~2 min  (spellcraft, system, arcane)
└─ Test 305-381: ~2 min  (remaining tests)
Total: 10 minutes wall-clock, 10 CI minutes
```

### Option 1: Parallel Execution (5 Shards)
```yaml
macOS Jobs (parallel):
├─ Shard 1: Tests 1-76    → 2 min wall-clock, 2 CI min
├─ Shard 2: Tests 77-152  → 2 min wall-clock, 2 CI min
├─ Shard 3: Tests 153-228 → 2 min wall-clock, 2 CI min
├─ Shard 4: Tests 229-304 → 2 min wall-clock, 2 CI min
└─ Shard 5: Tests 305-381 → 2 min wall-clock, 2 CI min
Total: 2 minutes wall-clock, 10 CI minutes
Wait time: -80% ⭐⭐⭐⭐⭐
CI cost: 0% (same total minutes)
```

**Actual numbers** (if shards run truly parallel):
- **Before**: 10 min wait
- **After**: 2 min wait (longest shard)
- **Developer time saved**: 8 minutes per PR
- **CI minutes**: Same (10 minutes total, just parallelized)

### Option 2: Tiered Testing
```yaml
Quick Check (required):
├─ Critical tests: 100 tests → 2 min
└─ CI cost: 2 minutes

Full Suite (post-merge, optional):
├─ All tests: 381 tests → 10 min
└─ CI cost: 10 minutes (but not blocking PRs)

PR flow:
├─ Push code → 2 min for critical tests → merge
└─ Post-merge full suite runs async (non-blocking)

Total: 2 minutes blocking, 10 minutes background
Wait time: -80% ⭐⭐⭐⭐⭐
CI cost: 2 min per PR + 10 min per merge (fewer runs)
```

**Assumptions**:
- ~100 critical tests identified
- Critical tests cover core functionality
- Full suite runs less frequently (only post-merge or nightly)

### Option 3: Hybrid Approach
```yaml
Quick Critical Tests (parallel, required):
├─ Shard 1: Critical tests 1-20   → 0.5 min
├─ Shard 2: Critical tests 21-40  → 0.5 min
├─ Shard 3: Critical tests 41-60  → 0.5 min
├─ Shard 4: Critical tests 61-80  → 0.5 min
└─ Shard 5: Critical tests 81-100 → 0.5 min
Total: 30 seconds wall-clock, 2.5 CI min

Full Suite (post-merge, parallel):
├─ All 5 shards → 2 min wall-clock, 10 CI min
└─ Runs async after merge

PR flow:
├─ Push code → 30 sec critical tests → merge
└─ Full suite runs in background (2 min due to parallel)

Wait time: -95% ⭐⭐⭐⭐⭐⭐
CI cost: 2.5 min per PR + 10 min per merge
```

### Option 5: Performance Optimization Only
```yaml
macOS Job (optimized sequential):
├─ Tests with 120s timeout (vs 180s): saves ~30s
├─ Optimized slow tests: saves ~1-2 min
├─ Cached setup: saves ~30-60s
└─ Total: 7-8 minutes (from 10 minutes)

Wait time: -20-30% ⭐⭐
CI cost: 0% (same pattern, just faster)
```

## Implementation Complexity Breakdown

### Option 1: Parallel Execution
**Changes needed**:
```yaml
# .github/workflows/tests.yml (macOS job only)

# BEFORE (single job):
macos:
  name: macOS unit tests
  runs-on: macos-latest
  steps:
    - name: Run unit tests
      run: ./spells/system/test-magic --verbose

# AFTER (matrix job):
macos:
  name: macOS unit tests
  strategy:
    fail-fast: false
    matrix:
      shard:
        - { id: 1, pattern: "cantrips/*" }
        - { id: 2, pattern: "menu/* .imps/test/*" }
        - { id: 3, pattern: ".imps/sys/* .imps/out/* .imps/fs/*" }
        - { id: 4, pattern: "spellcraft/* system/* arcane/*" }
        - { id: 5, pattern: ".imps/text/* .imps/cond/* .imps/str/*" }
  runs-on: macos-latest
  steps:
    - name: Run test shard ${{ matrix.shard.id }}
      run: |
        for pattern in ${{ matrix.shard.pattern }}; do
          ./spells/system/test-magic --only "$pattern" || exit 1
        done
```

**Files changed**: 1 (tests.yml)
**Lines changed**: ~20
**Risk**: Low (workflow-only)
**Rollback**: Easy (git revert)

### Option 2: Tiered Testing
**Changes needed**:

1. **test-magic** modifications:
```sh
# Add --quick flag support
case "$1" in
  --quick)
    # Only run tests marked as critical
    WIZARDRY_TEST_MODE=quick
    shift
    ;;
esac

# Filter tests based on mode
if [ "$WIZARDRY_TEST_MODE" = "quick" ]; then
  # Only include critical tests
  # Skip tests marked with "# DIAGNOSTIC" comment
fi
```

2. **Test file marking** (example):
```sh
# .tests/cantrips/test-ask-yn.sh
#!/bin/sh
# CRITICAL - User interaction core functionality
# (or)
# DIAGNOSTIC - Edge case testing
```

3. **Workflow changes**:
```yaml
# Required quick checks
quick-tests:
  runs-on: macos-latest
  steps:
    - run: ./spells/system/test-magic --quick

# Full suite (separate workflow or non-required)
full-tests:
  runs-on: macos-latest
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  steps:
    - run: ./spells/system/test-magic --verbose
```

**Files changed**: 3+ (test-magic, tests.yml, possibly 381 test files)
**Lines changed**: 50-500+ depending on granularity
**Risk**: Medium (code changes, categorization decisions)
**Rollback**: Medium (need to revert code changes)

### Option 5: Performance Optimization
**Potential changes**:

1. **Reduce default timeout**:
```sh
# In test-magic
test_timeout="${WIZARDRY_TEST_TIMEOUT:-120}"  # Was 180
```

2. **Optimize slow tests**:
```sh
# Example: Reduce fixture creation in test-install.sh
# Before: Create full directory structure for each test
# After: Share fixtures between tests when safe
```

3. **Cache setup steps**:
```yaml
# In workflow
- name: Cache test dependencies
  uses: actions/cache@v3
  with:
    path: ~/.cache/wizardry-test
    key: ${{ runner.os }}-test-${{ hashFiles('.tests/**') }}
```

**Files changed**: 2-10 (test-magic, slow tests, workflow)
**Lines changed**: 20-100
**Risk**: Low-Medium (depends on optimizations)
**Rollback**: Easy (git revert)

## Real-World Examples

### Shard Distribution (Based on Current Test Counts)

#### Balanced by Test Count
```
Shard 1 (76 tests): cantrips (35) + menu (22) + priorities (4) + wards (6) + enchant (9)
Shard 2 (76 tests): .imps/test (44) + .imps/input (7) + .imps/lex (9) + .imps/pkg (6) + .imps/paths (11)
Shard 3 (76 tests): .imps/sys (26) + .imps/out (19) + .imps/fs (17) + .imps/text (16)
Shard 4 (76 tests): .imps/cond (16) + .imps/str (10) + spellcraft (14) + system (10) + arcane (6) + translocation (6) + crypto (3) + divination (5) + mud (6)
Shard 5 (77 tests): All remaining .imps and edge categories
```

#### Balanced by Estimated Duration (Better)
```
Shard 1 (~2 min): cantrips (35 tests, many user-interactive, quick)
Shard 2 (~2.5 min): menu (22) + .imps/test (44, some setup-heavy)
Shard 3 (~2 min): .imps/sys (26) + .imps/out (19) + .imps/fs (17)
Shard 4 (~2 min): .imps/text (16) + .imps/cond (16) + spellcraft (14) + system (10)
Shard 5 (~3 min): Everything else (188 tests, but individually quick)
```

**Note**: Actual balancing requires profiling. These are estimates.

## Developer Experience Impact

### Current: Sequential Testing
```
Developer workflow:
1. Push code → 10 min wait → see results
2. Fix issue → push → 10 min wait → see results
3. Fix issue → push → 10 min wait → merge

Total time for 3-iteration PR: 30 minutes waiting
```

### With Parallel Execution
```
Developer workflow:
1. Push code → 2 min wait → see results
2. Fix issue → push → 2 min wait → see results
3. Fix issue → push → 2 min wait → merge

Total time for 3-iteration PR: 6 minutes waiting
Saved: 24 minutes per PR (80% reduction)
```

### With Tiered Testing
```
Developer workflow:
1. Push code → 2 min quick check → merge
2. [Background] Full suite runs → catches issues post-merge
3. [If issues] Fix → push → 2 min quick check → merge

Total time: 2-4 minutes blocking
Risk: Issues caught post-merge require additional PR
```

## Cost-Benefit Analysis

### Option 1: Parallel Execution

**Benefits**:
- ✅ 80% reduction in wait time (10 min → 2 min)
- ✅ Same CI minute consumption (just parallelized)
- ✅ Same test coverage (all tests still run)
- ✅ Easy to implement (workflow-only)
- ✅ Low maintenance (no code changes)

**Costs**:
- ❌ Slightly more complex workflow (5 jobs vs 1)
- ❌ More logs to review if failures
- ❌ Need to balance shards occasionally

**ROI**: ⭐⭐⭐⭐⭐ Excellent
- High benefit, low cost
- Fast implementation
- Low risk

### Option 2: Tiered Testing

**Benefits**:
- ✅ 80% reduction in wait time (10 min → 2 min)
- ✅ 80% reduction in CI minutes for PRs (10 min → 2 min)
- ✅ Developer flexibility (can run full suite locally)
- ✅ Same ultimate coverage (full suite still exists)

**Costs**:
- ❌ Code changes required (test-magic + possibly tests)
- ❌ Categorization maintenance burden
- ❌ Risk of missing issues in PR (caught post-merge)
- ❌ Need to define what "critical" means
- ❌ Potential for diagnostic tests to rot

**ROI**: ⭐⭐⭐ Good
- High benefit, medium cost
- Slower implementation
- Medium risk

### Option 5: Performance Optimization

**Benefits**:
- ✅ 20-30% reduction in time (10 min → 7-8 min)
- ✅ Benefits all platforms, not just macOS
- ✅ No architectural changes
- ✅ Cumulative with other options

**Costs**:
- ❌ Limited impact (may not reach goals)
- ❌ Requires profiling and investigation
- ❌ Diminishing returns on optimization effort

**ROI**: ⭐⭐⭐ Good
- Medium benefit, medium cost
- Good complement to other options
- Low risk

## Recommended Phased Approach

### Phase 1: Quick Win (This Week)
**Implement**: Option 1 (Parallel Execution) for macOS only

**Steps**:
1. Profile current test suite to measure per-category duration
2. Create balanced shards based on measurements
3. Update tests.yml with matrix strategy
4. Test in feature branch
5. Deploy if successful

**Expected outcome**: 10 min → 2-3 min (75% reduction)

### Phase 2: Optimization (Weeks 2-3)
**Implement**: Option 5 (Performance Optimization)

**Steps**:
1. Profile to find slowest tests
2. Reduce timeout from 180s to 120s
3. Optimize top 5 slowest tests
4. Cache setup steps if applicable

**Expected outcome**: 2-3 min → 1.5-2 min (additional 25-33% reduction)

**Combined**: 10 min → 1.5-2 min (80-85% total reduction)

### Phase 3: Consider Tiered Testing (Month 2)
**Evaluate**: Option 2 (Tiered Testing) if needed

**Decision criteria**:
- Are developers still waiting too long? (>2 min unacceptable)
- Are CI costs becoming problematic?
- Is there clear consensus on critical vs diagnostic?

**If yes**: Implement tiered testing
**If no**: Stick with optimized parallel execution

### Phase 4: Extend to Other Platforms (Month 3)
**Apply**: Lessons learned to other platforms

**Steps**:
1. Check if other platforms have similar issues
2. Apply same strategies (parallel + optimization)
3. Monitor overall CI health

## Monitoring & Success Criteria

### Key Metrics to Track

1. **PR wait time** (primary metric)
   - Current: ~10 minutes
   - Target: <2 minutes
   - Measurement: Time from push to green checkmark

2. **CI minute consumption**
   - Current: 10 minutes per macOS job
   - Target: <12 minutes (20% acceptable increase)
   - Measurement: Sum of all shard durations

3. **Test reliability**
   - Current: ~0% flakiness
   - Target: Maintain 0%
   - Measurement: Retry rate for failed tests

4. **Developer satisfaction**
   - Current: Unknown (but concern raised)
   - Target: Positive feedback
   - Measurement: Survey or informal feedback

### Weekly Monitoring Dashboard

```markdown
## Week of [Date]

### macOS Test Performance
- Average PR wait time: X min (target: <2 min)
- Longest shard: X min (ideally all <2.5 min)
- CI minutes consumed: X min per PR
- Flaky tests: X (target: 0)

### Shard Balance
- Shard 1: X min average
- Shard 2: X min average  
- Shard 3: X min average
- Shard 4: X min average
- Shard 5: X min average

### Action Items
- [ ] Rebalance shard 3 (too slow)
- [ ] Investigate flaky test in shard 2
- [ ] Consider adding 6th shard
```

## Conclusion

**Primary recommendation**: Implement **Option 1 (Parallel Execution)** immediately.

**Rationale**:
1. **Proven approach**: Standard pattern in industry
2. **Low risk**: No code changes, easy rollback
3. **High impact**: 75-80% reduction in wait time
4. **Fast to implement**: Can ship this week
5. **Scalable**: Can extend to other platforms
6. **Foundation**: Doesn't preclude other optimizations

**Secondary recommendation**: Pursue **Option 5 (Performance Optimization)** in parallel.

**Future consideration**: Evaluate **Option 2 (Tiered Testing)** after 1 month if needed.

**Avoid**: Option 4 (Smart Selection) - too complex for current scale.

---

**Next steps**: 
1. ✅ Create implementation plan
2. ✅ Profile current test suite
3. ⏳ Implement parallel execution
4. ⏳ Monitor and adjust
5. ⏳ Evaluate next optimizations
