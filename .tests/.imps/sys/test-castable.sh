#!/bin/sh
# Tests for the 'castable' imp.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_castable_defaults() {
  workdir=$(_make_tempdir)
  script="$workdir/demo-spell"
  cat >"$script" <<'SCRIPT'
#!/bin/sh
set -eu
PATH="$TEST_WORKDIR:$PATH"
export PATH
. "$WIZARDRY_DIR/spells/.imps/sys/castable"
_castable "$@"
SCRIPT
  chmod +x "$script"

  cat >"$workdir/demo_spell" <<'SCRIPT'
#!/bin/sh
printf 'demo:%s\n' "$*"
SCRIPT
  chmod +x "$workdir/demo_spell"

  _run_cmd env TEST_WORKDIR="$workdir" "$script" "one" "two"
  _assert_success || return 1
  _assert_output_contains "demo:one two" || return 1
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

test_castable_override_func() {
  workdir=$(_make_tempdir)
  script="$workdir/custom-spell"
  cat >"$script" <<'SCRIPT'
#!/bin/sh
set -eu
PATH="$TEST_WORKDIR:$PATH"
export PATH
. "$WIZARDRY_DIR/spells/.imps/sys/castable"
CASTABLE_FUNC=custom_runner _castable "$@"
SCRIPT
  chmod +x "$script"

  cat >"$workdir/custom_runner" <<'SCRIPT'
#!/bin/sh
printf 'custom:%s\n' "$*"
SCRIPT
  chmod +x "$workdir/custom_runner"

  _run_cmd env TEST_WORKDIR="$workdir" "$script" "alpha"
  _assert_success || return 1
  _assert_output_contains "custom:alpha" || return 1
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

_run_test_case "castable uses defaults and forwards args" test_castable_defaults
_run_test_case "castable supports CASTABLE_FUNC override" test_castable_override_func

_finish_tests
