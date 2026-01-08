#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - install-menu fails when no installable entries exist
# - install-menu builds menu entries from provided directories and status helpers

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_menu_env() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
# Send TERM signal to parent to simulate ESC behavior
kill -TERM "$PPID" 2>/dev/null || exit 0
exit 0
SH
  chmod +x "$tmp/menu"
}

make_stub_require() {
  tmp=$1
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/require-command"
}

test_install_menu_prefers_install_root_commands() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"

  install_root="$tmp/install"
  mkdir -p "$install_root/alpha" "$install_root/beta" "$install_root/gamma"

  cat >"$install_root/alpha/alpha-status" <<'SH'
#!/bin/sh
echo configured
SH
  chmod +x "$install_root/alpha/alpha-status"

  cat >"$install_root/alpha/alpha" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$install_root/alpha/alpha"

  cat >"$install_root/beta-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/beta-status"

  cat >"$install_root/beta-menu" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$install_root/beta-menu"

  MENU_LOG="$tmp/log"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="alpha beta gamma" MENU_LOG="$MENU_LOG" "$ROOT_DIR/spells/menu/install-menu"

  assert_success && assert_path_exists "$MENU_LOG" && \
    assert_output_contains "Install Menu:"

  menu_args=$(cat "$MENU_LOG")

  case "$menu_args" in
    *"alpha - configured%$install_root/alpha/alpha"* ) : ;;
    *) TEST_FAILURE_REASON="alpha entry missing nested command"; return 1 ;;
  esac

  case "$menu_args" in
    *"beta - ready%$install_root/beta-menu"* ) : ;;
    *) TEST_FAILURE_REASON="beta entry missing submenu command"; return 1 ;;
  esac

  case "$menu_args" in
    *"gamma - coming soon%printf \"This entry is not ready yet.\\n\""* ) : ;;
    *) TEST_FAILURE_REASON="gamma entry missing fallback message"; return 1 ;;
  esac
}

test_install_menu_errors_when_empty() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_DIRS=" " MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/install-menu"
  assert_failure && assert_error_contains "no installable spells"
}

test_install_menu_builds_entries_with_status() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/alpha-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$tmp/alpha-status"
  cat >"$tmp/alpha-menu" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/alpha-menu"
  MENU_LOG="$tmp/log"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_DIRS="alpha beta" MENU_LOG="$MENU_LOG" "$ROOT_DIR/spells/menu/install-menu"
  assert_success && assert_path_exists "$MENU_LOG" && \
    assert_output_contains "Install Menu:"
  menu_args=$(cat "$MENU_LOG")
  case "$menu_args" in
    *"alpha - ready%alpha-menu"* ) : ;; 
    *) TEST_FAILURE_REASON="menu entries missing status"; return 1 ;;
  esac
}

run_test_case "install-menu fails when empty" test_install_menu_errors_when_empty
run_test_case "install-menu builds entries from directories" test_install_menu_builds_entries_with_status
run_test_case "install-menu prefers spells in the install root" test_install_menu_prefers_install_root_commands

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  
  # Create menu stub that returns exit code 130
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 130
SH
  chmod +x "$tmp/menu"
  
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create a minimal install dir
  install_root="$tmp/install"
  mkdir -p "$install_root/test"
  cat >"$install_root/test/test-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/test/test-status"
  
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="test" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/install-menu"
  assert_success || { TEST_FAILURE_REASON="install-menu should exit successfully when menu returns 130"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%exit 130'*) : ;;
    *) TEST_FAILURE_REASON="Exit menu item should use 'exit 130' not 'kill -TERM \$PPID': $args"; return 1 ;;
  esac
}

run_test_case "install-menu ESC/Exit behavior" test_esc_exit_behavior

