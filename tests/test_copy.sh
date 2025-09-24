#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"
source "$(dirname "$0")/lib/stub_helpers.sh"

BASE_PATH=$PATH

# Missing file should fail.
run_script "spells/copy" "$TEST_TMPDIR/nowhere.txt"
expect_exit_code 1
expect_in_output "That file does not exist." "$RUN_STDOUT"

# pbcopy branch copies contents.
tmp_dir=$(make_temp_dir)
scroll="$tmp_dir/scroll.txt"
printf 'mystic runes' >"$scroll"
clipboard="$tmp_dir/pbcopy.txt"
pbcopy_stub=$(wizardry_install_clipboard_stubs pbcopy)
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$pbcopy_stub" "$BASE_PATH")" \
  CLIPBOARD_FILE="$clipboard" run_script "spells/copy" "$scroll"
expect_exit_code 0
expect_eq "mystic runes" "$(cat "$clipboard")" "pbcopy should capture the scroll contents"

# xsel fallback when pbcopy unavailable.
clipboard="$tmp_dir/xsel.txt"
xsel_stub=$(wizardry_install_clipboard_stubs xsel)
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$xsel_stub" "$BASE_PATH")" \
  CLIPBOARD_FILE="$clipboard" run_script "spells/copy" "$scroll"
expect_exit_code 0
expect_eq "mystic runes" "$(cat "$clipboard")" "xsel fallback should copy data"

# xclip fallback when pbcopy and xsel unavailable.
clipboard="$tmp_dir/xclip.txt"
xclip_stub=$(wizardry_install_clipboard_stubs xclip)
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$xclip_stub" "$BASE_PATH")" \
  CLIPBOARD_FILE="$clipboard" run_script "spells/copy" "$scroll"
expect_exit_code 0
expect_eq "mystic runes" "$(cat "$clipboard")" "xclip fallback should copy data"

# Without any clipboard helpers, spell should fail.
RUN_PATH_OVERRIDE="$BASE_PATH" run_script "spells/copy" "$scroll"
expect_exit_code 1
expect_in_output "Your spell fizzles." "$RUN_STDERR" "copy should explain lack of clipboard helpers"

assert_all_expectations_met
