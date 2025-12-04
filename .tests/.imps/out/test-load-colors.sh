#!/bin/sh
# Tests for the 'load-colors' imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_load_colors_help() {
  run_cmd "$ROOT_DIR/spells/.imps/out/load-colors" --help
  assert_success
  assert_output_contains "Usage: load-colors"
}

test_load_colors_sources_colors_when_available() {
  tmp=$(make_tempdir)
  cat >"$tmp/colors" <<'SH'
#!/bin/sh
RESET="[reset]"
CYAN="[cyan]"
GREY="[grey]"
WIZARDRY_COLORS_AVAILABLE=1
SH
  chmod +x "$tmp/colors"
  run_cmd sh -c "PATH=\"$tmp:\$PATH\"; . '$ROOT_DIR/spells/.imps/out/load-colors'; printf 'CYAN=%s' \"\$CYAN\""
  assert_success
  assert_output_contains "CYAN=[cyan]"
}

test_load_colors_sets_empty_when_missing() {
  tmp=$(make_tempdir)
  # No colors script in PATH
  run_cmd sh -c "PATH=\"$tmp\"; . '$ROOT_DIR/spells/.imps/out/load-colors'; printf 'CYAN=%s AVAILABLE=%s' \"\$CYAN\" \"\$WIZARDRY_COLORS_AVAILABLE\""
  assert_success
  assert_output_contains "CYAN= AVAILABLE=0"
}

test_load_colors_defines_fallback_variables() {
  tmp=$(make_tempdir)
  # No colors script - verify all expected variables are defined (as empty)
  run_cmd sh -c "set -u; PATH=\"$tmp\"; . '$ROOT_DIR/spells/.imps/out/load-colors'; printf '%s%s%s%s%s' \"\$RESET\" \"\$CYAN\" \"\$GREY\" \"\$GREEN\" \"\$YELLOW\""
  assert_success
}

run_test_case "load-colors --help shows usage" test_load_colors_help
run_test_case "load-colors sources colors when available" test_load_colors_sources_colors_when_available
run_test_case "load-colors sets empty when colors missing" test_load_colors_sets_empty_when_missing
run_test_case "load-colors defines fallback variables for set -u" test_load_colors_defines_fallback_variables

finish_tests
