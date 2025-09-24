#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"

original_home=$HOME
look_home=$(make_temp_dir)
export HOME="$look_home"

look_workspace=$(make_temp_dir)
cat <<'COLORS' >"$look_workspace/colors"
BLUE=""
BOLD=""
RESET=""
COLORS
chmod +x "$look_workspace/colors"

stub_bin="$look_workspace/bin"
mkdir -p "$stub_bin"
read_magic_stub="$stub_bin/read-magic"
cat <<'STUB' >"$read_magic_stub"
#!/usr/bin/env bash
file=$1
key=$2
case "$file" in
  room.txt)
    case "$key" in
      name) echo "Grand Hall" ;;
      description) echo "A vaulted chamber." ;;
      *) echo "Error: The attribute does not exist." ;;
    esac
    ;;
  *)
    echo "Error: The attribute does not exist."
    ;;
esac
STUB
chmod +x "$read_magic_stub"

if [[ $PATH == "$stub_bin:"* ]]; then
  BASE_PATH=${PATH#"$stub_bin:"}
else
  BASE_PATH=$PATH
fi

room_path="$look_workspace/room.txt"
empty_path="$look_workspace/empty.txt"
printf '' >"$room_path"
printf '' >"$empty_path"

# Memorise the spell and reveal a named room.
input_yes=$(mktemp "$TEST_TMPDIR/input.XXXXXX")
printf 'yes\n' >"$input_yes"
exec 8<&0
exec <"$input_yes"
pushd "$look_workspace" >/dev/null
PATH="$stub_bin:$BASE_PATH" run_script "spells/look" "room.txt"
popd >/dev/null
exec <&8
exec 8<&-
expect_exit_code 0
expect_in_output "Grand Hall" "$RUN_STDOUT"
expect_in_output "A vaulted chamber." "$RUN_STDOUT"
expect_in_output "Spell memorized" "$RUN_STDOUT"
expect_in_output "alias look" "$(cat "$HOME/.bashrc")"

# Decline to memorise and observe the fallback message.
printf '' >"$HOME/.bashrc"
input_no=$(mktemp "$TEST_TMPDIR/input.XXXXXX")
printf 'no\n' >"$input_no"
cat <<'STUB2' >"$read_magic_stub"
#!/usr/bin/env bash
echo "Error: The attribute does not exist."
STUB2
chmod +x "$read_magic_stub"
exec 9<&0
exec <"$input_no"
pushd "$look_workspace" >/dev/null
PATH="$stub_bin:$BASE_PATH" run_script "spells/look" "empty.txt"
popd >/dev/null
exec <&9
exec 9<&-
expect_exit_code 0
expect_in_output "The mud will only run" "$RUN_STDOUT"
expect_in_output "You look, but you don't see anything." "$RUN_STDOUT"

export HOME="$original_home"

assert_all_expectations_met
