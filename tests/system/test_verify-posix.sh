#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

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

runs_quietly_across_all_spells() {
  prepare_checkbashisms_stub || return 1
  run_cmd "$ROOT_DIR/spells/system/verify-posix"
  assert_success || return 1
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
  rel_tmp="tests/tmp.verify.$$.${RANDOM:-0}"
  abs_tmp="$ROOT_DIR/$rel_tmp"
  mkdir -p "$(dirname "$abs_tmp")"
  cat <<'SCRIPT' >"$abs_tmp"
#!/bin/sh
echo ok
SCRIPT

  run_cmd "$ROOT_DIR/spells/system/verify-posix" "$rel_tmp"
  assert_success || return 1
  echo "$OUTPUT" | grep "^PASS $rel_tmp$" >/dev/null 2>&1 || { TEST_FAILURE_REASON="expected PASS line for target"; return 1; }
  summary=$(printf '%s\n' "$OUTPUT" | tail -n 1)
  case $summary in
    "All 1 scripts are POSIX-compliant.") : ;;
    *) TEST_FAILURE_REASON="expected summary for single target"; return 1 ;;
  esac
  echo "$OUTPUT" | grep '^FAIL ' >/dev/null 2>&1 && { TEST_FAILURE_REASON="expected no FAIL lines"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

run_test_case "verify-posix scans all spells by default" runs_quietly_across_all_spells
run_test_case "verify-posix accepts explicit targets" accepts_individual_targets

finish_tests
