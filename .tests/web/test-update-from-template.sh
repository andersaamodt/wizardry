#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/web/update-from-template --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "update-from-template"
}

test_updates_from_template() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test site from demo template
  WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/create-from-template mytestsite demo
  assert_success
  
  # Modify a template file to simulate customization
  echo "<!-- CUSTOMIZATION -->" >> "$test_web_root/mytestsite/site/pages/index.md"
  
  # Verify customization exists
  grep -q "CUSTOMIZATION" "$test_web_root/mytestsite/site/pages/index.md" || {
    TEST_FAILURE_REASON="customization marker not found before update"
    return 1
  }
  
  # Update from template with --force flag
  WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/update-from-template mytestsite --force
  assert_success
  
  # Verify customization was overwritten (file should be back to original)
  if grep -q "CUSTOMIZATION" "$test_web_root/mytestsite/site/pages/index.md"; then
    TEST_FAILURE_REASON="customization still present after update (should be overwritten)"
    return 1
  fi
  
  # Verify template files exist
  [ -f "$test_web_root/mytestsite/site/pages/index.md" ] || {
    TEST_FAILURE_REASON="index.md not found after update"
    return 1
  }
  
  # Verify site.conf is preserved
  [ -f "$test_web_root/mytestsite/site.conf" ] || {
    TEST_FAILURE_REASON="site.conf not preserved"
    return 1
  }
  
  # Cleanup
  rm -rf "$test_web_root"
}

test_preserves_uploads() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test site
  WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/create-from-template mytestsite demo
  assert_success
  
  # Add a file to uploads
  echo "test upload content" > "$test_web_root/mytestsite/site/uploads/test-file.txt"
  
  # Update from template
  WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/update-from-template mytestsite --force
  assert_success
  
  # Verify upload is still there
  [ -f "$test_web_root/mytestsite/site/uploads/test-file.txt" ] || {
    TEST_FAILURE_REASON="uploads not preserved"
    return 1
  }
  
  # Cleanup
  rm -rf "$test_web_root"
}

test_fails_for_nonexistent_site() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Try to update a nonexistent site
  WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/update-from-template nonexistent --force
  assert_failure
  assert_output_contains "not found"
  
  # Cleanup
  rm -rf "$test_web_root"
}

test_update_uses_web_template_directory() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-wizardry-test)
  fake_wizardry_root=$(temp-dir wizardry-template-root)
  template_root="$fake_wizardry_root/web/minimal"

  mkdir -p "$template_root/pages" "$template_root/static"
  cat > "$template_root/pages/index.md" <<'EOF'
# from template v1
EOF
  cat > "$template_root/static/style.css" <<'EOF'
body { margin: 0; }
EOF

  WIZARDRY_DIR="$fake_wizardry_root" WEB_WIZARDRY_ROOT="$test_web_root" \
    run_spell spells/web/create-from-template minisite minimal
  assert_success

  # Customize file, then change template and verify update restores template content.
  echo "custom line" >> "$test_web_root/minisite/site/pages/index.md"
  cat > "$template_root/pages/index.md" <<'EOF'
# from template v2
EOF

  WIZARDRY_DIR="$fake_wizardry_root" WEB_WIZARDRY_ROOT="$test_web_root" \
    run_spell spells/web/update-from-template minisite --force
  assert_success

  if grep -q "custom line" "$test_web_root/minisite/site/pages/index.md"; then
    TEST_FAILURE_REASON="update-from-template did not overwrite from web template"
    rm -rf "$test_web_root" "$fake_wizardry_root"
    return 1
  fi

  if ! grep -q "from template v2" "$test_web_root/minisite/site/pages/index.md"; then
    TEST_FAILURE_REASON="updated template content not copied from web"
    rm -rf "$test_web_root" "$fake_wizardry_root"
    return 1
  fi
  [ ! -f "$test_web_root/minisite/wizardry-server-requirements.conf" ] || {
    TEST_FAILURE_REASON="requirements file should not exist when template does not define one"
    rm -rf "$test_web_root" "$fake_wizardry_root"
    return 1
  }

  rm -rf "$test_web_root" "$fake_wizardry_root"
}

