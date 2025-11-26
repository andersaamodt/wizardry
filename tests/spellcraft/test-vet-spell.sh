#!/bin/sh
# Behavioral cases for vet-spell:
# - vet-spell prints usage with --help
# - vet-spell passes well-formed spells
# - vet-spell fails spells missing shebang
# - vet-spell fails spells missing description comment
# - vet-spell fails spells missing strict mode
# - vet-spell fails spells with trailing space assignment
# - vet-spell skips usage/help checks for imps
# - vet-spell enables usage/help checks with --strict

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

make_spell_dir() {
  dir=$(make_tempdir)
  printf '%s\n' "$dir"
}

test_help() {
  run_spell "spells/spellcraft/vet-spell" --help
  assert_success && assert_output_contains "Usage: vet-spell"
}

test_usage_alias() {
  run_spell "spells/spellcraft/vet-spell" --usage
  assert_success && assert_output_contains "Usage: vet-spell"
}

test_passes_well_formed_spell() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/good-spell" <<'EOF'
#!/bin/sh

# This is a good spell that does something useful.
# It has proper documentation.

show_usage() {
  cat <<'USAGE'
Usage: good-spell

Does something useful.
USAGE
}

case "${1-}" in
--help|--usage|-h)
  show_usage
  exit 0
  ;;
esac

set -eu

echo "Hello from good spell"
EOF
  chmod +x "$spell_dir/good-spell"
  run_spell "spells/spellcraft/vet-spell" --strict "$spell_dir/good-spell"
  assert_success && assert_output_contains "passed"
}

test_fails_missing_shebang() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/bad-spell" <<'EOF'
# No shebang here

set -eu

echo "bad"
EOF
  chmod +x "$spell_dir/bad-spell"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/bad-spell"
  assert_failure && assert_output_contains "shebang"
}

test_fails_wrong_shebang() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/bad-spell" <<'EOF'
#!/bin/bash

# Bad shebang

set -eu

echo "bad"
EOF
  chmod +x "$spell_dir/bad-spell"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/bad-spell"
  assert_failure && assert_output_contains "shebang"
}

test_fails_missing_description() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/bad-spell" <<'EOF'
#!/bin/sh

set -eu

echo "bad"
EOF
  chmod +x "$spell_dir/bad-spell"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/bad-spell"
  assert_failure && assert_output_contains "description comment"
}

test_fails_missing_strict_mode() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/bad-spell" <<'EOF'
#!/bin/sh

# This spell lacks strict mode.

echo "bad"
EOF
  chmod +x "$spell_dir/bad-spell"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/bad-spell"
  assert_failure && assert_output_contains "strict mode"
}

test_fails_trailing_space_assignment() {
  spell_dir=$(make_spell_dir)
  # Create spell with trailing space in assignment
  printf '%s\n' '#!/bin/sh' '' '# Spell with bad assignment.' '' 'set -eu' '' 'var= ' '' 'echo "$var"' >"$spell_dir/bad-spell"
  chmod +x "$spell_dir/bad-spell"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/bad-spell"
  assert_failure && assert_output_contains "trailing space"
}

test_passes_imp_without_usage() {
  spell_dir=$(make_spell_dir)
  mkdir -p "$spell_dir/.imps"
  cat >"$spell_dir/.imps/simple-imp" <<'EOF'
#!/bin/sh

# Print the current date.

set -eu

date
EOF
  chmod +x "$spell_dir/.imps/simple-imp"
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/.imps/simple-imp"
  assert_success && assert_output_contains "passed"
}

test_strict_requires_usage_function() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/no-usage-spell" <<'EOF'
#!/bin/sh

# This spell has no usage function.

set -eu

echo "hello"
EOF
  chmod +x "$spell_dir/no-usage-spell"
  
  # Without --strict, should pass
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/no-usage-spell"
  assert_success || return 1
  
  # With --strict, should fail
  run_spell "spells/spellcraft/vet-spell" --strict "$spell_dir/no-usage-spell"
  assert_failure && assert_output_contains "usage function"
}

test_strict_requires_help_handler() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/no-help-spell" <<'EOF'
#!/bin/sh

# This spell has no help handler.

show_usage() {
  echo "Usage: no-help-spell"
}

set -eu

echo "hello"
EOF
  chmod +x "$spell_dir/no-help-spell"
  
  # Without --strict, should pass
  run_spell "spells/spellcraft/vet-spell" "$spell_dir/no-help-spell"
  assert_success || return 1
  
  # With --strict, should fail
  run_spell "spells/spellcraft/vet-spell" --strict "$spell_dir/no-help-spell"
  assert_failure && assert_output_contains "help"
}

test_list_option() {
  run_spell "spells/spellcraft/vet-spell" --list --only "look"
  assert_success && assert_output_contains "spells/mud/look"
}

run_test_case "vet-spell prints usage" test_help
run_test_case "vet-spell accepts --usage" test_usage_alias
run_test_case "vet-spell passes well-formed spell" test_passes_well_formed_spell
run_test_case "vet-spell fails missing shebang" test_fails_missing_shebang
run_test_case "vet-spell fails wrong shebang" test_fails_wrong_shebang
run_test_case "vet-spell fails missing description" test_fails_missing_description
run_test_case "vet-spell fails missing strict mode" test_fails_missing_strict_mode
run_test_case "vet-spell fails trailing space assignment" test_fails_trailing_space_assignment
run_test_case "vet-spell passes imp without usage" test_passes_imp_without_usage
run_test_case "vet-spell --strict requires usage function" test_strict_requires_usage_function
run_test_case "vet-spell --strict requires help handler" test_strict_requires_help_handler
run_test_case "vet-spell --list shows matching files" test_list_option

finish_tests
