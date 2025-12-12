#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

prepare_checkbashisms_stub() {
  stub_dir=$(mktemp -d "${WIZARDRY_TMPDIR}/checkbashisms.main.XXXXXX") || return 1
  cat <<'SCRIPT' >"$stub_dir/checkbashisms"
#!/bin/sh
exit 0
SCRIPT
  chmod +x "$stub_dir/checkbashisms"
  PATH="$stub_dir:$PATH"
  CHECKBASHISMS="$stub_dir/checkbashisms"
  export CHECKBASHISMS PATH
}

prepare_checkbashisms_failure_stub() {
  stub_dir=$(mktemp -d "${WIZARDRY_TMPDIR}/checkbashisms.fail.XXXXXX") || return 1
  cat <<'SCRIPT' >"$stub_dir/checkbashisms"
#!/bin/sh
printf '%s\n' "bashism detected" >&2
exit 1
SCRIPT
  chmod +x "$stub_dir/checkbashisms"
  PATH="$stub_dir:$PATH"
  CHECKBASHISMS="$stub_dir/checkbashisms"
  export CHECKBASHISMS PATH
}

run_verify_posix() {
  targets=$1
  # shellcheck disable=SC2086
  _run_cmd "$ROOT_DIR/spells/system/verify-posix" $targets
}

runs_quietly_across_all_spells() {
  prepare_checkbashisms_stub || return 1
  _run_cmd "$ROOT_DIR/spells/system/verify-posix"
  _assert_success || return 1
  summary=$(printf '%s\n' "$OUTPUT" | tail -n 1)
  case $summary in
    "All "*) : ;;
    *) TEST_FAILURE_REASON="expected summary to report all scripts compliant"; return 1 ;;
  esac
  echo "$OUTPUT" | grep '^FAIL ' >/dev/null 2>&1 && { TEST_FAILURE_REASON="expected no FAIL lines"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

accepts_individual_targets() {
  prepare_checkbashisms_stub || return 1
  rel_tmp=".tests/tmp.verify.$$.${RANDOM:-0}"
  abs_tmp="$ROOT_DIR/$rel_tmp"
  mkdir -p "$(dirname "$abs_tmp")"
  cat <<'SCRIPT' >"$abs_tmp"
#!/bin/sh
echo ok
SCRIPT

  _run_cmd "$ROOT_DIR/spells/system/verify-posix" "$rel_tmp"
  _assert_success || return 1
  echo "$OUTPUT" | grep "^PASS $rel_tmp$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected PASS line for target"; return 1; }
  summary=$(printf '%s\n' "$OUTPUT" | tail -n 1)
  case $summary in
    "All 1 scripts are POSIX-compliant.") : ;;
    *) TEST_FAILURE_REASON="expected summary for single target"; return 1 ;;
  esac
  echo "$OUTPUT" | grep '^FAIL ' >/dev/null 2>&1 && { TEST_FAILURE_REASON="expected no FAIL lines"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
  rm -f "$abs_tmp"
}

