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
  [ -x "$ROOT_DIR/spells/install/simplex-chat/uninstall-simplex-chat" ]
}

_run_test_case "install/simplex-chat/uninstall-simplex-chat is executable" spell_is_executable

shows_usage() {
  _run_cmd "$ROOT_DIR/spells/install/simplex-chat/uninstall-simplex-chat" --help
  _assert_success || return 1
  _assert_error_contains "Usage: uninstall-simplex-chat" || return 1
}

_run_test_case "uninstall-simplex-chat shows usage" shows_usage

performs_uninstall_and_optionally_purges_data() {
  tmp=$(_make_tempdir)
  log="$tmp/manage.log"
  cat >"$tmp/manage-system-command" <<'SHI'
#!/bin/sh
printf '%s ' "$@" >>"$LOG"
printf '\n' >>"$LOG"
SHI
  chmod +x "$tmp/manage-system-command"

  mkdir -p "$tmp/home/data" "$tmp/home/config"

  HOME="$tmp/home" LOG="$log" _run_cmd env PATH="$tmp:$PATH" MANAGE_SYSTEM_COMMAND="$tmp/manage-system-command" \
    SIMPLEX_CHAT_PACKAGE_DEFAULT="simplex-cli" SIMPLEX_CHAT_DATA_DIR="$tmp/home/data" SIMPLEX_CHAT_CONFIG_DIR="$tmp/home/config" \
    sh -c "printf 'y\\n' | '$ROOT_DIR/spells/install/simplex-chat/uninstall-simplex-chat'"

  _assert_success || return 1
  _assert_file_contains "$log" "--uninstall simplex-chat simplex-cli" || return 1
  [ ! -d "$tmp/home/data" ] || { TEST_FAILURE_REASON="data directory should be removed"; return 1; }
  [ ! -d "$tmp/home/config" ] || { TEST_FAILURE_REASON="config directory should be removed"; return 1; }
}

_run_test_case "uninstall-simplex-chat removes package and purges data when requested" performs_uninstall_and_optionally_purges_data

runs_rebuild_on_nixos_when_requested() {
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
    SIMPLEX_CHAT_ASSUME_NIXOS=1 SIMPLEX_CHAT_PACKAGE_DEFAULT="simplex-cli" \
    sh -c "printf 'y\\n' | '$ROOT_DIR/spells/install/simplex-chat/uninstall-simplex-chat'"

  _assert_success || return 1
  _assert_file_contains "$log" "--uninstall simplex-chat simplex-cli" || return 1
  _assert_file_contains "$rebuild_log" "switch" || return 1
}

_run_test_case "uninstall-simplex-chat triggers nixos rebuild when requested" runs_rebuild_on_nixos_when_requested

_finish_tests
