#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_HOME=$HOME
  ORIGINAL_PATH=$PATH
}

teardown() {
  HOME=$ORIGINAL_HOME
  PATH=$ORIGINAL_PATH
  default_teardown
}

make_stty_stub() {
  local dir="$BATS_TEST_TMPDIR/stty"
  mkdir -p "$dir"
  cat <<'STTY' >"$dir/stty"
#!/usr/bin/env bash
exit 0
STTY
  chmod +x "$dir/stty"
  printf '%s\n' "$dir"
}

@test 'ask prints prompt and captures response' {
  input="$BATS_TEST_TMPDIR/ask_input"
  printf 'response\n' >"$input"
  run_spell 'spells/cantrips/ask' 'Your name?' <"$input"
  assert_success
  assert_line --index 0 'Your name?'
  assert_line --index 1 'response'
}

@test 'ask_yn processes affirmative, default, and negative replies' {
  stty_dir=$(make_stty_stub)
  PATH="$stty_dir:$ORIGINAL_PATH"

  printf 'y' >"$BATS_TEST_TMPDIR/ask_yes"
  run_spell 'spells/cantrips/ask_yn' 'Proceed?' 'y' <"$BATS_TEST_TMPDIR/ask_yes"
  assert_success
  [[ "$stderr" == *'Proceed? (Y/n)?'* ]]
  [[ "$stderr" == *'Y'* ]]

  printf '\r' >"$BATS_TEST_TMPDIR/ask_default"
  run_spell 'spells/cantrips/ask_yn' 'Continue?' 'n' <"$BATS_TEST_TMPDIR/ask_default"
  assert_failure
  [[ "$stderr" == *'Continue? (y/N)?'* ]]
  [[ "$stderr" == *'N'* ]]

  printf 'n' >"$BATS_TEST_TMPDIR/ask_no"
  run_spell 'spells/cantrips/ask_yn' 'Retry?' 'y' <"$BATS_TEST_TMPDIR/ask_no"
  assert_failure
  [[ "$stderr" == *'Retry? (Y/n)?'* ]]
  [[ "$stderr" == *'N'* ]]
}

@test 'assertions helper succeeds and fails appropriately' {
  helper_success="$BATS_TEST_TMPDIR/assert_success.sh"
  cat <<'SUCCESS' >"$helper_success"
#!/usr/bin/env bash
set -euo pipefail
source "$ROOT_DIR/spells/cantrips/assertions"
assert_equal 1 1
assert_output "printf 42" "42"
assert_success true
assert_failure false
SUCCESS
  chmod +x "$helper_success"
  run_spell "$helper_success"
  assert_success

  helper_failure="$BATS_TEST_TMPDIR/assert_failure.sh"
  cat <<'FAIL' >"$helper_failure"
#!/usr/bin/env bash
set -euo pipefail
source "$ROOT_DIR/spells/cantrips/assertions"
assert_equal 1 2
FAIL
  chmod +x "$helper_failure"
  run_spell "$helper_failure"
  assert_failure
  assert_output --partial 'Assertion failed'
}

run_keypress() {
  local content=$1
  local expected=$2
  local file
  file=$(mktemp "$BATS_TEST_TMPDIR/key.XXXXXX")
  printf '%b' "$content" >"$file"
  run_spell 'spells/cantrips/await-keypress' <"$file"
  assert_success
  assert_output "$expected"
}

@test 'await-keypress maps input to friendly names' {
run_keypress $'a' 'a'
  run_keypress $'\n' 'enter'
  run_keypress $'\t' 'tab'
  run_keypress $'\b' 'backspace'
  run_keypress $'\177' 'backspace'
  run_keypress $'\e' 'escape'
  run_keypress $'\e[A' 'up'
  run_keypress $'\e[B' 'down'
  run_keypress $'\e[C' 'right'
  run_keypress $'\e[D' 'left'
  run_keypress $'\e[3~' 'delete'
  run_keypress $'\e[Z' 'escaped key: [Z'
}

