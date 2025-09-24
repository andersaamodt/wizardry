#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"

ORIGINAL_HOME=$HOME
ORIGINAL_PATH=$PATH

# --- ask ---
ask_input=$(mktemp "$TEST_TMPDIR/ask.XXXXXX")
printf 'response\n' >"$ask_input"
exec 12<&0
exec <"$ask_input"
run_script "spells/cantrips/ask" "Your name?"
exec <&12
exec 12<&-
expect_exit_code 0
expect_eq $'Your name?\nresponse\n' "$RUN_STDOUT"

# --- ask_yn ---
astty_stub=$(mktemp -d "$TEST_TMPDIR/stty.XXXXXX")
cat <<'STTY' >"$astty_stub/stty"
#!/usr/bin/env bash
exit 0
STTY
chmod +x "$astty_stub/stty"

ask_yn_input=$(mktemp "$TEST_TMPDIR/askyn.XXXXXX")
printf 'y' >"$ask_yn_input"
exec 13<&0
exec <"$ask_yn_input"
PATH="$astty_stub:$ORIGINAL_PATH" run_script "spells/cantrips/ask_yn" "Proceed?" y
exec <&13
exec 13<&-
expect_exit_code 0
expect_in_output "Proceed? (Y/n)?" "$RUN_STDERR"
expect_in_output "Y" "$RUN_STDERR"

ask_yn_default=$(mktemp "$TEST_TMPDIR/askyn_default.XXXXXX")
printf '\r' >"$ask_yn_default"
exec 14<&0
exec <"$ask_yn_default"
PATH="$astty_stub:$ORIGINAL_PATH" run_script "spells/cantrips/ask_yn" "Continue?" n
exec <&14
exec 14<&-
expect_exit_code 1
expect_in_output "Continue? (y/N)?" "$RUN_STDERR"
expect_in_output "N" "$RUN_STDERR"

ask_yn_no=$(mktemp "$TEST_TMPDIR/askyn_no.XXXXXX")
printf 'n' >"$ask_yn_no"
exec 15<&0
exec <"$ask_yn_no"
PATH="$astty_stub:$ORIGINAL_PATH" run_script "spells/cantrips/ask_yn" "Retry?" y
exec <&15
exec 15<&-
expect_exit_code 1
expect_in_output "Retry? (Y/n)?" "$RUN_STDERR"
expect_in_output "N" "$RUN_STDERR"

# --- assertions ---
helper_success="$TEST_TMPDIR/assert_success.sh"
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
run_script "${helper_success#$ROOT_DIR/}"
expect_exit_code 0

helper_failure="$TEST_TMPDIR/assert_failure.sh"
cat <<'FAIL' >"$helper_failure"
#!/usr/bin/env bash
set -euo pipefail
source "$ROOT_DIR/spells/cantrips/assertions"
assert_equal 1 2
FAIL
chmod +x "$helper_failure"
run_script "${helper_failure#$ROOT_DIR/}"
expect_exit_code 1
expect_in_output "Assertion failed" "$RUN_STDOUT"

# --- await-keypress ---
run_with_keys() {
  local content=$1
  local expected=$2
  local file
  file=$(mktemp "$TEST_TMPDIR/key.XXXXXX")
  printf '%b' "$content" >"$file"
  run_script "spells/cantrips/await-keypress" <"$file"
  expect_exit_code 0
  expect_eq "$expected" "$RUN_STDOUT"
}
run_with_keys $'a' 'a'
run_with_keys $'\n' 'enter'
run_with_keys $'\t' 'tab'
run_with_keys $'\b' 'backspace'
run_with_keys $'\177' 'backspace'
run_with_keys $'\e' 'escape'
run_with_keys $'\e[A' 'up'
run_with_keys $'\e[B' 'down'
run_with_keys $'\e[C' 'right'
run_with_keys $'\e[D' 'left'
run_with_keys $'\e[3~' 'delete'
run_with_keys $'\e[Z' 'escaped key: [Z'

# --- cd ---
cd_home=$(make_temp_dir)
export HOME="$cd_home"
touch "$HOME/.bashrc"
look_stub=$(mktemp -d "$TEST_TMPDIR/look.XXXXXX")
cat <<'LOOK' >"$look_stub/look"
#!/usr/bin/env bash
echo "LOOK:$@"
LOOK
chmod +x "$look_stub/look"

cd_input=$(mktemp "$TEST_TMPDIR/cd_yes.XXXXXX")
printf 'yes\n' >"$cd_input"
exec 16<&0
exec <"$cd_input"
PATH="$look_stub:$ORIGINAL_PATH" run_script "spells/cantrips/cd" "$ROOT_DIR"
exec <&16
exec 16<&-
expect_exit_code 0
expect_in_output "Spell memorized" "$RUN_STDOUT"
expect_in_output "LOOK:" "$RUN_STDOUT"
expect_in_output "alias cd=" "$(cat "$HOME/.bashrc")"

