#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"

# bind-tome should complain when no directory is given.
run_script "spells/bind-tome"
expect_exit_code 1
expect_in_output "Error: Please provide a folder path as an argument." "$RUN_STDOUT"

# Prepare a tome with a few loose pages.
bind_tmp=$(make_temp_dir)
pages_dir="$bind_tmp/pages"
mkdir -p "$pages_dir"
printf 'alpha rune\n' >"$pages_dir/first"
printf 'beta glyph\n' >"$pages_dir/second"

pushd "$bind_tmp" >/dev/null
run_script "spells/bind-tome" "pages"
popd >/dev/null
expect_exit_code 0
expect_in_output "Text file created: pages.txt" "$RUN_STDOUT"

bound_scroll="$bind_tmp/pages.txt"
bound_content=$(cat "$bound_scroll")
expect_in_output "first" "$bound_content"
expect_in_output "alpha rune" "$bound_content"
expect_in_output "End of first" "$bound_content"
expect_in_output "second" "$bound_content"
expect_in_output "beta glyph" "$bound_content"
expect_in_output "End of second" "$bound_content"

# Requesting deletion without a source directory currently builds an empty tome.
pushd "$bind_tmp" >/dev/null
run_script "spells/bind-tome" "-d"
popd >/dev/null
expect_exit_code 0
expect_in_output "Original files deleted." "$RUN_STDOUT"
expect_in_output "Text file created: .txt" "$RUN_STDOUT"

# unbind-tome should report misuse.
run_script "spells/unbind-tome"
expect_exit_code 1
expect_in_output "Error: Please provide a file path as an argument." "$RUN_STDOUT"

# Splitting a tome should create a directory per line with sanitised names.
unbind_tmp=$(make_temp_dir)
scroll="$unbind_tmp/story.txt"
cat <<'STORY' >"$scroll"
First page
Symbols & sigils
Trailing space 
STORY

pushd "$unbind_tmp" >/dev/null
run_script "spells/unbind-tome" "story.txt"
popd >/dev/null
expect_exit_code 0
expect_not_in_output "Error" "$RUN_STDERR"

pieces_dir="$unbind_tmp/story"
expect_eq "true" "$( [ -d "$pieces_dir" ] && echo true || echo false )" "unbind-tome should craft a directory for the torn pages"
expect_eq "true" "$( [ -f "$pieces_dir/First_page" ] && echo true || echo false )" "First page should become a file"
expect_eq "true" "$( [ -f "$pieces_dir/Symbols__sigils" ] && echo true || echo false )" "Punctuation should be stripped"
expect_eq "true" "$( [ -f "$pieces_dir/Trailing_space" ] && echo true || echo false )" "Trailing space should be trimmed"

assert_all_expectations_met
