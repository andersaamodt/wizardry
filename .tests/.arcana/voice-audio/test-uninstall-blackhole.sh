#!/bin/sh
# Behavioral coverage for uninstall-blackhole.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/voice-audio/uninstall-blackhole"

test_uninstall_blackhole_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: uninstall-blackhole" || return 1
}

test_uninstall_blackhole_dry_run() {
  run_cmd env HOME="$WIZARDRY_TMPDIR/home" WIZARDRY_VOICE_AUDIO_DRY_RUN=1 \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin WIZARDRY_VOICE_AUDIO_HAS_BLACKHOLE=1 \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "dry run would uninstall BlackHole" || return 1
}

test_uninstall_blackhole_reports_absent() {
  run_cmd env HOME="$WIZARDRY_TMPDIR/home" WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    WIZARDRY_VOICE_AUDIO_HAS_BLACKHOLE=0 sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "BlackHole is not installed" || return 1
}

run_test_case "uninstall-blackhole shows help" test_uninstall_blackhole_help
run_test_case "uninstall-blackhole supports dry run" test_uninstall_blackhole_dry_run
run_test_case "uninstall-blackhole reports absent driver" test_uninstall_blackhole_reports_absent

finish_tests
