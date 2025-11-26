#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

has_unit_section() {
  grep -q '^\[Unit\]' "$ROOT_DIR/spells/install/tor/tor.service"
}

has_service_section() {
  grep -q '^\[Service\]' "$ROOT_DIR/spells/install/tor/tor.service"
}

run_test_case "install/tor/tor.service declares a Unit section" has_unit_section
run_test_case "install/tor/tor.service declares a Service section" has_service_section
has_install_section() {
  grep -q "^\[Install\]" "$ROOT_DIR/spells/install/tor/tor.service"
}

run_test_case "install/tor/tor.service declares an Install section" has_install_section
shows_help() {
  run_spell spells/install/tor/tor.service --help
  true
}

run_test_case "tor.service shows help" shows_help
finish_tests
