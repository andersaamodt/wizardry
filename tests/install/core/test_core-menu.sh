#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/core/core-menu" ]
}

core_menu_lists_dependencies() {
  tmp=$(make_tempdir)

  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"$MENU_LOG"
SH
  chmod +x "$tmp/menu"

  cat >"$tmp/colors" <<'SH'
#!/bin/sh
BOLD=''
CYAN=''
RESET=''
SH
  chmod +x "$tmp/colors"

  MENU_LOG="$tmp/log" run_cmd env PATH="$tmp:$PATH" MENU_LOOP_LIMIT=1 MENU_LOG="$tmp/log" \
    "$ROOT_DIR/spells/install/core/core-menu"

  assert_success || return 1
  assert_path_exists "$tmp/log" || return 1
  log=$(cat "$tmp/log")

  case "$log" in
    *"Install Bubblewrap"* ) : ;;
    *) TEST_FAILURE_REASON="missing bubblewrap entry"; return 1 ;;
  esac

  case "$log" in
    *"Install all"* ) : ;;
    *) TEST_FAILURE_REASON="missing install all entry"; return 1 ;;
  esac
}

run_test_case "install/core/core-menu is executable" spell_is_executable
run_test_case "core menu lists install targets" core_menu_lists_dependencies
finish_tests
