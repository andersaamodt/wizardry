# Test Suite Optimization - Recommendations & Analysis

**Goal**: Reduce macOS test duration from ~10 minutes to improve developer experience while maintaining test coverage quality.

## Current State

### Test Suite Statistics
- **Total test files**: 381 tests
- **Platforms tested**: 5 (NixOS, macOS, Arch, Debian, Ubuntu)
- **Execution pattern**: All tests run sequentially on each platform
- **macOS duration**: ~10 minutes (reported bottleneck)
- **Test organization**: Well-structured in 20+ categories

### Test Distribution by Category
```
44  .imps/test       (Test infrastructure)
35  cantrips         (User interaction spells)
26  .imps/sys        (System imps)
22  menu             (Menu system)
19  .imps/out        (Output/logging imps)
17  .imps/fs         (Filesystem imps)
16  .imps/text       (Text processing)
16  .imps/cond       (Conditional imps)
14  spellcraft       (Spell management)
11  .imps/paths      (Path handling)
10  system           (System utilities)
10  .imps/str        (String operations)
9   .imps/lex        (Lexical parsing)
7   .imps/input      (Input handling)
6   translocation    (Navigation spells)
6   .imps/pkg        (Package management)
6   arcane           (Advanced spells)
5   divination       (Detection/discovery)
4   priorities       (Priority management)
+ 15 more categories with 1-4 tests each
```

### Current CI/CD Workflows
1. **tests.yml** - Main unit tests (5 OS jobs)
2. **posix.yml** - POSIX compliance checks
3. **vet-spells.yml** - Linting and formatting
4. **compile.yml** - Compilation workflow
5. **test-standalone-spells.yml** - Standalone spell testing
6. **test-doppelganger.yml** - Doppelganger testing

## Options Analysis

### Option 1: Parallel Test Execution (Split by Category)

**Approach**: Split tests into 4-5 parallel jobs per OS, running different test categories simultaneously.

#### Implementation Strategy
```yaml
# Example: tests.yml with matrix strategy
jobs:
  macos-tests:
    strategy:
      matrix:
        shard: [1, 2, 3, 4, 5]
    name: macOS tests (shard ${{ matrix.shard }}/5)
    runs-on: macos-latest
    steps:
      - name: Run test shard
        run: |
          case "${{ matrix.shard }}" in
            1) patterns="cantrips/* menu/*" ;;
            2) patterns=".imps/test/* .imps/sys/*" ;;
            3) patterns=".imps/out/* .imps/fs/* .imps/text/*" ;;
            4) patterns="spellcraft/* system/* arcane/*" ;;
            5) patterns="*"  # Everything else
          esac
          for pattern in $patterns; do
            ./spells/system/test-magic --only "$pattern"
          done
```

#### Pros
✅ **Significant time reduction**: 10 minutes → ~2-3 minutes (3-4x speedup)
✅ **Better resource utilization**: Leverages GitHub Actions parallelism
✅ **No code changes needed**: Only workflow configuration
✅ **Full coverage maintained**: All tests still run
✅ **Easy to balance**: Can adjust shard sizes based on actual duration
✅ **Existing support**: `test-magic --only` already supports patterns

#### Cons
❌ **Increased complexity**: More workflow jobs to manage
❌ **More CI minutes consumed**: 5 shards = 5x minutes (but wall-clock time is faster)
❌ **Harder to debug**: Failures spread across multiple jobs
❌ **Shard balancing required**: Need to distribute tests evenly by duration
❌ **Matrix strategy overhead**: Slight GitHub Actions scheduling overhead

#### Cost Analysis
- **Before**: 1 job × 10 min = 10 CI minutes (10 min wait)
- **After**: 5 jobs × 2.5 min = 12.5 CI minutes (2.5 min wait)
- **Trade-off**: +25% CI minutes for 75% faster feedback

#### Implementation Complexity: Medium
- Requires workflow file changes
- Need to balance test categories across shards
- May need iteration to optimize shard distribution
- Risk: If one shard is slow, overall time isn't optimal

