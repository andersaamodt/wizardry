#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - cd installs rc hook when user agrees
# - cd skips installation and still casts look after successful directory change

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

test_cd_installs_hook_when_user_agrees() {
  tmp=$(make_tempdir)
  cat >"$tmp/ask_yn" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/ask_yn"

  run_cmd env PATH="$tmp:$PATH" WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/cantrips/cd" "$tmp"
  assert_success && assert_path_exists "$tmp/rc" && assert_output_contains "installed wizardry hooks"
}

test_cd_casts_look_after_directory_change() {
  tmp=$(make_tempdir)
  cat >"$tmp/ask_yn" <<'SH'
#!/bin/sh
exit 1
SH
  chmod +x "$tmp/ask_yn"
  cat >"$tmp/look" <<'SH'
#!/bin/sh
printf 'looked' > "$PWD/looked"
SH
  chmod +x "$tmp/look"

  target="$WIZARDRY_TMPDIR/room"
  mkdir -p "$target"

  run_cmd env PATH="$tmp:$PATH" WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/cantrips/cd" "$target"
  assert_success && assert_path_exists "$target/looked"
}

run_test_case "cd installs rc hook when user agrees" test_cd_installs_hook_when_user_agrees
run_test_case "cd skips installation and casts look after directory change" test_cd_casts_look_after_directory_change
finish_tests
