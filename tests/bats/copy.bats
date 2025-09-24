#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
  CLIPBOARD_FILE="$BATS_TEST_TMPDIR/clipboard.txt"
  : >"$CLIPBOARD_FILE"
}

teardown() {
  PATH=$ORIGINAL_PATH
  default_teardown
}

make_clipboard_stubs() {
  local dir="$BATS_TEST_TMPDIR/$1"
  shift
  mkdir -p "$dir"
  for cmd in "$@"; do
    cat <<'STUB' >"$dir/$cmd"
#!/usr/bin/env bash
set -euo pipefail
if [ -z "${CLIPBOARD_FILE:-}" ]; then
  echo "clipboard stub: CLIPBOARD_FILE is not set" >&2
  exit 1
fi
cat >"$CLIPBOARD_FILE"
STUB
    chmod +x "$dir/$cmd"
  done
  printf '%s\n' "$dir"
}

@test 'copy writes file contents into clipboard using available commands' {
  run_spell "spells/copy"
  assert_failure
  assert_output --partial 'does not exist'

  test_dir="$BATS_TEST_TMPDIR"
  file="$test_dir/message.txt"
  printf 'hello world' >"$file"

  clip_dir=$(make_clipboard_stubs pbcopy pbcopy xsel xclip)
  PATH="$clip_dir:$ORIGINAL_PATH" CLIPBOARD_FILE="$CLIPBOARD_FILE" run_spell "spells/copy" "$file"
  assert_success
  run read_clipboard
  assert_output 'hello world'

  clip_dir=$(make_clipboard_stubs xsel-only xsel xclip)
  PATH="$clip_dir:$ORIGINAL_PATH" CLIPBOARD_FILE="$CLIPBOARD_FILE" run_spell "spells/copy" "$file"
  assert_success

  clip_dir=$(make_clipboard_stubs xclip-only xclip)
  PATH="$clip_dir:$ORIGINAL_PATH" CLIPBOARD_FILE="$CLIPBOARD_FILE" run_spell "spells/copy" "$file"
  assert_success

  PATH="$ORIGINAL_PATH" CLIPBOARD_FILE="$CLIPBOARD_FILE" run_spell "spells/copy" "$file"
  assert_failure
  assert_output --partial 'No clipboard utilities'
}
