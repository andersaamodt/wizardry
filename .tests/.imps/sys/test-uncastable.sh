#!/bin/sh
# Tests for the 'uncastable' imp.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

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

_run_test_case "uncastable errors when executed" test_uncastable_executed_errors
_run_test_case "uncastable allows sourced execution" test_uncastable_sourced_ok

_finish_tests
