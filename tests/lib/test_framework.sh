#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
TEST_DIR="$ROOT_DIR/tests"
COVERAGE_DIR="${COVERAGE_DIR:-$TEST_DIR/.coverage}"
TRACE_DIR="$COVERAGE_DIR/traces"
mkdir -p "$TRACE_DIR"

TEST_TMPDIR=$(mktemp -d "$TEST_DIR/tmp.XXXXXX")
cleanup_tmpdir() {
  rm -rf "$TEST_TMPDIR"
}
trap cleanup_tmpdir EXIT

TRACE_COUNTER=0

TEST_FAILURES=0
declare -a TEST_FAILURE_MESSAGES=()

run_script() {
  local script=$1
  shift
  local abs_script="$ROOT_DIR/$script"
  if [ ! -f "$abs_script" ]; then
    echo "Test harness could not find script: $script" >&2
    return 127
  fi

  local trace_file
  TRACE_COUNTER=$((TRACE_COUNTER + 1))
  trace_file=$(printf '%s/%04d_%s.trace' "$TRACE_DIR" "$TRACE_COUNTER" "$(echo "$script" | tr '/' '_')")

  local stdout_file stderr_file
  stdout_file=$(mktemp "$TEST_TMPDIR/stdout.XXXXXX")
  stderr_file=$(mktemp "$TEST_TMPDIR/stderr.XXXXXX")

  RUN_STDOUT=""
  RUN_STDERR=""
  RUN_EXIT_CODE=0

  set +e
  local previous_ps4=${PS4-}
  local previous_bash_env=${BASH_ENV-}
  local env_file
  env_file=$(mktemp "$TEST_TMPDIR/env.XXXXXX")
  cat <<'ENV' >"$env_file"
PS4='+${BASH_SOURCE}:${LINENO}:'
export PS4
ENV
  local previous_path=$PATH
  if [ -n "${RUN_PATH_OVERRIDE:-}" ]; then
    PATH="$RUN_PATH_OVERRIDE"
  fi
  exec 5>"$trace_file"
  export BASH_XTRACEFD=5
  BASH_ENV="$env_file" bash -x "$abs_script" "$@" >"$stdout_file" 2>"$stderr_file"
  local command_status=$?
  exec 5>&-
  PATH=$previous_path
  if [ -n "${previous_ps4+x}" ]; then
    export PS4="$previous_ps4"
  else
    unset PS4
  fi
  if [ -n "${previous_bash_env+x}" ]; then
    export BASH_ENV="$previous_bash_env"
  else
    unset BASH_ENV
  fi
  unset BASH_XTRACEFD
  rm -f "$env_file"
  RUN_EXIT_CODE=$command_status
  set -e

  RUN_STDOUT=$(cat "$stdout_file")
  RUN_STDERR=$(cat "$stderr_file")
  rm -f "$stdout_file" "$stderr_file"
}

make_temp_dir() {
  mktemp -d "$TEST_TMPDIR/case.XXXXXX"
}

fail() {
  echo "Assertion failed: $1" >&2
  exit 1
}

assert_eq() {
  local expected=$1
  local actual=$2
  local message=${3:-}
  if [ "$expected" != "$actual" ]; then
    if [ -n "$message" ]; then
      fail "$message (expected '$expected' but got '$actual')"
    else
      fail "expected '$expected' but got '$actual'"
    fi
  fi
}

assert_exit_code() {
  local expected=$1
  if [ "$RUN_EXIT_CODE" -ne "$expected" ]; then
    fail "expected exit code $expected but got $RUN_EXIT_CODE"
  fi
}

assert_in_output() {
  local needle=$1
  local haystack=$2
  local message=${3:-}
  if ! printf '%s' "$haystack" | grep -Fq "$needle"; then
    if [ -n "$message" ]; then
      fail "$message (missing '$needle')"
    else
      fail "expected to find '$needle'"
    fi
  fi
}

assert_not_in_output() {
  local needle=$1
  local haystack=$2
  local message=${3:-}
  if printf '%s' "$haystack" | grep -Fq "$needle"; then
    if [ -n "$message" ]; then
      fail "$message (unexpected '$needle')"
    else
      fail "did not expect to find '$needle'"
    fi
  fi
}

record_failure() {
  local message=$1
  TEST_FAILURES=$((TEST_FAILURES + 1))
  TEST_FAILURE_MESSAGES+=("$message")
}

expect_eq() {
  local expected=$1
  local actual=$2
  local message=${3:-}
  if [ "$expected" != "$actual" ]; then
    if [ -n "$message" ]; then
      record_failure "$message (expected '$expected' but got '$actual')"
    else
      record_failure "expected '$expected' but got '$actual'"
    fi
  fi
}

expect_exit_code() {
  local expected=$1
  if [ "$RUN_EXIT_CODE" -ne "$expected" ]; then
    record_failure "expected exit code $expected but got $RUN_EXIT_CODE"
  fi
}

expect_in_output() {
  local needle=$1
  local haystack=$2
  local message=${3:-}
  if ! printf '%s' "$haystack" | grep -Fq "$needle"; then
    if [ -n "$message" ]; then
      record_failure "$message (missing '$needle')"
    else
      record_failure "expected to find '$needle'"
    fi
  fi
}

expect_not_in_output() {
  local needle=$1
  local haystack=$2
  local message=${3:-}
  if printf '%s' "$haystack" | grep -Fq "$needle"; then
    if [ -n "$message" ]; then
      record_failure "$message (unexpected '$needle')"
    else
      record_failure "did not expect to find '$needle'"
    fi
  fi
}

assert_all_expectations_met() {
  if [ "$TEST_FAILURES" -eq 0 ]; then
    echo "All expectations met."
    return 0
  fi

  printf 'Encountered %d expectation failure(s):\n' "$TEST_FAILURES"
  for message in "${TEST_FAILURE_MESSAGES[@]}"; do
    printf '  - %s\n' "$message"
  done
  return 1
}
