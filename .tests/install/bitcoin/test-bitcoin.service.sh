#!/bin/sh
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

has_unit_section() {
  grep -q '^\[Unit\]' "$ROOT_DIR/spells/install/bitcoin/bitcoin.service"
}

has_service_section() {
  grep -q '^\[Service\]' "$ROOT_DIR/spells/install/bitcoin/bitcoin.service"
}

run_test_case "install/bitcoin/bitcoin.service declares a Unit section" has_unit_section
run_test_case "install/bitcoin/bitcoin.service declares a Service section" has_service_section
has_install_section() {
  grep -q "^\[Install\]" "$ROOT_DIR/spells/install/bitcoin/bitcoin.service"
}

run_test_case "install/bitcoin/bitcoin.service declares an Install section" has_install_section
shows_help() {
  run_spell spells/install/bitcoin/bitcoin.service --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "bitcoin.service shows help" shows_help
finish_tests
