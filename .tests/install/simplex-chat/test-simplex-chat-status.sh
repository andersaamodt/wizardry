#!/bin/sh
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
