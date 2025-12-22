#!/bin/sh
# COMPILED_UNSUPPORTED: tests install/uninstall scripts which are wizardry bootstrap
# Test install and uninstall scripts

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: Uninstall script is created by install
test_uninstall_script_created() {
  tmpdir=$(_make_tempdir)
  
  # Simulate a minimal install by creating the necessary structure
  wizardry_dir="$tmpdir/wizardry"
  mkdir -p "$wizardry_dir/spells/.imps/sys"
  mkdir -p "$wizardry_dir/spells/divination"
  mkdir -p "$wizardry_dir/spells/cantrips"
  mkdir -p "$wizardry_dir/spells/.arcana/core"
  mkdir -p "$wizardry_dir/spells/.arcana/mud"
  
  # Copy necessary helpers
  cp -r "$ROOT_DIR/spells/.imps/sys/"* "$wizardry_dir/spells/.imps/sys/"
  cp "$ROOT_DIR/spells/divination/detect-rc-file" "$wizardry_dir/spells/divination/"
  cp "$ROOT_DIR/spells/cantrips/ask-yn" "$wizardry_dir/spells/cantrips/"
  chmod +x "$wizardry_dir/spells/divination/detect-rc-file"
  chmod +x "$wizardry_dir/spells/cantrips/ask-yn"
  
  # Create minimal install script that creates uninstall
  cat > "$tmpdir/test-install.sh" << 'EOF'
#!/bin/sh
set -eu

ABS_DIR="$1"
detect_rc_file_value="$2"
detect_format_value="shell"
LOCAL_SOURCE=""
profile_file_modified="$3"

# Inline the create_uninstall_script function from install
EOF
  
  # Extract the create_uninstall_script function from the real install script
  sed -n '/^create_uninstall_script()/,/^}/p' "$ROOT_DIR/install" >> "$tmpdir/test-install.sh"
  
  # Add call to create the uninstall script
  cat >> "$tmpdir/test-install.sh" << 'EOF'

create_uninstall_script
EOF
  
  chmod +x "$tmpdir/test-install.sh"
  
  # Run the test install with profile file
  test_rc="$tmpdir/.testrc"
  test_profile="$tmpdir/.testprofile"
  touch "$test_rc"
  
  _run_cmd "$tmpdir/test-install.sh" "$wizardry_dir" "$test_rc" "$test_profile"
  _assert_success || return 1
  
  # Check that uninstall script was created
  if [ ! -f "$wizardry_dir/.uninstall" ]; then
    TEST_FAILURE_REASON="Uninstall script was not created"
    return 1
  fi
  
  # Check that uninstall script is executable
  if [ ! -x "$wizardry_dir/.uninstall" ]; then
    TEST_FAILURE_REASON="Uninstall script is not executable"
    return 1
  fi
  
  # Check that uninstall script contains PROFILE_FILE variable
  if ! grep -q "PROFILE_FILE=" "$wizardry_dir/.uninstall"; then
    TEST_FAILURE_REASON="Uninstall script missing PROFILE_FILE variable"
    return 1
  fi
}

