#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./tests/run.sh [options] [-- [Bats options]]

Options:
  --only PATTERN     Run tests whose path matches PATTERN relative to tests/.
                     May be repeated to include multiple patterns. Globs are
                     supported. When omitted, every test_*.bats file runs.
  --list             Print the resolved test files and exit without running.
  --no-coverage      Skip coverage reporting after the Bats run.
  -h, --help         Show this help and exit.

Any additional arguments that do not start with a dash are forwarded to Bats.
Use "--" to force all subsequent options to be passed directly to Bats.
EOF
}

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TEST_DIR="$ROOT_DIR/tests"
COVERAGE_DIR="$TEST_DIR/.coverage"
TRACE_DIR="$COVERAGE_DIR/traces"

run_coverage=1
list_only=0
declare -a only_patterns=()
declare -a bats_passthrough=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --list)
      list_only=1
      shift
      ;;
    --no-coverage)
      run_coverage=0
      shift
      ;;
    --only)
      if [ "$#" -lt 2 ]; then
        echo "error: --only requires a pattern" >&2
        usage
        exit 1
      fi
      only_patterns+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        bats_passthrough+=("$1")
        shift
      done
      break
      ;;
    *)
      bats_passthrough+=("$1")
      shift
      ;;
  esac
done

if [ "$list_only" -eq 0 ]; then
  rm -rf "$COVERAGE_DIR"
  mkdir -p "$TRACE_DIR"
fi

export COVERAGE_DIR
# Files included in the coverage report
mapfile -t coverage_targets < <(cd "$ROOT_DIR/spells" && find . -type f | sort)
if [ ${#coverage_targets[@]} -eq 0 ]; then
  echo "No spells discovered for coverage." >&2
  exit 1
fi

coverage_list=()
for rel in "${coverage_targets[@]}"; do
  rel=${rel#./}
  coverage_list+=("spells/$rel")
done
export COVERAGE_TARGETS="${coverage_list[*]}"

select_tests_with_patterns() {
  local pattern=$1
  local matches=()
  local candidate
  shopt -s nullglob
  if [[ $pattern = /* ]]; then
    matches=($pattern)
  elif [[ $pattern == tests/* ]]; then
    matches=("$ROOT_DIR/$pattern")
  else
    matches=("$TEST_DIR/$pattern")
  fi
  shopt -u nullglob
  if [ ${#matches[@]} -eq 0 ]; then
    echo "error: --only pattern '$pattern' matched no tests" >&2
    exit 1
  fi
  for candidate in "${matches[@]}"; do
    if [ ! -f "$candidate" ]; then
      echo "error: --only pattern '$pattern' resolved to non-existent file '$candidate'" >&2
      exit 1
    fi
    case "$candidate" in
      *.bats) ;;
      *)
        echo "error: --only pattern '$pattern' must resolve to .bats files" >&2
        exit 1
        ;;
    esac
    printf '%s\n' "$candidate"
  done
}

declare -a selected_tests=()
if [ ${#only_patterns[@]} -gt 0 ]; then
  while IFS= read -r match; do
    selected_tests+=("$match")
  done < <(
    for pattern in "${only_patterns[@]}"; do
      select_tests_with_patterns "$pattern"
    done | sort -u
  )
else
  mapfile -t bats_files < <(cd "$TEST_DIR" && printf '%s\n' test_*.bats | sort)
  for file in "${bats_files[@]}"; do
    selected_tests+=("$TEST_DIR/$file")
  done
fi

if [ "$list_only" -eq 1 ]; then
  if [ ${#selected_tests[@]} -eq 0 ]; then
    echo "No tests discovered." >&2
    exit 1
  fi
  for test in "${selected_tests[@]}"; do
    rel_path=${test#"$ROOT_DIR/"}
    printf '%s\n' "$rel_path"
  done
  exit 0
fi

status=0
if ! bash "$TEST_DIR/check_posix_bash.sh"; then
  status=1
fi

if compgen -G "$TEST_DIR"/test_*.bats >/dev/null; then
  if ! bats_path="$("$TEST_DIR/lib/ensure_bats.sh")"; then
    status=1
  else
    bats_cmd=("$bats_path" --formatter tap)
    if [ ${#bats_passthrough[@]} -gt 0 ]; then
      bats_cmd+=("${bats_passthrough[@]}")
    fi
    if [ ${#selected_tests[@]} -gt 0 ]; then
      bats_cmd+=("${selected_tests[@]}")
    fi

    if ! "${bats_cmd[@]}"; then
      status=1
    fi
  fi
fi

if [ "$run_coverage" -eq 1 ]; then
  if ! bash "$TEST_DIR/report_coverage.sh"; then
    status=1
  fi
fi

exit $status
