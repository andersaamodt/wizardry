#!/bin/sh
# Behavioral cases (derived from --help):
# - disable-service prompts then disables unit
# - disable-service fails when name missing

set -eu

. "$(dirname "$0")/lib/test_common.sh"

make_stub_dir() {
  dir=$(make_tempdir)
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

write_stub_ask_text() {
  dir=$1
  response=$2
  cat >"$dir/ask_text" <<EOF_INNER
#!/bin/sh
echo "$response"
EOF_INNER
  chmod +x "$dir/ask_text"
}

write_stub_systemctl() {
  dir=$1
  cat >"$dir/systemctl" <<'EOF_INNER'
#!/bin/sh
printf '%s' "$*" >"$WIZARDRY_TMPDIR/systemctl.args"
EOF_INNER
  chmod +x "$dir/systemctl"
}

disable_service_prompts_and_invokes() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" "epsilon"
  write_stub_systemctl "$stub_dir"
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/disable-service"
  assert_success || return 1
  assert_output_contains "Disabling epsilon.service so it no longer starts at boot..." || return 1
  assert_output_contains "systemd disable request submitted." || return 1
  [ "$(cat "$WIZARDRY_TMPDIR/systemctl.args")" = "disable epsilon.service" ] || {
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

finish_tests
