#!/bin/sh
# Behavioral cases (derived from --help):
# - mud menu validates dependencies before launching actions

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

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

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/menu/mud" ]
}

run_test_case "mud menu requires menu dependency" mud_requires_menu_dependency
run_test_case "menu/mud is executable" spell_is_executable
spell_has_shebang() {
  head -1 "$ROOT_DIR/spells/menu/mud" | grep -q "^#!"
}

run_test_case "menu/mud has shebang" spell_has_shebang
finish_tests
