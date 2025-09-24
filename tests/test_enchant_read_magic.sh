#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"
source "$(dirname "$0")/lib/stub_helpers.sh"

BASE_PATH=$PATH
attr_stubs=$(wizardry_install_attr_stubs)

tmp_dir=$(make_temp_dir)
spell_file="$tmp_dir/grimoire.txt"
printf 'knowledge' >"$spell_file"
empty_file="$tmp_dir/empty.txt"
>"$empty_file"
attr_store="$tmp_dir/attrs"
export ATTR_STORAGE_DIR="$attr_store"

# enchant: missing arguments should trigger the usage message.
run_script "spells/enchant"
expect_exit_code 1
expect_in_output "requires three or four arguments" "$RUN_STDOUT" "enchant should explain its argument requirements"

# enchant: extra arguments should also be rejected before touching the file.
run_script "spells/enchant" "$spell_file" "user.magic" "spark" "extra" "ignored"
expect_exit_code 1
expect_in_output "requires three or four arguments" "$RUN_STDOUT"

# enchant: targeting a missing file must fail.
run_script "spells/enchant" "$tmp_dir/missing.txt" "user.magic" "spark"
expect_exit_code 1
expect_in_output "The file does not exist." "$RUN_STDOUT"

# enchant: successfully set an attribute via attr.
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" run_script "spells/enchant" "$spell_file" "user.magic" "spark"
expect_exit_code 0
attr_output=$("$attr_stubs/attr" -g user.magic "$spell_file" 2>/dev/null || true)
expect_in_output "spark" "$attr_output" "enchant should store the provided value"
"$attr_stubs/attr" -s magic -V rune "$spell_file"

# enchant: values containing spaces should round-trip intact.
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" run_script "spells/enchant" "$spell_file" "user.poem" "lunar glow"
expect_exit_code 0
poem_output=$("$attr_stubs/attr" -g user.poem "$spell_file" 2>/dev/null || true)
expect_in_output "lunar glow" "$poem_output" "enchant should preserve spaces in attribute values"

# enchant: fallback to xattr if attr is unavailable.
xattr_file="$tmp_dir/xattr.txt"
printf 'moonlight' >"$xattr_file"
ATTR_FAIL=set RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" \
  run_script "spells/enchant" "$xattr_file" "user.moon" "glow"
unset ATTR_FAIL || true
expect_exit_code 0
xattr_value=$("$attr_stubs/xattr" -p user.moon "$xattr_file" 2>/dev/null || true)
expect_eq "glow" "$xattr_value" "enchant should rely on xattr when attr fails"

# enchant: fallback to setfattr when attr and xattr fail.
setfattr_file="$tmp_dir/setfattr.txt"
printf 'starlight' >"$setfattr_file"
ATTR_FAIL=set XATTR_FAIL=write RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" \
  run_script "spells/enchant" "$setfattr_file" "user.star" "shine"
unset ATTR_FAIL || true
unset XATTR_FAIL || true
expect_exit_code 0
setfattr_value=$("$attr_stubs/getfattr" -n user.star --only-values "$setfattr_file" 2>/dev/null || true)
expect_eq "shine" "$setfattr_value" "enchant should fall back to setfattr"

# enchant: fail cleanly if no helper commands succeed.
ATTR_FAIL=all XATTR_FAIL=all SETFATTR_FAIL=all RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" \
  run_script "spells/enchant" "$spell_file" "user.fail" "oops"
unset ATTR_FAIL || true
unset XATTR_FAIL || true
unset SETFATTR_FAIL || true
expect_exit_code 1
expect_in_output "requires the 'attr', 'xattr', or 'setfattr' command" "$RUN_STDOUT"

# read-magic: missing arguments should result in a clear usage message.
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" run_script "spells/read-magic"
expect_exit_code 1
expect_in_output "requires one or two arguments" "$RUN_STDOUT"

# read-magic: nonexistent files must error.
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" run_script "spells/read-magic" "$tmp_dir/unknown.txt"
expect_exit_code 1
expect_in_output "The file does not exist." "$RUN_STDOUT"

# read-magic: files without attributes should say so.
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" run_script "spells/read-magic" "$empty_file"
expect_exit_code 0
expect_in_output "No enchanted attributes found." "$RUN_STDOUT"

# read-magic: listing should surface every stored attribute.
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" run_script "spells/read-magic" "$spell_file"
expect_exit_code 0
expect_in_output "user.magic: spark" "$RUN_STDOUT"
expect_in_output "user.poem: lunar glow" "$RUN_STDOUT" "read-magic should show values with spaces"

# read-magic: when helpers provide normalized names we should still list attributes.
clean_getfattr_dir=$(make_temp_dir)
cat <<'GETFATTR' >"$clean_getfattr_dir/getfattr"
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
sed -i "s|__ROOT_DIR__|$ROOT_DIR|g" "$clean_getfattr_dir/getfattr"
chmod +x "$clean_getfattr_dir/getfattr"
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$clean_getfattr_dir" "$attr_stubs" "$BASE_PATH")" \
  run_script "spells/read-magic" "$spell_file"
expect_exit_code 0
expect_in_output "magic: rune" "$RUN_STDOUT" "read-magic should include simplified attribute names when helpers normalize output"

# read-magic: fetching a specific attribute should return its value.
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" run_script "spells/read-magic" "$spell_file" "user.magic"
expect_exit_code 0
value=$(printf '%s' "$RUN_STDOUT")
expect_eq "spark" "$value" "read-magic should retrieve specific enchantments"

# read-magic: requesting a missing attribute should fail.
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" run_script "spells/read-magic" "$spell_file" "user.missing"
expect_exit_code 1
expect_in_output "The attribute does not exist." "$RUN_STDOUT"

# read-magic: ensure fallbacks work when attr and xattr cannot read values.
ATTR_FAIL=get XATTR_FAIL=read RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" \
  run_script "spells/read-magic" "$setfattr_file" "user.star"
unset ATTR_FAIL || true
unset XATTR_FAIL || true
expect_exit_code 0
star_value=$(printf '%s' "$RUN_STDOUT")
expect_eq "shine" "$star_value" "read-magic should still find attributes when attr/xattr fail"

assert_all_expectations_met
