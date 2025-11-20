#!/bin/sh
# Behavioral cases (derived from --help):
# - stop-service prompts then stops unit
# - stop-service fails when name missing

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

stop_service_prompts_and_invokes() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" "beta"
  write_stub_systemctl "$stub_dir"
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/stop-service"
  assert_success || return 1
  assert_output_contains "Stopping beta.service via systemctl..." || return 1
  [ "$(cat "$WIZARDRY_TMPDIR/systemctl.args")" = "stop beta.service" ] || {
    TEST_FAILURE_REASON="systemctl called with unexpected args"; return 1; }
}

stop_service_requires_name() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" ""
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/stop-service"
  assert_failure || return 1
  assert_error_contains "No service name supplied." || return 1
}

run_test_case "stop-service prompts then stops unit" stop_service_prompts_and_invokes
run_test_case "stop-service fails when name missing" stop_service_requires_name

finish_tests
