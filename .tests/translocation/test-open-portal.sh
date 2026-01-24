#!/bin/sh
# Test coverage for open-portal spell:
# - Shows usage with --help
# - Requires sshfs command
# - Optionally requires torify for --tor mode
# - Handles server:path syntax

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/translocation/open-portal" --help
  assert_success || return 1
  assert_output_contains "Usage: open-portal" || return 1
}

test_requires_sshfs() {
  stubdir=$(make_tempdir)/bin
  mkdir -p "$stubdir"
  # Provide basic utilities but not sshfs
  for util in sh env printf; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done
  PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$stubdir:/bin:/usr/bin" run_spell "spells/translocation/open-portal"
  assert_failure || return 1
  assert_error_contains "sshfs not found" || return 1
}

test_requires_torify_for_tor_mode() {
  stubdir=$(make_tempdir)/bin
  mkdir -p "$stubdir"
  # Create stub sshfs but not torify
  cat > "$stubdir/sshfs" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stubdir/sshfs"
  for util in sh env printf mkdir; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done
  # Run with --tor flag but no torify available
  PATH="$stubdir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin" run_spell "spells/translocation/open-portal" --tor
  assert_failure || return 1
  assert_error_contains "torify" || return 1
}

test_requires_arguments() {
  stubdir=$(make_tempdir)/bin
  mkdir -p "$stubdir"
  # Create stub sshfs
  cat > "$stubdir/sshfs" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stubdir/sshfs"
  for util in sh env printf mkdir; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done
  # Run without arguments
  PATH="$stubdir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin" run_spell "spells/translocation/open-portal"
  assert_failure || return 1
  assert_error_contains "requires at least one argument" || return 1
}

run_test_case "open-portal shows usage text" test_help
run_test_case "open-portal requires sshfs" test_requires_sshfs
run_test_case "open-portal --tor requires torify" test_requires_torify_for_tor_mode
run_test_case "open-portal requires arguments" test_requires_arguments


# Test via source-then-invoke pattern  

finish_tests