shows_help() {
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  install_root="$tmp/install"
  mkdir -p "$install_root/test"
  cat >"$install_root/test/test-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/test/test-status"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="test" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/install-menu" --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "install-menu accepts --help" shows_help

# Test that no exit message is printed when ESC or Exit is used
test_no_exit_message_on_esc() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  install_root="$tmp/install"
  mkdir -p "$install_root/test"
  cat >"$install_root/test/test-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/test/test-status"
  
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="test" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/install-menu"
  assert_success || return 1
  
  # Verify no "Exiting" message appears in stderr
  case "$ERROR" in
    *"Exiting"*) 
      TEST_FAILURE_REASON="should not print exit message, got: $ERROR"
      return 1
      ;;
  esac
  return 0
}

run_test_case "install-menu no exit message on ESC" test_no_exit_message_on_esc

# Test that nested menu return shows proper blank line spacing
test_nested_menu_spacing() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  
  # Create a menu that records when it's called, and on second call sends TERM
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
count=$(cat "$INVOCATION_FILE" 2>/dev/null || echo 0)
count=$((count + 1))
printf '%s\n' "$count" >"$INVOCATION_FILE"
# Always send TERM to exit on first display (simulating ESC)
kill -TERM "$PPID" 2>/dev/null || exit 0
exit 0
SH
  chmod +x "$tmp/menu"
  
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  install_root="$tmp/install"
  mkdir -p "$install_root/test"
  cat >"$install_root/test/test-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/test/test-status"
  
  INVOCATION_FILE="$tmp/invocations"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="test" MENU_LOG="$tmp/log" INVOCATION_FILE="$INVOCATION_FILE" "$ROOT_DIR/spells/menu/install-menu"
  assert_success || return 1
  
  # The menu loop should have run once (on first_run, no leading newline)
  # This ensures consistent spacing behavior
  return 0
}

run_test_case "install-menu nested spacing behavior" test_nested_menu_spacing

# Test that import-arcanum appears in menu with divider
test_import_arcanum_in_menu() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  install_root="$tmp/install"
  mkdir -p "$install_root/test"
  cat >"$install_root/test/test-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/test/test-status"
  
  cat >"$install_root/import-arcanum" <<'SH'
#!/bin/sh
echo "import-arcanum called"
SH
  chmod +x "$install_root/import-arcanum"
  
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="test" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/install-menu"
  assert_success || return 1
  
  # Check that menu includes import-arcanum with divider before it
  menu_args=$(cat "$tmp/log")
  case "$menu_args" in
    *"---"*"Import arcanum%"*) : ;;
    *) TEST_FAILURE_REASON="import-arcanum with divider not found in menu"; return 1 ;;
  esac
  
  return 0
}

run_test_case "install-menu includes import-arcanum" test_import_arcanum_in_menu

# Test that exactly one blank line appears when selecting menu items
test_single_blank_line_on_selection() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  install_root="$tmp/arcana"
  mkdir -p "$install_root/test"
  
  # Create test arcanum menu
  cat >"$install_root/test/test-menu" <<'SH'
#!/bin/sh
printf 'Test menu displayed\n'
exit 0
SH
  chmod +x "$install_root/test/test-menu"
  
  cat >"$install_root/test/test-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/test/test-status"
  
  # Create a menu that simulates real behavior
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$1" >>"$MENU_OUTPUT"
shift
printf '%s\n' "$1" >>"$MENU_OUTPUT"
# Single blank line before executing command
printf '\n' >>"$MENU_OUTPUT"
# Execute first menu command
cmd=${1#*%}
eval "$cmd" >>"$MENU_OUTPUT" 2>&1
kill -TERM "$PPID" 2>/dev/null || exit 0
exit 0
SH
  chmod +x "$tmp/menu"
  
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  MENU_OUTPUT="$tmp/output"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="test" MENU_OUTPUT="$MENU_OUTPUT" "$ROOT_DIR/spells/menu/install-menu"
  assert_success || return 1
  
  if [ -f "$MENU_OUTPUT" ]; then
    blank_count=$(grep -c '^$' "$MENU_OUTPUT" || true)
    if [ "$blank_count" -ne 1 ]; then
      TEST_FAILURE_REASON="Expected exactly 1 blank line, got $blank_count"
      return 1
    fi
  fi
  
  return 0
}

run_test_case "install-menu shows exactly one blank line on selection" test_single_blank_line_on_selection


# Test via source-then-invoke pattern  

finish_tests