check_is_quiet_for_posix() {
  prepare_checkbashisms_stub || return 1
  workdir=$(_make_tempdir)
  cat <<'SCRIPT' >"$workdir/direct"
#!/bin/sh
echo ok
SCRIPT
  cat <<'SCRIPT' >"$workdir/env"
#!/usr/bin/env sh
echo ok
SCRIPT

  run_verify_posix "$workdir/direct $workdir/env"
  _assert_success || return 1
  pass_count=$(printf '%s\n' "$OUTPUT" | grep '^PASS ' | wc -l | tr -d ' ')
  [ "$pass_count" -eq 2 ] || { TEST_FAILURE_REASON="expected two PASS lines"; return 1; }
  printf '%s\n' "$OUTPUT" | grep '/direct' >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected direct script to be checked"; return 1; }
  printf '%s\n' "$OUTPUT" | grep '/env' >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected env script to be checked"; return 1; }
  summary=$(printf '%s\n' "$OUTPUT" | tail -n 1)
  case $summary in
    "All 2 scripts are POSIX-compliant.") : ;;
    *) TEST_FAILURE_REASON="expected summary for two scripts"; return 1 ;;
  esac
  echo "$OUTPUT" | grep '^FAIL ' >/dev/null 2>&1 && { TEST_FAILURE_REASON="expected no FAIL lines"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

warns_when_missing_shebang() {
  prepare_checkbashisms_stub || return 1
  workdir=$(_make_tempdir)
  cat <<'SCRIPT' >"$workdir/nameless"
echo 'no interpreter'
SCRIPT

  run_verify_posix "$workdir/nameless"
  _assert_failure || return 1
  printf '%s\n' "$OUTPUT" | grep 'lacks a shebang; expected #!/bin/sh' >/dev/null 2>&1 || { TEST_FAILURE_REASON="missing shebang message"; return 1; }
  # New format uses heading-section
  summary=$(printf '%s\n' "$OUTPUT" | grep "POSIX Compliance Summary")
  [ -n "$summary" ] || { TEST_FAILURE_REASON="expected POSIX Compliance Summary heading"; return 1; }
  # Check for Passed/Failed lines
  printf '%s\n' "$OUTPUT" | grep "Passed:" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected Passed: line"; return 1; }
  printf '%s\n' "$OUTPUT" | grep "Failed:" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected Failed: line"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

warns_for_bash_shebangs() {
  prepare_checkbashisms_stub || return 1
  workdir=$(_make_tempdir)
  cat <<'SCRIPT' >"$workdir/bashy"
#!/usr/bin/env bash
echo 'bash heavy'
SCRIPT

  run_verify_posix "$workdir/bashy"
  _assert_failure || return 1
  printf '%s\n' "$OUTPUT" | grep 'uses #!/usr/bin/env bash (should use /bin/sh)' >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected env bash message"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

warns_for_empty_shebang() {
  skip-if-compiled || return $?
  prepare_checkbashisms_stub || return 1
  workdir=$(_make_tempdir)
  printf '#!\n' >"$workdir/empty"

  run_verify_posix "$workdir/empty"
  _assert_failure || return 1
  printf '%s\n' "$OUTPUT" | grep 'has an empty shebang; expected #!/bin/sh' >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected empty shebang message"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

warns_for_env_arguments() {
  prepare_checkbashisms_stub || return 1
  workdir=$(_make_tempdir)
  cat <<'SCRIPT' >"$workdir/argful"
#!/usr/bin/env bash -l
echo argful
SCRIPT

  run_verify_posix "$workdir/argful"
  _assert_failure || return 1
  printf '%s\n' "$OUTPUT" | grep 'uses #!/usr/bin/env bash -l (should use /bin/sh)' >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected env arg message"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

warns_for_direct_bash_path() {
  prepare_checkbashisms_stub || return 1
  workdir=$(_make_tempdir)
  cat <<'SCRIPT' >"$workdir/direct_bash"
#!/bin/bash
echo direct
SCRIPT

  run_verify_posix "$workdir/direct_bash"
  _assert_failure || return 1
  printf '%s\n' "$OUTPUT" | grep 'uses #!/bin/bash (should use /bin/sh)' >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected direct bash message"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

accepts_space_before_sh() {
  prepare_checkbashisms_stub || return 1
  workdir=$(_make_tempdir)
  cat <<'SCRIPT' >"$workdir/spaced"
#! /bin/sh
echo ok
SCRIPT

  run_verify_posix "$workdir/spaced"
  _assert_success || return 1
  printf '%s\n' "$OUTPUT" | grep '^PASS ' >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected PASS line"; return 1; }
  summary=$(printf '%s\n' "$OUTPUT" | tail -n 1)
  case $summary in
    "All 1 scripts are POSIX-compliant.") : ;;
    *) TEST_FAILURE_REASON="expected summary for spaced shebang"; return 1 ;;
  esac
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

reports_missing_targets() {
  prepare_checkbashisms_stub || return 1
  missing_path=$(mktemp -u "${WIZARDRY_TMPDIR}/verify-posix.missing.XXXXXX")
  run_verify_posix "$missing_path"
  _assert_failure || return 1
  printf '%s\n' "$OUTPUT" | grep 'missing file' >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected missing file message"; return 1; }
  # New format uses heading-section
  summary=$(printf '%s\n' "$OUTPUT" | grep "POSIX Compliance Summary")
  [ -n "$summary" ] || { TEST_FAILURE_REASON="expected POSIX Compliance Summary heading"; return 1; }
  # Check for Passed/Failed lines
  printf '%s\n' "$OUTPUT" | grep "Failed:" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected Failed: line"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

flags_bashisms_and_counts_failures() {
  prepare_checkbashisms_failure_stub || return 1
  workdir=$(_make_tempdir)
  cat <<'SCRIPT' >"$workdir/bashism"
#!/bin/sh
[[ -n "${1-}" ]]
SCRIPT

  run_verify_posix "$workdir/bashism"
  _assert_failure || return 1
  printf '%s\n' "$OUTPUT" | grep '^FAIL ' >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected bashism message"; return 1; }
  echo "$OUTPUT" | grep "^  bashism detected$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected indented bashism output"; return 1; }
  # New format uses heading-section
  summary=$(printf '%s\n' "$OUTPUT" | grep "POSIX Compliance Summary")
  [ -n "$summary" ] || { TEST_FAILURE_REASON="expected POSIX Compliance Summary heading"; return 1; }
  # Check for Passed/Failed lines
  printf '%s\n' "$OUTPUT" | grep "Failed:" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected Failed: line"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

_run_test_case "verify-posix scans all spells by default" runs_quietly_across_all_spells
_run_test_case "verify-posix accepts explicit targets" accepts_individual_targets
_run_test_case "verify-posix is quiet for POSIX sh shebangs" check_is_quiet_for_posix
_run_test_case "verify-posix warns when shebang is missing" warns_when_missing_shebang
_run_test_case "verify-posix warns about bash shebangs" warns_for_bash_shebangs
_run_test_case "verify-posix warns on empty shebang" warns_for_empty_shebang
_run_test_case "verify-posix warns on env args" warns_for_env_arguments
_run_test_case "verify-posix warns on direct bash path" warns_for_direct_bash_path
_run_test_case "verify-posix accepts spaced sh shebang" accepts_space_before_sh
_run_test_case "verify-posix reports missing targets" reports_missing_targets
_run_test_case "verify-posix flags bashisms and counts failures" flags_bashisms_and_counts_failures

shows_help() {
  _run_spell spells/system/verify-posix --help
  true
}

_run_test_case "verify-posix shows help" shows_help
_finish_tests
