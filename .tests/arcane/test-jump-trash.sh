#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - jump-trash prints usage with --help
# - jump-trash outputs the trash directory path
# - jump-trash fails if detect-trash is missing
# - jump-trash fails if trash directory does not exist

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/arcane/jump-trash" --help
  assert_success && assert_output_contains "Usage: jump-trash"
}

test_outputs_path() {
  stub=$(make_tempdir)
  trash_dir="$stub/Trash"
  mkdir -p "$trash_dir"

  # Create detect-trash stub that returns our test trash dir
  cat >"$stub/detect-trash" <<STUB
#!/bin/sh
printf '%s\n' "$trash_dir"
STUB
  chmod +x "$stub/detect-trash"

  PATH="$stub:$PATH" run_spell "spells/arcane/jump-trash"
  assert_success || return 1
  assert_output_contains "$trash_dir" || return 1
}

test_fails_without_detect_trash() {
  stub=$(make_tempdir)
  # Provide only basic utilities, no detect-trash
  link_tools "$stub" sh printf test

  run_cmd sh -c "
    PATH='$stub'
    export PATH
    '$ROOT_DIR/spells/arcane/jump-trash'
  "
  assert_failure || return 1
  assert_error_contains "detect-trash imp not found" || return 1
}

test_fails_if_trash_dir_missing() {
  stub=$(make_tempdir)
  nonexistent_dir="$stub/nonexistent/Trash"

  # Create detect-trash stub that returns a nonexistent path
  cat >"$stub/detect-trash" <<STUB
#!/bin/sh
printf '%s\n' "$nonexistent_dir"
STUB
  chmod +x "$stub/detect-trash"

  PATH="$stub:$PATH" run_spell "spells/arcane/jump-trash"
  assert_failure || return 1
  assert_error_contains "trash directory does not exist" || return 1
}

run_test_case "jump-trash prints usage" test_help
run_test_case "jump-trash outputs trash path" test_outputs_path
run_test_case "jump-trash fails without detect-trash" test_fails_without_detect_trash
run_test_case "jump-trash fails if trash dir missing" test_fails_if_trash_dir_missing

finish_tests
