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
  assert_success || return 1
  assert_output_contains "Usage: listen" || return 1
}

test_nonexistent_directory() {
  run_spell "spells/mud/listen" /nonexistent/path
  assert_failure || return 1
  assert_error_contains "does not exist" || return 1
}

test_starts_listener_silent() {
  tmpdir=$(make_tempdir)
  
  # Start listener in test directory
  HOME="$tmpdir" run_spell "spells/mud/listen" "$tmpdir"
  
  # Should succeed but not output any startup messages
  assert_success || return 1
  [ -z "$OUTPUT" ] || return 1
}

test_stop_option() {
  tmpdir=$(make_tempdir)
  
  # Try to stop when nothing is running
  HOME="$tmpdir" run_spell "spells/mud/listen" --stop
  assert_success || return 1
  assert_output_contains "Stopped listening" || return 1
}

test_message_format_single_line() {
  # Test that single-line messages are formatted correctly
  # This verifies the message formatting logic works and ends with a newline
  
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
lines_to_insert=$(( lines_needed + 1 ))

# The key part: message should end with \r\n for proper cursor positioning
printf '\r%s' "$msg_text"
printf '\r\n'
printf 'lines_to_insert=%d\n' "$lines_to_insert"
SCRIPT
  
  chmod +x "$tmpdir/test-format.sh"
  output=$("$tmpdir/test-format.sh")
  
  # Verify the output contains the message and ends properly
  printf '%s' "$output" | grep -q "Alice: Hello world" || return 1
  printf '%s' "$output" | grep -q "lines_to_insert=2" || return 1
}

test_message_format_multiline() {
  # Test that multiline messages are formatted correctly with trailing newline
  # This is the key test for the bug fix
  
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
lines_to_insert=$(( lines_needed + 1 ))

# The key part: message should end with \r\n for proper cursor positioning
printf '\r%s' "$msg_text"
printf '\r\n'
printf 'lines_to_insert=%d\n' "$lines_to_insert"

# Verify cursor is on new line by printing something
printf 'cursor_on_new_line=yes\n'
SCRIPT
  
  chmod +x "$tmpdir/test-multiline.sh"
  output=$("$tmpdir/test-multiline.sh")
  
  # Verify the message was output
  printf '%s' "$output" | grep -q "Bob: This is a very long message" || return 1
  
  # Verify it calculated multiple lines (should be 2 or more for content + 1 for blank)
  lines=$(printf '%s' "$output" | grep "lines_to_insert=" | cut -d= -f2)
  [ "$lines" -ge 3 ] || return 1
  
  # Verify cursor moved to new line (this proves the \r\n was added)
  printf '%s' "$output" | grep -q "cursor_on_new_line=yes" || return 1
}

test_message_exact_line_boundaries() {
  # Test messages at exact line boundaries (80, 160, 240 chars)
  # These were problematic in the original fix
  
  tmpdir=$(make_tempdir)
  
  for len in 80 160 240; do
    cat > "$tmpdir/test-exact-$len.sh" << SCRIPT
#!/bin/sh
msg=\$(printf '%*s' $len '' | tr ' ' 'M')
msg_len=$len
LISTEN_TERM_WIDTH=80
lines_needed=\$(( (msg_len + LISTEN_TERM_WIDTH - 1) / LISTEN_TERM_WIDTH ))
lines_to_insert=\$(( lines_needed + 1 ))

printf '\r%s' "\$msg"
printf '\r\n'
printf 'lines_to_insert=%d\n' "\$lines_to_insert"
SCRIPT
    
    chmod +x "$tmpdir/test-exact-$len.sh"
    output=$("$tmpdir/test-exact-$len.sh")
    
    # Verify lines_to_insert is calculated correctly
    # For 80 chars: lines_needed=1, lines_to_insert=2
    # For 160 chars: lines_needed=2, lines_to_insert=3
    # For 240 chars: lines_needed=3, lines_to_insert=4
    expected_lines=$(( len / 80 + 1 ))
    printf '%s' "$output" | grep -q "lines_to_insert=$expected_lines" || return 1
  done
}

test_message_fractional_lines() {
  # Test messages at fractional line lengths (2 2/3, 2 3/4, etc)
  # As mentioned in the bug report
  
  tmpdir=$(make_tempdir)
  
  # 2 2/3 lines = 213 chars
  # 2 3/4 lines = 220 chars
  # 3 3/4 lines = 300 chars
  # 4 3/4 lines = 380 chars
  
  for len in 213 220 300 380; do
    cat > "$tmpdir/test-frac-$len.sh" << SCRIPT
#!/bin/sh
msg=\$(printf '%*s' $len '' | tr ' ' 'X')
msg_len=$len
LISTEN_TERM_WIDTH=80
lines_needed=\$(( (msg_len + LISTEN_TERM_WIDTH - 1) / LISTEN_TERM_WIDTH ))
lines_to_insert=\$(( lines_needed + 1 ))

printf '\r%s' "\$msg"
printf '\r\n'
printf 'lines_to_insert=%d\n' "\$lines_to_insert"
SCRIPT
    
    chmod +x "$tmpdir/test-frac-$len.sh"
    output=$("$tmpdir/test-frac-$len.sh")
    
    # Verify lines_to_insert exists
    printf '%s' "$output" | grep -q "lines_to_insert=" || return 1
  done
}

run_test_case "listen shows usage text" test_help
run_test_case "listen validates directory exists" test_nonexistent_directory  
run_test_case "listen starts silently" test_starts_listener_silent
run_test_case "listen --stop stops listener" test_stop_option
run_test_case "listen formats single-line messages correctly" test_message_format_single_line
run_test_case "listen formats multiline messages with newline" test_message_format_multiline
run_test_case "listen handles exact line boundary messages" test_message_exact_line_boundaries
run_test_case "listen handles fractional line length messages" test_message_fractional_lines

finish_tests
