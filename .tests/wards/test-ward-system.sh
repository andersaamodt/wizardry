#!/bin/sh
# Test coverage for ward-system spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that ward-system exists and is executable
test_ward_system_exists() {
  [ -f "$ROOT_DIR/spells/wards/ward-system" ] && [ -x "$ROOT_DIR/spells/wards/ward-system" ]
}

# Test that ward-system shows help
test_ward_system_help() {
  run_spell spells/wards/ward-system --help
  assert_success
  assert_output_contains "Usage: ward-system"
  assert_output_contains "LEVEL"
  assert_output_contains "Recommended"
  assert_output_contains "Advanced"
  assert_output_contains "Expert"
}

# Test ward-system with -h flag
test_ward_system_help_short() {
  run_spell spells/wards/ward-system -h
  assert_success
  assert_output_contains "Usage: ward-system"
}

# Test ward-system level 1 (default)
test_ward_system_level_1() {
  skip-if-compiled || return $?
  run_spell spells/wards/ward-system 1
  assert_success
  assert_output_contains "Level 1"
  assert_output_contains "Recommended Security Checks"
}

# Test ward-system with no arguments (defaults to level 1)
test_ward_system_default_level() {
  skip-if-compiled || return $?
  run_spell spells/wards/ward-system
  assert_success
  assert_output_contains "Level 1"
}

# Test ward-system level 2
test_ward_system_level_2() {
  skip-if-compiled || return $?
  run_spell spells/wards/ward-system 2
  assert_success
  assert_output_contains "Level 1"
  assert_output_contains "Level 2"
  assert_output_contains "Advanced Security Checks"
}

# Test ward-system level 3
test_ward_system_level_3() {
  skip-if-compiled || return $?
  run_spell spells/wards/ward-system 3
  assert_success
  assert_output_contains "Level 1"
  assert_output_contains "Level 2"
  assert_output_contains "Level 3"
  assert_output_contains "Expert Security Checks"
}

# Test ward-system with verbose flag
test_ward_system_verbose() {
  skip-if-compiled || return $?
  run_spell spells/wards/ward-system 1 --verbose
  assert_success
  assert_output_contains "Level 1"
}

# Test ward-system with -v flag
test_ward_system_verbose_short() {
  skip-if-compiled || return $?
  run_spell spells/wards/ward-system 1 -v
  assert_success
  assert_output_contains "Level 1"
}

# Test ward-system with --no-fix flag
test_ward_system_no_fix() {
  skip-if-compiled || return $?
  run_spell spells/wards/ward-system 1 --no-fix
  assert_success
  assert_output_contains "Level 1"
}

# Test ward-system detects PATH with current directory
test_ward_system_detects_path_issue() {
  skip-if-compiled || return $?
  # Add current directory to PATH
  PATH=".:$PATH" run_spell spells/wards/ward-system 1
  assert_success
  assert_output_contains "Current directory"
}

# Test ward-system checks umask
test_ward_system_checks_umask() {
  skip-if-compiled || return $?
  run_spell spells/wards/ward-system 1
  assert_success
  assert_output_contains "mask"
}

# Test ward-system with invalid argument
test_ward_system_invalid_arg() {
  skip-if-compiled || return $?
  run_spell spells/wards/ward-system --invalid
  assert_failure
  assert_error_contains "unknown option"
}

# Test ward-system checks SSH directory if it exists
test_ward_system_ssh_check() {
  skip-if-compiled || return $?
  
  # Create temporary test environment
  tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/ward-system-test.XXXXXX")
  
  # Save original HOME and set to temp
  old_home=$HOME
  HOME=$tmpdir
  
  # Create .ssh directory with correct permissions
  mkdir -p "$tmpdir/.ssh"
  chmod 700 "$tmpdir/.ssh"
  
  # Run ward-system
  run_spell spells/wards/ward-system 1
  
  # Restore HOME
  HOME=$old_home
  
  # Clean up
  rm -rf "$tmpdir"
  
  assert_success
  assert_output_contains "Level 1"
}

# Test ward-system detects insecure SSH directory permissions
test_ward_system_detects_bad_ssh_perms() {
  skip-if-compiled || return $?
  
  # Create a wrapper script that sets up bad SSH perms and then runs ward-system
  tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/ward-system-test.XXXXXX")
  wrapper="$tmpdir/test-wrapper.sh"
  
  cat >"$wrapper" <<'WRAPPER'
#!/bin/sh
set -eu
# Create .ssh with insecure permissions in the sandbox HOME
mkdir -p "$HOME/.ssh"
chmod 755 "$HOME/.ssh"

# Export ASK_CANTRIP_INPUT to avoid prompts
export ASK_CANTRIP_INPUT=none

# Run ward-system
exec ward-system 1 --no-fix
WRAPPER
  chmod +x "$wrapper"
  
  run_cmd "$wrapper"
  
  rm -rf "$tmpdir"
  
  assert_success
  assert_output_contains "insecure"
}

# Run all tests
run_test_case "ward-system exists and is executable" test_ward_system_exists
run_test_case "ward-system shows help" test_ward_system_help
run_test_case "ward-system shows help with -h" test_ward_system_help_short
run_test_case "ward-system runs level 1" test_ward_system_level_1
run_test_case "ward-system defaults to level 1" test_ward_system_default_level
run_test_case "ward-system runs level 2" test_ward_system_level_2
run_test_case "ward-system runs level 3" test_ward_system_level_3
run_test_case "ward-system accepts --verbose" test_ward_system_verbose
run_test_case "ward-system accepts -v" test_ward_system_verbose_short
run_test_case "ward-system accepts --no-fix" test_ward_system_no_fix
run_test_case "ward-system detects PATH issue" test_ward_system_detects_path_issue
run_test_case "ward-system checks umask" test_ward_system_checks_umask
run_test_case "ward-system rejects invalid argument" test_ward_system_invalid_arg
run_test_case "ward-system checks SSH directory" test_ward_system_ssh_check
run_test_case "ward-system detects bad SSH permissions" test_ward_system_detects_bad_ssh_perms

finish_tests
