#!/bin/sh
# Behavioral coverage for install-blackhole.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/voice-audio/install-blackhole"

test_install_blackhole_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: install-blackhole" || return 1
}

test_install_blackhole_dry_run() {
  run_cmd env HOME="$WIZARDRY_TMPDIR/home" WIZARDRY_VOICE_AUDIO_DRY_RUN=1 \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin WIZARDRY_VOICE_AUDIO_HAS_BLACKHOLE=0 \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "dry run would install BlackHole" || return 1
}

test_install_blackhole_rejects_non_macos() {
  run_cmd env HOME="$WIZARDRY_TMPDIR/home" WIZARDRY_VOICE_AUDIO_UNAME_S=Linux \
    sh "$ROOT_DIR/$target"
  assert_failure || return 1
  assert_error_contains "only supported on macOS" || return 1
}

run_test_case "install-blackhole shows help" test_install_blackhole_help
run_test_case "install-blackhole supports dry run" test_install_blackhole_dry_run
run_test_case "install-blackhole rejects non-macOS" test_install_blackhole_rejects_non_macos

finish_tests
