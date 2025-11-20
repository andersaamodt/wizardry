#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
}

teardown() {
  default_teardown
}

@test 'memorize --all exports detected environment to installable spells' {
  spell_dir="$BATS_TEST_TMPDIR/installables"
  mkdir -p "$spell_dir"

  log="$BATS_TEST_TMPDIR/install_log"
  spell="$spell_dir/stub-spell"
  cat >"$spell" <<EOF_INNER
#!/bin/sh
install() {
  printf '%s\n' "platform=\${WIZARDRY_PLATFORM:-missing}" >>"$log"
  printf '%s\n' "rc=\${WIZARDRY_RC_FILE:-missing}" >>"$log"
  printf '%s\n' "format=\${WIZARDRY_RC_FORMAT:-missing}" >>"$log"
}
EOF_INNER
  chmod +x "$spell"

  detect="$BATS_TEST_TMPDIR/detect"
  cat >"$detect" <<EOF_DETECT
#!/bin/sh
printf '%s\n' "platform=academy" "rc_file=$BATS_TEST_TMPDIR/.wizardrc" "format=starlight"
EOF_DETECT
  chmod +x "$detect"

  MEMORIZE_DETECT_RC_FILE="$detect" run_spell 'spells/memorize' --all "$spell_dir"
  assert_success
  assert_output --partial "Memorizing $spell"

  run cat "$log"
  assert_success
  assert_line 'platform=academy'
  assert_line "rc=$BATS_TEST_TMPDIR/.wizardrc"
  assert_line 'format=starlight'
}

@test 'memorize counts skipped entries when scanning directories' {
  spell_dir="$BATS_TEST_TMPDIR/mixed"
  mkdir -p "$spell_dir"

  log="$BATS_TEST_TMPDIR/mixed_log"
  valid="$spell_dir/valid"
  cat >"$valid" <<EOF_VALID
#!/bin/sh
install() {
  printf 'ok\n' >>"$log"
}
EOF_VALID
  chmod +x "$valid"

  # Not executable, so it should be skipped.
  cat >"$spell_dir/not-executable" <<'EOF_SKIP'
#!/bin/sh
install() { :; }
EOF_SKIP

  # Executable but missing an install() function.
  missing_func="$spell_dir/missing-install"
  cat >"$missing_func" <<'EOF_MISSING'
#!/bin/sh
echo "no install here" >/dev/null
EOF_MISSING
  chmod +x "$missing_func"

  detect="$BATS_TEST_TMPDIR/detect"
  cat >"$detect" <<'EOF_DETECT'
#!/bin/sh
printf '%s\n' "platform=academy" "rc_file=/tmp/.rc" "format=starlight"
EOF_DETECT
  chmod +x "$detect"

  MEMORIZE_DETECT_RC_FILE="$detect" run_spell 'spells/memorize' --all "$spell_dir"
  assert_success
  assert_output --partial 'Memorizing'
  assert_output --partial 'Memorized 1 spell(s); 2 skipped.'

  run cat "$log"
  assert_success
  assert_line 'ok'
}
