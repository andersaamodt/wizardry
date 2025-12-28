#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_import_arcanum_help() {
  skip-if-compiled || return $?
  run_spell spells/.arcana/import-arcanum --help
  assert_success && assert_output_contains "Usage:"
}

test_import_arcanum_validates_directory_exists() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Try to import a non-existent directory
  run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "/nonexistent/path"
  assert_failure && assert_error_contains "not a directory"
}

test_import_arcanum_validates_arcanum_name() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Create source with invalid name (contains space)
  source_dir="$tmp/invalid name"
  mkdir -p "$source_dir"
  
  run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$source_dir"
  assert_failure && assert_error_contains "invalid arcanum name"
}

test_import_arcanum_prevents_duplicate() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir/existing-arcanum"
  
  # Create source
  source_dir="$tmp/existing-arcanum"
  mkdir -p "$source_dir"
  
  run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$source_dir"
  assert_failure && assert_error_contains "already exists"
}

test_import_arcanum_copies_directory() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Create source arcanum
  source_dir="$tmp/test-arcanum"
  mkdir -p "$source_dir"
  printf '%s\n' "test content" >"$source_dir/test-file"
  
  run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$source_dir"
  assert_success && \
    assert_output_contains "Imported arcanum: test-arcanum" && \
    assert_path_exists "$arcana_dir/test-arcanum" && \
    assert_path_exists "$arcana_dir/test-arcanum/test-file"
}

test_import_arcanum_rejects_dots_in_name() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Create source with dots in name
  source_dir="$tmp/my.test.arcanum"
  mkdir -p "$source_dir"
  
  run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$source_dir"
  assert_failure && assert_error_contains "invalid arcanum name"
}

test_import_arcanum_prevents_path_traversal() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Try to use path with .. component
  source_dir="$tmp/subdir/../traversal"
  mkdir -p "$tmp/subdir"
  mkdir -p "$tmp/traversal"
  
  run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$source_dir"
  # Should fail due to path traversal detection
  assert_failure && assert_error_contains "path traversal"
}

test_import_arcanum_validates_metadata_name_match() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Create source with matching .arcanum file
  source_dir="$tmp/my-arcanum"
  mkdir -p "$source_dir"
  printf '%s\n' "metadata" >"$source_dir/my-arcanum.arcanum"
  
  run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$source_dir"
  assert_success && \
    assert_output_contains "Imported arcanum: my-arcanum" && \
    assert_path_exists "$arcana_dir/my-arcanum/my-arcanum.arcanum"
}

test_import_arcanum_rejects_dot_prefix() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Create source with dot prefix
  source_dir="$tmp/.hidden-arcanum"
  mkdir -p "$source_dir"
  
  run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$source_dir"
  assert_failure && assert_error_contains "invalid arcanum name"
}

test_import_arcanum_prevents_importing_from_arcana_dir() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir/existing"
  
  # Try to import from within the arcana directory itself
  run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "$arcana_dir/existing"
  assert_failure && assert_error_contains "cannot import from arcana directory"
}

test_import_arcanum_handles_relative_path() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  arcana_dir="$tmp/arcana"
  mkdir -p "$arcana_dir"
  
  # Create source arcanum in current directory
  source_dir="$tmp/relative-arcanum"
  mkdir -p "$source_dir"
  
  # Change to tmp directory and use relative path
  cd "$tmp" || return 1
  run_cmd env INSTALL_MENU_ROOT="$arcana_dir" "$ROOT_DIR/spells/.arcana/import-arcanum" "./relative-arcanum"
  assert_success && \
    assert_output_contains "Imported arcanum: relative-arcanum" && \
    assert_path_exists "$arcana_dir/relative-arcanum"
}

test_import_arcanum_handles_tilde_path() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
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
  
  run_cmd env INSTALL_MENU_ROOT="$arcana_dir" HOME="$HOME" "$ROOT_DIR/spells/.arcana/import-arcanum" "~/tilde-arcanum"
  result=$?
  
  # Restore HOME
  HOME=$old_home
  export HOME
  
  [ "$result" -eq 0 ] && \
    assert_output_contains "Imported arcanum: tilde-arcanum" && \
    assert_path_exists "$arcana_dir/tilde-arcanum"
}

run_test_case "import-arcanum prints usage" test_import_arcanum_help
run_test_case "import-arcanum validates directory exists" test_import_arcanum_validates_directory_exists
run_test_case "import-arcanum validates arcanum name" test_import_arcanum_validates_arcanum_name
run_test_case "import-arcanum prevents duplicate" test_import_arcanum_prevents_duplicate
run_test_case "import-arcanum copies directory" test_import_arcanum_copies_directory
run_test_case "import-arcanum rejects dots in name" test_import_arcanum_rejects_dots_in_name
run_test_case "import-arcanum prevents path traversal" test_import_arcanum_prevents_path_traversal
run_test_case "import-arcanum validates metadata file name match" test_import_arcanum_validates_metadata_name_match
run_test_case "import-arcanum rejects dot prefix" test_import_arcanum_rejects_dot_prefix
run_test_case "import-arcanum prevents importing from arcana directory" test_import_arcanum_prevents_importing_from_arcana_dir
run_test_case "import-arcanum handles relative path" test_import_arcanum_handles_relative_path
run_test_case "import-arcanum handles tilde path" test_import_arcanum_handles_tilde_path

finish_tests
