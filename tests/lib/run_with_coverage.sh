#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}
TEST_DIR=${TEST_DIR:-$ROOT_DIR/tests}
export ROOT_DIR TEST_DIR

# shellcheck disable=SC1090
source "$ROOT_DIR/tests/lib/coverage.sh"

wizardry_run_with_coverage "$@"
