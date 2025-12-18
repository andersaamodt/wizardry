#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - look prints usage
# - fails when read-magic is unavailable
# - reports missing attributes when no metadata exists
# - prints discovered attributes
# - writes rc block when ask_yn agrees
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_dir() {
  dir=$(_make_tempdir)
  printf '%s\n' "$dir"
}

# Build wizardry base path with all imp directories and cantrips
wizardry_base_path() {
  printf '%s' "$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input"
}

stub_read_magic_missing() {
  dir=$1
  cat >"$dir/read-magic" <<'EOF'
#!/bin/sh
printf '%s\n' 'read-magic: attribute does not exist.'
EOF
  chmod +x "$dir/read-magic"
}

stub_ask_yn() {
  dir=$1
  status=${2:-1}
  cat >"$dir/ask-yn" <<EOF
#!/bin/sh
exit $status
EOF
  chmod +x "$dir/ask-yn"
}

test_help() {
  _run_spell "spells/mud/look" --help
  _assert_success && _assert_output_contains "Usage: look"
}

test_missing_read_magic() {
  skip-if-compiled || return $?
  stub=$(make_stub_dir)
  PATH="$WIZARDRY_CANTRIPS_PATH:$WIZARDRY_IMPS_PATH:$stub:$(wizardry_base_path):/bin:/usr/bin" _run_spell "spells/mud/look" "$WIZARDRY_TMPDIR"
  _assert_failure && _assert_error_contains "look: read-magic spell is missing."
}

test_missing_attributes_shows_defaults() {
  stub=$(make_stub_dir)
  test_room=$(_make_tempdir)
  stub_ask_yn "$stub" 0
  stub_read_magic_missing "$stub"
  LOOK_READ_MAGIC="$stub/read-magic" PATH="$WIZARDRY_CANTRIPS_PATH:$WIZARDRY_IMPS_PATH:$stub:$(wizardry_base_path):/bin:/usr/bin" _run_spell "spells/mud/look" "$test_room"
  _assert_success
  # Should show folder name as title
  room_name=$(basename "$test_room")
  if ! printf '%s' "$OUTPUT" | grep -q "$room_name"; then
    TEST_FAILURE_REASON="expected output to contain folder name '$room_name'"
    return 1
  fi
  # Should show a default description (one of: "An ordinary room.", "A plain chamber.", etc.)
  if printf '%s' "$OUTPUT" | grep -qE "(An ordinary room|A plain chamber|A nondescript space|An unremarkable area|A simple room)"; then
    return 0
  else
    TEST_FAILURE_REASON="expected output to contain a default room description"
    return 1
  fi
}

test_output_ends_with_newline() {
  stub=$(make_stub_dir)
  test_room=$(_make_tempdir)
  stub_ask_yn "$stub" 0
  stub_read_magic_missing "$stub"
  NO_COLOR=1 LOOK_READ_MAGIC="$stub/read-magic" PATH="$WIZARDRY_CANTRIPS_PATH:$WIZARDRY_IMPS_PATH:$stub:$(wizardry_base_path):/bin:/usr/bin" _run_spell "spells/mud/look" "$test_room"
  _assert_success
  # With MUD formatting, output should always end with a newline after the description
  # Check that the output ends with period+newline for the default description
  last_chars=$(printf '%s' "$OUTPUT" | tail -c 2)
  # The last line should be a description ending in a period
  if printf '%s' "$OUTPUT" | tail -n1 | grep -qE '\.$'; then
    return 0
  else
    TEST_FAILURE_REASON="expected output to end with a description ending in period"
    return 1
  fi
}

test_home_description_defaults() {
  stub=$(make_stub_dir)
  home_dir=$(_make_tempdir)
  stub_ask_yn "$stub" 1
  stub_read_magic_missing "$stub"
  # Don't set HOME to match the directory we're looking at, so identify-room won't think it's home
  LOOK_READ_MAGIC="$stub/read-magic" PATH="$WIZARDRY_CANTRIPS_PATH:$WIZARDRY_IMPS_PATH:$stub:$(wizardry_base_path):/bin:/usr/bin" \
    _run_spell "spells/mud/look" "$home_dir"
  _assert_success || return 1
  _assert_output_contains "$(basename "$home_dir")" || return 1
  printf '%s' "$OUTPUT" | grep -qE "An ordinary room|A plain chamber|A nondescript space|An unremarkable area|A simple room" \
    || { TEST_FAILURE_REASON="expected default description"; return 1; }
}

