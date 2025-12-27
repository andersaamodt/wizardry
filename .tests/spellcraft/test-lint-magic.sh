#!/bin/sh
# Behavioral cases for lint-magic:
# - lint-magic prints usage with --help
# - lint-magic rejects unknown options
# - lint-magic fails for nonexistent files
# - lint-magic passes well-formed spells
# - lint-magic fails spells missing shebang
# - lint-magic fails spells missing description comment
# - lint-magic fails spells missing strict mode
# - lint-magic fails spells with trailing space assignment
# - lint-magic skips usage/help checks for imps
# - lint-magic requires usage function for non-imp spells
# - lint-magic requires help handler for non-imp spells
# - lint-magic fails imps with --help handlers (imps use comments as spec)
# - lint-magic fails imps using --flags (imps use space-separated args)
# - lint-magic passes imps that generate code with flags (heredoc content)
# - lint-magic fails imps with more than 3 parameters (FAIL)
# - lint-magic passes imps with variadic params (...) that don't count toward limit
# - lint-magic fails imps with duplicate set -eu statements
# - lint-magic passes imps with single set -eu statement

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_spell_dir() {
  dir=$(_make_tempdir)
  printf '%s\n' "$dir"
}

test_help() {
  _run_spell "spells/spellcraft/lint-magic" --help
  _assert_success && _assert_output_contains "Usage: lint-magic"
}

test_usage_alias() {
  _run_spell "spells/spellcraft/lint-magic" --usage
  _assert_success && _assert_output_contains "Usage: lint-magic"
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
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/good-spell"
  _assert_success && _assert_output_contains "passed"
}

test_fails_missing_shebang() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/bad-spell" <<'EOF'
# No shebang here

set -eu

echo "bad"
EOF
  chmod +x "$spell_dir/bad-spell"
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/bad-spell"
  _assert_failure && _assert_output_contains "shebang"
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
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/bad-spell"
  _assert_failure && _assert_output_contains "shebang"
}

test_fails_missing_description() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/bad-spell" <<'EOF'
#!/bin/sh

set -eu

echo "bad"
EOF
  chmod +x "$spell_dir/bad-spell"
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/bad-spell"
  _assert_failure && _assert_output_contains "description comment"
}

test_fails_missing_strict_mode() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/bad-spell" <<'EOF'
#!/bin/sh

# This spell lacks strict mode.

echo "bad"
EOF
  chmod +x "$spell_dir/bad-spell"
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/bad-spell"
  _assert_failure && _assert_output_contains "explicit mode"
}

test_fails_trailing_space_assignment() {
  spell_dir=$(make_spell_dir)
  # Create spell with trailing space in assignment
  printf '%s\n' '#!/bin/sh' '' '# Spell with bad assignment.' '' 'set -eu' '' 'var= ' '' 'echo "$var"' >"$spell_dir/bad-spell"
  chmod +x "$spell_dir/bad-spell"
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/bad-spell"
  _assert_failure && _assert_output_contains "trailing space"
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
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/.imps/simple-imp"
  _assert_success && _assert_output_contains "passed"
}

test_requires_usage_function() {
  spell_dir=$(make_spell_dir)
  cat >"$spell_dir/no-usage-spell" <<'EOF'
#!/bin/sh

# This spell has no usage function.

set -eu

echo "hello"
EOF
  chmod +x "$spell_dir/no-usage-spell"
  
  # Should fail without a usage function
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/no-usage-spell"
  _assert_failure && _assert_output_contains "usage function"
}

test_requires_help_handler() {
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
  
  # Should fail without a help handler
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/no-help-spell"
  _assert_failure && _assert_output_contains "help"
}

test_list_option() {
  _run_spell "spells/spellcraft/lint-magic" --list --only "look"
  _assert_success && _assert_output_contains "spells/mud/look"
}

test_unknown_option() {
  _run_spell "spells/spellcraft/lint-magic" --unknown
  _assert_failure && _assert_error_contains "Usage:"
}

test_fails_nonexistent_file() {
  _run_spell "spells/spellcraft/lint-magic" "/nonexistent/path/to/spell"
  _assert_failure && _assert_output_contains "file not found"
}

test_imp_fails_with_help_handler() {
  spell_dir=$(make_spell_dir)
  mkdir -p "$spell_dir/.imps"
  cat >"$spell_dir/.imps/bad-imp" <<'EOF'
#!/bin/sh

# This imp has a help handler which is not allowed.

show_usage() {
  echo "Usage: bad-imp"
}

case "${1-}" in
--help|--usage|-h)
  show_usage
  exit 0
  ;;
esac

set -eu

echo "hello"
EOF
  chmod +x "$spell_dir/.imps/bad-imp"
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/.imps/bad-imp"
  _assert_failure && _assert_output_contains "--help handler"
}

test_imp_fails_with_flags() {
  spell_dir=$(make_spell_dir)
  mkdir -p "$spell_dir/.imps"
  cat >"$spell_dir/.imps/flag-imp" <<'EOF'
#!/bin/sh

# This imp uses flags which is not allowed.

_flag_imp() {
  while [ "$#" -gt 0 ]; do
    case $1 in
      --name) name=$2; shift 2 ;;
      --verbose) verbose=1; shift ;;
      *) break ;;
    esac
  done
  echo "name=$name verbose=${verbose:-0}"
}

case "$0" in
  */flag-imp) _flag_imp "$@" ;; esac
EOF
  chmod +x "$spell_dir/.imps/flag-imp"
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/.imps/flag-imp"
  _assert_failure && _assert_output_contains "--flags"
}

