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
- Site-name arguments for maintenance commands need the same path-segment validation as site creation before reading or creating per-site metadata.
- Rename commands need source and destination validation; a dot-allowing character class still needs explicit `.` and `..` rejection.
- Status, menu, daemon, and HTTPS wrappers need site-name validation too; read-only helpers can still leak outside state, re-exec as an imported user, or mutate daemon/certificate artifacts before downstream validators run.
- Destructive site commands must reject path-shaped names before deriving both the site directory and companion data directory.
- Stop/restart commands must reject path-shaped names before PID-file cleanup, daemon label construction, or service-unit lookup.
- Scheduler/autorebuild helpers must validate local site labels, managed user labels, and relative content roots before cron entries, lock paths, release paths, or ownership changes are formed.
- Path arguments that are echoed in machine-readable status rows should reject line breaks even when the filesystem can technically represent them.
- Names that become service units, daemon labels, process matches, or security users need the same strict validator as create/configure paths.
- Daemon repair commands must validate labels before rendering service files or creating runtime directories such as nginx state paths.
- If a value is both a label and a path component, test create, edit, rename, import, and repair paths for the same contract.
- Template and import paths should share create-path validators because they often write both directories and profile metadata.
- Template-based site creation must validate site names before creating the output root; template paths with spaces should still resolve.
- Template refresh commands must share creation-time site-name validation before removing template-owned subtrees.
- Mutation commands must enforce the same path output contract as list/status commands before writing metadata or renaming folders.
- Wrapper commands must validate before their own early writes; relying on downstream command validation can still leave partial config changes.
- Rebuild/run/install-style commands that print machine-readable rows must reject line-break paths before executing side effects, not only before status-only reads.
- Build commands must validate site/path labels before creating generated output, cache directories, hooks, or feed artifacts.
- Values interpolated into regex matching need stricter name validation than path quoting alone provides.
- Composite refs such as `source:name` must reject unsupported namespaces, missing separators, repeated separators, and trailing words.
- After rejecting a path-like value, assert sibling/outside files were not created, modified, chmodded, or deleted.
- Test path-like values in config files too; imported metadata is input, not trusted source code.
- Hand-edited config values that feed daemon/service config need read-time validation even when writer commands validate them.
- Domain/host identifiers imported from config need read-time validation before TLS tools, generated paths, service config, or machine-readable output reuse them.
- URL fields assembled from generated config need each component revalidated immediately before printing, even when the generator normally writes safe defaults.
- Static artifact generators that embed URLs in feeds, sitemaps, or robots files must revalidate imported URL components at generation time.
- Imported user/group names need validation before privilege changes, ownership changes, account creation, or service User/UserName rendering.
- Account selectors should reject option-like, uid-like, and delimiter-bearing values before `sudo -u`, service unit rendering, plist rendering, or account probes.
- Permission repair commands must validate site/path labels before ownership, chmod, mkdir, or allowlist processing.
- Imported user/group names also need validation before shell-only conveniences such as tilde expansion; `eval "home=~$user"` is command execution if the name is hostile.
- Allowlist/imported path files that drive recursive ownership or permission changes must reject root, project-root ancestors, non-directories, and other overly broad paths on both write and read.
- Allowlist path managers should test both the writer UI and the repair reader; hand-edited allowlist files can bypass add-time validation.
- Imported path values passed through `sh -c` must be supplied as argv or environment values, never interpolated into the shell program string.
- Temporary directories derived from `TMPDIR` are imported paths too; probe scripts should test quote-bearing `TMPDIR` values before using `sh -c`.
- PTY/socat helpers should execute a generated, shell-quoted command script instead of flattening `"$@"` into one `EXEC:` string; test command paths and arguments containing spaces.
- Shell snippets embedded in tool address strings, such as socat `SYSTEM:` addresses, must shell-quote temp-file paths because `TMPDIR` is imported metadata.

### Argument Shape

