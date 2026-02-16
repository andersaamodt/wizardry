#!/bin/sh
# Tests for web build spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

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
  printf 'pandoc stub: missing --output\n' >&2
  exit 2
fi

title=${in_file##*/}
title=${title%.md}
cat > "$out_file" <<HTML
<!doctype html>
<html><body><h1>$title</h1></body></html>
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

  chmod +x "$stub_dir/pandoc" "$stub_dir/install-htmx"
  printf '%s\n' "$stub_dir"
}

test_build_help() {
  run_spell spells/web/build --help
  assert_success
  assert_output_contains "Usage: build"
}

test_build_generates_html_for_every_template() {
  skip-if-compiled || return $?

  if [ ! -d "$ROOT_DIR/.web" ]; then
    TEST_FAILURE_REASON="template directory missing: $ROOT_DIR/.web"
    return 1
  fi

  test_web_root=$(temp-dir web-build-root)
  stub_dir=$(make_build_stub_dir)

  found_template=0
  for template_path in "$ROOT_DIR/.web"/*; do
    [ -d "$template_path" ] || continue
    found_template=1
    template=$(basename "$template_path")
    site_name="build-${template}"
    site_dir="$test_web_root/$site_name"

    WEB_WIZARDRY_ROOT="$test_web_root" run_spell spells/web/create-from-template "$site_name" "$template"
    if [ "$STATUS" -ne 0 ]; then
      TEST_FAILURE_REASON="failed to create test site for template '$template'"
      rm -rf "$test_web_root" "$stub_dir"
      return 1
    fi

    PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$test_web_root" run_spell spells/web/build "$site_name" --full
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

    md_count=$(find "$site_dir/site/pages" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d '[:space:]')
    html_count=$(find "$site_dir/build/pages" -maxdepth 1 -name "*.html" -type f 2>/dev/null | wc -l | tr -d '[:space:]')
    if [ "${md_count:-0}" -gt 0 ] && [ "${html_count:-0}" -lt "${md_count:-0}" ]; then
      TEST_FAILURE_REASON="template '$template' built too few pages ($html_count/$md_count)"
      rm -rf "$test_web_root" "$stub_dir"
      return 1
    fi
  done

  if [ "$found_template" -ne 1 ]; then
    TEST_FAILURE_REASON="no templates found in $ROOT_DIR/.web"
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

  WEB_WIZARDRY_ROOT="$test_web_root" run_spell spells/web/create-from-template cachetest demo
  assert_success

  PATH="$stub_dir:$PATH" WEB_WIZARDRY_ROOT="$test_web_root" \
    WIZARDRY_WEB_JS_DIR="$blocked_cache_path" run_spell spells/web/build cachetest --full
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

run_test_case "build --help works" test_build_help
run_test_case "build generates output for every template" test_build_generates_html_for_every_template
run_test_case "build cache falls back to site data cache" test_build_cache_falls_back_to_site_data_only

finish_tests
