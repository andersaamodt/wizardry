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

  cat <<'FIND' >"$stub_dir/find"
#!/usr/bin/env bash
if [ "$1" = "$INSTALL_MENU_ROOT" ]; then
  for entry in $INSTALL_MENU_DIRS; do
    printf '%s/%s\n' "$INSTALL_MENU_ROOT" "$entry"
  done
else
  /usr/bin/find "$@"
fi
FIND
  chmod +x "$stub_dir/find"

  cat <<'ALPHA' >"$stub_dir/alpha-status"
#!/usr/bin/env bash
echo 'ready'
ALPHA
  chmod +x "$stub_dir/alpha-status"

  touch "$stub_dir/alpha-menu" "$stub_dir/beta-menu"
  chmod +x "$stub_dir/alpha-menu" "$stub_dir/beta-menu"
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
  export INSTALL_MENU_ROOT="$ROOT_DIR/spells/menu"
  export INSTALL_MENU_DIRS='alpha beta'
  with_menu_path run_spell 'spells/menu/install-menu'
  assert_success
  assert_output --partial 'MENU:Install Menu:'
  assert_output --partial 'alpha'
  assert_output --partial 'ready'
  assert_output --partial 'beta'
  assert_output --partial 'coming soon'
  assert_output --partial 'exiting'
}

@test 'main-menu forwards options to menu command' {
  export MENU_LOG="$menu_log"
  : >"$menu_log"
  with_menu_path run_spell 'spells/menu/main-menu'
  assert_success
  assert_output --partial 'MENU:Main Menu:'
  assert_output --partial 'Install Menu%install-menu'
  assert_output --partial 'Exit%kill -2'
  assert_output --partial 'exiting'
}

