#!/bin/sh
# Behavioral cases:
# - colors should keep ANSI palette when TERM is capable but tput is inconclusive

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

colors_keep_palette_when_tput_is_inconclusive() {
  tmpdir=$(make_tempdir)

  cat >"$tmpdir/tput" <<'SH'
#!/bin/sh
set -eu
exit 1
SH
  chmod +x "$tmpdir/tput"

  OUTPUT=$(TERM=xterm PATH="$tmpdir:$PATH" sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'avail:%s heading:%s\\n' \"\$WIZARDRY_COLORS_AVAILABLE\" \"\$THEME_HEADING\"")
  STATUS=$?
  export STATUS
  assert_success || return 1
  case "$OUTPUT" in
    avail:1\ heading:*) : ;;
    *)
      TEST_FAILURE_REASON="expected palette to stay enabled when tput is inconclusive, got: $OUTPUT"
      return 1
      ;;
  esac
}

run_test_case "colors keep palette when tput is inconclusive" colors_keep_palette_when_tput_is_inconclusive

finish_tests
