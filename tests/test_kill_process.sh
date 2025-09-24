#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"
source "$(dirname "$0")/lib/stub_helpers.sh"

stub_dir=$(make_temp_dir)
mkdir -p "$stub_dir"
cat <<'PS' >"$stub_dir/ps"
#!/usr/bin/env bash
if [ "$1" = "-ax" ]; then
  cat <<'OUT'
  PID TTY      STAT   TIME COMMAND
 101 ?        S      0:00 first
 202 ?        S      0:00 second
OUT
else
  /bin/ps "$@"
fi
PS
chmod +x "$stub_dir/ps"

kill_log="$stub_dir/kill.log"
cat <<'KILL' >"$stub_dir/kill"
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${KILL_LOG}" 2>/dev/null || true
exit 0
KILL
chmod +x "$stub_dir/kill"

BASE_PATH=$PATH
system_stubs=$(wizardry_install_systemd_stubs)

# Approve the termination of the second process.
choice_file=$(mktemp "$TEST_TMPDIR/input.XXXXXX")
printf '2\n' >"$choice_file"
export KILL_LOG="$kill_log"
export ASK_YN_STUB_RESPONSE=Y
exec 10<&0
exec <"$choice_file"
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$stub_dir" "$system_stubs" "$BASE_PATH")" run_script "spells/kill-process"
exec <&10
exec 10<&-
unset ASK_YN_STUB_RESPONSE
expect_exit_code 0
expect_in_output "List of running processes:" "$RUN_STDOUT"
expect_in_output "Process 202 (second) has been killed." "$RUN_STDOUT"
expect_eq "kill 202" "$(cat "$kill_log")"

# Decline to terminate the first process.
printf '' >"$kill_log"
choice_file=$(mktemp "$TEST_TMPDIR/input.XXXXXX")
printf '1\n' >"$choice_file"
export KILL_LOG="$kill_log"
export ASK_YN_STUB_RESPONSE=n
exec 11<&0
exec <"$choice_file"
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$stub_dir" "$system_stubs" "$BASE_PATH")" run_script "spells/kill-process"
exec <&11
exec 11<&-
unset ASK_YN_STUB_RESPONSE
expect_exit_code 0
expect_not_in_output "has been killed" "$RUN_STDOUT"
expect_eq "" "$(cat "$kill_log")"

assert_all_expectations_met
