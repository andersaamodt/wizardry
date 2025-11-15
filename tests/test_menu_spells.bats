#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
  stub_dir="$BATS_TEST_TMPDIR/menu_stubs"
  mkdir -p "$stub_dir"

  menu_log="$stub_dir/menu.log"
  cat <<'MENU' >"$stub_dir/menu"
#!/usr/bin/env bash
set -euo pipefail

result=""
if [ -n "${MENU_STUB_RESULTS_FILE-}" ] && [ -f "$MENU_STUB_RESULTS_FILE" ] && [ -s "$MENU_STUB_RESULTS_FILE" ]; then
  result=$(head -n 1 "$MENU_STUB_RESULTS_FILE")
  tmp="${MENU_STUB_RESULTS_FILE}.tmp"
  tail -n +2 "$MENU_STUB_RESULTS_FILE" >"$tmp" 2>/dev/null || :
  mv "$tmp" "$MENU_STUB_RESULTS_FILE"
elif [ -n "${MENU_STUB_RESULT-}" ]; then
  result="$MENU_STUB_RESULT"
else
  result="command"
fi

printf 'MENU:%s\n' "$@" | tee -a "$MENU_LOG"

escape_status=${MENU_ESCAPE_STATUS:-0}
case "$result" in
  escape)
    exit "$escape_status"
    ;;
  error)
    exit 1
    ;;
  *)
    exit 0
    ;;
esac
MENU
  chmod +x "$stub_dir/menu"

  cat <<'ALPHA' >"$stub_dir/alpha-status"
#!/usr/bin/env bash
echo 'ready'
ALPHA
  chmod +x "$stub_dir/alpha-status"

  touch "$stub_dir/alpha-menu" "$stub_dir/beta-menu"
  chmod +x "$stub_dir/alpha-menu" "$stub_dir/beta-menu"
}

make_require_stub() {
  local fail_command=$1
  local message=$2
  local path="$BATS_TEST_TMPDIR/menu-require-${fail_command}"
  cat <<STUB >"$path"
#!/usr/bin/env sh
if [ "\$1" = "$fail_command" ]; then
  printf '%s\n' "require-command: $message" >&2
  exit 1
fi
exec "$ROOT_DIR/spells/cantrips/require-command" "\$@"
STUB
  chmod +x "$path"
  printf '%s\n' "$path"
}

teardown() {
  PATH=$ORIGINAL_PATH
  default_teardown
}

with_menu_path() {
  PATH="$stub_dir:$ORIGINAL_PATH" "$@"
}

create_menu_cantrip_stubs() {
  local dir="$BATS_TEST_TMPDIR/menu_cantrip_stubs"
  rm -rf "$dir"
  mkdir -p "$dir"

  cat <<'STUB' >"$dir/fathom-cursor"
#!/usr/bin/env sh
want_y=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    -y)
      want_y=1
      ;;
    -x)
      printf '1\n'
      exit 0
      ;;
    -v|--verbose)
      ;;
  esac
  shift
done
if [ "$want_y" -eq 1 ]; then
  printf '%s\n' "${FAKE_CURSOR_Y:-5}"
else
  printf '1\n'
  printf '%s\n' "${FAKE_CURSOR_Y:-5}"
fi
STUB
  chmod +x "$dir/fathom-cursor"

  cat <<'STUB' >"$dir/fathom-terminal"
#!/usr/bin/env sh
case "$1" in
  -w)
    printf '80\n'
    ;;
  -h)
    printf '24\n'
    ;;
  *)
    printf '80\n'
    ;;
esac
STUB
  chmod +x "$dir/fathom-terminal"

  cat <<'STUB' >"$dir/move-cursor"
#!/usr/bin/env sh
if [ -z "${MOVE_CURSOR_LOG:-}" ]; then
  exit 1
fi
x=$1
y=$2
case "$x" in
  ''|*[!0-9]*)
    x=1
    ;;
  0)
    x=1
    ;;
