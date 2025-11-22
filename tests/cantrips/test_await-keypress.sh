#!/bin/sh
# Behavior cases from --help: read one key and name it; handles escape sequences and buffered bytes.
# - Emits descriptive names for control keys like Enter.
# - Decodes literal text from provided byte codes.
# - Buffers incomplete escape sequences for the next invocation.
# - Flushes buffers when a complete key is decoded.

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

await_with_buffer() {
  buffer=$1
  shift
  run_cmd env \
    AWAIT_KEYPRESS_BUFFER_FILE="$buffer" \
    AWAIT_KEYPRESS_SKIP_STTY=1 \
    AWAIT_KEYPRESS_DEVICE=/dev/null \
    "$ROOT_DIR/spells/cantrips/await-keypress" "$@"
}

# prints enter for newline code
prints_enter_for_newline() {
  buffer_file=$(mktemp "${WIZARDRY_TMPDIR}/await-buffer.XXXXXX")
  printf '10\n' >"$buffer_file"
  await_with_buffer "$buffer_file"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "enter" ] || { TEST_FAILURE_REASON="expected enter but got $OUTPUT"; return 1; }
  [ ! -e "$buffer_file" ] || { TEST_FAILURE_REASON="buffer file should be cleared"; return 1; }
}

# decodes literal text from buffered byte codes
prints_literal_text() {
  buffer_file=$(mktemp "${WIZARDRY_TMPDIR}/await-buffer.XXXXXX")
  printf '97 98\n' >"$buffer_file"
  await_with_buffer "$buffer_file"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "ab" ] || { TEST_FAILURE_REASON="expected ab but got $OUTPUT"; return 1; }
}

# buffers partial escape sequences for later completion
buffers_partial_escape_sequence() {
  partial_file=$(mktemp "${WIZARDRY_TMPDIR}/await-buffer.XXXXXX")
  printf '27 91\n' >"$partial_file"
  await_with_buffer "$partial_file"
  [ "$STATUS" -eq 0 ] || return 1
  [ -s "$partial_file" ] || { TEST_FAILURE_REASON="expected partial codes to remain"; return 1; }
  [ "$(cat "$partial_file")" = '27 91' ] || { TEST_FAILURE_REASON="unexpected buffered codes"; return 1; }

  printf '27 91 68\n' >"$partial_file"
  await_with_buffer "$partial_file"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = 'left' ] || { TEST_FAILURE_REASON="expected left but got $OUTPUT"; return 1; }
  [ ! -s "$partial_file" ] || { TEST_FAILURE_REASON="buffer should be cleared after completion"; return 1; }
}

run_test_case "prints enter for newline" prints_enter_for_newline
run_test_case "prints literal text from bytes" prints_literal_text
run_test_case "buffers partial escape sequence until complete" buffers_partial_escape_sequence

finish_tests
