#!/bin/sh
# Behavior cases for fathom-terminal:
# - Uses direct tty sizing when available.
# - Falls back to tput when direct tty sizing is unavailable.

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

fathom_terminal_prefers_stty_size() {
  tmpdir=$(make_tempdir)

  cat >"$tmpdir/stty" <<'SH'
#!/bin/sh
set -eu
case "${1-}" in
  size) printf '24 80\n' ;;
  *) exit 1 ;;
esac
SH
  chmod +x "$tmpdir/stty"

  cat >"$tmpdir/tput" <<'SH'
#!/bin/sh
set -eu
exit 1
SH
  chmod +x "$tmpdir/tput"

  run_cmd env \
    PATH="$tmpdir:$PATH" \
    FATHOM_TERMINAL_DEVICE=/dev/null \
    "$ROOT_DIR/spells/.imps/menu/fathom-terminal" --height
  assert_success || return 1
  [ "$OUTPUT" = "24" ] || {
    TEST_FAILURE_REASON="expected height from stty size, got: $OUTPUT"
    return 1
  }
}

fathom_terminal_falls_back_to_tput() {
  tmpdir=$(make_tempdir)

  cat >"$tmpdir/stty" <<'SH'
#!/bin/sh
set -eu
exit 1
SH
  chmod +x "$tmpdir/stty"

  cat >"$tmpdir/tput" <<'SH'
#!/bin/sh
set -eu
case "${1-}" in
  cols) printf '90\n' ;;
  lines) printf '33\n' ;;
  *) exit 1 ;;
esac
SH
  chmod +x "$tmpdir/tput"

  run_cmd env \
    PATH="$tmpdir:$PATH" \
    FATHOM_TERMINAL_DEVICE=/dev/null \
    "$ROOT_DIR/spells/.imps/menu/fathom-terminal" --width
  assert_success || return 1
  [ "$OUTPUT" = "90" ] || {
    TEST_FAILURE_REASON="expected width from tput fallback, got: $OUTPUT"
    return 1
  }
}

run_test_case "fathom-terminal prefers stty size" fathom_terminal_prefers_stty_size
run_test_case "fathom-terminal falls back to tput" fathom_terminal_falls_back_to_tput

finish_tests
