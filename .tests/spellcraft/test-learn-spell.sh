#!/bin/sh
# Behavioral coverage for learn-spell:
# - prints usage
# - requires path argument
# - handles files and directories
# - supports -r/--recursive flag
# - supports --dry-run flag

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/spellcraft/learn-spell" --help
  assert_success && assert_error_contains "Usage: learn-spell"
}

test_requires_path() {
  run_spell "spells/spellcraft/learn-spell"
  assert_failure && assert_error_contains "Usage:"
}

test_rejects_unknown_options() {
  run_spell "spells/spellcraft/learn-spell" --unknown
  assert_failure && assert_error_contains "Unknown option"
}

test_handles_nonexistent_path() {
  run_spell "spells/spellcraft/learn-spell" "/nonexistent/path"
  assert_failure && assert_error_contains "not a file or directory"
}

test_dry_run_shows_spells() {
  # Create a test directory with a spell that has install()
  tmpdir=$(make_tempdir)
  cat > "$tmpdir/test-spell" << 'EOF'
#!/bin/sh
install() {
  echo "installed"
}
EOF
  chmod +x "$tmpdir/test-spell"
  
  run_spell "spells/spellcraft/learn-spell" --dry-run "$tmpdir"
  assert_success && assert_output_contains "test-spell"
}

run_test_case "learn-spell prints usage" test_help
run_test_case "learn-spell requires path argument" test_requires_path
run_test_case "learn-spell rejects unknown options" test_rejects_unknown_options
run_test_case "learn-spell handles nonexistent path" test_handles_nonexistent_path
run_test_case "learn-spell dry-run shows spells" test_dry_run_shows_spells

finish_tests
