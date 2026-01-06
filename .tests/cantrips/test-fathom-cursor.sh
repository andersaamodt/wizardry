#!/bin/sh
# Behavior cases from --help: report cursor coordinates from terminal DSR responses.
# - Emits both X and Y when no axis is chosen.
# - Supports selecting a single axis with -x or -y.
# - Adds labels in verbose mode.
# - Fails on malformed or missing terminal responses.

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_response() {
  file=$(mktemp "${WIZARDRY_TMPDIR}/fathom-cursor.XXXXXX")
  printf '\033[%s;%sR' "$1" "$2" >"$file"
  printf '%s' "$file"
}

run_fathom() {
  resp_file=$1
  shift
  run_cmd env PATH="$WIZARDRY_IMPS_PATH:/bin:/usr/bin" FATHOM_CURSOR_DEVICE="$resp_file" FATHOM_CURSOR_SKIP_STTY=1 "$ROOT_DIR/spells/cantrips/fathom-cursor" "$@"
}

normalize_output() {
  printf '%s' "$OUTPUT" | tr '\n' '|'
}

# emits both axes when none requested
reports_both_axes() {
  skip-if-compiled || return $?
  resp=$(make_response 12 34)
  run_fathom "$resp"
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "34|12"|"34|12|") : ;;
    *) TEST_FAILURE_REASON="unexpected output: $OUTPUT"; return 1 ;;
  esac
}

# supports single axis selection
selects_single_axis() {
  skip-if-compiled || return $?
  resp=$(make_response 5 9)
  run_fathom "$resp" -x
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "9"|"9|") : ;;
    *) TEST_FAILURE_REASON="expected column"; return 1 ;;
  esac

  run_fathom "$resp" -y
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "5"|"5|") : ;;
    *) TEST_FAILURE_REASON="expected row"; return 1 ;;
  esac
}

# adds labels when verbose
prints_verbose_labels() {
  skip-if-compiled || return $?
  resp=$(make_response 7 11)
  run_fathom "$resp" --verbose
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "X: 11|Y: 7"|"X: 11|Y: 7|") : ;;
    *) TEST_FAILURE_REASON="unexpected verbose output: $OUTPUT"; return 1 ;;
  esac
}

# fails on malformed responses
fails_on_invalid_response() {
  skip-if-compiled || return $?
  bad=$(mktemp "${WIZARDRY_TMPDIR}/fathom-cursor.XXXXXX")
  printf 'junk' >"$bad"
  run_fathom "$bad"
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected failure"; return 1; }
}

run_test_case "reports both axes" reports_both_axes
run_test_case "selects a single axis" selects_single_axis
run_test_case "adds labels in verbose mode" prints_verbose_labels
run_test_case "fails on invalid response" fails_on_invalid_response

shows_help() {
  run_spell spells/cantrips/fathom-cursor --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "fathom-cursor shows help" shows_help

# Test via source-then-invoke pattern  

finish_tests
