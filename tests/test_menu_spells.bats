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
printf 'MENU:%s\n' "$@" | tee -a "$MENU_LOG"
kill -2 "$PPID" 2>/dev/null || true
exit 0
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

@test 'install-menu reports available menu entries' {
  export MENU_LOG="$menu_log"
  export INSTALL_MENU_DIRS='alpha beta'
  with_menu_path run_spell 'spells/menu/install-menu'
  assert_success
  assert_output --partial 'MENU:Install Menu:'
  assert_output --partial 'alpha - ready'
  assert_output --partial 'beta - coming soon'
  assert_output --partial 'exiting'
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

  mapfile -t move_calls <"$move_log"
  if [ "${#move_calls[@]}" -lt 1 ]; then
    fail 'move-cursor was not invoked'
  fi
  local menu_length=2
  local terminal_height=24
  local expected_row=$fake_y
  local max_row=$((terminal_height - menu_length + 1))
  if [ "$max_row" -lt 1 ]; then
    max_row=1
  fi
  if [ "$expected_row" -gt "$max_row" ]; then
    expected_row=$max_row
  fi
  if [ "$expected_row" -lt 1 ]; then
    expected_row=1
  fi
  assert_equal "${move_calls[0]}" "1 ${expected_row}"

  local upper_bound=$((expected_row + 1))
  for call in "${move_calls[@]}"; do
    local row=${call#* }
    if [ "$row" -lt "$expected_row" ] || [ "$row" -gt "$upper_bound" ]; then
      fail "move-cursor jumped outside the menu rows: $call"
    fi
  done
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

  mapfile -t move_calls <"$move_log"
  if [ "${#move_calls[@]}" -lt 1 ]; then
    fail 'move-cursor was not invoked'
  fi
  local menu_length=2
  local terminal_height=24
  local expected_row=$alternate_fake_y
  local max_row=$((terminal_height - menu_length + 1))
  if [ "$max_row" -lt 1 ]; then
    max_row=1
  fi
  if [ "$expected_row" -gt "$max_row" ]; then
    expected_row=$max_row
  fi
  if [ "$expected_row" -lt 1 ]; then
    expected_row=1
  fi
  assert_equal "${move_calls[0]}" "1 ${expected_row}"

  local upper_bound=$((expected_row + 1))
  for call in "${move_calls[@]}"; do
    local row=${call#* }
    if [ "$row" -lt "$expected_row" ] || [ "$row" -gt "$upper_bound" ]; then
      fail "move-cursor jumped outside the menu rows: $call"
    fi
  done
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
  with_menu_path run_spell 'spells/menu/main-menu'
  assert_success
  assert_output --partial 'MENU:Main Menu:'
  assert_output --partial 'Install Free Software%install-menu'
  assert_output --partial 'Update all software%update-all'
  assert_output --partial 'Exit%kill -2'
  assert_output --partial 'exiting'
}