esac
case "$y" in
  ''|*[!0-9]*)
    y=1
    ;;
  0)
    y=1
    ;;
esac
printf '%s %s\n' "$x" "$y" >>"$MOVE_CURSOR_LOG"
exit 0
STUB
  chmod +x "$dir/move-cursor"

  cat <<'STUB' >"$dir/await-keypress"
#!/usr/bin/env sh
if [ -z "${MENU_KEY_FILE:-}" ] || [ ! -f "$MENU_KEY_FILE" ]; then
  exit 0
fi
if ! IFS= read -r key <"$MENU_KEY_FILE"; then
  exit 0
fi
if [ -z "$key" ]; then
  exit 0
fi
tmp="$MENU_KEY_FILE.tmp"
tail -n +2 "$MENU_KEY_FILE" >"$tmp" 2>/dev/null || :
mv "$tmp" "$MENU_KEY_FILE"
printf '%s' "$key"
exit 0
STUB
  chmod +x "$dir/await-keypress"

  cat <<'STUB' >"$dir/cursor-blink"
#!/usr/bin/env sh
exit 0
STUB
  chmod +x "$dir/cursor-blink"

  printf '%s\n' "$dir"
}

assert_move_cursor_log() {
  local log_path=$1
  local expected_row=$2
  local menu_length=$3

  mapfile -t move_calls <"$log_path"
  if [ "${#move_calls[@]}" -lt $((menu_length + 2)) ]; then
    fail "move-cursor produced too few calls: ${#move_calls[@]}"
  fi

  local below_row=$((expected_row + menu_length))
  assert_equal "${move_calls[0]}" "1 ${expected_row}"

  local index=1
  local row_offset=0
  while [ "$row_offset" -lt "$menu_length" ]; do
    local call="${move_calls[$index]}"
    local row=${call#* }
    local want=$((expected_row + row_offset))
    assert_equal "$row" "$want"
    index=$((index + 1))
    row_offset=$((row_offset + 1))
  done

  local initial_calls=$((menu_length + 2))
  assert_equal "${move_calls[$((initial_calls - 1))]}" "1 ${below_row}"

  local total=${#move_calls[@]}
  local remaining=$((total - initial_calls))
  if [ $((remaining % 3)) -ne 0 ]; then
    fail "move-cursor log has incomplete refresh groups: ${move_calls[*]}"
  fi

  local idx=$initial_calls
  while [ "$idx" -lt "$total" ]; do
    local first_row=${move_calls[$idx]#* }
    local second_row=${move_calls[$((idx + 1))]#* }
    local third_row=${move_calls[$((idx + 2))]#* }

    if [ "$first_row" -eq "$second_row" ]; then
      fail "move-cursor repeated row in refresh group: ${move_calls[$idx]} / ${move_calls[$((idx + 1))]}"
    fi

    if [ "$first_row" -lt "$expected_row" ] || [ "$first_row" -gt "$((expected_row + menu_length - 1))" ]; then
      fail "move-cursor targeted unexpected row: ${move_calls[$idx]}"
    fi

    if [ "$second_row" -lt "$expected_row" ] || [ "$second_row" -gt "$((expected_row + menu_length - 1))" ]; then
      fail "move-cursor targeted unexpected row: ${move_calls[$((idx + 1))]}"
    fi

    if [ "$third_row" -ne "$below_row" ]; then
      fail "move-cursor did not park below the menu: ${move_calls[$((idx + 2))]}"
    fi

    idx=$((idx + 3))
  done
}

@test 'install-menu reports available menu entries' {
  export MENU_LOG="$menu_log"
  export MENU_STUB_RESULT=escape
  export INSTALL_MENU_DIRS='alpha beta'
  with_menu_path run_spell 'spells/menu/install-menu'
  assert_success
  assert_output --partial 'MENU:Install Menu:'
  assert_output --partial 'alpha - ready%launch_submenu alpha-menu'
  assert_output --partial 'beta - coming soon'
  unset MENU_STUB_RESULT
}

@test 'menu redraws selections without scrolling' {
  local stub_dir
  stub_dir=$(create_menu_cantrip_stubs)
  local key_file="$stub_dir/keys"
  printf 'down\nenter\n' >"$key_file"
  local move_log="$stub_dir/move.log"
  : >"$move_log"

  local fake_y=7
  FAKE_CURSOR_Y=$fake_y \
  MENU_KEY_FILE="$key_file" \
  MOVE_CURSOR_LOG="$move_log" \
  PATH="$stub_dir:$ORIGINAL_PATH" \
  REQUIRE_COMMAND="$ROOT_DIR/spells/cantrips/require-command" \
  run_spell 'spells/cantrips/menu' \
    'Demo Menu' \
    "First%printf 'chosen:first\\n'" \
    "Second%printf 'chosen:second\\n'"

  assert_success
  assert_output --partial 'chosen:second'

  local menu_length=2
  local terminal_height=24
  local expected_row=$fake_y
  local max_row=$((terminal_height - menu_length))
  if [ "$max_row" -lt 1 ]; then
    max_row=1
  fi
  if [ "$expected_row" -gt "$max_row" ]; then
    expected_row=$max_row
  fi
  if [ "$expected_row" -lt 1 ]; then
    expected_row=1
  fi
  assert_move_cursor_log "$move_log" "$expected_row" "$menu_length"
}

@test 'menu redraws selections without scrolling from alternate cursor start' {
  local stub_dir
  stub_dir=$(create_menu_cantrip_stubs)
  local key_file="$stub_dir/keys"
  printf 'down\nenter\n' >"$key_file"
  local move_log="$stub_dir/move.log"
  : >"$move_log"

  local alternate_fake_y=6
  FAKE_CURSOR_Y=$alternate_fake_y \
  MENU_KEY_FILE="$key_file" \
  MOVE_CURSOR_LOG="$move_log" \
  PATH="$stub_dir:$ORIGINAL_PATH" \
  REQUIRE_COMMAND="$ROOT_DIR/spells/cantrips/require-command" \
  run_spell 'spells/cantrips/menu' \
    'Demo Menu' \
    "First%printf 'chosen:first\\n'" \
    "Second%printf 'chosen:second\\n'"

  assert_success
  assert_output --partial 'chosen:second'

  local menu_length=2
  local terminal_height=24
  local expected_row=$alternate_fake_y
  local max_row=$((terminal_height - menu_length))
  if [ "$max_row" -lt 1 ]; then
    max_row=1
  fi
  if [ "$expected_row" -gt "$max_row" ]; then
    expected_row=$max_row
  fi
  if [ "$expected_row" -lt 1 ]; then
    expected_row=1
  fi
  assert_move_cursor_log "$move_log" "$expected_row" "$menu_length"
}

@test 'menu keeps cursor aligned through rapid navigation' {
  local stub_dir
  stub_dir=$(create_menu_cantrip_stubs)
  local key_file="$stub_dir/keys"
  printf 'down\nup\ndown\ndown\nup\nenter\n' >"$key_file"
  local move_log="$stub_dir/move.log"
  : >"$move_log"

  local fake_y=8
  FAKE_CURSOR_Y=$fake_y \
  MENU_KEY_FILE="$key_file" \
  MOVE_CURSOR_LOG="$move_log" \
  PATH="$stub_dir:$ORIGINAL_PATH" \
  REQUIRE_COMMAND="$ROOT_DIR/spells/cantrips/require-command" \
  run_spell 'spells/cantrips/menu' \
    'Demo Menu' \
    "First%printf 'chosen:first\\n'" \
    "Second%printf 'chosen:second\\n'"

  assert_success
  assert_output --partial 'chosen:second'

  local menu_length=2
  local terminal_height=24
  local expected_row=$fake_y
  local max_row=$((terminal_height - menu_length))
  if [ "$max_row" -lt 1 ]; then
    max_row=1
  fi
  if [ "$expected_row" -gt "$max_row" ]; then
    expected_row=$max_row
  fi
  if [ "$expected_row" -lt 1 ]; then
    expected_row=1
  fi

  assert_move_cursor_log "$move_log" "$expected_row" "$menu_length"
}

@test 'menu leaves the terminal's last row available for command output' {
  local stub_dir
  stub_dir=$(create_menu_cantrip_stubs)
  local key_file="$stub_dir/keys"
  printf 'enter\n' >"$key_file"
  local move_log="$stub_dir/move.log"
  : >"$move_log"

  local fake_y_near_bottom=25
  FAKE_CURSOR_Y=$fake_y_near_bottom \
  MENU_KEY_FILE="$key_file" \
  MOVE_CURSOR_LOG="$move_log" \
  PATH="$stub_dir:$ORIGINAL_PATH" \
  REQUIRE_COMMAND="$ROOT_DIR/spells/cantrips/require-command" \
  run_spell 'spells/cantrips/menu' \
    'Demo Menu' \
    "First%printf 'chosen:first\\n'" \
    "Second%printf 'chosen:second\\n'" \
    "Third%printf 'chosen:third\\n'"

  assert_success
  assert_output --partial 'chosen:first'

  local menu_length=3
  local terminal_height=24
  local expected_row=$fake_y_near_bottom
  local max_row=$((terminal_height - menu_length))
  if [ "$max_row" -lt 1 ]; then
    max_row=1
  fi
  if [ "$expected_row" -gt "$max_row" ]; then
    expected_row=$max_row
  fi
  if [ "$expected_row" -lt 1 ]; then
    expected_row=1
  fi

  assert_move_cursor_log "$move_log" "$expected_row" "$menu_length"

  local final_menu_row=$((expected_row + menu_length - 1))
  [ "$final_menu_row" -lt "$terminal_height" ] || fail "menu reached terminal's last row: $final_menu_row"
}

@test 'install-menu reports missing menu command' {
  stub=$(make_require_stub menu "The install-menu spell requires the 'menu' command to present choices.")
  REQUIRE_COMMAND="$stub" run_spell 'spells/menu/install-menu'
  assert_failure
  assert_error --partial "install-menu spell requires the 'menu' command"
}

@test 'main-menu forwards options to menu command' {
  export MENU_LOG="$menu_log"
  : >"$menu_log"
  export MENU_STUB_RESULT=escape
  with_menu_path run_spell 'spells/menu/main-menu'
  assert_success
  assert_output --partial 'MENU:Main Menu:'
  assert_output --partial 'MUD menu%mud'
  assert_output --partial 'Install Free Software%install-menu'
  assert_output --partial 'Manage System%system-menu'
  assert_output --partial 'Exit%kill -2'
  unset MENU_STUB_RESULT
}

@test 'main-menu keeps running until escape is selected' {
  export MENU_LOG="$menu_log"
  : >"$menu_log"
  results_file="$BATS_TEST_TMPDIR/main_menu_results"
  printf '%s\n' command escape >"$results_file"
  export MENU_STUB_RESULTS_FILE="$results_file"
  with_menu_path run_spell 'spells/menu/main-menu'
  assert_success
  menu_calls=$(grep -c '^MENU:Main Menu:' "$menu_log")
  assert_equal "$menu_calls" 2
  unset MENU_STUB_RESULTS_FILE
}

@test 'mud forwards options to menu command' {
  export MENU_LOG="$menu_log"
  : >"$menu_log"
  export MENU_STUB_RESULT=escape
  with_menu_path run_spell 'spells/menu/mud'
  assert_success
  assert_output --partial 'MENU:MUD Menu:'
  assert_output --partial 'Look around%look'
  assert_output --partial 'Mark this location%mark-location'
  assert_output --partial 'Return to the marked location%jump-to-marker'
  assert_output --partial 'Review your contacts%read-contact'
  assert_output --partial 'Install supporting software%launch_submenu install-menu'
  assert_output --partial 'Exit%kill -2'
  unset MENU_STUB_RESULT
}

@test 'mud exits when escape is selected' {
  export MENU_LOG="$menu_log"
  : >"$menu_log"
  export MENU_STUB_RESULT=escape
  with_menu_path run_spell 'spells/menu/mud'
  assert_success
  menu_calls=$(grep -c '^MENU:MUD Menu:' "$menu_log")
  assert_equal "$menu_calls" 1
  [[ "$output" != *exiting* ]] || fail 'mud should not print an exiting message'
  unset MENU_STUB_RESULT
}

@test 'main-menu shows single blank lines when entering and leaving system menu' {
  export MENU_LOG="$menu_log"
  : >"$menu_log"

  cat <<'MENU' >"$stub_dir/menu"
#!/usr/bin/env bash
set -euo pipefail

title=$1
shift

printf 'MENU:%s\n' "$title"
printf 'MENU:%s\n' "$title" >>"$MENU_LOG"

for entry in "$@"; do
  printf 'MENU:%s\n' "$entry"
  printf 'MENU:%s\n' "$entry" >>"$MENU_LOG"
done

  state_file="${MENU_LOG}.state"
  state=0
  if [ -f "$state_file" ]; then
    state=$(cat "$state_file")
  fi

  case "$title" in
  'Main Menu:')
    case "$state" in
      0)
        printf '1\n' >"$state_file"
        for entry in "$@"; do
          case "$entry" in
            'MUD menu%'* )
              cmd=${entry#*%}
              PATH="$ROOT_DIR/spells/menu:$PATH"
              eval "$cmd"
              ;;
          esac
        done
        exit 0
        ;;
      1)
        printf '2\n' >"$state_file"
        for entry in "$@"; do
          case "$entry" in
            'Manage System%'* )
              cmd=${entry#*%}
              PATH="$ROOT_DIR/spells/menu:$PATH"
              eval "$cmd"
              ;;
          esac
        done
        exit 0
        ;;
      *)
        exit "${MENU_ESCAPE_STATUS:-0}"
        ;;
    esac
    ;;
  'MUD Menu:'|'System Menu:')
    exit "${MENU_ESCAPE_STATUS:-0}"
    ;;
  *)
    exit 0
    ;;
  esac
