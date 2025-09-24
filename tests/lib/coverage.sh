#!/usr/bin/env bash

__wizardry_coverage_initialized=0
__wizardry_trace_directory=""

_wizardry_trace_dir() {
  if [ "$__wizardry_coverage_initialized" -eq 0 ]; then
    if [ -z "${ROOT_DIR:-}" ]; then
      ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
    fi
    local test_dir="${TEST_DIR:-$ROOT_DIR/tests}"
    local coverage_dir="${COVERAGE_DIR:-$test_dir/.coverage}"
    local trace_dir="$coverage_dir/traces"
    mkdir -p "$trace_dir"
    __wizardry_trace_directory="$trace_dir"
    __wizardry_coverage_initialized=1
  fi
  printf '%s\n' "$__wizardry_trace_directory"
}

_wizardry_make_trace_file() {
  local script=$1
  local trace_dir
  trace_dir=$(_wizardry_trace_dir)
  local sanitized
  sanitized=$(printf '%s' "$script" | tr '/ ' '__')
  mktemp "$trace_dir/${sanitized}.XXXX.trace"
}

wizardry_run_with_coverage() {
  local script=$1
  shift

  if [ -z "${ROOT_DIR:-}" ]; then
    ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
  fi

  local abs
  if [[ $script = /* ]]; then
    abs="$script"
  else
    abs="$ROOT_DIR/$script"
  fi

  if [ ! -f "$abs" ]; then
    echo "Test harness could not find script: $script" >&2
    return 127
  fi

  local trace_file
  trace_file=$(_wizardry_make_trace_file "$script")

  local tmp_dir="${WIZARDRY_TMPDIR:-${TEST_TMPDIR:-${BATS_TEST_TMPDIR:-}}}"
  local created_tmp=0
  if [ -z "$tmp_dir" ] || [ ! -d "$tmp_dir" ]; then
    tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/wizardry.XXXXXX")
    created_tmp=1
  fi

  local stdout_file stderr_file env_file
  stdout_file=$(mktemp "$tmp_dir/stdout.XXXXXX")
  stderr_file=$(mktemp "$tmp_dir/stderr.XXXXXX")
  env_file=$(mktemp "$tmp_dir/env.XXXXXX")

  cat <<'ENV' >"$env_file"
PS4='+${BASH_SOURCE}:${LINENO}:'
export PS4
ENV

  local previous_path=$PATH
  if [ -n "${RUN_PATH_OVERRIDE:-}" ]; then
    PATH="$RUN_PATH_OVERRIDE"
  fi

  local had_errexit=0
  case $- in
    *e*) had_errexit=1 ;;
  esac

  set +e
  exec 5>"$trace_file"
  BASH_ENV="$env_file" ROOT_DIR="$ROOT_DIR" BASH_XTRACEFD=5 bash -x "$abs" "$@" \
    >"$stdout_file" 2>"$stderr_file"
  local status=$?
  exec 5>&-

  if [ "$had_errexit" -eq 1 ]; then
    set -e
  fi

  PATH=$previous_path

  cat "$stdout_file"
  cat "$stderr_file" >&2

  rm -f "$stdout_file" "$stderr_file" "$env_file"
  if [ "$created_tmp" -eq 1 ]; then
    rm -rf "$tmp_dir"
  fi

  return "$status"
}
