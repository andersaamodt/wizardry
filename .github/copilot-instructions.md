# Wizardry Repository - GitHub Copilot Instructions  🧙🔮

## Essential Reading  📚✨

1. **`README.md`** — Project principles, values, and standards (READ FIRST)  🗝️
2. **`.AGENTS.md`** — Comprehensive agent instructions and style guide  🤖📜
3. **Topic-specific instructions** (consult as needed):  🌳
   - `.github/instructions/castable-uncastable-pattern.instructions.md` — **CRITICAL**: Self-execute pattern rules (return vs exit, set -eu placement, function structure)  ⚠️🔥
   - `.github/instructions/spells.instructions.md` — Spell writing guide  ✨📖
   - `.github/instructions/imps.instructions.md` — Imp (micro-helper) guide  👹🔧
   - `.github/instructions/tests.instructions.md` — Testing framework and patterns  🧪
   - `.github/instructions/logging.instructions.md` — Output and error handling  📝⚡
   - `.github/instructions/cross-platform.instructions.md` — Platform compatibility  🌍🔗
   - `.github/instructions/best-practices.instructions.md` — Proven patterns  💎🏆

## What is Wizardry?  🪄

A collection of POSIX shell scripts themed as magical spells for the terminal. Turns folders into rooms and files into items, like a fantasy MUD (Multi-User Dungeon).  🏰🗺️

**Tech Stack:**  ⚙️
- **Language**: POSIX sh only (`#!/bin/sh`) — no bash-isms  🐚⚖️
- **Linting**: `lint-magic` and `checkbashisms`  🔍✨
- **Testing**: `.tests/` directory with test-bootstrap framework  🧪🌱
- **CI**: GitHub Actions (`.github/workflows/`)  🤖⚡

**Architecture:**  🏗️
- **Spells** = User-facing scripts in `spells/` (can assume wizardry installed and in PATH)  📜✨
- **Imps** = Micro-helpers in `spells/.imps/` (abstract common patterns)  👹🔨
- **Tests** = Mirror structure in `.tests/` (ALWAYS required for new spells/imps)  🧪🔒
- **Bootstrap scripts** = Can't assume wizardry in PATH (`install`, `spells/install/core/`)  🥾🌅

## CRITICAL: Common AI Compliance Issues  ⚠️🚨

**You MUST follow these at all times:**  🔒⚡

1. **Tests are NON-NEGOTIABLE**  🧪🔒🔥
   - ALWAYS create test files in `.tests/` when creating spells or imps  ⚠️
   - Test naming: `spells/category/spell-name` → `.tests/category/test-spell-name.sh` (hyphens, not underscores!)  📛
   - Use test-driven development (TDD) when possible  🎯
   - **ONLY report actual test results** — NEVER assume or guess tests will pass  🚫🔮
   - Run tests and report exact pass/fail counts  📊✅

2. **Abstract into imps (but only when reused)**  🔄👹
   - Create new imps ONLY if code is used in at least 2 spells  2️⃣✨
   - Always prefer using imps over inline code (except in bootstrap scripts)  🔧💡
   - Imps make spells clean, readable, and minimal  ✨📏

3. **Spells assume wizardry is installed**  🪄🏠
   - All spells can assume wizardry is in PATH  🛤️
   - All spells and imps are available  📦✅
   - Testing setup goes in tests, NOT in spell code  🧪🚫

4. **No new exemptions without permission**  🚫📋
   - All exceptions are documented in `EXEMPTIONS.md`  📖
   - Don't add new exemptions without asking first  🙋⚠️
   - Always try to reduce/eliminate existing exemptions  ♻️🎯

5. **All CI must pass before merge**  ✅🚦
   - Fix preexisting and unrelated test failures if blocking merge  🔧🚧
   - Don't back down from or mutate requirements  💪🔒
   - Don't give up until all requirements are fully completed  🏁

6. **Follow ALL project rules**  📏⚖️
   - Don't excuse yourself from any project policies  🚫🙅
   - Keep clean, readable, minimal spell files  ✨🧹
   - Make surgical, minimal changes  🔬✂️

