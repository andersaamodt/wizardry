#!/bin/sh
# Tests for the 'autocast' imp.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_autocast_when_executed() {
  workdir=$(make_tempdir)
  script="$workdir/demo-autocast"
  cat >"$script" <<'SCRIPT'
#!/bin/sh
set -eu

demo_autocast() {
  printf 'executed:%s\n' "${1:-no-args}"
}

. "$WIZARDRY_DIR/spells/.imps/sys/autocast"
SCRIPT
  chmod +x "$script"

  run_cmd env WIZARDRY_DIR="$ROOT_DIR" "$script" "test-arg"
  assert_success || return 1
  assert_output_contains "executed:test-arg" || return 1
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

test_autocast_when_sourced() {
  workdir=$(make_tempdir)
  script="$workdir/demo-source"
  cat >"$script" <<'SCRIPT'
#!/bin/sh
set -eu

demo_source() {
  printf 'sourced:ok\n'
}

. "$WIZARDRY_DIR/spells/.imps/sys/autocast"
SCRIPT
  chmod +x "$script"

  run_cmd env WIZARDRY_DIR="$ROOT_DIR" sh "$script"
  assert_success || return 1
  assert_output_contains "sourced:ok" || return 1
}

test_autocast_auto_detects_name() {
  workdir=$(make_tempdir)
  # Script name must match function name pattern for auto-detection
  script="$workdir/auto_detect"
  cat >"$script" <<'SCRIPT'
#!/bin/sh
set -eu

auto_detect() {
  printf 'detected:success\n'
}

. "$WIZARDRY_DIR/spells/.imps/sys/autocast"
SCRIPT
  chmod +x "$script"

  run_cmd env WIZARDRY_DIR="$ROOT_DIR" "$script"
  assert_success || return 1
  assert_output_contains "detected:success" || return 1
}

run_test_case "autocast executes function when script is executed" test_autocast_when_executed
run_test_case "autocast calls function when sourced" test_autocast_when_sourced
run_test_case "autocast auto-detects spell name from script path" test_autocast_auto_detects_name

finish_tests
