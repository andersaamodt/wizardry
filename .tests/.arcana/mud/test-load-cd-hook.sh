#!/bin/sh
# Tests for cd spell (settings-based, sourceable)
# The cd spell is a sourceable file that defines a cd() override function.
# It reads settings from ~/.spellbook/.mud/config to decide whether to run look.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_cd_help_shows_usage() {
  run_spell spells/.arcana/mud/cd --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "Source this file" || return 1
}

test_cd_defines_cd_function_when_sourced() {
  skip-if-compiled || return $?
  run_cmd sh -c '
    . '"$ROOT_DIR"'/spells/.arcana/mud/cd &&
    type cd | grep -q "function"
  '
  assert_success || return 1
}

test_cd_function_runs_look_when_enabled() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  
  # Create settings file with cd-look enabled
  mkdir -p "$tmpdir/.spellbook/.mud"
  printf "cd-look=1\n" > "$tmpdir/.spellbook/.mud/config"
  
  # Create look stub that creates a marker file
  cat >"$tmpdir/look" <<'SH'
#!/bin/sh
touch "$PWD/.looked"
SH
  chmod +x "$tmpdir/look"
  
  # Create test directory
  mkdir -p "$tmpdir/testdir"
  
  # Test: cd with settings enabled should run look
  run_cmd sh -c '
    export HOME='"$tmpdir"'
    export SPELLBOOK_DIR='"$tmpdir"'/.spellbook
    export PATH='"$tmpdir"':$PATH
    . '"$ROOT_DIR"'/spells/.arcana/mud/cd &&
    cd '"$tmpdir"'/testdir &&
    [ -f .looked ] && printf "look-ran"
  '
  assert_success || return 1
  assert_output_contains "look-ran" || return 1
}

test_cd_function_skips_look_when_disabled() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  
  # Create settings file with cd-look disabled (no cd-look=1 line)
  mkdir -p "$tmpdir/.spellbook/.mud"
  printf "other-setting=1\n" > "$tmpdir/.spellbook/.mud/config"
  
  # Create look stub
  cat >"$tmpdir/look" <<'SH'
#!/bin/sh
touch "$PWD/.looked"
SH
  chmod +x "$tmpdir/look"
  
  # Create test directory
  mkdir -p "$tmpdir/testdir"
  
  # Test: cd with settings disabled should NOT run look
  run_cmd sh -c '
    export HOME='"$tmpdir"'
    export SPELLBOOK_DIR='"$tmpdir"'/.spellbook
    export PATH='"$tmpdir"':$PATH
    . '"$ROOT_DIR"'/spells/.arcana/mud/cd &&
    cd '"$tmpdir"'/testdir &&
    [ ! -f .looked ] && printf "look-not-ran"
  '
  assert_success || return 1
  assert_output_contains "look-not-ran" || return 1
}

run_test_case "cd --help shows usage" test_cd_help_shows_usage
run_test_case "cd defines cd function when sourced" test_cd_defines_cd_function_when_sourced
run_test_case "cd function runs look when enabled" test_cd_function_runs_look_when_enabled
run_test_case "cd function skips look when disabled" test_cd_function_skips_look_when_disabled
finish_tests