---

### Option 2: Tiered Testing with Skip Flags

**Approach**: Mark tests as "critical" vs "diagnostic", skip diagnostic by default, run full suite in separate non-blocking workflow.

#### Implementation Strategy
```yaml
# Fast PR workflow (required)
jobs:
  quick-tests:
    name: Quick validation tests
    runs-on: macos-latest
    steps:
      - name: Run critical tests only
        run: ./spells/system/test-magic --quick
        # Runs ~100 critical tests in ~2 minutes

# Full test workflow (non-blocking, runs after merge or on-demand)
jobs:
  full-tests:
    name: Full test suite
    runs-on: macos-latest
    steps:
      - name: Run all tests
        run: ./spells/system/test-magic --verbose
```

#### Test Categorization Strategy
```sh
# Critical tests (run by default):
- --help tests for all spells
- Core functionality tests for critical spells (install, menu, invoke-wizardry)
- Platform compatibility tests
- Common infrastructure tests

# Diagnostic tests (skip by default):
- Edge case tests
- Comprehensive behavioral tests
- Integration tests for non-critical spells
- Performance tests
```

#### Pros
✅ **Fast feedback**: 2-3 minutes for PR validation
✅ **Simple to understand**: Clear critical vs diagnostic split
✅ **Lower CI cost**: Fewer minutes for required checks
✅ **Developer flexibility**: Can run full suite locally when needed
✅ **Progressive enhancement**: Start simple, refine categories over time
✅ **Preserved coverage**: Full suite still runs regularly

#### Cons
❌ **Code changes required**: Need to modify test-magic and possibly test files
❌ **Risk of false confidence**: Might merge with diagnostic failures
❌ **Requires discipline**: Must keep critical tests actually critical
❌ **Categorization complexity**: Deciding which tests are critical
❌ **Maintenance burden**: Need to maintain two test profiles
❌ **Potential for drift**: Diagnostic tests might rot if rarely run

#### Implementation Complexity: Medium-High
- Requires test-magic modifications to support --quick flag
- Need to establish clear categorization criteria
- Possibly need to mark tests with metadata (comments or special markers)
- Risk: Mis-categorization could hide important bugs

---

### Option 3: Hybrid Approach (Recommended)

**Approach**: Combine parallel execution for macOS with tiered testing.

#### Implementation Strategy
```yaml
# Quick PR checks (required, parallel)
jobs:
  macos-quick:
    strategy:
      matrix:
        shard: [1, 2, 3]  # Only 3 shards for critical tests
    name: macOS critical tests (shard ${{ matrix.shard }}/3)
    runs-on: macos-latest
    steps:
      - name: Run critical test shard
        run: ./spells/system/test-magic --quick --shard ${{ matrix.shard }}/3

# Full suite (non-required, runs nightly or post-merge)
jobs:
  macos-full:
    name: macOS full test suite
    runs-on: macos-latest
    steps:
      - name: Run all tests
        run: ./spells/system/test-magic --verbose
```

#### Pros
✅ **Best of both worlds**: Fast feedback + comprehensive coverage
✅ **Optimal resource usage**: Parallel for speed, tiered for efficiency
✅ **Scalable**: Can adjust both dimensions independently
✅ **Gradual rollout**: Can implement in phases

#### Cons
❌ **Most complex**: Combines complexity of both approaches
❌ **Higher maintenance**: Two systems to maintain

---

### Option 4: Smart Test Selection (Advanced)

**Approach**: Only run tests affected by changed files.

#### Implementation Strategy
```sh
# Detect changed files
changed_files=$(git diff --name-only origin/main)

# Map changed files to relevant tests
# Example: spells/cantrips/ask-yn → .tests/cantrips/test-ask-yn.sh
#          spells/.imps/out/say → all tests (used widely)

# Run only relevant tests
./spells/system/test-magic --only "pattern1" --only "pattern2"
```

#### Pros
✅ **Extremely fast**: Only tests what changed (could be <1 minute)
✅ **Scales with codebase**: Larger repo = more benefit
✅ **Smart resource usage**: Don't waste time on unrelated tests

