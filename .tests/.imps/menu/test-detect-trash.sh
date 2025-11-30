#!/bin/sh
# Tests for the 'detect-trash' imp

. "${0%/*}/../../test-common.sh"

test_detect_trash_outputs_path() {
  run_spell spells/.imps/menu/detect-trash
  assert_success || return 1
  # Should output a non-empty path
  [ -n "$OUTPUT" ] || { TEST_FAILURE_REASON="should output trash path"; return 1; }
}

test_detect_trash_macos_path() {
  stub=$(make_tempdir)
  # Create uname stub for macOS detection
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Darwin\n'
STUB
  chmod +x "$stub/uname"

  # Run detect-trash with custom HOME by wrapping in a shell script
  run_cmd sh -c "
    HOME='/Users/testuser'
    export HOME
    PATH='$stub:/bin:/usr/bin'
    export PATH
    '$ROOT_DIR/spells/.imps/menu/detect-trash'
  "
  assert_success || return 1
  assert_output_contains "/Users/testuser/.Trash" || return 1
}

test_detect_trash_linux_path() {
  stub=$(make_tempdir)
  # Create uname stub for Linux detection
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$stub/uname"

  # Run detect-trash with custom HOME by wrapping in a shell script
  run_cmd sh -c "
    HOME='/home/testuser'
    export HOME
    PATH='$stub:/bin:/usr/bin'
    export PATH
    '$ROOT_DIR/spells/.imps/menu/detect-trash'
  "
  assert_success || return 1
  assert_output_contains "/home/testuser/.local/share/Trash/files" || return 1
}

test_detect_trash_xdg_override() {
  stub=$(make_tempdir)
  # Create uname stub for Linux detection
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$stub/uname"

  # Run detect-trash with custom HOME and XDG_DATA_HOME
  run_cmd sh -c "
    HOME='/home/testuser'
    XDG_DATA_HOME='/custom/data'
    export HOME XDG_DATA_HOME
    PATH='$stub:/bin:/usr/bin'
    export PATH
    '$ROOT_DIR/spells/.imps/menu/detect-trash'
  "
  assert_success || return 1
  assert_output_contains "/custom/data/Trash/files" || return 1
}

test_detect_trash_unsupported_os() {
  stub=$(make_tempdir)
  # Create uname stub for unknown OS
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'FreeBSD\n'
STUB
  chmod +x "$stub/uname"
  link_tools "$stub" sh printf

  run_cmd sh -c "
    PATH='$stub'
    export PATH
    '$ROOT_DIR/spells/.imps/menu/detect-trash'
  "
  assert_failure || return 1
  assert_error_contains "unsupported operating system" || return 1
}

run_test_case "detect-trash outputs path" test_detect_trash_outputs_path
run_test_case "detect-trash returns macOS path" test_detect_trash_macos_path
run_test_case "detect-trash returns Linux path" test_detect_trash_linux_path
run_test_case "detect-trash respects XDG_DATA_HOME" test_detect_trash_xdg_override
run_test_case "detect-trash fails on unsupported OS" test_detect_trash_unsupported_os

finish_tests
