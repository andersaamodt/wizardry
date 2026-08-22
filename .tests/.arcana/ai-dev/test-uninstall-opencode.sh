#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/uninstall-opencode" --help
  assert_success || return 1
  assert_output_contains "Usage: uninstall-opencode" || return 1
}

test_removes_binary_and_preserves_state() {
  tmp=$(make_tempdir)
  home="$tmp/home"
  mkdir -p "$home/.local/bin" "$home/.local/share/opencode"
  printf '%s\n' '#!/bin/sh' >"$home/.local/bin/opencode"
  chmod +x "$home/.local/bin/opencode"
  printf '%s\n' keep >"$home/.local/share/opencode/session"

  run_cmd env HOME="$home" "$ROOT_DIR/spells/.arcana/ai-dev/uninstall-opencode"
  assert_success || return 1
  [ ! -e "$home/.local/bin/opencode" ] || {
    TEST_FAILURE_REASON="OpenCode binary remains"
    return 1
  }
  [ -f "$home/.local/share/opencode/session" ] || {
    TEST_FAILURE_REASON="OpenCode state was unexpectedly removed"
    return 1
  }
}

run_test_case "uninstall-opencode shows help" test_help
run_test_case "uninstall-opencode preserves state" test_removes_binary_and_preserves_state
finish_tests