#### Cons
❌ **Complex dependency tracking**: Hard to know what affects what
❌ **Risk of missing issues**: Cross-cutting changes might be missed
❌ **Still need full suite**: Must run periodically
❌ **False negatives possible**: Integration issues between unchanged components
❌ **Difficult to implement correctly**: Requires deep codebase understanding

#### Implementation Complexity: Very High
- Requires dependency graph analysis
- Need to maintain change-to-test mappings
- High risk of incorrect mappings causing missed bugs
- **Not recommended** for this codebase at current scale

---

### Option 5: Optimize Test Execution Time

**Approach**: Make tests run faster rather than running fewer/parallel.

#### Potential Optimizations
1. **Reduce timeout values**: Current default 180s per test might be excessive
2. **Optimize slow tests**: Profile and improve the slowest tests
3. **Cache dependencies**: Cache setup steps across test runs
4. **Use faster test runners**: Optimize test-magic itself
5. **Reduce fixture creation**: Share fixtures between tests when safe

#### Pros
✅ **No architectural changes**: Keep current structure
✅ **Benefits all platforms**: Faster everywhere, not just macOS
✅ **Cumulative**: Each optimization compounds
✅ **Lower complexity**: Focused improvements

#### Cons
❌ **Limited gains**: Might only get 20-30% improvement
❌ **Requires profiling**: Need to identify bottlenecks first
❌ **Diminishing returns**: Hard optimizations for small gains
❌ **May not reach goal**: Unlikely to get 75% reduction

#### Investigation Needed
- Profile test suite to find slowest tests
- Check if timeouts are being hit (indicates hanging tests)
- Analyze fixture creation overhead
- Look for redundant setup/teardown

---

## Recommendations

### Primary Recommendation: **Option 1 (Parallel Execution)**

**Rationale**:
1. **Fastest implementation**: Only workflow changes, no code modifications
2. **Predictable outcome**: Well-understood parallelization strategy
3. **Low risk**: Doesn't change test coverage or execution logic
4. **Existing support**: `test-magic --only` pattern matching already works
5. **Easy rollback**: Can revert workflow changes if needed

**Implementation Plan**:

#### Phase 1: Create Balanced Shards (Week 1)
1. Profile current test suite to measure per-test duration
2. Create 4-5 balanced shards based on actual execution time
3. Consider grouping:
   - **Shard 1**: cantrips (35 tests, ~2 min estimated)
   - **Shard 2**: menu + .imps/test (66 tests, ~2.5 min estimated)
   - **Shard 3**: .imps/sys + .imps/out + .imps/fs (62 tests, ~2 min estimated)
   - **Shard 4**: spellcraft + system + arcane (30 tests, ~2 min estimated)
   - **Shard 5**: Everything else (188 tests, ~3 min estimated)

#### Phase 2: Update Workflow (Week 1)
```yaml
jobs:
  macos-tests:
    strategy:
      fail-fast: false  # Continue other shards if one fails
      matrix:
        include:
          - shard: 1
            pattern: "cantrips/*"
          - shard: 2
            pattern: "menu/* .imps/test/*"
          - shard: 3
            pattern: ".imps/sys/* .imps/out/* .imps/fs/*"
          - shard: 4
            pattern: "spellcraft/* system/* arcane/*"
          - shard: 5
            pattern: "*"  # Run all, but previous shards cached
    name: macOS tests (shard ${{ matrix.shard }})
    runs-on: macos-latest
    steps:
      # ... checkout and setup ...
      - name: Run test shard ${{ matrix.shard }}
        run: |
          # Run tests for this shard's patterns
          for pattern in ${{ matrix.pattern }}; do
            ./spells/system/test-magic --only "$pattern" --verbose || exit 1
          done
```

#### Phase 3: Monitor and Adjust (Week 2)
1. Run several CI builds to measure actual durations
2. Rebalance shards if needed
3. Adjust fail-fast strategy based on experience

### Secondary Recommendation: **Option 5 (Optimization) in Parallel**

