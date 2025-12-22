# Testing System Requirements

## Purpose

This document specifies the complete requirements for the wizardry testing system. All requirements here must be enforced operationally through tests that validate the testing system itself.

## Core Philosophy

The testing system should be an intelligent storyteller that:
1. **Checks environmental assumptions** - Queries system capabilities before testing
2. **Self-heals** - Repairs what it can automatically
3. **Works around limitations** - Skips or adapts when it cannot heal
4. **Reports clearly** - Explains what was skipped/worked around and why
5. **Tests real installation** - Actually installs wizardry in isolated environment
6. **Minimizes stubbing** - Stubs only terminal I/O, tests real wizardry behavior
7. **Tells a coherent story** - Organizes tests as logical interrogation of capabilities

## Part 1: Environment Preparation

### REQ-ENV-001: Baseline PATH must be established before any commands
**Priority**: Critical  
**Rationale**: On some platforms (macOS CI), PATH may be empty, causing immediate failure  
**Implementation**: test-bootstrap and test-magic set baseline PATH before `set -eu`  
**Test**: Verify baseline PATH is set in bootstrap before first command execution

### REQ-ENV-002: banish spell must check and prepare environment
**Priority**: Critical  
**Rationale**: banish is the gateway spell - it ensures environment is ready for invoke-wizardry  
**Requirements**:
- Check POSIX tool availability (sh, test, printf, awk, sed, grep, etc.)
- Auto-detect or accept WIZARDRY_DIR
- Verify WIZARDRY_DIR contains spells/
- Set baseline PATH if needed
- Export WIZARDRY_DIR for downstream use
- Call detect-posix if available for thorough checking
- Support --verbose for diagnostics
**Test**: banish should pass on clean minimal system, report issues clearly

### REQ-ENV-003: Test environment must be isolated but realistic
**Priority**: High  
**Rationale**: Tests should run in isolation without disturbing host system  
**Implementation**: Use sandboxing when available (bwrap on Linux, sandbox-exec on macOS)  
**Fallback**: Gracefully proceed without sandbox with warning  
**Test**: Verify sandbox is used when available, graceful fallback when not

## Part 2: Sandboxing and Isolation

### REQ-SAND-001: Bubblewrap must work on Ubuntu and NixOS
**Priority**: Critical  
**Status**: Currently working on Ubuntu and NixOS  
**Requirements**:
- User namespaces must be configured in CI
- uidmap/subuid/subgid must be set up
- bwrap must be available via package manager
**Test**: CI workflows for Ubuntu and NixOS must configure and verify bwrap

### REQ-SAND-002: Bubblewrap must work on Debian
**Priority**: High  
**Current**: Works (as of tests.yml configuration)  
**Requirements**: Same as REQ-SAND-001  
**Test**: Debian CI workflow must verify bwrap functionality

### REQ-SAND-003: Bubblewrap must work on Arch Linux OR be gracefully disabled
**Priority**: High  
**Current Issue**: May not work reliably  
**Options**:
  A. Fix bwrap for Arch (preferred) - install uidmap, configure namespaces  
  B. Disable gracefully with clear reporting  
**Decision needed**: Should we fix or disable?  
**Test**: Arch CI should either use bwrap successfully or report graceful disable

### REQ-SAND-004: macOS must use alternative sandboxing OR gracefully disable
**Priority**: High  
**Current**: macOS doesn't use bwrap (not available)  
**Options**:
  A. Use sandbox-exec (macOS native)  
  B. Disable sandboxing gracefully (simpler)  
**Current**: Gracefully disabled with warning  
**Test**: macOS CI must run tests without bwrap, report appropriately

### REQ-SAND-005: Sandbox unavailability must not fail tests
**Priority**: Critical  
**Rationale**: Tests must run on systems without sandboxing capability  
**Implementation**: test-bootstrap checks sandbox availability, sets flags, warns once  
**Test**: Tests pass on system without bwrap/sandbox-exec

### REQ-SAND-006: Test isolation must not require root/sudo
**Priority**: High  
**Rationale**: Regular users should be able to run tests  
**Current Issue**: bwrap via sudo creates permission issues (files as root)  
**Solution**: Use user namespaces (--unshare-user-try) instead of sudo  
**Test**: Tests run as non-root user with user namespaces

## Part 3: Test Installation Testing

