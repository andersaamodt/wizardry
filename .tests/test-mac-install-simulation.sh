#!/bin/sh
# Test simulating Mac install scenario
# This test validates that after install, menu can be run immediately

# Locate the repository root so we can source test-bootstrap
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_install_sources_invoke_wizardry() {
  # Simulate what happens when install script sources invoke-wizardry
  tmp=$(_make_tempdir)
  test_script="$tmp/test-install.sh"
  
  cat >"$test_script" <<'EOF'
#!/bin/sh
# Simulate install script sourcing invoke-wizardry
export WIZARDRY_DIR="$1"
INVOKE_WIZARDRY="$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry"

# Source invoke-wizardry like the install script does
sourcing_succeeded=0
if [ -f "$INVOKE_WIZARDRY" ] && . "$INVOKE_WIZARDRY" 2>/dev/null; then
  sourcing_succeeded=1
fi

if [ "$sourcing_succeeded" -eq 1 ]; then
  echo "Sourcing succeeded"
  # Try to run menu --help
  if command -v menu >/dev/null 2>&1; then
    echo "menu is available"
  else
    echo "menu is NOT available"
    exit 1
  fi
else
  echo "Sourcing failed"
  exit 1
fi
EOF
  
  chmod +x "$test_script"
  
  # Run the test script
  _run_cmd sh "$test_script" "$ROOT_DIR"
  _assert_success || return 1
  _assert_output_contains "Sourcing succeeded" || return 1
  _assert_output_contains "menu is available" || return 1
}

test_rc_file_sources_invoke_wizardry() {
  # Simulate what happens when a new shell sources the rc file
  tmp=$(_make_tempdir)
  rc_file="$tmp/.bashrc"
  test_script="$tmp/test-rc.sh"
  
  # Create a fake rc file with invoke-wizardry source line
  cat >"$rc_file" <<EOF
# Fake bashrc
export WIZARDRY_DIR="\$1"
. "\$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" # wizardry: wizardry-init
EOF
  
  # Create a script that sources the rc file then runs menu
  cat >"$test_script" <<'EOF'
#!/bin/sh
export HOME="$2"
. "$2/.bashrc" "$1" >/dev/null 2>&1 || exit 1
# Try to run menu --help
if command -v menu >/dev/null 2>&1; then
  echo "menu is available after sourcing rc"
else
  echo "menu is NOT available after sourcing rc"
  exit 1
fi
EOF
  
  chmod +x "$test_script"
  
  # Run the test script
  _run_cmd sh "$test_script" "$ROOT_DIR" "$tmp"
  _assert_success || return 1
  _assert_output_contains "menu is available after sourcing rc" || return 1
}

_run_test_case "install sources invoke-wizardry successfully" test_install_sources_invoke_wizardry
_run_test_case "rc file sources invoke-wizardry successfully" test_rc_file_sources_invoke_wizardry
_finish_tests
