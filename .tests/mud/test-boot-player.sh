#!/bin/sh
# Test coverage for boot-player spell:
# - Shows usage with --help
# - Is POSIX compliant
# - Shows message when no players connected

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/mud/boot-player" --help
  assert_success || return 1
  assert_output_contains "Usage: boot-player" || return 1
}

test_help_h_flag() {
  run_spell "spells/mud/boot-player" -h
  assert_success || return 1
  assert_output_contains "Usage: boot-player" || return 1
}

test_has_strict_mode() {
  # Verify the spell uses strict mode
  grep -q "set -eu" "$ROOT_DIR/spells/mud/boot-player" || {
    TEST_FAILURE_REASON="spell does not use strict mode"
    return 1
  }
}

test_no_players_connected() {
  # Test when no players are connected (no sshfs mounts)
  tmp=$(make_tempdir)
  
  # Stub mount to return no sshfs mounts
  cat >"$tmp/mount" <<'SH'
#!/bin/sh
# Return some mounts but none with sshfs
printf '%s\n' "/dev/sda1 on / type ext4 (rw,relatime)"
printf '%s\n' "tmpfs on /tmp type tmpfs (rw)"
exit 0
SH
  chmod +x "$tmp/mount"
  
  PATH="$tmp:$PATH" run_spell "spells/mud/boot-player"
  assert_success || return 1
  assert_output_contains "No players currently connected" || return 1
}

run_test_case "boot-player shows usage text" test_help
run_test_case "boot-player shows usage with -h" test_help_h_flag
run_test_case "boot-player uses strict mode" test_has_strict_mode
run_test_case "boot-player handles no connected players" test_no_players_connected

finish_tests