MENU
  chmod +x "$stub_dir/menu"

  with_menu_path run_spell 'spells/menu/main-menu'
  assert_success

  [[ "$output" == *$'\n\nMENU:MUD Menu:'* ]] || fail 'expected exactly one blank line before MUD Menu prompt'
  [[ "$output" != *$'\n\n\nMENU:MUD Menu:'* ]] || fail 'found multiple blank lines before MUD Menu prompt'
  [[ "$output" == *$'\n\nMENU:System Menu:'* ]] || fail 'expected exactly one blank line before System Menu prompt'
  [[ "$output" != *$'\n\n\nMENU:System Menu:'* ]] || fail 'found multiple blank lines before System Menu prompt'
  [[ "$output" == *$'\n\nMENU:Main Menu:'* ]] || fail 'expected blank line before Main Menu prompt after returning'

  rm -f "${MENU_LOG}.state"
  if [ -f "$stub_dir/menu.default" ]; then
    cp "$stub_dir/menu.default" "$stub_dir/menu"
    chmod +x "$stub_dir/menu"
    rm -f "$stub_dir/menu.default"
  fi
}

@test 'install-menu exits when escape is selected' {
  export MENU_LOG="$menu_log"
  : >"$menu_log"
  export MENU_STUB_RESULT=escape
  export INSTALL_MENU_DIRS='alpha beta'
  with_menu_path run_spell 'spells/menu/install-menu'
  assert_success
  menu_calls=$(grep -c '^MENU:Install Menu:' "$menu_log")
  assert_equal "$menu_calls" 1
  unset MENU_STUB_RESULT
  unset INSTALL_MENU_DIRS
}

