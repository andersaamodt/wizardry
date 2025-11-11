#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
  stub_dir="$BATS_TEST_TMPDIR/menu_stubs"
  mkdir -p "$stub_dir"

  menu_log="$stub_dir/menu.log"
  cat <<'MENU' >"$stub_dir/menu"
#!/usr/bin/env bash
printf 'MENU:%s\n' "$@" | tee -a "$MENU_LOG"
kill -2 "$PPID" 2>/dev/null || true
exit 0
MENU
  chmod +x "$stub_dir/menu"

  cat <<'ALPHA' >"$stub_dir/alpha-status"
#!/usr/bin/env bash
echo 'ready'
ALPHA
  chmod +x "$stub_dir/alpha-status"

  touch "$stub_dir/alpha-menu" "$stub_dir/beta-menu"
  chmod +x "$stub_dir/alpha-menu" "$stub_dir/beta-menu"
}

make_require_stub() {
  local fail_command=$1
  local message=$2
  local path="$BATS_TEST_TMPDIR/menu-require-${fail_command}"
  cat <<STUB >"$path"
#!/usr/bin/env sh
if [ "\$1" = "$fail_command" ]; then
  printf '%s\n' "require-command: $message" >&2
  exit 1
fi
exec "$ROOT_DIR/spells/cantrips/require-command" "\$@"
STUB
  chmod +x "$path"
  printf '%s\n' "$path"
}

teardown() {
  PATH=$ORIGINAL_PATH
  default_teardown
}

with_menu_path() {
  PATH="$stub_dir:$ORIGINAL_PATH" "$@"
}

@test 'install-menu reports available menu entries' {
  export MENU_LOG="$menu_log"
  export INSTALL_MENU_DIRS='alpha beta'
  with_menu_path run_spell 'spells/menu/install-menu'
  assert_success
  assert_output --partial 'MENU:Install Menu:'
  assert_output --partial 'alpha - ready'
  assert_output --partial 'beta - coming soon'
  assert_output --partial 'exiting'
}

@test 'install-menu reports missing menu command' {
  stub=$(make_require_stub menu "The install-menu spell requires the 'menu' command to present choices.")
  REQUIRE_COMMAND="$stub" run_spell 'spells/menu/install-menu'
  assert_failure
  assert_error --partial "install-menu spell requires the 'menu' command"
}

@test 'main-menu forwards options to menu command' {
  export MENU_LOG="$menu_log"
  : >"$menu_log"
  with_menu_path run_spell 'spells/menu/main-menu'
  assert_success
  assert_output --partial 'MENU:Main Menu:'
  assert_output --partial 'Install Free Software%install-menu'
  assert_output --partial 'Exit%kill -2'
  assert_output --partial 'exiting'
}

