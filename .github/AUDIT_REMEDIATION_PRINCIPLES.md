# Audit Remediation Principles

- A removed helper is not gone until build, package, and smoke paths no longer
  reference it.
- A Theurgy capability migration must preserve an explicit portable,
  unsupported, or manual-action behavior when Theurgy is unavailable.
- Python references must be classified as first-party logic, external-engine
  boundary, test-only tooling, or a dated migration candidate.
- Direct macOS automation is never an ambient convenience; it belongs in a
  named Theurgy capability or a path-specific temporary ledger exception.
