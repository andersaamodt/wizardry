# Wizardry Core AI Notes

## Upstream Standards
- Read `README.md` for Wizardry core ethos.
- Read `/Users/andersaamodt/git/phronesis/standards/` for family policy.
- Read `/Users/andersaamodt/git/theurgy/docs/platform-quarantine.md` before adding or retaining platform-specific machinery.

## Local Exception Ledger

### Language Boundaries
- POSIX sh: canonical Wizardry implementation language.
- Python: first-party web helpers no longer invoke Python; remaining Python references are external-tool or compatibility boundaries recorded in `.github/LANGUAGE_EXCEPTION_LEDGER.yaml`.
- Rust: none in Wizardry core.
- Direct macOS automation: core macOS actions cross through named Theurgy capabilities. New or retained exceptions record exact call sites, rationale, and re-audit trigger.

### Storage And Generated Output
- Wizardry core does not own one app durable-state root.
- Runtime, build, test, and release output stays outside the checkout unless it is a deliberate fixture.

### Tests And Audit Evidence
- Canonical tests live under `.tests/`.
- `.github/ROLLING_AUDIT.md` is evidence for its recorded source revision only; refresh findings name the observation date, direct paths, and follow-up boundary.

### Pending Decisions
- Keep capability migrations complete by removing replaced staging, release, and smoke references and defining unavailable behavior.
- Narrow remaining Python boundaries to exact paths with dated review.
