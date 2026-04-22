#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_configure_fauxzilla_client_help() {
  run_spell "spells/.arcana/web-wizardry/configure-fauxzilla-client" --help
  assert_success && assert_output_contains "Firefox enterprise policy"
}

test_configure_fauxzilla_client_forwards_to_repo_spell() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  repo_dir="$tmp/repo"
  mkdir -p "$repo_dir/.git" "$repo_dir/wizardry"
  cat >"$repo_dir/wizardry/configure-fauxzilla-client" <<'EOF'
#!/bin/sh
set -eu
printf 'args=%s\n' "$*"
EOF
  chmod +x "$repo_dir/wizardry/configure-fauxzilla-client"

  FAUXZILLA_REPO_DIR="$repo_dir" \
    FAUXZILLA_SKIP_REPO_UPDATE=1 \
    run_spell "spells/.arcana/web-wizardry/configure-fauxzilla-client" \
      --check \
      --non-interactive
  assert_success || return 1
  assert_output_contains "args=--check --non-interactive" || return 1
}

test_configure_fauxzilla_client_reports_missing_repo_spell() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  repo_dir="$tmp/repo"
  mkdir -p "$repo_dir/.git"

  FAUXZILLA_REPO_DIR="$repo_dir" \
    FAUXZILLA_SKIP_REPO_UPDATE=1 \
    run_spell "spells/.arcana/web-wizardry/configure-fauxzilla-client" \
      --check \
      --non-interactive
  assert_failure || return 1
  assert_error_contains "repo checkout is missing" || return 1
}

run_test_case "configure-fauxzilla-client shows help" test_configure_fauxzilla_client_help
run_test_case "configure-fauxzilla-client forwards to Fauxzilla repo helper" test_configure_fauxzilla_client_forwards_to_repo_spell
run_test_case "configure-fauxzilla-client reports missing repo helper" test_configure_fauxzilla_client_reports_missing_repo_spell
finish_tests
