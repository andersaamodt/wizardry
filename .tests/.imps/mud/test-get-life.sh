#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Create stub xattr helper
create_xattr_stub() {
  stub_dir=$1
  
  # Create xattr stub (macOS style)
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
# Simple xattr stub that tracks attributes in a temp file
case "$1" in
  -w)
    # Write: xattr -w key value file
    key=$2
    value=$3
    file=$4
    attr_file="${file}.attrs"
    # Remove existing key if present
    if [ -f "$attr_file" ]; then
      grep -v "^${key}=" "$attr_file" > "${attr_file}.tmp" 2>/dev/null || true
      mv "${attr_file}.tmp" "$attr_file" 2>/dev/null || true
    fi
    # Add new key=value
    printf '%s=%s\n' "$key" "$value" >> "$attr_file"
    ;;
  -p)
    # Read: xattr -p key file
    key=$2
    file=$3
    attr_file="${file}.attrs"
    if [ -f "$attr_file" ]; then
      value=$(grep "^${key}=" "$attr_file" 2>/dev/null | cut -d= -f2-)
      if [ -n "$value" ]; then
        printf '%s\n' "$value"
        exit 0
      fi
    fi
    exit 1
    ;;
  *)
    # List: xattr file
    file=$1
    attr_file="${file}.attrs"
    if [ -f "$attr_file" ]; then
      cut -d= -f1 < "$attr_file"
    fi
    ;;
esac
STUB
  chmod +x "$stub_dir/xattr"
  
  # Create attr stub (Linux style)
  cat >"$stub_dir/attr" <<'STUB'
#!/bin/sh
# attr stub for Linux
# Handles: attr -s key -V value file
key=""
value=""
file=""
while [ $# -gt 0 ]; do
  case "$1" in
    -s)
      key=$2
      shift 2
      ;;
    -V)
      value=$2
      shift 2
      ;;
    *)
      file=$1
      shift
      ;;
  esac
done
if [ -n "$key" ] && [ -n "$value" ] && [ -n "$file" ]; then
  attr_file="${file}.attrs"
  # Escape special regex characters in key for grep
  escaped_key=$(printf '%s\n' "$key" | sed 's/[.[\*^$]/\\&/g')
  if [ -f "$attr_file" ]; then
    grep -v "^${escaped_key}=" "$attr_file" > "${attr_file}.tmp" 2>/dev/null || true
    mv "${attr_file}.tmp" "$attr_file" 2>/dev/null || true
  fi
  printf '%s=%s\n' "$key" "$value" >> "$attr_file"
fi
STUB
  chmod +x "$stub_dir/attr"
  
  # Create setfattr stub (Linux style)
  cat >"$stub_dir/setfattr" <<'STUB'
#!/bin/sh
# setfattr stub for Linux
while [ $# -gt 0 ]; do
  case "$1" in
    -n)
      key=$2
      shift 2
      ;;
    -v)
      value=$2
      shift 2
      ;;
    *)
      file=$1
      shift
      ;;
  esac
done
attr_file="${file}.attrs"
# Escape special regex characters in key for grep
escaped_key=$(printf '%s\n' "$key" | sed 's/[.[\*^$]/\\&/g')
if [ -f "$attr_file" ]; then
  grep -v "^${escaped_key}=" "$attr_file" > "${attr_file}.tmp" 2>/dev/null || true
  mv "${attr_file}.tmp" "$attr_file" 2>/dev/null || true
fi
printf '%s=%s\n' "$key" "$value" >> "$attr_file"
STUB
  chmod +x "$stub_dir/setfattr"
  
  # Create getfattr stub (Linux style)
  cat >"$stub_dir/getfattr" <<'STUB'
#!/bin/sh
# getfattr stub for Linux
while [ $# -gt 0 ]; do
  case "$1" in
    -n)
      key=$2
      shift 2
      ;;
    *)
      file=$1
      shift
      ;;
  esac
done
attr_file="${file}.attrs"
if [ -f "$attr_file" ]; then
  value=$(grep "^${key}=" "$attr_file" 2>/dev/null | cut -d= -f2-)
  if [ -n "$value" ]; then
    printf '%s="%s"\n' "$key" "$value"
    exit 0
  fi
fi
exit 1
STUB
  chmod +x "$stub_dir/getfattr"
}

test_get_life_no_damage() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test\n' > "$test_file"
  
  create_xattr_stub "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Set max_life
  "$stub_dir/xattr" -w user.max_life 100 "$test_file"
  
  output=$(get-life "$test_file")
  [ "$output" = "100" ] || fail "Expected life=100, got $output"
}

test_get_life_with_damage() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test\n' > "$test_file"
  
  create_xattr_stub "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Set max_life and damage
  "$stub_dir/xattr" -w user.max_life 100 "$test_file"
  "$stub_dir/xattr" -w user.damage 30 "$test_file"
  
  output=$(get-life "$test_file")
  [ "$output" = "70" ] || fail "Expected life=70, got $output"
}

test_get_life_dead() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test\n' > "$test_file"
  
  create_xattr_stub "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Set damage >= max_life
  "$stub_dir/xattr" -w user.max_life 100 "$test_file"
  "$stub_dir/xattr" -w user.damage 150 "$test_file"
  
  output=$(get-life "$test_file")
  [ "$output" = "0" ] || fail "Expected life=0, got $output"
}

test_deal_damage_basic() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test\n' > "$test_file"
  
  create_xattr_stub "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  deal-damage "$test_file" 25
  
  damage=$("$stub_dir/xattr" -p user.damage "$test_file")
  [ "$damage" = "25" ] || fail "Expected damage=25, got $damage"
}

test_deal_damage_accumulates() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test\n' > "$test_file"
  
  create_xattr_stub "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  deal-damage "$test_file" 25
  deal-damage "$test_file" 15
  
  damage=$("$stub_dir/xattr" -p user.damage "$test_file")
  [ "$damage" = "40" ] || fail "Expected damage=40, got $damage"
}

test_deal_damage_marks_dead() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test\n' > "$test_file"
  
  create_xattr_stub "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Set max_life and deal lethal damage
  "$stub_dir/xattr" -w user.max_life 100 "$test_file"
  deal-damage "$test_file" 150
  
  dead=$("$stub_dir/xattr" -p user.dead "$test_file")
  [ "$dead" = "1" ] || fail "Expected dead=1, got $dead"
}

run_test_case "get-life returns full health with no damage" test_get_life_no_damage
run_test_case "get-life calculates current life with damage" test_get_life_with_damage
run_test_case "get-life returns 0 when dead" test_get_life_dead
run_test_case "deal-damage applies damage" test_deal_damage_basic
run_test_case "deal-damage accumulates" test_deal_damage_accumulates
run_test_case "deal-damage marks target as dead" test_deal_damage_marks_dead

finish_tests
