#!/bin/sh
# Comprehensive end-to-end test for Mac installation scenario
# Tests the full install -> use -> uninstall cycle

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: Full Mac installation cycle - zsh with .zprofile
test_full_mac_zsh_cycle() {
  tmpdir=$(_make_tempdir)
  export HOME="$tmpdir"
  export WIZARDRY_DIR="$ROOT_DIR"
  
  # Step 1: Simulate install adding to .zshrc
  test_zshrc="$HOME/.zshrc"
  cat > "$test_zshrc" << 'EOF'
# Existing user config
export PATH="/usr/local/bin:$PATH"
export LANG="en_US.UTF-8"
EOF
  
  # Add wizardry line (simulating install)
  cat >> "$test_zshrc" << EOF
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" # wizardry: wizardry-init
EOF
  
  # Step 2: Install creates .zprofile
  test_zprofile="$HOME/.zprofile"
  cat > "$test_zprofile" << 'EOF'
# Source .zshrc if it exists (added by wizardry installer)
# This ensures zsh login shells get the same configuration as interactive shells
if [ -f ~/.zshrc ]; then
        . ~/.zshrc
fi
EOF
  
  # Step 3: Simulate opening a new terminal (login shell sources .zprofile)
  cat > "$HOME/simulate-login.sh" << 'SIMLOGIN'
#!/bin/sh
# Source .zprofile like a login shell would
. "$HOME/.zprofile" 2>/dev/null

# Check that wizardry is available
if [ -n "${WIZARDRY_DIR-}" ]; then
  printf 'wizardry_loaded=yes\n'
fi

# Check that menu is available
if command -v menu >/dev/null 2>&1; then
  printf 'menu_available=yes\n'
fi

printf 'login_complete=yes\n'
SIMLOGIN
  chmod +x "$HOME/simulate-login.sh"
  
  # Run the login simulation
  _run_cmd "$HOME/simulate-login.sh"
  _assert_success || return 1
  _assert_output_contains "wizardry_loaded=yes" || return 1
  _assert_output_contains "menu_available=yes" || return 1
  _assert_output_contains "login_complete=yes" || return 1
  
  # Step 4: Simulate uninstall
  cat > "$HOME/simulate-uninstall.sh" << 'SIMUNINSTALL'
#!/bin/sh
set -eu

RC_FILE="$HOME/.zshrc"
PROFILE_FILE="$HOME/.zprofile"

# Remove from RC file
if [ -f "$RC_FILE" ]; then
  tmp_file="${RC_FILE}.wizardry.$$"
  if grep -v '# wizardry:' "$RC_FILE" > "$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$RC_FILE"
  else
    rm -f "$tmp_file"
  fi
fi

# Remove from profile file using awk
if [ -n "$PROFILE_FILE" ] && [ -f "$PROFILE_FILE" ]; then
  tmp_file="${PROFILE_FILE}.wizardry.$$"
  
  awk '
  /^# Source \..*rc if it exists \(added by wizardry installer\)$/ { skip = 1; next }
  skip == 1 && /^fi$/ { skip = 0; next }
  skip == 0 { print }
  ' "$PROFILE_FILE" > "$tmp_file" 2>/dev/null || true
  
  if [ -f "$tmp_file" ] && ! cmp -s "$PROFILE_FILE" "$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$PROFILE_FILE"
  else
    rm -f "$tmp_file"
  fi
  
  # Delete if empty
  if [ -f "$PROFILE_FILE" ]; then
    if ! grep -qE '^[^#[:space:]]' "$PROFILE_FILE" 2>/dev/null; then
      if [ ! -s "$PROFILE_FILE" ] || ! grep -qE '^[^#[:space:]]' "$PROFILE_FILE" 2>/dev/null; then
        rm -f "$PROFILE_FILE"
      fi
    fi
  fi
fi

printf 'uninstall_complete=yes\n'
SIMUNINSTALL
  chmod +x "$HOME/simulate-uninstall.sh"
  
  _run_cmd "$HOME/simulate-uninstall.sh"
  _assert_success || return 1
  _assert_output_contains "uninstall_complete=yes" || return 1
  
  # Step 5: Verify cleanup
  # .zshrc should exist but without wizardry line
  if [ ! -f "$test_zshrc" ]; then
    TEST_FAILURE_REASON=".zshrc was deleted (should only be modified)"
    return 1
  fi
  
  if grep -q 'wizardry:' "$test_zshrc"; then
    TEST_FAILURE_REASON="wizardry marker still in .zshrc after uninstall"
    return 1
  fi
  
  # Original .zshrc content should still be there
  if ! grep -q 'export PATH=' "$test_zshrc"; then
    TEST_FAILURE_REASON="original .zshrc content was removed"
    return 1
  fi
  
  # .zprofile should be deleted (it only had wizardry content)
  if [ -f "$test_zprofile" ]; then
    TEST_FAILURE_REASON=".zprofile still exists after uninstall (should be deleted)"
    return 1
  fi
}

