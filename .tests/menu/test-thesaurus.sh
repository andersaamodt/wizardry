#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - thesaurus is executable and has content
# - thesaurus shows usage with --help
# - thesaurus fails when menu dependency is missing
# - thesaurus supports --list flag

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/menu/thesaurus" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/menu/thesaurus" ]
}

_run_test_case "menu/thesaurus is executable" spell_is_executable
_run_test_case "menu/thesaurus has content" spell_has_content

test_shows_help() {
  _run_cmd "$ROOT_DIR/spells/menu/thesaurus" --help
  _assert_success
  _assert_output_contains "Usage: thesaurus"
}

_run_test_case "thesaurus --help shows usage" test_shows_help

test_fails_without_menu_dependency() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "thesaurus: The 'menu' command is required." >&2
exit 1
SH
  chmod +x "$tmp/require-command"
  PATH="$tmp:$PATH" _run_cmd "$ROOT_DIR/spells/menu/thesaurus"
  _assert_failure || return 1
  _assert_error_contains "menu" || return 1
}

_run_test_case "thesaurus fails without menu dependency" test_fails_without_menu_dependency

test_accepts_list_flag() {
  _run_cmd "$ROOT_DIR/spells/menu/thesaurus" --help
  _assert_success || return 1
  _assert_output_contains "--list" || return 1
}

_run_test_case "thesaurus accepts --list flag" test_accepts_list_flag


# Test via source-then-invoke pattern  
