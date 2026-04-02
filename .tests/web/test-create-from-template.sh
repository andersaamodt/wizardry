#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

resolve_test_template_root() {
  root_parent=$(dirname "$ROOT_DIR")
  for candidate in "$ROOT_DIR/web" "$ROOT_DIR/spells/web" "$root_parent/git/wizardry-apps/web" "$HOME/git/wizardry-apps/web"; do
    [ -d "$candidate" ] || continue
    for template_path in "$candidate"/*; do
      [ -d "$template_path/pages" ] || continue
      printf '%s\n' "$candidate"
      return 0
    done
  done
  return 1
}

TEST_TEMPLATE_ROOT=$(resolve_test_template_root 2>/dev/null || printf '')

test_help() {
  run_spell spells/web/create-from-template --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "demo"
}

test_blog_template_has_sample_posts() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"

  WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/create-from-template mytestblog blog
  assert_success

  post_count=$(find "$test_web_root/mytestblog/site/pages/posts" -name "*.md" -type f | wc -l)
  [ "$post_count" -gt 0 ] || {
    TEST_FAILURE_REASON="no sample posts found (expected at least 1)"
    rm -rf "$test_web_root"
    return 1
  }

  rm -rf "$test_web_root"
}

test_all_web_templates_create_expected_structure() {
  skip-if-compiled || return $?

  template_root=${TEST_TEMPLATE_ROOT-}
  if [ -z "$template_root" ] || [ ! -d "$template_root" ]; then
    TEST_FAILURE_REASON="template directory missing"
    return 1
  fi

  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"

  found_template=0
  for template_path in "$template_root"/*; do
    [ -d "$template_path" ] || continue
    found_template=1
    template=$(basename "$template_path")
    site_name="tmpl-${template}"
    site_dir="$test_web_root/$site_name"

    WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/create-from-template "$site_name" "$template"
    if [ "$STATUS" -ne 0 ]; then
      TEST_FAILURE_REASON="failed to create template '$template'"
      rm -rf "$test_web_root"
      return 1
    fi

    [ -d "$site_dir/site/pages" ] || {
      TEST_FAILURE_REASON="template '$template' missing generated site/pages"
      rm -rf "$test_web_root"
      return 1
    }
    [ -d "$site_dir/site/uploads" ] || {
      TEST_FAILURE_REASON="template '$template' missing generated site/uploads"
      rm -rf "$test_web_root"
      return 1
    }
    [ -d "$site_dir/build" ] || {
      TEST_FAILURE_REASON="template '$template' missing generated build directory"
      rm -rf "$test_web_root"
      return 1
    }
    [ -f "$site_dir/site.conf" ] || {
      TEST_FAILURE_REASON="template '$template' missing generated site.conf"
      rm -rf "$test_web_root"
      return 1
    }
    if [ -f "$template_path/wizardry-server-requirements.conf" ] && [ ! -f "$site_dir/wizardry-server-requirements.conf" ]; then
      TEST_FAILURE_REASON="template '$template' missing generated wizardry-server-requirements.conf"
      rm -rf "$test_web_root"
      return 1
    fi

    config_template=$(config-get "$site_dir/site.conf" template 2>/dev/null || printf '')
    if [ "$config_template" != "$template" ]; then
      TEST_FAILURE_REASON="site.conf template mismatch for '$template' (got '$config_template')"
      rm -rf "$test_web_root"
      return 1
    fi

    if [ -d "$template_path/cgi" ] && [ ! -d "$site_dir/cgi" ]; then
      TEST_FAILURE_REASON="template '$template' has cgi but generated site is missing cgi directory"
      rm -rf "$test_web_root"
      return 1
    fi
  done

  if [ "$found_template" -ne 1 ]; then
    TEST_FAILURE_REASON="no templates found in $template_root"
    rm -rf "$test_web_root"
    return 1
  fi

  rm -rf "$test_web_root"
}

test_create_from_template_uses_web_directory() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-wizardry-test)
  fake_wizardry_root=$(temp-dir wizardry-template-root)

  mkdir -p "$fake_wizardry_root/web/minimal/pages"
  mkdir -p "$fake_wizardry_root/web/minimal/static"
  cat > "$fake_wizardry_root/web/minimal/pages/index.md" <<'EOF'
# Minimal Template
EOF
  cat > "$fake_wizardry_root/web/minimal/static/style.css" <<'EOF'
body { font-family: sans-serif; }
EOF
  cat > "$fake_wizardry_root/web/minimal/wizardry-server-requirements.conf" <<'EOF'
nostril=required
EOF

  WIZARDRY_DIR="$fake_wizardry_root" WEB_WIZARDRY_ROOT="$test_web_root" \
    run_spell spells/web/create-from-template mini minimal
  if [ "$STATUS" -ne 0 ]; then
    TEST_FAILURE_REASON="create-from-template did not resolve templates from web"
    rm -rf "$test_web_root" "$fake_wizardry_root"
    return 1
  fi

  [ -f "$test_web_root/mini/site/pages/index.md" ] || {
    TEST_FAILURE_REASON="custom web template index.md not copied"
    rm -rf "$test_web_root" "$fake_wizardry_root"
    return 1
  }
  [ -f "$test_web_root/mini/wizardry-server-requirements.conf" ] || {
    TEST_FAILURE_REASON="custom web template requirements file not copied"
    rm -rf "$test_web_root" "$fake_wizardry_root"
    return 1
  }

  rm -rf "$test_web_root"
  rm -rf "$fake_wizardry_root"
}

test_create_from_template_resolves_external_repo_templates() {
  skip-if-compiled || return $?

  fake_home=$(temp-dir wizardry-home)
  fake_wizardry_root="$fake_home/.wizardry"
  fake_git_root="$fake_home/git"
  test_web_root=$(temp-dir web-wizardry-test)

  mkdir -p "$fake_wizardry_root"
  mkdir -p "$fake_git_root/nostr-blog/pages" "$fake_git_root/nostr-blog/static"
  mkdir -p "$fake_git_root/unix-settings/hosted-web/pages" \
    "$fake_git_root/unix-settings/hosted-web/static" \
    "$fake_git_root/unix-settings/hosted-web/cgi"

  cat > "$fake_git_root/nostr-blog/pages/index.md" <<'EOF'
# External Blog
EOF
  cat > "$fake_git_root/nostr-blog/static/style.css" <<'EOF'
body { color: #222; }
EOF
  cat > "$fake_git_root/unix-settings/hosted-web/pages/index.md" <<'EOF'
# UNIX Settings
EOF
  cat > "$fake_git_root/unix-settings/hosted-web/static/style.css" <<'EOF'
body { color: #111; }
EOF
  cat > "$fake_git_root/unix-settings/hosted-web/cgi/unix-roster" <<'EOF'
#!/bin/sh
printf 'Content-Type: text/plain\n\nok\n'
EOF
  chmod +x "$fake_git_root/unix-settings/hosted-web/cgi/unix-roster"

  HOME="$fake_home" WIZARDRY_DIR="$fake_wizardry_root" WEB_WIZARDRY_ROOT="$test_web_root" \
    run_spell spells/web/create-from-template blogsite blog
  assert_success || return 1

  HOME="$fake_home" WIZARDRY_DIR="$fake_wizardry_root" WEB_WIZARDRY_ROOT="$test_web_root" \
    run_spell spells/web/create-from-template settings unix-settings
  assert_success || return 1

  [ -f "$test_web_root/blogsite/site/pages/index.md" ] || {
    TEST_FAILURE_REASON="external blog template index not copied"
    rm -rf "$fake_home" "$test_web_root"
    return 1
  }
  [ -f "$test_web_root/settings/site/pages/index.md" ] || {
    TEST_FAILURE_REASON="external unix-settings template index not copied"
    rm -rf "$fake_home" "$test_web_root"
    return 1
  }
  [ -x "$test_web_root/settings/cgi/unix-roster" ] || {
    TEST_FAILURE_REASON="external unix-settings CGI payload not copied"
    rm -rf "$fake_home" "$test_web_root"
    return 1
  }

  rm -rf "$fake_home" "$test_web_root"
}

run_test_case "create-from-template shows help" test_help
if [ -d "$ROOT_DIR/web/blog" ]; then
  run_test_case "blog template has sample posts" test_blog_template_has_sample_posts
elif [ -d "$ROOT_DIR/spells/web/blog" ] || [ -d "$(dirname "$ROOT_DIR")/git/wizardry-apps/web/blog" ] || [ -d "$HOME/git/wizardry-apps/web/blog" ]; then
  run_test_case "blog template has sample posts" test_blog_template_has_sample_posts
fi
run_test_case "all templates create expected site structure" test_all_web_templates_create_expected_structure
run_test_case "create-from-template resolves templates from web" test_create_from_template_uses_web_directory
run_test_case "create-from-template resolves external repo templates" test_create_from_template_resolves_external_repo_templates

finish_tests