### REQ-INST-001: Tests must actually install wizardry in clean environment
**Priority**: Critical  
**Rationale**: Need to verify installation works, not just stub it  
**Implementation**: 
- Create isolated temp directory or sandbox
- Run install script
- Verify wizardry is installed and functional
- Test invoke-wizardry works
- Uninstall and verify cleanup
**Test**: test-install.sh must perform real installation, not stubbed

### REQ-INST-002: wizardry must be portable enough to install without disturbing host
**Priority**: Critical  
**Rationale**: Installation in test shouldn't affect existing wizardry installation  
**Requirements**:
- Support custom WIZARDRY_DIR via banish --wizardry-dir
- Support custom SPELLBOOK_DIR
- Don't modify system files without permission
- Use isolated directories in tests
**Test**: Multiple wizardry installations can coexist

### REQ-INST-003: banish must prepare environment before invoke-wizardry
**Priority**: Critical  
**Rationale**: invoke-wizardry needs prepared environment to work  
**Sequence**:
1. Run banish (checks environment, sets WIZARDRY_DIR)
2. Source invoke-wizardry (adds to PATH, sources spells)
**Test**: banish + invoke-wizardry sequence works in clean shell

## Part 4: Minimizing Stubbing

### REQ-STUB-001: Only terminal I/O should be stubbed
**Priority**: High  
**Rationale**: Over-stubbing makes tests unrealistic and complex  
**Stub only**: fathom-cursor, fathom-terminal, move-cursor, stty, await-keypress  
**Test real**: All wizardry spells and imps (except terminal I/O)  
**Test**: Verify tests use real spells, not inline implementations

### REQ-STUB-002: Stubs must be reusable test imps, not inline
**Priority**: High  
**Rationale**: Consistency across tests, avoid duplication  
**Location**: spells/.imps/test/stub-*  
**Usage**: Tests create symlinks to stub imps  
**Test**: No inline stubs in test files

### REQ-STUB-003: Stub imps must match both prefixed and unprefixed names
**Priority**: Medium  
**Rationale**: Tests create symlinks without stub- prefix  
**Pattern**: `case "$0" in */stub-name|*/name) _stub_name "$@" ;; esac`  
**Test**: All stub imps have correct self-execute pattern

## Part 5: Test Organization

### REQ-ORG-001: Tests must mirror spell structure
**Priority**: Critical  
**Pattern**: `spells/category/spell-name` → `.tests/category/test-spell-name.sh`  
**Test**: All spells have corresponding test files

### REQ-ORG-002: Test files must use hyphen naming (test-name.sh)
**Priority**: Critical  
**Rationale**: Consistency with spell naming convention  
**Wrong**: `test_name.sh` (underscores)  
**Correct**: `test-name.sh` (hyphens)  
**Test**: All test files follow hyphen convention

### REQ-ORG-003: Tests must be organized as coherent story
**Priority**: Medium  
**Rationale**: Tests should read as logical exploration of capabilities  
**Implementation**:
- common-tests.sh runs first (structural checks)
- Test categories follow wizardry categories
- Tests within category tell story of that domain
**Test**: Test execution order makes semantic sense

### REQ-ORG-004: test-magic must be intelligent orchestrator
**Priority**: High  
**Rationale**: test-magic is the main entry point, should be well-organized  
**Requirements**:
- Pre-flight environment checks
- Test discovery and filtering
- Timeout protection
- Coverage reporting
- Coherent output (not just file dump)
**Test**: test-magic behavior is well-structured

## Part 6: Imp Semantic Coherence

### REQ-IMP-001: die imp must exit script when called from script
**Priority**: Critical  
**Current**: die uses `return` not `exit`  
**Issue**: When sourced, `return` works, but when executed directly, may not exit script  
**Analysis needed**: Is current behavior correct? Should there be two imps?  
**Options**:
  A. Keep die as-is (use return, works when sourced)  
  B. Add exit-die that uses exit (for scripts)  
  C. Make die detect context and choose return vs exit  
**Test**: die imp behavior matches expected semantics

### REQ-IMP-002: fail imp must NOT exit script
**Priority**: Critical  
**Current**: fail returns 1 (correct)  
**Usage**: `has git || fail "git required"` - continues after reporting  
**Test**: fail returns error code but doesn't exit

### REQ-IMP-003: All imps must have clear semantic names
**Priority**: Medium  
**Examples**:
- die = fatal error, exits
- fail = error but continue
- warn = warning, continue
- say = normal output
- info = informational (respects log level)
**Test**: Imp names accurately describe behavior