# Test: Uninstall script removes profile file modifications
test_uninstall_removes_profile_modifications() {
  tmpdir=$(_make_tempdir)
  
  # Create test files
  test_rc="$tmpdir/.testrc"
  test_profile="$tmpdir/.testprofile"
  
  # Create rc file with wizardry marker
  cat > "$test_rc" << 'EOF'
# Test RC file
. "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry" # wizardry: wizardry-init
EOF
  
  # Create profile file with wizardry additions
  cat > "$test_profile" << 'EOF'
# Existing content
export PATH="/usr/local/bin:$PATH"

# Source .testrc if it exists (added by wizardry installer)
if [ -f ~/.testrc ]; then
        . ~/.testrc
fi
EOF
  
  # Create a minimal uninstall script
  cat > "$tmpdir/.uninstall" << EOF
#!/bin/sh
set -eu

INSTALL_DIR="$tmpdir"
INSTALL_WAS_LOCAL=""
RC_FILE="$test_rc"
RC_FORMAT="shell"
PROFILE_FILE="$test_profile"

# Inline color definitions
RESET='' GREEN='' YELLOW='' CYAN='' RED='' BOLD=''

# Remove RC file
if [ -f "\$RC_FILE" ]; then
  tmp_file="\${RC_FILE}.wizardry.\$\$"
  if grep -v '# wizardry:' "\$RC_FILE" > "\$tmp_file" 2>/dev/null; then
    mv "\$tmp_file" "\$RC_FILE"
  else
    rm -f "\$tmp_file"
  fi
fi

# Remove profile file modifications (extracted from install script)
if [ -n "\$PROFILE_FILE" ] && [ -f "\$PROFILE_FILE" ]; then
  tmp_file="\${PROFILE_FILE}.wizardry.\$\$"
  if grep -v 'added by wizardry installer' "\$PROFILE_FILE" > "\$tmp_file" 2>/dev/null; then
    if ! cmp -s "\$PROFILE_FILE" "\$tmp_file" 2>/dev/null; then
      mv "\$tmp_file" "\$PROFILE_FILE"
    else
      rm -f "\$tmp_file"
    fi
  else
    rm -f "\$tmp_file"
  fi
  
  # If profile file is now empty or only contains whitespace/comments, delete it
  if [ -f "\$PROFILE_FILE" ]; then
    if ! grep -qE '^[^#[:space:]]' "\$PROFILE_FILE" 2>/dev/null; then
      if [ ! -s "\$PROFILE_FILE" ] || ! grep -qE '^[^#[:space:]]' "\$PROFILE_FILE" 2>/dev/null; then
        rm -f "\$PROFILE_FILE"
      fi
    fi
  fi
fi
EOF
  chmod +x "$tmpdir/.uninstall"
  
  # Run uninstall
  _run_cmd "$tmpdir/.uninstall"
  _assert_success || return 1
  
  # Check that RC file still exists but wizardry line is removed
  if [ ! -f "$test_rc" ]; then
    TEST_FAILURE_REASON="RC file was deleted (should only be modified)"
    return 1
  fi
  
  if grep -q 'wizardry:' "$test_rc"; then
    TEST_FAILURE_REASON="Wizardry marker still in RC file"
    return 1
  fi
  
  # Check that profile file had wizardry lines removed
  if [ -f "$test_profile" ]; then
    if grep -q 'added by wizardry installer' "$test_profile"; then
      TEST_FAILURE_REASON="Wizardry lines still in profile file"
      return 1
    fi
    # Profile should still have the original content
    if ! grep -q 'export PATH=' "$test_profile"; then
      TEST_FAILURE_REASON="Original profile content was removed"
      return 1
    fi
  fi
}

# Test: Profile file tracks .bash_profile for .bashrc
test_bash_profile_tracking() {
  # Check that the install script has logic to set profile_file_modified
  if ! grep -q 'profile_file_modified=' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="Install script missing profile_file_modified tracking"
    return 1
  fi
  
  # Check for .bash_profile logic
  if ! grep -q '\.bash_profile' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="Install script missing .bash_profile logic"
    return 1
  fi
  
  # Check for .zprofile logic  
  if ! grep -q '\.zprofile' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="Install script missing .zprofile logic"
    return 1
  fi
}

# Test: Uninstall script includes PROFILE_FILE variable
test_uninstall_has_profile_var() {
  # Extract the uninstall script generation from install
  if ! grep -q 'PROFILE_FILE=' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="Install script doesn't pass PROFILE_FILE to uninstall"
    return 1
  fi
  
  # Check that uninstall script generation includes profile cleanup
  # Look between UNINSTALL_MAIN markers for PROFILE_FILE handling
  if ! sed -n '/^.*<<.*UNINSTALL_MAIN/,/^UNINSTALL_MAIN$/p' "$ROOT_DIR/install" | grep -q 'PROFILE_FILE'; then
    TEST_FAILURE_REASON="Uninstall script doesn't handle PROFILE_FILE"
    return 1
  fi
}

_run_test_case "uninstall script is created" test_uninstall_script_created
_run_test_case "uninstall removes profile modifications" test_uninstall_removes_profile_modifications
_run_test_case "bash_profile tracking in install" test_bash_profile_tracking
_run_test_case "uninstall has PROFILE_FILE variable" test_uninstall_has_profile_var

_finish_tests
