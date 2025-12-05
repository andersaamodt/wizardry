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

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_dir() {
  dir=$(_make_tempdir)
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

test_help() {
  _run_spell "spells/system/update-wizardry" --help
  _assert_success && _assert_output_contains "Usage: update-wizardry"
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

  REQUIRE_LOG="$require_log" REQUIRE_COMMAND="$stub_dir/require-command" _run_spell "spells/system/update-wizardry"
  _assert_failure && _assert_error_contains "Update wizardry needs 'git'"
  _assert_file_contains "$require_log" "git"
}

test_uses_env_directory() {
  stub_dir=$(make_stub_dir)
  wizard_dir=$(_make_tempdir)
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
    _run_spell "spells/system/update-wizardry"
  _assert_success
  _assert_file_contains "$git_log" "-C $wizard_dir pull --ff-only"
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
    _run_spell "spells/system/update-wizardry"
  _assert_failure
  _assert_error_contains "does not exist or is not a directory"
  _assert_path_missing "$git_log"
}

test_rejects_non_repo_env_directory() {
  stub_dir=$(make_stub_dir)
  git_log="$stub_dir/git.log"
  not_repo=$(_make_tempdir)

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
    _run_spell "spells/system/update-wizardry"
  _assert_failure
  _assert_error_contains "is not a git repository"
  _assert_file_contains "$git_log" "-C $not_repo rev-parse --is-inside-work-tree"
}

test_detects_repository_and_pulls() {
  stub_dir=$(make_stub_dir)
  git_log="$stub_dir/git.log"
  toplevel=$(_make_tempdir)

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
    _run_spell "spells/system/update-wizardry"
  _assert_success
  _assert_output_contains "$toplevel"
  _assert_file_contains "$git_log" "--show-toplevel"
  _assert_file_contains "$git_log" "-C $toplevel pull --ff-only"
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

  PATH="$stub_dir:$PATH" REQUIRE_COMMAND="$stub_dir/require-command" _run_spell "spells/system/update-wizardry"
  _assert_failure
  _assert_error_contains "Unable to determine the wizardry repository"
}

test_propagates_git_failure() {
  stub_dir=$(make_stub_dir)
  git_log="$stub_dir/git.log"
  toplevel=$(_make_tempdir)

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
    _run_spell "spells/system/update-wizardry"
  _assert_status 42
  _assert_file_contains "$git_log" "-C $toplevel pull --ff-only"
}

_run_test_case "update-wizardry prints usage" test_help
_run_test_case "update-wizardry requires git" test_requires_git
_run_test_case "update-wizardry uses WIZARDRY_DIR when provided" test_uses_env_directory
_run_test_case "update-wizardry rejects missing WIZARDRY_DIR" test_rejects_missing_env_directory
_run_test_case "update-wizardry rejects non-repo WIZARDRY_DIR" test_rejects_non_repo_env_directory
_run_test_case "update-wizardry auto-detects the repo and pulls" test_detects_repository_and_pulls
_run_test_case "update-wizardry fails when detection fails" test_detection_failure
_run_test_case "update-wizardry propagates git failures" test_propagates_git_failure
_finish_tests
