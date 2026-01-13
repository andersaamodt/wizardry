#!/bin/sh
# Test write-pkgin-stub imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  fixture=$(make_fixture)
  write_pkgin_stub "$fixture"
  [ -x "$fixture/opt/pkg/bin/pkgin" ]
}

test_stub_logs_install() {
  fixture=$(make_fixture)
  write_pkgin_stub "$fixture"
  export PKGIN_LOG="$fixture/log/pkgin.log"
  "$fixture/opt/pkg/bin/pkgin" -y install vim
  [ -f "$PKGIN_LOG" ] && grep -q "install vim" "$PKGIN_LOG"
}

test_stub_logs_remove() {
  fixture=$(make_fixture)
  write_pkgin_stub "$fixture"
  export PKGIN_LOG="$fixture/log/pkgin.log"
  "$fixture/opt/pkg/bin/pkgin" -y remove vim
  [ -f "$PKGIN_LOG" ] && grep -q "remove vim" "$PKGIN_LOG"
}

run_test_case "write-pkgin-stub creates executable" test_creates_stub
run_test_case "write-pkgin-stub logs install" test_stub_logs_install
run_test_case "write-pkgin-stub logs remove" test_stub_logs_remove

finish_tests
