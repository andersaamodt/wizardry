# Pact Language

Pacts are wizardry's semanthesis layer for reliability contracts. A pact marker is a POSIX null command whose arguments are parsed and sequenced but do not cause action:

```sh
: pact publish-safely
: threshold imported-site-name
: essence site-name "$site_name"
divine site-name "$site_name"
```

This keeps meaning separate from mechanism: pact markers make intent visible to readers and tooling, while ordinary spells and imps still perform every effect explicitly.

## Vocabulary

| Word | Role |
| --- | --- |
| `pact` | Declares the reliability contract governing a section or spell. |
| `ward` | Names a boundary that must be protected before side effects. |
| `essence` | Names the safe kind a value must have, such as `site-name`, `domain`, or `release-url`. |
| `divine` | Confirms an essence, usually beside a real validator or `divine` imp. |
| `foresee` | Marks a preflight check before mutation, rendering, deploy, or release. |
| `hexagram` | Marks a hermetic working space such as a restricted `PATH`, fake network, or disposable root. |
| `promise` | Records an obligation that must later be completed or intentionally released. |
| `fulfill` | Closes a completed promise. |
| `release` | Intentionally unbinds a promise, lock, or relation. |
| `seal` | Marks atomic finalization after validation succeeds. |
| `cleanse` | Marks cleanup or restoration of temporary, partial, or altered state. |
| `taboo` | Marks a dangerous surface such as `sh -c`, remote shell, `sudo`, destructive writes, or config rendering. |
| `transgress` | Marks a justified crossing of a taboo, with concrete protections named locally. |
| `sigil` | Marks safe machine-readable representation for `key=value`, TSV, JSON, menu, or GUI rows. |
| `threshold` | Marks where untrusted input or imported metadata enters a trusted action path. |
| `witness` | Acknowledges a meaningful state without causing another effect. |
| `vow` | Names an enduring project or spell constraint, not a routine action exception. |

## Tooling Rules

- `lint-magic` runs `check-pact-language` on each target.
- `read-pacts` lists pact markers in one file or across the spell tree.
- `wards` lists known ward checks; `ward NAME ...` runs a concrete ward.
- `sigil FORMAT ...` emits safe machine-readable output for supported formats.
- `hexagram COMMAND...` runs a command in a clean disposable environment.
- Pact names must be safe labels: no empty names, `.`, `..`, leading `-`, slashes, spaces, or shell punctuation.
- Once a file declares `: pact NAME`, later semanthesis lines must use known pact words.
- Every `: promise NAME ...` must later be matched by `: fulfill NAME ...` or `: release NAME ...`.
- Every `: transgress NAME ...` must follow a matching `: taboo NAME` and include at least one reason.
- `: essence KIND ...` and `: divine KIND ...` need both a kind and the value being treated as that kind.

## Operational Helpers

| Command | Use |
| --- | --- |
| `read-pacts [FILE...]` | Inspect pact structure without executing a spell. |
| `wards` | Show reusable wards. |
| `ward safe-label VALUE` | Check safe identifier shape. |
| `ward no-linebreak VALUE` | Reject line-forging values. |
| `ward path-contained PATH ROOT` | Check that a path resolves under a root. |
| `ward release-url-allowlisted URL PREFIX` | Check release download origin. |
| `ward status-row-safe VALUE` | Check output destined for status rows. |
| `sigil key-value KEY VALUE` | Emit a safe `key=value` row. |
| `sigil tsv VALUE` | Emit a safe TSV field. |
| `sigil json-string VALUE` | Emit a quoted JSON string for simple scalar values. |
| `hexagram COMMAND...` | Run a command with disposable `HOME` and `TMPDIR`. |

## Usage Guidance

Use pact language where it clarifies real risk: filesystem mutation, generated code, remote metadata, config rendering, privilege changes, release swaps, parser/eval surfaces, and machine-readable output. Do not annotate harmless linear code just to decorate it.

Pact markers are not enforcement by themselves. The enforcement remains the concrete validator, cleanup, lock, test, or atomic operation next to the marker.
