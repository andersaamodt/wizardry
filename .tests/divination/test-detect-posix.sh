#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

detect_posix_shows_usage() {
  _run_spell "spells/divination/detect-posix" --help
  _assert_success || return 1
  _assert_output_contains "Usage: detect-posix" || return 1
}

detect_posix_reports_success_for_minimal_probe() {
  DETECT_POSIX_TOOLS="sh" DETECT_POSIX_PROBES="sh" _run_spell "spells/divination/detect-posix"
  _assert_success || return 1
  _assert_output_contains "POSIX toolchain and probes look healthy." || return 1
}

detect_posix_reports_missing_tools() {
  DETECT_POSIX_TOOLS="nope" DETECT_POSIX_PROBES="sh" _run_spell "spells/divination/detect-posix"
  _assert_failure || return 1
  _assert_error_contains "detect-posix: missing tools: nope" || return 1
}
