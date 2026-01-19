#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Copy the create_xattr_stub function from the actual test
create_xattr_stub() {
  stub_dir=$1
  
  # Create xattr stub (macOS style)
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
case "$1" in
  -w)
    key=$2; value=$3; file=$4
    attr_file="${file}.attrs"
    if [ -f "$attr_file" ]; then
      grep -v "^${key}=" "$attr_file" > "${attr_file}.tmp" 2>/dev/null || true
      mv "${attr_file}.tmp" "$attr_file" 2>/dev/null || true
    fi
    printf '%s=%s\n' "$key" "$value" >> "$attr_file"
    ;;
  -p)
    key=$2; file=$3; attr_file="${file}.attrs"
    if [ -f "$attr_file" ]; then
      value=$(grep "^${key}=" "$attr_file" 2>/dev/null | cut -d= -f2-)
      if [ -n "$value" ]; then
        printf '%s\n' "$value"
        exit 0
      fi
    fi
    exit 1
    ;;
esac
STUB
  chmod +x "$stub_dir/xattr"
  
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
key=""; value=""; file=""
while [ $# -gt 0 ]; do
  case "$1" in
    -s) key=$2; shift 2 ;;
    -V) value=$2; shift 2 ;;
    *) file=$1; shift ;;
  esac
done
if [ -n "$key" ] && [ -n "$value" ] && [ -n "$file" ]; then
  attr_file="${file}.attrs"
  escaped_key=$(printf '%s\n' "$key" | sed 's/[.[\*^$]/\\&/g')
  if [ -f "$attr_file" ]; then
    grep -v "^${escaped_key}=" "$attr_file" > "${attr_file}.tmp" 2>/dev/null || true
    mv "${attr_file}.tmp" "$attr_file" 2>/dev/null || true
  fi
  printf '%s=%s\n' "$key" "$value" >> "$attr_file"
fi
STUB
  chmod +x "$stub_dir/attr"
  
  cat >"$stub_dir/setfattr" <<'STUB'
#!/bin/sh
key=""; value=""; file=""
while [ $# -gt 0 ]; do
  case "$1" in
    -n) key=$2; shift 2 ;;
    -v) value=$2; shift 2 ;;
    *) file=$1; shift ;;
  esac
done
if [ -n "$file" ]; then
  attr_file="${file}.attrs"
  escaped_key=$(printf '%s\n' "$key" | sed 's/[.[\*^$]/\\&/g')
  if [ -f "$attr_file" ]; then
    grep -v "^${escaped_key}=" "$attr_file" > "${attr_file}.tmp" 2>/dev/null || true
    mv "${attr_file}.tmp" "$attr_file" 2>/dev/null || true
  fi
  printf '%s=%s\n' "$key" "$value" >> "$attr_file"
fi
STUB
  chmod +x "$stub_dir/setfattr"
}

test_debug() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir/custom-spellbook"
  export HOME="$tmpdir"
  
  create_xattr_stub "$stub_dir"
  
  mkdir -p "$SPELLBOOK_DIR"
  printf 'avatar-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  avatar_path="$tmpdir/.avatar-test"
  mkdir -p "$avatar_path"
  printf 'avatar-path=%s\n' "$avatar_path" >> "$SPELLBOOK_DIR/.mud"
  
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  "$stub_dir/xattr" -w user.dead 1 "$avatar_path"
  "$stub_dir/xattr" -w user.max_life 100 "$avatar_path"
  
  printf 'Before: ' && cat "$avatar_path.attrs"
  
  cd "$tmpdir"
  run_spell "spells/mud/resurrect"
  
  printf 'After: ' && cat "$avatar_path.attrs"
  printf 'Output: %s\n' "$OUTPUT"
  printf 'Error: %s\n' "$ERROR"
  printf 'Status: %s\n' "$STATUS"
  
  dead_flag=$("$stub_dir/xattr" -p user.dead "$avatar_path" 2>/dev/null || printf '0')
  printf 'Dead flag: %s\n' "$dead_flag"
}

run_test_case "debug" test_debug
finish_tests
