# Wizardry AI Instructions

## PR Debug Loop

- When fixing PR failures, run `./.github/read-test-failures <pr-number>` first.
- Do not ask users to paste CI output when the script can fetch it.
- The failure reader surfaces unit-test summaries, `FAILED`/`ERROR` lines, workflow `##[error]` markers, early `not found`/`Permission denied` failures, and strips cleanup noise.
- Fix direct regressions first.
- Fix unrelated preexisting failures too if they block merge.
- Re-run or re-read failures until all blocking CI issues are gone.
- Commit surgical fixes as you go.

## Required Reading

- `README.md` - most canonical project philosophy, values, and standards.
- `.github/FULL_SPEC.md` - canonical technical specification.
- `.github/CODEX.md` - concise Codex operating guide.
- `.github/SHELL_CODE_PATTERNS.md` - POSIX shell idioms and quirks.
- `.github/CROSS_PLATFORM_PATTERNS.md` - cross-platform rules.
- `.github/adversarial-testing.md` - living adversarial audit standard.
- `.github/tests.md` - test structure and required testing workflow.
- `.github/EXEMPTIONS.md` - documented exceptions.
- `.github/LESSONS.md` - one-line debugging lessons; update after bug fixes.

## Non-Negotiable Rules

- Use POSIX sh only: `#!/bin/sh`, `[ ]`, `=`, `.`, `$()`, no arrays, no `local`, no `[[ ]]`.
- Quote variables unless intentional splitting is documented.
- Use `printf`, not `echo`.
- Use `command -v`, not `which`.
- Keep spells in `spells/`, imps in `spells/.imps/`, tests in mirrored `.tests/` paths.
- Every new spell or imp needs a matching test file.
- Test filenames use hyphens: `test-spell-name.sh`, not `test_spell-name.sh`.
- Report only test results you actually ran, with exact pass/fail counts.
- Add adversarial tests for risky input, imported metadata, path boundaries, shell evaluation, generated code, remote data, GUI/menu bridges, CGI endpoints, installers, releases, and destructive side effects.
- Update `.github/adversarial-testing.md` when you discover a new bug class or audit technique.
- Add a one-sentence `.github/LESSONS.md` entry after every bug fix or debugging session unless already captured.
- Do not use environment variables to coordinate behavior between spells; use arguments, return codes, files, or `builtin`/`command` patterns documented in `SHELL_CODE_PATTERNS.md`.
- Document new POSIX shell patterns in `.github/SHELL_CODE_PATTERNS.md`.
- Document new cross-platform discoveries in `.github/CROSS_PLATFORM_PATTERNS.md`.
- Create new imps only for reused/internal behavior; prefer existing imps before inline helpers.
- Spells can assume wizardry is installed and in `PATH`; testing setup belongs in tests, not spell code.
- Error messages are descriptive, not imperative; prefer self-healing missing prerequisites.
- Do not add new exemptions without explicit reason and `.github/EXEMPTIONS.md` documentation.
- Do not create AI/debug docs in the repo root; AI-facing docs belong in `.github/`.
- Preserve user-facing help text, flavor text, and project lore unless explicitly changing them.

## Spell Calling Convention

- Spell and imp command calls use hyphenated names from `PATH`: `env-clear`, `temp-file`, `has git`.
- Function names use underscores because POSIX functions cannot contain hyphens.
- Do not call wizardry commands by full `$WIZARDRY_DIR/spells/...` paths outside documented bootstrap exceptions.
- See `.github/glossary-and-function-architecture.md` and `.github/bootstrapping.md` for sourced/uncastable behavior.

## Testing Workflow

- For local test runs, source wizardry and run `banish 8` first when practical.
- Preferred single-spell run: `./spells/system/test-spell category/test-spell-name.sh`.
- Focused direct run is acceptable: `.tests/category/test-spell-name.sh`.
- Run `lint-magic <spell>` for touched spells.
- Run `checkbashisms <spell>` for touched spells.
- Run `.tests/common-tests.sh` after structural documentation, naming, mode, or spell layout changes.
- Keep transient test output in temp/XDG paths, not in the checkout.

## Adversarial Checklist

- Arguments: missing operands, extra operands, option order, unsupported values.
- Paths and labels: `.`, `..`, slashes, backslashes, line breaks, leading dashes, spaces, symlinks.
- Imported metadata: hand-edited config, cache files, manifests, filenames, remote JSON.
- Shell boundaries: quotes, globs, delimiters, regex metacharacters, CRLF, `sh -c`, menu action strings.
- Parser/gloss: caller state, recursion depth, disabled modes, synonym targets with args, regex-shaped names.
- Output contracts: `key=value`, TSV, JSON, HTML, forged line breaks, stderr/stdout separation.
- Filesystem state: missing, empty, stale, partial, permission-denied, rollback on failure.
- Install/release: fake network tools, package-manager absence, hostile remote metadata, PATH precedence.
- Test harness: executable bits, stale helper names, skip helpers, env overrides reaching subprocesses.

## Documentation Style

- Prefer atomic bullets like `.github/LESSONS.md`.
- Put durable specifics in the most relevant canonical doc.
- Replace duplicated prose with links to the canonical doc.
- Keep examples current; delete stale templates instead of leaving contradictions.
- If a lesson changes the spec, update both `.github/LESSONS.md` and `.github/FULL_SPEC.md`.

## Reference Commands

```sh
./.github/read-test-failures <pr-number>
. spells/.imps/sys/invoke-wizardry && banish 8
./spells/system/test-spell category/test-spell-name.sh
.tests/common-tests.sh
lint-magic spells/category/spell-name
checkbashisms spells/category/spell-name
```
