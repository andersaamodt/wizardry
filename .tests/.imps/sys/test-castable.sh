#!/bin/sh
# Tests for the 'castable' imp.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_castable_defaults() {
  workdir=$(make_tempdir)
  script="$workdir/demo-spell"
  cat >"$script" <<'SCRIPT'
#!/bin/sh
set -eu
PATH="$TEST_WORKDIR:$PATH"
export PATH
. "$WIZARDRY_DIR/spells/.imps/sys/castable"

demo_spell() {
  printf 'demo:%s\n' "$*"
}

castable "$@"
SCRIPT
  chmod +x "$script"

  run_cmd env TEST_WORKDIR="$workdir" "$script" "one" "two"
  assert_success || return 1
  assert_output_contains "demo:one two" || return 1
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

test_castable_override_func() {
  workdir=$(make_tempdir)
  script="$workdir/custom-spell"
  cat >"$script" <<'SCRIPT'
#!/bin/sh
set -eu
PATH="$TEST_WORKDIR:$PATH"
export PATH
. "$WIZARDRY_DIR/spells/.imps/sys/castable"

custom_runner() {
  printf 'custom:%s\n' "$*"
}

CASTABLE_FUNC=custom_runner castable "$@"
SCRIPT
  chmod +x "$script"

  run_cmd env TEST_WORKDIR="$workdir" "$script" "alpha"
  assert_success || return 1
  assert_output_contains "custom:alpha" || return 1
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

run_test_case "castable uses defaults and forwards args" test_castable_defaults
run_test_case "castable supports CASTABLE_FUNC override" test_castable_override_func

finish_tests
