#!/bin/sh
# Tests for toggle-cd spell
# Behavioral cases:
# - toggle-cd installs the hook when not present
# - toggle-cd uninstalls the hook when present
# - toggle-cd --help shows usage

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_toggle_cd_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/mud/toggle-cd" ]
}

test_toggle_cd_requires_cd_spell() {
  content=$(cat "$ROOT_DIR/spells/.arcana/mud/toggle-cd")
  case "$content" in
    *CD_SPELL*cd*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="toggle-cd should reference the cd spell"
      return 1
      ;;
  esac
}

test_toggle_cd_has_install_and_uninstall() {
  content=$(cat "$ROOT_DIR/spells/.arcana/mud/toggle-cd")
  case "$content" in
    *install*uninstall*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="toggle-cd should handle both install and uninstall"
      return 1
      ;;
  esac
}

test_toggle_cd_installs_when_not_present() {
  tmp=$(_make_tempdir)
  # Create an empty rc file without the hook
  : >"$tmp/rc"
  
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/toggle-cd"
  _assert_success || return 1
  _assert_output_contains "cd hook enabled" || return 1
  
  # Verify hook was installed
  if ! grep -q ">>> wizardry cd cantrip >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook not installed after toggle"
    return 1
  fi
}

test_toggle_cd_uninstalls_when_present() {
  tmp=$(_make_tempdir)
  
  # First install the hook
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/cd" install
  _assert_success || return 1
  
  # Now toggle should uninstall it
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/toggle-cd"
  _assert_success || return 1
  _assert_output_contains "cd hook disabled" || return 1
  
  # Verify hook was removed
  if grep -q ">>> wizardry cd cantrip >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook still present after toggle off"
    return 1
  fi
}

test_toggle_cd_help_shows_usage() {
  _run_spell spells/.arcana/mud/toggle-cd --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
  _assert_output_contains "toggle" || return 1
}

test_toggle_cd_shows_installing_message() {
  tmp=$(_make_tempdir)
  # Create an empty rc file without the hook
  : >"$tmp/rc"
  
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/toggle-cd"
  _assert_success || return 1
  # Verify it shows the progress message before install
  _assert_output_contains "Installing cd hook" || return 1
}

test_toggle_cd_shows_uninstalling_message() {
  tmp=$(_make_tempdir)
  
  # First install the hook
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/cd" install
  _assert_success || return 1
  
  # Now toggle should uninstall it and show a progress message
  # Create detect-rc-file stub
  cat >"$tmp/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\n' '$tmp/rc'
EOF
  chmod +x "$tmp/detect-rc-file"
  
  _run_cmd env PATH="$tmp:$PATH" "$ROOT_DIR/spells/.arcana/mud/toggle-cd"
  _assert_success || return 1
  # Verify it shows the progress message before uninstall
  _assert_output_contains "Uninstalling cd hook" || return 1
}

_run_test_case "toggle-cd is executable" test_toggle_cd_is_executable
_run_test_case "toggle-cd requires cd spell" test_toggle_cd_requires_cd_spell
_run_test_case "toggle-cd handles install and uninstall" test_toggle_cd_has_install_and_uninstall
_run_test_case "toggle-cd installs when not present" test_toggle_cd_installs_when_not_present
_run_test_case "toggle-cd uninstalls when present" test_toggle_cd_uninstalls_when_present
_run_test_case "toggle-cd --help shows usage" test_toggle_cd_help_shows_usage
_run_test_case "toggle-cd shows installing message" test_toggle_cd_shows_installing_message
_run_test_case "toggle-cd shows uninstalling message" test_toggle_cd_shows_uninstalling_message
_finish_tests
