#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/lightning/lightning-status" ]
}
run_test_case "install/lightning/lightning-status is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/lightning/lightning-status" ]
}
run_test_case "install/lightning/lightning-status has content" spell_has_content

shows_usage_help() {
  run_spell spells/install/lightning/lightning-status --help
  assert_success || return 1
  assert_error_contains "Usage: lightning-status"
}
run_test_case "lightning-status shows usage help" shows_usage_help

reports_running_status() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/lightning-status.XXXXXX")
  mkdir -p "$tmpdir/bin"

  cat >"$tmpdir/bin/colors" <<'STUB'
#!/bin/sh
GREEN=""
YELLOW=""
RED=""
GRAY=""
RESET=""
STUB
  cat >"$tmpdir/bin/lightning-cli" <<'STUB'
#!/bin/sh
exit 0
STUB
  cat >"$tmpdir/bin/lightningd" <<'STUB'
#!/bin/sh
exit 0
STUB
  cat >"$tmpdir/bin/is-service-installed" <<'STUB'
#!/bin/sh
exit 0
STUB
  cat >"$tmpdir/bin/is-service-running" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$tmpdir/bin"/*

  PATH="$tmpdir/bin:$PATH" run_spell spells/install/lightning/lightning-status
  assert_success || return 1
  assert_output_contains "installed, running"
}
run_test_case "lightning-status reports running state" reports_running_status

reports_needs_setup_when_cli_fails() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/lightning-status-setup.XXXXXX")
  mkdir -p "$tmpdir/bin"

  cat >"$tmpdir/bin/colors" <<'STUB'
#!/bin/sh
GREEN=""; YELLOW=""; RED=""; GRAY=""; RESET=""
STUB
  cat >"$tmpdir/bin/lightning-cli" <<'STUB'
#!/bin/sh
exit 1
STUB
  cat >"$tmpdir/bin/lightningd" <<'STUB'
#!/bin/sh
exit 0
STUB
  cat >"$tmpdir/bin/is-service-installed" <<'STUB'
#!/bin/sh
exit 0
STUB
  cat >"$tmpdir/bin/is-service-running" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$tmpdir/bin"/*

  PATH="$tmpdir/bin:$PATH" run_spell spells/install/lightning/lightning-status
  assert_success || return 1
  assert_output_contains "installed, needs setup"
}
run_test_case "lightning-status flags setup problems" reports_needs_setup_when_cli_fails

reports_not_running_when_service_stopped() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/lightning-status-stopped.XXXXXX")
  mkdir -p "$tmpdir/bin"

  cat >"$tmpdir/bin/colors" <<'STUB'
#!/bin/sh
GREEN=""; YELLOW=""; RED=""; GRAY=""; RESET=""
STUB
  cat >"$tmpdir/bin/lightning-cli" <<'STUB'
#!/bin/sh
exit 0
STUB
  cat >"$tmpdir/bin/lightningd" <<'STUB'
#!/bin/sh
exit 0
STUB
  cat >"$tmpdir/bin/is-service-installed" <<'STUB'
#!/bin/sh
exit 0
STUB
  cat >"$tmpdir/bin/is-service-running" <<'STUB'
#!/bin/sh
exit 1
STUB
  chmod +x "$tmpdir/bin"/*

  PATH="$tmpdir/bin:$PATH" run_spell spells/install/lightning/lightning-status
  assert_success || return 1
  assert_output_contains "installed, not running"
}
run_test_case "lightning-status shows stopped service" reports_not_running_when_service_stopped

reports_missing_when_not_installed() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/lightning-status-missing.XXXXXX")
  mkdir -p "$tmpdir/bin"

  cat >"$tmpdir/bin/colors" <<'STUB'
#!/bin/sh
GREEN=""; YELLOW=""; RED=""; GRAY=""; RESET=""
STUB
  chmod +x "$tmpdir/bin"/*

  PATH="$tmpdir/bin:$PATH" run_spell spells/install/lightning/lightning-status
  assert_success || return 1
  assert_output_contains "not installed"
}
run_test_case "lightning-status reports missing installation" reports_missing_when_not_installed

finish_tests
