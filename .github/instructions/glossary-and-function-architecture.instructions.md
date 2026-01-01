# Glossary and Function Architecture Instructions

applyTo: "spells/**,.tests/**,spells/.imps/**"

## Core Architecture

**CRITICAL:** POSIX sh doesn't support hyphens in function names. Wizardry solves this via underscore functions + glosses.

1. **Imps define underscore functions**: `require_wizardry()`, `env_or()`, `menu()`
2. **Glosses provide hyphenated commands**: `require-wizardry`, `env-or`, `main-menu`
3. **invoke-wizardry preloads functions** via word_of_binding (not PATH)
4. **Only glossary in PATH** (not imp/spell directories)
5. **Background jobs call functions** (not scripts)

## Function Naming

```sh
# IMP FILE: spells/.imps/sys/require-wizardry
require_wizardry() {   # Underscore (ALWAYS works in POSIX)
  # Implementation
}
case "$0" in
  */require-wizardry) require_wizardry "$@" ;; esac
```

**In spell code, use underscores:**
```sh
require_wizardry || return 1       # ✓ CORRECT
value=$(env_or VAR "default")      # ✓ CORRECT

require-wizardry || return 1       # ✗ WRONG (causes parse loop)
value=$(env-or VAR "default")      # ✗ WRONG
```

**Users get hyphens via glosses:**
```sh
$ require-wizardry                 # ✓ Works (gloss in PATH)
$ env-or SPELLBOOK "$HOME/.spellbook"  # ✓ Works
```

## How Glosses Work

`parse` imp reconstructs multi-word commands from space-separated args:

```sh
# User: env or VAR DEFAULT
# Gloss: parse "env" "or" "VAR" "DEFAULT"
# Parse tries (longest first):
#   env_or_VAR_DEFAULT → env_or_VAR → env_or ✓ → env
# Calls: env_or("VAR", "DEFAULT")
```

**Priority:** Preloaded functions → wizardry spells → system commands

## Background Jobs

**✓ CORRECT:** Call function (has access to preloaded functions)
```sh
generate_glosses --quiet &
```

**✗ WRONG:** Execute script (new process, no functions)
```sh
"$WIZARDRY_DIR/spells/system/generate-glosses" --quiet &
```

## Testing

**Modern (sourced spell):**
```sh
run_sourced_spell generate-glosses --quiet
```

**Legacy (direct execution - doesn't work for spells needing functions):**
```sh
run_spell "spells/system/generate-glosses" --quiet
```

## invoke-wizardry Sequence

1. **Set baseline PATH** (especially macOS)
2. **Load word_of_binding** via `WIZARDRY_SOURCE_WORD_OF_BINDING=1`
3. **Preload imps** (levels 0-3): require-wizardry, env-or, parse, etc.
4. **Preload spells** (levels 0-3): detect-posix, validate-spells, generate-glosses, menu
5. **Generate glosses** (synchronous - creates functions/aliases in shell)
6. **Verify** menu loaded

## Common Mistakes

| Wrong | Right | Issue |
|-------|-------|-------|
| `require-wizardry` in spell | `require_wizardry` | Hyphen causes parse loop |
| Add imps to PATH | Preload with word_of_binding | Violates architecture |
| `./spell &` background | `spell_function &` | Script has no functions |
| `run_spell` modern spell | `run_sourced_spell` | Needs preloaded functions |

## Debugging

**"require_wizardry: not found"** → Spell using underscore but function not preloaded
- Fix: Ensure invoke-wizardry preloaded it, or use `run_sourced_spell` in tests

**"require-wizardry: not found"** → Hyphenated command not in PATH
- Fix: Use underscore in spell code: `require_wizardry`

**Background job fails** → Executing script instead of calling function
- Fix: `spell_function &` not `"$path/spell" &`