@test 'install-menu shows single blank lines when entering submenus' {
  export MENU_LOG="$menu_log"
  : >"$menu_log"

  cat <<'MENU' >"$stub_dir/menu"
#!/usr/bin/env bash
set -euo pipefail

title=$1
shift

printf 'MENU:%s\n' "$title"
printf 'MENU:%s\n' "$title" >>"$MENU_LOG"

case "$title" in
  'Install Menu:')
    for entry in "$@"; do
      case "$entry" in
        'alpha - ready%'* )
          cmd=${entry#*%}
          PATH="$ROOT_DIR/spells/menu:$PATH"
          case "$cmd" in
            'launch_submenu '*)
              submenu=${cmd#launch_submenu }
              printf '\n'
              eval "$submenu"
              ;;
            *)
              eval "$cmd"
              ;;
          esac
          ;;
      esac
    done
    exit "${MENU_ESCAPE_STATUS:-0}"
    ;;
  'Alpha Menu:')
    exit "${MENU_ESCAPE_STATUS:-0}"
    ;;
  *)
    exit 0
    ;;
esac
MENU
  chmod +x "$stub_dir/menu"

  cp "$stub_dir/alpha-menu" "$stub_dir/alpha-menu.default"

  cat <<'ALPHA' >"$stub_dir/alpha-menu"
