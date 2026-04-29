#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_blog_list_drafts_exists() {
  [ -x "spells/.imps/cgi/blog-list-drafts" ]
}

test_blog_list_drafts_requires_auth() {
  export QUERY_STRING=""
  output=$(spells/.imps/cgi/blog-list-drafts 2>&1)
  printf '%s' "$output" | grep -q '"success":false'
}

test_blog_list_drafts_requires_exact_admin_group() {
  skip-if-compiled || return $?

  sites_dir=$(temp-dir blog-drafts-sites)
  session_dir="$sites_dir/.sitedata/testsite/ssh-auth/sessions"
  mkdir -p "$session_dir"
  printf '%s\n' '{"username":"alice","fingerprint":"fp"}' > "$session_dir/tok"

  stub_dir=$(temp-dir blog-drafts-stub)
  cat > "$stub_dir/id" <<'EOF'
#!/bin/sh
if [ "${1-}" = "-nG" ]; then
  printf '%s\n' 'staff blog-admins'
  exit 0
fi
exit 0
EOF
  chmod +x "$stub_dir/id"

  PATH="$stub_dir:$PATH" QUERY_STRING='session_token=tok' \
    WIZARDRY_SITE_NAME=testsite WIZARDRY_SITES_DIR="$sites_dir" \
    run_cmd spells/.imps/cgi/blog-list-drafts
  assert_success || return 1
  assert_output_contains 'Admin permission required' || return 1

  rm -rf "$sites_dir" "$stub_dir"
}

test_blog_list_drafts_escapes_filenames() {
  skip-if-compiled || return $?

  sites_dir=$(temp-dir blog-drafts-sites)
  session_dir="$sites_dir/.sitedata/testsite/ssh-auth/sessions"
  posts_dir="$sites_dir/.sitedata/site/pages/posts"
  mkdir -p "$session_dir" "$posts_dir"
  printf '%s\n' '{"username":"alice","fingerprint":"fp"}' > "$session_dir/tok"
  cat > "$posts_dir/bad\"name.md" <<'EOF'
---
visibility: "draft"
---
body
EOF

  stub_dir=$(temp-dir blog-drafts-stub)
  cat > "$stub_dir/id" <<'EOF'
#!/bin/sh
if [ "${1-}" = "-nG" ]; then
  printf '%s\n' 'staff blog-admin'
  exit 0
fi
exit 0
EOF
  chmod +x "$stub_dir/id"

  PATH="$stub_dir:$PATH" QUERY_STRING='session_token=tok' \
    WIZARDRY_SITE_NAME=testsite WIZARDRY_SITES_DIR="$sites_dir" \
    run_cmd spells/.imps/cgi/blog-list-drafts
  assert_success || return 1
  assert_output_contains 'bad\"name.md' || return 1
  if printf '%s' "$OUTPUT" | grep -F '"filename":"bad"name.md"' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="blog-list-drafts emitted unescaped filename JSON"
    rm -rf "$sites_dir" "$stub_dir"
    return 1
  fi

  rm -rf "$sites_dir" "$stub_dir"
}

run_test_case "blog-list-drafts is executable" test_blog_list_drafts_exists
run_test_case "blog-list-drafts requires authentication" test_blog_list_drafts_requires_auth
run_test_case "blog-list-drafts requires exact admin group" \
  test_blog_list_drafts_requires_exact_admin_group
run_test_case "blog-list-drafts escapes filenames" \
  test_blog_list_drafts_escapes_filenames
finish_tests
