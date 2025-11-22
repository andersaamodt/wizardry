#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/../../test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/../../test_common.sh"

prepare_checkbashisms_stub() {
  stub_dir=$(mktemp -d "${WIZARDRY_TMPDIR}/checkbashisms.menu.XXXXXX") || return 1
  cat <<'SCRIPT' >"$stub_dir/checkbashisms"
#!/bin/sh
exit 0
SCRIPT
  chmod +x "$stub_dir/checkbashisms"
  PATH="$stub_dir:$PATH"
  CHECKBASHISMS="$stub_dir/checkbashisms"
  export CHECKBASHISMS PATH
}

runs_from_system_menu() {
  prepare_checkbashisms_stub || return 1
  run_cmd "$ROOT_DIR/spells/menu/system/verify-posix"
  assert_success || return 1
  [ -z "${OUTPUT}" ] || { TEST_FAILURE_REASON="expected no stdout"; return 1; }
  [ -z "${ERROR}" ] || { TEST_FAILURE_REASON="expected no stderr"; return 1; }
}

run_test_case "system verify-posix delegates to root spell" runs_from_system_menu

finish_tests
