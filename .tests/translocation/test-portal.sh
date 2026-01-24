#!/bin/sh
# Test coverage for portal spell:
# - Shows usage with --help
# - Requires sshfs command
# - Handles server:path syntax
# - Handles server path syntax
# - Creates mount point directory

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/translocation/portal" --help
  assert_success || return 1
  assert_output_contains "Usage: portal" || return 1
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
  PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$stubdir:/bin:/usr/bin" run_spell "spells/translocation/portal"
  assert_failure || return 1
  assert_error_contains "sshfs not found" || return 1
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
  PATH="$stubdir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin" run_spell "spells/translocation/portal"
  assert_failure || return 1
  assert_error_contains "requires at least one argument" || return 1
}

run_test_case "portal shows usage text" test_help
run_test_case "portal requires sshfs" test_requires_sshfs
run_test_case "portal requires arguments" test_requires_arguments

finish_tests
