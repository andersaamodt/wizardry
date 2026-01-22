#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - network-menu is executable and has content
# - network-menu shows usage with --help
# - network-menu fails when menu dependency is missing

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/menu/network-menu" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/menu/network-menu" ]
}

run_test_case "menu/network-menu is executable" spell_is_executable
run_test_case "menu/network-menu has content" spell_has_content

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/menu/network-menu" --help
  assert_success
  assert_output_contains "Usage: network-menu"
}

run_test_case "network-menu --help shows usage" test_shows_help

test_fails_without_menu_dependency() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "network-menu: The 'menu' command is required." >&2
exit 1
SH
  chmod +x "$tmp/require-command"
  PATH="$tmp:$PATH" run_cmd "$ROOT_DIR/spells/menu/network-menu"
  assert_failure || return 1
  assert_error_contains "menu" || return 1
}

run_test_case "network-menu fails without menu dependency" test_fails_without_menu_dependency


# Test via source-then-invoke pattern  

finish_tests
