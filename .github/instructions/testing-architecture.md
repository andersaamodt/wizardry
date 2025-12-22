# Testing System Architecture

## Philosophy: The Intelligent Storyteller

The wizardry testing system is designed as an intelligent storyteller that narrates a coherent interrogation of wizardry's capabilities. It doesn't just blast random test files—it tells the story of wizardry from environment preparation through spell execution.

## The Story Arc

### Act 1: Preparation (Environment Setup)

**banish** - The gateway spell
- Checks POSIX tool availability
- Auto-detects or accepts WIZARDRY_DIR
- Sets baseline PATH if needed
- Verifies invoke-wizardry is available
- Prepares the environment for magic

**test-bootstrap** - The test narrator's preparation
- Sets baseline PATH before any commands (critical for macOS CI)
- Locates repository root
- Sets up comprehensive PATH with all spells and imps
- Detects sandboxing capabilities (bwrap on Linux, sandbox-exec on macOS)
- Falls back gracefully when sandboxing unavailable
- Sources all boot imps to provide test framework

### Act 2: The Testing Framework (Infrastructure)

**Boot Imps** (`spells/.imps/test/boot/`) - The narrator's tools
- `run-spell` - Execute a spell and capture output
- `run-cmd` - Execute a command in controlled environment
- `run-bwrap` - Wrap execution in sandbox when available
- `assert-*` - Family of assertion helpers
- `test-*` - Test result reporting (PASS, FAIL, SKIP, LACK)
- `make-fixture` - Create isolated test fixtures
- `stub-*` helpers - Consistent test stubs

**Test Bootstrap Pattern** - Every test begins the same way:
```sh
#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"
```

This locates the repository root and sources the test framework, making all tools available.

### Act 3: Structural Integrity (common-tests.sh)

**common-tests.sh** - The first chapter, validating structure

Tests run in order of abstraction:
1. **File structure** - No duplicate names, test files match spells
2. **Code structure** - No global declarations outside declare-globals
3. **Function discipline** - Spells follow function limits
4. **Variable naming** - Lowercase locals, uppercase exports only
5. **Error handling** - All scripts have explicit `set -eu`
6. **Testing integrity** - Tests use imps, not inline helpers

This chapter ensures the codebase structure is sound before testing behavior.

### Act 4: Domain Capabilities (Category Tests)

Tests organized by wizardry domain:

**System** (`system/test-*`) - Core system interaction
- test-magic itself (the meta-narrator)
- banish environment preparation
- update mechanisms
- POSIX compliance

**Arcane** (`arcane/test-*`) - File and directory magic
- Reading and writing extended attributes
- Trash management
- Batch operations (forall)

**Cantrips** (`cantrips/test-*`) - Quick utility spells
- Interactive input (ask-yn, ask-text, menu)
- Terminal capabilities (fathom-cursor, move-cursor)
- Service management
- System requirements

**Divination** (`divination/test-*`) - Detection and discovery
- Platform detection (detect-distro)
- Environment introspection
- Configuration discovery

**Enchantment** (`enchant/test-*`) - Extended attributes and metadata
- Enchantment reading and writing
- YAML conversion

**Crypto** (`crypto/test-*`) - Cryptographic operations
- Hashing
- Verification

**Translocation** (`translocation/test-*`) - Navigation and teleportation
- Portal creation and navigation
- Location marking
- Teleportation helpers

**MUD** (`mud/test-*`) - Multi-User Dungeon features
- Room identification
- Player tracking
- CD hooks

**Spellcraft** (`spellcraft/test-*`) - Meta-magic for spell creation
- Spell compilation (doppelganger)
- Spell learning and scribing
- Linting and verification
- Spell forgetting

**Priorities** (`priorities/test-*`) - Task prioritization
- Priority management
- Upvoting/downvoting

**PSI** (`psi/test-*`) - Contact management
- vCard reading
- Contact operations

**Arcana** (`.arcana/test-*`) - Installation and configuration
- Core installation
- Optional package installation
- Configuration management

### Act 5: Integration (Installation Tests)

**test-install.sh** - The installation narrative
- Tests real installation process
- Verifies invoke-wizardry integration
- Tests uninstallation and cleanup
- Validates wizard onboarding flow

