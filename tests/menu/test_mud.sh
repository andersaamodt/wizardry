#!/bin/sh
# Behavioral cases (derived from --help):
# - mud menu validates dependencies before launching actions

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

mud_requires_menu_dependency() {
  stub_dir=$(make_tempdir)
  cat <<'STUB' >"$stub_dir/require-command"
#!/bin/sh
printf '%s\n' "require-command stub: $*" >&2
exit 1
STUB
  chmod +x "$stub_dir/require-command"

  run_cmd env REQUIRE_COMMAND="$stub_dir/require-command" PATH="$stub_dir:$PATH" "$ROOT_DIR/spells/menu/mud"
  assert_failure || return 1
  assert_error_contains "The MUD menu needs the 'menu' command" || return 1
}

run_test_case "mud menu requires menu dependency" mud_requires_menu_dependency
finish_tests
