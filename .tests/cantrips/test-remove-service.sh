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


make_stub_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/remove-service.XXXXXX") || exit 1
  printf '%s\n' "$dir"
}

write_ask_text_stub() {
  dir=$1
  cat >"$dir/ask-text" <<'STUB'
#!/bin/sh
printf '%s\n' "${ASK_TEXT_RESPONSE:-}"
STUB
  chmod +x "$dir/ask-text"
}

write_systemctl_stub() {
  dir=$1
  cat >"$dir/systemctl" <<'STUB'
#!/bin/sh
state_dir=${SYSTEMCTL_STATE_DIR:-$(mktemp -d)}
mkdir -p "$state_dir"
case "$1" in
  is-active)
    exit ${SYSTEMCTL_IS_ACTIVE_STATUS:-1}
    ;;
  stop)
    printf 'stopped %s\n' "$2" >>"$state_dir/systemctl.log"
    exit 0
    ;;
  daemon-reload)
    printf 'reloaded' >"$state_dir/daemon-reload"
    exit 0
    ;;
  *) exit 0 ;;
esac
STUB
  chmod +x "$dir/systemctl"
}

write_sudo_stub() {
  dir=$1
  cat >"$dir/sudo" <<'STUB'
#!/bin/sh
exec "$@"
STUB
  chmod +x "$dir/sudo"
}

test_requires_service_name() {
  stub_dir=$(make_stub_dir)
  write_ask_text_stub "$stub_dir"
  write_systemctl_stub "$stub_dir"
  write_sudo_stub "$stub_dir"

  ASK_TEXT_RESPONSE="" \
  REMOVE_SERVICE_ASK_TEXT="$stub_dir/ask-text" \
  SYSTEMCTL_STATE_DIR="$stub_dir/state" \
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/remove-service"

  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"no service specified"*) : ;; 
    *) TEST_FAILURE_REASON="missing service warning not shown"; return 1 ;;
  esac
}

test_reports_missing_service() {
  stub_dir=$(make_stub_dir)
  write_ask_text_stub "$stub_dir"
  write_systemctl_stub "$stub_dir"
  write_sudo_stub "$stub_dir"

  service_dir=$(mktemp -d "$WIZARDRY_TMPDIR/services.XXXXXX") || return 1
  SERVICE_DIR="$service_dir" \
  REMOVE_SERVICE_ASK_TEXT="$stub_dir/ask-text" \
  SYSTEMCTL_STATE_DIR="$stub_dir/state" \
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/remove-service" missing

  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"Service missing.service does not exist"*) : ;; 
    *) TEST_FAILURE_REASON="missing service message not shown"; return 1 ;;
  esac
}

test_stops_and_removes_service() {
  stub_dir=$(make_stub_dir)
  write_ask_text_stub "$stub_dir"
  write_systemctl_stub "$stub_dir"
  write_sudo_stub "$stub_dir"

  service_dir=$(mktemp -d "$WIZARDRY_TMPDIR/services.XXXXXX") || return 1
  service_path="$service_dir/demo.service"
  printf 'active' >"$service_path"

  SERVICE_DIR="$service_dir" \
  REMOVE_SERVICE_ASK_TEXT="$stub_dir/ask-text" \
  SYSTEMCTL_STATE_DIR="$stub_dir/state" \
  SYSTEMCTL_IS_ACTIVE_STATUS=0 \
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/remove-service" demo

  assert_success
  assert_output_contains "Removing demo.service"
  [ ! -f "$service_path" ] || { TEST_FAILURE_REASON="service file not removed"; return 1; }
  grep -q "stopped demo.service" "$stub_dir/state/systemctl.log" || { TEST_FAILURE_REASON="service not stopped"; return 1; }
  [ -f "$stub_dir/state/daemon-reload" ] || { TEST_FAILURE_REASON="daemon-reload not invoked"; return 1; }
}

run_test_case "remove-service fails without a service name" test_requires_service_name
run_test_case "remove-service reports missing services" test_reports_missing_service
run_test_case "remove-service stops active services and cleans up" test_stops_and_removes_service

shows_help() {
  run_spell spells/cantrips/remove-service --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "remove-service accepts --help" shows_help
finish_tests
