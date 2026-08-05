#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

transcribe_shows_help() {
  run_spell spells/.arcana/voice-recognition/voice-recognition-transcribe --help
  assert_success
}

transcribe_requires_audio_path() {
  run_spell spells/.arcana/voice-recognition/voice-recognition-transcribe
  assert_status 2
}

transcribe_rejects_missing_audio_file() {
  run_spell spells/.arcana/voice-recognition/voice-recognition-transcribe /definitely/missing/audio.wav
  assert_failure || return 1
  assert-error-contains 'audio file not found'
}

run_test_case "voice recognition transcribe shows help" transcribe_shows_help
run_test_case "voice recognition transcribe requires audio" transcribe_requires_audio_path
run_test_case "voice recognition transcribe rejects missing audio" transcribe_rejects_missing_audio_file
finish_tests
