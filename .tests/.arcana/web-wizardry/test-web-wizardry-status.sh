#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_web_wizardry_status_help() {
  run_spell "spells/.arcana/web-wizardry/web-wizardry-status" --help
  assert_success && assert_output_contains "fauxzilla"
}

test_web_wizardry_status_counts_gazeta_template() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)

  for command_name in pandoc nginx fcgiwrap openssl resize2fs xfs_growfs certbot; do
    cat >"$tmp/$command_name" <<'SH'
#!/bin/sh
exit 0
SH
    chmod +x "$tmp/$command_name"
  done

  mkdir -p "$tmp/home/.local/share/wizardry/web/js"
  touch "$tmp/home/.local/share/wizardry/web/js/htmx.min.js"

  mkdir -p "$tmp/fauxzilla/scripts"
  cat >"$tmp/fauxzilla/scripts/fauxzilla-check" <<'SH'
#!/bin/sh
printf '%s\n' 'status=ok'
SH
  chmod +x "$tmp/fauxzilla/scripts/fauxzilla-check"

  run_cmd env \
    PATH="$tmp:$PATH" \
    HOME="$tmp/home" \
    FAUXZILLA_REPO_DIR="$tmp/fauxzilla" \
    "$ROOT_DIR/spells/.arcana/web-wizardry/web-wizardry-status"
  assert_success || return 1

  case "$OUTPUT" in
    *"partial install"*)
      ;;
    *)
      TEST_FAILURE_REASON=$(
        printf 'web-wizardry-status should count missing Gazeta as partial install: %s' \
          "$OUTPUT"
      )
      return 1
      ;;
  esac
}

run_test_case "web-wizardry-status shows help" test_web_wizardry_status_help
run_test_case "web-wizardry-status counts Gazeta template" \
  test_web_wizardry_status_counts_gazeta_template
finish_tests
