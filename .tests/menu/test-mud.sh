#!/bin/sh
# Behavioral cases (derived from --help):
# - mud menu validates dependencies before launching actions
# - mud menu presents expected MUD navigation options

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -TERM "$PPID" 2>/dev/null || exit 0; exit 0
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

mud_requires_menu_dependency() {
  stub_dir=$(make_tempdir)
  cat <<'STUB' >"$stub_dir/require-command"
#!/bin/sh
printf '%s\n' "require-command stub: $*" >&2
exit 1
STUB
  chmod +x "$stub_dir/require-command"

  run_cmd env REQUIRE_COMMAND="$stub_dir/require-command" PATH="$stub_dir:$PATH" "$ROOT_DIR/spells/menu/mud"
  assert_failure || return 1
  assert_error_contains "The MUD menu needs the 'menu' command" || return 1
}

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/menu/mud" ]
}

test_mud_presents_navigation_options() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud"
  assert_success
  
  # Verify navigation options
  grep -q "Look Around%look" "$tmp/log" || {
    TEST_FAILURE_REASON="Look Around action missing"
    return 1
  }
  grep -q "Teleport Home%cd" "$tmp/log" || {
    TEST_FAILURE_REASON="Teleport Home action missing"
    return 1
  }
  grep -q "Teleport to Marker%jump-to-marker" "$tmp/log" || {
    TEST_FAILURE_REASON="Teleport to Marker action missing"
    return 1
  }
  # Portal Chamber location is platform-specific: /Volumes on macOS, /mnt on Linux
  grep -q "Teleport to Portal Chamber%cd " "$tmp/log" || {
    TEST_FAILURE_REASON="Teleport to Portal Chamber action missing"
    return 1
  }
}

test_mud_presents_admin_options() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud"
  assert_success
  
  # Verify admin options (Install MUD was moved to Arcana/install-menu)
  grep -q "Admin MUD Hosting%" "$tmp/log" || {
    TEST_FAILURE_REASON="Admin MUD Hosting action missing"
    return 1
  }
  grep -q "MUD Settings%" "$tmp/log" || {
    TEST_FAILURE_REASON="MUD Settings action missing"
    return 1
  }
}

test_mud_shows_menu_title() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud"
  assert_success
  
  # Verify menu title
  grep -q "MUD Menu:" "$tmp/log" || {
    TEST_FAILURE_REASON="MUD Menu: title missing"
    return 1
  }
}

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
}

run_test_case "mud menu requires menu dependency" mud_requires_menu_dependency
run_test_case "menu/mud is executable" spell_is_executable

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/menu/mud" --help
  assert_success
  assert_output_contains "Usage: mud"
}

run_test_case "mud --help shows usage" test_shows_help
run_test_case "mud presents navigation options" test_mud_presents_navigation_options
run_test_case "mud presents admin options" test_mud_presents_admin_options
run_test_case "mud shows menu title" test_mud_shows_menu_title
run_test_case "mud ESC/Exit behavior" test_esc_exit_behavior

finish_tests
