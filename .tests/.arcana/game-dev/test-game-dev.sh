#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_game_dev_spells_show_help() {
  for spell in \
    install-godot \
    uninstall-godot \
    is-godot-installed \
    game-dev-menu \
    game-dev-status
  do
    run_cmd "$ROOT_DIR/spells/.arcana/game-dev/$spell" --help
    assert_success || return 1
  done
}

test_game_dev_selects_godot_release_asset() {
  tmp=$(make_tempdir)
  metadata="$tmp/release.json"
  cat >"$metadata" <<'JSON'
{
  "assets": [
    { "browser_download_url": "https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip" },
    { "browser_download_url": "https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_macos.universal.zip" }
  ]
}
JSON

  run_cmd env \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    sh -c '. "$1"; game_dev_release_asset_url "$2" "Godot_v.*_macos[.]universal[.]zip"' \
    sh "$ROOT_DIR/spells/.arcana/game-dev/game-dev-common" "$metadata"
  assert_success || return 1
  assert_output_contains "Godot_v4.7-stable_macos.universal.zip"
}

test_godot_installer_does_not_call_homebrew() {
  if grep -q 'brew ' "$ROOT_DIR/spells/.arcana/game-dev/install-godot" "$ROOT_DIR/spells/.arcana/game-dev/game-dev-common"; then
    TEST_FAILURE_REASON="Godot installer should not call Homebrew"
    return 1
  fi
}

run_test_case "game-dev spells show help" test_game_dev_spells_show_help
run_test_case "game-dev selects Godot release asset" test_game_dev_selects_godot_release_asset
run_test_case "Godot installer does not call Homebrew" test_godot_installer_does_not_call_homebrew

finish_tests
