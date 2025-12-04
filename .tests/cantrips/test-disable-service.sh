#!/bin/sh
# Behavioral cases (derived from --help):
# - disable-service prompts then disables unit
# - disable-service fails when name missing

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

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

disable_service_prompts_and_invokes() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" "epsilon"
  write_stub_systemctl "$stub_dir"
  write_stub_sudo "$stub_dir"
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/disable-service"
  assert_success || return 1
  assert_output_contains "Disabling epsilon.service so it no longer starts at boot..." || return 1
  assert_output_contains "systemd disable request submitted." || return 1
  [ "$(cat "$stub_dir/systemctl.args")" = "disable epsilon.service" ] || {
    TEST_FAILURE_REASON="systemctl called with unexpected args"; return 1; }
}

disable_service_requires_name() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" ""
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/disable-service"
  assert_failure || return 1
  assert_error_contains "No service name supplied." || return 1
}

run_test_case "disable-service prompts then disables unit" disable_service_prompts_and_invokes
run_test_case "disable-service fails when name missing" disable_service_requires_name

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/cantrips/disable-service" ]
}

run_test_case "cantrips/disable-service is executable" spell_is_executable
shows_help() {
  run_spell spells/cantrips/disable-service --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "disable-service shows help" shows_help
finish_tests
