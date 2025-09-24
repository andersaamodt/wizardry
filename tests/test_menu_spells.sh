#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"

stub_dir=$(make_temp_dir)
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
echo "ready"
ALPHA
chmod +x "$stub_dir/alpha-status"

touch "$stub_dir/alpha-menu" "$stub_dir/beta-menu"
chmod +x "$stub_dir/alpha-menu" "$stub_dir/beta-menu"

if [[ $PATH == "$stub_dir:"* ]]; then
  BASE_PATH=${PATH#"$stub_dir:"}
else
  BASE_PATH=$PATH
fi

export MENU_LOG="$menu_log"
export INSTALL_MENU_ROOT="$ROOT_DIR/spells/menu"
export INSTALL_MENU_DIRS="alpha beta"

PATH="$stub_dir:$BASE_PATH" run_script "spells/menu/install-menu"
expect_in_output "MENU:Install Menu:" "$RUN_STDOUT"
expect_in_output "alpha" "$RUN_STDOUT"
expect_in_output "ready" "$RUN_STDOUT"
expect_in_output "beta" "$RUN_STDOUT"
expect_in_output "coming soon" "$RUN_STDOUT"
expect_in_output "exiting" "$RUN_STDOUT"

# The main menu should hand its options to the menu command.
>"$menu_log"
PATH="$stub_dir:$BASE_PATH" run_script "spells/menu/main-menu"
expect_in_output "MENU:Main Menu:" "$RUN_STDOUT"
expect_in_output "Install Menu%install-menu" "$RUN_STDOUT"
expect_in_output "Exit%kill -2" "$RUN_STDOUT"
expect_in_output "exiting" "$RUN_STDOUT"

assert_all_expectations_met
