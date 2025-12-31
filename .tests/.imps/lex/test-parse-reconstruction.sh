#!/bin/sh
# Test parse command reconstruction from space-separated arguments

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that parse reconstructs 2-word commands (env or -> env_or)
test_parse_reconstructs_two_word_command() {
  # Create a temp directory for our test spell
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/.imps/sys"
  mkdir -p "$test_spell_dir"
  
  # Create a test imp that will be called
  cat > "$test_spell_dir/env-or" <<'EOF'
#!/bin/sh
# env-or VAR DEFAULT - return env var or default

_env_or() {
  printf 'env_or_called_with:[%s][%s]\n' "$1" "$2"
}

case "$0" in
  */env-or) _env_or "$@" ;; esac
EOF
  chmod +x "$test_spell_dir/env-or"
  
  # Set WIZARDRY_DIR to our temp directory
  export WIZARDRY_DIR="$tmpdir/wizardry"
  export WIZARDRY_DEBUG=1
  
  # Call parse as a first-word gloss would
  # Simulates: env() { parse "env" "$@"; }
  # User types: env or VAR DEFAULT
  run_spell "spells/.imps/lex/parse" "env" "or" "MYVAR" "default_value"
  
  # Should have found and executed env_or with args MYVAR and default_value
  assert_success || return 1
  assert_output_contains "env_or_called_with:[MYVAR][default_value]" || return 1
}

# Test that parse reconstructs 3-word commands
test_parse_reconstructs_three_word_command() {
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/.imps/test"
  mkdir -p "$test_spell_dir"
  
  # Create a 3-word test command
  cat > "$test_spell_dir/make-temp-file" <<'EOF'
#!/bin/sh
# make-temp-file - create a temp file

_make_temp_file() {
  printf 'make_temp_file_called_with:[%s]\n' "$*"
}

case "$0" in
  */make-temp-file) _make_temp_file "$@" ;; esac
EOF
  chmod +x "$test_spell_dir/make-temp-file"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Simulates: make() { parse "make" "$@"; }
  # User types: make temp file myfile.txt
  run_spell "spells/.imps/lex/parse" "make" "temp" "file" "myfile.txt"
  
  assert_success || return 1
  assert_output_contains "make_temp_file_called_with:[myfile.txt]" || return 1
}

# Test that parse reconstructs 4-word commands (maximum)
test_parse_reconstructs_four_word_command() {
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/.imps/test"
  mkdir -p "$test_spell_dir"
  
  # Create a 4-word test command
  cat > "$test_spell_dir/get-remote-file-path" <<'EOF'
#!/bin/sh
# get-remote-file-path - get path from remote

_get_remote_file_path() {
  printf 'get_remote_file_path_called_with:[%s]\n' "$*"
}

case "$0" in
  */get-remote-file-path) _get_remote_file_path "$@" ;; esac
EOF
  chmod +x "$test_spell_dir/get-remote-file-path"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Simulates: get() { parse "get" "$@"; }
  # User types: get remote file path /some/path
  run_spell "spells/.imps/lex/parse" "get" "remote" "file" "path" "/some/path"
  
  assert_success || return 1
  assert_output_contains "get_remote_file_path_called_with:[/some/path]" || return 1
}

# Test that parse prefers longer matches over shorter ones
test_parse_prefers_longer_matches() {
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/.imps/test"
  mkdir -p "$test_spell_dir"
  
  # Create both env and env-or commands
  cat > "$test_spell_dir/env" <<'EOF'
#!/bin/sh
_env() { printf 'WRONG:env_called\n'; }
case "$0" in */env) _env "$@" ;; esac
EOF
  chmod +x "$test_spell_dir/env"
  
  cat > "$test_spell_dir/env-or" <<'EOF'
#!/bin/sh
_env_or() { printf 'CORRECT:env_or_called\n'; }
case "$0" in */env-or) _env_or "$@" ;; esac
EOF
  chmod +x "$test_spell_dir/env-or"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Should match env-or, not env
  run_spell "spells/.imps/lex/parse" "env" "or" "VAR" "DEFAULT"
  
  assert_success || return 1
  assert_output_contains "CORRECT:env_or_called" || return 1
  # Should NOT call the shorter 'env' command
  if printf '%s' "$OUTPUT" | grep -q "WRONG:env_called"; then
    TEST_FAILURE_REASON="Parse called shorter 'env' instead of longer 'env-or'"
    return 1
  fi
}

# Test collision handling: when only single-word exists and it's a system command
test_parse_handles_system_command_collision() {
  # Don't create any wizardry env spell/imp
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/wizardry/spells/.imps/sys"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # When user calls: env
  # And there's no multi-word wizardry command starting with "env"
  # Parse should fall through to system /usr/bin/env
  run_spell "spells/.imps/lex/parse" "env"
  
  # System env with no args should succeed and output env vars
  assert_success || return 1
}

# Test that parse tries progressively shorter combinations
test_parse_tries_progressively_shorter() {
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/.imps/test"
  mkdir -p "$test_spell_dir"
  
  # Only create the 2-word version
  cat > "$test_spell_dir/temp-file" <<'EOF'
#!/bin/sh
_temp_file() { printf 'temp_file_called_with:[%s]\n' "$*"; }
case "$0" in */temp-file) _temp_file "$@" ;; esac
EOF
  chmod +x "$test_spell_dir/temp-file"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # User types: temp file with extra args
  # Should try: temp_file_with_extra (not found)
  # Should try: temp_file_with (not found)
  # Should try: temp_file (FOUND!)
  # Should call temp_file with args: "with" "extra" "args"
  run_spell "spells/.imps/lex/parse" "temp" "file" "with" "extra" "args"
  
  assert_success || return 1
  assert_output_contains "temp_file_called_with:[with extra args]" || return 1
}

# Run all tests
run_test_case "parse reconstructs 2-word commands" test_parse_reconstructs_two_word_command
run_test_case "parse reconstructs 3-word commands" test_parse_reconstructs_three_word_command
run_test_case "parse reconstructs 4-word commands" test_parse_reconstructs_four_word_command
run_test_case "parse prefers longer matches" test_parse_prefers_longer_matches
run_test_case "parse handles system command collisions" test_parse_handles_system_command_collision
run_test_case "parse tries progressively shorter combinations" test_parse_tries_progressively_shorter

finish_tests
