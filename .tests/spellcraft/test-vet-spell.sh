#!/bin/sh
# Behavioral cases for vet-spell:
# - vet-spell prints usage with --help
# - vet-spell rejects unknown options
# - vet-spell fails for nonexistent files
# - vet-spell passes well-formed spells
# - vet-spell fails spells missing shebang
# - vet-spell fails spells missing description comment
# - vet-spell fails spells missing strict mode
# - vet-spell fails spells with trailing space assignment
# - vet-spell skips usage/help checks for imps
# - vet-spell requires usage function for non-imp spells
# - vet-spell requires help handler for non-imp spells

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


make_spell_dir() {
  dir=$(make_tempdir)
  printf '%s\n' "$dir"
}

test_help() {
  run_spell "spells/spellcraft/vet-spell" --help
  assert_success && assert_output_contains "Usage: vet-spell"
}

test_usage_alias() {
  run_spell "spells/spellcraft/vet-spell" --usage
  assert_success && assert_output_contains "Usage: vet-spell"
}

test_passes_well_formed_spell() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/good-spell" <<'EOF'
#!/bin/sh

# This is a good spell that does something useful.
# It has proper documentation.

show_usage() {
  cat <<'USAGE'
Usage: good-spell

Does something useful.
USAGE
}

case "${1-}" in
--help|--usage|-h)
  show_usage
  exit 0
  ;;
esac

set -eu

echo "Hello from good spell"
EOF
  chmod +x "$spell_dir/good-spell"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/good-spell"
  assert_success && assert_output_contains "passed"
}

test_fails_missing_shebang() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/bad-spell" <<'EOF'
# No shebang here

set -eu

echo "bad"
EOF
  chmod +x "$spell_dir/bad-spell"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/bad-spell"
  assert_failure && assert_output_contains "shebang"
}

test_fails_wrong_shebang() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/bad-spell" <<'EOF'
#!/bin/bash

# Bad shebang

set -eu

echo "bad"
EOF
  chmod +x "$spell_dir/bad-spell"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/bad-spell"
  assert_failure && assert_output_contains "shebang"
}

test_fails_missing_description() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/bad-spell" <<'EOF'
#!/bin/sh

set -eu

echo "bad"
EOF
  chmod +x "$spell_dir/bad-spell"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/bad-spell"
  assert_failure && assert_output_contains "description comment"
}

test_fails_missing_strict_mode() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/bad-spell" <<'EOF'
#!/bin/sh

# This spell lacks strict mode.

echo "bad"
EOF
  chmod +x "$spell_dir/bad-spell"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/bad-spell"
  assert_failure && assert_output_contains "strict mode"
}

test_fails_trailing_space_assignment() {
  spell_dir=$(make_spell_dir)
  # Create spell with trailing space in assignment
  printf '%s\n' '#!/bin/sh' '' '# Spell with bad assignment.' '' 'set -eu' '' 'var= ' '' 'echo "$var"' >"$spell_dir/bad-spell"
  chmod +x "$spell_dir/bad-spell"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/bad-spell"
  assert_failure && assert_output_contains "trailing space"
}

test_passes_imp_without_usage() {
  spell_dir=$(make_spell_dir)
  mkdir -p "$spell_dir/.imps"
  cat >"$spell_dir/.imps/simple-imp" <<'EOF'
#!/bin/sh

# Print the current date.

set -eu

date
EOF
  chmod +x "$spell_dir/.imps/simple-imp"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/.imps/simple-imp"
  assert_success && assert_output_contains "passed"
}

test_requires_usage_function() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/no-usage-spell" <<'EOF'
#!/bin/sh

# This spell has no usage function.

set -eu

echo "hello"
EOF
  chmod +x "$spell_dir/no-usage-spell"
  
  # Should fail without a usage function
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/no-usage-spell"
  assert_failure && assert_output_contains "usage function"
}

test_requires_help_handler() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/no-help-spell" <<'EOF'
#!/bin/sh

# This spell has no help handler.

show_usage() {
  echo "Usage: no-help-spell"
}

set -eu

echo "hello"
EOF
  chmod +x "$spell_dir/no-help-spell"
  
  # Should fail without a help handler
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/no-help-spell"
  assert_failure && assert_output_contains "help"
}

test_list_option() {
  run_spell "spells/spellcraft/vet-spell" --list --only "look"
  assert_success && assert_output_contains "spells/mud/look"
}

test_unknown_option() {
  run_spell "spells/spellcraft/vet-spell" --unknown
  assert_failure && assert_error_contains "unknown option"
}

test_fails_nonexistent_file() {
  run_spell "spells/spellcraft/vet-spell" "/nonexistent/path/to/spell"
  assert_failure && assert_output_contains "file not found"
}

run_test_case "vet-spell prints usage" test_help
run_test_case "vet-spell accepts --usage" test_usage_alias
run_test_case "vet-spell rejects unknown option" test_unknown_option
run_test_case "vet-spell fails for nonexistent file" test_fails_nonexistent_file
run_test_case "vet-spell passes well-formed spell" test_passes_well_formed_spell
run_test_case "vet-spell fails missing shebang" test_fails_missing_shebang
run_test_case "vet-spell fails wrong shebang" test_fails_wrong_shebang
run_test_case "vet-spell fails missing description" test_fails_missing_description
run_test_case "vet-spell fails missing strict mode" test_fails_missing_strict_mode
run_test_case "vet-spell fails trailing space assignment" test_fails_trailing_space_assignment
run_test_case "vet-spell passes imp without usage" test_passes_imp_without_usage
run_test_case "vet-spell requires usage function" test_requires_usage_function
run_test_case "vet-spell requires help handler" test_requires_help_handler
run_test_case "vet-spell --list shows matching files" test_list_option

finish_tests
