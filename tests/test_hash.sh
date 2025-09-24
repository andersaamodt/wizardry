#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"

# Missing argument should fail with helpful usage text.
run_script "spells/hash"
expect_exit_code 1
expect_in_output "Usage: hash file" "$RUN_STDOUT" "hash should explain how to invoke the spell"

# Non-existent files should produce a clear error.
run_script "spells/hash" "does-not-exist.txt"
expect_exit_code 1
expect_in_output "Your spell fizzles. There is no file." "$RUN_STDOUT" "hash should complain about missing inputs"

# Hashing an existing file should report the canonical path and CRC-32.
tmp_dir=$(make_temp_dir)
file="$tmp_dir/scroll.txt"
printf 'magic words' >"$file"
relative_dir=${tmp_dir#"$ROOT_DIR/"}
relative_path="../$relative_dir/scroll.txt"
run_script "spells/hash" "$relative_path"
expect_exit_code 0
expected_path=$(cd "$(dirname "$file")" && pwd)/"$(basename "$file")"
expected_crc=$(cksum "$file" | awk '{print $1}')
expected_hex=$(printf '0x%x' "$expected_crc")
expect_in_output "$expected_path" "$RUN_STDOUT" "hash should emit the full resolved file path"
expect_in_output "$expected_hex" "$RUN_STDOUT" "hash should emit a hexadecimal CRC-32"

assert_all_expectations_met
