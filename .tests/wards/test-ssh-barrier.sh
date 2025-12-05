#!/bin/sh
# Behavioral coverage for ssh-barrier:
# - shows usage with --help
# - shows usage with -h
# - spell file exists and has content

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


spell_exists() {
  [ -f "$ROOT_DIR/spells/wards/ssh-barrier" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/wards/ssh-barrier" ]
}

shows_help() {
  run_spell spells/wards/ssh-barrier --help
  assert_success
  assert_output_contains "Usage: ssh-barrier"
}

applies_hardening_to_temp_file() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/ssh-barrier.XXXXXX")
  config="$tmpdir/sshd_config"
  cat >"$config" <<'CFG'
#PermitRootLogin prohibit-password
#PasswordAuthentication yes
#Port 22
CFG

  stub_dir="$tmpdir/bin"
  mkdir -p "$stub_dir"

  cat >"$stub_dir/ask-yn" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$stub_dir/ask-yn"

  cat >"$stub_dir/backup" <<'SH'
#!/bin/sh
# no-op backup stub
exit 0
SH
  chmod +x "$stub_dir/backup"

  cat >"$stub_dir/sed-inplace" <<'SH'
#!/bin/sh
sed -i "$1" "$2"
SH
  chmod +x "$stub_dir/sed-inplace"

  PATH="$stub_dir:$PATH" SSHD_CONFIG="$config" run_spell spells/wards/ssh-barrier
  assert_success
  assert_file_contains "$config" "PermitRootLogin no"
  assert_file_contains "$config" "PasswordAuthentication no"
  assert_file_contains "$config" "Port 2222"
  assert_file_contains "$config" "AllowUsers"
}

run_test_case "wards/ssh-barrier exists" spell_exists
run_test_case "wards/ssh-barrier has content" spell_has_content
run_test_case "ssh-barrier shows help" shows_help
run_test_case "ssh-barrier hardens provided config" applies_hardening_to_temp_file

finish_tests
