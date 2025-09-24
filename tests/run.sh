#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TEST_DIR="$ROOT_DIR/tests"
COVERAGE_DIR="$TEST_DIR/.coverage"
TRACE_DIR="$COVERAGE_DIR/traces"
rm -rf "$COVERAGE_DIR"
mkdir -p "$TRACE_DIR"

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

status=0
if ! bash "$TEST_DIR/check_posix_bash.sh"; then
  status=1
fi
if compgen -G "$TEST_DIR/bats/*.bats" >/dev/null; then
  if ! bats_path="$("$TEST_DIR/lib/ensure_bats.sh")"; then
    status=1
  elif ! "$bats_path" --formatter tap "$TEST_DIR/bats"; then
    status=1
  fi
fi
for test_file in "$TEST_DIR"/test_*.sh; do
  echo "Running $(basename "$test_file")"
  if ! bash "$test_file"; then
    status=1
  fi
done

if ! bash "$TEST_DIR/report_coverage.sh"; then
  status=1
fi

exit $status
