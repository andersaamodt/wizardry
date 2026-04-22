#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_is_web_component_installed_help() {
  run_spell "spells/.arcana/web-wizardry/is-web-component-installed" --help
  assert_success || return 1
  assert_output_contains "fauxzilla" || return 1
}

test_is_web_component_installed_reports_fauxzilla_present() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  repo_dir="$tmp/repo"
  mkdir -p "$repo_dir/.git" "$repo_dir/scripts"
  cat >"$repo_dir/scripts/fauxzilla-check" <<'EOF'
#!/bin/sh
set -eu
printf 'status=ok\n'
printf 'summary=ready\n'
EOF
  chmod +x "$repo_dir/scripts/fauxzilla-check"

  FAUXZILLA_REPO_DIR="$repo_dir" \
    run_spell "spells/.arcana/web-wizardry/is-web-component-installed" fauxzilla
  assert_success || return 1
}

test_is_web_component_installed_reports_fauxzilla_absent() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  repo_dir="$tmp/repo"
  mkdir -p "$repo_dir/.git" "$repo_dir/scripts"
  cat >"$repo_dir/scripts/fauxzilla-check" <<'EOF'
#!/bin/sh
set -eu
printf 'status=bad\n'
printf 'summary=missing\n'
EOF
  chmod +x "$repo_dir/scripts/fauxzilla-check"

  FAUXZILLA_REPO_DIR="$repo_dir" \
    run_spell "spells/.arcana/web-wizardry/is-web-component-installed" fauxzilla
  assert_failure || return 1
}

run_test_case "is-web-component-installed shows help" test_is_web_component_installed_help
run_test_case "is-web-component-installed reports Fauxzilla present" test_is_web_component_installed_reports_fauxzilla_present
run_test_case "is-web-component-installed reports Fauxzilla absent" test_is_web_component_installed_reports_fauxzilla_absent
finish_tests