test_update_refreshes_requirements_file() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-wizardry-test)
  fake_wizardry_root=$(temp-dir wizardry-template-root)
  template_root="$fake_wizardry_root/web/minimal"

  mkdir -p "$template_root/pages" "$template_root/static"
  cat > "$template_root/pages/index.md" <<'EOF'
# from template
EOF
  cat > "$template_root/static/style.css" <<'EOF'
body { margin: 0; }
EOF
  cat > "$template_root/wizardry-server-requirements.conf" <<'EOF'
nostril=required
EOF

  WIZARDRY_DIR="$fake_wizardry_root" WEB_WIZARDRY_ROOT="$test_web_root" \
    run_spell spells/web/create-from-template minisite minimal
  assert_success

  printf '%s\n' 'old=requirement' > "$test_web_root/minisite/wizardry-server-requirements.conf"

  WIZARDRY_DIR="$fake_wizardry_root" WEB_WIZARDRY_ROOT="$test_web_root" \
    run_spell spells/web/update-from-template minisite --force
  assert_success

  if ! grep -q '^nostril=required$' "$test_web_root/minisite/wizardry-server-requirements.conf"; then
    TEST_FAILURE_REASON="requirements file not refreshed from template"
    rm -rf "$test_web_root" "$fake_wizardry_root"
    return 1
  fi

  rm -rf "$test_web_root" "$fake_wizardry_root"
}

test_update_resolves_external_repo_templates() {
  skip-if-compiled || return $?

  fake_home=$(temp-dir wizardry-home)
  fake_wizardry_root="$fake_home/.wizardry"
  fake_git_root="$fake_home/git"
  test_web_root=$(temp-dir web-wizardry-test)
  template_root="$fake_git_root/unix-settings/hosted-web"

  mkdir -p "$fake_wizardry_root"
  mkdir -p "$template_root/pages" "$template_root/static"
  cat > "$template_root/pages/index.md" <<'EOF'
# external template v1
EOF
  cat > "$template_root/static/style.css" <<'EOF'
body { color: #111; }
EOF

  HOME="$fake_home" WIZARDRY_DIR="$fake_wizardry_root" WEB_WIZARDRY_ROOT="$test_web_root" \
    run_spell spells/web/create-from-template settings unix-settings
  assert_success || return 1

  echo "custom line" >> "$test_web_root/settings/site/pages/index.md"
  cat > "$template_root/pages/index.md" <<'EOF'
# external template v2
EOF

  HOME="$fake_home" WIZARDRY_DIR="$fake_wizardry_root" WEB_WIZARDRY_ROOT="$test_web_root" \
    run_spell spells/web/update-from-template settings --force
  assert_success || return 1

  if grep -q "custom line" "$test_web_root/settings/site/pages/index.md"; then
    TEST_FAILURE_REASON="update-from-template did not overwrite from external template"
    rm -rf "$fake_home" "$test_web_root"
    return 1
  fi
  if ! grep -q "external template v2" "$test_web_root/settings/site/pages/index.md"; then
    TEST_FAILURE_REASON="updated external template content not copied"
    rm -rf "$fake_home" "$test_web_root"
    return 1
  fi

  rm -rf "$fake_home" "$test_web_root"
}

run_test_case "update-from-template shows help" test_help
run_test_case "update-from-template updates files from template" test_updates_from_template
run_test_case "update-from-template preserves uploads" test_preserves_uploads
run_test_case "update-from-template fails for nonexistent site" test_fails_for_nonexistent_site
run_test_case "update-from-template resolves templates from web" test_update_uses_web_template_directory
run_test_case "update-from-template refreshes requirements file" test_update_refreshes_requirements_file
run_test_case "update-from-template resolves external repo templates" test_update_resolves_external_repo_templates

finish_tests
