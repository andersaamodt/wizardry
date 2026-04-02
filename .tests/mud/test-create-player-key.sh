#!/bin/sh
# Behavioral cases:
# - create-player-key shows usage
# - create-player-key requires PLAYER
# - create-player-key rejects invalid names
# - create-player-key fails when the key already exists
# - create-player-key generates a key pair and prints the public key

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/mud/create-player-key" --help
  assert_success || return 1
  assert_output_contains "Usage: create-player-key" || return 1
}

test_requires_player() {
  run_spell "spells/mud/create-player-key"
  assert_failure || return 1
  assert_error_contains "PLAYER required" || return 1
}

test_rejects_invalid_name() {
  run_spell "spells/mud/create-player-key" "bad/name"
  assert_failure || return 1
}

test_fails_when_key_exists() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/home/.ssh"
  : > "$tmp/home/.ssh/hero"
  run_cmd env HOME="$tmp/home" "$ROOT_DIR/spells/mud/create-player-key" hero
  assert_failure || return 1
  assert_error_contains "already exists" || return 1
}

test_creates_key() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/home/.ssh"
  cat >"$tmp/ssh-keygen" <<'SH'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  case $1 in
    -f)
      key_path=$2
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
printf '%s\n' "private" > "$key_path"
printf '%s\n' "ssh-ed25519 AAAA generated@MUD" > "${key_path}.pub"
SH
  chmod +x "$tmp/ssh-keygen"

  run_cmd env HOME="$tmp/home" PATH="$tmp:$PATH" \
    "$ROOT_DIR/spells/mud/create-player-key" hero
  assert_success || return 1
  assert_output_contains "ssh-ed25519 AAAA generated@MUD" || return 1
  assert_path_exists "$tmp/home/.ssh/hero"
  assert_path_exists "$tmp/home/.ssh/hero.pub"
}

run_test_case "create-player-key shows usage" test_help
run_test_case "create-player-key requires PLAYER" test_requires_player
run_test_case "create-player-key rejects invalid names" test_rejects_invalid_name
run_test_case "create-player-key fails when key exists" test_fails_when_key_exists
run_test_case "create-player-key generates the key pair" test_creates_key

finish_tests
