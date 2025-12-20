#!/bin/sh
# Tests for the 'rc-migrate-marker' imp

# Locate the repository root so we can source test-bootstrap
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_rc_migrate_marker_converts_old_to_new_format() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  rc_file="$tmpdir/.testrc"
  
  # Create file with old format (marker on separate line)
  cat > "$rc_file" <<'EOF'
export PATH=/usr/bin
# wizardry: cd-hook
. "/path/to/cd"
echo "test"
EOF
  
  # Migrate
  result=$("$ROOT_DIR/spells/.imps/sys/rc-migrate-marker" cd-hook "$rc_file" '. "/path/to/cd"' 2>&1) || {
    TEST_FAILURE_REASON="rc-migrate-marker failed: $result"
    return 1
  }
  
  # Verify old format removed
  if grep -q "^# wizardry: cd-hook\$" "$rc_file"; then
    TEST_FAILURE_REASON="expected old format marker line to be removed"
    return 1
  fi
  
  # Verify new inline format added
  if ! grep -qF '. "/path/to/cd" # wizardry: cd-hook' "$rc_file"; then
    TEST_FAILURE_REASON="expected new inline format. Contents: $(cat "$rc_file")"
    return 1
  fi
  
  # Verify other content preserved
  if ! grep -q "export PATH=/usr/bin" "$rc_file"; then
    TEST_FAILURE_REASON="expected original content to be preserved"
    return 1
  fi
  if ! grep -q 'echo "test"' "$rc_file"; then
    TEST_FAILURE_REASON="expected original content to be preserved"
    return 1
  fi
  
  # Verify old command line removed (shouldn't have duplicate)
  count=$(grep -c '. "/path/to/cd"' "$rc_file" || printf '0')
  if [ "$count" -ne 1 ]; then
    TEST_FAILURE_REASON="expected exactly 1 occurrence of command, found $count"
    return 1
  fi
}

test_rc_migrate_marker_handles_already_migrated() {
  tmpdir=$(_make_tempdir)
  rc_file="$tmpdir/.testrc"
  
  # Create file with new inline format
  cat > "$rc_file" <<'EOF'
export PATH=/usr/bin
. "/path/to/cd" # wizardry: cd-hook
echo "test"
EOF
  
  initial_content=$(cat "$rc_file")
  
  # Run migration (should be no-op)
  "$ROOT_DIR/spells/.imps/sys/rc-migrate-marker" cd-hook "$rc_file" '. "/path/to/cd"'
  
  # Verify content unchanged
  current_content=$(cat "$rc_file")
  if [ "$current_content" != "$initial_content" ]; then
    TEST_FAILURE_REASON="expected content to remain unchanged when already in new format"
    return 1
  fi
}

test_rc_migrate_marker_handles_missing_file() {
  tmpdir=$(_make_tempdir)
  rc_file="$tmpdir/.nonexistent"
  
  # Should succeed (nothing to migrate)
  if ! "$ROOT_DIR/spells/.imps/sys/rc-migrate-marker" cd-hook "$rc_file" '. "/path/to/cd"' 2>/dev/null; then
    TEST_FAILURE_REASON="expected rc-migrate-marker to succeed on missing file"
    return 1
  fi
}

test_rc_migrate_marker_handles_no_old_format() {
  tmpdir=$(_make_tempdir)
  rc_file="$tmpdir/.testrc"
  
  # Create file without marker at all
  printf 'export PATH=/usr/bin\n' > "$rc_file"
  
  initial_content=$(cat "$rc_file")
  
  # Should succeed (nothing to migrate)
  if ! "$ROOT_DIR/spells/.imps/sys/rc-migrate-marker" cd-hook "$rc_file" '. "/path/to/cd"' 2>/dev/null; then
    TEST_FAILURE_REASON="expected rc-migrate-marker to succeed when no old format found"
    return 1
  fi
  
  # Verify content unchanged
  current_content=$(cat "$rc_file")
  if [ "$current_content" != "$initial_content" ]; then
    TEST_FAILURE_REASON="expected content to remain unchanged when no old format exists"
    return 1
  fi
}

_run_test_case "rc-migrate-marker converts old to new format" test_rc_migrate_marker_converts_old_to_new_format
_run_test_case "rc-migrate-marker handles already migrated" test_rc_migrate_marker_handles_already_migrated
_run_test_case "rc-migrate-marker handles missing file" test_rc_migrate_marker_handles_missing_file
_run_test_case "rc-migrate-marker handles no old format" test_rc_migrate_marker_handles_no_old_format

_finish_tests
