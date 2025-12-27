#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - trash prints usage with --help
# - trash errors when given no arguments
# - trash errors on unknown options
# - trash errors when file does not exist (without -f)
# - trash ignores nonexistent files with -f
# - trash errors when trashing directory without -r
# - trash succeeds with -r for directories
# - trash calls gio trash on Linux
# - trash calls osascript on macOS
# - trash calls trash-put as fallback
# - trash handles multiple files
# - trash handles combined flags like -rf

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_dir() {
  dir=$(_make_tempdir)
  printf '%s\n' "$dir"
}

test_help() {
  _run_spell "spells/arcane/trash" --help
  _assert_success && _assert_output_contains "Usage: trash"
}

test_no_arguments() {
  _run_spell "spells/arcane/trash"
  _assert_failure && _assert_error_contains "missing file operand"
}

test_unknown_option() {
  _run_spell "spells/arcane/trash" --unknown
  _assert_failure && _assert_error_contains "unknown option"
}

test_nonexistent_file() {
  stub=$(make_stub_dir)
  # Create a stub gio that should not be called
  cat >"$stub/gio" <<'STUB'
#!/bin/sh
printf 'gio called\n' >&2
exit 0
STUB
  chmod +x "$stub/gio"
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" _run_spell "spells/arcane/trash" "$WIZARDRY_TMPDIR/does_not_exist"
  _assert_failure && _assert_error_contains "No such file or directory"
}

test_nonexistent_file_with_force() {
  stub=$(make_stub_dir)
  cat >"$stub/gio" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub/gio"
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" _run_spell "spells/arcane/trash" -f "$WIZARDRY_TMPDIR/does_not_exist"
  _assert_success
}

test_directory_without_recursive() {
  stub=$(make_stub_dir)
  target_dir="$stub/testdir"
  mkdir -p "$target_dir"
  cat >"$stub/gio" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub/gio"
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" _run_spell "spells/arcane/trash" "$target_dir"
  _assert_failure && _assert_error_contains "Is a directory"
}

test_directory_with_recursive() {
  stub=$(make_stub_dir)
  target_dir="$stub/testdir"
  mkdir -p "$target_dir"
  log_file="$stub/gio.log"
  cat >"$stub/gio" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$log_file"
exit 0
STUB
  chmod +x "$stub/gio"
  # Create uname stub for Linux detection
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$stub/uname"
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" _run_spell "spells/arcane/trash" -r "$target_dir"
  _assert_success && _assert_file_contains "$log_file" "trash"
}

test_calls_gio_on_linux() {
  stub=$(make_stub_dir)
  target_file="$stub/testfile.txt"
  printf 'test content\n' >"$target_file"
  log_file="$stub/gio.log"
  cat >"$stub/gio" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$log_file"
exit 0
STUB
  chmod +x "$stub/gio"
  # Create uname stub for Linux detection
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$stub/uname"
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" _run_spell "spells/arcane/trash" "$target_file"
  _assert_success && _assert_file_contains "$log_file" "trash"
}

test_calls_osascript_on_macos() {
  skip-if-compiled || return $?
  stub=$(make_stub_dir)
  target_file="$stub/testfile.txt"
  printf 'test content\n' >"$target_file"
  log_file="$stub/osascript.log"
  cat >"$stub/osascript" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$log_file"
exit 0
STUB
  chmod +x "$stub/osascript"
  # Create uname stub for macOS detection
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Darwin\n'
STUB
  chmod +x "$stub/uname"
  # Remove gio and trash-put from path to ensure osascript is chosen
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" _run_spell "spells/arcane/trash" "$target_file"
  _assert_success && _assert_file_contains "$log_file" "Finder"
}

test_calls_trash_put_fallback() {
  stub=$(make_stub_dir)
  target_file="$stub/testfile.txt"
  printf 'test content\n' >"$target_file"
  log_file="$stub/trash-put.log"
  cat >"$stub/trash-put" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$log_file"
exit 0
STUB
  chmod +x "$stub/trash-put"
  # Create uname stub for Linux
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$stub/uname"
  # Symlink essential utilities but NOT gio, so trash-put is used as fallback
  _link_tools "$stub" sh cat printf test env basename dirname pwd command tr
  PATH="$WIZARDRY_IMPS_PATH:$stub" _run_spell "spells/arcane/trash" "$target_file"
  _assert_success && _assert_file_contains "$log_file" "$target_file"
}

test_multiple_files() {
  stub=$(make_stub_dir)
  file1="$stub/file1.txt"
  file2="$stub/file2.txt"
  printf 'content 1\n' >"$file1"
  printf 'content 2\n' >"$file2"
  log_file="$stub/gio.log"
  cat >"$stub/gio" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$log_file"
exit 0
STUB
  chmod +x "$stub/gio"
  # Create uname stub for Linux detection
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$stub/uname"
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" _run_spell "spells/arcane/trash" "$file1" "$file2"
  _assert_success && _assert_file_contains "$log_file" "file1.txt" && _assert_file_contains "$log_file" "file2.txt"
}

test_combined_flags() {
  stub=$(make_stub_dir)
  target_dir="$stub/testdir"
  mkdir -p "$target_dir"
  log_file="$stub/gio.log"
  cat >"$stub/gio" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$log_file"
exit 0
STUB
  chmod +x "$stub/gio"
  # Create uname stub for Linux detection
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$stub/uname"
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" _run_spell "spells/arcane/trash" -rf "$target_dir" "$WIZARDRY_TMPDIR/nonexistent"
  _assert_success && _assert_file_contains "$log_file" "testdir"
}

test_no_trash_utility() {
  stub=$(make_stub_dir)
  target_file="$stub/testfile.txt"
  printf 'content\n' >"$target_file"
  # Create uname stub for unknown OS
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'FreeBSD\n'
STUB
  chmod +x "$stub/uname"
  # Provide only basic utilities, no trash commands
  _link_tools "$stub" sh cat printf test env basename dirname pwd tr
  PATH="$WIZARDRY_IMPS_PATH:$stub" _run_spell "spells/arcane/trash" "$target_file"
  _assert_failure && _assert_error_contains "no supported trash utility found"
}

_run_test_case "trash prints usage" test_help
_run_test_case "trash errors on no arguments" test_no_arguments
_run_test_case "trash errors on unknown option" test_unknown_option
_run_test_case "trash errors on nonexistent file" test_nonexistent_file
_run_test_case "trash ignores nonexistent with -f" test_nonexistent_file_with_force
_run_test_case "trash errors on directory without -r" test_directory_without_recursive
_run_test_case "trash succeeds on directory with -r" test_directory_with_recursive
_run_test_case "trash calls gio on Linux" test_calls_gio_on_linux
_run_test_case "trash calls osascript on macOS" test_calls_osascript_on_macos
_run_test_case "trash calls trash-put as fallback" test_calls_trash_put_fallback
_run_test_case "trash handles multiple files" test_multiple_files
_run_test_case "trash handles combined flags -rf" test_combined_flags
_run_test_case "trash errors when no trash utility available" test_no_trash_utility
_finish_tests
