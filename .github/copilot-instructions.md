# Wizardry Repository - GitHub Copilot Instructions

> **New to wizardry?** → Start with **`.github/AI-ONBOARDING.md`** for a complete step-by-step guide.  
> **Looking for something specific?** → Use the "How to Find Documentation" section below.

## Quick Start

**Essential reading** (in order):
1. **`README.md`** — Project principles, values, and standards (required first read)
2. **`.github/QUICK-REFERENCE.md`** — Quick lookup card for common patterns
3. **`.AGENTS.md`** — Comprehensive agent instructions and style guide

**Topic-specific instructions** (consult as needed):
- `.github/instructions/spells.instructions.md` — Spell writing guide
- `.github/instructions/imps.instructions.md` — Imp (micro-helper) guide  
- `.github/instructions/tests.instructions.md` — Testing framework and patterns
- `.github/instructions/logging.instructions.md` — Output and error handling
- `.github/instructions/cross-platform.instructions.md` — Platform compatibility
- `.github/instructions/best-practices.instructions.md` — Proven patterns from the codebase

## What is Wizardry?

A collection of POSIX shell scripts themed as magical spells for the terminal. Turns folders into rooms and files into items, like a fantasy MUD (Multi-User Dungeon).

**Tech Stack:**
- **Language**: POSIX sh only (`#!/bin/sh`) — no bash-isms
- **Linting**: `lint-magic` and `checkbashisms`
- **Testing**: `.tests/` directory with test-bootstrap framework
- **CI**: GitHub Actions (`.github/workflows/`)

## Core Principles (Must Follow)

1. **Preserve the spec** — Don't edit `--help` usage text or spec comments without explicit instruction
2. **Preserve the lore** — Don't modify flavor text unless specifically asked
3. **Self-healing** — Fix missing prerequisites automatically; never quit with imperative error messages
4. **Tests required** — Always create test files in `.tests/` when creating spells/imps
5. **Report actual results** — Only report test results you've verified by running tests

## Critical Quality Rules

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

## File Structure

```
spells/           # Main spell scripts (categories as subdirs)
  .imps/          # Micro-helper scripts (imps)
.tests/           # Test files mirroring spells/ structure
install           # Bootstrap install script
```

## Every Spell Must Have

- Opening description comment (1-2 lines after shebang)
- `show_usage()` function with heredoc (unless it's an imp)
- Help handler for `--help`, `--usage`, `-h`
- `set -eu` strict mode
- **Corresponding test file in `.tests/`** (non-negotiable)

**Test naming**: `spells/category/spell-name` → `.tests/category/test-spell-name.sh`

## How to Find Documentation

**Working on spells?** → `.github/instructions/spells.instructions.md`  
**Working on imps?** → `.github/instructions/imps.instructions.md`  
**Writing tests?** → `.github/instructions/tests.instructions.md`  
**Need logging/output?** → `.github/instructions/logging.instructions.md`  
**Cross-platform issues?** → `.github/instructions/cross-platform.instructions.md`  
**Need a pattern?** → `.github/QUICK-REFERENCE.md`  
**Need context?** → `README.md` and `.AGENTS.md`

## Common Tasks

**Check style compliance**: `lint-magic spells/category/spell-name`  
**Run tests**: `.tests/category/test-spell-name.sh`  
**Run all tests**: `test-magic` (if wizardry installed)

## Architecture Notes

- **Spells** = User-facing scripts in `spells/`
- **Imps** = Micro-helpers in `spells/.imps/`
- **Tests** = Mirror structure in `.tests/`
- **Bootstrap scripts** = Can't assume wizardry in PATH (`install`, `spells/install/core/`)

See `.AGENTS.md` for comprehensive architectural details and coding standards.
