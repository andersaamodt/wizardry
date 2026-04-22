#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_install_fauxzilla_help() {
  run_spell "spells/.arcana/web-wizardry/install-fauxzilla" --help
  assert_success && assert_output_contains "Fauxzilla"
}

test_install_fauxzilla_forwards_to_repo_spell() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  repo_dir="$tmp/repo"
  mkdir -p "$repo_dir/.git" "$repo_dir/scripts"
  cat >"$repo_dir/scripts/fauxzilla-install" <<'EOF'
#!/bin/sh
set -eu
printf 'args=%s\n' "$*"
EOF
  chmod +x "$repo_dir/scripts/fauxzilla-install"

  FAUXZILLA_REPO_DIR="$repo_dir" \
    FAUXZILLA_SKIP_REPO_UPDATE=1 \
    run_spell "spells/.arcana/web-wizardry/install-fauxzilla" \
      --hub \
      --configure-browser
  assert_success || return 1
  assert_output_contains "args=--hub --configure-browser" || return 1
}

run_test_case "install-fauxzilla shows help" test_install_fauxzilla_help
run_test_case "install-fauxzilla forwards to Fauxzilla repo helper" test_install_fauxzilla_forwards_to_repo_spell
finish_tests
