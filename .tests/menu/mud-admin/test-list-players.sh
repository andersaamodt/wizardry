#!/bin/sh
# Test coverage for list-players spell.

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/menu/mud-admin/list-players" --help
  assert_success || return 1
  assert_output_contains "Usage: list-players" || return 1
}

test_help_h_flag() {
  run_spell "spells/menu/mud-admin/list-players" -h
  assert_success || return 1
  assert_output_contains "Usage: list-players" || return 1
}

test_has_strict_mode() {
  grep -q "set -eu" "$ROOT_DIR/spells/menu/mud-admin/list-players" || {
    TEST_FAILURE_REASON="spell does not use strict mode"
    return 1
  }
}

test_rejects_imported_shell_syntax_in_group_member_names() {
  tmpdir=$(make_tempdir)
  stubdir="$tmpdir/bin"
  good_home="$tmpdir/good-home"
  payload_file="$tmpdir/list-players-injected"
  mkdir -p "$stubdir" "$good_home"

  cat > "$stubdir/getent" <<EOF
#!/bin/sh
if [ "\$1" = "group" ]; then
  printf '%s\n' 'mud:x:100:good,\$(touch "$payload_file")'
  exit 0
fi
if [ "\$1" = "passwd" ] && [ "\$2" = "good" ]; then
  printf '%s\n' 'good:x:1000:1000:Good:$good_home:/bin/sh'
  exit 0
fi
exit 1
EOF
  chmod +x "$stubdir/getent"

  PATH="$stubdir:$PATH" run_spell "spells/menu/mud-admin/list-players"

  assert_success || return 1
  assert_output_contains "good" || return 1
  if [ -e "$payload_file" ]; then
    TEST_FAILURE_REASON="list-players evaluated shell syntax from imported group member name"
    return 1
  fi
}

run_test_case "list-players shows usage text" test_help
run_test_case "list-players shows usage with -h" test_help_h_flag
run_test_case "list-players uses strict mode" test_has_strict_mode
run_test_case "list-players rejects shell syntax in imported members" test_rejects_imported_shell_syntax_in_group_member_names

finish_tests
