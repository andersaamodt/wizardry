#!/bin/sh
# Behavioral cases:
# - verify-posix reports PASS for POSIX sh shebangs
# - warns when shebangs are missing, empty, or bash-oriented
# - reports missing targets without crashing

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

make_repo_tempdir() {
  rel_dir="tests/tmp.posix.$$.${RANDOM:-0}"
  abs_dir="$ROOT_DIR/$rel_dir"
  mkdir -p "$abs_dir"
  printf '%s\n' "$rel_dir"
}

prepare_checkbashisms_stub() {
  stub_dir=$(mktemp -d "${WIZARDRY_TMPDIR}/checkbashisms.XXXXXX") || return 1
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
  run_cmd "$ROOT_DIR/spells/verify-posix" $targets
}

check_is_quiet_for_posix() {
  prepare_checkbashisms_stub || return 1
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  cat <<'SCRIPT' >"$workdir/direct"
#!/bin/sh
echo ok
SCRIPT
  cat <<'SCRIPT' >"$workdir/env"
#!/usr/bin/env sh
echo ok
SCRIPT

  run_verify_posix "$workrel/direct $workrel/env"
  assert_success || return 1
  echo "$OUTPUT" | grep "^PASS $workrel/direct$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected PASS line for direct"; return 1; }
  echo "$OUTPUT" | grep "^PASS $workrel/env$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected PASS line for env"; return 1; }
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
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  cat <<'SCRIPT' >"$workdir/nameless"
echo 'no interpreter'
SCRIPT

  run_verify_posix "$workrel/nameless"
  assert_failure || return 1
  echo "$OUTPUT" | grep "^FAIL $workrel/nameless: lacks a shebang; expected #!/bin/sh$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="missing shebang message"; return 1; }
  summary=$(printf '%s\n' "$OUTPUT" | tail -n 1)
  case $summary in
    "1 of 1 scripts failed POSIX compliance.") : ;;
    *) TEST_FAILURE_REASON="expected failure summary"; return 1 ;;
  esac
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

warns_for_bash_shebangs() {
  prepare_checkbashisms_stub || return 1
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  cat <<'SCRIPT' >"$workdir/bashy"
#!/usr/bin/env bash
echo 'bash heavy'
SCRIPT

  run_verify_posix "$workrel/bashy"
  assert_failure || return 1
  echo "$OUTPUT" | grep "^FAIL $workrel/bashy: uses #!/usr/bin/env bash; please use /bin/sh$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected env bash message"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

warns_for_empty_shebang() {
  prepare_checkbashisms_stub || return 1
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  printf '#!\n' >"$workdir/empty"

  run_verify_posix "$workrel/empty"
  assert_failure || return 1
  echo "$OUTPUT" | grep "^FAIL $workrel/empty: has an empty shebang; expected #!/bin/sh$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected empty shebang message"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

warns_for_env_arguments() {
  prepare_checkbashisms_stub || return 1
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  cat <<'SCRIPT' >"$workdir/argful"
#!/usr/bin/env bash -l
echo argful
SCRIPT

  run_verify_posix "$workrel/argful"
  assert_failure || return 1
  echo "$OUTPUT" | grep "^FAIL $workrel/argful: uses #!/usr/bin/env bash -l; please use /bin/sh$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected env arg message"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

warns_for_direct_bash_path() {
  prepare_checkbashisms_stub || return 1
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  cat <<'SCRIPT' >"$workdir/direct_bash"
#!/bin/bash
echo direct
SCRIPT

  run_verify_posix "$workrel/direct_bash"
  assert_failure || return 1
  echo "$OUTPUT" | grep "^FAIL $workrel/direct_bash: uses #!/bin/bash; please use /bin/sh$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected direct bash message"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

accepts_space_before_sh() {
  prepare_checkbashisms_stub || return 1
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  cat <<'SCRIPT' >"$workdir/spaced"
#! /bin/sh
echo ok
SCRIPT

  run_verify_posix "$workrel/spaced"
  assert_success || return 1
  echo "$OUTPUT" | grep "^PASS $workrel/spaced$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected PASS line"; return 1; }
  summary=$(printf '%s\n' "$OUTPUT" | tail -n 1)
  case $summary in
    "All 1 scripts are POSIX-compliant.") : ;;
    *) TEST_FAILURE_REASON="expected summary for spaced shebang"; return 1 ;;
  esac
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

reports_missing_targets() {
  prepare_checkbashisms_stub || return 1
  run_verify_posix "tests/tmp.posix.missing"
  assert_failure || return 1
  echo "$OUTPUT" | grep "^FAIL tests/tmp.posix.missing: missing file$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected missing file message"; return 1; }
  summary=$(printf '%s\n' "$OUTPUT" | tail -n 1)
  case $summary in
    "1 of 1 scripts failed POSIX compliance.") : ;;
    *) TEST_FAILURE_REASON="expected summary for missing file"; return 1 ;;
  esac
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

flags_bashisms_and_counts_failures() {
  prepare_checkbashisms_failure_stub || return 1
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  cat <<'SCRIPT' >"$workdir/bashism"
#!/bin/sh
[[ -n "${1-}" ]]
SCRIPT

  run_verify_posix "$workrel/bashism"
  assert_failure || return 1
  echo "$OUTPUT" | grep "^FAIL $workrel/bashism: contains bashisms (checkbashisms)$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected bashism message"; return 1; }
  echo "$OUTPUT" | grep "^  bashism detected$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected indented bashism output"; return 1; }
  summary=$(printf '%s\n' "$OUTPUT" | tail -n 1)
  case $summary in
    "1 of 1 scripts failed POSIX compliance.") : ;;
    *) TEST_FAILURE_REASON="expected bashism summary"; return 1 ;;
  esac
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

run_test_case "verify-posix is quiet for POSIX sh shebangs" check_is_quiet_for_posix
run_test_case "verify-posix warns when shebang is missing" warns_when_missing_shebang
run_test_case "verify-posix warns about bash shebangs" warns_for_bash_shebangs
run_test_case "verify-posix warns on empty shebang" warns_for_empty_shebang
run_test_case "verify-posix warns on env args" warns_for_env_arguments
run_test_case "verify-posix warns on direct bash path" warns_for_direct_bash_path
run_test_case "verify-posix accepts spaced sh shebang" accepts_space_before_sh
run_test_case "verify-posix reports missing targets" reports_missing_targets
run_test_case "verify-posix flags bashisms and counts failures" flags_bashisms_and_counts_failures

finish_tests
