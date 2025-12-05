#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - hashchant prints usage
# - errors when no target is provided
# - errors when the target does not exist
# - errors when no attribute helpers are available
# - prefers attr over xattr/setfattr, falling back in order
# - computes the expected hash from filename and contents

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


make_stub_bin() {
  dir=$(make_tempdir)
  mkdir -p "$dir/bin"
  printf '%s\n' "$dir/bin"
}

test_help() {
  run_spell "spells/crypto/hashchant" --help
  assert_success && assert_output_contains "Usage: hashchant"
}

test_missing_arg() {
  run_spell "spells/crypto/hashchant"
  assert_failure && assert_output_contains "Error: No file specified."
}

test_missing_file() {
  run_spell "spells/crypto/hashchant" "$WIZARDRY_TMPDIR/absent.txt"
  assert_failure && assert_output_contains "Error: File not found."
}

test_missing_helpers() {
  stub=$(make_stub_bin)
  tmpdir=$(make_tempdir)
  file="$tmpdir/target.txt"
  echo "lore" >"$file"
  PATH="$stub:/bin:/usr/bin" run_spell "spells/crypto/hashchant" "$file"
  assert_failure && assert_output_contains "Error: xattr and attr commands not found"
}

test_prefers_attr() {
  workdir=$(make_tempdir)
  file="$workdir/data.txt"
  echo "amulet" >"$file"
  expected=$( (echo "data.txt" && cat "$file") | cksum | awk '{printf "0x%X", $1}')

  stub=$(make_stub_bin)
  log="$workdir/attr.log"
  cat >"$stub/attr" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$ATTR_LOG"
EOF
  chmod +x "$stub/attr"
  cat >"$stub/xattr" <<'EOF'
#!/bin/sh
echo "xattr invoked" >>"$ATTR_LOG"
exit 1
EOF
  chmod +x "$stub/xattr"
  export ATTR_LOG="$log"
  PATH="$stub:/bin:/usr/bin" run_spell "spells/crypto/hashchant" "$file"
  assert_success || return 1
  assert_output_contains "$expected" || return 1
  assert_path_exists "$log" || return 1
  if ! grep -Fq -- "-s user.hash -V $expected $file" "$log"; then
    TEST_FAILURE_REASON="attr helper was not invoked with expected arguments"
    return 1
  fi
  if grep -q "xattr invoked" "$log"; then
    TEST_FAILURE_REASON="xattr should not be used when attr succeeds"
    return 1
  fi
}

test_fallback_to_xattr() {
  workdir=$(make_tempdir)
  file="$workdir/book.txt"
  echo "scroll" >"$file"
  expected=$( (echo "book.txt" && cat "$file") | cksum | awk '{printf "0x%X", $1}')

  stub=$(make_stub_bin)
  log="$workdir/helper.log"
  cat >"$stub/xattr" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$ATTR_LOG"
EOF
  chmod +x "$stub/xattr"
  cat >"$stub/setfattr" <<'EOF'
#!/bin/sh
echo "setfattr invoked" >>"$ATTR_LOG"
exit 1
EOF
  chmod +x "$stub/setfattr"
  export ATTR_LOG="$log"
  PATH="$stub:/bin:/usr/bin" run_spell "spells/crypto/hashchant" "$file"
  assert_success || return 1
  assert_output_contains "$expected" || return 1
  assert_path_exists "$log" || return 1
  if ! grep -Fq -- "-w user.hash $expected $file" "$log"; then
    TEST_FAILURE_REASON="xattr helper was not invoked with expected arguments"
    return 1
  fi
  if grep -q "setfattr invoked" "$log"; then
    TEST_FAILURE_REASON="setfattr should not be used when xattr exists"
    return 1
  fi
}

test_fallback_to_setfattr() {
  workdir=$(make_tempdir)
  file="$workdir/charm.txt"
  echo "enigma" >"$file"
  expected=$( (echo "charm.txt" && cat "$file") | cksum | awk '{printf "0x%X", $1}')

  stub=$(make_stub_bin)
  log="$workdir/helper.log"
  cat >"$stub/setfattr" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$ATTR_LOG"
EOF
  chmod +x "$stub/setfattr"
  export ATTR_LOG="$log"
  PATH="$stub:/bin:/usr/bin" run_spell "spells/crypto/hashchant" "$file"
  assert_success || return 1
  assert_output_contains "$expected" || return 1
  assert_path_exists "$log" || return 1
  if ! grep -Fq -- "-n user.hash -v $expected $file" "$log"; then
    TEST_FAILURE_REASON="setfattr helper was not invoked with expected arguments"
    return 1
  fi
}

run_test_case "hashchant prints usage" test_help
run_test_case "hashchant errors without a file" test_missing_arg
run_test_case "hashchant errors for missing target" test_missing_file
run_test_case "hashchant errors when helpers are unavailable" test_missing_helpers
run_test_case "hashchant prefers attr helper" test_prefers_attr
run_test_case "hashchant falls back to xattr" test_fallback_to_xattr
run_test_case "hashchant falls back to setfattr" test_fallback_to_setfattr
finish_tests
