#!/bin/sh
# Test run-macos-sandbox imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_uses_sandbox_exec_bin() {
  # Create a stub that records invocation
  tmpdir=$(make_tempdir)
  printf '#!/bin/sh\necho "sandbox-exec called"\n' > "$tmpdir/sandbox-exec"
  chmod +x "$tmpdir/sandbox-exec"
  
  SANDBOX_EXEC_BIN="$tmpdir/sandbox-exec"
  output=$(run_macos_sandbox echo hello 2>&1)
  
  echo "$output" | grep -q "sandbox-exec called"
}

test_passes_command() {
  tmpdir=$(make_tempdir)
  printf '#!/bin/sh\nshift; shift; "$@"\n' > "$tmpdir/sandbox-exec"
  chmod +x "$tmpdir/sandbox-exec"
  
  SANDBOX_EXEC_BIN="$tmpdir/sandbox-exec"
  output=$(run_macos_sandbox echo hello 2>&1)
  
  echo "$output" | grep -q "hello"
}

run_test_case "run-macos-sandbox uses SANDBOX_EXEC_BIN" test_uses_sandbox_exec_bin
run_test_case "run-macos-sandbox passes command" test_passes_command

finish_tests
