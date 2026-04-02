#!/bin/sh
# Behavioral cases (derived from --help):
# - mud menu validates dependencies before launching actions
# - mud menu presents expected MUD navigation options

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"




mud_requires_menu_dependency() {
  skip-if-compiled || return $?
  stub_dir=$(make_tempdir)
  cat <<'STUB' >"$stub_dir/require-command"
#!/bin/sh
printf '%s\n' "require-command stub: $*" >&2
exit 1
STUB
  chmod +x "$stub_dir/require-command"

  REQUIRE_COMMAND="$stub_dir/require-command" PATH="$stub_dir:$PATH" run_sourced_spell "spells/menu/mud"
  assert_failure || return 1
  assert_error_contains "The MUD menu needs the 'menu' command" || return 1
}

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/menu/mud" ]
}

test_mud_presents_navigation_options() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  PATH="$tmp:$PATH" MENU_LOG="$tmp/log" run_sourced_spell "spells/menu/mud"
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
  grep -q "Say Something%say-interactive" "$tmp/log" || {
    TEST_FAILURE_REASON="Say Something should use say-interactive"
    return 1
  }
  grep -q "Open Portal%open-portal-interactive" "$tmp/log" || {
    TEST_FAILURE_REASON="Open Portal should use open-portal-interactive"
    return 1
  }
  # Portal Chamber location is platform-specific: /Volumes on macOS, /mnt on Linux
  grep -q "Teleport to Portal Chamber%cd " "$tmp/log" || {
    TEST_FAILURE_REASON="Teleport to Portal Chamber action missing"
    return 1
  }
}

test_mud_presents_admin_options() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  PATH="$tmp:$PATH" MENU_LOG="$tmp/log" run_sourced_spell "spells/menu/mud"
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
  grep -q "Player status%player-status" "$tmp/log" || {
    TEST_FAILURE_REASON="Player status action missing"
    return 1
  }
}

test_mud_shows_menu_title() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  PATH="$tmp:$PATH" MENU_LOG="$tmp/log" run_sourced_spell "spells/menu/mud"
  assert_success
  
  # Verify menu title
  grep -q "MUD Menu:" "$tmp/log" || {
    TEST_FAILURE_REASON="MUD Menu: title missing"
    return 1
  }
}

test_mud_shows_create_player_first_when_no_keys() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  home_tmp="$tmp/home"
  mkdir -p "$home_tmp"
  stub-menu "$tmp"
  stub-require-command "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"

  HOME="$home_tmp" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" run_sourced_spell "spells/menu/mud"
  assert_success

  args=$(cat "$tmp/log")
  case "$args" in
    *"MUD Menu:"*"Create Player%new-player"*"Look Around%look"*) : ;;
    *) TEST_FAILURE_REASON="Create Player should appear before main actions when no keys exist: $args"; return 1 ;;
  esac
}

test_mud_shows_change_player_near_end_when_logged_in() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  home_tmp="$tmp/home"
  mkdir -p "$home_tmp/.ssh"
  touch "$home_tmp/.ssh/hero.pub"
  stub-menu "$tmp"
  stub-require-command "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"

  HOME="$home_tmp" MUD_PLAYER=hero PATH="$tmp:$PATH" MENU_LOG="$tmp/log" run_sourced_spell "spells/menu/mud"
  assert_success

  args=$(cat "$tmp/log")
  case "$args" in
    *"Admin MUD Hosting%mud-admin-menu"*"Change player%choose-player"*'MUD Settings%. mud-settings'*'Exit%kill -TERM $PPID'*) : ;;
    *) TEST_FAILURE_REASON="Change player should be third-to-last when logged in: $args"; return 1 ;;
  esac
}

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  PATH="$tmp:$PATH" MENU_LOG="$tmp/log" run_sourced_spell "spells/menu/mud"
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
  run_sourced_spell "spells/menu/mud" --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "mud"
}

run_test_case "mud --help shows usage" test_shows_help
run_test_case "mud presents navigation options" test_mud_presents_navigation_options
run_test_case "mud presents admin options" test_mud_presents_admin_options
run_test_case "mud shows menu title" test_mud_shows_menu_title
run_test_case "mud shows Create Player first when no keys exist" test_mud_shows_create_player_first_when_no_keys
run_test_case "mud shows Change player near end when logged in" test_mud_shows_change_player_near_end_when_logged_in
run_test_case "mud ESC/Exit behavior" test_esc_exit_behavior


# Test via source-then-invoke pattern  

finish_tests
