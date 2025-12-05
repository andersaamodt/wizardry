#!/bin/sh
set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


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