test_imp_passes_with_heredoc_flags() {
  # Imps that generate scripts containing flags in heredocs should pass
  spell_dir=$(make_spell_dir)
  mkdir -p "$spell_dir/.imps"
  cat >"$spell_dir/.imps/stub-gen" <<'EOF'
#!/bin/sh

# stub-gen OUTFILE - generate a stub script that handles flags

_stub_gen() {
  outfile=$1
  cat <<'STUB' >"$outfile"
#!/bin/sh
# This is a generated stub
while [ $# -gt 0 ]; do
  case "$1" in
    --verbose) shift ;;
    --quiet) shift ;;
    *) break ;;
  esac
done
exec "$@"
STUB
  chmod +x "$outfile"
}

case "$0" in
  */stub-gen) _stub_gen "$@" ;; esac
EOF
  chmod +x "$spell_dir/.imps/stub-gen"
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/.imps/stub-gen"
  _assert_success && _assert_output_contains "passed"
}

test_imp_fails_with_too_many_params() {
  # Imps must have 3 or fewer parameters
  spell_dir=$(make_spell_dir)
  mkdir -p "$spell_dir/.imps"
  cat >"$spell_dir/.imps/many-params-imp" <<'EOF'
#!/bin/sh

# many-params-imp A B C D - this imp has too many parameters

_many_params_imp() {
  echo "$1 $2 $3 $4"
}

case "$0" in
  */many-params-imp) _many_params_imp "$@" ;; esac
EOF
  chmod +x "$spell_dir/.imps/many-params-imp"
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/.imps/many-params-imp"
  _assert_failure && _assert_output_contains "4 parameters"
}

test_imp_passes_with_variadic_params() {
  # Variadic parameters (ending with ...) don't count toward limit
  spell_dir=$(make_spell_dir)
  mkdir -p "$spell_dir/.imps"
  cat >"$spell_dir/.imps/variadic-imp" <<'EOF'
#!/bin/sh

# variadic-imp A B C REST... - 3 regular params plus variadic

_variadic_imp() {
  echo "$@"
}

case "$0" in
  */variadic-imp) _variadic_imp "$@" ;; esac
EOF
  chmod +x "$spell_dir/.imps/variadic-imp"
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/.imps/variadic-imp"
  _assert_success && _assert_output_contains "passed"
}

test_imp_fails_with_duplicate_set_eu() {
  # Imps should not have duplicate "set -eu" statements
  spell_dir=$(make_spell_dir)
  mkdir -p "$spell_dir/.imps"
  cat >"$spell_dir/.imps/bad-duplicate-imp" <<'EOF'
#!/bin/sh

# bad-duplicate-imp - imp with duplicate set -eu
set -eu

_bad_duplicate_imp() {
  echo "test"
}

set -eu
case "$0" in
  */bad-duplicate-imp) _bad_duplicate_imp "$@" ;; esac
EOF
  chmod +x "$spell_dir/.imps/bad-duplicate-imp"
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/.imps/bad-duplicate-imp"
  _assert_failure && _assert_output_contains "duplicate 'set -eu'"
}

test_imp_passes_with_single_set_eu() {
  # Imps with single "set -eu" should pass
  spell_dir=$(make_spell_dir)
  mkdir -p "$spell_dir/.imps"
  cat >"$spell_dir/.imps/good-imp" <<'EOF'
#!/bin/sh

# good-imp - imp with single set -eu
set -eu

_good_imp() {
  echo "test"
}

case "$0" in
  */good-imp) _good_imp "$@" ;; esac
EOF
  chmod +x "$spell_dir/.imps/good-imp"
  _run_spell "spells/spellcraft/lint-magic" "$spell_dir/.imps/good-imp"
  _assert_success && _assert_output_contains "passed"
}

_run_test_case "lint-magic prints usage" test_help
_run_test_case "lint-magic accepts --usage" test_usage_alias
_run_test_case "lint-magic rejects unknown option" test_unknown_option
_run_test_case "lint-magic fails for nonexistent file" test_fails_nonexistent_file
_run_test_case "lint-magic passes well-formed spell" test_passes_well_formed_spell
_run_test_case "lint-magic fails missing shebang" test_fails_missing_shebang
_run_test_case "lint-magic fails wrong shebang" test_fails_wrong_shebang
_run_test_case "lint-magic fails missing description" test_fails_missing_description
_run_test_case "lint-magic fails missing strict mode" test_fails_missing_strict_mode
_run_test_case "lint-magic fails trailing space assignment" test_fails_trailing_space_assignment
_run_test_case "lint-magic passes imp without usage" test_passes_imp_without_usage
_run_test_case "lint-magic requires usage function" test_requires_usage_function
_run_test_case "lint-magic requires help handler" test_requires_help_handler
_run_test_case "lint-magic --list shows matching files" test_list_option
_run_test_case "lint-magic fails imp with --help handler" test_imp_fails_with_help_handler
_run_test_case "lint-magic fails imp using flags" test_imp_fails_with_flags
_run_test_case "lint-magic passes imp with heredoc flags" test_imp_passes_with_heredoc_flags
_run_test_case "lint-magic fails imp with too many params" test_imp_fails_with_too_many_params
_run_test_case "lint-magic passes imp with variadic params" test_imp_passes_with_variadic_params
_run_test_case "lint-magic fails imp with duplicate set -eu" test_imp_fails_with_duplicate_set_eu
_run_test_case "lint-magic passes imp with single set -eu" test_imp_passes_with_single_set_eu


# Test via source-then-invoke pattern  