This is NOT stubbed—it actually installs wizardry in an isolated environment.

### Act 6: Standalone Execution (Doppelganger)

**test-doppelganger.sh** - The portability story
- Compiles all spells into standalone scripts
- Tests compiled versions work without wizardry installed
- Validates true portability

Run separately in dedicated CI workflow due to time requirements.

## Key Architectural Decisions

### 1. Minimize Stubbing

**Philosophy**: Test real wizardry, stub only terminal I/O

**Stub only**:
- Terminal dimensions (fathom-cursor, fathom-terminal)
- Terminal control (move-cursor, cursor-blink, stty)
- User input (await-keypress - only when needed)

**Test real**:
- All wizardry spells and imps
- All wizardry logic
- Actual filesystem operations
- Real command execution

**Rationale**: Over-stubbing makes tests unrealistic and complex. We want to know wizardry actually works, not that our stubs work.

### 2. Graceful Degradation

**Philosophy**: Environment limitations should not fail tests

**Sandbox Strategy**:
- **Prefer**: bubblewrap on Linux (isolates filesystem)
- **Fallback**: Run without sandbox (warn once)
- **macOS**: sandbox-exec available but disabled by default
- **Result**: Tests always run, isolation when possible

**Platform Strategy**:
- Detect capabilities (has command available?)
- Use fallbacks when primary tool missing
- Skip tests gracefully when requirements not met
- Report what was skipped and why

### 3. Test Real Installation

**Philosophy**: Don't stub what we're testing

**Installation Testing**:
- Creates isolated temp directory or sandbox
- Runs actual install script
- Verifies wizardry is functional
- Tests invoke-wizardry sourcing
- Uninstalls and verifies cleanup
- Doesn't disturb existing wizardry installation

**Rationale**: Installation is critical functionality. Stubbing it provides false confidence.

### 4. Coherent Organization

**Philosophy**: Tests tell a story, not a random collection

**Organization**:
1. Structure first (common-tests.sh)
2. Domains second (by category)
3. Integration third (test-install.sh)
4. Special cases last (test-doppelganger.sh)

**Naming Convention**:
- `test-<spell-name>.sh` (hyphens, not underscores)
- Mirrors spell structure: `spells/cat/spell` → `.tests/cat/test-spell.sh`

**Discovery**:
- test-magic finds tests by pattern
- Reports coverage (spells without tests, tests without spells)
- Can filter with `--only` pattern

## The Test Orchestrator: test-magic

**test-magic** is the main entry point and intelligent coordinator:

### Responsibilities

1. **Pre-flight checks** - Verify required commands available
2. **Test discovery** - Find all test files matching pattern
3. **Coverage analysis** - Report uncovered spells, extraneous tests
4. **Test execution** - Run tests with timeout protection
5. **Output aggregation** - Stream results line-by-line (via stdbuf)
6. **Failure reporting** - Detailed output for failed tests
7. **Summary** - Pass/fail counts, coverage gaps, incomplete tests

### Execution Model

```
test-magic
├── Pre-flight: Check required commands (sh, find, grep, awk, sed, etc.)
├── Discovery: Find all test files in .tests/
├── Filtering: Apply --only patterns if specified
├── Execution: For each test:
│   ├── Set up isolated environment (sandbox if available)
│   ├── Run test with timeout (default 180s)
│   ├── Capture output (via stdbuf for line-buffering)
│   ├── Parse PASS/FAIL/SKIP lines
│   └── Record results
├── Coverage: Scan spells/ for untested spells
└── Summary: Report pass/fail/skip/lack counts and details
```

### Output Format

**Per-test output**:
```
### [42/100] spell-name
  PASS #1 shows usage
  PASS #2 handles valid input
  FAIL #3 handles invalid input
  SKIP #4 handles edge case (dependency unavailable)
  3/4 tests passed
```

**Summary output**:
```
Summary
Tests: 95 passed, 5 failed, 100 total
Subtests: 450 passed, 470 total
Coverage: 3 uncovered
Incomplete: 2 tests

Uncovered spells:
  spells/new/experimental-spell
  spells/arcane/unfinished-feature

Failed tests (ubuntu): spell-a (#3), spell-b, spell-c (#1, #5)

=== spell-a ===
FAIL #3 handles invalid input: expected error message not found
```

