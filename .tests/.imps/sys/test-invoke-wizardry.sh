#!/bin/sh

WIZARDRY_TEST_SKIP_INVOKE=1
export WIZARDRY_TEST_SKIP_INVOKE

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

invoke_wizardry_keeps_termux_bin_ahead_of_baseline_path() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/home" "$tmpdir/spellbook"

  run_cmd env HOME="$tmpdir/home" SPELLBOOK_DIR="$tmpdir/spellbook" \
    WIZARDRY_DIR="$ROOT_DIR" WIZARDRY_TEST_HELPERS_ONLY=1 \
    PATH="/data/data/com.termux/files/usr/bin" \
    /bin/sh -c '. "$1/spells/.imps/sys/invoke-wizardry"; printf "%s\n" "$PATH"' sh "$ROOT_DIR"

  assert_success || return 1
  case "$OUTPUT" in
    *"/data/data/com.termux/files/usr/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="expected Termux bin to stay ahead of baseline PATH"
      return 1
      ;;
  esac
}

run_test_case "invoke-wizardry keeps Termux bin ahead of baseline PATH" \
  invoke_wizardry_keeps_termux_bin_ahead_of_baseline_path

finish_tests