- Missing operands should fail before side effects.
- Extra operands should fail for mutating commands and eval-printing commands.
- Optional flags should work in every documented position.
- Constrained options must reject unsupported values before platform tools run.
- Natural-language parsers must distinguish reserved connector words from literal filenames.
- Sourced parsers must be tested for repeated independent invocations in one shell, leaked recursion depth, and clobbered caller loop variables.
- Sourced parsers should also preserve caller positional parameters after internal `shift` and `set --` operations.
- Sourced parser scratch variables should use parser-specific names because POSIX shell function variables still leak into callers.
- Parser connector imps that hand off to `parse` must source it, not execute it as a script, and should test the handoff path with remaining words.
- Parser-adjacent caches keyed by command name should reject path-shaped names before reading, deleting, or writing remembered choices.
- Parser-adjacent caches should revalidate cached choice values against the current candidate set before execution.
- Parser-adjacent candidate lists should not use `:`-delimited records for filesystem paths; valid paths can contain colons.
- Synonym targets that include preset arguments must be tested through direct parser recursion, not only through generated shell glosses.
- Generated parser/gloss code must use the same literal lookup semantics as the runtime parser; test regex-shaped names against near-match records.
- Parser synonym targets should include category/path-prefixed spells and must resolve them only under the project spell tree.
- Parser synonym target tests should include path traversal variants alongside valid spell-relative paths, because later fallback scans can bypass an earlier safe-path branch.
- Generated gloss files should be syntax-checked with POSIX `sh -n` after adding aliases or first-word functions for names containing special characters.
- Hand-edited synonym files are imported metadata; test quote-bearing targets so one malformed record cannot make every generated gloss unsourceable.
- Generated gloss synonym targets are shell code unless validated; reject shell metacharacters, globs, and control characters while preserving simple preset-argument targets.
- Generated `sh -c` wrappers should execute quote-bearing command text in tests, not only inspect the generated file.
- Generated glosses that embed an install root must execute parser fallbacks with that root when `WIZARDRY_DIR` is unset; test an isolated root outside `~/.wizardry`.
- Generated parser/gloss functions should be executed under `set -u` with optional environment variables unset, not only syntax-checked.
- Parser and gloss configuration readers should include CRLF config files so disabled flags are not bypassed by carriage returns.
- Parse-disabled generated aliases should be executed with trailing arguments, not only sourced or syntax-checked.
- Parser and gloss synonym readers should execute CRLF synonym targets, not only syntax-check generated output; carriage returns in command names can pass `sh -n` and fail only at runtime.
- Parser system-command fallbacks should preserve nonzero statuses from found utilities instead of rewriting failures as command-not-found.
- Parser system-command fallbacks should execute the found command with only the remaining operands, not repeat the command word as argv[1].

### Shell Expansion

