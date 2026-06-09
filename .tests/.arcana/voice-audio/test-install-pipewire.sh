#!/bin/sh
# Behavioral coverage for install-pipewire.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/voice-audio/install-pipewire"

test_install_pipewire_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: install-pipewire" || return 1
}

test_install_pipewire_already_installed() {
  run_cmd env HOME="$WIZARDRY_TMPDIR/home" WIZARDRY_VOICE_AUDIO_UNAME_S=Linux \
    WIZARDRY_VOICE_AUDIO_HAS_PIPEWIRE=1 sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "PipeWire tools are already installed" || return 1
}

test_install_pipewire_rejects_non_linux() {
  run_cmd env HOME="$WIZARDRY_TMPDIR/home" WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    sh "$ROOT_DIR/$target"
  assert_failure || return 1
  assert_error_contains "only supported on Linux" || return 1
}

run_test_case "install-pipewire shows help" test_install_pipewire_help
run_test_case "install-pipewire exits when already installed" test_install_pipewire_already_installed
run_test_case "install-pipewire rejects non-Linux" test_install_pipewire_rejects_non_linux

finish_tests
