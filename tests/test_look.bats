#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_HOME=$HOME
  ORIGINAL_PATH=$PATH
  HOME="$BATS_TEST_TMPDIR/look_home"
  mkdir -p "$HOME"

  workspace="$BATS_TEST_TMPDIR/workspace"
  mkdir -p "$workspace/bin"
  cat <<'COLORS' >"$workspace/colors"
BLUE=""
BOLD=""
RESET=""
COLORS
  chmod +x "$workspace/colors"

  read_magic_stub="$workspace/bin/read-magic"
  write_room_stub
}

teardown() {
  HOME=$ORIGINAL_HOME
  PATH=$ORIGINAL_PATH
  default_teardown
}

write_room_stub() {
  cat <<'STUB' >"$read_magic_stub"
#!/usr/bin/env bash
file=$1
key=$2
case "$file" in
  room.txt)
    case "$key" in
      name) echo "Grand Hall" ;;
      description) echo "A vaulted chamber." ;;
      *) echo "Error: The attribute does not exist." ;;
    esac
    ;;
  *)
    echo "Error: The attribute does not exist."
    ;;
esac
STUB
  chmod +x "$read_magic_stub"
}

with_look_path() {
  PATH="$workspace/bin:$ORIGINAL_PATH" "$@"
}

@test 'look memorizes spell and reveals room details' {
  room_path="$workspace/room.txt"
  : >"$room_path"

  printf 'yes\n' >"$BATS_TEST_TMPDIR/yes"
  pushd "$workspace" >/dev/null
  with_look_path run_spell 'spells/look' 'room.txt' <"$BATS_TEST_TMPDIR/yes"
  popd >/dev/null

  assert_success
  assert_output --partial 'Grand Hall'
  assert_output --partial 'A vaulted chamber.'
  assert_output --partial 'Spell memorized'

  run cat "$HOME/.bashrc"
  assert_success
  assert_output --partial 'alias look'
}

@test 'look falls back when attributes missing' {
  printf '' >"$HOME/.bashrc"
  cat <<'EMPTY' >"$read_magic_stub"
#!/usr/bin/env bash
echo "Error: The attribute does not exist."
EMPTY
  chmod +x "$read_magic_stub"

  empty_path="$workspace/empty.txt"
  : >"$empty_path"

  printf 'no\n' >"$BATS_TEST_TMPDIR/no"
  pushd "$workspace" >/dev/null
  with_look_path run_spell 'spells/look' 'empty.txt' <"$BATS_TEST_TMPDIR/no"
  popd >/dev/null

  assert_success
  assert_output --partial 'The mud will only run'
  assert_output --partial "You look, but you don't see anything."
}

