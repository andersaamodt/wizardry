#!/bin/sh
# Test coverage for open-teletype spell:
# - Shows usage with --help
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
  _run_spell "spells/translocation/open-teletype" --help
  _assert_success || return 1
  _assert_output_contains "Usage: open-teletype" || return 1
}

test_requires_torify() {
  stubdir=$(_make_tempdir)/bin
  mkdir -p "$stubdir"
  # Provide basic utilities but not torify
  for util in sh env printf; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done
  PATH="$WIZARDRY_CANTRIPS_PATH:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$stubdir" _run_spell "spells/translocation/open-teletype"
  _assert_failure || return 1
  _assert_error_contains "torify (tor) not found" || return 1
}

test_requires_mud_player() {
  stubdir=$(_make_tempdir)/bin
  mkdir -p "$stubdir"
  # Create stub torify
  cat > "$stubdir/torify" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stubdir/torify"
  for util in sh env printf; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done
  # Run without MUD_PLAYER set
  MUD_PLAYER="" PATH="$WIZARDRY_CANTRIPS_PATH:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$stubdir" _run_spell "spells/translocation/open-teletype"
  _assert_failure || return 1
  _assert_error_contains "MUD_PLAYER" || return 1
}

_run_test_case "open-teletype shows usage text" test_help
_run_test_case "open-teletype requires torify" test_requires_torify
_run_test_case "open-teletype requires MUD_PLAYER" test_requires_mud_player

_finish_tests
