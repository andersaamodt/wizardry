# Wizardry Repository Custom Instructions

Always read `README.md` first for project principles before making changes.

**Essential documentation**:
- `README.md` — Project principles, values, and standards
- `.AGENTS.md` — Comprehensive agent instructions and style guide
- `.github/QUICK-REFERENCE.md` — Quick lookup card for common patterns
- `.github/instructions/best-practices.instructions.md` — Proven patterns from the codebase
- `.github/instructions/spells.instructions.md` — Spell writing guide
- `.github/instructions/imps.instructions.md` — Imp (micro-helper) guide
- `.github/instructions/logging.instructions.md` — Output and error handling
- `.github/instructions/tests.instructions.md` — Testing framework and patterns

## Project Overview

Wizardry is a collection of POSIX shell scripts themed as magical spells for the terminal. It turns folders into rooms and files into items, like a fantasy MUD (Multi-User Dungeon).

## Tech Stack

- **Language**: POSIX sh only (`#!/bin/sh`) — no bash-isms
- **Style checker**: `lint-magic` and `checkbashisms`
- **Testing**: `.tests/` directory with `test_common.sh` framework
- **CI**: GitHub Actions (see `.github/workflows/`)

## Core AI Directives

1. **Preserve the spec**: Do not edit spec comments at the top of scripts or `--help` usage text unless specifically instructed
2. **Preserve the lore**: Do not delete, modify, or add flavor text unless specifically instructed
3. **No globals**: Avoid shell variables; use parameters or stdout instead
4. **No wrappers**: All files are standalone, portable, and front-facing
5. **Self-healing failures**: Fix missing prerequisites automatically or offer to fix them—never quit with imperative error messages
6. **Always add tests**: When creating new spells or imps, ALWAYS create corresponding test files in `.tests/` following the mirrored directory structure
7. **Only report actual test results**: NEVER guess, assume, or claim tests pass without actually running them. Only report test results you have verified by executing the tests. If you haven't run tests, explicitly state "tests not yet run" rather than claiming success.

## Essential Code Quality Rules

- **Shebang**: `#!/bin/sh` (not `#!/bin/bash`)
- **Strict mode**: `set -eu`
- **Quotes**: Always quote variables: `"$var"`
- **Tests**: Use `[ ]` not `[[ ]]`, `=` not `==`
- **Output**: Use `printf` not `echo`
- **Commands**: Use `command -v` not `which`
- **Paths**: Use `pwd -P`, not `realpath`

## File Structure

```
spells/           # Main spell scripts (categories as subdirs)
spells/.imps/     # Micro-helper scripts (imps)
.tests/           # Test files mirroring spells/ structure
install           # Bootstrap install script
```

## Spell Requirements

Every spell must have:
- Opening description comment (1-2 lines after shebang)
- `show_usage()` function with heredoc (unless it's an imp)
- Help handler for `--help`, `--usage`, `-h`
- `set -eu` strict mode
- Corresponding test file in `.tests/` (REQUIRED - never create a spell without its test)

**IMPORTANT**: When creating a new spell, you MUST also create a test file at `.tests/category/test_spell-name.sh` that mirrors the spell's location. Test files are not optional.

## References

- See `README.md` for project principles and values
- See `.AGENTS.md` for detailed style guide and cross-platform patterns
- See `.github/instructions/` for topic-specific guidance:
  - `spells.instructions.md` — Spell style guide
  - `imps.instructions.md` — Imp (micro-helper) guide
  - `cross-platform.instructions.md` — Platform compatibility
  - `tests.instructions.md` — Testing patterns
