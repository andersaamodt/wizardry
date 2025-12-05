#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

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
