# Testing Instructions

applyTo: ".tests/**"

## Required Preflight

- CI runs `banish 8` before `test-magic`.
- Local test runs should source wizardry and run `banish 8` first.
- Level 8 validates through testing infrastructure and is sufficient for unit tests.

```sh
. spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose
. spells/.imps/sys/invoke-wizardry && banish 8 && test-spell category/test-name
```

## Required Tests

- Every spell and imp must have a corresponding test file.
- Test files mirror `spells/` exactly.
- Project-wide validation checks belong in existing spells such as `lint-magic`, `test-magic`, or common tests; do not invent orphan test files.
- Test filenames use `test-<name>.sh` with hyphens, never underscores.
- Spell test: `spells/category/spell-name` -> `.tests/category/test-spell-name.sh`.
- Imp test: `spells/.imps/family/imp-name` -> `.tests/.imps/family/test-imp-name.sh`.

## Adversarial Tests

- Adversarial tests are required for user input, imported metadata, filesystem paths, shell evaluation, generated code, remote data, GUI/menu bridges, CGI endpoints, installers, release flows, and destructive side effects.
- Use `.github/adversarial-testing.md` as the canonical standard.
- Add new bug classes to `.github/adversarial-testing.md`.
- Add concise reusable lessons to `.github/LESSONS.md` or the relevant topic doc.

Common adversarial fixtures:
- path-shaped names such as `.`, `..`, slashes, backslashes, leading dashes, spaces, and line breaks
- hand-edited config/cache/metadata that bypasses the normal writer
- quote, glob, delimiter, regex, CRLF, and shell-metacharacter values
- missing, stale, partial, symlinked, or permission-denied filesystem state
- fake network/package-manager/tool outputs instead of live services
- parser/gloss/menu/PTY inputs that exercise caller state and command boundaries

## Test-Driven Flow

1. Write tests that reproduce the bug or test the new feature FIRST
2. Run tests to verify they fail for the expected reason
3. Add at least one adversarial test for the highest-risk input, metadata, or state boundary touched by the change
4. Fix the code
5. Run tests again to verify they pass
6. Update `.github/adversarial-testing.md` and `.github/LESSONS.md` when a new reusable bug class or lesson is found
7. Only then report the fix as complete

Never claim code works without running actual tests.

## Repository Hygiene For Tests

- Test output is operator-local runtime state, not repository content.
- Write transient test and assay output under temp/XDG state paths, not inside the checkout, unless the file is a deliberate fixture.
- Check in fixtures only when they are stable behavior contracts; do not check in raw run output, transcripts, or ad hoc debug captures.
- If a test helper must create a repo-adjacent generated path, ignore it and document why it cannot live elsewhere.
- Follow `.github/PUSH_READY_CHECKLIST.md` for final repo-hygiene and publish-surface review.

## Stub Imps

- Reusable stubs live in `spells/.imps/test/stub-*`.
- Stub directory must be first in `PATH`.
- Stub the minimum necessary; test real wizardry for everything else.
- Stub terminal/system boundaries, not wizardry internals.
- Use symlinks to reusable stubs; do not inline stubs in test files.

Common stubs:
- `stub-fathom-cursor` - Mock cursor position detection
- `stub-fathom-terminal` - Mock terminal size detection
- `stub-move-cursor` - Mock cursor movement (no-op)
- `stub-cursor-blink` - Mock cursor visibility control
- `stub-stty` - Mock terminal settings

```sh
stub_dir="$tmpdir/stubs"
mkdir -p "$stub_dir"
for stub in fathom-cursor fathom-terminal move-cursor; do
  ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
done
PATH="$stub_dir:$ROOT_DIR/spells/cantrips:...:$PATH" run_spell "spells/cantrips/menu"
```

## Interactive Tests

- Use real PTY testing for interactive behavior; do not mock menu navigation or raw terminal behavior.
- `banish 8` checks `socat`; tests that require it should fail or skip explicitly according to their contract.
- `run-with-pty COMMAND [ARGS]` - recommended helper for symbolic key input.
- `socat-pty COMMAND [ARGS]` - Advanced PTY allocation
- `socat-send-keys KEYS` - Convert symbolic keys to raw escape bytes
- `socat-normalize-output` - Strip ANSI codes and carriage returns from output

Supported `PTY_KEYS`: `enter`, `up`, `down`, `left`, `right`, `escape`/`esc`, `tab`, `space`, `backspace`; other words are literal text.
Use `PTY_INPUT` for raw bytes such as `text\n`.

```sh
test_menu_navigation() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  # Use PTY_KEYS for symbolic key input (converted to escape sequences)
  PTY_KEYS="down down enter" run_cmd run-with-pty \
    menu "Select option:" \
    "First%cmd1" "Second%cmd2" "Third%cmd3"
  
  assert_success || return 1
  assert_output_contains "cmd2" || return 1  # Selected second item
}
```

## Test Result Accuracy

- Never report test success without running the tests.
- Wrong: "All tests pass" without a command result.
- Wrong: "Tests should pass" or "I expect tests to succeed."
- Correct: "5/5 tests passed" after running the test.
- Correct: "Tests created but not yet verified" when not run.
- Prefer `test-spell` for single-spell work because it also runs common structural tests.

```sh
./spells/system/test-spell category/test-spell-name.sh
./spells/system/test-spell --skip-common category/test-spell-name.sh
.tests/category/test-spell-name.sh
```

## Test File Location and Naming

| Spell Path | Test Path | Correct |
|------------|-----------|---------|
| `spells/category/spell-name` | `.tests/category/test-spell-name.sh` | correct |
| `spells/category/spell-name` | `.tests/category/test_spell-name.sh` | wrong: underscore |
| `spells/.imps/family/imp-name` | `.tests/.imps/family/test-imp-name.sh` | correct |
| `spells/.imps/family/imp-name` | `.tests/.imps/family/test_imp-name.sh` | wrong: underscore |

- Do not create orphan validation tests such as `.tests/spellcraft/test-no-duplicate-set-eu.sh` without a matching spell.
- Put project-wide validation in existing validation spells or common tests.

## Test Template

```sh
#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/category/spell-name" --help
  assert_success && assert_output_contains "Usage:"
}

run_test_case "spell prints usage" test_help
finish_tests
```

## Test Helpers

```sh
# Run a spell
run_spell "spells/path/to/spell" arg1 arg2

# Assertions
assert_success || return 1
assert_failure || return 1
assert_output_contains "expected text" || return 1
assert_error_contains "error text" || return 1

# Create temp directory
tmpdir=$(make_tempdir)
```

## PATH Isolation for Tests

- Use real wizardry with minimal stubs.
- Put stub directory first in `PATH`.
- Include `/bin` and `/usr/bin` when building restricted paths.
- Normalize paths before assertions with `pwd -P` and `sed 's|//|/|g'`.
- Use `make_tempdir` for portable temporary directories.

```sh
stub_dir="$tmpdir/stubs"
mkdir -p "$stub_dir"
for stub in fathom-cursor fathom-terminal stty; do
  ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
done

for util in sh sed cat printf test env basename dirname; do
  util_path=$(command -v "$util" 2>/dev/null) || continue
  [ -x "$util_path" ] && ln -sf "$util_path" "$stub_dir/$util"
done

PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:...:$PATH" run_spell "spells/category/spell"
```

## Test Coverage

Every test should cover:
1. `--help` output
2. Success cases
3. Error cases
4. Platform-specific fallbacks if applicable
