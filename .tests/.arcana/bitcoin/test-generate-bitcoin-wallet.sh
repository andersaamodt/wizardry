#!/bin/sh
# Behavioral coverage for generate-bitcoin-wallet.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/bitcoin/generate-bitcoin-wallet"

test_generate_bitcoin_wallet_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: generate-bitcoin-wallet" || return 1
}

test_generate_bitcoin_wallet_requires_bitcoin_cli() {
  tmpdir=$(make_tempdir)

  run_cmd env \
    HOME="$tmpdir/home" \
    PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" \
    WIZARDRY_DIR="$ROOT_DIR" \
    sh "$ROOT_DIR/$target"
  assert_failure || return 1
  assert_output_contains "Bitcoin Core CLI is not installed yet" || return 1
}

test_generate_bitcoin_wallet_allows_decline_before_creation() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"

  cat > "$stub_dir/bitcoin-cli" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/bitcoin-cli"

  run_cmd env \
    HOME="$tmpdir/home" \
    PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" \
    WIZARDRY_DIR="$ROOT_DIR" \
    sh -c "printf 'n\n' | sh '$ROOT_DIR/$target'"
  assert_success || return 1
  assert_output_contains "Wallet creation stayed paused." || return 1
}

run_test_case "generate-bitcoin-wallet shows help" test_generate_bitcoin_wallet_help
run_test_case "generate-bitcoin-wallet requires bitcoin-cli" \
  test_generate_bitcoin_wallet_requires_bitcoin_cli
run_test_case "generate-bitcoin-wallet allows decline before creation" \
  test_generate_bitcoin_wallet_allows_decline_before_creation

finish_tests
