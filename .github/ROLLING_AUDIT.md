# Wizardry Rolling Audit

## Round 1
- Date: 2026-06-13
- Auditor scope: repo-grounded audit of Wizardry source, standards docs, audit surfaces, and targeted tests
- Criteria source: Wizardry core standards plus the rolling Wizardry-family audit criteria for shell purity, documentation consistency, portability, plain-text state, and category-first audit tracking

## Architecture Observed
- Wizardry is the shell-first core of the family rather than an app repo.
- The repo is overwhelmingly POSIX `sh` and already follows the `.tests/` contract broadly.
- The main audit pressure here is therefore on standards coherence, portability discipline, and audit accuracy rather than on app-shell GUI concerns.

## Result
- Pass: no

## What Passes
- No Python, Rust, or Cargo surfaces were found in the Wizardry repo during this pass.
- Test surfaces are already organized under `.tests/`, with broad coverage across spell families.
- The previously reported `pocket-dimension` undefined-function failure is no longer present in current source.
- Verified in this pass:
  - `sh .tests/psi/test-list-contacts.sh` passed

## Findings

### 1. AI-facing shell override guidance normalized during fix-it
- Severity: resolved
- Why it matters:
  - Wizardry relies on `.github/` as the canonical place where humans and agents learn safe shell patterns.
  - Contradictory guidance in that surface directly weakens consistency and can cause agents to reintroduce a known bad pattern.
- Evidence:
  - `LESSONS.md` says never wrap `builtin` in `eval`: `.github/LESSONS.md`
  - `EXEMPTIONS.md` reinforces the same rule and says the `eval` is only for the version check: `.github/EXEMPTIONS.md`
  - `SHELL_CODE_PATTERNS.md` now teaches the same pattern and does not recommend eval-wrapping `builtin`: `.github/SHELL_CODE_PATTERNS.md`
  - `SHELL_CODE_PATTERNS.md` also now matches `LESSONS.md` by refusing sourced-script completion setup through `complete`, `compdef`, or `bind`: `.github/SHELL_CODE_PATTERNS.md`
- Assessment:
  - This finding is closed for current source.

### 2. Existing audit results table refreshed where stale evidence was cited
- Severity: resolved
- Why it matters:
  - Wizardry already has an AI-facing audit surface, so if it is stale it becomes active misinformation rather than neutral history.
  - A stale audit table undermines later rolling audits because it mixes old failures with current source truth.
- Evidence:
  - `AUDIT_RESULTS.md` now records `spells/system/pocket-dimension` as fixed: `.github/AUDIT_RESULTS.md`
  - `AUDIT_RESULTS.md` now records `spells/psi/list-contacts` as POSIX awk-backed rather than GNU `FPAT`-backed: `.github/AUDIT_RESULTS.md`
  - `README.md` install examples were checked against the current install section during fix-it: `README.md`
- Assessment:
  - This finding is closed for the stale evidence cited in this rolling audit.

### 3. `list-contacts` POSIX awk portability restored
- Severity: resolved
- Why it matters:
  - Wizardry standards explicitly reject GNU-specific command usage when a POSIX-safe path is required.
  - vCard parsing should stay portable across ordinary POSIX awk implementations.
- Evidence:
  - no `FPAT` usage remains in `spells/psi/list-contacts`
  - the test now exercises real vCard parsing, including FN, ORG, TEL, folded lines, escaped punctuation, and filename fallback: `.tests/psi/test-list-contacts.sh`
  - verified during fix-it: `sh .tests/psi/test-list-contacts.sh` passed 6/6
- Assessment:
  - This finding is closed for current source.

## Suggested Next Moves
1. Continue category-first remediation in the shared `wizardry-apps` rolling-audit queue.

## Refresh: 2026-07-19
- Scope: read-only source and standards refresh against current Phronesis policy.
- Source revision: working-tree observation; this refresh does not claim a clean-tree revision.
- Result: Round 1's statement that Wizardry had no Python or non-shell surfaces is superseded.

### Current Findings

1. `python-exception-undocumented` — high
- Direct evidence: `spells/web/build` and `spells/web/fix-site-security` invoke Python helpers; the related install/check spells establish Python availability rather than eliminate the implementation boundary.
- Required direction: remove, narrow, or explicitly approve the direct helper boundary in the core exception ledger.
- Re-audit trigger: the next change to either helper or its web-runtime contract.

2. `osascript-boundary-unquarantined` — high
- Direct evidence: `spells/arcane/trash` and `spells/menu/shutdown-menu` invoke AppleScript from core shell code; additional macOS-specific arcana requires the same review.
- Required direction: move retained automation behind named Theurgy capabilities or approve an explicit, narrow core exception.
- Re-audit trigger: the next macOS automation or Theurgy platform-boundary change.

3. `audit-surface-stale` — high
- Direct evidence: the Round 1 claim of no Python/non-shell surfaces conflicts with the current source paths above.
- Required direction: audit reports must identify their observed revision and remain historical when source changes.
- Re-audit trigger: every audit refresh.

## Validation Notes
- `sh .tests/psi/test-list-contacts.sh` passed 6/6 during fix-it.
- I did not run the full Wizardry test suite in this pass.
- This round was a repo-and-standards audit, not a file-by-file exhaustive reread of the whole repository.
