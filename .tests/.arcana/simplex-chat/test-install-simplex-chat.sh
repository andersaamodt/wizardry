#!/bin/sh
set -eu

# Locate test helpers
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/simplex-chat/install-simplex-chat" ]
}

_run_test_case "install/simplex-chat/install-simplex-chat is executable" spell_is_executable

renders_usage_information() {
  _run_cmd "$ROOT_DIR/spells/.arcana/simplex-chat/install-simplex-chat" --help
  _assert_success || return 1
  _assert_error_contains "Usage: install-simplex-chat" || return 1
}

_run_test_case "install-simplex-chat shows usage via --help" renders_usage_information

runs_install_with_defaults_and_prepares_dirs() {
  tmp=$(_make_tempdir)
  log="$tmp/manage.log"
  cat >"$tmp/manage-system-command" <<'SHI'
#!/bin/sh
printf '%s ' "$@" >>"$LOG"
printf '\n' >>"$LOG"
SHI
  chmod +x "$tmp/manage-system-command"

  HOME="$tmp/home" LOG="$log" _run_cmd env PATH="$tmp:$PATH" MANAGE_SYSTEM_COMMAND="$tmp/manage-system-command" \
    SIMPLEX_CHAT_PACKAGE_DEFAULT="simplex-cli" SIMPLEX_CHAT_DATA_DIR="$tmp/home/data" SIMPLEX_CHAT_CONFIG_DIR="$tmp/home/config" \
    sh -c "printf '\n\n' | '$ROOT_DIR/spells/.arcana/simplex-chat/install-simplex-chat'"

  _assert_success || return 1
  _assert_file_contains "$log" "simplex-chat simplex-cli" || return 1
  _assert_path_exists "$tmp/home/data" || return 1
  _assert_path_exists "$tmp/home/config" || return 1
}

_run_test_case "install-simplex-chat installs default package and creates directories" runs_install_with_defaults_and_prepares_dirs

respects_custom_package_and_runs_rebuild_on_nixos() {
  tmp=$(_make_tempdir)
  log="$tmp/manage.log"
  rebuild_log="$tmp/rebuild.log"

  cat >"$tmp/manage-system-command" <<'SHI'
#!/bin/sh
printf '%s ' "$@" >>"$LOG"
printf '\n' >>"$LOG"
SHI
  chmod +x "$tmp/manage-system-command"

  cat >"$tmp/nixos-rebuild" <<'SHI'
#!/bin/sh
printf '%s\n' "$@" >>"$REBUILD_LOG"
SHI
  chmod +x "$tmp/nixos-rebuild"

  cat >"$tmp/sudo" <<'SHI'
#!/bin/sh
exec "$@"
SHI
  chmod +x "$tmp/sudo"

  HOME="$tmp/home" LOG="$log" REBUILD_LOG="$rebuild_log" _run_cmd env PATH="$tmp:$PATH" MANAGE_SYSTEM_COMMAND="$tmp/manage-system-command" \
    SIMPLEX_CHAT_ASSUME_NIXOS=1 SIMPLEX_CHAT_PACKAGE_DEFAULT="simplex-cli" SIMPLEX_CHAT_DATA_DIR="$tmp/home/data" SIMPLEX_CHAT_CONFIG_DIR="$tmp/home/config" \
    sh -c "printf 'custompkg\\n/tmp/data\\n/tmp/config\\ny\\n' | '$ROOT_DIR/spells/.arcana/simplex-chat/install-simplex-chat'"

  _assert_success || return 1
  _assert_file_contains "$log" "simplex-chat custompkg" || return 1
  _assert_file_contains "$rebuild_log" "switch" || return 1
}

_run_test_case "install-simplex-chat respects package choice and triggers nixos rebuild when requested" respects_custom_package_and_runs_rebuild_on_nixos

_finish_tests
