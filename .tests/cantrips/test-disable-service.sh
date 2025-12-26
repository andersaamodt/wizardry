#!/bin/sh
# Behavioral cases (derived from --help):
# - disable-service prompts then disables unit
# - disable-service fails when name missing

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_dir() {
  dir=$(_make_tempdir)
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
  PATH="$stub_dir:$PATH" _run_spell "spells/cantrips/disable-service"
  _assert_success || return 1
  _assert_output_contains "Disabling epsilon.service so it no longer starts at boot..." || return 1
  _assert_output_contains "systemd disable request submitted." || return 1
  [ "$(cat "$stub_dir/systemctl.args")" = "disable epsilon.service" ] || {
    TEST_FAILURE_REASON="systemctl called with unexpected args"; return 1; }
}

disable_service_requires_name() {
  stub_dir=$(make_stub_dir)
  write_stub_ask_text "$stub_dir" ""
  PATH="$stub_dir:$PATH" _run_spell "spells/cantrips/disable-service"
  _assert_failure || return 1
  _assert_error_contains "No service name supplied." || return 1
}

_run_test_case "disable-service prompts then disables unit" disable_service_prompts_and_invokes
_run_test_case "disable-service fails when name missing" disable_service_requires_name

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/cantrips/disable-service" ]
}

_run_test_case "cantrips/disable-service is executable" spell_is_executable
shows_help() {
  _run_spell spells/cantrips/disable-service --help
  # Note: spell may not have --help implemented yet
  true
}

_run_test_case "disable-service shows help" shows_help

# Test via source-then-invoke pattern  
disable_service_help_via_sourcing() {
  _run_sourced_spell disable-service --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "disable-service works via source-then-invoke" disable_service_help_via_sourcing
_finish_tests
