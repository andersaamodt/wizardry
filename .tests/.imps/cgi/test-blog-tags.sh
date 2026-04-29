#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_blog_tags_exists() {
  [ -x "spells/.imps/cgi/blog-tags" ]
}

test_blog_tags_escapes_tags_and_titles() {
  skip-if-compiled || return $?

  site_dir=$(temp-dir blog-tags-site)
  posts_dir="$site_dir/site/pages/posts"
  mkdir -p "$posts_dir"
  cat > "$posts_dir/2026-01-01-bad.md" <<'EOF'
---
title: "<script>alert(1)</script>"
tags: ["<tag>"]
visibility: "public"
---
body
EOF

  WEB_SITE_DIR="$site_dir" run_cmd spells/.imps/cgi/blog-tags
  assert_success || return 1
  if printf '%s' "$OUTPUT" | grep -F '<script>alert(1)</script>' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="blog-tags emitted raw title script tag"
    rm -rf "$site_dir"
    return 1
  fi
  assert_output_contains '&lt;tag&gt;' || return 1
  assert_output_contains '&lt;script&gt;alert(1)&lt;/script&gt;' || return 1

  rm -rf "$site_dir"
}

test_blog_tags_matches_literal_tag() {
  skip-if-compiled || return $?

  site_dir=$(temp-dir blog-tags-site)
  posts_dir="$site_dir/site/pages/posts"
  mkdir -p "$posts_dir"
  cat > "$posts_dir/2026-01-01-dot.md" <<'EOF'
---
title: "Dot"
tags: ["a.b"]
visibility: "public"
---
body
EOF
  cat > "$posts_dir/2026-01-02-axb.md" <<'EOF'
---
title: "AxB"
tags: ["axb"]
visibility: "public"
---
body
EOF

  WEB_SITE_DIR="$site_dir" run_cmd spells/.imps/cgi/blog-tags
  assert_success || return 1
  dot_count=$(printf '%s' "$OUTPUT" | grep -c 'Dot')
  axb_under_dot=$(printf '%s' "$OUTPUT" | awk '
    index($0, "<section id=\"a.b\"") { in_section=1 }
    in_section { print }
    in_section && index($0, "</section>") { in_section=0 }
  ' | grep -c 'AxB' || true)
  if [ "$dot_count" -ne 1 ] || [ "$axb_under_dot" -ne 0 ]; then
    TEST_FAILURE_REASON="blog-tags matched regex-shaped tag against another tag"
    rm -rf "$site_dir"
    return 1
  fi

  rm -rf "$site_dir"
}

run_test_case "blog-tags is executable" test_blog_tags_exists
run_test_case "blog-tags escapes tags and titles" test_blog_tags_escapes_tags_and_titles
run_test_case "blog-tags matches literal tag" test_blog_tags_matches_literal_tag
finish_tests