While implementing Option 1, investigate test performance:

1. **Week 1**: Profile test suite on macOS
   ```sh
   # Add timing to test-magic output
   time ./spells/system/test-magic --verbose 2>&1 | tee test-timings.log
   # Analyze slowest tests
   grep "tests passed" test-timings.log | sort -rn
   ```

2. **Week 2**: Address top bottlenecks
   - If timeouts are common: Reduce default timeout
   - If specific tests are slow: Optimize those tests
   - If setup is slow: Cache or optimize setup steps

3. **Combined benefit**: Parallel (3-4x) + Optimization (1.2-1.5x) = 4-6x total speedup

### Future Consideration: **Option 2 (Tiered Testing)**

If parallel execution alone doesn't provide sufficient improvement, or if CI costs become prohibitive:

1. **Phase 1**: Define critical test criteria
2. **Phase 2**: Implement `--quick` flag in test-magic
3. **Phase 3**: Mark tests as critical/diagnostic
4. **Phase 4**: Create separate full-suite workflow

This can be added incrementally without disrupting the parallel execution strategy.

---

## Implementation Checklist

### Immediate Actions (This Week)
- [ ] Profile macOS test suite to get baseline metrics
- [ ] Identify natural test groupings for shards
- [ ] Draft workflow changes for parallel execution
- [ ] Test workflow changes in a feature branch

### Short-term Actions (Next 2 Weeks)
- [ ] Implement parallel execution for macOS
- [ ] Monitor CI runs and adjust shard balance
- [ ] Document shard strategy in workflow comments
- [ ] Consider extending to other platforms if successful

### Medium-term Actions (Next Month)
- [ ] Investigate test performance bottlenecks
- [ ] Implement quick wins from profiling
- [ ] Evaluate need for tiered testing
- [ ] Consider smart caching strategies

### Long-term Monitoring
- [ ] Track average PR test duration over time
- [ ] Monitor CI minute consumption
- [ ] Gather developer feedback on test speed
- [ ] Reassess strategy quarterly

---

## Risk Mitigation

### Risk: Shard imbalance causes slow overall time
**Mitigation**: 
- Profile tests before creating shards
- Monitor actual durations and rebalance
- Use `fail-fast: false` to avoid cascading delays

### Risk: Increased CI costs
**Mitigation**:
- Calculate cost impact before rollout
- Consider GitHub Actions billing limits
- Start with macOS only (the bottleneck)
- Monitor and adjust if costs are problematic

### Risk: Harder to debug failures
**Mitigation**:
- Clear shard naming in job titles
- Comprehensive logging in each shard
- Document shard contents in workflow
- Easy to run specific shard locally

### Risk: Breaking changes to test-magic
**Mitigation**:
- Thoroughly test workflow changes
- Use feature flags if adding new functionality
- Maintain backward compatibility
- Have rollback plan ready

---

## Success Metrics

### Primary Metrics
- **macOS test duration**: Target <3 minutes (from ~10 minutes)
- **Total CI time**: Minimize wall-clock time for developers
- **Test reliability**: Maintain 0% flakiness rate

### Secondary Metrics
- **CI minute consumption**: Keep within reasonable bounds (<50% increase)
- **Developer satisfaction**: Gather feedback on improved speed
- **Test coverage**: Maintain 100% coverage (no tests skipped)

### Monitoring
- Track metrics in GitHub Actions UI
- Weekly review of test durations
- Monthly cost analysis
- Quarterly strategy review

---

## Conclusion

**Recommended approach**: Implement **parallel test execution (Option 1)** immediately, while investigating **performance optimizations (Option 5)** in parallel.

This provides:
- **Fast results**: Workflow-only changes can be implemented this week
- **Low risk**: No code changes, easy rollback
- **Significant improvement**: 3-4x speedup expected (10 min → 2-3 min)
- **Future flexibility**: Can add tiered testing later if needed
- **Scalable**: Proven pattern that works at any scale

Start with macOS (the bottleneck), then extend to other platforms if successful and needed.
