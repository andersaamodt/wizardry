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
- If a value is both a label and a path component, test create, edit, rename, import, and repair paths for the same contract.
- Composite refs such as `source:name` must reject unsupported namespaces, missing separators, repeated separators, and trailing words.
- After rejecting a path-like value, assert sibling/outside files were not created, modified, chmodded, or deleted.
- Test path-like values in config files too; imported metadata is input, not trusted source code.

### Argument Shape

- Missing operands should fail before side effects.
- Extra operands should fail for mutating commands and eval-printing commands.
- Optional flags should work in every documented position.
- Constrained options must reject unsupported values before platform tools run.
- Natural-language parsers must distinguish reserved connector words from literal filenames.

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
- Metadata conversions should stage changes and replace originals only after all writes succeed.
- Front-matter parsing must preserve delimiter-like body content after the closing delimiter.
- Round-trip tests should include empty values, multi-line values, repeated delimiters, and write failures.

### Release And Remote Metadata

- Treat release asset names, package names, bundle IDs, API filter values, and remote branch/track names as hostile input.
- Validate remote metadata before downloads, extraction, install paths, chmod, JWT signing, API URLs, or platform tools run.
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
