#!/bin/sh
# Test coverage for priority-menu spell:
# - Shows usage with --help
# - Requires file argument
# - Sources colors
# - Shows menu entries for file operations

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

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

make_read_magic_stub() {
  tmp=$1
  cat >"$tmp/read-magic" <<'SH'
#!/bin/sh
echo "read-magic: attribute does not exist."
SH
  chmod +x "$tmp/read-magic"
}

test_help() {
  run_spell "spells/menu/priority-menu" --help
  assert_success || return 1
  assert_output_contains "Usage: priority-menu" || return 1
}

test_requires_file_argument() {
  skip-if-compiled || return $?
  run_spell "spells/menu/priority-menu"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_help_h_flag() {
  run_spell "spells/menu/priority-menu" -h
  assert_success || return 1
  assert_output_contains "Usage: priority-menu" || return 1
}

test_help_usage_flag() {
  run_spell "spells/menu/priority-menu" --usage
  assert_success || return 1
  assert_output_contains "Usage: priority-menu" || return 1
}

test_priority_menu_presents_actions() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  make_read_magic_stub "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create test file
  touch "$tmp/testfile"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/testfile"
  assert_success || return 1
  
  # Verify key actions are present
  grep -q "Prioritize" "$tmp/log" || {
    TEST_FAILURE_REASON="Prioritize action missing"
    return 1
  }
  grep -q "Check%" "$tmp/log" || {
    TEST_FAILURE_REASON="Check action missing"
    return 1
  }
  grep -q "Discard" "$tmp/log" || {
    TEST_FAILURE_REASON="Discard action missing"
    return 1
  }
  grep -q "Edit priority%" "$tmp/log" || {
    TEST_FAILURE_REASON="Edit priority action missing"
    return 1
  }
}

test_priority_menu_shows_filename_in_title() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  make_read_magic_stub "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create test file with recognizable name
  touch "$tmp/myspecialfile"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/myspecialfile"
  assert_success || return 1
  
  # Verify filename is shown in menu title
  grep -q "myspecialfile" "$tmp/log" || {
    TEST_FAILURE_REASON="filename should appear in menu title"
    return 1
  }
}

test_priority_menu_shows_uncheck_when_checked() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  # Create read-magic stub that says item is checked
  cat >"$tmp/read-magic" <<'SH'
#!/bin/sh
if [ "$2" = "checked" ]; then
  echo "1"
else
  echo "read-magic: attribute does not exist."
fi
SH
  chmod +x "$tmp/read-magic"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  touch "$tmp/testfile"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/testfile"
  assert_success || return 1
  
  # When checked, should show "Uncheck" instead of "Check"
  grep -q "Uncheck%" "$tmp/log" || {
    TEST_FAILURE_REASON="Uncheck action should appear when item is checked"
    return 1
  }
}

run_test_case "priority-menu shows usage text" test_help
run_test_case "priority-menu requires file argument" test_requires_file_argument
run_test_case "priority-menu shows usage with -h" test_help_h_flag
run_test_case "priority-menu shows usage with --usage" test_help_usage_flag
run_test_case "priority-menu presents expected actions" test_priority_menu_presents_actions
run_test_case "priority-menu shows filename in title" test_priority_menu_shows_filename_in_title
run_test_case "priority-menu shows uncheck when checked" test_priority_menu_shows_uncheck_when_checked

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  make_read_magic_stub "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create test file
  touch "$tmp/testfile"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/testfile"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%exit 0') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
}

run_test_case "priority-menu ESC/Exit behavior" test_esc_exit_behavior

test_priority_menu_shows_browse_subpriorities() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  # Create read-magic stub that returns priority for subdirectory items
  cat >"$tmp/read-magic" <<'SH'
#!/bin/sh
file=$1
attr=${2-}

# Return 0 for checked attribute on directory (not checked)
if [ "$attr" = "checked" ]; then
  echo "0"
  exit 0
fi

