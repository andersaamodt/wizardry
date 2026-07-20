# Wizardry Core AI Notes

## Upstream Standards
- Read `README.md` for Wizardry core ethos.
- Read `/Users/andersaamodt/git/phronesis/standards/` for family policy.
- Read `/Users/andersaamodt/git/theurgy/docs/platform-quarantine.md` before adding or retaining platform-specific machinery.

## Local Exception Ledger

### Language Boundaries
- POSIX sh: canonical Wizardry implementation language.
- Python: `spells/web/build` and `spells/web/fix-site-security` retain direct helper invocations; Python availability/install spells describe an external dependency rather than a new implementation language. Direct helper use is removal-default until narrowed behind an approved boundary.
- Rust: none in Wizardry core.
- Direct macOS automation: legacy direct `osascript` calls remain in macOS-specific core flows such as Trash and logout handling. They are removal-default; new or retained automation must cross through a named Theurgy capability and record exact call sites, rationale, and re-audit trigger.

### Storage And Generated Output
- Wizardry core does not own one app durable-state root.
- Runtime, build, test, and release output stays outside the checkout unless it is a deliberate fixture.

### Tests And Audit Evidence
- Canonical tests live under `.tests/`.
- `.github/ROLLING_AUDIT.md` is evidence for its recorded source revision only; refresh findings name the observation date, direct paths, and follow-up boundary.

### Pending Decisions
- Move retained macOS automation behind Theurgy-owned structured capabilities or approve narrowly justified core exceptions.
- Replace or explicitly approve the remaining direct Python helper paths.