# Test: Full Mac installation cycle - bash with .bash_profile
test_full_mac_bash_cycle() {
  tmpdir=$(_make_tempdir)
  export HOME="$tmpdir"
  export WIZARDRY_DIR="$ROOT_DIR"
  
  # Step 1: Simulate install adding to .bashrc
  test_bashrc="$HOME/.bashrc"
  cat > "$test_bashrc" << 'EOF'
# Existing user config
export PATH="/usr/local/bin:$PATH"
EOF
  
  # Add wizardry line
  cat >> "$test_bashrc" << EOF
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" # wizardry: wizardry-init
EOF
  
  # Step 2: Install creates .bash_profile
  test_bash_profile="$HOME/.bash_profile"
  cat > "$test_bash_profile" << 'EOF'
# Source .bashrc if it exists (added by wizardry installer)
# This ensures bash login shells (like those opened by Terminal.app on macOS)
# get the same configuration as interactive shells
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi
EOF
  
  # Step 3: Simulate uninstall (same logic as zsh)
  cat > "$HOME/simulate-uninstall.sh" << 'SIMUNINSTALL'
#!/bin/sh
set -eu

RC_FILE="$HOME/.bashrc"
PROFILE_FILE="$HOME/.bash_profile"

# Remove from RC file
if [ -f "$RC_FILE" ]; then
  tmp_file="${RC_FILE}.wizardry.$$"
  if grep -v '# wizardry:' "$RC_FILE" > "$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$RC_FILE"
  else
    rm -f "$tmp_file"
  fi
fi

# Remove from profile file
if [ -n "$PROFILE_FILE" ] && [ -f "$PROFILE_FILE" ]; then
  tmp_file="${PROFILE_FILE}.wizardry.$$"
  
  awk '
  /^# Source \..*rc if it exists \(added by wizardry installer\)$/ { skip = 1; next }
  skip == 1 && /^fi$/ { skip = 0; next }
  skip == 0 { print }
  ' "$PROFILE_FILE" > "$tmp_file" 2>/dev/null || true
  
  if [ -f "$tmp_file" ] && ! cmp -s "$PROFILE_FILE" "$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$PROFILE_FILE"
  else
    rm -f "$tmp_file"
  fi
  
  # Delete if empty
  if [ -f "$PROFILE_FILE" ]; then
    if ! grep -qE '^[^#[:space:]]' "$PROFILE_FILE" 2>/dev/null; then
      if [ ! -s "$PROFILE_FILE" ] || ! grep -qE '^[^#[:space:]]' "$PROFILE_FILE" 2>/dev/null; then
        rm -f "$PROFILE_FILE"
      fi
    fi
  fi
fi

printf 'uninstall_complete=yes\n'
SIMUNINSTALL
  chmod +x "$HOME/simulate-uninstall.sh"
  
  _run_cmd "$HOME/simulate-uninstall.sh"
  _assert_success || return 1
  
  # Verify .bash_profile was deleted
  if [ -f "$test_bash_profile" ]; then
    TEST_FAILURE_REASON=".bash_profile still exists after uninstall"
    return 1
  fi
  
  # Verify .bashrc still exists without wizardry
  if ! grep -q 'export PATH=' "$test_bashrc"; then
    TEST_FAILURE_REASON="original .bashrc content was removed"
    return 1
  fi
  
  if grep -q 'wizardry:' "$test_bashrc"; then
    TEST_FAILURE_REASON="wizardry marker still in .bashrc"
    return 1
  fi
}

_run_test_case "full Mac zsh installation cycle" test_full_mac_zsh_cycle
_run_test_case "full Mac bash installation cycle" test_full_mac_bash_cycle

_finish_tests
