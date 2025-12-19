# Wizardry Quick Reference Card for AI Assistants

Quick lookups for common patterns. See `.github/instructions/best-practices.instructions.md` for full details.

## 🔧 Common Patterns

### Spell Template
```sh
#!/bin/sh
# Brief description

show_usage() { cat <<'USAGE'
Usage: spell-name [args]
Description.
USAGE
}

case "${1-}" in
--help|--usage|-h) show_usage; exit 0 ;; esac

require-wizardry || exit 1
set -eu
. env-clear

# Main logic
```

### Imp Template (Action)
```sh
#!/bin/sh
# imp-name ARG - brief description
set -eu

_imp_name() {
  # Implementation
}

case "$0" in
  */imp-name) _imp_name "$@" ;; esac
```

### Imp Template (Conditional)
```sh
#!/bin/sh
# imp-name ARG - test if condition
# NO set -eu for conditionals!

_imp_name() {
  # Return 0 for true, 1 for false
}

case "$0" in
  */imp-name) _imp_name "$@" ;; esac
```

### Test Template
```sh
#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_feature() {
  _run_spell "spells/category/spell-name" arg
  _assert_success && _assert_output_contains "expected"
}

_run_test_case "description" test_feature
_finish_tests
```

## 📋 Quick Checks

### Before Creating a Spell
- [ ] Is the spell focused on one thing?
- [ ] Can it be < 100 lines?
- [ ] Does it need ≤ 3 functions total?
- [ ] Is help text ≤ 10 lines?
- [ ] Will you create the test file?

### Before Creating an Imp
- [ ] Does it do exactly one thing?
- [ ] Is it < 50 lines?
- [ ] Zero or one function?
- [ ] Is it reusable?
- [ ] Conditional → no `set -eu`
- [ ] Action → use `set -eu`

### Before Committing
- [ ] All tests created and passing?
- [ ] `set -eu` present?
- [ ] Variables quoted?
- [ ] `${1-}` for optional args?
- [ ] Error messages descriptive, not imperative?
- [ ] Spell name in error messages?

## 🚫 Common Mistakes

| Mistake | Correct |
|---------|---------|
| `var= ` (space) | `var=''` or `var=""` |
| `value=$1` | `value=${1-}` |
| `[[ ]]` | `[ ]` |
| `==` | `=` |
| `echo` | `printf` |
| `which` | `command -v` |
| `realpath` | `pwd -P` |
| `source` | `.` |
| Test: `test_name.sh` | `test-name.sh` |
| Error: "Please install X" | "spell-name: X not found" |

## 🎯 Output and Errors

```sh
# Always shown
say "Normal output"
success "Installation complete"
warn "spell-name: something unexpected"
die "spell-name: fatal error"
die 2 "spell-name: usage error"

# Respect WIZARDRY_LOG_LEVEL
info "Processing files..."      # Level >= 1
step "Installing packages..."   # Level >= 1
debug "Variable: $var"          # Level >= 2

# Conditional checks
has git || fail "git required"
```

## 📏 Function Limits

- `show_usage()` - Required (except imps)
- 0-1 additional - ✅ Freely allowed
- 2 additional - ⚠️ Acceptable with warning
- 3 additional - ⚠️⚠️ Marginal
- 4+ additional - ❌ Must refactor

## 🧪 Test Patterns

```sh
# Create temp directory
tmpdir=$(_make_tempdir)

# Run spell
_run_spell "spells/category/name" arg1 arg2

# Assertions
_assert_success || return 1
_assert_failure || return 1
_assert_output_contains "text" || return 1
_assert_error_contains "text" || return 1

# Stub terminal I/O (minimal stubbing)
stub_dir="$tmpdir/stubs"
mkdir -p "$stub_dir"
for stub in fathom-cursor stty; do
  ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
done
PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$PATH"
```

## 🔍 Variable Patterns

```sh
# Empty default (most common)
value=${1-}              # Empty if unset
name=${NAME-}            # Empty if unset

# Non-empty default
value=${1:-default}      # Default if unset OR empty
path=${PATH:-/usr/bin}   # Default if unset OR empty

# Conditional assignment
: "${VAR:=default}"      # Set VAR if unset or empty

# PATH baseline (bootstrap only)
baseline_path="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
case ":${PATH-}:" in
  *":/usr/bin:"*|*":/bin:"*) ;;
  *) PATH="${baseline_path}${PATH:+:}${PATH-}" ;;
esac
export PATH
```

## 📚 Documentation References

- `README.md` - Project principles and values
- `.AGENTS.md` - Comprehensive style guide
- `.github/instructions/best-practices.instructions.md` - Full patterns (this summary)
- `.github/instructions/spells.instructions.md` - Spell details
- `.github/instructions/imps.instructions.md` - Imp details
- `.github/instructions/logging.instructions.md` - Output standards
- `.github/instructions/tests.instructions.md` - Testing framework

## 🎲 Examples to Study

**Excellent spells**:
- `spells/arcane/forall` - Minimal, focused, well-documented
- `spells/cantrips/menu` - Complex but well-structured

**Model imps**:
- `spells/.imps/out/say` - Simple action imp
- `spells/.imps/cond/has` - Conditional imp (no set -eu)
- `spells/.imps/sys/on-exit` - Signal handling

**Model tests**:
- `.tests/arcane/test-forall.sh` - Comprehensive coverage
- `.tests/.imps/out/test-say.sh` - Simple imp test

---

**Remember**: These are proven patterns from real code. When in doubt, look at existing examples in the codebase!
