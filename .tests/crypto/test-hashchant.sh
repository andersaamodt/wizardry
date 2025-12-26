#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - hashchant prints usage
# - errors when no target is provided
# - errors when the target does not exist
# - errors when no attribute helpers are available
# - prefers attr over xattr/setfattr, falling back in order
# - computes the expected hash from filename and contents

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_bin() {
  dir=$(_make_tempdir)
  mkdir -p "$dir/bin"
  printf '%s\n' "$dir/bin"
}

test_help() {
  _run_spell "spells/crypto/hashchant" --help
  _assert_success && _assert_output_contains "Usage: hashchant"
}

test_missing_arg() {
  _run_spell "spells/crypto/hashchant"
  _assert_failure && _assert_error_contains "hashchant: file path required"
}

test_missing_file() {
  _run_spell "spells/crypto/hashchant" "$WIZARDRY_TMPDIR/absent.txt"
  _assert_failure && _assert_error_contains "hashchant: file not found"
}

test_missing_helpers() {
  stub=$(make_stub_bin)
  tmpdir=$(_make_tempdir)
  file="$tmpdir/target.txt"
  echo "lore" >"$file"
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" _run_spell "spells/crypto/hashchant" "$file"
  _assert_failure && _assert_error_contains "hashchant: xattr and attr commands not found"
}

test_prefers_attr() {
  workdir=$(_make_tempdir)
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
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" _run_spell "spells/crypto/hashchant" "$file"
  _assert_success || return 1
  _assert_output_contains "$expected" || return 1
  _assert_path_exists "$log" || return 1
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
  workdir=$(_make_tempdir)
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
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" _run_spell "spells/crypto/hashchant" "$file"
  _assert_success || return 1
  _assert_output_contains "$expected" || return 1
  _assert_path_exists "$log" || return 1
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
  workdir=$(_make_tempdir)
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
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" _run_spell "spells/crypto/hashchant" "$file"
  _assert_success || return 1
  _assert_output_contains "$expected" || return 1
  _assert_path_exists "$log" || return 1
  if ! grep -Fq -- "-n user.hash -v $expected $file" "$log"; then
    TEST_FAILURE_REASON="setfattr helper was not invoked with expected arguments"
    return 1
  fi
}

_run_test_case "hashchant prints usage" test_help
_run_test_case "hashchant errors without a file" test_missing_arg
_run_test_case "hashchant errors for missing target" test_missing_file
_run_test_case "hashchant errors when helpers are unavailable" test_missing_helpers
_run_test_case "hashchant prefers attr helper" test_prefers_attr
_run_test_case "hashchant falls back to xattr" test_fallback_to_xattr
_run_test_case "hashchant falls back to setfattr" test_fallback_to_setfattr

# Test via source-then-invoke pattern  
hashchant_help_via_sourcing() {
  _run_sourced_spell hashchant --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "hashchant works via source-then-invoke" hashchant_help_via_sourcing
_finish_tests
