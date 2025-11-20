#!/bin/sh
# Behavioral cases (derived from --help):
# - enable-service prompts then enables unit
# - enable-service fails when name missing

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
printf '%s' "$*" >"$(dirname "$0")/systemctl.args"
EOF_INNER
  chmod +x "$dir/systemctl"
}

enable_service_prompts_and_invokes() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" "delta"
  write_stub_systemctl "$stub_dir"
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/enable-service"
  assert_success || return 1
  assert_output_contains "Enabling delta.service so it starts at boot..." || return 1
  assert_output_contains "systemd enablement request submitted." || return 1
  [ "$(cat "$stub_dir/systemctl.args")" = "enable delta.service" ] || {
    TEST_FAILURE_REASON="systemctl called with unexpected args"; return 1; }
}

enable_service_requires_name() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" ""
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/enable-service"
  assert_failure || return 1
  assert_error_contains "No service name supplied." || return 1
}

run_test_case "enable-service prompts then enables unit" enable_service_prompts_and_invokes
run_test_case "enable-service fails when name missing" enable_service_requires_name

finish_tests
