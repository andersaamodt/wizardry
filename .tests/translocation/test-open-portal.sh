#!/bin/sh
# Test coverage for open-portal spell:
# - Shows usage with --help
# - Requires sshfs command
# - Requires torify command
# - Requires MUD_PLAYER environment variable

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

test_requires_mud_player() {
  stubdir=$(make_tempdir)/bin
  mkdir -p "$stubdir"
  # Create stub sshfs and torify
  cat > "$stubdir/sshfs" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat > "$stubdir/torify" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stubdir/sshfs" "$stubdir/torify"
  for util in sh env printf mkdir; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done
  # Run without MUD_PLAYER set
  MUD_PLAYER="" PATH="$stubdir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin" run_spell "spells/translocation/open-portal"
  assert_failure || return 1
  assert_error_contains "MUD_PLAYER" || return 1
}

run_test_case "open-portal shows usage text" test_help
run_test_case "open-portal requires sshfs" test_requires_sshfs
run_test_case "open-portal requires MUD_PLAYER" test_requires_mud_player


# Test via source-then-invoke pattern  

finish_tests
