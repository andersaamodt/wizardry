#!/bin/sh
set -eu

# Locate test helpers
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/node/node-status" ]
}

run_test_case "install/node/node-status is executable" spell_is_executable

renders_usage_information() {
  run_cmd "$ROOT_DIR/spells/install/node/node-status" --help

  assert_success || return 1
  assert_error_contains "Usage: node-status" || return 1
  assert_error_contains "Reports whether Node.js is installed" || return 1
}

run_test_case "node-status prints usage with --help" renders_usage_information

reports_not_installed_without_node_binary() {
  tmp=$(make_tempdir)
  run_cmd env PATH="$tmp:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps:$ROOT_DIR/spells/.imps/menu" \
    "$ROOT_DIR/spells/install/node/node-status"

  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

run_test_case "node-status reports not installed when node is absent" reports_not_installed_without_node_binary

reports_installed_when_node_exists() {
  tmp=$(make_tempdir)
  cat >"$tmp/node" <<'SHI'
#!/bin/sh
if [ "$1" = "--version" ]; then
  echo "v22.0.0"
  exit 0
fi
exit 0
SHI
  chmod +x "$tmp/node"

  run_cmd env PATH="$tmp:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps:$ROOT_DIR/spells/.imps/menu" \
    "$ROOT_DIR/spells/install/node/node-status"

  assert_success || return 1
  assert_output_contains "installed, npm missing" || return 1
}

run_test_case "node-status flags missing npm" reports_installed_when_node_exists

reports_running_service_state() {
  tmp=$(make_tempdir)
  cat >"$tmp/node" <<'SHI'
#!/bin/sh
if [ "$1" = "--version" ]; then
  echo "v20.1.0"
  exit 0
fi
exit 0
SHI
  chmod +x "$tmp/node"

  cat >"$tmp/npm" <<'SHI'
#!/bin/sh
if [ "$1" = "--version" ]; then
  echo "10.0.0"
  exit 0
fi
exit 0
SHI
  chmod +x "$tmp/npm"

  cat >"$tmp/is-service-installed" <<'SHI'
#!/bin/sh
exit 0
SHI
  chmod +x "$tmp/is-service-installed"

  cat >"$tmp/is-service-running" <<'SHI'
#!/bin/sh
exit 0
SHI
  chmod +x "$tmp/is-service-running"

  run_cmd env PATH="$tmp:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps:$ROOT_DIR/spells/.imps/menu" \
    "$ROOT_DIR/spells/install/node/node-status"

  assert_success || return 1
  assert_output_contains "service running" || return 1
}

run_test_case "node-status reports running service when detectors succeed" reports_running_service_state

finish_tests
