# Best Practices from Wizardry Codebase

applyTo: "spells/**,.tests/**"

Proven patterns from the wizardry repository. Use these when creating/modifying code.

## Self-Execute Pattern

**For invocable spells (sourced + executed):**
```sh
spell_name() {
  # Function body
}
case "$0" in
  */spell-name) spell_name "$@" ;; esac
```
**Why:** Works both sourced (invoke-wizardry) and executed (tests/users)

## PATH Baseline (Bootstrap Only)

**Set baseline BEFORE `set -eu`:**
```sh
baseline_path="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
case ":${PATH-}:" in
  *":/usr/bin:"*|*":/bin:"*) ;;
  *) PATH="${baseline_path}${PATH:+:}${PATH-}" ;;
esac
export PATH
set -eu
```
**Why:** macOS CI starts with empty PATH

## env-clear Sourcing

```sh
case "${1-}" in
--help|--usage|-h) show_usage; exit 0 ;; esac
require-wizardry || exit 1
set -eu
. env-clear  # After set -eu, before main logic
```
**Why:** Clears env vars but preserves wizardry/system/test vars

## Function Discipline

**Spell complexity limits:**
- `show_usage()` required
- 0-1 helper function: freely allowed
- 2 helpers: acceptable with warning
- 3 helpers: marginal
- 4+ helpers: split into multiple spells or extract to imps

**Why:** Spells are scrolls (linear), not programs (branching)

## Stub Imps for Tests

**Create reusable stubs in `spells/.imps/test/stub-*`:**
```sh
#!/bin/sh
# stub-example - test stub for example command
_stub_example() {
  printf 'mocked-output\n'
}
case "$0" in
  */stub-example) _stub_example "$@" ;; esac
```

**Use via symlinks in tests:**
```sh
stub_dir="$tmpdir/stubs"
mkdir -p "$stub_dir"
ln -s "$ROOT_DIR/spells/.imps/test/stub-fathom-cursor" "$stub_dir/fathom-cursor"
PATH="$stub_dir:$PATH" run_spell "spells/cantrips/menu"
```
**Why:** Reusable, consistent mocking (no inline stubs)

## Test Naming

**Pattern:** `test-<name>.sh` (hyphens, NOT underscores)

| Spell | Test |
|-------|------|
| `spells/cantrips/ask-yn` | `.tests/cantrips/test-ask-yn.sh` |
| `spells/.imps/out/say` | `.tests/.imps/out/test-say.sh` |

**Common mistake:** `test_spell-name.sh` ✗

## Test Bootstrap

**Find repo root and source test framework:**
```sh
#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_feature() {
  _run_spell "spells/category/name" arg
  _assert_success && _assert_output_contains "expected"
}
_run_test_case "description" test_feature
_finish_tests
```

## Error Messages

**Descriptive, not imperative:**
```sh
# ✓ RIGHT
die "spell-name: sshfs not found"
warn "spell-name: configuration missing"

# ✗ WRONG
die "Please install sshfs"
warn "You must create a configuration file"
```
**Why:** Self-healing philosophy (fix problems, don't demand fixes)

## require-wizardry Pattern

```sh
case "${1-}" in
--help|--usage|-h) show_usage; exit 0 ;; esac
require-wizardry || exit 1  # Before set -eu, before imps
set -eu
. env-clear
```
**Why:** Ensures wizardry available, exits gracefully if missing

## Variable Defaults

```sh
value=${1-}              # Empty if unset (most common)
value=${1:-default}      # "default" if unset OR empty
: "${VAR:=default}"      # Sets VAR to "default" if unset/empty
```
**With `set -u`:** Always provide defaults to avoid "unbound variable" errors

## Conditional Imps Don't Use set -eu

**Conditional imps (return exit codes for flow control):**
```sh
#!/bin/sh
# has COMMAND - test if exists
_has() {
  command -v "$1" >/dev/null 2>&1
}
case "$0" in
  */has) _has "$@" ;; esac
```
**No `set -eu`** - designed for `if`, `&&`, `||` where non-zero = false

**Action imps DO use `set -eu`** (everything except cond/, lex/, some menu/)

## Summary

| Pattern | Use When | Key Benefit |
|---------|----------|-------------|
| Self-execute | Spells, imps | Sourced + executed works |
| PATH baseline | Bootstrap scripts | macOS CI compatibility |
| env-clear | Non-bootstrap spells | Clean environment |
| Function discipline | All spells | Readability (scrolls not programs) |
| Stub imps | Testing | Reusable mocking |
| Test bootstrap | All tests | Consistent framework |
| Descriptive errors | All code | Self-healing UX |
| Variable defaults | With set -u | Prevent unbound errors |
