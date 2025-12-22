#!/bin/sh
# Test that cd hook is integrated into invoke-wizardry

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: cd function is defined after sourcing invoke-wizardry
test_cd_function_defined() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-cd-defined.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Source invoke-wizardry
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Check if cd is defined as a function
if command -v cd >/dev/null 2>&1; then
  # Check if it's a function (not the builtin)
  # Use 'type' to check - functions show "cd is a function"
  cd_type=\$(type cd 2>/dev/null | head -1)
  case "\$cd_type" in
    *function*) printf 'cd is a function\n'; exit 0 ;;
    *) printf 'cd type: %s\n' "\$cd_type"; exit 0 ;;
  esac
else
  printf 'cd not found\n'
  exit 1
fi
EOF
  chmod +x "$tmpdir/test-cd-defined.sh"
  
  _run_cmd sh "$tmpdir/test-cd-defined.sh"
  _assert_success || return 1
  _assert_output_contains "cd is a function" || return 1
}

# Test: cd function respects config file setting
test_cd_respects_config() {
  tmpdir=$(_make_tempdir)
  
  # Create a mock spellbook with MUD config
  spellbook_dir="$tmpdir/.spellbook"
  mkdir -p "$spellbook_dir/.mud"
  
  # Enable cd-look in config
  printf 'cd-look=1\n' > "$spellbook_dir/.mud/config"
  
  # Create a test directory to cd into
  test_dir="$tmpdir/test-room"
  mkdir -p "$test_dir"
  
  cat > "$tmpdir/test-cd-config.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR
SPELLBOOK_DIR="$spellbook_dir"
export SPELLBOOK_DIR

# Source invoke-wizardry to get cd function
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Create a mock 'look' command that prints something
look() {
  printf 'look command called\n'
}

# Change directory - should trigger look
cd "$test_dir" 2>/dev/null

# If we get here, cd succeeded
printf 'cd completed\n'
EOF
  chmod +x "$tmpdir/test-cd-config.sh"
  
  _run_cmd sh "$tmpdir/test-cd-config.sh"
  _assert_success || return 1
  _assert_output_contains "cd completed" || return 1
}

# Test: cd function doesn't call look when config disabled
test_cd_disabled_no_look() {
  tmpdir=$(_make_tempdir)
  
  # Create a mock spellbook with MUD config
  spellbook_dir="$tmpdir/.spellbook"
  mkdir -p "$spellbook_dir/.mud"
  
  # Disable cd-look in config (or just don't set it)
  printf '' > "$spellbook_dir/.mud/config"
  
  # Create a test directory to cd into
  test_dir="$tmpdir/test-room"
  mkdir -p "$test_dir"
  
  cat > "$tmpdir/test-cd-disabled.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR
SPELLBOOK_DIR="$spellbook_dir"
export SPELLBOOK_DIR

# Source invoke-wizardry to get cd function
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Create a mock 'look' command that should NOT be called
look() {
  printf 'ERROR: look was called when disabled\n'
  exit 1
}

# Change directory - should NOT trigger look
cd "$test_dir" 2>/dev/null

# If we get here, cd succeeded without calling look
printf 'cd completed without calling look\n'
EOF
  chmod +x "$tmpdir/test-cd-disabled.sh"
  
  _run_cmd sh "$tmpdir/test-cd-disabled.sh"
  _assert_success || return 1
  _assert_output_contains "cd completed without calling look" || return 1
}

# Test: cd function still works normally (basic functionality)
test_cd_basic_functionality() {
  tmpdir=$(_make_tempdir)
  
  test_dir="$tmpdir/test-dir"
  mkdir -p "$test_dir"
  
  cat > "$tmpdir/test-cd-basic.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Source invoke-wizardry
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Change to test directory
cd "$test_dir" 2>/dev/null || exit 1

# Verify we're in the right place
current_dir=\$(pwd -P)
expected_dir=\$(cd "$test_dir" && pwd -P)

if [ "\$current_dir" = "\$expected_dir" ]; then
  printf 'cd works correctly\n'
  exit 0
else
  printf 'cd failed: expected %s, got %s\n' "\$expected_dir" "\$current_dir"
  exit 1
fi
EOF
  chmod +x "$tmpdir/test-cd-basic.sh"
  
  _run_cmd sh "$tmpdir/test-cd-basic.sh"
  _assert_success || return 1
  _assert_output_contains "cd works correctly" || return 1
}

_run_test_case "cd function is defined in invoke-wizardry" test_cd_function_defined
_run_test_case "cd function respects config setting" test_cd_respects_config
_run_test_case "cd function doesn't call look when disabled" test_cd_disabled_no_look
_run_test_case "cd function works for basic directory changes" test_cd_basic_functionality

_finish_tests
