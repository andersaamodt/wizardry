#!/bin/sh
# Behavioral cases:
# - uninstall-wizardry shows usage
# - uninstall-wizardry runs the generated uninstall script
# - uninstall-wizardry fails clearly when no generated script exists

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.wizardry/uninstall-wizardry" --help
  assert_success || return 1
  assert_output_contains "Usage: uninstall-wizardry" || return 1
}

test_runs_generated_uninstaller() {
  tmp=$(make_tempdir)
  cat >"$tmp/.uninstall" <<'SH'
#!/bin/sh
printf '%s\n' "uninstall-ran"
SH
  chmod +x "$tmp/.uninstall"

  WIZARDRY_DIR="$tmp" run_spell "spells/.wizardry/uninstall-wizardry"
  assert_success || return 1
  assert_output_contains "uninstall-ran" || return 1
}

test_fails_without_generated_uninstaller() {
  tmp=$(make_tempdir)
  WIZARDRY_DIR="$tmp" run_spell "spells/.wizardry/uninstall-wizardry"
  assert_failure || return 1
  assert_error_contains "no generated uninstall script found" || return 1
}

run_test_case "uninstall-wizardry shows usage" test_help
run_test_case "uninstall-wizardry runs generated uninstaller" test_runs_generated_uninstaller
run_test_case "uninstall-wizardry fails when no script exists" test_fails_without_generated_uninstaller

finish_tests
