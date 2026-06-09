#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_web_wizardry_menu_contains_gazeta_template_toggle() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 \
    "$ROOT_DIR/spells/.arcana/web-wizardry/web-wizardry-menu"
  assert_success || return 1

  menu_args=$(cat "$tmp/log" 2>/dev/null || printf '')
  case "$menu_args" in
    *"[ ] Gazeta blog template%"*"/spells/.arcana/web-wizardry/../gazeta/install-gazeta"*)
      ;;
    *)
      TEST_FAILURE_REASON="web-wizardry-menu did not expose Gazeta install toggle: $menu_args"
      return 1
      ;;
  esac
}

run_test_case "web-wizardry-menu contains Gazeta template toggle" \
  test_web_wizardry_menu_contains_gazeta_template_toggle

finish_tests
