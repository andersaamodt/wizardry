#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
  attr_stubs=$(wizardry_install_attr_stubs)
  workdir="$BATS_TEST_TMPDIR/work"
  mkdir -p "$workdir"
  spell_file="$workdir/grimoire.txt"
  printf 'knowledge' >"$spell_file"
  empty_file="$workdir/empty.txt"
  : >"$empty_file"
  attr_store="$workdir/attrs"
  rm -rf "$attr_store"
  export ATTR_STORAGE_DIR="$attr_store"
}

teardown() {
  PATH=$ORIGINAL_PATH
  unset ATTR_STORAGE_DIR
  default_teardown
}

cast_enchant() {
  PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" run_spell 'spells/enchant' "$@"
}

@test 'enchant requires arguments' {
  run_spell 'spells/enchant'
  assert_failure
  assert_output --partial 'requires three or four arguments'
}

@test 'enchant rejects extra arguments' {
  run_spell 'spells/enchant' "$spell_file" 'user.magic' 'spark' 'extra' 'ignored'
  assert_failure
  assert_output --partial 'requires three or four arguments'
}

@test 'enchant fails when file is missing' {
  run_spell 'spells/enchant' "$workdir/missing.txt" 'user.magic' 'spark'
  assert_failure
  assert_output --partial 'The file does not exist.'
}

@test 'enchant stores attributes via attr helpers' {
  cast_enchant "$spell_file" 'user.magic' 'spark'
  assert_success

  run "$attr_stubs/attr" -g user.magic "$spell_file"
  assert_success
  assert_output --partial 'spark'
}

@test 'enchant preserves spaces in attribute values' {
  cast_enchant "$spell_file" 'user.poem' 'lunar glow'
  assert_success

  run "$attr_stubs/attr" -g user.poem "$spell_file"
  assert_success
  assert_output --partial 'lunar glow'
}

@test 'enchant falls back to xattr when attr fails' {
  xattr_file="$workdir/xattr.txt"
  printf 'moonlight' >"$xattr_file"

  ATTR_FAIL=set PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" \
    run_spell 'spells/enchant' "$xattr_file" 'user.moon' 'glow'
  assert_success

  run "$attr_stubs/xattr" -p user.moon "$xattr_file"
  assert_success
  assert_output 'glow'
}

@test 'enchant falls back to setfattr when others fail' {
  setfattr_file="$workdir/setfattr.txt"
  printf 'starlight' >"$setfattr_file"

  ATTR_FAIL=set XATTR_FAIL=write PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" \
    run_spell 'spells/enchant' "$setfattr_file" 'user.star' 'shine'
  assert_success

  run "$attr_stubs/getfattr" -n user.star --only-values "$setfattr_file"
  assert_success
  assert_output 'shine'
}

@test 'enchant reports failure when no helpers succeed' {
  ATTR_FAIL=all XATTR_FAIL=all SETFATTR_FAIL=all PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" \
    run_spell 'spells/enchant' "$spell_file" 'user.fail' 'oops'
  assert_failure
  assert_output --partial "requires the 'attr', 'xattr', or 'setfattr' command"
}

@test 'read-magic requires arguments' {
  PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" run_spell 'spells/read-magic'
  assert_failure
  assert_output --partial 'requires one or two arguments'
}

@test 'read-magic fails for missing file' {
  PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" run_spell 'spells/read-magic' "$workdir/unknown.txt"
  assert_failure
  assert_output --partial 'The file does not exist.'
}

@test 'read-magic reports when no attributes exist' {
  PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" run_spell 'spells/read-magic' "$empty_file"
  assert_success
  assert_output --partial 'No enchanted attributes found.'
}

prepare_enchanted_scroll() {
  cast_enchant "$spell_file" 'user.magic' 'spark'
  assert_success
  cast_enchant "$spell_file" 'user.poem' 'lunar glow'
  assert_success
}

@test 'read-magic lists stored attributes' {
  prepare_enchanted_scroll
  PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" run_spell 'spells/read-magic' "$spell_file"
  assert_success
  assert_output --partial 'user.magic: spark'
  assert_output --partial 'user.poem: lunar glow'
}

@test 'read-magic normalizes helper output' {
  prepare_enchanted_scroll
  "$attr_stubs/attr" -s magic -V rune "$spell_file"

  clean_dir="$BATS_TEST_TMPDIR/clean_getfattr"
  mkdir -p "$clean_dir"
  cat <<'GETFATTR' >"$clean_dir/getfattr"
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="__ROOT_DIR__"
. "$ROOT_DIR/tests/lib/attr_store.sh"

file=""
while [ $# -gt 0 ]; do
  case $1 in
    -h)
      shift
      ;;
    -m|-e|-n)
      shift
      [ $# -gt 0 ] && shift || true
      ;;
    --only-values)
      shift
      ;;
    --absolute-names)
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      shift
      ;;
    *)
      file=$1
      shift
      ;;
  esac
done

if [ -z "$file" ]; then
  exit 1
fi

printf '# file: %s\n' "$file"
list_attr_keys "$file" | while IFS= read -r attr_key; do
  [ -z "$attr_key" ] && continue
  value=$(get_attr_value "$file" "$attr_key" || printf '')
  printf 'attr.%s: %s\n' "$attr_key" "$value"
done
GETFATTR
  sed -i "s|__ROOT_DIR__|$ROOT_DIR|g" "$clean_dir/getfattr"
  chmod +x "$clean_dir/getfattr"

  PATH="$(wizardry_join_paths "$clean_dir" "$attr_stubs" "$ORIGINAL_PATH")" run_spell 'spells/read-magic' "$spell_file"
  assert_success
  assert_output --partial 'magic: rune'
}

@test 'read-magic returns a specific attribute value' {
  prepare_enchanted_scroll
  PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" run_spell 'spells/read-magic' "$spell_file" 'user.magic'
  assert_success
  assert_output 'spark'
}

@test 'read-magic fails for missing attributes' {
  prepare_enchanted_scroll
  PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" run_spell 'spells/read-magic' "$spell_file" 'user.missing'
  assert_failure
  assert_output --partial 'The attribute does not exist.'
}

@test 'read-magic falls back when attr and xattr cannot read values' {
  run "$attr_stubs/setfattr" -n user.star -v shine "$spell_file"
  assert_success
  ATTR_FAIL=get XATTR_FAIL=read PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" \
    run_spell 'spells/read-magic' "$spell_file" 'user.star'
  assert_success
  assert_output 'shine'
}

