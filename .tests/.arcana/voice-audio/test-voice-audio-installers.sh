#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/../../.." && pwd -P)
failures=0

run_direct() {
  run_direct_output=$(
    env -i \
      HOME="$HOME" \
      PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
      WIZARDRY_TEST_HELPERS_ONLY=1 \
      "$@" 2>&1
  )
  run_direct_status=$?
}

check_output() {
  check_output_name=$1
  check_output_expected=$2
  shift 2

  if run_direct "$@"; then
    :
  else
    printf '%s\n' "not ok - $check_output_name: exited $run_direct_status"
    printf '%s\n' "$run_direct_output"
    failures=$((failures + 1))
    return 0
  fi

  case "$run_direct_output" in
    *"$check_output_expected"*)
      printf '%s\n' "ok - $check_output_name"
      ;;
    *)
      printf '%s\n' "not ok - $check_output_name: expected output containing '$check_output_expected'"
      printf '%s\n' "$run_direct_output"
      failures=$((failures + 1))
      ;;
  esac
}

check_output \
  "install-blackhole bootstraps when cast directly" \
  "voice-audio: dry run would install BlackHole" \
  WIZARDRY_VOICE_AUDIO_DRY_RUN=1 \
  WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
  WIZARDRY_VOICE_AUDIO_HAS_BLACKHOLE=0 \
  "$ROOT_DIR/spells/.arcana/voice-audio/install-blackhole"

check_output \
  "uninstall-blackhole bootstraps when cast directly" \
  "voice-audio: dry run would uninstall BlackHole" \
  WIZARDRY_VOICE_AUDIO_DRY_RUN=1 \
  WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
  WIZARDRY_VOICE_AUDIO_HAS_BLACKHOLE=1 \
  "$ROOT_DIR/spells/.arcana/voice-audio/uninstall-blackhole"

check_output \
  "install-pipewire bootstraps when cast directly" \
  "voice-audio: PipeWire tools are already installed" \
  WIZARDRY_VOICE_AUDIO_UNAME_S=Linux \
  WIZARDRY_VOICE_AUDIO_HAS_PIPEWIRE=1 \
  "$ROOT_DIR/spells/.arcana/voice-audio/install-pipewire"

if [ "$failures" -gt 0 ]; then
  printf '%s\n' "$failures installer test(s) failed"
  exit 1
fi

printf '%s\n' "all voice-audio installer tests passed"
