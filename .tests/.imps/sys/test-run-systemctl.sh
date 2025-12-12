#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
# Normalize double slashes (macOS TMPDIR issue)
test_root=$(printf '%s' "$test_root" | sed 's|//|/|g')
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

test_runs_systemctl_directly_as_root() {
  skip-if-not-root || return $?
  run_spell "spells/.imps/sys/run-systemctl" "status" "sshd"
  assert_success
}

test_runs_systemctl_with_sudo() {
  skip-if-root || return $?
  tmpdir=$(make_tempdir)
  
  # Create sudo stub that logs the command
  cat >"$tmpdir/sudo" <<'STUB'
#!/bin/sh
printf 'sudo %s\n' "$*" >&2
exec "$@"
STUB
  chmod +x "$tmpdir/sudo"
  
  # Create systemctl stub
  cat >"$tmpdir/systemctl" <<'STUB'
#!/bin/sh
printf 'systemctl %s\n' "$*"
exit 0
STUB
  chmod +x "$tmpdir/systemctl"
  
  PATH="$tmpdir:$PATH" run_spell "spells/.imps/sys/run-systemctl" "list-units"
  assert_success
  assert_error_contains "sudo"
}

test_passes_arguments_correctly() {
  tmpdir=$(make_tempdir)
  
  cat >"$tmpdir/systemctl" <<'STUB'
#!/bin/sh
printf 'args: %s\n' "$*"
exit 0
STUB
  chmod +x "$tmpdir/systemctl"
  
  cat >"$tmpdir/sudo" <<'STUB'
#!/bin/sh
exec "$@"
STUB
  chmod +x "$tmpdir/sudo"
  
  PATH="$tmpdir:$PATH" run_spell "spells/.imps/sys/run-systemctl" "status" "myservice.service"
  assert_success
  assert_output_contains "args: status myservice.service"
}

run_test_case "run-systemctl works as root" test_runs_systemctl_directly_as_root
run_test_case "run-systemctl uses sudo when needed" test_runs_systemctl_with_sudo
run_test_case "run-systemctl passes arguments" test_passes_arguments_correctly
finish_tests
