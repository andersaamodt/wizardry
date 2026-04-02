#!/bin/sh
# Behavioral cases:
# - say-interactive shows usage
# - say-interactive delegates non-empty input to say
# - say-interactive cancels cleanly on empty input

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/mud/say-interactive" --help
  assert_success || return 1
  assert_output_contains "Usage: say-interactive" || return 1
}

test_delegates_to_say() {
  tmp=$(make_tempdir)
  cat >"$tmp/say" <<SH
#!/bin/sh
printf '%s\n' "\$*" >"$tmp/log"
SH
  chmod +x "$tmp/say"

  if env PATH="$tmp:$PATH" ASK_CANTRIP_INPUT=stdin \
    sh -c "printf 'Hello from menu\\n' | \"$ROOT_DIR/spells/mud/say-interactive\"" \
    >"$tmp/out" 2>"$tmp/err"; then
    :
  else
    TEST_FAILURE_REASON="say-interactive should succeed on non-empty input"
    return 1
  fi
  assert_file_contains "$tmp/log" "Hello from menu"
}

test_blank_input_cancels() {
  tmp=$(make_tempdir)
  cat >"$tmp/say" <<SH
#!/bin/sh
printf '%s\n' "\$*" >"$tmp/log"
SH
  chmod +x "$tmp/say"

  if env PATH="$tmp:$PATH" ASK_CANTRIP_INPUT=stdin \
    sh -c "printf '\\n' | \"$ROOT_DIR/spells/mud/say-interactive\"" \
    >"$tmp/out" 2>"$tmp/err"; then
    :
  else
    TEST_FAILURE_REASON="say-interactive should cancel cleanly on empty input"
    return 1
  fi
  if ! grep -q "cancelled" "$tmp/err"; then
    TEST_FAILURE_REASON="expected cancellation message"
    return 1
  fi
  assert_path_missing "$tmp/log"
}

run_test_case "say-interactive shows usage" test_help
run_test_case "say-interactive delegates to say" test_delegates_to_say
run_test_case "say-interactive cancels on empty input" test_blank_input_cancels

finish_tests
