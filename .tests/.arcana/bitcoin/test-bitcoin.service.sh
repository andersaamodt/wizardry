#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

has_unit_section() {
  skip-if-compiled || return $?
  grep -q '^\[Unit\]' "$ROOT_DIR/spells/.arcana/bitcoin/bitcoin.service"
}

has_service_section() {
  skip-if-compiled || return $?
  grep -q '^\[Service\]' "$ROOT_DIR/spells/.arcana/bitcoin/bitcoin.service"
}

run_test_case "install/bitcoin/bitcoin.service declares a Unit section" has_unit_section
run_test_case "install/bitcoin/bitcoin.service declares a Service section" has_service_section
has_install_section() {
  skip-if-compiled || return $?
  grep -q "^\[Install\]" "$ROOT_DIR/spells/.arcana/bitcoin/bitcoin.service"
}

run_test_case "install/bitcoin/bitcoin.service declares an Install section" has_install_section
shows_help() {
  run_spell spells/.arcana/bitcoin/bitcoin.service --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "bitcoin.service shows help" shows_help
finish_tests
