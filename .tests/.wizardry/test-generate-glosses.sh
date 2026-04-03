#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_generate_glosses_skips_system_command_prefixes() {
  fixture=$(mktemp -d "${TMPDIR:-/tmp}/test-generate-glosses.XXXXXX")
  mkdir -p "$fixture/bin" "$fixture/spellbook"

  cat >"$fixture/bin/ssh" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/ssh"

  run_cmd env \
    PATH="$fixture/bin:/usr/bin:/bin" \
    WIZARDRY_DIR="$ROOT_DIR" \
    SPELLBOOK_DIR="$fixture/spellbook" \
    "$ROOT_DIR/spells/.wizardry/generate-glosses" --quiet

  assert_success || return 1

  case "$RUN_OUTPUT" in
    *"
ssh() {"*|ssh\(\)\ \{*)
      TEST_FAILURE_REASON="generate-glosses should not emit ssh() when ssh exists on PATH"
      return 1
      ;;
  esac
}

run_test_case "generate-glosses skips first-word glosses that shadow system commands" test_generate_glosses_skips_system_command_prefixes
finish_tests
