#!/bin/sh
# Behavioral cases:
# - jump prints usage with --help
# - jump spellbook jumps to $SPELLBOOK_DIR
# - jump wizardry jumps to $WIZARDRY_DIR
# - jump home jumps to $HOME
# - jump trash delegates to jump-trash
# - jump to marker delegates to jump-to-marker
# - jump <marker> delegates to jump-to-marker
# - jump fails without arguments

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/translocation/jump" --help
  assert_success && assert_output_contains "Usage:"
}

test_no_args() {
  run_cmd sh -c ". '$ROOT_DIR/spells/translocation/jump'"
  assert_failure && assert_error_contains "destination required"
}

test_jump_spellbook() {
  skip-if-compiled || return $?
  stub=$(make_tempdir)
  spellbook_dir="$stub/spellbook"
  mkdir -p "$spellbook_dir"
  
  # Test jump spellbook
  spellbook_resolved=$(cd "$spellbook_dir" && pwd -P | sed 's|//|/|g')
  run_cmd sh -c "
    export SPELLBOOK_DIR='$spellbook_dir'
    set -- spellbook
    . '$ROOT_DIR/spells/translocation/jump'
    new_dir=\$(pwd -P | sed 's|//|/|g')
    [ \"\$new_dir\" = '$spellbook_resolved' ]
  "
  assert_success || return 1
  assert_output_contains "teleport to the spellbook" || return 1
}

test_jump_wizardry() {
  skip-if-compiled || return $?
  stub=$(make_tempdir)
  wizardry_dir="$stub/wizardry"
  mkdir -p "$wizardry_dir"
  
  # Test jump wizardry
  wizardry_resolved=$(cd "$wizardry_dir" && pwd -P | sed 's|//|/|g')
  run_cmd sh -c "
    export WIZARDRY_DIR='$wizardry_dir'
    set -- wizardry
    . '$ROOT_DIR/spells/translocation/jump'
    new_dir=\$(pwd -P | sed 's|//|/|g')
    [ \"\$new_dir\" = '$wizardry_resolved' ]
  "
  assert_success || return 1
  assert_output_contains "teleport to the wizardry sanctum" || return 1
}

test_jump_home() {
  skip-if-compiled || return $?
  stub=$(make_tempdir)
  home_dir="$stub/home"
  mkdir -p "$home_dir"
  
  # Test jump home
  home_resolved=$(cd "$home_dir" && pwd -P | sed 's|//|/|g')
  run_cmd sh -c "
    export HOME='$home_dir'
    set -- home
    . '$ROOT_DIR/spells/translocation/jump'
    new_dir=\$(pwd -P | sed 's|//|/|g')
    [ \"\$new_dir\" = '$home_resolved' ]
  "
  assert_success || return 1
  assert_output_contains "teleport home" || return 1
}

test_jump_trash_delegation() {
  skip-if-compiled || return $?
  stub=$(make_tempdir)
  trash_dir="$stub/Trash"
  mkdir -p "$trash_dir"
  
  # Create detect-trash stub
  cat >"$stub/detect-trash" <<STUB
#!/bin/sh
printf '%s\n' "$trash_dir"
STUB
  chmod +x "$stub/detect-trash"
  
  # Test jump trash delegation
  trash_resolved=$(cd "$trash_dir" && pwd -P | sed 's|//|/|g')
  run_cmd sh -c "
    export PATH='$stub:$WIZARDRY_IMPS_PATH:/bin:/usr/bin'
    export WIZARDRY_DIR='$ROOT_DIR'
    set -- trash
    . '$ROOT_DIR/spells/translocation/jump'
    new_dir=\$(pwd -P | sed 's|//|/|g')
    [ \"\$new_dir\" = '$trash_resolved' ]
  "
  assert_success || return 1
  assert_output_contains "teleport to the trash" || return 1
}

test_jump_to_marker_delegation() {
  skip-if-compiled || return $?
  stub=$(make_tempdir)
  spellbook_dir="$stub/spellbook"
  markers_dir="$spellbook_dir/.markers"
  marker_dest="$stub/destination"
  mkdir -p "$markers_dir" "$marker_dest"
  
  # Create a marker
  printf '%s\n' "$marker_dest" > "$markers_dir/1"
  
  # Test jump to marker delegation
  marker_resolved=$(cd "$marker_dest" && pwd -P | sed 's|//|/|g')
  run_cmd sh -c "
    export SPELLBOOK_DIR='$spellbook_dir'
    export WIZARDRY_DIR='$ROOT_DIR'
    set -- to marker 1
    . '$ROOT_DIR/spells/translocation/jump'
    new_dir=\$(pwd -P | sed 's|//|/|g')
    [ \"\$new_dir\" = '$marker_resolved' ]
  "
  assert_success || return 1
  # Check that some output was produced (any of the random arrival messages)
  [ -n "$OUTPUT" ] || return 1
}

test_jump_marker_direct() {
  skip-if-compiled || return $?
  stub=$(make_tempdir)
  spellbook_dir="$stub/spellbook"
  markers_dir="$spellbook_dir/.markers"
  marker_dest="$stub/destination"
  mkdir -p "$markers_dir" "$marker_dest"
  
  # Create a marker
  printf '%s\n' "$marker_dest" > "$markers_dir/myplace"
  
  # Test jump <marker> delegation
  marker_resolved=$(cd "$marker_dest" && pwd -P | sed 's|//|/|g')
  run_cmd sh -c "
    export SPELLBOOK_DIR='$spellbook_dir'
    export WIZARDRY_DIR='$ROOT_DIR'
    set -- myplace
    . '$ROOT_DIR/spells/translocation/jump'
    new_dir=\$(pwd -P | sed 's|//|/|g')
    [ \"\$new_dir\" = '$marker_resolved' ]
  "
  assert_success || return 1
  # Check that some output was produced (any of the random arrival messages)
  [ -n "$OUTPUT" ] || return 1
}

test_jump_spellbook_already_there() {
  skip-if-compiled || return $?
  stub=$(make_tempdir)
  spellbook_dir="$stub/spellbook"
  mkdir -p "$spellbook_dir"
  
  # Start in spellbook and try to jump there
  run_cmd sh -c "
    export SPELLBOOK_DIR='$spellbook_dir'
    cd '$spellbook_dir'
    set -- spellbook
    . '$ROOT_DIR/spells/translocation/jump'
  "
  assert_success || return 1
  assert_output_contains "already in the spellbook" || return 1
}

test_jump_spellbook_missing() {
  skip-if-compiled || return $?
  stub=$(make_tempdir)
  nonexistent="$stub/nonexistent"
  
  run_cmd sh -c "
    export SPELLBOOK_DIR='$nonexistent'
    set -- spellbook
    . '$ROOT_DIR/spells/translocation/jump'
  "
  assert_failure || return 1
  assert_error_contains "does not exist" || return 1
}

# Tests for gloss invocations
test_gloss_jump_spellbook() {
  skip-if-compiled || return $?
  stub=$(make_tempdir)
  spellbook_dir="$stub/spellbook"
  mkdir -p "$spellbook_dir"
  
  spellbook_resolved=$(cd "$spellbook_dir" && pwd -P | sed 's|//|/|g')
  run_cmd sh -c "
    export WIZARDRY_DIR='$ROOT_DIR'
    export SPELLBOOK_DIR='$spellbook_dir'
    export PATH='$WIZARDRY_IMPS_PATH:/bin:/usr/bin'
    # Generate glosses and source them
    eval \"\$(PATH='$WIZARDRY_IMPS_PATH:/bin:/usr/bin' '$ROOT_DIR/spells/.wizardry/generate-glosses' --quiet)\"
    # Now call the gloss function
    jump spellbook
    result=\$?
    new_dir=\$(pwd -P | sed 's|//|/|g')
    [ \"\$result\" -eq 0 ] && [ \"\$new_dir\" = '$spellbook_resolved' ]
  "
  assert_success
}

test_gloss_jump_wizardry() {
  skip-if-compiled || return $?
  
  # Use ROOT_DIR as the wizardry directory
  wizardry_resolved=$(cd "$ROOT_DIR" && pwd -P | sed 's|//|/|g')
  run_cmd sh -c "
    export WIZARDRY_DIR='$ROOT_DIR'
    export PATH='$WIZARDRY_IMPS_PATH:/bin:/usr/bin'
    # Generate glosses and source them
    eval \"\$(PATH='$WIZARDRY_IMPS_PATH:/bin:/usr/bin' '$ROOT_DIR/spells/.wizardry/generate-glosses' --quiet)\"
    # Now call the gloss function
    jump wizardry
    result=\$?
    new_dir=\$(pwd -P | sed 's|//|/|g')
    [ \"\$result\" -eq 0 ] && [ \"\$new_dir\" = '$wizardry_resolved' ]
  "
  assert_success
}

test_gloss_jump_home() {
  skip-if-compiled || return $?
  stub=$(make_tempdir)
  home_dir="$stub/home"
  mkdir -p "$home_dir"
  
  home_resolved=$(cd "$home_dir" && pwd -P | sed 's|//|/|g')
  run_cmd sh -c "
    export WIZARDRY_DIR='$ROOT_DIR'
    export HOME='$home_dir'
    export PATH='$WIZARDRY_IMPS_PATH:/bin:/usr/bin'
    # Generate glosses and source them
    eval \"\$(PATH='$WIZARDRY_IMPS_PATH:/bin:/usr/bin' '$ROOT_DIR/spells/.wizardry/generate-glosses' --quiet)\"
    # Now call the gloss function
    jump home
    result=\$?
    new_dir=\$(pwd -P | sed 's|//|/|g')
    [ \"\$result\" -eq 0 ] && [ \"\$new_dir\" = '$home_resolved' ]
  "
  assert_success
}

run_test_case "jump prints usage" test_help
run_test_case "jump fails without args" test_no_args
run_test_case "jump spellbook works" test_jump_spellbook
run_test_case "jump wizardry works" test_jump_wizardry
run_test_case "jump home works" test_jump_home
run_test_case "jump trash delegates" test_jump_trash_delegation
run_test_case "jump to marker delegates" test_jump_to_marker_delegation
run_test_case "jump <marker> delegates" test_jump_marker_direct
run_test_case "jump spellbook already there" test_jump_spellbook_already_there
run_test_case "jump spellbook missing" test_jump_spellbook_missing
run_test_case "jump spellbook via gloss" test_gloss_jump_spellbook
run_test_case "jump wizardry via gloss" test_gloss_jump_wizardry
run_test_case "jump home via gloss" test_gloss_jump_home

finish_tests
