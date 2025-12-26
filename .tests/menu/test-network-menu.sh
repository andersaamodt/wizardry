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

_run_test_case "menu/network-menu is executable" spell_is_executable
_run_test_case "menu/network-menu has content" spell_has_content

test_shows_help() {
  _run_cmd "$ROOT_DIR/spells/menu/network-menu" --help
  _assert_success
  _assert_output_contains "Usage: network-menu"
}

_run_test_case "network-menu --help shows usage" test_shows_help

test_fails_without_menu_dependency() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "network-menu: The 'menu' command is required." >&2
exit 1
SH
  chmod +x "$tmp/require-command"
  PATH="$tmp:$PATH" _run_cmd "$ROOT_DIR/spells/menu/network-menu"
  _assert_failure || return 1
  _assert_error_contains "menu" || return 1
}

_run_test_case "network-menu fails without menu dependency" test_fails_without_menu_dependency


# Test via source-then-invoke pattern  
network_menu_help_via_sourcing() {
  _run_sourced_spell network-menu --help
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

_run_test_case "network-menu works via source-then-invoke" network_menu_help_via_sourcing
_finish_tests