# Check if querying priority of a subdirectory item
case "$file" in
  */testdir/subitem1)
    if [ "$attr" = "priority" ]; then
      echo "3"
    fi
    ;;
  */testdir/subitem2)
    if [ "$attr" = "priority" ]; then
      echo "0"
    fi
    ;;
  *)
    echo "read-magic: attribute does not exist."
    ;;
esac
SH
  chmod +x "$tmp/read-magic"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create test directory with subdirectory that has prioritized items
  mkdir -p "$tmp/testdir"
  touch "$tmp/testdir/subitem1"
  touch "$tmp/testdir/subitem2"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/testdir"
  assert_success || return 1
  
  # Verify "Subpriorities..." appears in menu
  grep -q "Subpriorities...%" "$tmp/log" || {
    TEST_FAILURE_REASON="Subpriorities... should appear for directory with prioritized items: $(cat "$tmp/log")"
    return 1
  }
}

test_priority_menu_hides_browse_for_file() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  make_read_magic_stub "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create test file (not directory)
  touch "$tmp/testfile"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/testfile"
  assert_success || return 1
  
  # Verify "Subpriorities..." does NOT appear for regular file
  grep -q "Subpriorities...%" "$tmp/log" && {
    TEST_FAILURE_REASON="Subpriorities... should not appear for regular file: $(cat "$tmp/log")"
    return 1
  }
  return 0
}

test_priority_menu_hides_browse_for_empty_dir() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  # Create read-magic stub that returns no priority for items
  cat >"$tmp/read-magic" <<'SH'
#!/bin/sh
file=$1
attr=${2-}

# Return 0 for checked attribute on directory (not checked)
if [ "$attr" = "checked" ]; then
  echo "0"
  exit 0
fi

# Always return 0 priority
if [ "$attr" = "priority" ]; then
  echo "0"
else
  echo "read-magic: attribute does not exist."
fi
SH
  chmod +x "$tmp/read-magic"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create test directory with items but no priorities
  mkdir -p "$tmp/testdir"
  touch "$tmp/testdir/item1"
  touch "$tmp/testdir/item2"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/testdir"
  assert_success || return 1
  
  # Verify "Subpriorities..." does NOT appear when no items have priority >= 1
  grep -q "Subpriorities...%" "$tmp/log" && {
    TEST_FAILURE_REASON="Subpriorities... should not appear when no prioritized subitems: $(cat "$tmp/log")"
    return 1
  }
  return 0
}

test_priority_menu_hides_prioritize_for_highest() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  # Create read-magic stub that says this file is the highest priority
  cat >"$tmp/read-magic" <<'SH'
#!/bin/sh
file=$1
attr=${2-}

# Return hash for the file
if [ "$attr" = "hash" ]; then
  echo "abc123"
  exit 0
fi

# Return priorities list with this file's hash as first
if [ "$attr" = "priorities" ]; then
  echo "abc123,def456"
  exit 0
fi

# Return checked=0
if [ "$attr" = "checked" ]; then
  echo "0"
  exit 0
fi

echo "read-magic: attribute does not exist."
SH
  chmod +x "$tmp/read-magic"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create test file
  touch "$tmp/testfile"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/priority-menu" "$tmp/testfile"
  assert_success || return 1
  
  # Verify "Prioritize" does NOT appear for highest priority
  grep -q "Prioritize%" "$tmp/log" && {
    TEST_FAILURE_REASON="Prioritize should not appear for highest priority item: $(cat "$tmp/log")"
    return 1
  }
  
  # Verify "Check" is still present (should be the first item)
  grep -q "Check%" "$tmp/log" || {
    TEST_FAILURE_REASON="Check should still be present: $(cat "$tmp/log")"
    return 1
  }
  return 0
}

run_test_case "priority-menu shows subpriorities for dirs with priorities" test_priority_menu_shows_browse_subpriorities
run_test_case "priority-menu hides subpriorities for regular files" test_priority_menu_hides_browse_for_file
run_test_case "priority-menu hides subpriorities for dirs without priorities" test_priority_menu_hides_browse_for_empty_dir
run_test_case "priority-menu hides prioritize for highest priority" test_priority_menu_hides_prioritize_for_highest


# Test via source-then-invoke pattern  

finish_tests
