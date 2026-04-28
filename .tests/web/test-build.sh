#!/bin/sh
# Tests for web build spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

resolve_build_template_root() {
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

make_build_stub_dir() {
  stub_dir=$(temp-dir web-build-stubs)

  cat > "$stub_dir/pandoc" <<'EOF'
#!/bin/sh
set -eu
out_file=""
in_file=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --output=*)
      out_file=${1#--output=}
      ;;
    --output)
      shift
      out_file=${1-}
      ;;
    --*)
      ;;
    *)
      in_file=$1
      ;;
  esac
  shift
done

if [ -z "$out_file" ]; then
  # Fragment mode (used for feed generation): echo input as minimal HTML.
  if [ -n "$in_file" ] && [ -f "$in_file" ]; then
    cat "$in_file"
  else
    cat
  fi
  exit 0
fi

title=${in_file##*/}
title=${title%.md}
cat > "$out_file" <<HTML
<!doctype html>
<html><body><h1>$title</h1>
$(cat "$in_file")
</body></html>
HTML
EOF

  cat > "$stub_dir/install-htmx" <<'EOF'
#!/bin/sh
set -eu
lib_dir=${WIZARDRY_WEB_JS_DIR-}
if [ -z "$lib_dir" ]; then
  printf 'install-htmx stub: WIZARDRY_WEB_JS_DIR not set\n' >&2
  exit 2
fi
mkdir -p "$lib_dir"
printf '%s\n' "// htmx stub" > "$lib_dir/htmx.min.js"
printf '%s\n' "// idiomorph stub" > "$lib_dir/idiomorph-ext.min.js"
EOF

  cat > "$stub_dir/nostril" <<'EOF'
#!/bin/sh
set -eu
case "${1-}" in
  verify|--verify)
    cat >/dev/null
    exit 0
    ;;
  --help|-h|help|"")
    printf 'nostril stub\nverify\n'
    exit 0
    ;;
  *)
    cat >/dev/null || true
    exit 0
    ;;
esac
EOF

  cat > "$stub_dir/nak" <<'EOF'
#!/bin/sh
set -eu
case "${1-}" in
  help|--help|-h|"")
    printf 'nak stub\nverify\n'
    exit 0
    ;;
  verify)
    cat >/dev/null
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF

  chmod +x "$stub_dir/pandoc" "$stub_dir/install-htmx" "$stub_dir/nostril" "$stub_dir/nak"
  printf '%s\n' "$stub_dir"
}

test_build_help() {
  run_spell spells/web/build --help
  assert_success
  assert_output_contains "Usage: build"
}

