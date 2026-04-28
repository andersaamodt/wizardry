#!/bin/sh
# Test coverage for close-portal spell:
# - Shows usage with --help
# - Lists portals when no argument given
# - Validates mount point exists
# - Rejects extra operands before unmounting
# - Handles mount points containing grep metacharacters

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/translocation/close-portal" --help
  assert_success || return 1
  assert_output_contains "Usage: close-portal" || return 1
}

test_no_args_lists_portals() {
  # When no args, should list portals or say none found
  run_spell "spells/translocation/close-portal"
  assert_success || return 1
  # Should output something (either portals or "none found")
  [ -n "$OUTPUT" ] || return 1
}

test_nonexistent_mount_point() {
  stubdir=$(make_tempdir)/bin
  mkdir -p "$stubdir"
  # Create stub mount and fusermount
  cat > "$stubdir/mount" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat > "$stubdir/fusermount" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stubdir/mount" "$stubdir/fusermount"
  for util in sh env printf; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done
  
  # Try to close a nonexistent mount point
  PATH="$stubdir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin" run_spell "spells/translocation/close-portal" /nonexistent/path
  assert_failure || return 1
  assert_error_contains "does not exist" || return 1
}

test_rejects_extra_operands_before_unmounting() {
  tmpdir=$(make_tempdir)
  mount_point=$tmpdir/portal
  stubdir=$tmpdir/bin
  log=$tmpdir/fusermount.log
  mkdir -p "$mount_point" "$stubdir"
  cat > "$stubdir/mount" <<EOF
#!/bin/sh
printf '%s\n' "remote on $mount_point type fuse.sshfs (rw)"
EOF
  cat > "$stubdir/fusermount" <<EOF
#!/bin/sh
printf '%s\n' "fusermount \$*" >> "$log"
exit 0
EOF
  chmod +x "$stubdir/mount" "$stubdir/fusermount"
  for util in sh env printf grep; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done

  PATH="$stubdir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin" run_spell "spells/translocation/close-portal" "$mount_point" extra
  assert_failure || return 1
  assert_error_contains "at most one" || return 1
  if [ -f "$log" ]; then
    TEST_FAILURE_REASON="close-portal unmounted after receiving extra operands"
    return 1
  fi
}

test_unmounts_mount_point_with_grep_metacharacters() {
  tmpdir=$(make_tempdir)
  mount_point=$tmpdir/'portal[1]'
  stubdir=$tmpdir/bin
  log=$tmpdir/fusermount.log
  mkdir -p "$mount_point" "$stubdir"
  cat > "$stubdir/mount" <<EOF
#!/bin/sh
printf '%s\n' "remote on $mount_point type fuse.sshfs (rw)"
EOF
  cat > "$stubdir/fusermount" <<EOF
#!/bin/sh
printf '%s\n' "fusermount \$*" >> "$log"
exit 0
EOF
  chmod +x "$stubdir/mount" "$stubdir/fusermount"
  for util in sh env printf grep; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done

  PATH="$stubdir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin" run_spell "spells/translocation/close-portal" "$mount_point"
  assert_success || return 1
  assert_file_contains "$log" "$mount_point" || return 1
}

run_test_case "close-portal shows usage text" test_help
run_test_case "close-portal lists portals when no args" test_no_args_lists_portals
run_test_case "close-portal fails on nonexistent mount point" test_nonexistent_mount_point
run_test_case "close-portal rejects extra operands before unmounting" test_rejects_extra_operands_before_unmounting
run_test_case "close-portal handles grep metacharacters in mount point" test_unmounts_mount_point_with_grep_metacharacters

finish_tests