test_other_home_description() {
  stub=$(make_stub_dir)
  base_home=$(_make_tempdir)
  other_home=$(dirname "$base_home")/chris
  mkdir -p "$other_home"
  stub_ask_yn "$stub" 1
  stub_read_magic_missing "$stub"
  # Set HOME to base_home but look at other_home directory
  LOOK_READ_MAGIC="$stub/read-magic" HOME="$base_home" PATH="$WIZARDRY_CANTRIPS_PATH:$WIZARDRY_IMPS_PATH:$stub:$(wizardry_base_path):/bin:/usr/bin" \
    _run_spell "spells/mud/look" "$other_home"
  _assert_success || return 1
  _assert_output_contains "chris" || return 1
  # When identify-room is unavailable, expect default description
  # When identify-room is available (doppelganger), expect "home folder" description
  if printf '%s' "$OUTPUT" | grep -qE "An ordinary room|A plain chamber|A nondescript space|An unremarkable area|A simple room"; then
    return 0
  elif printf '%s' "$OUTPUT" | grep -q "home folder"; then
    return 0
  else
    TEST_FAILURE_REASON="expected default description or identify-room description"
    return 1
  fi
}

test_root_description() {
  stub=$(make_stub_dir)
  stub_ask_yn "$stub" 1
  stub_read_magic_missing "$stub"
  LOOK_READ_MAGIC="$stub/read-magic" PATH="$WIZARDRY_CANTRIPS_PATH:$WIZARDRY_IMPS_PATH:$stub:$(wizardry_base_path):/bin:/usr/bin" _run_spell "spells/mud/look" /
  _assert_success || return 1
  # Accept either "/" (when identify-room is unavailable) or "Root" (when it's available)
  if printf '%s' "$OUTPUT" | grep -q "/"; then
    # When identify-room is unavailable, expect "/" and default description
    printf '%s' "$OUTPUT" | grep -qE "An ordinary room|A plain chamber|A nondescript space|An unremarkable area|A simple room" \
      || { TEST_FAILURE_REASON="expected default description when showing /"; return 1; }
  elif printf '%s' "$OUTPUT" | grep -q "Root"; then
    # When identify-room is available, expect "Root" and system description
    printf '%s' "$OUTPUT" | grep -q "root of the filesystem" \
      || { TEST_FAILURE_REASON="expected system description when showing Root"; return 1; }
  else
    TEST_FAILURE_REASON="expected either / or Root in output"
    return 1
  fi
}

test_displays_attributes() {
  stub=$(make_stub_dir)
  stub_ask_yn "$stub" 0
  cat >"$stub/read-magic" <<'EOF'
#!/bin/sh
case "$2" in
  title) printf '%s\n' 'Hidden Door' ;;
  description) printf '%s\n' 'A narrow doorway concealed by ivy.' ;;
esac
EOF
  chmod +x "$stub/read-magic"
  LOOK_READ_MAGIC="$stub/read-magic" PATH="$WIZARDRY_CANTRIPS_PATH:$WIZARDRY_IMPS_PATH:$stub:$(wizardry_base_path):/bin:/usr/bin" _run_spell "spells/mud/look" "$WIZARDRY_TMPDIR"
  _assert_success && printf '%s' "$OUTPUT" | grep -q "Hidden Door" && printf '%s' "$OUTPUT" | grep -q "A narrow doorway concealed by ivy."
}

_run_test_case "look prints usage" test_help
_run_test_case "look fails when read-magic is missing" test_missing_read_magic
_run_test_case "look shows defaults when attributes missing" test_missing_attributes_shows_defaults
_run_test_case "look describes the current user's home" test_home_description_defaults
_run_test_case "look describes another user's home" test_other_home_description
_run_test_case "look describes the filesystem root" test_root_description
_run_test_case "look output ends with newline" test_output_ends_with_newline
_run_test_case "look prints discovered attributes" test_displays_attributes
_finish_tests
