#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/web/template-menu --help
  assert_success
  assert_output_contains "Usage:"
}

test_template_menu_lists_only_available_templates() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  fake_home=$(temp-dir wizardry-home)
  fake_wizardry_root="$fake_home/.wizardry"
  fake_git_root="$fake_home/git"

  mkdir -p "$fake_wizardry_root"
  mkdir -p "$fake_git_root/wizardry-apps/web/demo/pages"
  mkdir -p "$fake_git_root/unix-settings/hosted-web/pages"
  cat >"$fake_git_root/wizardry-apps/web/demo/pages/index.md" <<'EOF'
# Demo
EOF
  cat >"$fake_git_root/unix-settings/hosted-web/pages/index.md" <<'EOF'
# UNIX Settings
EOF

  stub-menu "$tmp"
  stub-require-command "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"

  run_cmd env \
    HOME="$fake_home" \
    WIZARDRY_DIR="$fake_wizardry_root" \
    WEB_WIZARDRY_ROOT="$fake_home/sites" \
    PATH="$tmp:$PATH" \
    MENU_LOG="$tmp/menu.log" \
    /bin/sh -c "printf 'mysite\n' | '$ROOT_DIR/spells/web/template-menu'"
  assert_success || return 1

  args=$(cat "$tmp/menu.log")
  case "$args" in
    *"Demo Site (Interactive CGI demos)"*"UNIX Settings (Local system authority UI)"*) : ;;
    *)
      TEST_FAILURE_REASON="template-menu missing available templates: $args"
      rm -rf "$tmp" "$fake_home"
      return 1
      ;;
  esac
  case "$args" in
    *"Personal Blog (Content-addressable posts)"*)
      TEST_FAILURE_REASON="template-menu advertised unavailable blog template"
      rm -rf "$tmp" "$fake_home"
      return 1
      ;;
  esac
  case "$args" in
    *"Artificer (Local coding assistant)"*)
      TEST_FAILURE_REASON="template-menu advertised unavailable artificer template"
      rm -rf "$tmp" "$fake_home"
      return 1
      ;;
  esac

  rm -rf "$tmp" "$fake_home"
}

run_test_case "template-menu shows help" test_help
run_test_case "template-menu lists only available templates" test_template_menu_lists_only_available_templates
finish_tests