## Semantic Coherence of Imps

### Output Imps (`spells/.imps/out/`)

**Philosophy**: Clear naming reflects behavior

| Imp | Behavior | Exit | Use Case |
|-----|----------|------|----------|
| `die` | Print error, return exit code | No (returns) | Fatal error in spell function |
| `fail` | Print error, return 1 | No (returns) | Conditional error, continue |
| `warn` | Print warning | No | Non-fatal issue |
| `say` | Print message | No | Normal output (always shown) |
| `info` | Print message | No | Informational (level ≥ 1) |
| `step` | Print step | No | Process step (level ≥ 1) |
| `debug` | Print debug | No | Debug info (level ≥ 2) |
| `success` | Print success | No | Success message (always shown) |
| `usage-error` | Print usage error, return 2 | No (returns) | Invalid arguments |

**Key Insight**: All use `return` not `exit` because they're designed to work with word-of-binding:
- When sourced, functions return to caller
- When spell function returns non-zero, script exits
- This allows spells to be both sourced and executed

### Error Handling Pattern

```sh
#!/bin/sh
spell_name() {
  has git || fail "git required"  # Print error, return 1, caller handles
  
  if [ ! -f "$config" ]; then
    die "config file not found"  # Print error, return 1, function exits
  fi
  
  warn "using default configuration"  # Warning but continue
  
  # ... main logic ...
  
  success "operation complete"  # Success message
  return 0
}

# Self-execute when run directly
case "$0" in */spell-name) spell_name "$@" ;; esac
```

## Platform Abstraction

### Detection

**detect-distro** - Platform identification
- Returns: ubuntu, debian, arch, nixos, mac, etc.
- Used by: Platform-specific installation, configuration

### Abstraction

**Imps abstract platform differences**:
- `pkg-install` - Platform-agnostic package installation
- `has` - Check command availability (works everywhere)
- Platform-specific package variables (APT_PACKAGE, DNF_PACKAGE, etc.)

**Tests adapt to platform**:
- Check tool availability before using
- Skip tests when dependencies unavailable
- Report platform in failure messages

## Current State and Future Direction

### What Works Well

1. ✅ Test organization and discovery
2. ✅ Graceful sandbox fallback
3. ✅ Clear error reporting
4. ✅ Coverage tracking
5. ✅ Platform compatibility
6. ✅ Minimal stubbing philosophy
7. ✅ Self-execute pattern for word-of-binding
8. ✅ Line-buffered output (stdbuf)

### Areas for Improvement

1. **Documentation** - This document! ✅ (Done)
2. **Meta-tests** - Tests for test infrastructure ✅ (Done)
3. **Installation testing** - Make it truly isolated and realistic
4. **Test narrative** - Better organize tests to tell coherent story
5. **Banish enhancement** - Make it the definitive environment preparer
6. **Requirement enforcement** - Tests that validate requirements document

### Roadmap

**Phase 1: Documentation and Validation** ✅
- [x] Document architecture (this file)
- [x] Document requirements (testing-requirements.md)
- [x] Create meta-tests (test-testing-system.sh)

**Phase 2: Enhancement**
- [ ] Enhance banish as primary environment preparer
- [ ] Test real installation in sandbox
- [ ] Improve test organization narrative
- [ ] Add more meta-tests

**Phase 3: Polish**
- [ ] Better error messages
- [ ] Clearer test output
- [ ] Comprehensive requirement tests
- [ ] Documentation examples

## Conclusion

The wizardry testing system is already well-architected:
- Clean separation of concerns
- Minimal stubbing (test real behavior)
- Graceful degradation (work with what's available)
- Self-healing (detect and adapt)
- Coherent organization (structured narrative)

The main improvements needed are:
1. Better documentation (✅ Done)
2. Meta-tests for self-validation (✅ Done)
3. Enhanced environment preparation (banish)
4. True isolated installation testing

The system embodies the wizardry ethos: clean, readable, minimal, and magical.