printf '' >"$HOME/.bashrc"
cd_input_no=$(mktemp "$TEST_TMPDIR/cd_no.XXXXXX")
printf 'no\n' >"$cd_input_no"
exec 17<&0
exec <"$cd_input_no"
PATH="$look_stub:$ORIGINAL_PATH" run_script "spells/cantrips/cd" "$ROOT_DIR"
exec <&17
exec 17<&-
expect_exit_code 0
expect_in_output "The mud will only run" "$RUN_STDOUT"

export HOME="$ORIGINAL_HOME"

# --- colors ---
run_script "spells/cantrips/colors"
expect_exit_code 0
expect_eq "" "$RUN_STDOUT"

# --- cursor-blink ---
run_script "spells/cantrips/cursor-blink" on
expect_exit_code 0
expect_eq $'\033[?25h' "$RUN_STDOUT"
run_script "spells/cantrips/cursor-blink" off
expect_exit_code 0
expect_eq $'\033[?25l' "$RUN_STDOUT"
run_script "spells/cantrips/cursor-blink"
expect_exit_code 1
expect_in_output "Usage: cast_cursor_blink on|off" "$RUN_STDOUT"

# --- fathom-cursor ---
fathom_input=$(mktemp "$TEST_TMPDIR/fcursor.XXXXXX")
printf '\e[12;34R' >"$fathom_input"
exec 18<&0
exec <"$fathom_input"
run_script "spells/cantrips/fathom-cursor" -x
exec <&18
exec 18<&-
expect_exit_code 0
expect_eq '34\n' "$RUN_STDOUT"

fathom_input2=$(mktemp "$TEST_TMPDIR/fcursor2.XXXXXX")
printf '\e[12;34R' >"$fathom_input2"
exec 19<&0
exec <"$fathom_input2"
run_script "spells/cantrips/fathom-cursor" -y -v
exec <&19
exec 19<&-
expect_exit_code 0
expect_eq $'Y: 12\n' "$RUN_STDOUT"

fathom_input3=$(mktemp "$TEST_TMPDIR/fcursor3.XXXXXX")
printf '\e[12;34R' >"$fathom_input3"
exec 20<&0
exec <"$fathom_input3"
run_script "spells/cantrips/fathom-cursor"
exec <&20
exec 20<&-
expect_exit_code 0
expect_eq $'12;34\n' "$RUN_STDOUT"

fathom_input4=$(mktemp "$TEST_TMPDIR/fcursor4.XXXXXX")
printf '\e[12;34R' >"$fathom_input4"
exec 21<&0
exec <"$fathom_input4"
run_script "spells/cantrips/fathom-cursor" -x -y
exec <&21
exec 21<&-
expect_exit_code 0
expect_eq $'34\n12\n' "$RUN_STDOUT"

fathom_input5=$(mktemp "$TEST_TMPDIR/fcursor5.XXXXXX")
printf '\e[12;34R' >"$fathom_input5"
exec 22<&0
exec <"$fathom_input5"
run_script "spells/cantrips/fathom-cursor" -x -y -v
exec <&22
exec 22<&-
expect_exit_code 0
expect_eq $'X: 34\nY: 12\n' "$RUN_STDOUT"

fathom_input6=$(mktemp "$TEST_TMPDIR/fcursor6.XXXXXX")
printf '\e[12;34R' >"$fathom_input6"
exec 23<&0
exec <"$fathom_input6"
run_script "spells/cantrips/fathom-cursor" -v
exec <&23
exec 23<&-
expect_exit_code 0
expect_eq $'Position: 12;34\n' "$RUN_STDOUT"

# --- fathom-terminal ---
tput_stub=$(mktemp -d "$TEST_TMPDIR/tput.XXXXXX")
cat <<'TPUT' >"$tput_stub/tput"
#!/usr/bin/env bash
if [ "$1" = "cols" ]; then
  echo 80
else
  echo 24
