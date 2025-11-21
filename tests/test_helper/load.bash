#!/usr/bin/env bash

wizardry_find_root() {
  local dir="${BATS_TEST_DIRNAME:-$(pwd)}"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/spells" ] && [ -d "$dir/tests" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  printf '%s\n' "$BATS_TEST_DIRNAME"
}

ROOT_DIR=$(wizardry_find_root)
TEST_DIR="$ROOT_DIR/tests"

wizardry_load_helper() {
  local module=$1
  local script=$2
  local vendor_base="$TEST_DIR/vendor/$module"
  local vendor_script=""
  if [ -f "$vendor_base/$script.bash" ]; then
    vendor_script="$vendor_base/$script.bash"
  elif [ -f "$vendor_base/$script" ]; then
    vendor_script="$vendor_base/$script"
  fi

  if [ -n "$vendor_script" ]; then
    load "$vendor_script"
  else
    load "$module/$script"
  fi
}

wizardry_load_helper bats-support load
wizardry_load_helper bats-assert load
wizardry_load_helper bats-mock stub

bats_require_minimum_version 1.5.0

# shellcheck disable=SC1090
source "$TEST_DIR/lib/coverage.sh"
# shellcheck disable=SC1090
source "$TEST_DIR/lib/stub_helpers.sh"

declare -a __wizardry_stubbed=()

default_setup() {
  STUB_TMPDIR="$BATS_TEST_TMPDIR/stubs"
  mkdir -p "$STUB_TMPDIR"
  local wizardry_paths="$ROOT_DIR/spells:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/menu"
  PATH="$STUB_TMPDIR:$wizardry_paths:$PATH"
  TEST_TMPDIR="$BATS_TEST_TMPDIR"
  WIZARDRY_TMPDIR="$BATS_TEST_TMPDIR"
  export WIZARDRY_TMPDIR
  export TEST_TMPDIR
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
  run --separate-stderr -- wizardry_run_with_coverage "$script" "$@"
}

assert_error() {
  local mode="exact"
  if [ "$1" = "--partial" ]; then
    mode="partial"
    shift
  fi

  local expected=${1-}
  if [ "$mode" = "partial" ]; then
    if [[ "$stderr" != *"$expected"* ]]; then
      echo "stderr does not contain substring: $expected" >&2
      echo "stderr: $stderr" >&2
      return 1
    fi
  else
    if [ "$stderr" != "$expected" ]; then
      echo "stderr differed" >&2
      echo "expected: $expected" >&2
      echo "stderr  : $stderr" >&2
      return 1
    fi
  fi
}

read_clipboard() {
  cat "$BATS_TEST_TMPDIR/clipboard.txt"
}
