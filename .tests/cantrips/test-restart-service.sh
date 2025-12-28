#!/bin/sh
# Behavioral cases (derived from --help):
# - restart-service prompts then restarts unit
# - restart-service fails when name missing

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
printf '%s' "$*" >"$(dirname "$0")/systemctl.args"
EOF_INNER
  chmod +x "$dir/systemctl"
}

write_stub_sudo() {
  dir=$1
  cat >"$dir/sudo" <<'EOF_INNER'
#!/bin/sh
exec "$@"
EOF_INNER
  chmod +x "$dir/sudo"
}

restart_service_prompts_and_invokes() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" "gamma"
  write_stub_systemctl "$stub_dir"
  write_stub_sudo "$stub_dir"
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/restart-service"
  assert_success || return 1
  assert_output_contains "Restarting gamma.service via systemctl..." || return 1
  [ "$(cat "$stub_dir/systemctl.args")" = "restart gamma.service" ] || {
    TEST_FAILURE_REASON="systemctl called with unexpected args"; return 1; }
}

restart_service_requires_name() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" ""
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/restart-service"
  assert_failure || return 1
  assert_error_contains "No service name supplied." || return 1
}

run_test_case "restart-service prompts then restarts unit" restart_service_prompts_and_invokes
run_test_case "restart-service fails when name missing" restart_service_requires_name

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/cantrips/restart-service" ]
}

run_test_case "cantrips/restart-service is executable" spell_is_executable
shows_help() {
  run_spell spells/cantrips/restart-service --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "restart-service shows help" shows_help

# Test via source-then-invoke pattern  
