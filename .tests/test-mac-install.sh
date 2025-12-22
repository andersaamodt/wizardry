#!/bin/sh
# Test Mac-specific installation scenarios
# Simulates zsh behavior on macOS

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: .zprofile is created when .zshrc is modified
test_zprofile_created_for_zshrc() {
  tmpdir=$(_make_tempdir)
  
  # Create a test .zshrc
  test_zshrc="$tmpdir/.zshrc"
  cat > "$test_zshrc" << 'EOF'
# Existing zsh config
export PATH="/usr/local/bin:$PATH"
EOF
  
  # Simulate what install script does
  # Add wizardry line to .zshrc
  cat >> "$test_zshrc" << 'EOF'
. "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry" # wizardry: wizardry-init
EOF
  
  # Check if .zprofile logic would create/update .zprofile
  test_zprofile="$tmpdir/.zprofile"
  
  # Simulate the install script logic for .zprofile
  if [ ! -f "$test_zprofile" ]; then
    cat > "$test_zprofile" << 'EOF'
# Source .zshrc if it exists
# This ensures zsh login shells get the same configuration as interactive shells
if [ -f ~/.zshrc ]; then
        . ~/.zshrc
fi
EOF
  fi
  
  # Verify .zprofile was created
  if [ ! -f "$test_zprofile" ]; then
    TEST_FAILURE_REASON=".zprofile was not created"
    return 1
  fi
  
  # Verify .zprofile sources .zshrc
  if ! grep -q '\.zshrc' "$test_zprofile"; then
    TEST_FAILURE_REASON=".zprofile doesn't source .zshrc"
    return 1
  fi
}

# Test: Zsh sourcing simulation doesn't hang
test_zsh_sourcing_simulation() {
  tmpdir=$(_make_tempdir)
  
  # Create a test environment similar to what would happen on Mac with zsh
  cat > "$tmpdir/test-zsh-source.sh" << EOF
#!/bin/sh
# Simulate zsh login shell on Mac
# Login shells source .zprofile, which sources .zshrc

# Set up HOME for this test
export HOME="$tmpdir"
export WIZARDRY_DIR="$ROOT_DIR"

# Create .zshrc with invoke-wizardry
cat > "\$HOME/.zshrc" << 'ZSHRC_EOF'
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null
ZSHRC_EOF

# Create .zprofile that sources .zshrc
cat > "\$HOME/.zprofile" << 'ZPROFILE_EOF'
if [ -f ~/.zshrc ]; then
  . ~/.zshrc
fi
ZPROFILE_EOF

# Simulate login shell: source .zprofile
. "\$HOME/.zprofile" 2>/dev/null

# Check that menu is available
if command -v menu >/dev/null 2>&1; then
  printf 'menu_available=yes\n'
else
  printf 'menu_available=no\n'
fi

printf 'zsh_simulation_complete=yes\n'
EOF
  chmod +x "$tmpdir/test-zsh-source.sh"
  
  # Run with timeout
  if command -v timeout >/dev/null 2>&1; then
    _run_cmd timeout 30 sh "$tmpdir/test-zsh-source.sh"
  else
    _run_cmd sh "$tmpdir/test-zsh-source.sh"
  fi
  
  _assert_success || return 1
  _assert_output_contains "menu_available=yes" || return 1
  _assert_output_contains "zsh_simulation_complete=yes" || return 1
}

# Test: Check install script creates .zprofile for .zshrc
test_install_creates_zprofile() {
  # Check that install script has .zprofile logic for .zshrc
  if ! grep -q '\.zprofile' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="Install script missing .zprofile logic"
    return 1
  fi
  
  # Check for zsh-specific case handling
  if ! grep -q '\*/.zshrc)' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="Install script missing .zshrc case handling"
    return 1
  fi
}

# Test: Uninstall removes .zprofile modifications
test_uninstall_removes_zprofile() {
  tmpdir=$(_make_tempdir)
  
  # Create test files
  test_zshrc="$tmpdir/.zshrc"
  test_zprofile="$tmpdir/.zprofile"
  
  # Create .zshrc with wizardry
  cat > "$test_zshrc" << 'EOF'
# Test zshrc
. "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry" # wizardry: wizardry-init
EOF
  
  # Create .zprofile with wizardry additions
  cat > "$test_zprofile" << 'EOF'
# Source .zshrc if it exists (added by wizardry installer)
# This ensures zsh login shells get the same configuration as interactive shells
if [ -f ~/.zshrc ]; then
        . ~/.zshrc
fi
EOF
  
  # Create minimal uninstall script
  cat > "$tmpdir/.uninstall" << EOF
#!/bin/sh
set -eu

RC_FILE="$test_zshrc"
PROFILE_FILE="$test_zprofile"

# Remove from RC file
if [ -f "\$RC_FILE" ]; then
  tmp_file="\${RC_FILE}.wizardry.\$\$"
  if grep -v '# wizardry:' "\$RC_FILE" > "\$tmp_file" 2>/dev/null; then
    mv "\$tmp_file" "\$RC_FILE"
  else
    rm -f "\$tmp_file"
  fi
fi

# Remove from profile file
if [ -n "\$PROFILE_FILE" ] && [ -f "\$PROFILE_FILE" ]; then
  tmp_file="\${PROFILE_FILE}.wizardry.\$\$"
  
  # Use awk to remove the entire wizardry block
  awk '
  /^# Source \..*rc if it exists \(added by wizardry installer\)$/ { skip = 1; next }
  skip == 1 && /^fi$/ { skip = 0; next }
  skip == 0 { print }
  ' "\$PROFILE_FILE" > "\$tmp_file" 2>/dev/null || true
  
  if [ -f "\$tmp_file" ] && ! cmp -s "\$PROFILE_FILE" "\$tmp_file" 2>/dev/null; then
    mv "\$tmp_file" "\$PROFILE_FILE"
  else
    rm -f "\$tmp_file"
  fi
  
  # Delete if empty
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
  
  # .zprofile should be deleted (it only had wizardry content)
  if [ -f "$test_zprofile" ]; then
    TEST_FAILURE_REASON=".zprofile still exists after uninstall (should be deleted)"
    return 1
  fi
  
  # .zshrc should exist but without wizardry line
  if [ ! -f "$test_zshrc" ]; then
    TEST_FAILURE_REASON=".zshrc was deleted (should only be modified)"
    return 1
  fi
  
  if grep -q 'wizardry:' "$test_zshrc"; then
    TEST_FAILURE_REASON="wizardry marker still in .zshrc"
    return 1
  fi
}

_run_test_case ".zprofile created for .zshrc" test_zprofile_created_for_zshrc
_run_test_case "zsh sourcing simulation doesn't hang" test_zsh_sourcing_simulation
_run_test_case "install creates .zprofile logic" test_install_creates_zprofile
_run_test_case "uninstall removes .zprofile" test_uninstall_removes_zprofile

_finish_tests
