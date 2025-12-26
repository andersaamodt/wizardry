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
  _run_spell "spells/translocation/open-portal" --help
  _assert_success || return 1
  _assert_output_contains "Usage: open-portal" || return 1
}

test_requires_sshfs() {
  stubdir=$(_make_tempdir)/bin
  mkdir -p "$stubdir"
  # Provide basic utilities but not sshfs
  for util in sh env printf; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done
  PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$stubdir" _run_spell "spells/translocation/open-portal"
  _assert_failure || return 1
  _assert_error_contains "sshfs not found" || return 1
}

test_requires_mud_player() {
  stubdir=$(_make_tempdir)/bin
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
  MUD_PLAYER="" PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$stubdir" _run_spell "spells/translocation/open-portal"
  _assert_failure || return 1
  _assert_error_contains "MUD_PLAYER" || return 1
}

_run_test_case "open-portal shows usage text" test_help
_run_test_case "open-portal requires sshfs" test_requires_sshfs
_run_test_case "open-portal requires MUD_PLAYER" test_requires_mud_player


# Test via source-then-invoke pattern  
open_portal_help_via_sourcing() {
  _run_sourced_spell open-portal --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "open-portal works via source-then-invoke" open_portal_help_via_sourcing
_finish_tests