@test 'cd cantrip memorises spell optionally' {
  cd_home="$BATS_TEST_TMPDIR/cd"
  mkdir -p "$cd_home"
  export HOME="$cd_home"
  : >"$HOME/.bashrc"

  look_stub="$BATS_TEST_TMPDIR/look"
  mkdir -p "$look_stub"
  cat <<'LOOK' >"$look_stub/look"
#!/usr/bin/env bash
echo "LOOK:$@"
LOOK
  chmod +x "$look_stub/look"

  printf 'yes\n' >"$BATS_TEST_TMPDIR/cd_yes"
  PATH="$look_stub:$ORIGINAL_PATH" run_spell 'spells/cantrips/cd' "$ROOT_DIR" <"$BATS_TEST_TMPDIR/cd_yes"
  assert_success
  assert_output --partial 'Spell memorized'
  assert_output --partial 'LOOK:'
  run cat "$HOME/.bashrc"
  assert_success
  assert_output --partial 'alias cd='

  printf '' >"$HOME/.bashrc"
  printf 'no\n' >"$BATS_TEST_TMPDIR/cd_no"
  PATH="$look_stub:$ORIGINAL_PATH" run_spell 'spells/cantrips/cd' "$ROOT_DIR" <"$BATS_TEST_TMPDIR/cd_no"
  assert_success
  assert_output --partial 'The mud will only run'
}

@test 'colors cantrip emits nothing' {
  run_spell 'spells/cantrips/colors'
  assert_success
  assert_output ''
}

@test 'cursor-blink toggles visibility' {
  run_spell 'spells/cantrips/cursor-blink' on
  assert_success
  assert_output $'\033[?25h'

  run_spell 'spells/cantrips/cursor-blink' off
  assert_success
  assert_output $'\033[?25l'

  run_spell 'spells/cantrips/cursor-blink'
  assert_failure
  assert_output --partial 'Usage: cast_cursor_blink on|off'
}

fathom_cursor() {
  local input=$1
  shift
  local file
  file=$(mktemp "$BATS_TEST_TMPDIR/fcursor.XXXXXX")
  printf '%s' "$input" >"$file"
  run_spell 'spells/cantrips/fathom-cursor' "$@" <"$file"
}

@test 'fathom-cursor parses coordinates' {
  fathom_cursor $'\e[12;34R' -x
  assert_success
  assert_output '34'

  fathom_cursor $'\e[12;34R' -y -v
  assert_success
  assert_output 'Y: 12'

  fathom_cursor $'\e[12;34R'
  assert_success
  assert_output '12;34'

  fathom_cursor $'\e[12;34R' -x -y
  assert_success
  assert_output $'34\n12'

  fathom_cursor $'\e[12;34R' -x -y -v
  assert_success
  assert_output $'X: 34\nY: 12'

  fathom_cursor $'\e[12;34R' -v
  assert_success
  assert_output 'Position: 12;34'
}

make_tput_stub() {
  local dir="$BATS_TEST_TMPDIR/tput"
  mkdir -p "$dir"
  cat <<'TPUT' >"$dir/tput"
#!/usr/bin/env bash
if [ "$1" = "cols" ]; then
  echo 80
else
  echo 24
fi
TPUT
  chmod +x "$dir/tput"
  printf '%s\n' "$dir"
}

@test 'fathom-terminal reports terminal size' {
  tput_dir=$(make_tput_stub)
  PATH="$tput_dir:$ORIGINAL_PATH" run_spell 'spells/cantrips/fathom-terminal' -w -v
  assert_success
  assert_output --partial 'Width: 80'

  PATH="$tput_dir:$ORIGINAL_PATH" run_spell 'spells/cantrips/fathom-terminal' -h
  assert_success
  assert_output '24'

  PATH="$tput_dir:$ORIGINAL_PATH" run_spell 'spells/cantrips/fathom-terminal' -w -h
  assert_success
  assert_line --index 0 '80'
  assert_line --index 1 '24'

  PATH="$tput_dir:$ORIGINAL_PATH" run_spell 'spells/cantrips/fathom-terminal' -w -h -v
  assert_success
  assert_line --index 0 'Width: 80'
  assert_line --index 1 'Height: 24'

  PATH="$tput_dir:$ORIGINAL_PATH" run_spell 'spells/cantrips/fathom-terminal' -v
  assert_success
  assert_output 'Size: 80;24'

  PATH="$tput_dir:$ORIGINAL_PATH" run_spell 'spells/cantrips/fathom-terminal' -z
  assert_failure
  [[ "$stderr" == *'Usage:'* ]]
}

