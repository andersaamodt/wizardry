#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
}

teardown() {
  default_teardown
}

@test 'detect-magic lists enchanted files with ambience' {
  workdir="$BATS_TEST_TMPDIR/magic"
  mkdir -p "$workdir"
  cat <<'STUB' >"$workdir/read-magic"
#!/bin/sh
case "$1" in
  heavy.txt)
    i=1
    while [ "$i" -le 40 ]; do
      printf 'sigil:%d\n' "$i"
      i=$((i + 1))
    done
    ;;
  light.txt)
    i=1
    while [ "$i" -le 25 ]; do
      printf 'glyph:%d\n' "$i"
      i=$((i + 1))
    done
    ;;
  *)
    exit 0
    ;;
esac
STUB
  chmod +x "$workdir/read-magic"
  printf 'dense' >"$workdir/heavy.txt"
  printf 'faint' >"$workdir/light.txt"

  pushd "$workdir" >/dev/null
  DETECT_MAGIC_READ_MAGIC="$workdir/read-magic" run_spell 'spells/detect-magic'
  popd >/dev/null

  assert_success
  assert_output --partial 'File'
  assert_output --partial 'heavy.txt'
  assert_output --partial 'light.txt'
  assert_output --partial 'I can feel the'
  [[ "$output" != *'ordinary.txt'* ]]
}

@test 'detect-magic can run under plain sh and handles empty rooms' {
  workdir="$BATS_TEST_TMPDIR/magic_empty"
  mkdir -p "$workdir/keep_out"
  cat <<'STUB' >"$workdir/read-magic"
#!/bin/sh
# Offer no enchantments so the spell exercises its gentle fallback.
exit 0
STUB
  chmod +x "$workdir/read-magic"
  : >"$workdir/mild.txt"

  pushd "$workdir" >/dev/null
  run --separate-stderr -- env DETECT_MAGIC_READ_MAGIC="$workdir/read-magic" \
    sh "$ROOT_DIR/spells/detect-magic"
  popd >/dev/null

  assert_success
  assert_output --partial 'No enchantments'
  refute_output --partial 'keep_out'
  refute_output --partial 'mild.txt'
  assert_equal "" "$stderr"
}

@test 'detect-magic whispers intensely when the room overflows with magic' {
  workdir="$BATS_TEST_TMPDIR/magic_overflow"
  mkdir -p "$workdir"
  cat <<'STUB' >"$workdir/read-magic"
#!/bin/sh
case "$1" in
  torrent.txt)
    i=1
    while [ "$i" -le 130 ]; do
      printf 'sigil:%d\n' "$i"
      i=$((i + 1))
    done
    ;;
  *)
    exit 0
    ;;
esac
STUB
  chmod +x "$workdir/read-magic"
  : >"$workdir/torrent.txt"

  pushd "$workdir" >/dev/null
  DETECT_MAGIC_READ_MAGIC="$workdir/read-magic" run_spell 'spells/detect-magic'
  popd >/dev/null

  assert_success
  assert_output --partial 'off the charts'
}

@test 'detect-magic notes faint auras when magic barely stirs' {
  workdir="$BATS_TEST_TMPDIR/magic_gentle"
  mkdir -p "$workdir"
  cat <<'STUB' >"$workdir/read-magic"
#!/bin/sh
if [ "$1" = "glimmer.txt" ]; then
  i=1
  while [ "$i" -le 20 ]; do
    printf 'glyph:%d\n' "$i"
    i=$((i + 1))
  done
fi
STUB
  chmod +x "$workdir/read-magic"
  : >"$workdir/glimmer.txt"

  pushd "$workdir" >/dev/null
  DETECT_MAGIC_READ_MAGIC="$workdir/read-magic" run_spell 'spells/detect-magic'
  popd >/dev/null

  assert_success
  assert_output --partial 'faint glimmer'
}

@test 'detect-magic sprinkles coloured keywords when available' {
  workdir="$BATS_TEST_TMPDIR/magic_colours"
  mkdir -p "$workdir"
  cat <<'STUB' >"$workdir/read-magic"
#!/bin/sh
case "$1" in
  charged.txt)
    i=1
    while [ "$i" -le 61 ]; do
      printf 'sigil:%d\n' "$i"
      i=$((i + 1))
    done
    ;;
  *)
    exit 0
    ;;
esac
STUB
  chmod +x "$workdir/read-magic"
  : >"$workdir/charged.txt"

  pushd "$workdir" >/dev/null
  DETECT_MAGIC_READ_MAGIC="$workdir/read-magic" run_spell 'spells/detect-magic'
  popd >/dev/null

  assert_success
  assert_output --partial $'\033[0;35m'
  assert_output --partial $'magic\033[0m in these files is almost tangible'
}

@test 'detect-magic disables colour when requested' {
  workdir="$BATS_TEST_TMPDIR/magic_plain"
  mkdir -p "$workdir"
  cat <<'STUB' >"$workdir/read-magic"
#!/bin/sh
printf 'sigil:1\n'
STUB
  chmod +x "$workdir/read-magic"
  : >"$workdir/soft.txt"

  pushd "$workdir" >/dev/null
  NO_COLOR=1 DETECT_MAGIC_READ_MAGIC="$workdir/read-magic" run_spell 'spells/detect-magic'
  popd >/dev/null

  assert_success
  refute_output --partial $'\033'
  assert_output --partial 'soft.txt'
}

@test 'detect-magic reports missing helper loudly' {
  workdir="$BATS_TEST_TMPDIR/magic_missing"
  mkdir -p "$workdir/bin"
  cp "$ROOT_DIR/spells/detect-magic" "$workdir/bin/detect-magic"
  chmod +x "$workdir/bin/detect-magic"
  pushd "$workdir" >/dev/null
  PATH="/usr/bin:/bin" run --separate-stderr -- "$workdir/bin/detect-magic"
  popd >/dev/null

  assert_failure
  assert_equal "" "$output"
  [[ "$stderr" == *"read-magic spell is missing."* ]] || \
    fail "stderr did not mention missing helper: $stderr"
}

@test 'detect-magic skips files whose enchantments refuse to be read' {
  workdir="$BATS_TEST_TMPDIR/magic_skips"
  mkdir -p "$workdir"
  cat <<'STUB' >"$workdir/read-magic"
#!/bin/sh
case "$1" in
  shy.txt)
    exit 1
    ;;
  eager.txt)
    printf 'sigil:1\n'
    ;;
esac
STUB
  chmod +x "$workdir/read-magic"
  : >"$workdir/shy.txt"
  : >"$workdir/eager.txt"

  pushd "$workdir" >/dev/null
  DETECT_MAGIC_READ_MAGIC="$workdir/read-magic" run_spell 'spells/detect-magic'
  popd >/dev/null

  assert_success
  refute_output --partial 'shy.txt'
  assert_output --partial 'eager.txt'
}

@test 'detect-magic still narrates emptiness when helper responds via coverage path' {
  workdir="$BATS_TEST_TMPDIR/magic_empty_covered"
  mkdir -p "$workdir"
  cat <<'STUB' >"$workdir/read-magic"
#!/bin/sh
exit 0
STUB
  chmod +x "$workdir/read-magic"
  : >"$workdir/echoes.txt"

  pushd "$workdir" >/dev/null
  DETECT_MAGIC_READ_MAGIC="$workdir/read-magic" run_spell 'spells/detect-magic'
  popd >/dev/null

  assert_success
  assert_output --partial 'No enchantments reveal themselves today.'
}

