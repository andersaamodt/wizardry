#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/crossposting/is-crossposting-component-installed"

test_is_crossposting_component_installed_help() {
  run_spell "$target" --help
  assert_success && assert_output_contains "bridge-runtime"
}

test_is_crossposting_component_installed_detects_stubbed_components() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  mkdir -p "$tmp/bin"

  for cmd in jq pandoc; do
    cat >"$tmp/bin/$cmd" <<'SH'
#!/bin/sh
exit 0
SH
    chmod +x "$tmp/bin/$cmd"
  done

  cat >"$tmp/bin/fake-granary-python" <<'SH'
#!/bin/sh
if [ "${1-}" = "-c" ]; then
  exit 0
fi
exit 1
SH
  chmod +x "$tmp/bin/fake-granary-python"

  for platform in misskey lemmy kbin reddit x tumblr facebook minds mirror; do
    cat >"$tmp/bin/origin-bridge-$platform" <<'SH'
#!/bin/sh
exit 0
SH
    chmod +x "$tmp/bin/origin-bridge-$platform"
  done

  run_cmd env PATH="$tmp/bin:/usr/bin:/bin" "$ROOT_DIR/$target" jq
  assert_success || return 1

  run_cmd env PATH="$tmp/bin:/usr/bin:/bin" "$ROOT_DIR/$target" pandoc
  assert_success || return 1

  run_cmd env PATH="$tmp/bin:/usr/bin:/bin" ORIGIN_GRANARY_PYTHON="$tmp/bin/fake-granary-python" "$ROOT_DIR/$target" granary-runtime
  assert_success || return 1

  run_cmd env PATH="$tmp/bin:/usr/bin:/bin" "$ROOT_DIR/$target" bridge-runtime
  assert_success || return 1
}

run_test_case "is-crossposting-component-installed shows help" test_is_crossposting_component_installed_help
run_test_case "is-crossposting-component-installed detects stubbed components" test_is_crossposting_component_installed_detects_stubbed_components
finish_tests
