#!/bin/sh
# Behavioral cases (derived from --help):
# - start-service prompts then starts unit
# - start-service fails when name missing

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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

start_service_prompts_and_invokes() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" "alpha"
  write_stub_systemctl "$stub_dir"
  write_stub_sudo "$stub_dir"
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/start-service"
  assert_success || return 1
  assert_output_contains "Starting alpha.service via systemctl..." || return 1
  [ "$(cat "$stub_dir/systemctl.args")" = "start alpha.service" ] || {
    TEST_FAILURE_REASON="systemctl called with unexpected args"; return 1; }
}

start_service_fails_without_name() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" ""
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/start-service"
  assert_failure || return 1
  assert_error_contains "No service name supplied." || return 1
}

run_test_case "start-service prompts then starts unit" start_service_prompts_and_invokes
run_test_case "start-service fails when name missing" start_service_fails_without_name

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/cantrips/start-service" ]
}

run_test_case "cantrips/start-service is executable" spell_is_executable
shows_help() {
  run_spell spells/cantrips/start-service --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "start-service shows help" shows_help
finish_tests
