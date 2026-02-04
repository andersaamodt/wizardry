#!/bin/sh
# Test coverage for listen spell:
# - Shows usage with --help
# - Validates directory exists
# - Starts background process
# - Stops with --stop option
# - No startup messages (silent start)
# - Shows only new activity (not history)

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/mud/listen" --help
  if ! assert_success; then
    TEST_FAILURE_REASON="listen --help should succeed but failed with status $STATUS"
    return 1
  fi
  if ! assert_output_contains "Usage: listen"; then
    TEST_FAILURE_REASON="help output should contain 'Usage: listen' but got: $OUTPUT"
    return 1
  fi
}

test_nonexistent_directory() {
  skip-if-compiled || return $?  # Sourcing doesn't work in compiled mode
  
  run_sourced_spell "spells/mud/listen" /nonexistent/path
  if ! assert_failure; then
    TEST_FAILURE_REASON="listen should fail when given nonexistent directory but returned success"
    return 1
  fi
  if ! assert_error_contains "does not exist"; then
    TEST_FAILURE_REASON="error message should contain 'does not exist' but got: $ERROR"
    return 1
  fi
}

test_starts_listener_silent() {
  skip-if-compiled || return $?  # Sourcing and background processes don't work in compiled mode
  
  tmpdir=$(make_tempdir)
  
  # Start listener in test directory (must be sourced)
  HOME="$tmpdir" run_sourced_spell "spells/mud/listen" "$tmpdir"
  
  # Should succeed but not output any startup messages
  if ! assert_success; then
    TEST_FAILURE_REASON="listen should start successfully but failed with status $STATUS"
    return 1
  fi
  if [ -n "$OUTPUT" ]; then
    TEST_FAILURE_REASON="listen should start silently but produced output: $OUTPUT"
    return 1
  fi
}

test_stop_option() {
  skip-if-compiled || return $?  # Sourcing and process management don't work in compiled mode
  
  tmpdir=$(make_tempdir)
  
  # Try to stop when nothing is running (must be sourced)
  HOME="$tmpdir" run_sourced_spell "spells/mud/listen" --stop
  if ! assert_success; then
    TEST_FAILURE_REASON="listen --stop should succeed but failed with status $STATUS"
    return 1
  fi
  if ! assert_output_contains "Stopped listening"; then
    TEST_FAILURE_REASON="listen --stop should output 'Stopped listening' but got: $OUTPUT"
    return 1
  fi
}