test_build_generates_html_for_every_template() {
  skip-if-compiled || return $?

  template_root=$(resolve_build_template_root 2>/dev/null || printf '')
  if [ -z "$template_root" ] || [ ! -d "$template_root" ]; then
    TEST_FAILURE_REASON="template directory missing"
    return 1
  fi

  test_web_root=$(temp-dir web-build-root)
  stub_dir=$(make_build_stub_dir)

  found_template=0
  for template_path in "$template_root"/*; do
    [ -d "$template_path" ] || continue
    found_template=1
    template=$(basename "$template_path")
    site_name="build-${template}"
    site_dir="$test_web_root/$site_name"

    WEB_WIZARDRY_ROOT="$test_web_root" WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/create-from-template "$site_name" "$template"
    if [ "$STATUS" -ne 0 ]; then
      TEST_FAILURE_REASON="failed to create test site for template '$template'"
      rm -rf "$test_web_root" "$stub_dir"
      return 1
    fi

    PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$test_web_root" WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/build "$site_name" --full
    if [ "$STATUS" -ne 0 ]; then
      TEST_FAILURE_REASON="build failed for template '$template'"
      rm -rf "$test_web_root" "$stub_dir"
      return 1
    fi

    [ -f "$site_dir/build/pages/index.html" ] || {
      TEST_FAILURE_REASON="template '$template' did not build index.html"
      rm -rf "$test_web_root" "$stub_dir"
      return 1
    }
    [ -f "$site_dir/build/static/js/htmx.min.js" ] || {
      TEST_FAILURE_REASON="template '$template' missing copied htmx.min.js"
      rm -rf "$test_web_root" "$stub_dir"
      return 1
    }
    [ -f "$site_dir/build/static/js/idiomorph-ext.min.js" ] || {
      TEST_FAILURE_REASON="template '$template' missing copied idiomorph-ext.min.js"
      rm -rf "$test_web_root" "$stub_dir"
      return 1
    }

    md_count=$(find "$site_dir/site/pages" -name "*.md" -type f 2>/dev/null | wc -l | tr -d '[:space:]')
    html_count=$(find "$site_dir/build/pages" -name "*.html" -type f 2>/dev/null | wc -l | tr -d '[:space:]')
    if [ "${md_count:-0}" -gt 0 ] && [ "${html_count:-0}" -lt "${md_count:-0}" ]; then
      TEST_FAILURE_REASON="template '$template' built too few pages ($html_count/$md_count)"
      rm -rf "$test_web_root" "$stub_dir"
      return 1
    fi
  done

  if [ "$found_template" -ne 1 ]; then
    TEST_FAILURE_REASON="no templates found in $template_root"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi

  rm -rf "$test_web_root" "$stub_dir"
}

test_build_blog_generates_posts_and_feeds() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-build-root)
  stub_dir=$(make_build_stub_dir)
  site_name="build-blog"
  site_dir="$test_web_root/$site_name"

  WEB_WIZARDRY_ROOT="$test_web_root" WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/create-from-template "$site_name" blog
  assert_success

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$test_web_root" WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/build "$site_name" --full
  assert_success

  source_posts=$(find "$site_dir/site/pages/posts" -name "*.md" -type f 2>/dev/null | wc -l | tr -d '[:space:]')
  built_posts=$(find "$site_dir/build/pages/posts" -name "*.html" -type f 2>/dev/null | wc -l | tr -d '[:space:]')
  if [ "${source_posts:-0}" -ne "${built_posts:-0}" ]; then
    TEST_FAILURE_REASON="blog build should render nested post pages ($built_posts/$source_posts)"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi

  [ -f "$site_dir/build/rss.xml" ] || {
    TEST_FAILURE_REASON="blog build should generate rss.xml"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  }
  [ -f "$site_dir/build/atom.xml" ] || {
    TEST_FAILURE_REASON="blog build should generate atom.xml"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  }
  [ -f "$site_dir/build/sitemap.xml" ] || {
    TEST_FAILURE_REASON="blog build should generate sitemap.xml"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  }
  [ -f "$site_dir/build/robots.txt" ] || {
    TEST_FAILURE_REASON="blog build should generate robots.txt"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  }
  [ -f "$site_dir/build/pages/archive.html" ] || {
    TEST_FAILURE_REASON="blog build should generate archive.html"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  }
  [ -f "$site_dir/build/static/post-context.js" ] || {
    TEST_FAILURE_REASON="blog build should include post-context.js"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  }
  if ! grep -q 'href="/rss.xml"' "$site_dir/build/pages/index.html"; then
    TEST_FAILURE_REASON="blog index should include RSS footer link"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi
  if ! grep -q 'href="/atom.xml"' "$site_dir/build/pages/index.html"; then
    TEST_FAILURE_REASON="blog index should include Atom footer link"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi
  if grep -q 'hx-get="/cgi/blog-index"' "$site_dir/build/pages/index.html"; then
    TEST_FAILURE_REASON="blog index should prerender posts without htmx load placeholder"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi
  if grep -q 'Loading posts...' "$site_dir/build/pages/index.html"; then
    TEST_FAILURE_REASON="blog index should not show loading placeholder in static build"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi
  if ! grep -q 'class="post-list"' "$site_dir/build/pages/index.html"; then
    TEST_FAILURE_REASON="blog index should include rendered post-list HTML"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi
  if grep -q 'hx-get="/cgi/blog-tags"' "$site_dir/build/pages/tags.html"; then
    TEST_FAILURE_REASON="categories page should prerender tags without htmx load placeholder"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi
  if grep -q 'Loading tags...' "$site_dir/build/pages/tags.html"; then
    TEST_FAILURE_REASON="categories page should not show loading placeholder in static build"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi
  if ! grep -q 'class="tag-cloud"' "$site_dir/build/pages/tags.html"; then
    TEST_FAILURE_REASON="categories page should include rendered tag-cloud HTML"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi

  rm -rf "$test_web_root" "$stub_dir"
}

test_build_cache_falls_back_to_site_data_only() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-build-root)
  stub_dir=$(make_build_stub_dir)
  blocked_cache_path="$test_web_root/blocked-cache-path"
  : > "$blocked_cache_path"

  WEB_WIZARDRY_ROOT="$test_web_root" WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/create-from-template cachetest demo
  assert_success

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$test_web_root" \
    WIZARDRY_WEB_JS_DIR="$blocked_cache_path" WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/build cachetest --full
  assert_success

  fallback_lib_dir="$test_web_root/.sitedata/cachetest/.web-libs/js"
  [ -f "$fallback_lib_dir/htmx.min.js" ] || {
    TEST_FAILURE_REASON="expected htmx cache at site data fallback path"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  }
  [ -f "$fallback_lib_dir/idiomorph-ext.min.js" ] || {
    TEST_FAILURE_REASON="expected idiomorph cache at site data fallback path"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  }

  if printf '%s\n%s\n' "$OUTPUT" "$ERROR" | grep -q "final fallback cache"; then
    TEST_FAILURE_REASON="build output still mentions project-root final fallback cache"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi

  rm -rf "$test_web_root" "$stub_dir"
}

test_build_runs_site_pre_build_hook() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-build-root)
  stub_dir=$(make_build_stub_dir)
  site_name="hooktest"
  site_dir="$test_web_root/$site_name"

  WEB_WIZARDRY_ROOT="$test_web_root" WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/create-from-template "$site_name" demo
  assert_success

  mkdir -p "$site_dir/cgi"
  cat > "$site_dir/cgi/pre-build" <<'EOF'
#!/bin/sh
set -eu
pages_dir=$WEB_WIZARDRY_ROOT/$WIZARDRY_SITE_NAME/site/pages
cat > "$pages_dir/generated.md" <<'EOMD'
# Generated
EOMD
EOF
  chmod +x "$site_dir/cgi/pre-build"

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$test_web_root" WIZARDRY_DIR="$ROOT_DIR" \
    run_spell spells/web/build "$site_name" --full
  assert_success

  [ -f "$site_dir/build/pages/generated.html" ] || {
    TEST_FAILURE_REASON="pre-build hook should generate pages before build"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  }

  rm -rf "$test_web_root" "$stub_dir"
}

test_build_adds_cache_bust_for_local_static_assets() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-build-root)
  stub_dir=$(make_build_stub_dir)
  site_name="cachebust"
  site_dir="$test_web_root/$site_name"

  WEB_WIZARDRY_ROOT="$test_web_root" WIZARDRY_DIR="$ROOT_DIR" run_spell spells/web/create-from-template "$site_name" demo
  assert_success

  cat > "$site_dir/site/pages/cache-test.md" <<'EOF'
# Cache Test

<script src="/static/app.js"></script>
<script src="/static/already.js?v=keep"></script>
<link rel="stylesheet" href="/static/style.css" />
EOF

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$test_web_root" WIZARDRY_DIR="$ROOT_DIR" \
    run_spell spells/web/build "$site_name" --full
  assert_success

  html_file="$site_dir/build/pages/cache-test.html"
  [ -f "$html_file" ] || {
    TEST_FAILURE_REASON="cache-test page should be built"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  }

  if ! grep -Eq 'src="/static/app\.js\?v=[0-9]+"' "$html_file"; then
    TEST_FAILURE_REASON="build should append cache bust token to local static JS"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi

  if ! grep -Eq 'href="/static/style\.css\?v=[0-9]+"' "$html_file"; then
    TEST_FAILURE_REASON="build should append cache bust token to local static CSS"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi

  if ! grep -Eq 'src="/static/already\.js\?v=[0-9]+"' "$html_file"; then
    TEST_FAILURE_REASON="build should normalize existing static cache tokens"
    rm -rf "$test_web_root" "$stub_dir"
    return 1
  fi

  rm -rf "$test_web_root" "$stub_dir"
}

test_build_rejects_path_shaped_site_name() {
  skip-if-compiled || return $?

  tmpdir=$(make_tempdir)
  web_root="$tmpdir/sites"
  escape_dir="$tmpdir/escape"
  mkdir -p "$web_root" "$escape_dir/site/pages"
  cat > "$escape_dir/site.conf" <<'EOF'
template=demo
EOF
  cat > "$escape_dir/site/pages/index.md" <<'EOF'
# Escape
EOF

  stub_dir=$(make_build_stub_dir)

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$web_root" WIZARDRY_DIR="$ROOT_DIR" \
    run_spell spells/web/build ../escape --full

  assert_failure || return 1
  assert_error_contains "invalid site name" || return 1
  if [ -d "$escape_dir/build" ]; then
    TEST_FAILURE_REASON="build created output outside WEB_WIZARDRY_ROOT"
    return 1
  fi

  rm -rf "$tmpdir" "$stub_dir"
}

run_test_case "build --help works" test_build_help
run_test_case "build generates output for every template" test_build_generates_html_for_every_template
run_test_case "build cache falls back to site data cache" test_build_cache_falls_back_to_site_data_only
run_test_case "build runs site pre-build hook" test_build_runs_site_pre_build_hook
run_test_case "build appends cache bust tokens to local static assets" test_build_adds_cache_bust_for_local_static_assets
run_test_case "build rejects path-shaped site names" test_build_rejects_path_shaped_site_name
if [ -d "$ROOT_DIR/web/blog" ]; then
  run_test_case "blog build renders nested posts and feeds" test_build_blog_generates_posts_and_feeds
fi

finish_tests
