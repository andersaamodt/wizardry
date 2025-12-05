#!/bin/sh
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


spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/node/node-menu" ]
}

run_test_case "install/node/node-menu is executable" spell_is_executable

make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SHI'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -TERM "$PPID" 2>/dev/null || exit 0
SHI
  chmod +x "$tmp/menu"
}

menu_shows_install_when_node_missing() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  cat >"$tmp/exit-label" <<'SHI'
#!/bin/sh
printf '%s' "Exit"
SHI
  chmod +x "$tmp/exit-label"

  cat >"$tmp/node-status" <<'SHI'
#!/bin/sh
echo "not installed"
SHI
  chmod +x "$tmp/node-status"

  MENU_LOG="$tmp/menu.log"

  run_cmd env PATH="$tmp:$ROOT_DIR/spells/cantrips" MENU_LOG="$MENU_LOG" \
    "$ROOT_DIR/spells/install/node/node-menu"

  assert_success || return 1
  assert_path_exists "$MENU_LOG" || return 1
  content=$(cat "$MENU_LOG")
  case "$content" in
    *"Install Node.js%install-node"* ) : ;;
    *) TEST_FAILURE_REASON="install option missing"; return 1 ;;
  esac
  case "$content" in
    *'Exit%kill -TERM $PPID'* ) : ;;
    *) TEST_FAILURE_REASON="exit option missing"; return 1 ;;
  esac
}

run_test_case "node-menu shows install flow when Node.js is absent" menu_shows_install_when_node_missing

menu_places_uninstall_before_exit_when_installed() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"

  cat >"$tmp/exit-label" <<'SHI'
#!/bin/sh
printf '%s' "Exit"
SHI
  chmod +x "$tmp/exit-label"

  cat >"$tmp/node-status" <<'SHI'
#!/bin/sh
echo "installed"
SHI
  chmod +x "$tmp/node-status"

  # Stub node tools and service helpers
  cat >"$tmp/node" <<'SHI'
#!/bin/sh
case "$1" in
  --version)
    echo "v20.0.0"
    ;;
  -e)
    echo "ok"
    ;;
  *)
    :
    ;;
 esac
SHI
  chmod +x "$tmp/node"

  cat >"$tmp/npm" <<'SHI'
#!/bin/sh
case "$1" in
  --version)
    echo "10.0.0"
    ;;
  list)
    echo "npm list"
    ;;
  *)
    :
    ;;
 esac
SHI
  chmod +x "$tmp/npm"

  cat >"$tmp/is-service-installed" <<'SHI'
#!/bin/sh
exit 0
SHI
  chmod +x "$tmp/is-service-installed"

  cat >"$tmp/is-service-running" <<'SHI'
#!/bin/sh
exit 0
SHI
  chmod +x "$tmp/is-service-running"

  MENU_LOG="$tmp/menu.log"
  run_cmd env PATH="$tmp:$ROOT_DIR/spells/cantrips" MENU_LOG="$MENU_LOG" \
    "$ROOT_DIR/spells/install/node/node-menu"

  assert_success || return 1
  assert_path_exists "$MENU_LOG" || return 1

  # Skip the title; inspect menu entries
  entries=$(tail -n +2 "$MENU_LOG")
  last_line=$(printf '%s\n' "$entries" | tail -n 1)
  second_last=$(printf '%s\n' "$entries" | tail -n 2 | head -n 1)

  case "$second_last" in
    "Uninstall Node.js%uninstall-node") : ;;
    *) TEST_FAILURE_REASON="uninstall option should be second to last"; return 1 ;;
  esac

  case "$last_line" in
    *'%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="exit option should be last"; return 1 ;;
  esac

  case "$entries" in
    *"Show Node version%node --version"* ) : ;; 
    *) TEST_FAILURE_REASON="version entry missing"; return 1 ;;
  esac

  case "$entries" in
    *"Restart Node service%sudo systemctl restart node"* ) : ;; 
    *) TEST_FAILURE_REASON="service restart entry missing"; return 1 ;;
  esac
}

run_test_case "node-menu orders uninstall before exit and surfaces node helpers" menu_places_uninstall_before_exit_when_installed

finish_tests
