#!/bin/sh
# Behavioral checks for castable/uncastable helpers.
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_castable_defaults_and_args() {
  workdir=$(_make_tempdir)
  script="$workdir/demo-spell"
  cat >"$script" <<'SCRIPT'
#!/bin/sh
set -eu
. "$WIZARDRY_DIR/spells/.imps/sys/castable"
demo_spell() { printf 'demo:%s\n' "$*"; }
_castable "$@"
SCRIPT
  chmod +x "$script"

  _run_cmd "$script" "one" "two"
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
. "$WIZARDRY_DIR/spells/.imps/sys/castable"
custom_runner() { printf 'custom:%s\n' "$*"; }
CASTABLE_FUNC=custom_runner _castable "$@"
SCRIPT
  chmod +x "$script"

  _run_cmd "$script" "alpha"
  _assert_success || return 1
  _assert_output_contains "custom:alpha" || return 1
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

test_uncastable_executed_errors() {
  workdir=$(_make_tempdir)
  script="$workdir/guarded"
  cat >"$script" <<'SCRIPT'
#!/bin/sh
set -eu
. "$WIZARDRY_DIR/spells/.imps/sys/uncastable"
_uncastable
printf '%s\n' "after"
SCRIPT
  chmod +x "$script"

  _run_cmd "$script"
  _assert_failure || return 1
  _assert_error_contains "guarded: must be sourced, not executed" || return 1
  _assert_error_contains "Usage: . guarded" || return 1
}

test_uncastable_sourced_ok() {
  workdir=$(_make_tempdir)
  script="$workdir/guarded-src"
  cat >"$script" <<'SCRIPT'
#!/bin/sh
set -eu
. "$WIZARDRY_DIR/spells/.imps/sys/uncastable"
_uncastable
printf '%s\n' "sourced-ok"
SCRIPT
  chmod +x "$script"

  _run_cmd sh -c ". \"$script\""
  _assert_success || return 1
  _assert_output_contains "sourced-ok" || return 1
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

_run_test_case "castable uses defaults and forwards args" test_castable_defaults_and_args
_run_test_case "castable supports CASTABLE_FUNC override" test_castable_override_func
_run_test_case "uncastable errors when executed" test_uncastable_executed_errors
_run_test_case "uncastable allows sourced execution" test_uncastable_sourced_ok
