#!/bin/sh
# Test word-of-binding dispatcher

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: word-of-binding finds modules in imps directory
test_finds_module_in_imps() {
  # The 'say' imp should be findable
  run_spell "spells/.imps/sys/word-of-binding" say "hello world"
  assert_success || return 1
  assert_output_contains "hello world" || return 1
}

# Test: word-of-binding returns 127 for unknown commands  
test_unknown_command_returns_127() {
  run_spell "spells/.imps/sys/word-of-binding" nonexistent-spell-12345
  assert_status 127 || return 1
}

# Test: word-of-binding requires command name
test_requires_command_name() {
  run_spell "spells/.imps/sys/word-of-binding"
  assert_failure || return 1
  assert_error_contains "command name required" || return 1
}

# Test: word-of-binding evokes scripts without true-name functions
test_evokes_scripts_without_functions() {
  # Create a test script without a function
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/.spellbook"
  cat > "$tmpdir/.spellbook/test-evoke-script" << 'EOF'
#!/bin/sh
printf '%s\n' "evoked: $1"
EOF
  chmod +x "$tmpdir/.spellbook/test-evoke-script"
  
  # Set SPELLBOOK_DIR to our temp location
  SPELLBOOK_DIR="$tmpdir/.spellbook" run_spell "spells/.imps/sys/word-of-binding" test-evoke-script myarg
  assert_success || return 1
  assert_output_contains "evoked: myarg" || return 1
}

run_test_case "finds module in imps directory" test_finds_module_in_imps
run_test_case "unknown command returns 127" test_unknown_command_returns_127
run_test_case "requires command name argument" test_requires_command_name
run_test_case "evokes scripts without functions" test_evokes_scripts_without_functions

finish_tests
