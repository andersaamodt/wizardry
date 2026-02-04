#!/bin/sh
# Integration test for cd-listen functionality with relative paths

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that cd with relative path triggers listen and sees messages
test_cd_listen_relative_path() {
  tmpdir=$(make_tempdir)
  testdir="$tmpdir/.wizardry"
  mkdir -p "$testdir"
  
  # Create a test shell script that simulates the cd-listen workflow
  cat > "$tmpdir/test-workflow.sh" << 'TESTSCRIPT'
#!/bin/sh

# Add spells to PATH
export PATH="WIZARDRY_DIR/spells/mud:WIZARDRY_DIR/spells/.imps/sys:WIZARDRY_DIR/spells/.imps/out:WIZARDRY_DIR/spells/.arcana/mud:$PATH"
export SPELLBOOK_DIR="TMPDIR"
export MUD_PLAYER="TestUser"

# Enable cd-listen
mkdir -p "$SPELLBOOK_DIR"
echo "cd-listen=1" > "$SPELLBOOK_DIR/.mud"

# Source the cd-hook to set up the cd function
. WIZARDRY_DIR/spells/.arcana/mud/load-cd-hook

# Start from the temp directory
cd TMPDIR || exit 1

# Now cd using relative path (the problematic case)
echo "About to cd .wizardry from $(pwd)"
echo "DEBUG: cd-listen config value before cd:"
grep "^cd-listen=" "$SPELLBOOK_DIR/.mud" || echo "No cd-listen config"
cd .wizardry || exit 1
echo "After cd, pwd is: $(pwd)"
echo "DEBUG: Checking if listen command exists:"
command -v listen && echo "listen found" || echo "listen NOT found"

# Give listen a moment to start
sleep 2

# Check if listener is running
listener_count=$(pgrep -f "tail -f.*\.wizardry/\.log" 2>/dev/null | wc -l)
echo "Listener count: $listener_count"
if [ "$listener_count" -eq 0 ]; then
  echo "ERROR: Listener not started after cd .wizardry"
  echo "Contents of .log file:"
  ls -la .log 2>&1 || echo "No .log file"
  exit 1
fi

# Send a message
echo "About to say test message"
say "test message" || exit 1
echo "Say command completed"

# Give it a moment to appear
sleep 1

# Check if the message is in the log
if [ -f .log ]; then
  echo "Log file contents:"
  cat .log
  if grep -q "test message" .log; then
    echo "SUCCESS: cd-listen with relative path works"
    exit 0
  else
    echo "ERROR: Message not found in .log"
    exit 1
  fi
else
  echo "ERROR: .log file doesn't exist"
  exit 1
fi
TESTSCRIPT

  # Replace placeholders
  sed "s|WIZARDRY_DIR|$test_root|g" "$tmpdir/test-workflow.sh" | sed "s|TMPDIR|$tmpdir|g" > "$tmpdir/final-test.sh"
  chmod +x "$tmpdir/final-test.sh"
  
  # Run the test workflow
  output=$("$tmpdir/final-test.sh" 2>&1)
  exit_code=$?
  
  # Always show output for debugging
  echo "$output"
  
  # Clean up any tail processes - get PIDs and kill them
  tail_pids=$(pgrep -f "tail -f.*$tmpdir" 2>/dev/null || true)
  if [ -n "$tail_pids" ]; then
    for pid in $tail_pids; do
      kill "$pid" 2>/dev/null || true
    done
  fi
  
  # Check result
  if [ $exit_code -ne 0 ]; then
    return 1
  fi
  
  echo "$output" | grep -q "SUCCESS" || return 1
}

run_test_case "cd-listen works with relative path (cd .wizardry)" test_cd_listen_relative_path

finish_tests
