#!/bin/sh
# Test run-both-patterns imp (deprecated but retained for compatibility)

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_exists() {
  # Verify the imp exists and is executable
  if [ -x "$ROOT_DIR/spells/.imps/test/boot/run-both-patterns" ]; then
    return 0
  fi
  return 1
}

test_has_shebang() {
  # Verify it's a valid shell script
  if head -n 1 "$ROOT_DIR/spells/.imps/test/boot/run-both-patterns" | grep -q "^#!/bin/sh"; then
    return 0
  fi
  return 1
}

test_has_description() {
  # Verify it has documentation
  if grep -q "DEPRECATED" "$ROOT_DIR/spells/.imps/test/boot/run-both-patterns"; then
    return 0
  fi
  return 1
}

run_test_case "run-both-patterns exists and is executable" test_exists
run_test_case "run-both-patterns has valid shebang" test_has_shebang
run_test_case "run-both-patterns is documented as deprecated" test_has_description

finish_tests
