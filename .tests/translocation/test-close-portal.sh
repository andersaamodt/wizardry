#!/bin/sh
# Test coverage for close-portal spell:
# - Shows usage with --help
# - Lists portals when no argument given
# - Validates mount point exists

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

run_test_case "close-portal shows usage text" test_help
run_test_case "close-portal lists portals when no args" test_no_args_lists_portals
run_test_case "close-portal fails on nonexistent mount point" test_nonexistent_mount_point

finish_tests
