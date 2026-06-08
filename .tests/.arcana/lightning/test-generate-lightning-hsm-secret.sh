#!/bin/sh
# Behavioral coverage for generate-lightning-hsm-secret.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/lightning/generate-lightning-hsm-secret"

test_generate_lightning_hsm_secret_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: generate-lightning-hsm-secret" || return 1
}

test_generate_lightning_hsm_secret_requires_hsmtool() {
  tmpdir=$(make_tempdir)

  run_cmd env \
    HOME="$tmpdir/home" \
    PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" \
    WIZARDRY_DIR="$ROOT_DIR" \
    sh "$ROOT_DIR/$target"
  assert_failure || return 1
  assert_output_contains "Core Lightning hsmtool is not installed yet" || return 1
}

test_generate_lightning_hsm_secret_allows_decline_before_generation() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"

  cat > "$stub_dir/lightning-hsmtool" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/lightning-hsmtool"

  run_cmd env \
    HOME="$tmpdir/home" \
    PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" \
    WIZARDRY_DIR="$ROOT_DIR" \
    sh -c "printf 'n\n' | sh '$ROOT_DIR/$target'"
  assert_success || return 1
  assert_output_contains "Secret generation stayed paused." || return 1
}

run_test_case "generate-lightning-hsm-secret shows help" test_generate_lightning_hsm_secret_help
run_test_case "generate-lightning-hsm-secret requires hsmtool" \
  test_generate_lightning_hsm_secret_requires_hsmtool
run_test_case "generate-lightning-hsm-secret allows decline before generation" \
  test_generate_lightning_hsm_secret_allows_decline_before_generation

finish_tests
