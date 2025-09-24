#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"

# Applying a spell to every file should enumerate them and indent the output.
forall_tmp=$(make_temp_dir)
printf 'aaa\n' >"$forall_tmp/a.txt"
printf 'bb\n' >"$forall_tmp/b.txt"

pushd "$forall_tmp" >/dev/null
run_script "spells/forall" wc -c
popd >/dev/null

expect_exit_code 0
expect_in_output "a.txt" "$RUN_STDOUT"
expect_in_output "b.txt" "$RUN_STDOUT"
expect_in_output "   4 ./a.txt" "$RUN_STDOUT"
expect_in_output "   3 ./b.txt" "$RUN_STDOUT"

assert_all_expectations_met
