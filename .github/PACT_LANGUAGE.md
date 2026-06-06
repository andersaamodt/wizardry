# Pact Language

Pacts are wizardry's semanthesis layer for reliability contracts. A pact marker is a POSIX null command whose arguments are parsed and sequenced but do not cause action:

```sh
: pact publish-safely
: threshold imported-site-name
: essence site-name "$site_name"
: divine site-name "$site_name"
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
| `enthrall` | Reserves exclusive command over a resource such as a lock, release path, service, or port. |
| `disenthrall` | Releases an enthralled resource and returns it to ordinary use. |

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
- Treat `enthrall` and `disenthrall` as reserved pact words for resource exclusivity. Do not document them as commands until helper imps exist.

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

## AI Usage Rules

Use pacts as a compact proof outline beside real code. A good pact shows:

- what untrusted material crosses a threshold
- what essence a value must have after validation
- what taboo operation is being crossed
- what protections justify the transgression
- what cleanup, release, or seal closes the work

Do not use pact markers as decoration. If a linear block has no trust boundary, destructive effect, generated output, external metadata, privilege boundary, lock, temp file, or machine-readable output, leave it unmarked.

Prefer this shape:

```sh
: pact update-template-files
: threshold site-config
if ! site_name_is_safe "$site_name"; then
  die 2 "invalid site name"
fi
: essence site-name "$site_name"
: divine site-name "$site_name"
: taboo overwrite-template-owned-files

: foresee template-update "$site_name"
: transgress overwrite-template-owned-files site-name-divined template-divined confirmed-or-forced
rm -rf "$site_dir/site/pages"
: seal template-update "$site_name"
```

Avoid this shape:

```sh
: pact ordinary-loop
: ward every-line
while IFS= read -r line; do
  : divine line "$line"
  printf '%s\n' "$line"
done
```

The second example adds ceremony and runtime work without improving the contract.

## Wards

Use `ward` when a reusable boundary check is clearer than an inline `case` block. Use inline checks when the validation is local, cheap, and only used once.

Good ward sites:

- account names, site names, release URLs, status rows, menu rows, GUI records
- paths before mutation, copy, deletion, ownership changes, or release staging
- values imported from config, generated metadata, remote APIs, or filesystem names

Do not call `ward` inside hot loops over many rows. `ward` is an imp and therefore a subprocess; high-volume validation should be batched or inlined.

## Sigils

Use `sigil` for output that another tool will parse. It is especially useful before writing `key=value`, TSV, JSON strings, status rows, menu rows, or GUI/backend records. Revalidate imported data at the output boundary; a value may have been safe for a path but unsafe for a row format.

## Hexagrams

Use `hexagram` for tests and risky probes that should not inherit the caller's `HOME`, `TMPDIR`, or ambient tool path. It is a small hermetic shell, not a full container. Use it to reduce accidental coupling; do not claim it is a complete security sandbox.

## Promises

Use `promise` for obligations created by temp files, locks, partial writes, staged releases, privilege changes, or environment changes. Close every promise with `fulfill` when the obligation was completed, or `release` when it was intentionally abandoned.

Prefer pairing promises with real cleanup:

```sh
tmp_bin=$(mktemp "${TMPDIR:-/tmp}/tool.XXXXXX")
: promise cleanse-tool "$tmp_bin"
if ! fetch_url "$url" -o "$tmp_bin"; then
  : cleanse cleanse-tool "$tmp_bin"
  rm -f "$tmp_bin"
  : fulfill cleanse-tool "$tmp_bin"
  return 1
fi
```

## Taboos

Use `taboo` / `transgress` around dangerous but legitimate operations: `sudo`, remote shell, `sh -c`, recursive deletion, recursive ownership, generated shell, config rendering, release swaps, and direct writes to service/runtime state. `transgress` must name the protections that make the crossing acceptable.

## Resource Exclusivity

For exclusive control over a resource, use the language `enthrall` / `disenthrall` in pact markers. Until dedicated helper imps exist, pair the markers with the concrete lock or atomic directory operation already used by the spell.

```sh
: promise disenthrall-release "$lock_dir"
: enthrall release "$lock_dir"
if ! mkdir "$lock_dir" 2>/dev/null; then
  die "release already in progress"
fi

# protected work

rm -rf "$lock_dir"
: disenthrall release "$lock_dir"
: fulfill disenthrall-release "$lock_dir"
```

Prefer `disenthrall` over `unthrall`: it is clearer in code and less likely to be mistaken for a typo.

## Performance

Pact markers using `:` are shell builtins and are acceptable at high-risk boundaries. External helpers such as `ward`, `sigil`, `hexagram`, and `read-pacts` may fork subprocesses. Use them at thresholds, not as per-row ceremony in hot loops. If a protection belongs inside a tight scan, inline it or batch it.
