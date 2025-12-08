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
  grep -q '^\[Unit\]' "$ROOT_DIR/spells/.arcana/tor/tor.service"
}

has_service_section() {
  skip-if-compiled || return $?
  grep -q '^\[Service\]' "$ROOT_DIR/spells/.arcana/tor/tor.service"
}

_run_test_case "install/tor/tor.service declares a Unit section" has_unit_section
_run_test_case "install/tor/tor.service declares a Service section" has_service_section
has_install_section() {
  skip-if-compiled || return $?
  grep -q "^\[Install\]" "$ROOT_DIR/spells/.arcana/tor/tor.service"
}

_run_test_case "install/tor/tor.service declares an Install section" has_install_section
shows_help() {
  _run_spell spells/.arcana/tor/tor.service --help
  true
}

_run_test_case "tor.service shows help" shows_help
_finish_tests