fi
TPUT
chmod +x "$tput_stub/tput"
PATH="$tput_stub:$ORIGINAL_PATH" run_script "spells/cantrips/fathom-terminal" -w -v
expect_exit_code 0
expect_eq $'Width: 80\n' "$RUN_STDOUT"
PATH="$tput_stub:$ORIGINAL_PATH" run_script "spells/cantrips/fathom-terminal" -h
expect_exit_code 0
expect_eq $'24\n' "$RUN_STDOUT"
PATH="$tput_stub:$ORIGINAL_PATH" run_script "spells/cantrips/fathom-terminal" -w -h
expect_exit_code 0
expect_eq $'80\n24\n' "$RUN_STDOUT"
PATH="$tput_stub:$ORIGINAL_PATH" run_script "spells/cantrips/fathom-terminal" -w -h -v
expect_exit_code 0
expect_eq $'Width: 80\nHeight: 24\n' "$RUN_STDOUT"
PATH="$tput_stub:$ORIGINAL_PATH" run_script "spells/cantrips/fathom-terminal" -v
expect_exit_code 0
expect_eq $'Size: 80;24\n' "$RUN_STDOUT"
PATH="$tput_stub:$ORIGINAL_PATH" run_script "spells/cantrips/fathom-terminal" -z
expect_exit_code 1
expect_in_output "Usage:" "$RUN_STDERR"

# --- max-length ---
run_script "spells/cantrips/max-length" 'one three five'
expect_exit_code 0
expect_eq '5\n' "$RUN_STDOUT"
run_script "spells/cantrips/max-length" 'alpha beta' -v
expect_exit_code 0
expect_eq $'Maximum length: 5\n5\n' "$RUN_STDOUT"
run_script "spells/cantrips/max-length" 'luminous' 'glyph'
expect_exit_code 0
expect_eq '8\n' "$RUN_STDOUT"
run_script "spells/cantrips/max-length"
expect_exit_code 1
expect_in_output "Usage" "$RUN_STDERR"

# --- menu ---
menu_workspace=$(make_temp_dir)
cat <<'COL' >"$menu_workspace/colors"
RESET=""
CYAN=""
GREY=""
COL
chmod +x "$menu_workspace/colors"
menu_stub_dir=$(mktemp -d "$TEST_TMPDIR/menu.XXXXXX")
cat <<'FAKE' >"$menu_stub_dir/fathom-cursor"
#!/usr/bin/env bash
echo 2
FAKE
cat <<'TERM' >"$menu_stub_dir/fathom-terminal"
#!/usr/bin/env bash
if [ "$1" = "-w" ] || [ "$1" = "--width" ]; then
  echo 40
else
  echo 10
fi
TERM
cat <<'KEYS' >"$menu_stub_dir/await-keypress"
#!/usr/bin/env bash
IFS= read -r key <"$MENU_KEYS"
printf '%s\n' "$key"
tail -n +2 "$MENU_KEYS" >"$MENU_KEYS.tmp" && mv "$MENU_KEYS.tmp" "$MENU_KEYS"
KEYS
cat <<'BLINK' >"$menu_stub_dir/cursor-blink"
#!/usr/bin/env bash
exit 0
BLINK
cat <<'MOVE' >"$menu_stub_dir/move-cursor"
#!/usr/bin/env bash
exit 0
MOVE
chmod +x "$menu_stub_dir"/*

menu_keys_file=$(mktemp "$TEST_TMPDIR/keys.XXXXXX")
printf 'down\nenter\n' >"$menu_keys_file"
export MENU_KEYS="$menu_keys_file"
PATH="$menu_stub_dir:$ORIGINAL_PATH"
pushd "$menu_workspace" >/dev/null
run_script "spells/cantrips/menu" "Choose:" "First%echo first" "Second%echo second"
popd >/dev/null
PATH="$ORIGINAL_PATH"
expect_exit_code 0
expect_in_output "Second" "$RUN_STDOUT"
expect_in_output "first" "$RUN_STDOUT"

printf 'up\nescape\n' >"$menu_keys_file"
export MENU_KEYS="$menu_keys_file"
PATH="$menu_stub_dir:$ORIGINAL_PATH"
pushd "$menu_workspace" >/dev/null
run_script "spells/cantrips/menu" "Leave:" "Alpha%echo alpha" "Beta%echo beta"
popd >/dev/null
PATH="$ORIGINAL_PATH"
expect_exit_code 0
expect_in_output "ESC" "$RUN_STDOUT"

# --- move-cursor ---
run_script "spells/cantrips/move-cursor" 3 4
expect_exit_code 0
expect_eq $'\033[4;3H' "$RUN_STDOUT"
run_script "spells/cantrips/move-cursor" 5
expect_exit_code 1
expect_in_output "Usage" "$RUN_STDERR"

# --- say ---
run_script "spells/cantrips/say" 'hello world'
expect_exit_code 0
expect_eq 'hello world\n' "$RUN_STDOUT"
run_script "spells/cantrips/say" 'inner' 'ignored'
expect_exit_code 0
expect_eq $'inner ignored\n' "$RUN_STDOUT"

unset MENU_KEYS
PATH="$ORIGINAL_PATH"

assert_all_expectations_met
