#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

parse_skips_functions_on_fallback() {
  marker="$WIZARDRY_TMPDIR/parse-function-marker"
  rm -f "$marker"

  run_cmd sh -c '
    marker=$1
    gloss_calls=0
    glossfunc() { gloss_calls=$((gloss_calls + 1)); parse glossfunc; }
    trap "printf '\''%s\n'\'' \"$gloss_calls\" >\"$marker\"" EXIT
    set -- glossfunc
    . "$ROOT_DIR/spells/.imps/lex/parse"
  ' sh "$marker"

  if [ ! -f "$marker" ]; then
    TEST_FAILURE_REASON="parse executed via exec path (EXIT trap skipped)"
    return 1
  fi

  if [ "$STATUS" -ne 127 ]; then
    TEST_FAILURE_REASON="expected status 127 when function fallback is skipped (got $STATUS)"
    return 1
  fi

  calls=$(cat "$marker")
  if [ "$calls" -ne 0 ]; then
    TEST_FAILURE_REASON="gloss function should not execute when parse skips functions (ran $calls times)"
    return 1
  fi
}

run_test_case "parse skips functions on fallback" parse_skips_functions_on_fallback

finish_tests
