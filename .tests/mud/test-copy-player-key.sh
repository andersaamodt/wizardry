#!/bin/sh
# Behavioral cases:
# - copy-player-key shows usage
# - copy-player-key requires PLAYER
# - copy-player-key fails when the key is missing
# - copy-player-key copies the public key via clip-copy

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/mud/copy-player-key" --help
  assert_success || return 1
  assert_output_contains "Usage: copy-player-key" || return 1
}

test_requires_player() {
  run_spell "spells/mud/copy-player-key"
  assert_failure || return 1
  assert_error_contains "PLAYER required" || return 1
}

test_fails_when_missing() {
  tmp=$(make_tempdir)
  HOME="$tmp/home" run_spell "spells/mud/copy-player-key" hero
  assert_failure || return 1
  assert_error_contains "key not found" || return 1
}

test_copies_key() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/home/.ssh"
  printf 'ssh-ed25519 AAAA hero@MUD\n' > "$tmp/home/.ssh/hero.pub"
  cat >"$tmp/clip-copy" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >"$CLIP_LOG"
SH
  chmod +x "$tmp/clip-copy"

  run_cmd env HOME="$tmp/home" PATH="$tmp:$PATH" CLIP_LOG="$tmp/log" \
    "$ROOT_DIR/spells/mud/copy-player-key" hero
  assert_success || return 1
  assert_file_contains "$tmp/log" "ssh-ed25519 AAAA hero@MUD"
}

run_test_case "copy-player-key shows usage" test_help
run_test_case "copy-player-key requires PLAYER" test_requires_player
run_test_case "copy-player-key fails when missing" test_fails_when_missing
run_test_case "copy-player-key copies the key" test_copies_key

finish_tests