7. **Document lessons learned in `.github/LESSONS.md`**  📝🧠
   - After EVERY bug fix or debugging session, add a one-sentence lesson to LESSONS.md  🐛💡
   - Check LESSONS.md when creating new code or debugging  🔍📚
   - If the lesson already exists, increment its counter (e.g., "(3)") instead of duplicating  🔢
   - Don't duplicate lessons already documented in other AI-facing documentation  🚫📋
   - Keep lessons extremely succinct (one sentence)  ⚡📝
   - When approaching 1000 lines, remove least-important or most-conquered lessons  🗑️🏆

## Core Principles (Must Follow)  🎯📜

1. **Preserve the spec** — Don't edit `--help` usage text or spec comments without explicit instruction  🔒📖
2. **Preserve the lore** — Don't modify flavor text unless specifically asked  🏺✨
3. **Self-healing** — Fix missing prerequisites automatically; never quit with imperative error messages  ❤️‍🩹🔧
4. **Tests required** — ALWAYS create test files in `.tests/` when creating spells/imps (NON-NEGOTIABLE)  🧪⚠️
5. **Report actual results** — ONLY report test results you've verified by running tests (NEVER guess)  📊🚫🔮

## Critical Quality Rules  ⚖️🔍

| Rule | Required | Wrong |
|------|----------|-------|
| Shebang | `#!/bin/sh` | `#!/bin/bash` |
| Strict mode | `set -eu` | (missing) |
| Variables | `"$var"` | `$var` |
| Tests | `[ ]` | `[[ ]]` |
| Comparison | `=` | `==` |
| Output | `printf` | `echo` |
| Commands | `command -v` | `which` |
| Paths | `pwd -P` | `realpath` |
| Test naming | `test-name.sh` | `test_name.sh` |

## Quick Templates  📋✨

### Spell Template  📜
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

### Imp Template (Action)  👹⚡
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

### Imp Template (Conditional - NO set -eu!)  👹❓
```sh
#!/bin/sh
# imp-name ARG - test if condition

_imp_name() {
  # Return 0 for true, 1 for false
}

case "$0" in
  */imp-name) _imp_name "$@" ;; esac
```

### Test Template  🧪
```sh
#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_feature() {
  _run_spell "spells/category/name" arg
  _assert_success && _assert_output_contains "expected"
}

_run_test_case "description" test_feature
_finish_tests
```

## Common Patterns

```sh
# Check command exists
has git || fail "git required"

# Variable defaults
name=${1-}                  # Empty if unset
path=${1:-/default/path}    # Use default if unset/empty

# Output (respects WIZARDRY_LOG_LEVEL)
say "Normal message"        # Always shown
success "Complete"          # Always shown
info "Processing..."        # Level >= 1
step "Installing..."        # Level >= 1
debug "Debug info"          # Level >= 2

# Errors (always shown)
warn "spell-name: warning message"
die "spell-name: fatal error"
die 2 "spell-name: usage error"
has git || fail "git required"
```

## Common Mistakes to AVOID

| Don't Do This | Do This Instead |
|---------------|-----------------|
| `#!/bin/bash` | `#!/bin/sh` |
| Skip tests | Always create test files |
| `[[ ]]` or `==` | `[ ]` and `=` |
| `echo` | `printf '%s\n'` |
| `$var` unquoted | `"$var"` |
| `value=$1` | `value=${1-}` |
| "Please install X" | "spell-name: X not found" + auto-fix |
| 4+ functions in spell | Split into spells or use imps |
| `test_name.sh` | `test-name.sh` (hyphens!) |
| Guess test results | Run tests, report actual counts |
| `require-wizardry` in code | `require_wizardry` (underscore!) |
| `. env-clear` | `env_clear` (call function!) |
| Execute script in background | Call function in background |
| Add imps to PATH | Preload with word_of_binding |
| `run_spell` for modern spells | `run_sourced_spell` |

## CRITICAL: Glossary and Function Architecture

**READ THIS BEFORE WORKING ON SPELLS, IMPS, OR GLOSSES:**

See `.github/instructions/glossary-and-function-architecture.instructions.md` for complete details.

**Key rules:**
1. **Spells use underscore function names:** `require_wizardry`, `env_or`, `temp_file`
2. **Glosses provide hyphenated commands:** `require-wizardry`, `env-or`, `temp-file`  
3. **Only glossary directory in PATH:** No imp/spell directories
4. **Background jobs call functions:** `generate_glosses &`, not `./generate-glosses &`
5. **Tests use sourced spells:** `run_sourced_spell spell-name` for modern spells