- Quote every variable expansion unless intentionally splitting.
- Disable globbing before intentional word splitting of user-provided strings.
- Test paths and values containing spaces, `*`, `-`, empty strings, and reserved words such as `from` or `to`.
- Connector imps that append or prepend explicit operands should quote those operands separately from intentionally split accumulated argument strings.
- Connector imps that replay accumulated command-argument strings should disable globbing around the intentional split, then restore the prior globbing mode.
- Generated gloss scanners should test `WIZARDRY_DIR` and `SPELLBOOK_DIR` paths containing spaces, especially when feeding file lists to grep or find.
- Candidate path lists should not be space-delimited; test `$HOME`, project roots, and config paths containing spaces.
- Template source candidate lists should be newline-delimited, not command-substitution `for` loops, because install roots commonly contain spaces.
- Template creation and update commands should both be tested with `WIZARDRY_DIR` paths containing spaces because they often resolve shared roots through separate helper loops.
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
- Metadata writers and editors must reject both LF and CR line breaks; reader-side CR stripping can otherwise silently change persisted identifiers.
- Line-based key/value readers can still import CR inside a value; sanitize or fall back before reprinting display names or writing generated launchers.
- CSV-like values must reject leading/trailing commas, empty entries, unsupported characters, and line-break injection.
- Tab-, pipe-, and comma-delimited records must reject delimiter characters in fields before persisting or printing rows for another parser.
- Use delimiter-specific output sanitizers for row formats; `key=value` CR/LF cleanup does not protect TSV or pipe-separated columns.
- Machine-readable `key=value` output must reject CR/LF in echoed values so hostile input cannot forge later keys.
- Reject CR/LF before adding values to newline-delimited candidate lists, not only immediately before output; otherwise the list parser can split hostile values into safe-looking fragments.
- Environment-derived fields such as shell, cwd, platform, and detected helper labels are untrusted when echoed in machine-readable status output.
- Diagnostic/status commands are not exempt from output-shape rules; treat their paths and environment fields as hostile key/value values.
- Validators that print `key=value` summaries should validate or sanitize the file paths they echo, not only the structured data being validated.
- If a command must execute a control-character-bearing path, keep the execution value separate from the sanitized display/status value printed as `key=value`.
- Helper-script stdout and filesystem entry names are untrusted when they are forwarded into GUI/backend records; test installed modules with delimiter-shaped filenames and status lines.
- CGI upload and file-info handlers should test URL-decoded filenames containing path separators, quotes, and HTML delimiters before writing files or reflecting names in HTML.
- File-backed CGI auth should test path-shaped session tokens, generated token alphabets, and username traversal before reading or writing session/user directories.
- Chat room/avatar CGI endpoints should test URL-decoded room and username path segments before any create, delete, or rename filesystem operation.
- CGI JSON endpoints should test quote-bearing config values, filenames, and titles, plus privilege-group near misses such as `blog-admins`.
- Shared CGI data-root helpers should reject path-shaped site-name environment values before composing storage paths for other handlers.
- Chat-style CGI state should test create/delete/rename/send parity for room and avatar names; every endpoint that composes a room path needs the same validator.
- Blog/content CGI renderers should test quote/HTML-bearing front matter, regex-shaped search queries, regex-shaped tags, and invalid numeric pagination values.
- Shared CGI validators should include the stricter label contract expected by all consumers, then rerun stream/list/delete variants that rely on that validator without extra local checks.
- Catalog/list/count commands must apply the same identifier validator as the command that later executes the selected item.
- Read/import paths for hand-edited metadata must revalidate the same delimiters and identifiers enforced by create/update commands.
- Imported profile/config fields must be sanitized at output time even when only a subset of those fields drive filesystem or command actions.
- Fallback readers for cache/state directories should be audited like importers: unsafe filenames and record delimiters can bypass the primary writer.
- Metadata conversions should stage changes and replace originals only after all writes succeed.
- Optional catalog/project tests should skip when an optional checkout is absent but still fail when the checkout exists and required files are broken.
- Front-matter parsing must preserve delimiter-like body content after the closing delimiter.
- Config paths rendered into another language or config format must reject that renderer's quote, variable, comment, and statement delimiters.
- Display names are release inputs when they become bundle paths, archive names, plist text, or build metadata; validate them beyond "single line".
- Config scalars rendered into daemon/server config files should be revalidated at render time; create-time prompts do not protect hand-edited `key=value` files.
- Renderer-specific validation should cover every imported field embedded in that renderer, not just the obvious public URL fields.
- Site names rendered into nginx/Tor/service config must be validated before file writes and before regex matching against existing config.
- Identifier values that may contain regex metacharacters, such as dotted site names, should be compared literally after parsing records instead of interpolated into grep patterns.
- Round-trip tests should include empty values, multi-line values, repeated delimiters, and write failures.

### Release And Remote Metadata

