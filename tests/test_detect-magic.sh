#!/bin/sh
# Behavioral cases (derived from --help):
# - detect-magic lists files with attributes
# - detect-magic reports when nothing is enchanted

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

detect_magic_reports_found_files() {
  tmpdir=$(make_tempdir)
  stub="$tmpdir/read-magic"
  cat <<'STUB' >"$stub"
#!/bin/sh
case "$1" in
  a.txt) printf '%s\n' 'alpha' 'beta' ;;
  b.txt) : ;; # no attributes so should be skipped
  *) exit 1 ;;
esac
STUB
  chmod +x "$stub"

  printf 'content' >"$tmpdir/a.txt"
  printf 'other' >"$tmpdir/b.txt"

  NO_COLOR=1 DETECT_MAGIC_READ_MAGIC="$stub" run_spell_in_dir "$tmpdir" "spells/detect-magic"
  assert_success || return 1
  assert_output_contains "File" || return 1
  assert_output_contains "a.txt" || return 1
  case "$OUTPUT" in
    *b.txt*) TEST_FAILURE_REASON="file without attributes was listed"; return 1 ;;
  esac
}

detect_magic_handles_empty_rooms() {
  tmpdir=$(make_tempdir)
  NO_COLOR=1 run_spell_in_dir "$tmpdir" "spells/detect-magic"
  assert_success || return 1
  assert_output_contains "No enchantments reveal themselves today." || return 1
}

run_test_case "detect-magic lists files with attributes" detect_magic_reports_found_files
run_test_case "detect-magic reports when nothing is enchanted" detect_magic_handles_empty_rooms

finish_tests