**Common mistakes that cause "command not found" errors:**
- Using hyphenated names in spell code (`require-wizardry` → `require_wizardry`)
- Executing scripts in background instead of calling functions
- Adding imp directories to PATH (violates architecture)
- Using `run_spell` for spells that need preloaded functions

## Workflows

### Creating a New Spell

1. **Plan**: One focused thing? < 100 lines? ≤ 3 functions?
2. **Copy template** from above
3. **Implement** following `.github/instructions/spells.instructions.md`
4. **Create test** at `.tests/category/test-spell-name.sh` (REQUIRED)
5. **Run test** with `test-spell category/test-spell-name.sh` (includes common tests)
6. **Lint**: `lint-magic spells/category/spell-name`
7. **Check POSIX**: `checkbashisms spells/category/spell-name`

### Creating a New Imp

1. **Verify reuse**: Is code used in at least 2 spells? (If not, don't create imp)
2. **Plan**: One thing? < 50 lines? Zero or one function?
3. **Determine type**: Conditional (no `set -eu`) or Action (`set -eu`)?
4. **Copy template** from above
5. **Implement** following `.github/instructions/imps.instructions.md`
6. **Create test** at `.tests/.imps/family/test-imp-name.sh` (REQUIRED)
7. **Run test** with `test-spell .imps/family/test-imp-name.sh` (includes common tests)

## File Types

| Type | Location | Purpose |
|------|----------|---------|
| **Spell** | `spells/category/name` | User-facing command |
| **Imp** | `spells/.imps/family/name` | Micro-helper (internal, reusable) |
| **Test** | `.tests/category/test-name.sh` | Test for spell/imp (REQUIRED) |
| **Bootstrap** | `install`, `spells/install/core/` | Pre-wizardry scripts |

## Key Concepts

- **Spell** = Focused, self-contained script that does one thing well
- **Imp** = Smallest building block; abstracts common patterns (`has`, `say`, `die`)
- **Test** = POSIX sh script that exercises a spell's behavior (ALWAYS required)
- **Function discipline** = Spells have `show_usage()` + at most 1-2 other functions
- **Bootstrap** = Scripts that run before wizardry is installed (can't use imps)

## Documentation Map

**Working on spells?** → `.github/instructions/spells.instructions.md`  
**Working on imps?** → `.github/instructions/imps.instructions.md`  
**Writing tests?** → `.github/instructions/tests.instructions.md`  
**Need logging/output?** → `.github/instructions/logging.instructions.md`  
**Cross-platform issues?** → `.github/instructions/cross-platform.instructions.md`  
**Proven patterns?** → `.github/instructions/best-practices.instructions.md`  
**Lessons from debugging?** → `.github/LESSONS.md`  
**Full style guide?** → `.AGENTS.md`  
**Project philosophy?** → `README.md`

## Model Code to Study

- **Spells**: `spells/arcane/forall` (minimal), `spells/arcane/look` (excellent help text)
- **Imps**: `spells/.imps/out/say` (action), `spells/.imps/cond/has` (conditional)
- **Tests**: `.tests/arcane/test-forall.sh` (comprehensive)

## Every Spell Must Have

- Opening description comment (1-2 lines after shebang)
- `show_usage()` function with heredoc (unless it's an imp)
- Help handler for `--help`, `--usage`, `-h`
- `set -eu` strict mode
- **Corresponding test file in `.tests/`** (NON-NEGOTIABLE)

## Before Submitting

- [ ] Read README.md (Values, Design Tenets, Engineering Standards)
- [ ] Consulted relevant instruction file
- [ ] Created tests for any new spells or imps
- [ ] **Ran tests and verified they pass** (report actual counts, don't guess!)
- [ ] Checked style with `lint-magic`
- [ ] Verified POSIX compliance with `checkbashisms`
- [ ] Used templates from this file
- [ ] Preserved `--help` text and flavor text (unless explicitly changing)
- [ ] Made minimal, surgical changes
- [ ] All variables quoted, using `${var-}` for optional args
- [ ] Error messages are descriptive, not imperative
- [ ] Abstract reusable code into imps (if used in 2+ spells)
- [ ] No new exemptions added without permission

---

**Remember:** Clean, readable, minimal spell files. Testing setup in tests, not spells. Always TDD. Always run tests. Always use imps. Always follow ALL project rules.
