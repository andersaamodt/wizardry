#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"

original_home=$HOME
mark_home=$(make_temp_dir)
export HOME="$mark_home"

# Mark the current directory without arguments.
first_destination=$(make_temp_dir)
pushd "$first_destination" >/dev/null
run_script "spells/mark-location"
popd >/dev/null
expect_exit_code 0
expect_in_output "Location marked at" "$RUN_STDOUT"
marker_file="$HOME/.mud/portal_marker"
expect_eq "$first_destination" "$(cat "$marker_file")"

# Provide a relative path and expect it to resolve to an absolute location.
mkdir -p "$HOME/vault"
pushd "$HOME" >/dev/null
run_script "spells/mark-location" "vault/treasure"
popd >/dev/null
expect_exit_code 0
expect_eq "$HOME/vault/treasure" "$(cat "$marker_file")"

# Reject paths that do not exist.
run_script "spells/mark-location" "$HOME/nonexistent/place"
expect_exit_code 1
expect_in_output "does not exist" "$RUN_STDERR"

# Extra arguments should be refused.
run_script "spells/mark-location" "$HOME/one" "$HOME/two"
expect_exit_code 1
expect_in_output "Usage" "$RUN_STDERR"

export HOME="$original_home"

assert_all_expectations_met
