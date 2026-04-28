#!/bin/sh
# Tests for the 'web-wizardry' spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_web_wizardry_help() {
  run_spell spells/web/web-wizardry --help
  assert_success
  assert_output_contains "Usage: web-wizardry"
  assert_output_contains "create"
  assert_output_contains "create-from-template"
  assert_output_contains "build"
  assert_output_contains "rebuild"
  assert_output_contains "autorebuild"
}

test_web_wizardry_create_site() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Stub sudo so fix-site-security doesn't create privileged directories
  stub_dir=$(temp-dir wizardry-stub)
  stub-sudo "$stub_dir"
  export PATH="$stub_dir:$PATH"
  
  # Create a test site
  run_spell spells/web/web-wizardry create testsite
  assert_success
  
  # Verify site directory exists (WEB_WIZARDRY_ROOT/sitename, not WEB_WIZARDRY_ROOT/sites/sitename)
  [ -d "$test_web_root/testsite" ] || {
    TEST_FAILURE_REASON="site directory not created"
    return 1
  }
  
  # Verify default files exist
  [ -f "$test_web_root/testsite/site/pages/index.md" ] || {
    TEST_FAILURE_REASON="index.md not created"
    return 1
  }
  
  # Cleanup
  rm -rf "$test_web_root" "$stub_dir"
}

test_web_wizardry_status() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Stub sudo so fix-site-security doesn't create privileged directories
  stub_dir=$(temp-dir wizardry-stub)
  stub-sudo "$stub_dir"
  export PATH="$stub_dir:$PATH"
  
  # Create a test site
  run_spell spells/web/web-wizardry create testsite
  assert_success
  
  # Check status
  run_spell spells/web/web-wizardry status testsite
  assert_success
  assert_output_contains "testsite"
  
  # Cleanup
  rm -rf "$test_web_root" "$stub_dir"
}

test_web_wizardry_autorebuild_requires_site() {
  run_spell spells/web/web-wizardry autorebuild
  assert_status 2
  assert_error_contains "autorebuild requires SITENAME argument"
}

test_web_wizardry_create_from_template_requires_args() {
  run_spell spells/web/web-wizardry create-from-template
  assert_status 2
  assert_error_contains "create-from-template requires SITENAME and TEMPLATE"
}

test_web_wizardry_rebuild_requires_site() {
  run_spell spells/web/web-wizardry rebuild
  assert_status 2
  assert_error_contains "rebuild requires SITENAME argument"
}

test_web_wizardry_rejects_path_shaped_site_names() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir wizardry-path-test)
  mkdir -p "$test_web_root/../escape"

  WEB_WIZARDRY_ROOT="$test_web_root" run_spell spells/web/web-wizardry rebuild ../escape
  assert_status 2 || return 1
  assert_error_contains "invalid site name" || return 1

  rm -rf "$test_web_root" "$test_web_root/../escape"
}

test_web_wizardry_create_from_template_runs_build() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  cat >"$tmp/create-from-template" <<'SH'
#!/bin/sh
printf 'create:%s:%s\n' "$1" "$2" >>"$WEB_WIZARDRY_LOG"
SH
  chmod +x "$tmp/create-from-template"

  cat >"$tmp/build" <<'SH'
#!/bin/sh
printf 'build:%s\n' "$1" >>"$WEB_WIZARDRY_LOG"
SH
  chmod +x "$tmp/build"

  run_cmd env PATH="$tmp:$PATH" WEB_WIZARDRY_LOG="$tmp/log" \
    "$ROOT_DIR/spells/web/web-wizardry" create-from-template mysite demo
  assert_success || return 1

  output=$(cat "$tmp/log")
  case "$output" in
    *"create:mysite:demo"*"\n"*|"create:mysite:demo"*"build:mysite"*) : ;;
    *)
      TEST_FAILURE_REASON="create-from-template flow did not call expected commands: $output"
      return 1
      ;;
  esac
}

test_web_wizardry_rebuild_runs_full_build_and_restart() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  cat >"$tmp/build" <<'SH'
#!/bin/sh
printf 'build:%s:%s\n' "$1" "${2-}" >>"$WEB_WIZARDRY_LOG"
SH
  chmod +x "$tmp/build"

  cat >"$tmp/restart-site" <<'SH'
#!/bin/sh
printf 'restart:%s\n' "$1" >>"$WEB_WIZARDRY_LOG"
SH
  chmod +x "$tmp/restart-site"

  run_cmd env PATH="$tmp:$PATH" WEB_WIZARDRY_LOG="$tmp/log" \
    "$ROOT_DIR/spells/web/web-wizardry" rebuild mysite
  assert_success || return 1

  output=$(cat "$tmp/log")
  case "$output" in
    *"build:mysite:--full"*"\n"*|"build:mysite:--full"*"restart:mysite"*) : ;;
    *)
      TEST_FAILURE_REASON="rebuild flow did not call expected commands: $output"
      return 1
      ;;
  esac
}

run_test_case "web-wizardry --help works" test_web_wizardry_help
run_test_case "web-wizardry can create site" test_web_wizardry_create_site
run_test_case "web-wizardry can show status" test_web_wizardry_status
run_test_case "web-wizardry autorebuild validates sitename" test_web_wizardry_autorebuild_requires_site
run_test_case "web-wizardry create-from-template validates arguments" \
  test_web_wizardry_create_from_template_requires_args
run_test_case "web-wizardry rebuild validates sitename" \
  test_web_wizardry_rebuild_requires_site
run_test_case "web-wizardry rejects path-shaped site names" \
  test_web_wizardry_rejects_path_shaped_site_names
run_test_case "web-wizardry create-from-template builds the site" \
  test_web_wizardry_create_from_template_runs_build
run_test_case "web-wizardry rebuild runs full build and restart" \
  test_web_wizardry_rebuild_runs_full_build_and_restart

finish_tests
