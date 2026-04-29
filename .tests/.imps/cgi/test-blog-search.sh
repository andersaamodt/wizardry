#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_blog_search_exists() {
  [ -x "spells/.imps/cgi/blog-search" ]
}

test_blog_search_uses_literal_query() {
  skip-if-compiled || return $?

  site_dir=$(temp-dir blog-search-site)
  posts_dir="$site_dir/site/pages/posts"
  mkdir -p "$posts_dir"
  cat > "$posts_dir/2026-01-01-alpha.md" <<'EOF'
---
title: "Alpha"
visibility: "public"
---
body
EOF

  WEB_SITE_DIR="$site_dir" QUERY_STRING='q=%5B' run_cmd spells/.imps/cgi/blog-search
  assert_success || return 1
  assert_output_contains 'No results found' || return 1

  rm -rf "$site_dir"
}

test_blog_search_escapes_query_and_results() {
  skip-if-compiled || return $?

  site_dir=$(temp-dir blog-search-site)
  posts_dir="$site_dir/site/pages/posts"
  mkdir -p "$posts_dir"
  cat > "$posts_dir/2026-01-01-bad.md" <<'EOF'
---
title: "<script>alert(1)</script>"
summary: "<img src=x onerror=alert(1)>"
tags: ["bad"]
visibility: "public"
---
body
EOF

  WEB_SITE_DIR="$site_dir" QUERY_STRING='q=%3Cscript%3E' run_cmd spells/.imps/cgi/blog-search
  assert_success || return 1
  if printf '%s' "$OUTPUT" | grep -F '<script>alert(1)</script>' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="blog-search emitted raw script tag"
    rm -rf "$site_dir"
    return 1
  fi
  assert_output_contains '&lt;script&gt;alert(1)&lt;/script&gt;' || return 1
  assert_output_contains '&lt;img src=x onerror=alert(1)&gt;' || return 1

  rm -rf "$site_dir"
}

run_test_case "blog-search is executable" test_blog_search_exists
run_test_case "blog-search uses literal query" test_blog_search_uses_literal_query
run_test_case "blog-search escapes query and results" \
  test_blog_search_escapes_query_and_results
finish_tests
