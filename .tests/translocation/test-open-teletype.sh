#!/bin/sh
# Test coverage for open-teletype spell:
# - Shows usage with --help
# - Requires torify command
# - Requires MUD_PLAYER environment variable
# - Rejects extra operands before connecting

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

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
  PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$stubdir:/bin:/usr/bin" run_spell "spells/translocation/open-teletype"
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
  MUD_PLAYER="" PATH="$stubdir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin" run_spell "spells/translocation/open-teletype"
  assert_failure || return 1
  assert_error_contains "MUD_PLAYER" || return 1
}

test_rejects_extra_operands_before_connecting() {
  tmpdir=$(make_tempdir)
  stubdir=$tmpdir/bin
  home=$tmpdir/home
  log=$tmpdir/torify.log
  mkdir -p "$stubdir" "$home/.ssh"
  : > "$home/.ssh/test_player"
  cat > "$stubdir/torify" <<EOF
#!/bin/sh
printf '%s\n' "torify \$*" >> "$log"
exit 0
EOF
  chmod +x "$stubdir/torify"
  for util in sh env printf; do
    if command -v "$util" >/dev/null 2>&1; then
      ln -sf "$(command -v "$util")" "$stubdir/$util" 2>/dev/null || true
    fi
  done

  run_cmd env PATH="$stubdir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin" HOME="$home" MUD_PLAYER=test_player "$ROOT_DIR/spells/translocation/open-teletype" host.example user extra
  assert_failure || return 1
  assert_error_contains "at most two" || return 1
  if [ -f "$log" ]; then
    TEST_FAILURE_REASON="open-teletype connected after receiving extra operands"
    return 1
  fi
}

run_test_case "open-teletype shows usage text" test_help
run_test_case "open-teletype requires torify" test_requires_torify
run_test_case "open-teletype requires MUD_PLAYER" test_requires_mud_player
run_test_case "open-teletype rejects extra operands before connecting" test_rejects_extra_operands_before_connecting


# Test via source-then-invoke pattern  

finish_tests
