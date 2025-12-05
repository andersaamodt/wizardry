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

set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


make_stub_dir() {
  dir=$(make_tempdir)
  printf '%s\n' "$dir"
}

test_help() {
  run_spell "spells/arcane/trash" --help
  assert_success && assert_output_contains "Usage: trash"
}

test_no_arguments() {
  run_spell "spells/arcane/trash"
  assert_failure && assert_error_contains "missing file operand"
}

test_unknown_option() {
  run_spell "spells/arcane/trash" --unknown
  assert_failure && assert_error_contains "unknown option"
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
  PATH="$stub:/bin:/usr/bin" run_spell "spells/arcane/trash" "$WIZARDRY_TMPDIR/does_not_exist"
  assert_failure && assert_error_contains "No such file or directory"
}

test_nonexistent_file_with_force() {
  stub=$(make_stub_dir)
  cat >"$stub/gio" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub/gio"
  PATH="$stub:/bin:/usr/bin" run_spell "spells/arcane/trash" -f "$WIZARDRY_TMPDIR/does_not_exist"
  assert_success
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
  PATH="$stub:/bin:/usr/bin" run_spell "spells/arcane/trash" "$target_dir"
  assert_failure && assert_error_contains "Is a directory"
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
  PATH="$stub:/bin:/usr/bin" run_spell "spells/arcane/trash" -r "$target_dir"
  assert_success && assert_file_contains "$log_file" "trash"
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
  PATH="$stub:/bin:/usr/bin" run_spell "spells/arcane/trash" "$target_file"
  assert_success && assert_file_contains "$log_file" "trash"
}

test_calls_osascript_on_macos() {
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
  PATH="$stub:/bin:/usr/bin" run_spell "spells/arcane/trash" "$target_file"
  assert_success && assert_file_contains "$log_file" "Finder"
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
  link_tools "$stub" sh cat printf test env basename dirname pwd command
  PATH="$stub" run_spell "spells/arcane/trash" "$target_file"
  assert_success && assert_file_contains "$log_file" "$target_file"
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
  PATH="$stub:/bin:/usr/bin" run_spell "spells/arcane/trash" "$file1" "$file2"
  assert_success && assert_file_contains "$log_file" "file1.txt" && assert_file_contains "$log_file" "file2.txt"
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
  PATH="$stub:/bin:/usr/bin" run_spell "spells/arcane/trash" -rf "$target_dir" "$WIZARDRY_TMPDIR/nonexistent"
  assert_success && assert_file_contains "$log_file" "testdir"
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
  link_tools "$stub" sh cat printf test env basename dirname pwd
  PATH="$stub" run_spell "spells/arcane/trash" "$target_file"
  assert_failure && assert_error_contains "no supported trash utility"
}

run_test_case "trash prints usage" test_help
run_test_case "trash errors on no arguments" test_no_arguments
run_test_case "trash errors on unknown option" test_unknown_option
run_test_case "trash errors on nonexistent file" test_nonexistent_file
run_test_case "trash ignores nonexistent with -f" test_nonexistent_file_with_force
run_test_case "trash errors on directory without -r" test_directory_without_recursive
run_test_case "trash succeeds on directory with -r" test_directory_with_recursive
run_test_case "trash calls gio on Linux" test_calls_gio_on_linux
run_test_case "trash calls osascript on macOS" test_calls_osascript_on_macos
run_test_case "trash calls trash-put as fallback" test_calls_trash_put_fallback
run_test_case "trash handles multiple files" test_multiple_files
run_test_case "trash handles combined flags -rf" test_combined_flags
run_test_case "trash errors when no trash utility available" test_no_trash_utility
finish_tests
