#!/bin/sh
# Behavioral cases:
# - check_posix_bash is quiet for POSIX sh shebangs
# - warns when shebangs are missing, empty, or bash-oriented
# - tolerates missing targets without crashing

set -eu

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

make_repo_tempdir() {
  rel_dir="tests/tmp.posix.$$.${RANDOM:-0}"
  abs_dir="$ROOT_DIR/$rel_dir"
  mkdir -p "$abs_dir"
  printf '%s\n' "$rel_dir"
}

run_check_posix_bash() {
  COVERAGE_TARGETS="$1" run_cmd "$ROOT_DIR/tests/check_posix_bash.sh"
}

check_is_quiet_for_posix() {
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

  run_check_posix_bash "$workrel/direct $workrel/env"
  assert_success || return 1
  [ -z "${OUTPUT}" ] || { TEST_FAILURE_REASON="expected no stdout"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

warns_when_missing_shebang() {
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  cat <<'SCRIPT' >"$workdir/nameless"
echo 'no interpreter'
SCRIPT

  run_check_posix_bash "$workrel/nameless"
  assert_success || return 1
  [ -z "${OUTPUT}" ] || { TEST_FAILURE_REASON="unexpected stdout"; return 1; }
  assert_error_contains "does not declare a shebang" || return 1
}

warns_for_bash_shebangs() {
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  cat <<'SCRIPT' >"$workdir/bashy"
#!/usr/bin/env bash
echo 'bash heavy'
SCRIPT

  run_check_posix_bash "$workrel/bashy"
  assert_success || return 1
  assert_error_contains "rewrite it for plain POSIX Bash" || return 1
}

warns_for_empty_shebang() {
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  printf '#!\n' >"$workdir/empty"

  run_check_posix_bash "$workrel/empty"
  assert_success || return 1
  assert_error_contains "has an empty shebang" || return 1
}

warns_for_env_arguments() {
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  cat <<'SCRIPT' >"$workdir/argful"
#!/usr/bin/env bash -l
echo argful
SCRIPT

  run_check_posix_bash "$workrel/argful"
  assert_success || return 1
  assert_error_contains "rewrite it for plain POSIX Bash" || return 1
}

warns_for_direct_bash_path() {
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  cat <<'SCRIPT' >"$workdir/direct_bash"
#!/bin/bash
echo direct
SCRIPT

  run_check_posix_bash "$workrel/direct_bash"
  assert_success || return 1
  assert_error_contains "rewrite it for plain POSIX Bash" || return 1
}

accepts_space_before_sh() {
  workrel=$(make_repo_tempdir)
  workdir="$ROOT_DIR/$workrel"
  cat <<'SCRIPT' >"$workdir/spaced"
#! /bin/sh
echo ok
SCRIPT

  run_check_posix_bash "$workrel/spaced"
  assert_success || return 1
  [ -z "${OUTPUT}" ] || { TEST_FAILURE_REASON="expected no stdout"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

ignores_missing_targets() {
  run_check_posix_bash "tests/tmp.posix.missing"
  assert_success || return 1
  [ -z "${OUTPUT}" ] || { TEST_FAILURE_REASON="unexpected stdout"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="unexpected stderr"; return 1; }
}

run_test_case "check_posix_bash is quiet for POSIX sh shebangs" check_is_quiet_for_posix
run_test_case "check_posix_bash warns when shebang is missing" warns_when_missing_shebang
run_test_case "check_posix_bash warns about bash shebangs" warns_for_bash_shebangs
run_test_case "check_posix_bash warns on empty shebang" warns_for_empty_shebang
run_test_case "check_posix_bash warns on env args" warns_for_env_arguments
run_test_case "check_posix_bash warns on direct bash path" warns_for_direct_bash_path
run_test_case "check_posix_bash accepts spaced sh shebang" accepts_space_before_sh
run_test_case "check_posix_bash ignores missing targets" ignores_missing_targets

finish_tests
