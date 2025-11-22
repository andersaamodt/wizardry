#!/bin/sh
# Behavioral cases (derived from --help):
# - mud prints usage
# - mud fails when menu dependency is missing
# - mud forwards entries to menu and exits on escape status
# - mud propagates menu errors
# - mud loads optional colors helper when present
# - mud re-runs the menu after successful selections until escape is requested

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

test_colors_helper_is_sourced_when_available() {
  stub_dir=$(mktemp -d "$WIZARDRY_TMPDIR/mud-colors.XXXXXX")
  log="$stub_dir/log"

  cat >"$stub_dir/colors" <<EOF
#!/bin/sh
printf 'colors loaded\n' >>"$log"
CYAN='cyan'
EOF
  chmod +x "$stub_dir/colors"

  cat >"$stub_dir/require-command" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/require-command"

  cat >"$stub_dir/menu" <<'EOF'
#!/bin/sh
exit 113
EOF
  chmod +x "$stub_dir/menu"

  run_cmd env PATH="$stub_dir:$PATH" REQUIRE_COMMAND="$stub_dir/require-command" "$(pwd)/spells/mud"
  assert_success
  assert_file_contains "$log" "colors loaded"
}

test_menu_repeats_until_escape() {
  stub_dir=$(mktemp -d "$WIZARDRY_TMPDIR/mud-repeat.XXXXXX")
  log="$stub_dir/log"
  counter="$stub_dir/calls"

  cat >"$stub_dir/require-command" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/require-command"

  cat >"$stub_dir/menu" <<'EOF'
#!/bin/sh
set -e
log_path="${LOG_PATH:?}"
count_file="${COUNT_FILE:?}"
count=0
if [ -f "$count_file" ]; then
  count=$(cat "$count_file")
fi
count=$((count + 1))
printf '%s\n' "$count" >"$count_file"
printf 'call %s\n' "$count" >>"$log_path"
if [ "$count" -eq 1 ]; then
  exit 0
fi
exit 113
EOF
  chmod +x "$stub_dir/menu"

  run_cmd env LOG_PATH="$log" COUNT_FILE="$counter" PATH="$stub_dir:$PATH" REQUIRE_COMMAND="$stub_dir/require-command" "$(pwd)/spells/mud"
  assert_success
  assert_file_contains "$log" "call 1"
  assert_file_contains "$log" "call 2"
}

run_test_case "mud prints usage" test_help
run_test_case "mud requires menu dependency" test_requires_menu
run_test_case "mud forwards menu entries and exits on escape" test_menu_flow
run_test_case "mud propagates menu failures" test_menu_failure_propagates
run_test_case "mud loads colors helper when present" test_colors_helper_is_sourced_when_available
run_test_case "mud re-runs menu after successful selections" test_menu_repeats_until_escape
finish_tests
