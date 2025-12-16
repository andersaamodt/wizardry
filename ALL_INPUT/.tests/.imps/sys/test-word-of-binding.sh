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
  skip-if-compiled || return $?
  # The 'say' imp should be findable
  _run_spell "spells/.imps/sys/word-of-binding" say "hello world"
  _assert_success || return 1
  _assert_output_contains "hello world" || return 1
}

# Test: word-of-binding returns 127 for unknown commands  
test_unknown_command_returns_127() {
  skip-if-compiled || return $?
  _run_spell "spells/.imps/sys/word-of-binding" nonexistent-spell-12345
  _assert_status 127 || return 1
}

# Test: word-of-binding requires command name
test_requires_command_name() {
  skip-if-compiled || return $?
  _run_spell "spells/.imps/sys/word-of-binding"
  _assert_failure || return 1
  _assert_error_contains "command name required" || return 1
}

# Test: word-of-binding evokes scripts without true-name functions
test_evokes_scripts_without_functions() {
  skip-if-compiled || return $?
  # Create a test script without a function
  tmpdir=$(_make_tempdir)
  mkdir -p "$tmpdir/.spellbook"
  cat > "$tmpdir/.spellbook/test-evoke-script" << 'EOF'
#!/bin/sh
printf '%s\n' "evoked: $1"
EOF
  chmod +x "$tmpdir/.spellbook/test-evoke-script"
  
  # Set SPELLBOOK_DIR to our temp location
  SPELLBOOK_DIR="$tmpdir/.spellbook" _run_spell "spells/.imps/sys/word-of-binding" test-evoke-script myarg
  _assert_success || return 1
  _assert_output_contains "evoked: myarg" || return 1
}

_run_test_case "finds module in imps directory" test_finds_module_in_imps
_run_test_case "unknown command returns 127" test_unknown_command_returns_127
_run_test_case "requires command name argument" test_requires_command_name
_run_test_case "evokes scripts without functions" test_evokes_scripts_without_functions

_finish_tests
