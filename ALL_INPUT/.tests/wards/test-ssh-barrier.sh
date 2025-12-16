#!/bin/sh
# Behavioral coverage for ssh-barrier:
# - shows usage with --help
# - shows usage with -h
# - spell file exists and has content

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_exists() {
  [ -f "$ROOT_DIR/spells/wards/ssh-barrier" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/wards/ssh-barrier" ]
}

shows_help() {
  _run_spell spells/wards/ssh-barrier --help
  _assert_success
  _assert_output_contains "Usage: ssh-barrier"
}

applies_hardening_to_temp_file() {
  skip-if-compiled || return $?
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
# Portable sed-inplace stub
pattern=$1
file=$2
tmpfile="${file}.sed.$$"
sed "$pattern" "$file" > "$tmpfile" && mv "$tmpfile" "$file"
SH
  chmod +x "$stub_dir/sed-inplace"

  PATH="$stub_dir:$PATH" SSHD_CONFIG="$config" _run_spell spells/wards/ssh-barrier
  _assert_success
  _assert_file_contains "$config" "PermitRootLogin no"
  _assert_file_contains "$config" "PasswordAuthentication no"
  _assert_file_contains "$config" "Port 2222"
  _assert_file_contains "$config" "AllowUsers"
}

_run_test_case "wards/ssh-barrier exists" spell_exists
_run_test_case "wards/ssh-barrier has content" spell_has_content
_run_test_case "ssh-barrier shows help" shows_help
_run_test_case "ssh-barrier hardens provided config" applies_hardening_to_temp_file

_finish_tests
