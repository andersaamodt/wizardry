#!/bin/sh
# Behavioral cases (derived from --help):
# - update-wizardry prints usage
# - update-wizardry requires git
# - update-wizardry uses WIZARDRY_DIR when provided
# - update-wizardry rejects non-existent WIZARDRY_DIR
# - update-wizardry rejects non-repo WIZARDRY_DIR
# - update-wizardry auto-detects the repo and pulls
# - update-wizardry fails when detection fails
# - update-wizardry propagates git pull failures

set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


make_stub_dir() {
  dir=$(make_tempdir)
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

test_help() {
  run_spell "spells/system/update-wizardry" --help
  assert_success && assert_output_contains "Usage: update-wizardry"
}

test_requires_git() {
  stub_dir=$(make_stub_dir)
  require_log="$stub_dir/require.log"

  cat >"$stub_dir/require-command" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" >>"$REQUIRE_LOG"
printf '%s\n' "$2" >&2
exit 1
STUB
  chmod +x "$stub_dir/require-command"

  REQUIRE_LOG="$require_log" REQUIRE_COMMAND="$stub_dir/require-command" run_spell "spells/system/update-wizardry"
  assert_failure && assert_error_contains "Update wizardry needs 'git'"
  assert_file_contains "$require_log" "git"
}

test_uses_env_directory() {
  stub_dir=$(make_stub_dir)
  wizard_dir=$(make_tempdir)
  git_log="$stub_dir/git.log"

  cat >"$stub_dir/git" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$GIT_LOG"
if [ "$1" = "-C" ] && [ "$3" = "pull" ]; then
  exit 0
fi
if [ "$2" = "rev-parse" ]; then
  exit 0
fi
exit 0
STUB
  chmod +x "$stub_dir/git"

  cat >"$stub_dir/require-command" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/require-command"

  PATH="$stub_dir:$PATH" REQUIRE_COMMAND="$stub_dir/require-command" GIT_LOG="$git_log" WIZARDRY_DIR="$wizard_dir" \
    run_spell "spells/system/update-wizardry"
  assert_success
  assert_file_contains "$git_log" "-C $wizard_dir pull --ff-only"
}

test_rejects_missing_env_directory() {
  stub_dir=$(make_stub_dir)
  git_log="$stub_dir/git.log"

  cat >"$stub_dir/git" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$GIT_LOG"
exit 0
STUB
  chmod +x "$stub_dir/git"

  cat >"$stub_dir/require-command" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/require-command"

  missing_dir="$stub_dir/nowhere"

  PATH="$stub_dir:$PATH" REQUIRE_COMMAND="$stub_dir/require-command" GIT_LOG="$git_log" WIZARDRY_DIR="$missing_dir" \
    run_spell "spells/system/update-wizardry"
  assert_failure
  assert_error_contains "does not exist or is not a directory"
  assert_path_missing "$git_log"
}

test_rejects_non_repo_env_directory() {
  stub_dir=$(make_stub_dir)
  git_log="$stub_dir/git.log"
  not_repo=$(make_tempdir)

  cat >"$stub_dir/git" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$GIT_LOG"
if [ "$2" = "rev-parse" ] && [ "$3" = "--is-inside-work-tree" ]; then
  exit 1
fi
exit 0
STUB
  chmod +x "$stub_dir/git"

  cat >"$stub_dir/require-command" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/require-command"

  PATH="$stub_dir:$PATH" REQUIRE_COMMAND="$stub_dir/require-command" GIT_LOG="$git_log" WIZARDRY_DIR="$not_repo" \
    run_spell "spells/system/update-wizardry"
  assert_failure
  assert_error_contains "is not a git repository"
  assert_file_contains "$git_log" "-C $not_repo rev-parse --is-inside-work-tree"
}

test_detects_repository_and_pulls() {
  stub_dir=$(make_stub_dir)
  git_log="$stub_dir/git.log"
  toplevel=$(make_tempdir)

  cat >"$stub_dir/git" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$GIT_LOG"
case "$*" in
  *"--is-inside-work-tree"*)
    exit 0 ;;
  *"--show-toplevel"*)
    printf '%s\n' "$MOCK_TOPLEVEL"
    exit 0 ;;
  "-C"*"pull --ff-only")
    exit "${PULL_STATUS:-0}" ;;
esac
exit 0
STUB
  chmod +x "$stub_dir/git"

  cat >"$stub_dir/require-command" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/require-command"

  PATH="$stub_dir:$PATH" REQUIRE_COMMAND="$stub_dir/require-command" GIT_LOG="$git_log" MOCK_TOPLEVEL="$toplevel" \
    run_spell "spells/system/update-wizardry"
  assert_success
  assert_output_contains "$toplevel"
  assert_file_contains "$git_log" "--show-toplevel"
  assert_file_contains "$git_log" "-C $toplevel pull --ff-only"
}

test_detection_failure() {
  stub_dir=$(make_stub_dir)

  cat >"$stub_dir/git" <<'STUB'
#!/bin/sh
exit 1
STUB
  chmod +x "$stub_dir/git"

  cat >"$stub_dir/require-command" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/require-command"

  PATH="$stub_dir:$PATH" REQUIRE_COMMAND="$stub_dir/require-command" run_spell "spells/system/update-wizardry"
  assert_failure
  assert_error_contains "Unable to determine the wizardry repository"
}

test_propagates_git_failure() {
  stub_dir=$(make_stub_dir)
  git_log="$stub_dir/git.log"
  toplevel=$(make_tempdir)

  cat >"$stub_dir/git" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$GIT_LOG"
case "$*" in
  *"--is-inside-work-tree"*) exit 0 ;;
  *"--show-toplevel"*) printf '%s\n' "$MOCK_TOPLEVEL"; exit 0 ;;
  "-C"*"pull --ff-only") exit 42 ;;
esac
exit 0
STUB
  chmod +x "$stub_dir/git"

  cat >"$stub_dir/require-command" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/require-command"

  PATH="$stub_dir:$PATH" REQUIRE_COMMAND="$stub_dir/require-command" GIT_LOG="$git_log" MOCK_TOPLEVEL="$toplevel" \
    run_spell "spells/system/update-wizardry"
  assert_status 42
  assert_file_contains "$git_log" "-C $toplevel pull --ff-only"
}

run_test_case "update-wizardry prints usage" test_help
run_test_case "update-wizardry requires git" test_requires_git
run_test_case "update-wizardry uses WIZARDRY_DIR when provided" test_uses_env_directory
run_test_case "update-wizardry rejects missing WIZARDRY_DIR" test_rejects_missing_env_directory
run_test_case "update-wizardry rejects non-repo WIZARDRY_DIR" test_rejects_non_repo_env_directory
run_test_case "update-wizardry auto-detects the repo and pulls" test_detects_repository_and_pulls
run_test_case "update-wizardry fails when detection fails" test_detection_failure
run_test_case "update-wizardry propagates git failures" test_propagates_git_failure
finish_tests
