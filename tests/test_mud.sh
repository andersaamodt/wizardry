#!/bin/sh
# Behavioral cases (derived from --help):
# - mud prints usage
# - mud fails when menu dependency is missing
# - mud forwards entries to menu and exits on escape status
# - mud propagates menu errors

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
run_spell "spells/mud" --help
  assert_success && assert_output_contains "Usage: mud"
}

test_requires_menu() {
  stub_dir=$(mktemp -d "$WIZARDRY_TMPDIR/mud-require.XXXXXX")
  log="$stub_dir/log"

  cat >"$stub_dir/require-command" <<EOF
#!/bin/sh
log_path="$log"
printf '%s\n' "\$@" >>"\$log_path"
printf 'missing %s\n' "\$1" >&2
printf '%s\n' "\$2" >&2
exit 1
EOF
  chmod +x "$stub_dir/require-command"

  run_cmd env PATH="$stub_dir:$PATH" REQUIRE_COMMAND="$stub_dir/require-command" "$(pwd)/spells/mud"
  assert_failure && assert_error_contains "missing menu"
  assert_error_contains "The MUD menu needs the 'menu' command"
}

test_menu_flow() {
  stub_dir=$(mktemp -d "$WIZARDRY_TMPDIR/mud-menu.XXXXXX")
  log="$stub_dir/log"

  cat >"$stub_dir/require-command" <<EOF
#!/bin/sh
log_path="$log"
printf 'require %s\n' "\$1" >>"\$log_path"
exit 0
EOF
  chmod +x "$stub_dir/require-command"

  cat >"$stub_dir/menu" <<EOF
#!/bin/sh
log_path="$log"
printf '%s\n' "\$@" >>"\$log_path"
exit 113
EOF
  chmod +x "$stub_dir/menu"

  run_cmd env PATH="$stub_dir:$PATH" REQUIRE_COMMAND="$stub_dir/require-command" "$(pwd)/spells/mud"
  assert_success
  assert_file_contains "$log" "require menu"
  assert_file_contains "$log" "MUD Menu:"
  assert_file_contains "$log" "Look Around%ls"
  assert_file_contains "$log" "Spellbook%spellbook"
}

test_menu_failure_propagates() {
  stub_dir=$(mktemp -d "$WIZARDRY_TMPDIR/mud-error.XXXXXX")

  cat >"$stub_dir/require-command" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/require-command"

  cat >"$stub_dir/menu" <<'EOF'
#!/bin/sh
exit 7
EOF
  chmod +x "$stub_dir/menu"

  run_cmd env PATH="$stub_dir:$PATH" REQUIRE_COMMAND="$stub_dir/require-command" "$(pwd)/spells/mud"
  assert_status 7
}

run_test_case "mud prints usage" test_help
run_test_case "mud requires menu dependency" test_requires_menu
run_test_case "mud forwards menu entries and exits on escape" test_menu_flow
run_test_case "mud propagates menu failures" test_menu_failure_propagates
finish_tests