- Treat release asset names, package names, bundle IDs, API filter values, and remote branch/track names as hostile input.
- Validate every release credential identifier consistently across build, upload, and promote helpers before passing them to platform tools.
- Release-control flags should reject unsupported values instead of silently changing deploy, review, or publish behavior.
- Store release-status values should be allowlisted before upload/promotion helpers perform irreversible API work.
- Release tag/version strings become generated project metadata; validate them before rendering build-system files.
- Remote API response fields should be revalidated after structured parsing before they are reused in URLs or status rows.
- Remote API tokens should be revalidated after structured parsing before they are used in HTTP headers.
- Remote API download URLs should be revalidated for scheme/source before any downloader receives them.
- Installer tests that harden `PATH` should inject the downloader explicitly so fake-network regressions cannot silently hit the host `curl`.
- Installer tests for hostile remote metadata should pass downloader and install-target overrides through the sandbox so the test cannot fall back to host tools.
- Service account JSON should be treated as imported release metadata; validate identity fields before JWT rendering.
- Deploy/signing environment values should be validated before remote-shell, codesign, or notarization tooling receives them.
- Remote-shell command strings such as `rsync -e` need shell quoting inside the string; test `TMPDIR` or key paths containing spaces and quotes.
- Asset generators that print status rows should reject line-break paths and unsafe stored file extensions before writing metadata.
- Asset generators should validate stored source extensions before creating output trees so invalid image metadata leaves no partial assets.
- File-artifact builders should validate output suffixes and reject line-break paths before overwriting files or printing status rows.
- Packaging and upload helpers should reject CR/LF in artifact directories, app bundles, and upload paths before staging, signing, or invoking platform tools.
- Upload helpers that print artifact paths should reject CR/LF in artifact input files as well as output directories.
- Platform asset staging should preflight required outputs before copying so missing fallbacks cannot leave stale files behind.
- Preflight path canonicalization must be side-effect-free; rejected destinations should not create missing parent directories under source trees.
- Installer-generated shell or desktop launchers must reject or structurally escape path values containing shell-expansion characters.
- Native packaging entrypoints should validate bundle IDs again before rendering plist or project metadata.
- Backend status rows should sanitize XDG/env-derived file paths, including preference write confirmations.
- Shared root resolvers should reject line-break roots before returning, because downstream commands often echo or persist root paths.
- Plain-text backend outputs still need argument shape checks when GUI code treats the first line as authoritative state.
- Launcher root paths that are persisted for future app starts should reject line breaks before writing config files.
- Install/uninstall helpers should reject explicit replacement or removal paths outside the artifact shape they own before recursive deletion.
- macOS app installers should stage and verify replacement bundles before copying over an existing Applications bundle; never delete the installed app before the replacement copy succeeds.
- Build helpers should reject explicit artifact output paths outside the artifact shape they own before recursive replacement.
- Validate remote metadata before downloads, extraction, install paths, chmod, JWT signing, API URLs, or platform tools run.
- Git remote URLs can contain CR/LF and path-shaped slugs; validate before printing status rows or constructing GitHub API URLs.
- Git remote write commands should reject CR/LF before persisting URLs, even if imported remote status readers sanitize later.
- Stub network tools and feed hostile metadata instead of relying on live services for adversarial release tests.

### GUI And Bridge Surfaces

- GUI controls must not rely on client-only validation; backend validators own the command contract.
- Test create/edit parity: values rejected during creation must not become valid through rename, settings, import, or advanced fields.
- Bridge actions should route to fixed commands with positional args, never user-selected executables or shell fragments.
- Help/about-style bridge actions should map friendly labels to a fixed allowlist instead of executing arbitrary command names with `--help`.
- Direct menu-run and terminal-launch paths should share one-line argument validation so one GUI path cannot accept forged row text the other rejects.
- Menu action strings that include paths should be tested with spaces and quotes because menu execution commonly evals the action payload.
- Menu actions built from allowlist/config files should treat every path as imported metadata and quote it before interpolation into an action string.
- Menu action strings that include names/labels should be tested with shell metacharacters too; downstream validation does not protect the menu eval boundary.
- Menu actions built from imported metadata should shell-quote every embedded field, including fields that the destination command will validate later.
- Menu actions that render config-derived URLs or ports should validate those fields before interpolation; double-quoted command strings still evaluate command substitutions.
- Menu metadata registry keys imported from project config should be validated as single path segments before looking up labels or install commands.
- For Wizardry app GUI specifics, read `/Users/andersaamodt/git/wizardry-apps/.github/adversarial-testing.md`.

### Pipelines and Exit Status

- Under `set -e`, pipelines that may legitimately find no rows need explicit status normalization.
- Do not suppress tool stderr until after validating user-facing option errors.
- Check cleanup and temp-file removal on both success and failure paths.
- Test skip helpers are part of harness correctness: a skipped case should return the harness skip status and increment skip counters, not print an error and pass.

