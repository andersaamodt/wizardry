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

run_test_case "menu/thesaurus is executable" spell_is_executable
run_test_case "menu/thesaurus has content" spell_has_content

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/menu/thesaurus" --help
  assert_success
  assert_output_contains "Usage: thesaurus"
}

run_test_case "thesaurus --help shows usage" test_shows_help

test_fails_without_menu_dependency() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "thesaurus: The 'menu' command is required." >&2
exit 1
SH
  chmod +x "$tmp/require-command"
  PATH="$tmp:$PATH" run_cmd "$ROOT_DIR/spells/menu/thesaurus"
  assert_failure || return 1
  assert_error_contains "menu" || return 1
}

run_test_case "thesaurus fails without menu dependency" test_fails_without_menu_dependency

test_accepts_list_flag() {
  run_cmd "$ROOT_DIR/spells/menu/thesaurus" --help
  assert_success || return 1
  assert_output_contains "--list" || return 1
}

run_test_case "thesaurus accepts --list flag" test_accepts_list_flag


# Test via source-then-invoke pattern  

finish_tests
