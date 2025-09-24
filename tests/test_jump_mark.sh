#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"

original_home=$HOME
jump_home=$(make_temp_dir)
export HOME="$jump_home"
touch "$HOME/.bashrc"

stub_dir=$(make_temp_dir)
mkdir -p "$stub_dir/bin"
cat <<'LOOK' >"$stub_dir/bin/look"
#!/usr/bin/env bash
echo "Peering into $(pwd)"
LOOK
chmod +x "$stub_dir/bin/look"

if [[ $PATH == "$stub_dir/bin:"* ]]; then
  BASE_PATH=${PATH#"$stub_dir/bin:"}
else
  BASE_PATH=$PATH
fi

# Without a marker the spell warns the wizard, and consent memorises it.
input_file=$(mktemp "$TEST_TMPDIR/input.XXXXXX")
printf 'y\n' >"$input_file"
exec 7<&0
exec <"$input_file"
PATH="$stub_dir/bin:$BASE_PATH" run_script "spells/jump-to-marker"
exec <&7
exec 7<&-
expect_exit_code 0
expect_in_output "Memorize the 'jump' spell now?" "$RUN_STDOUT"
expect_in_output "The 'jump' spell has been memorized" "$RUN_STDOUT"
expect_in_output "No location has been marked" "$RUN_STDOUT"
expect_in_output "Peering" "$RUN_STDOUT"
expect_in_output "source" "$(cat "$HOME/.bashrc")"

# Mark the current location and confirm the marker file.
destination=$(make_temp_dir)
pushd "$destination" >/dev/null
PATH="$stub_dir/bin:$BASE_PATH" run_script "spells/mark-location"
popd >/dev/null
expect_exit_code 0
marker_file="$HOME/.mud/portal_marker"
expect_eq "$destination" "$(cat "$marker_file")"

# Mark a custom path.
other_target=$(make_temp_dir)
PATH="$stub_dir/bin:$BASE_PATH" run_script "spells/mark-location" "$other_target"
expect_exit_code 0
expect_eq "$other_target" "$(cat "$marker_file")"

# Jump to the marked location now that the spell is memorised.
traveller=$(make_temp_dir)
pushd "$traveller" >/dev/null
RANDOM=0 PATH="$stub_dir/bin:$BASE_PATH" run_script "spells/jump-to-marker"
popd >/dev/null
expect_exit_code 0
expect_not_in_output "Memorize" "$RUN_STDOUT"
expect_in_output "Peering into $other_target" "$RUN_STDOUT"

# Remove the marker and observe the warning.
rm -f "$marker_file"
PATH="$stub_dir/bin:$BASE_PATH" run_script "spells/jump-to-marker"
expect_exit_code 0
expect_in_output "No location has been marked" "$RUN_STDOUT"

export HOME="$original_home"

assert_all_expectations_met
