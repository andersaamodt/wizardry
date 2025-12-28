#!/bin/sh
# Test run-bwrap imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_uses_bwrap_bin() {
  # Create a stub that records invocation
  tmpdir=$(make_tempdir)
  printf '#!/bin/sh\necho "bwrap called"\n' > "$tmpdir/bwrap"
  chmod +x "$tmpdir/bwrap"
  
  BWRAP_BIN="$tmpdir/bwrap"
  BWRAP_VIA_SUDO=0
  output=$(run_bwrap --help 2>&1)
  
  echo "$output" | grep -q "bwrap called"
}

test_passes_args() {
  tmpdir=$(make_tempdir)
  printf '#!/bin/sh\necho "$@"\n' > "$tmpdir/bwrap"
  chmod +x "$tmpdir/bwrap"
  
  BWRAP_BIN="$tmpdir/bwrap"
  BWRAP_VIA_SUDO=0
  output=$(run_bwrap --help --version 2>&1)
  
  echo "$output" | grep -q "\-\-help"
}

run_test_case "run-bwrap uses BWRAP_BIN variable" test_uses_bwrap_bin
run_test_case "run-bwrap passes arguments" test_passes_args

finish_tests
