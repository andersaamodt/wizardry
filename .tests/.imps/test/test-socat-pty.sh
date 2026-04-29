#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_requires_command() {
  run_cmd "$ROOT_DIR/spells/.imps/test/socat-pty"
  assert_failure || return 1
  assert_error_contains "command required" || return 1
}

test_requires_socat() {
  # Only run if socat is not installed
  if command -v socat >/dev/null 2>&1; then
    test_skip "requires socat to be missing"
    return 0
  fi
  
  run_cmd "$ROOT_DIR/spells/.imps/test/socat-pty" echo "test"
  assert_failure || return 1
  assert_error_contains "socat not found" || return 1
}

test_preserves_command_argument_boundaries() {
  tmpdir=$(make_tempdir)
  stubdir=$tmpdir/bin
  mkdir -p "$stubdir"

  {
    printf '%s\n' '#!/bin/sh'
    printf '%s\n' 'shift'
    printf '%s\n' '"$@"'
  } > "$stubdir/timeout"
  chmod +x "$stubdir/timeout"

  {
    printf '%s\n' '#!/bin/sh'
    printf '%s\n' 'address=${1-}'
    printf '%s\n' 'case "$address" in'
    printf '%s\n' '  EXEC:*,pty,setsid,ctty,stderr)'
    printf '%s\n' '    script=${address#EXEC:}'
    printf '%s\n' '    script=${script%,pty,setsid,ctty,stderr}'
    printf '%s\n' '    "$script"'
    printf '%s\n' '    ;;'
    printf '%s\n' '  *)'
    printf '%s\n' '    printf "%s\n" "unexpected socat address: $address"'
    printf '%s\n' '    exit 1'
    printf '%s\n' '    ;;'
    printf '%s\n' 'esac'
  } > "$stubdir/socat"
  chmod +x "$stubdir/socat"

  command_path="$tmpdir/command with space"
  {
    printf '%s\n' '#!/bin/sh'
    printf '%s\n' 'printf "%s\n" "cmd=$0"'
    printf '%s\n' 'printf "%s\n" "arg1=${1-}"'
  } > "$command_path"
  chmod +x "$command_path"

  PATH="$stubdir:$PATH" "$ROOT_DIR/spells/.imps/test/socat-pty" "$command_path" "arg with space" > "$tmpdir/output"
  output=$(cat "$tmpdir/output")

  printf '%s\n' "$output" | grep -Fx "cmd=$command_path" >/dev/null || {
    TEST_FAILURE_REASON=$output
    return 1
  }
  printf '%s\n' "$output" | grep -Fx "arg1=arg with space" >/dev/null || {
    TEST_FAILURE_REASON=$output
    return 1
  }
}

run_test_case "socat-pty requires command" test_requires_command
run_test_case "socat-pty requires socat installed" test_requires_socat
run_test_case "socat-pty preserves command argument boundaries" test_preserves_command_argument_boundaries
finish_tests