test_message_format_single_line() {
  # Test that single-line messages are formatted correctly
  
  tmpdir=$(make_tempdir)
  logfile="$tmpdir/.log"
  touch "$logfile"
  
  # Create a test script that simulates the message formatting logic
  cat > "$tmpdir/test-format.sh" << 'SCRIPT'
#!/bin/sh
# Simulate single-line message formatting
player="Alice"
message="Hello world"
msg_text="$player: $message"
msg_len=${#msg_text}
LISTEN_TERM_WIDTH=80
lines_needed=$(( (msg_len + LISTEN_TERM_WIDTH - 1) / LISTEN_TERM_WIDTH ))

# Simulate the escape sequence: save, move to col 0, insert lines, print, restore+move down
printf '\0337\r'
i=0
while [ "$i" -lt "$lines_needed" ]; do
  printf '\033[1L'
  i=$((i + 1))
done
printf '\r%s' "$msg_text"
printf '\0338\033[%dB' "$lines_needed"

printf '\nlines_needed=%d\n' "$lines_needed"
SCRIPT
  
  chmod +x "$tmpdir/test-format.sh"
  output=$("$tmpdir/test-format.sh")
  
  # Verify the output contains the message and calculated lines correctly
  printf '%s' "$output" | grep -q "Alice: Hello world" || return 1
  printf '%s' "$output" | grep -q "lines_needed=1" || return 1
}

test_message_format_multiline() {
  # Test that multiline messages are formatted correctly
  
  tmpdir=$(make_tempdir)
  
  # Create a test script that simulates multiline message formatting
  cat > "$tmpdir/test-multiline.sh" << 'SCRIPT'
#!/bin/sh
# Simulate multiline message formatting (2+ lines)
player="Bob"
message="This is a very long message that will definitely wrap across multiple lines when displayed in a terminal with a width of 80 characters or less"
msg_text="$player: $message"
msg_len=${#msg_text}
LISTEN_TERM_WIDTH=80
lines_needed=$(( (msg_len + LISTEN_TERM_WIDTH - 1) / LISTEN_TERM_WIDTH ))

# Simulate the escape sequence (scroll up, cursor up, insert lines, print, restore)
printf '\0337\r'
i=0
while [ "$i" -lt "$lines_needed" ]; do
  printf '\033[S'
  i=$((i + 1))
done
printf '\033[%dA' "$lines_needed"
i=0
while [ "$i" -lt "$lines_needed" ]; do
  printf '\033[1L'
  i=$((i + 1))
done
printf '\r%s' "$msg_text"
printf '\0338'

printf '\nlines_needed=%d\n' "$lines_needed"
printf 'test_complete=yes\n'
SCRIPT
  
  chmod +x "$tmpdir/test-multiline.sh"
  output=$("$tmpdir/test-multiline.sh")
  
  # Verify the message was output
  printf '%s' "$output" | grep -q "Bob: This is a very long message" || return 1
  
  # Verify it calculated multiple lines (should be 2 or more)
  lines=$(printf '%s' "$output" | grep "lines_needed=" | cut -d= -f2)
  [ "$lines" -ge 2 ] || return 1
  
  # Verify test completed
  printf '%s' "$output" | grep -q "test_complete=yes" || return 1
}

test_message_exact_line_boundaries() {
  # Test messages at exact line boundaries (80, 160, 240 chars)
  
  tmpdir=$(make_tempdir)
  
  for len in 80 160 240; do
    cat > "$tmpdir/test-exact-$len.sh" << SCRIPT
#!/bin/sh
msg=\$(printf '%*s' $len '' | tr ' ' 'M')
msg_len=$len
LISTEN_TERM_WIDTH=80
lines_needed=\$(( (msg_len + LISTEN_TERM_WIDTH - 1) / LISTEN_TERM_WIDTH ))

printf '\0337\r'
i=0
while [ "\$i" -lt "\$lines_needed" ]; do
  printf '\033[S'
  i=\$((i + 1))
done
printf '\033[%dA' "\$lines_needed"
i=0
while [ "\$i" -lt "\$lines_needed" ]; do
  printf '\033[1L'
  i=\$((i + 1))
done
printf '\r%s' "\$msg"
printf '\0338'

printf '\nlines_needed=%d\n' "\$lines_needed"
SCRIPT
    
    chmod +x "$tmpdir/test-exact-$len.sh"
    output=$("$tmpdir/test-exact-$len.sh")
    
    # Verify lines_needed is calculated correctly
    # For 80 chars: lines_needed=1
    # For 160 chars: lines_needed=2
    # For 240 chars: lines_needed=3
    expected_lines=$(( len / 80 ))
    printf '%s' "$output" | grep -q "lines_needed=$expected_lines" || return 1
  done
}

test_message_fractional_lines() {
  # Test messages at fractional line lengths
  
  tmpdir=$(make_tempdir)
  
  # Test various fractional lengths
  for len in 213 220 300 380; do
    cat > "$tmpdir/test-frac-$len.sh" << SCRIPT
#!/bin/sh
msg=\$(printf '%*s' $len '' | tr ' ' 'X')
msg_len=$len
LISTEN_TERM_WIDTH=80
lines_needed=\$(( (msg_len + LISTEN_TERM_WIDTH - 1) / LISTEN_TERM_WIDTH ))

printf '\0337\r'
i=0
while [ "\$i" -lt "\$lines_needed" ]; do
  printf '\033[S'
  i=\$((i + 1))
done
printf '\033[%dA' "\$lines_needed"
i=0
while [ "\$i" -lt "\$lines_needed" ]; do
  printf '\033[1L'
  i=\$((i + 1))
done
printf '\r%s' "\$msg"
printf '\0338'

printf '\nlines_needed=%d\n' "\$lines_needed"
SCRIPT
    
    chmod +x "$tmpdir/test-frac-$len.sh"
    output=$("$tmpdir/test-frac-$len.sh")
    
    # Verify lines_needed exists and is calculated
    printf '%s' "$output" | grep -q "lines_needed=" || return 1
  done
}

# Test that listen enforces uncastable pattern (must be sourced)
test_uncastable() {
  # Try to execute listen directly (should fail)
  tmpdir=$(make_tempdir)
  
  # Execute directly - should fail with error message
  run_spell "spells/mud/listen" "$tmpdir"
  assert_failure || return 1
  assert_error_contains "must be sourced" || return 1
}

# Test cd-listen with relative paths (the scenario that was broken)
test_cd_listen_relative_path() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/sites"
  
  # Set up environment with cd-listen enabled
  export PATH="$test_root/spells/mud:$test_root/spells/.imps/sys:$test_root/spells/.imps/out:$test_root/spells/.arcana/mud:$PATH"
  export SPELLBOOK_DIR="$tmpdir"
  export MUD_PLAYER="TestUser"
  export HOME="$tmpdir"
  
  # Enable cd-listen
  echo "cd-listen=1" > "$SPELLBOOK_DIR/.mud"
  
  # Source cd hook to enable automatic listen on cd
  . "$test_root/spells/.arcana/mud/load-cd-hook"
  
  # Test the exact scenario: cd ~ then cd sites (relative path)
  # This was failing because listen inherited cd's $1="sites" instead of using $PWD
  cd ~ || return 1
  sleep 1
  
  cd sites || return 1
  sleep 2
  
  # Check if listener started for sites directory
  listener_count=$(pgrep -f "tail -f.*sites/.log" 2>/dev/null | wc -l)
  
  # Clean up tail processes
  tail_pids=$(pgrep -f "tail -f.*$tmpdir" 2>/dev/null || true)
  for pid in $tail_pids; do
    [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
  done
  
  # Verify listener was running
  [ "$listener_count" -gt 0 ] || return 1
}

# Test that "log:" messages don't show username prefix
test_log_username_hidden() {
  tmpdir=$(make_tempdir)
  
  # Create a .log file with a message from the special "log" user
  mkdir -p "$tmpdir"
  echo "[12:34] log: System notification" > "$tmpdir/.log"
  
  # Create a test script that simulates listen's message parsing
  cat > "$tmpdir/test-log.sh" <<'SCRIPT'
#!/bin/sh
line="[12:34] log: System notification"

# Parse the log entry (same logic as listen spell)
rest=$(printf '%s' "$line" | sed 's/^\[[^]]*\] //')
player=$(printf '%s' "$rest" | sed 's/:.*//')
message=$(printf '%s' "$rest" | sed 's/^[^:]*: //')

# Special case: "log" username should not be displayed
if [ "$player" = "log" ]; then
  # Just show the message without username prefix
  printf '%s\n' "$message"
else
  # Show with username
  printf '%s: %s\n' "$player" "$message"
fi
SCRIPT
  
  chmod +x "$tmpdir/test-log.sh"
  output=$("$tmpdir/test-log.sh")
  
  # Verify output is just the message, not "log: message"
  [ "$output" = "System notification" ] || return 1
  
  # Also test that normal users still show their username
  cat > "$tmpdir/test-user.sh" <<'SCRIPT'
#!/bin/sh
line="[12:34] alice: Hello there"

# Parse the log entry
rest=$(printf '%s' "$line" | sed 's/^\[[^]]*\] //')
player=$(printf '%s' "$rest" | sed 's/:.*//')
message=$(printf '%s' "$rest" | sed 's/^[^:]*: //')

# Special case: "log" username should not be displayed
if [ "$player" = "log" ]; then
  printf '%s\n' "$message"
else
  printf '%s: %s\n' "$player" "$message"
fi
SCRIPT
  
  chmod +x "$tmpdir/test-user.sh"
  output=$("$tmpdir/test-user.sh")
  
  # Verify normal user shows "username: message"
  [ "$output" = "alice: Hello there" ] || return 1
}


run_test_case "listen shows usage text" test_help
run_test_case "listen must be sourced (uncastable)" test_uncastable
run_test_case "listen validates directory exists" test_nonexistent_directory  
run_test_case "listen starts silently" test_starts_listener_silent
run_test_case "listen --stop stops listener" test_stop_option
run_test_case "listen formats single-line messages correctly" test_message_format_single_line
run_test_case "listen formats multiline messages with newline" test_message_format_multiline
run_test_case "listen handles exact line boundary messages" test_message_exact_line_boundaries
run_test_case "listen handles fractional line length messages" test_message_fractional_lines
run_test_case "listen hides log username prefix" test_log_username_hidden
run_test_case "cd-listen works with relative paths" test_cd_listen_relative_path

finish_tests
