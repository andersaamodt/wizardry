#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - check-cd-hook prints usage
# - check-cd-hook returns 0 when hook marker is present
# - check-cd-hook returns 1 when hook marker is absent
# - check-cd-hook returns 1 when rc file doesn't exist
# - check-cd-hook uses WIZARDRY_RC_FILE when set

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/mud/check-cd-hook" --help
  _assert_success && _assert_output_contains "Usage: check-cd-hook"
}

test_returns_success_when_hook_present() {
  rc_file="$WIZARDRY_TMPDIR/test-bashrc-with-hook"
  cat >"$rc_file" <<'EOF'
# >>> wizardry cd cantrip >>>
alias cd='wizardry-cd'
# <<< wizardry cd cantrip <<<
EOF
  WIZARDRY_RC_FILE="$rc_file" _run_spell "spells/mud/check-cd-hook"
  _assert_success
}

test_returns_failure_when_hook_absent() {
  rc_file="$WIZARDRY_TMPDIR/test-bashrc-without-hook"
  cat >"$rc_file" <<'EOF'
# Normal bashrc without wizardry hooks
export PATH="/usr/local/bin:$PATH"
EOF
  WIZARDRY_RC_FILE="$rc_file" _run_spell "spells/mud/check-cd-hook"
  _assert_failure
}

test_returns_failure_when_rc_file_missing() {
  rc_file="$WIZARDRY_TMPDIR/nonexistent-rc-file"
  rm -f "$rc_file"
  WIZARDRY_RC_FILE="$rc_file" _run_spell "spells/mud/check-cd-hook"
  _assert_failure
}

test_respects_wizardry_rc_file_env() {
  rc_file="$WIZARDRY_TMPDIR/test-custom-rc"
  cat >"$rc_file" <<'EOF'
# >>> wizardry cd cantrip >>>
alias cd='wizardry-cd'
# <<< wizardry cd cantrip <<<
EOF
  WIZARDRY_RC_FILE="$rc_file" _run_spell "spells/mud/check-cd-hook"
  _assert_success
}

_run_test_case "check-cd-hook prints usage" test_help
_run_test_case "check-cd-hook returns success when hook is present" test_returns_success_when_hook_present
_run_test_case "check-cd-hook returns failure when hook is absent" test_returns_failure_when_hook_absent
_run_test_case "check-cd-hook returns failure when rc file is missing" test_returns_failure_when_rc_file_missing
_run_test_case "check-cd-hook respects WIZARDRY_RC_FILE environment variable" test_respects_wizardry_rc_file_env
_finish_tests