### REQ-IMP-004: Related imps must have consistent behavior
**Priority**: Medium  
**Example families**:
- Output: say, info, step, debug, success (all output to stdout/stderr appropriately)
- Error: die, fail, warn (all different error levels)
- Conditional: has, there, is, yes, no (all return exit codes)
**Test**: Imp families are internally consistent

## Part 7: Test System Self-Tests

### REQ-META-001: Test system must test itself
**Priority**: High  
**Rationale**: Prevent test infrastructure bugs  
**Requirements**:
- Test helpers have their own tests
- test-bootstrap is tested
- Stub imps are tested
- Boot imps are tested
**Test**: Meta-tests exist for test infrastructure

### REQ-META-002: Test requirements must be enforced operationally
**Priority**: Critical  
**Rationale**: This document must not drift from reality  
**Implementation**: Each requirement should have corresponding test  
**Test**: Requirements document is validated by actual tests

### REQ-META-003: Test output must stream line-by-line
**Priority**: Medium  
**Rationale**: See test progress in real-time, not all at once  
**Implementation**: Use stdbuf to unbuffer output  
**Test**: PASS/FAIL lines appear as tests complete (test-magic uses stdbuf)

## Part 8: Platform Compatibility

### REQ-PLAT-001: Tests must work on all supported platforms
**Priority**: Critical  
**Platforms**: Ubuntu, Debian, Arch, NixOS, macOS  
**Requirements**:
- Platform detection works
- Platform-specific fallbacks available
- Tests adapt to platform capabilities
**Test**: CI passes on all platforms

### REQ-PLAT-002: Missing tools must be handled gracefully
**Priority**: High  
**Rationale**: Not all tools available on all platforms  
**Implementation**: Check with `command -v`, provide fallbacks or skip  
**Test**: Tests skip features when tools unavailable (with clear reporting)

### REQ-PLAT-003: Platform differences must be abstracted
**Priority**: Medium  
**Rationale**: Tests shouldn't contain platform-specific conditionals  
**Implementation**: Use imps to abstract differences  
**Test**: Test code is platform-agnostic

## Part 9: Error Reporting

### REQ-ERR-001: Test failures must report clearly
**Priority**: High  
**Current**: FAIL lines with optional details  
**Requirements**:
- Failed test name
- Failure reason
- Failed subtest numbers (for multi-subtest tests)
- Full output for failed tests (when <= 12 failures)
**Test**: Failure output is clear and actionable

### REQ-ERR-002: Skipped tests must report reason
**Priority**: Medium  
**Current**: SKIP with reason, LACK for incomplete  
**Requirements**:
- Clear reason why skipped
- Distinguishable from failures
**Test**: Skipped tests are clearly marked

### REQ-ERR-003: Coverage gaps must be reported
**Priority**: High  
**Current**: Reports uncovered spells, extraneous tests  
**Requirements**:
- List spells without tests
- List tests without spells
- Count incomplete tests
**Test**: Coverage reporting is accurate

## Part 10: CI Integration

### REQ-CI-001: All CI platforms must pass
**Priority**: Critical  
**No exemptions**: CI must not use continue-on-error  
**Test**: All platform workflows succeed

### REQ-CI-002: CI failures must be debuggable
**Priority**: High  
**Requirements**:
- Full test output in CI logs
- Clear failure reasons
- Platform information included
**Test**: CI logs contain enough information to reproduce failures

### REQ-CI-003: CI must not hang
**Priority**: Critical  
**Implementation**: Timeouts on tests (default 180s, configurable)  
**Test**: Hung tests timeout and report clearly

## Requirement Categories Summary

| Category | Requirements | Priority | Status |
|----------|--------------|----------|--------|
| Environment | 3 | Critical | Partial |
| Sandboxing | 6 | High | Needs Work |
| Installation | 3 | Critical | Unknown |
| Stubbing | 3 | High | Good |
| Organization | 4 | Medium-Critical | Good |
| Imp Semantics | 4 | Medium-Critical | Needs Review |
| Meta-Testing | 3 | High | Partial |
| Platform | 3 | Critical-Medium | Good |
| Error Reporting | 3 | High-Medium | Good |
| CI | 3 | Critical | Good |

## Next Steps

1. **Audit existing tests** - Verify which requirements are met
2. **Create meta-tests** - Test the test system itself
3. **Fix bwrap** - Decide on Arch/macOS strategy, implement
4. **Review imp semantics** - Especially die/fail/warn consistency
5. **Improve banish** - Make it the proper environment preparer
6. **Test real installation** - Stop stubbing installation testing
7. **Document test story** - Organize tests into coherent narrative
