#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_component_install() {
  root=$1
  component=$2
  comp_dir="$root/$component"
  mkdir -p "$comp_dir/venv/bin"
  cat >"$comp_dir/venv/bin/python" <<'PY'
#!/bin/sh
exit 0
PY
  chmod +x "$comp_dir/venv/bin/python"
  printf 'component=%s\n' "$component" > "$comp_dir/installed"
}

test_uninstall_ctranslate2_whisper_help() {
  run_spell "spells/.arcana/voice-recognition/uninstall-ctranslate2-whisper" --help
  assert_success || return 1
  assert_output_contains "Usage: uninstall-ctranslate2-whisper" || return 1
}

test_uninstall_ctranslate2_whisper_removes_runtime() {
  tmp=$(make_tempdir)
  root="$tmp/voice"
  make_component_install "$root" ctranslate2-whisper

  run_cmd env \
    WIZARDRY_VOICE_RECOGNITION_DIR="$root" \
    "$ROOT_DIR/spells/.arcana/voice-recognition/uninstall-ctranslate2-whisper"
  assert_success || return 1
  assert_path_missing "$root/ctranslate2-whisper" || return 1
}

run_test_case "uninstall-ctranslate2-whisper shows help" test_uninstall_ctranslate2_whisper_help
run_test_case "uninstall-ctranslate2-whisper removes local runtime" test_uninstall_ctranslate2_whisper_removes_runtime

finish_tests