### Platform Differences

- Prefer POSIX constructs and document any exception.
- Exercise BSD/GNU differences for `find`, `stat`, `sed`, `date`, permission predicates, and xattr tools.
- Spell discovery should avoid `find -executable`; use `find -type f` plus `[ -x ]` filtering and test on BSD/macOS.
- Test behavior when optional helper commands are missing by stubbing `PATH`.
- Keep temporary artifacts in `WIZARDRY_TMPDIR`, `TMPDIR`, or another ignored external location.
- Treat repository sync/import scripts as release tools: reject missing or recursive source/target paths, test dotfile copies, and preserve local-only generated/host directories.
- Staging helpers that delete/recreate output directories should reject destinations that overlap source directories before removal.
- Any sync/import script that prints `key=value` status rows should reject line-break paths before echoing canonical source or target values.
- Generated metadata that gets committed or synced should avoid machine-local absolute paths; readers should resolve relative paths against the project and ignore config paths that escape it.
- Relative suffixes between two paths should be computed after both sides are canonicalized; symlinked system paths can otherwise become nested absolute paths.
- Release helper scripts should revalidate manifest fields they print, not rely only on CI ordering around a separate validator.
- Manifest and catalog validators should test future hostile records, not only the current checked-in data, because workflows often iterate those records into paths, package IDs, API calls, and generated files.
- Catalog source subdirectories are repo-internal paths; reject absolute paths, empty components, `.`, `..`, backslashes, tabs, and CR/LF before clone/copy/cache replacement code runs.
- Catalog source subdirectories should be canonicalized after clone; a symlinked subdir that resolves outside the checkout is hostile even if the string passed validation.
- Catalog source repos and refs become cache-lock metadata; reject line breaks before clone, refresh checks, or lock writes.
- Target-list mutation commands need the same allowlist and duplicate rejection as manifest validators, not just delimiter-shape checks.
- Generated app scaffolds should leave manifests valid immediately by writing safe target defaults with the new record.
- Downloaded release archive contents are remote metadata; validate discovered bundle basenames before install paths or status rows are formed.
- Git branch names can be valid refs while still unsafe in compare-page URLs; reject or encode URL delimiter characters before opening PR links.
- "Single-line" validators should reject tabs when the same values can later appear in TSV or other delimiter-based GUI rows.
- When staging generated assets, test partial output directories; each expected file should have an explicit fallback instead of relying on a glob to mean the directory is complete.
- Platform icon staging should verify generated icon sets are complete before copying them; partial sets should fall back or fail loudly.
- Status output that echoes configured commands or generated log paths must sanitize CR/LF separately from execution semantics; shell comments can let hostile command text succeed while forging GUI rows.
- GUI status commands that read manifests should sanitize the manifest fields they echo, even when a separate manifest validator exists.
- GUI preference/config readers should parse and revalidate hand-edited files instead of streaming them directly back to the bridge.
- Project starter templates should carry the same adversarial backend contracts as first-party apps so generated projects do not recreate fixed bugs.
- Log/history readers that feed GUIs should revalidate delimiter row shape and sanitize CR, even when the normal writer already cleans entries.
- Helper command list output should be treated as imported GUI rows and filtered for delimiter shape before forwarding.
- Menu labels built from hand-edited metadata should strip CR before display and command construction, even when writer commands now reject CR.
- Root hint validation belongs in the shared resolver, not only the diagnostic action that prints the resolved root.
- GUI backend root/path candidate lists should stay newline-delimited or argument-list based; space-delimited path lists break valid project roots containing spaces.
- Workspace-relative paths from config and auto-detected child directories should reject CR/LF before they are served, launched, persisted, or echoed as GUI rows.

### Eval-Printing Commands

Commands whose stdout is meant for `eval` or sourcing need stricter failure behavior:

- Validate all operands before printing shell code.
- Shell-quote every printed value structurally; quoting with raw double quotes is not enough for imported paths containing `"`, `$`, backticks, or command substitutions.
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
