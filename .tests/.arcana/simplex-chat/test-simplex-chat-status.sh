#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="$ROOT_DIR/spells/.arcana/simplex-chat/simplex-chat-status"
basic_path="/usr/bin:/bin:/usr/sbin:/sbin"

spell_is_executable() {
  [ -x "$target" ]
}

run_test_case "install/simplex-chat/simplex-chat-status is executable" spell_is_executable

shows_usage_with_help_flag() {
  run_cmd "$target" --help
  assert_success || return 1
  assert_error_contains "Usage: simplex-chat-status" || return 1
}

run_test_case "simplex-chat-status shows usage with --help" shows_usage_with_help_flag

write_fake_simplex_binary() {
  fake_bin=$1
  cat >"$fake_bin" <<'SHI'
#!/bin/sh
[ "${1-}" = "-h" ] && exit 0
exit 0
SHI
  chmod +x "$fake_bin"
}

reports_not_installed_without_binary() {
  tmp=$(make_tempdir)
  stub-colors "$tmp"
  run_cmd env \
    PATH="$tmp:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$basic_path" \
    HOME="$tmp/home" \
    XDG_BIN_HOME="$tmp/bin" \
    WIZARDRY_SIMPLEX_ROOT="$tmp/state/simplex" \
    "$target"
  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

run_test_case "simplex-chat-status reports not installed when binary missing" reports_not_installed_without_binary

reports_installed_managed_runtime() {
  tmp=$(make_tempdir)
  stub-colors "$tmp"
  mkdir -p "$tmp/state/simplex/current"
  write_fake_simplex_binary "$tmp/state/simplex/current/simplex-chat"
  cat >"$tmp/state/simplex/install.conf" <<'EOFCONF'
version=vtest
binary_path=
EOFCONF

  run_cmd env \
    PATH="$tmp:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$basic_path" \
    HOME="$tmp/home" \
    XDG_BIN_HOME="$tmp/bin" \
    WIZARDRY_SIMPLEX_ROOT="$tmp/state/simplex" \
    "$target"
  assert_success || return 1
  assert_output_contains "installed vtest" || return 1
}

run_test_case "simplex-chat-status reports installed managed runtime" reports_installed_managed_runtime

prints_resolved_path() {
  tmp=$(make_tempdir)
  stub-colors "$tmp"
  mkdir -p "$tmp/state/simplex/current"
  write_fake_simplex_binary "$tmp/state/simplex/current/simplex-chat"

  run_cmd env \
    PATH="$tmp:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$basic_path" \
    HOME="$tmp/home" \
    XDG_BIN_HOME="$tmp/bin" \
    WIZARDRY_SIMPLEX_ROOT="$tmp/state/simplex" \
    "$target" --path
  assert_success || return 1
  assert_output_contains "$tmp/state/simplex/current/simplex-chat" || return 1
}

run_test_case "simplex-chat-status --path prints managed binary" prints_resolved_path

reports_error_for_stale_install_conf() {
  tmp=$(make_tempdir)
  stub-colors "$tmp"
  mkdir -p "$tmp/state/simplex"
  cat >"$tmp/state/simplex/install.conf" <<'EOFCONF'
version=vtest
validation_state=ready
EOFCONF

  run_cmd env \
    PATH="$tmp:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$basic_path" \
    HOME="$tmp/home" \
    XDG_BIN_HOME="$tmp/bin" \
    WIZARDRY_SIMPLEX_ROOT="$tmp/state/simplex" \
    "$target"
  assert_success || return 1
  assert_output_contains "installed, error" || return 1
}

run_test_case "simplex-chat-status reports stale install metadata as error" reports_error_for_stale_install_conf

finish_tests
