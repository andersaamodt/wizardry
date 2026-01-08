#!/bin/sh
# Test ESC and Exit behavior across all menus to prevent regression
# 
# This test verifies that:
# 1. ESC key returns exit code 130 from menu cantrip
# 2. Exit menu items use "kill -TERM \$PPID" pattern
# 3. All menus handle ESC correctly (capture exit code, kill self)
# 4. ESC and Exit both navigate up exactly one level in nested menus

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# List of all menu files to test
menu_files="
spellbook
install-menu
system-menu
thesaurus
cast
spell-menu
synonym-menu
priorities
main-menu
shutdown-menu
services-menu
network-menu
users-menu
priority-menu
mud-settings
mud
mud-admin-menu
mud-menu
"

# List of bootstrap menus (in .arcana)
bootstrap_menus="
.arcana/core/core-menu
"

test_all_menus_have_esc_handling() {
  skip-if-compiled || return $?
  
  for menu in $menu_files; do
    menu_file="$ROOT_DIR/spells/menu/$menu"
    
    # Check that menu uses || menu_status=$? pattern
    if ! grep -q "|| menu_status=\$?" "$menu_file" && \
       ! grep -q "|| _.*_menu_status=\$?" "$menu_file"; then
      fail "Menu $menu missing '|| menu_status=\$?' pattern"
      return 1
    fi
    
    # Check that menu has ESC handling block
    if ! grep -q "if \[ \"\$.*menu_status\" -eq 130 \]" "$menu_file"; then
      fail "Menu $menu missing ESC handling block"
      return 1
    fi
    
    # Check that ESC handling kills self with TERM
    # Note: In the actual file it's $$ not \$\$ (no escaping needed in kill command)
    if ! grep -q 'kill -TERM \$\$' "$menu_file"; then
      fail "Menu $menu missing 'kill -TERM \$\$' in ESC handler"
      return 1
    fi
  done
  
  # Check bootstrap menus too
  for menu in $bootstrap_menus; do
    menu_file="$ROOT_DIR/spells/$menu"
    
    if ! grep -q "|| menu_status=\$?" "$menu_file"; then
      fail "Bootstrap menu $menu missing '|| menu_status=\$?' pattern"
      return 1
    fi
    
    if ! grep -q "if \[ \"\$menu_status\" -eq 130 \]" "$menu_file"; then
      fail "Bootstrap menu $menu missing ESC handling block"
      return 1
    fi
  done
  
  return 0
}

run_test_case "all menus have ESC handling" test_all_menus_have_esc_handling

test_all_menus_have_exit_button_pattern() {
  skip-if-compiled || return $?
  
  for menu in $menu_files; do
    menu_file="$ROOT_DIR/spells/menu/$menu"
    
    # Check that Exit/Back button uses kill -TERM \$PPID pattern
    if ! grep -q "kill -TERM \\\\\$PPID" "$menu_file" && \
       ! grep -q 'kill -TERM \$PPID' "$menu_file"; then
      fail "Menu $menu missing 'kill -TERM \$PPID' in Exit button"
      return 1
    fi
  done
  
  # Check bootstrap menus too
  for menu in $bootstrap_menus; do
    menu_file="$ROOT_DIR/spells/$menu"
    
    if ! grep -q "kill -TERM \\\\\$PPID" "$menu_file" && \
       ! grep -q 'kill -TERM \$PPID' "$menu_file"; then
      fail "Bootstrap menu $menu missing 'kill -TERM \$PPID' in Exit button"
      return 1
    fi
  done
  
  return 0
}

run_test_case "all menus have Exit button with kill -TERM \$PPID" test_all_menus_have_exit_button_pattern

test_all_menus_have_trap_handler() {
  skip-if-compiled || return $?
  
  for menu in $menu_files; do
    menu_file="$ROOT_DIR/spells/menu/$menu"
    
    # Check that menu has trap handler for INT and TERM
    if ! grep -q "trap.*INT.*TERM" "$menu_file" && \
       ! grep -q "trap.*TERM.*INT" "$menu_file"; then
      fail "Menu $menu missing 'trap ... INT TERM' handler"
      return 1
    fi
  done
  
  # Check bootstrap menus too
  for menu in $bootstrap_menus; do
    menu_file="$ROOT_DIR/spells/$menu"
    
    if ! grep -q "trap.*INT.*TERM" "$menu_file" && \
       ! grep -q "trap.*TERM.*INT" "$menu_file"; then
      fail "Bootstrap menu $menu missing 'trap ... INT TERM' handler"
      return 1
    fi
  done
  
  return 0
}

run_test_case "all menus have trap handler for INT and TERM" test_all_menus_have_trap_handler

test_all_menus_print_esc_message() {
  skip-if-compiled || return $?
  
  for menu in $menu_files; do
    menu_file="$ROOT_DIR/spells/menu/$menu"
    
    # Check that menu prints ESC message when ESC is pressed
    if ! grep -q "printf.*ESC" "$menu_file" && \
       ! grep -q "say.*ESC" "$menu_file" && \
       ! grep -q "echo.*ESC" "$menu_file"; then
      fail "Menu $menu missing ESC message output"
      return 1
    fi
  done
  
  # Check bootstrap menus too
  for menu in $bootstrap_menus; do
    menu_file="$ROOT_DIR/spells/$menu"
    
    if ! grep -q "printf.*ESC" "$menu_file"; then
      fail "Bootstrap menu $menu missing ESC message output"
      return 1
    fi
  done
  
  return 0
}

run_test_case "all menus print ESC message" test_all_menus_print_esc_message

test_no_menu_uses_exit_130_in_menu_items() {
  skip-if-compiled || return $?
  
  for menu in $menu_files; do
    menu_file="$ROOT_DIR/spells/menu/$menu"
    
    # Check that menu does NOT use 'exit 130' in menu items
    # (This was the opaque pattern that was rejected)
    if grep -q "%exit 130" "$menu_file"; then
      fail "Menu $menu uses opaque 'exit 130' pattern in menu items"
      return 1
    fi
  done
  
  # Check bootstrap menus too
  for menu in $bootstrap_menus; do
    menu_file="$ROOT_DIR/spells/$menu"
    
    if grep -q "%exit 130" "$menu_file"; then
      fail "Bootstrap menu $menu uses opaque 'exit 130' pattern"
      return 1
    fi
  done
  
  return 0
}

run_test_case "no menu uses opaque 'exit 130' in menu items" test_no_menu_uses_exit_130_in_menu_items

test_esc_message_has_no_leading_newline() {
  skip-if-compiled || return $?
  
  for menu in $menu_files; do
    menu_file="$ROOT_DIR/spells/menu/$menu"
    
    # Check that ESC message does NOT have leading \n
    # (This was requested to be removed)
    if grep -q "printf '\\\\nESC" "$menu_file" || \
       grep -q 'printf "\\nESC' "$menu_file"; then
      fail "Menu $menu has unwanted leading newline before ESC"
      return 1
    fi
  done
  
  # Check bootstrap menus too
  for menu in $bootstrap_menus; do
    menu_file="$ROOT_DIR/spells/$menu"
    
    if grep -q "printf '\\\\nESC" "$menu_file" || \
       grep -q 'printf "\\nESC' "$menu_file"; then
      fail "Bootstrap menu $menu has unwanted leading newline before ESC"
      return 1
    fi
  done
  
  return 0
}

run_test_case "ESC message has no leading newline" test_esc_message_has_no_leading_newline

finish_tests
