#!/bin/sh
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/simplex-chat/simplex-chat-status" ]
}

run_test_case "install/simplex-chat/simplex-chat-status is executable" spell_is_executable

shows_usage_with_help_flag() {
  run_cmd "$ROOT_DIR/spells/install/simplex-chat/simplex-chat-status" --help
  assert_success || return 1
  # Usage text is written to stderr to match other arcanum scripts.
  assert_error_contains "Usage: simplex-chat-status" || return 1
}

run_test_case "simplex-chat-status shows usage with --help" shows_usage_with_help_flag

make_stub_colors() {
  tmp=$1
  cat >"$tmp/colors" <<'SHI'
#!/bin/sh
RESET=""
GREEN=""
YELLOW=""
RED=""
GRAY=""
GREY=""
SHI
  chmod +x "$tmp/colors"
}

reports_not_installed_without_binary() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  HOME="$tmp/home" run_cmd env PATH="$tmp" HOME="$tmp/home" SIMPLEX_CHAT_CONFIG_DIR="$tmp/home/config" SIMPLEX_CHAT_DATA_DIR="$tmp/home/data" \
    "$ROOT_DIR/spells/install/simplex-chat/simplex-chat-status"
  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

run_test_case "simplex-chat-status reports not installed when binary missing" reports_not_installed_without_binary

reports_installed_with_directories() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  mkdir -p "$tmp/home/config" "$tmp/home/data"
  cat >"$tmp/simplex-chat" <<'SHI'
#!/bin/sh
[ "$1" = "--version" ] && exit 0
exit 0
SHI
  chmod +x "$tmp/simplex-chat"

  HOME="$tmp/home" run_cmd env PATH="$tmp" HOME="$tmp/home" SIMPLEX_CHAT_CONFIG_DIR="$tmp/home/config" SIMPLEX_CHAT_DATA_DIR="$tmp/home/data" \
    "$ROOT_DIR/spells/install/simplex-chat/simplex-chat-status"
  assert_success || return 1
  assert_output_contains "installed" || return 1
}

run_test_case "simplex-chat-status reports installed when version works and directories exist" reports_installed_with_directories

warns_when_setup_missing() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  mkdir -p "$tmp/home/config"
  cat >"$tmp/simplex-chat" <<'SHI'
#!/bin/sh
[ "$1" = "--version" ] && exit 0
exit 0
SHI
  chmod +x "$tmp/simplex-chat"

  HOME="$tmp/home" run_cmd env PATH="$tmp" HOME="$tmp/home" SIMPLEX_CHAT_CONFIG_DIR="$tmp/home/config" SIMPLEX_CHAT_DATA_DIR="$tmp/home/data" \
    "$ROOT_DIR/spells/install/simplex-chat/simplex-chat-status"
  assert_success || return 1
  assert_output_contains "installed, needs setup" || return 1
}

run_test_case "simplex-chat-status warns when data directory is missing" warns_when_setup_missing

reports_error_when_version_fails() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  cat >"$tmp/simplex-chat" <<'SHI'
#!/bin/sh
exit 1
SHI
  chmod +x "$tmp/simplex-chat"

  HOME="$tmp/home" run_cmd env PATH="$tmp" HOME="$tmp/home" SIMPLEX_CHAT_CONFIG_DIR="$tmp/home/config" SIMPLEX_CHAT_DATA_DIR="$tmp/home/data" \
    "$ROOT_DIR/spells/install/simplex-chat/simplex-chat-status"
  assert_success || return 1
  assert_output_contains "installed, error" || return 1
}

run_test_case "simplex-chat-status reports version errors" reports_error_when_version_fails

finish_tests
