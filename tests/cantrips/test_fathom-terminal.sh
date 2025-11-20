#!/bin/sh
# Behavior cases from --help: report terminal dimensions via tput.
# - Reports both width and height by default.
# - Honors --width/--height flags for single-dimension queries.
# - Adds labels in verbose mode.
# - Exits with an error when terminfo queries fail.

set -eu
. "$(dirname "$0")/lib/test_common.sh"

make_stub_tput() {
  dir=$(mktemp -d "${WIZARDRY_TMPDIR}/tput-stub.XXXXXX")
  cat >"$dir/tput" <<'SCRIPT'
#!/bin/sh
case "$1" in
  cols) printf '120' ;;
  lines) printf '40' ;;
  *) exit 1 ;;
 esac
SCRIPT
  chmod +x "$dir/tput"
  printf '%s' "$dir"
}

run_fathom_terminal() {
  bin_dir=$1
  shift
  run_cmd env PATH="$bin_dir:$PATH" "$ROOT_DIR/spells/cantrips/fathom-terminal" "$@"
}

normalize_output() {
  printf '%s' "$OUTPUT" | tr '\n' '|'
}

# reports both dimensions by default
reports_width_and_height() {
  stub=$(make_stub_tput)
  run_fathom_terminal "$stub"
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "120|40"|"120|40|") : ;;
    *) TEST_FAILURE_REASON="unexpected output: $OUTPUT"; return 1 ;;
  esac
}

# selects a single dimension
selects_single_dimension() {
  stub=$(make_stub_tput)
  run_fathom_terminal "$stub" --width
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "120"|"120|") : ;;
    *) TEST_FAILURE_REASON="expected width"; return 1 ;;
  esac

  run_fathom_terminal "$stub" --height
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "40"|"40|") : ;;
    *) TEST_FAILURE_REASON="expected height"; return 1 ;;
  esac
}

# verbose adds labels
prints_verbose_labels() {
  stub=$(make_stub_tput)
  run_fathom_terminal "$stub" --verbose
  [ "$STATUS" -eq 0 ] || return 1
  case "$(normalize_output)" in
    "Width: 120|Height: 40"|"Width: 120|Height: 40|") : ;;
    *) TEST_FAILURE_REASON="unexpected verbose output: $OUTPUT"; return 1 ;;
  esac
}

# fails when terminfo queries fail
fails_without_tput() {
  empty=$(mktemp -d "${WIZARDRY_TMPDIR}/empty-path.XXXXXX")
  run_cmd env PATH="$empty" "$ROOT_DIR/spells/cantrips/fathom-terminal" --width
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected failure"; return 1; }
}

run_test_case "reports width and height" reports_width_and_height
run_test_case "selects a single dimension" selects_single_dimension
run_test_case "adds verbose labels" prints_verbose_labels
run_test_case "fails when tput is missing" fails_without_tput

finish_tests
