#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_web_wizardry_menu_help() {
  run_spell "spells/.arcana/web-wizardry/web-wizardry-menu" --help
  assert_success && assert_output_contains "Fauxzilla"
}

test_web_wizardry_menu_includes_fauxzilla_client_entry() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"

  PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 \
    run_sourced_spell "spells/.arcana/web-wizardry/web-wizardry-menu"
  assert_success || return 1

  args=$(cat "$tmp/log")
  case "$args" in
    *"configure Fauxzilla browser%configure-fauxzilla-client"*) : ;;
    *)
      TEST_FAILURE_REASON="menu entry missing Fauxzilla client configuration action: $args"
      return 1
      ;;
  esac
}

test_web_wizardry_menu_contains_gazeta_template_toggle() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  stub-exit-label "$tmp"

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/menu.log" MENU_LOOP_LIMIT=1 \
    "$ROOT_DIR/spells/.arcana/web-wizardry/web-wizardry-menu"
  assert_success || return 1

  menu_args=$(cat "$tmp/menu.log" 2>/dev/null || printf '')
  case "$menu_args" in
    *"[ ] Gazeta blog template%"*"/spells/.arcana/web-wizardry/../gazeta/install-gazeta"*)
      ;;
    *)
      TEST_FAILURE_REASON="web-wizardry-menu did not expose Gazeta install toggle: $menu_args"
      return 1
      ;;
  esac
}

run_test_case "web-wizardry-menu shows help" test_web_wizardry_menu_help
run_test_case "web-wizardry-menu includes Fauxzilla client action" test_web_wizardry_menu_includes_fauxzilla_client_entry
run_test_case "web-wizardry-menu contains Gazeta template toggle" \
  test_web_wizardry_menu_contains_gazeta_template_toggle
finish_tests
