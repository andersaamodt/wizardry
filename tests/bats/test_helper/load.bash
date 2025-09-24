#!/usr/bin/env bash
load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'
load '../vendor/bats-mock/stub'

ROOT_DIR=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)

declare -a __wizardry_stubbed=()

default_setup() {
  STUB_TMPDIR="$BATS_TEST_TMPDIR/stubs"
  mkdir -p "$STUB_TMPDIR"
  PATH="$STUB_TMPDIR:$PATH"
}

default_teardown() {
  for cmd in "${__wizardry_stubbed[@]}"; do
    unstub "$cmd"
  done
  __wizardry_stubbed=()
}

wizardry_stub() {
  local cmd=$1
  shift
  stub "$cmd" "$@"
  __wizardry_stubbed+=("$cmd")
}

wizardry_remove_stub() {
  local cmd=$1
  local remaining=()
  for existing in "${__wizardry_stubbed[@]}"; do
    if [ "$existing" != "$cmd" ]; then
      remaining+=("$existing")
    fi
  done
  __wizardry_stubbed=("${remaining[@]}")
}

run_spell() {
  local script=$1
  shift
  local abs="$ROOT_DIR/$script"
  run env ROOT_DIR="$ROOT_DIR" bash "$abs" "$@"
}

stub_clipboard() {
  local file="$BATS_TEST_TMPDIR/clipboard.txt"
  wizardry_stub pbcopy "if [ -n \"\${PBCOPY_STUB_END:-}\" ]; then exit 0; fi; cat >\"$file\""
  wizardry_stub xclip "if [ -n \"\${XCLIP_STUB_END:-}\" ]; then exit 0; fi; cat >\"$file\""
  wizardry_stub xsel "if [ -n \"\${XSEL_STUB_END:-}\" ]; then exit 0; fi; cat >\"$file\""
  : >"$file"
  CLIPBOARD_FILE="$file"
}

read_clipboard() {
  cat "$BATS_TEST_TMPDIR/clipboard.txt"
}
