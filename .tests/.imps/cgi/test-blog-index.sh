#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_blog_index_exists() {
  [ -x "spells/.imps/cgi/blog-index" ]
}

test_blog_index_escapes_front_matter() {
  skip-if-compiled || return $?

  site_dir=$(temp-dir blog-index-site)
  posts_dir="$site_dir/site/pages/posts"
  mkdir -p "$posts_dir"
  cat > "$posts_dir/2026-01-01-bad.md" <<'EOF'
---
title: "<script>alert(1)</script>"
published_at: "2026-01-01T00:00:00Z"
summary: "<img src=x onerror=alert(1)>"
tags: ["<tag>"]
visibility: "public"
---
body
EOF

  WEB_SITE_DIR="$site_dir" run_cmd spells/.imps/cgi/blog-index
  assert_success || return 1
  if printf '%s' "$OUTPUT" | grep -F '<script>alert(1)</script>' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="blog-index emitted raw script tag from front matter"
    rm -rf "$site_dir"
    return 1
  fi
  assert_output_contains '&lt;script&gt;alert(1)&lt;/script&gt;' || return 1
  assert_output_contains '&lt;img src=x onerror=alert(1)&gt;' || return 1

  rm -rf "$site_dir"
}

test_blog_index_tolerates_invalid_page() {
  skip-if-compiled || return $?

  site_dir=$(temp-dir blog-index-site)
  mkdir -p "$site_dir/site/pages/posts"

  WEB_SITE_DIR="$site_dir" QUERY_STRING='page=-' run_cmd spells/.imps/cgi/blog-index
  assert_success || return 1

  rm -rf "$site_dir"
}

run_test_case "blog-index is executable" test_blog_index_exists
run_test_case "blog-index escapes front matter" test_blog_index_escapes_front_matter
run_test_case "blog-index tolerates invalid page" test_blog_index_tolerates_invalid_page
finish_tests
