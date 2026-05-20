#!/bin/sh
# Behavioral coverage for webcam installable spells.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help_callable() {
  for target in \
    spells/.arcana/webcam/is-ffmpeg-installed \
    spells/.arcana/webcam/install-ffmpeg \
    spells/.arcana/webcam/uninstall-ffmpeg \
    spells/.arcana/webcam/is-go2rtc-installed \
    spells/.arcana/webcam/install-go2rtc \
    spells/.arcana/webcam/uninstall-go2rtc \
    spells/.arcana/webcam/webcam-status; do
    run_spell "$target" --help
    assert_success || return 1
  done
}

run_test_case "webcam installable help is callable" test_help_callable

finish_tests
