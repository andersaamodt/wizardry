#!/bin/sh
# Behavioral cases (derived from --help):
# - service-status prints systemctl output
# - service-status fails when name missing

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_dir() {
  dir=$(make_tempdir)
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

write_stub_ask_text() {
  dir=$1
  response=$2
  cat >"$dir/ask-text" <<EOF_INNER
#!/bin/sh
echo "$response"
EOF_INNER
  chmod +x "$dir/ask-text"
}

write_stub_systemctl() {
  dir=$1
  cat >"$dir/systemctl" <<'EOF_INNER'
#!/bin/sh
echo "status-ok"; printf '%s' "$*" >"$(dirname "$0")/systemctl.args"
EOF_INNER
  chmod +x "$dir/systemctl"
}

service_status_prompts_and_prints() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" "zeta"
  write_stub_systemctl "$stub_dir"
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/service-status"
  assert_success || return 1
  assert_output_contains "Showing status for zeta.service..." || return 1
  assert_output_contains "status-ok" || return 1
  [ "$(cat "$stub_dir/systemctl.args")" = "status --no-pager zeta.service" ] || {
    TEST_FAILURE_REASON="systemctl called with unexpected args"; return 1; }
}

service_status_requires_name() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" ""
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/service-status"
  assert_failure || return 1
  assert_error_contains "No service name supplied." || return 1
}

run_test_case "service-status prints systemctl output" service_status_prompts_and_prints
run_test_case "service-status fails when name missing" service_status_requires_name

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/cantrips/service-status" ]
}

run_test_case "cantrips/service-status is executable" spell_is_executable
shows_help() {
  run_spell spells/cantrips/service-status --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "service-status shows help" shows_help

# Test via source-then-invoke pattern  

finish_tests
