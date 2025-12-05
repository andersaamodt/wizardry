#!/bin/sh
# Test coverage for open-teletype spell:
# - Shows usage with --help
# - Requires torify command
# - Requires MUD_PLAYER environment variable

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_help() {
  run_spell "spells/translocation/open-teletype" --help
  assert_success || return 1
  assert_output_contains "Usage: open-teletype" || return 1
}

test_requires_torify() {
  stubdir=$(make_tempdir)/bin
  mkdir -p "$stubdir"
  # Provide basic utilities but not torify
  for util in sh env printf; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$stubdir" run_spell "spells/translocation/open-teletype"
  assert_failure || return 1
  assert_error_contains "torify (tor) not found" || return 1
}

test_requires_mud_player() {
  stubdir=$(make_tempdir)/bin
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
  MUD_PLAYER="" PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$stubdir" run_spell "spells/translocation/open-teletype"
  assert_failure || return 1
  assert_error_contains "MUD_PLAYER" || return 1
}

run_test_case "open-teletype shows usage text" test_help
run_test_case "open-teletype requires torify" test_requires_torify
run_test_case "open-teletype requires MUD_PLAYER" test_requires_mud_player

finish_tests
