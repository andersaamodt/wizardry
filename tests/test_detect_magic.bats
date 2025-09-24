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
#!/usr/bin/env bash
case "$1" in
  heavy.txt)
    for i in $(seq 1 40); do
      printf 'sigil:%d\n' "$i"
    done
    ;;
  light.txt)
    for i in $(seq 1 25); do
      printf 'glyph:%d\n' "$i"
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
  RANDOM=0 run_spell 'spells/detect-magic'
  popd >/dev/null

  assert_success
  assert_output --partial 'File'
  assert_output --partial 'heavy.txt'
  assert_output --partial 'light.txt'
  assert_output --partial 'I can feel the'
  [[ "$output" != *'ordinary.txt'* ]]
}

