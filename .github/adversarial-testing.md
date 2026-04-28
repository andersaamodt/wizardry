# Adversarial Testing Standard

Use this standard when auditing Wizardry spells, imps, installers, generated apps, and Wizardry-style shell projects. The goal is to find realistic bugs through hostile-but-plausible inputs and failure paths, then fix the issues that are wise to fix without adding broad, speculative hardening.

## Core Method

1. Read the relevant `.github/` standards before changing code.
2. Pick one narrow behavior surface: arguments, filesystem state, metadata, command output, interactivity, or platform dependency.
3. Write a regression test that captures the adversarial case.
4. Run the test and confirm it fails for the expected reason.
5. Make the smallest code change that restores the command contract.
6. Re-run the focused test, POSIX checks, and style checks for touched spells.
7. Add any reusable lesson to `.github/LESSONS.md` or a topic guide.
8. Commit the completed batch before continuing.

Prefer cases a real user, shell, filesystem, or platform can trigger. Avoid turning simple commands into large validation frameworks unless the bug can corrupt data, run the wrong action, print eval-able unsafe output, or hide a meaningful failure.

## High-Value Bug Classes

### Path And Name Boundaries

- Values used as path segments must reject `.`, `..`, `/`, `\`, empty values, and line breaks before side effects.
- Path arguments that are echoed in machine-readable status rows should reject line breaks even when the filesystem can technically represent them.
- If a value is both a label and a path component, test create, edit, rename, import, and repair paths for the same contract.
- Template and import paths should share create-path validators because they often write both directories and profile metadata.
- Values interpolated into regex matching need stricter name validation than path quoting alone provides.
- Composite refs such as `source:name` must reject unsupported namespaces, missing separators, repeated separators, and trailing words.
- After rejecting a path-like value, assert sibling/outside files were not created, modified, chmodded, or deleted.
- Test path-like values in config files too; imported metadata is input, not trusted source code.

### Argument Shape

- Missing operands should fail before side effects.
- Extra operands should fail for mutating commands and eval-printing commands.
- Optional flags should work in every documented position.
- Constrained options must reject unsupported values before platform tools run.
- Natural-language parsers must distinguish reserved connector words from literal filenames.
- Sourced parsers must be tested for repeated independent invocations in one shell, leaked recursion depth, and clobbered caller loop variables.
- Synonym targets that include preset arguments must be tested through direct parser recursion, not only through generated shell glosses.
- Generated parser/gloss code must use the same literal lookup semantics as the runtime parser; test regex-shaped names against near-match records.
- Parser synonym targets should include category/path-prefixed spells and must resolve them only under the project spell tree.
- Generated gloss files should be syntax-checked with POSIX `sh -n` after adding aliases or first-word functions for names containing special characters.
- Hand-edited synonym files are imported metadata; test quote-bearing targets so one malformed record cannot make every generated gloss unsourceable.
- Generated parser/gloss functions should be executed under `set -u` with optional environment variables unset, not only syntax-checked.
- Parser and gloss configuration readers should include CRLF config files so disabled flags are not bypassed by carriage returns.
- Parse-disabled generated aliases should be executed with trailing arguments, not only sourced or syntax-checked.

### Shell Expansion

- Quote every variable expansion unless intentionally splitting.
- Disable globbing before intentional word splitting of user-provided strings.
- Test paths and values containing spaces, `*`, `-`, empty strings, and reserved words such as `from` or `to`.
- Use `--` when passing user paths to commands that support it.

### Numeric and Interactive Input

- Signed integer validators must reject a bare sign before arithmetic comparison.
- Empty input, EOF, non-interactive stdin, defaults, min/max inversions, and retry loops need regression coverage.
- Usage output should be clean on stderr for invalid invocation and stdout for help.

### Filesystem State

- Test missing files, missing directories, empty directories, existing output files, symlinks when relevant, and paths with spaces.
- Directory listings should handle unmatched globs explicitly.
- Generated outputs should be rewritten unless append mode is part of the contract.
- Dry runs must not overwrite existing files or leave temp files behind.

### Metadata and Structured Data

- Key-value files must keep keys allowlisted and values single-line unless multi-line values are the explicit file format.
- CSV-like values must reject leading/trailing commas, empty entries, unsupported characters, and line-break injection.
- Tab-, pipe-, and comma-delimited records must reject delimiter characters in fields before persisting or printing rows for another parser.
- Use delimiter-specific output sanitizers for row formats; `key=value` CR/LF cleanup does not protect TSV or pipe-separated columns.
- Machine-readable `key=value` output must reject CR/LF in echoed values so hostile input cannot forge later keys.
- Environment-derived fields such as shell, cwd, platform, and detected helper labels are untrusted when echoed in machine-readable status output.
- Diagnostic/status commands are not exempt from output-shape rules; treat their paths and environment fields as hostile key/value values.
- If a command must execute a control-character-bearing path, keep the execution value separate from the sanitized display/status value printed as `key=value`.
- Helper-script stdout and filesystem entry names are untrusted when they are forwarded into GUI/backend records; test installed modules with delimiter-shaped filenames and status lines.
- Catalog/list/count commands must apply the same identifier validator as the command that later executes the selected item.
- Read/import paths for hand-edited metadata must revalidate the same delimiters and identifiers enforced by create/update commands.
- Imported profile/config fields must be sanitized at output time even when only a subset of those fields drive filesystem or command actions.
- Fallback readers for cache/state directories should be audited like importers: unsafe filenames and record delimiters can bypass the primary writer.
- Metadata conversions should stage changes and replace originals only after all writes succeed.
- Front-matter parsing must preserve delimiter-like body content after the closing delimiter.
- Config paths rendered into another language or config format must reject that renderer's quote, variable, comment, and statement delimiters.
- Round-trip tests should include empty values, multi-line values, repeated delimiters, and write failures.

### Release And Remote Metadata

- Treat release asset names, package names, bundle IDs, API filter values, and remote branch/track names as hostile input.
- Validate every release credential identifier consistently across build, upload, and promote helpers before passing them to platform tools.
- Validate remote metadata before downloads, extraction, install paths, chmod, JWT signing, API URLs, or platform tools run.
- Git remote URLs can contain CR/LF and path-shaped slugs; validate before printing status rows or constructing GitHub API URLs.
- Stub network tools and feed hostile metadata instead of relying on live services for adversarial release tests.

### GUI And Bridge Surfaces

- GUI controls must not rely on client-only validation; backend validators own the command contract.
- Test create/edit parity: values rejected during creation must not become valid through rename, settings, import, or advanced fields.
- Bridge actions should route to fixed commands with positional args, never user-selected executables or shell fragments.
- For Wizardry app GUI specifics, read `/Users/andersaamodt/git/wizardry-apps/.github/adversarial-testing.md`.

### Pipelines and Exit Status

- Under `set -e`, pipelines that may legitimately find no rows need explicit status normalization.
- Do not suppress tool stderr until after validating user-facing option errors.
- Check cleanup and temp-file removal on both success and failure paths.

### Platform Differences

- Prefer POSIX constructs and document any exception.
- Exercise BSD/GNU differences for `find`, `stat`, `sed`, `date`, permission predicates, and xattr tools.
- Test behavior when optional helper commands are missing by stubbing `PATH`.
- Keep temporary artifacts in `WIZARDRY_TMPDIR`, `TMPDIR`, or another ignored external location.
- Treat repository sync/import scripts as release tools: reject missing or recursive source/target paths, test dotfile copies, and preserve local-only generated/host directories.
- Staging helpers that delete/recreate output directories should reject destinations that overlap source directories before removal.
- Any sync/import script that prints `key=value` status rows should reject line-break paths before echoing canonical source or target values.
- Generated metadata that gets committed or synced should avoid machine-local absolute paths; readers should resolve relative paths against the project and ignore config paths that escape it.
- Release helper scripts should revalidate manifest fields they print, not rely only on CI ordering around a separate validator.
- Manifest and catalog validators should test future hostile records, not only the current checked-in data, because workflows often iterate those records into paths, package IDs, API calls, and generated files.
- "Single-line" validators should reject tabs when the same values can later appear in TSV or other delimiter-based GUI rows.
- When staging generated assets, test partial output directories; each expected file should have an explicit fallback instead of relying on a glob to mean the directory is complete.
- Platform icon staging should verify generated icon sets are complete before copying them; partial sets should fall back or fail loudly.
- Status output that echoes configured commands or generated log paths must sanitize CR/LF separately from execution semantics; shell comments can let hostile command text succeed while forging GUI rows.
- GUI status commands that read manifests should sanitize the manifest fields they echo, even when a separate manifest validator exists.
- GUI preference/config readers should parse and revalidate hand-edited files instead of streaming them directly back to the bridge.
- Project starter templates should carry the same adversarial backend contracts as first-party apps so generated projects do not recreate fixed bugs.
- Log/history readers that feed GUIs should revalidate delimiter row shape and sanitize CR, even when the normal writer already cleans entries.
- Helper command list output should be treated as imported GUI rows and filtered for delimiter shape before forwarding.

### Eval-Printing Commands

Commands whose stdout is meant for `eval` or sourcing need stricter failure behavior:

- Validate all operands before printing shell code.
- If a destination or target is invalid, exit nonzero and print no eval-able command.
- Reject extra operands even when the first operand would be valid.

## Audit Recipe

For each command, ask:

- What does it do if every argument after the first is junk?
- What if an option appears after operands?
- What if a filename equals a parser keyword?
- What if a path contains spaces or glob characters?
- What if the target already exists?
- What if the target disappears between read and write?
- What if a helper command is missing or returns malformed output?
- What if the command is run twice?
- What if no matches are found?
- What if a write fails halfway through?

## Regression Pattern

Keep tests small and named after the failure mode:

```sh
test_rejects_extra_operands() {
  run_spell "spells/category/spell-name" good extra
  assert_failure || return 1
  assert_error_contains "expected message" || return 1
}
```

For dependency failures, stub only the required command in a temp `PATH`:

```sh
tmpdir=$(make_tempdir)
stubdir=$tmpdir/bin
mkdir -p "$stubdir"
{
  printf '%s\n' '#!/bin/sh'
  printf '%s\n' 'exit 1'
} > "$stubdir/helper"
chmod +x "$stubdir/helper"

PATH="$stubdir:$PATH" run_spell "spells/category/spell-name" arg
assert_failure || return 1
```

For eval-printing commands, assert failure output does not contain command text:

```sh
case "$OUTPUT" in
  *'cd "'*)
    TEST_FAILURE_REASON="printed eval-able output after failure"
    return 1
    ;;
esac
```