@test 'max-length computes lengths and handles verbosity' {
  run_spell 'spells/cantrips/max-length' 'one three five'
  assert_success
  assert_output '5'

  run_spell 'spells/cantrips/max-length' 'alpha beta' -v
  assert_success
  assert_line --index 0 'Maximum length: 5'
  assert_line --index 1 '5'

  run_spell 'spells/cantrips/max-length' 'luminous glyph'
  assert_success
  assert_output '8'

  run_spell 'spells/cantrips/max-length'
  assert_failure
  [[ "$stderr" == *'Usage'* ]]
}

create_menu_stubs() {
  local dir="$BATS_TEST_TMPDIR/menu"
  mkdir -p "$dir"
  cat <<'FAKE' >"$dir/fathom-cursor"
#!/usr/bin/env bash
echo 2
FAKE
  cat <<'TERM' >"$dir/fathom-terminal"
#!/usr/bin/env bash
if [ "$1" = "-w" ] || [ "$1" = "--width" ]; then
  echo 40
else
  echo 10
fi
TERM
  cat <<'KEYS' >"$dir/await-keypress"
#!/usr/bin/env bash
IFS= read -r key <"$MENU_KEYS"
printf '%s\n' "$key"
tail -n +2 "$MENU_KEYS" >"$MENU_KEYS.tmp" && mv "$MENU_KEYS.tmp" "$MENU_KEYS"
KEYS
  cat <<'BLINK' >"$dir/cursor-blink"
#!/usr/bin/env bash
exit 0
BLINK
  cat <<'MOVE' >"$dir/move-cursor"
#!/usr/bin/env bash
exit 0
MOVE
  chmod +x "$dir"/*
  printf '%s\n' "$dir"
}

@test 'menu runs selected commands and handles escape' {
  menu_workspace="$BATS_TEST_TMPDIR/menu_ws"
  mkdir -p "$menu_workspace"
  cat <<'COL' >"$menu_workspace/colors"
RESET=""
CYAN=""
GREY=""
COL
  chmod +x "$menu_workspace/colors"

  stubs=$(create_menu_stubs)
  keys="$BATS_TEST_TMPDIR/menu_keys"
  printf 'down\nenter\n' >"$keys"
  export MENU_KEYS="$keys"
  PATH="$stubs:$ORIGINAL_PATH"
  pushd "$menu_workspace" >/dev/null
  run_spell 'spells/cantrips/menu' 'Choose:' 'First%echo first' 'Second%echo second'
  popd >/dev/null
  assert_success
  assert_output --partial 'Second'
  assert_output --partial 'first'

  printf 'up\nescape\n' >"$keys"
  export MENU_KEYS="$keys"
  pushd "$menu_workspace" >/dev/null
  run_spell 'spells/cantrips/menu' 'Leave:' 'Alpha%echo alpha' 'Beta%echo beta'
  popd >/dev/null
  assert_success
  assert_output --partial 'ESC'
}

@test 'move-cursor prints ANSI sequence or usage' {
  run_spell 'spells/cantrips/move-cursor' 3 4
  assert_success
  assert_output $'\033[4;3H'

  run_spell 'spells/cantrips/move-cursor' 5
  assert_failure
  [[ "$stderr" == *'Usage'* ]]
}

@test 'say echoes joined arguments' {
  run_spell 'spells/cantrips/say' 'hello world'
  assert_success
  assert_output 'hello world'

  run_spell 'spells/cantrips/say' 'inner' 'ignored'
  assert_success
  assert_output 'inner ignored'
}

