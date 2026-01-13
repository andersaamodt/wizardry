#!/bin/sh
# Test write-apt-stub imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  [ -x "$fixture/bin/apt-get" ]
}

test_stub_logs_invocations() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  export APT_LOG="$fixture/log/apt.log"
  "$fixture/bin/apt-get" install vim
  [ -f "$APT_LOG" ] && grep -q "install vim" "$APT_LOG"
}

run_test_case "write-apt-stub creates executable" test_creates_stub
run_test_case "write-apt-stub logs invocations" test_stub_logs_invocations

finish_tests