#!/usr/bin/env bash
printf 'MENU:Alpha Menu:\n'
ALPHA
  chmod +x "$stub_dir/alpha-menu"

  export INSTALL_MENU_DIRS='alpha'
  with_menu_path run_spell 'spells/menu/install-menu'
  assert_success

  [[ "$output" == *$'\n\nMENU:Alpha Menu:'* ]] || fail 'expected exactly one blank line before Alpha Menu prompt'
  [[ "$output" != *$'\n\n\nMENU:Alpha Menu:'* ]] || fail 'found multiple blank lines before Alpha Menu prompt'

  if [ -f "$stub_dir/menu.default" ]; then
    cp "$stub_dir/menu.default" "$stub_dir/menu"
    chmod +x "$stub_dir/menu"
    rm -f "$stub_dir/menu.default"
  fi
  if [ -f "$stub_dir/alpha-menu.default" ]; then
    cp "$stub_dir/alpha-menu.default" "$stub_dir/alpha-menu"
    chmod +x "$stub_dir/alpha-menu"
    rm -f "$stub_dir/alpha-menu.default"
  else
    : >"$stub_dir/alpha-menu"
    chmod +x "$stub_dir/alpha-menu"
  fi
  unset INSTALL_MENU_DIRS
}

@test 'system-menu forwards maintenance options to menu command' {
  export MENU_LOG="$menu_log"
  : >"$menu_log"
  export MENU_STUB_RESULT=escape
  with_menu_path run_spell 'spells/menu/system-menu'
  assert_success
  assert_output --partial 'MENU:System Menu:'
  assert_output --partial 'Update all software%update-all'
  assert_output --partial 'Update wizardry%update-wizardry'
  assert_output --partial 'Test all wizardry spells%(cd '
  assert_output --partial 'Force restart%sudo shutdown -r now'
  assert_output --partial 'Exit%kill -2'
  unset MENU_STUB_RESULT
}

@test 'system-menu exits when escape is selected' {
  export MENU_LOG="$menu_log"
  : >"$menu_log"
  export MENU_STUB_RESULT=escape
  with_menu_path run_spell 'spells/menu/system-menu'
  assert_success
  menu_calls=$(grep -c '^MENU:System Menu:' "$menu_log")
  assert_equal "$menu_calls" 1
  unset MENU_STUB_RESULT
}

