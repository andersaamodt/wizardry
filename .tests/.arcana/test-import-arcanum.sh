#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_import_arcanum_help() {
  _run_spell spells/.arcana/import-arcanum --help
  _assert_success && _assert_output_contains "Usage:"
}

test_import_arcanum_validates_directory_exists() {
  tmp=$(_make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Try to import a non-existent directory
  _run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "/nonexistent/path"
  _assert_failure && _assert_error_contains "not a directory"
}

test_import_arcanum_validates_arcanum_name() {
  tmp=$(_make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Create source with invalid name (contains space)
  source_dir="$tmp/invalid name"
  mkdir -p "$source_dir"
  
  _run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$source_dir"
  _assert_failure && _assert_error_contains "invalid arcanum name"
}

test_import_arcanum_prevents_duplicate() {
  tmp=$(_make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir/existing-arcanum"
  
  # Create source
  source_dir="$tmp/existing-arcanum"
  mkdir -p "$source_dir"
  
  _run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$source_dir"
  _assert_failure && _assert_error_contains "already exists"
}

test_import_arcanum_copies_directory() {
  tmp=$(_make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Create source arcanum
  source_dir="$tmp/test-arcanum"
  mkdir -p "$source_dir"
  printf '%s\n' "test content" >"$source_dir/test-file"
  
  _run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$source_dir"
  _assert_success && \
    _assert_output_contains "Imported arcanum: test-arcanum" && \
    _assert_path_exists "$arcana_dir/test-arcanum" && \
    _assert_path_exists "$arcana_dir/test-arcanum/test-file"
}

test_import_arcanum_validates_metadata_name_match() {
  tmp=$(_make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Create source with matching .arcanum file
  source_dir="$tmp/my-arcanum"
  mkdir -p "$source_dir"
  printf '%s\n' "metadata" >"$source_dir/my-arcanum.arcanum"
  
  _run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$source_dir"
  _assert_success && \
    _assert_output_contains "Imported arcanum: my-arcanum" && \
    _assert_path_exists "$arcana_dir/my-arcanum/my-arcanum.arcanum"
}

test_import_arcanum_rejects_dot_prefix() {
  tmp=$(_make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Create source with dot prefix
  source_dir="$tmp/.hidden-arcanum"
  mkdir -p "$source_dir"
  
  _run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$source_dir"
  _assert_failure && _assert_error_contains "invalid arcanum name"
}

test_import_arcanum_prevents_importing_from_arcana_dir() {
  tmp=$(_make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir/existing"
  
  # Try to import from within the arcana directory itself
  _run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$arcana_dir/existing"
  _assert_failure && _assert_error_contains "cannot import from arcana directory"
}

test_import_arcanum_handles_relative_path() {
  tmp=$(_make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Create source arcanum in current directory
  source_dir="$tmp/relative-arcanum"
  mkdir -p "$source_dir"
  
  # Change to tmp directory and use relative path
  cd "$tmp" || return 1
  _run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "./relative-arcanum"
  _assert_success && \
    _assert_output_contains "Imported arcanum: relative-arcanum" && \
    _assert_path_exists "$arcana_dir/relative-arcanum"
}

test_import_arcanum_handles_tilde_path() {
  tmp=$(_make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Create source in a temp dir
  source_dir="$tmp/tilde-test"
  mkdir -p "$source_dir"
  
  # Mock HOME for this test
  old_home=${HOME-}
  HOME=$tmp
  export HOME
  
  # Create arcanum in "HOME"
  mkdir -p "$HOME/tilde-arcanum"
  
  _run_cmd env INSTALL_MENU_ROOT="$arcana_dir" HOME="$HOME" "$ROOT_DIR/spells/.arcana/import-arcanum" "~/tilde-arcanum"
  result=$?
  
  # Restore HOME
  HOME=$old_home
  export HOME
  
  [ "$result" -eq 0 ] && \
    _assert_output_contains "Imported arcanum: tilde-arcanum" && \
    _assert_path_exists "$arcana_dir/tilde-arcanum"
}

_run_test_case "import-arcanum prints usage" test_import_arcanum_help
_run_test_case "import-arcanum validates directory exists" test_import_arcanum_validates_directory_exists
_run_test_case "import-arcanum validates arcanum name" test_import_arcanum_validates_arcanum_name
_run_test_case "import-arcanum prevents duplicate" test_import_arcanum_prevents_duplicate
_run_test_case "import-arcanum copies directory" test_import_arcanum_copies_directory
_run_test_case "import-arcanum validates metadata file name match" test_import_arcanum_validates_metadata_name_match
_run_test_case "import-arcanum rejects dot prefix" test_import_arcanum_rejects_dot_prefix
_run_test_case "import-arcanum prevents importing from arcana directory" test_import_arcanum_prevents_importing_from_arcana_dir
_run_test_case "import-arcanum handles relative path" test_import_arcanum_handles_relative_path
_run_test_case "import-arcanum handles tilde path" test_import_arcanum_handles_tilde_path

_finish_tests
