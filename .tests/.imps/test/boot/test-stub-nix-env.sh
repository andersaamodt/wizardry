#!/bin/sh
# Test stub-nix-env imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  fixture=$(_make_fixture)
  _stub_nix_env "$fixture"
  [ -x "$fixture/bin/nix-env" ]
}

test_stub_logs_invocations() {
  fixture=$(_make_fixture)
  _stub_nix_env "$fixture"
  export NIX_ENV_LOG="$fixture/log/nix-env.log"
  "$fixture/bin/nix-env" -iA nixpkgs.git
  [ -f "$NIX_ENV_LOG" ] && grep -q "nix-env -iA nixpkgs.git" "$NIX_ENV_LOG"
}

_run_test_case "stub-nix-env creates executable" test_creates_stub
_run_test_case "stub-nix-env logs invocations" test_stub_logs_invocations

_finish_tests
