#!/bin/sh
# Tests for invoke-thesaurus default synonym updates

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_invoke_thesaurus_adds_missing_defaults() {
  skip-if-compiled || return $?

  spellbook_dir=$(temp-dir spellbook)
  default_file="$spellbook_dir/.default-synonyms"
  init_file="$spellbook_dir/.default-synonyms-initialized"

  cat > "$default_file" <<'EOF'
# Wizardry Default Synonyms
# Format: word=target
EOF
  touch "$init_file"

  SPELLBOOK_DIR="$spellbook_dir" run_sourced_spell "spells/.imps/sys/invoke-thesaurus"
  assert_success

  if ! grep -q "^sites=web-wizardry" "$default_file"; then
    TEST_FAILURE_REASON="sites default synonym not added"
    return 1
  fi
  if ! grep -q "^site=site-menu" "$default_file"; then
    TEST_FAILURE_REASON="site default synonym not added"
    return 1
  fi

  rm -rf "$spellbook_dir"
}

run_test_case "invoke-thesaurus adds missing defaults" test_invoke_thesaurus_adds_missing_defaults

finish_tests
