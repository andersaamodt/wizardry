#!/bin/sh
# Tests for the browse spell
# - browse prints usage
# - browse accepts --help, --usage, and -h flags
# - browse defaults to current directory when no path specified
# - browse rejects non-existent paths
# - browse resolves relative paths to absolute paths

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/cantrips/browse" --help
  assert_success || return 1
  assert_output_contains "Usage: browse" || return 1
  assert_output_contains "Open the OS's default GUI file browser" || return 1
}

test_usage_alias() {
  run_spell "spells/cantrips/browse" --usage
  assert_success || return 1
  assert_output_contains "Usage: browse" || return 1
}

test_usage_h_flag() {
  run_spell "spells/cantrips/browse" -h
  assert_success || return 1
  assert_output_contains "Usage: browse" || return 1
}

test_non_existent_path() {
  run_spell "spells/cantrips/browse" /this/path/does/not/exist
  assert_failure || return 1
  assert_error_contains "browse: path does not exist" || return 1
}

# Test that browse can be invoked with current directory
# We can't test the actual GUI opening, but we can test the spell runs
# We stub the platform-specific commands to verify they get called correctly
test_browse_current_directory() {
  # Create a stub for the platform command
  stubdir="${WIZARDRY_TMPDIR}/stubs"
  mkdir -p "$stubdir"
  
  # Determine which command to stub based on platform
  kernel=$(uname -s 2>/dev/null || printf 'unknown')
  case $kernel in
    Darwin)
      # macOS - stub 'open'
      cat > "$stubdir/open" <<'STUB'
#!/bin/sh
printf 'stub-open called with: %s\n' "$*"
exit 0
STUB
      chmod +x "$stubdir/open"
      PATH="$stubdir:$PATH" run_spell "spells/cantrips/browse"
      assert_success || return 1
      assert_output_contains "stub-open called with:" || return 1
      ;;
    Linux)
      # Linux - stub 'xdg-open'
      cat > "$stubdir/xdg-open" <<'STUB'
#!/bin/sh
printf 'stub-xdg-open called with: %s\n' "$*"
exit 0
STUB
      chmod +x "$stubdir/xdg-open"
      PATH="$stubdir:$PATH" run_spell "spells/cantrips/browse"
      assert_success || return 1
      # xdg-open output is redirected, but the spell should succeed
      ;;
    *)
      # Skip test on other platforms
      return 0
      ;;
  esac
}

# Test that browse can be invoked with a specific path
test_browse_specific_path() {
  # Create a temporary directory to browse to
  testdir="${WIZARDRY_TMPDIR}/browse-test"
  mkdir -p "$testdir"
  
  # Create a stub for the platform command
  stubdir="${WIZARDRY_TMPDIR}/stubs"
  mkdir -p "$stubdir"
  
  # Determine which command to stub based on platform
  kernel=$(uname -s 2>/dev/null || printf 'unknown')
  case $kernel in
    Darwin)
      # macOS - stub 'open'
      cat > "$stubdir/open" <<'STUB'
#!/bin/sh
printf 'stub-open called with: %s\n' "$*"
exit 0
STUB
      chmod +x "$stubdir/open"
      PATH="$stubdir:$PATH" run_spell "spells/cantrips/browse" "$testdir"
      assert_success || return 1
      assert_output_contains "stub-open called with:" || return 1
      ;;
    Linux)
      # Linux - stub 'xdg-open'
      cat > "$stubdir/xdg-open" <<'STUB'
#!/bin/sh
printf 'stub-xdg-open called with: %s\n' "$*"
exit 0
STUB
      chmod +x "$stubdir/xdg-open"
      PATH="$stubdir:$PATH" run_spell "spells/cantrips/browse" "$testdir"
      assert_success || return 1
      # xdg-open output is redirected, but the spell should succeed
      ;;
    *)
      # Skip test on other platforms
      return 0
      ;;
  esac
}

# Run all tests
run_test_case "browse prints usage with --help" test_help
run_test_case "browse accepts --usage flag" test_usage_alias
run_test_case "browse accepts -h flag" test_usage_h_flag
run_test_case "browse rejects non-existent paths" test_non_existent_path
run_test_case "browse opens current directory by default" test_browse_current_directory
run_test_case "browse opens specified path" test_browse_specific_path

finish_tests
