#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_ai_dev_menu_help() {
  run_spell "spells/.arcana/ai-dev/ai-dev-menu" --help
  assert_success || return 1
  assert_output_contains "AI development management menu" || return 1
}

test_ai_dev_menu_requires_menu_helper() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-colors "$tmp"
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "The ai-dev-menu needs the 'menu' command to present options." >&2
exit 1
SH
  chmod +x "$tmp/require-command"
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/ai-dev/ai-dev-menu"
  assert_failure || return 1
  assert_error_contains "menu" || return 1
}

test_ai_dev_menu_shows_toggles() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-colors "$tmp"
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
command -v "$1" >/dev/null 2>&1
SH
  chmod +x "$tmp/require-command"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/.arcana/ai-dev/ai-dev-menu"
  assert_success || return 1
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"AI Development:"*"[ ] ollama"*"[ ] AnythingLLM"*"Enable all"*'Exit%kill -TERM $PPID'* ) : ;;
    *) TEST_FAILURE_REASON="menu not invoked with expected options: $args"; return 1 ;;
  esac
}

run_test_case "ai-dev-menu shows help" test_ai_dev_menu_help
run_test_case "ai-dev-menu requires menu helper" test_ai_dev_menu_requires_menu_helper
run_test_case "ai-dev-menu shows toggles" test_ai_dev_menu_shows_toggles

finish_tests
