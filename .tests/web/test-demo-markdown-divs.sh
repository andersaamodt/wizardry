#!/bin/sh
# Tests for demo markdown div blocks

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_demo_markdown_uses_fenced_divs() {
  graphics_file="$ROOT_DIR/.templates/demo/pages/graphics-media.md"
  hardware_file="$ROOT_DIR/.templates/demo/pages/hardware.md"
  ssh_auth_file="$ROOT_DIR/.templates/blog/pages/ssh-auth.md"

  if ! grep -q "::: {.demo-box}" "$graphics_file"; then
    TEST_FAILURE_REASON="graphics-media demo box not fenced"
    return 1
  fi
  if ! grep -q "::: {.demo-box}" "$hardware_file"; then
    TEST_FAILURE_REASON="hardware demo box not fenced"
    return 1
  fi
  if grep -q "<div class=\"demo-box\">" "$ssh_auth_file"; then
    TEST_FAILURE_REASON="ssh-auth still uses HTML demo-box"
    return 1
  fi
}

run_test_case "demo markdown uses fenced divs" test_demo_markdown_uses_fenced_divs

finish_tests
