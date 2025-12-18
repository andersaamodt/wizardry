#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - jump-trash prints usage with --help
# - jump-trash rejects unknown options
# - jump-trash cds to trash when sourced (via jump_trash function)
# - jump-trash uses inline fallback when detect-trash is missing
# - jump-trash fails if trash directory does not exist
# - jump-trash prompts to memorize when run directly

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/arcane/jump-trash" --help
  _assert_success && _assert_output_contains "Usage: jump-trash"
}

test_cds_when_sourced() {
  skip-if-compiled || return $?
  stub=$(_make_tempdir)
  trash_dir="$stub/Trash"
  mkdir -p "$trash_dir"

  # Create detect-trash stub that returns our test trash dir
  cat >"$stub/detect-trash" <<STUB
#!/bin/sh
printf '%s\n' "$trash_dir"
STUB
  chmod +x "$stub/detect-trash"

  # Source the spell and call the jump_trash function
  _run_cmd sh -c "
    PATH='$stub:$PATH'
    export PATH
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jump_trash
    pwd
  "
  _assert_success || return 1
  _assert_output_contains "teleport to the trash" || return 1
  _assert_output_contains "$trash_dir" || return 1
}

test_uses_inline_fallback() {
  stub=$(_make_tempdir)
  # Create a fake trash dir based on the system's expected location
  # We'll use a custom HOME to control the path
  fake_home="$stub/home"
  trash_dir="$fake_home/.local/share/Trash/files"
  mkdir -p "$trash_dir"
  
  # Create uname stub for Linux
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$stub/uname"
  
  # Provide only basic utilities, no detect-trash
  _link_tools "$stub" sh printf test cd

  # Source the spell and call the jump_trash function with custom HOME
  _run_cmd sh -c "
    PATH='$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin'
    HOME='$fake_home'
    export PATH HOME
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jump_trash
    pwd
  "
  _assert_success || return 1
  _assert_output_contains "teleport to the trash" || return 1
}

test_fails_if_trash_dir_missing() {
  stub=$(_make_tempdir)
  nonexistent_dir="$stub/nonexistent/Trash"

  # Create detect-trash stub that returns a nonexistent path
  cat >"$stub/detect-trash" <<STUB
#!/bin/sh
printf '%s\n' "$nonexistent_dir"
STUB
  chmod +x "$stub/detect-trash"

  # Source and call the jump_trash function
  _run_cmd sh -c "
    PATH='$stub:$PATH'
    export PATH
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jump_trash
  "
  _assert_failure || return 1
  _assert_error_contains "trash directory does not exist" || return 1
}

test_jump_trash_function_help() {
  skip-if-compiled || return $?
  stub=$(_make_tempdir)
  trash_dir="$stub/Trash"
  mkdir -p "$trash_dir"

  cat >"$stub/detect-trash" <<STUB
#!/bin/sh
printf '%s\n' "$trash_dir"
STUB
  chmod +x "$stub/detect-trash"

  # Test jump_trash function --help
  _run_cmd sh -c "
    PATH='$stub:$PATH'
    export PATH
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jump_trash --help
  "
  _assert_success || return 1
  _assert_output_contains "Usage: jump-trash" || return 1
}

test_unknown_option() {
  skip-if-compiled || return $?
  _run_spell "spells/arcane/jump-trash" --unknown
  _assert_failure && _assert_error_contains "unknown option"
}

_run_test_case "jump-trash prints usage" test_help
_run_test_case "jump-trash rejects unknown option" test_unknown_option
_run_test_case "jump-trash cds when sourced" test_cds_when_sourced
_run_test_case "jump-trash uses inline fallback without detect-trash" test_uses_inline_fallback
_run_test_case "jump-trash fails if trash dir missing" test_fails_if_trash_dir_missing
_run_test_case "jump_trash function shows help" test_jump_trash_function_help

_finish_tests
