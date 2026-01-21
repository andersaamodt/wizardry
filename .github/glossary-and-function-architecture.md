# Glossary and Function Architecture Instructions

applyTo: "spells/**,.tests/**,spells/.imps/**"

## Core Architecture

**CRITICAL:** All wizardry spells (including imps—imps ARE spells) call each other by hyphenated command names from PATH.

**After invoke-wizardry runs:**
1. All wizardry spells and imps are available in PATH
2. Spells call each other by hyphenated names: `env-clear`, `has`, `temp-file`
3. Never use full paths: NOT `$WIZARDRY_DIR/spells/.imps/...`
4. Never use underscores in spell calls: NOT `env_clear` or `temp_file`

**Function names vs spell names:**
- **Function names** (inside functions): Use underscores (POSIX requirement) - `my_function()`
- **Spell calls** (calling other spells): Use hyphens (from PATH) - `env-clear`, `has git`

## How Glosses Work

`parse` imp reconstructs multi-word commands from space-separated args:

```sh
# User types: env or VAR DEFAULT
# First-word gloss: parse "or" "VAR" "DEFAULT"
# Parse reconstructs: env-or "VAR" "DEFAULT"
# Executes the env-or spell from PATH
```

Multi-word commands are split into space-separated words, then reconstructed by first-word glosses calling parse.

## Spell Invocation

**Modern pattern (all spells in PATH):**
```sh
# ✅ CORRECT - Call spells by hyphenated name from PATH
env-clear
has git || exit 1
temp-file "data.txt"
cursor-blink on
```

**WRONG patterns:**
```sh
# ❌ WRONG - Never use underscores
env_clear
temp_file "data.txt"

# ❌ WRONG - Never use full paths
"$WIZARDRY_DIR/spells/.imps/sys/env-clear"
. "$WIZARDRY_DIR/spells/.imps/sys/env-clear"
```

## Testing

**For regular spells (executed):**
```sh
run_spell "spells/category/spell-name" --args
```

**For uncastable spells (must be sourced):**
```sh
run_sourced_spell "spells/category/spell-name" --args
```

**run_spell vs run_sourced_spell:**
- `run_spell`: Executes the spell as a script (most spells)
- `run_sourced_spell`: Sources the spell (for uncastable spells like jump-to-marker)

## invoke-wizardry Sequence

1. **Set baseline PATH** (especially macOS)
2. **Add all spell/imp directories to PATH**
3. **Validate spells** 
4. **Generate glosses** (creates first-word wrappers for multi-word commands)
5. **Verify** menu loaded

## Common Mistakes

| Wrong | Right | Issue |
|-------|-------|-------|
| `env_clear` in spell | `env-clear` | Use hyphenated command name |
| `temp_file` in spell | `temp-file` | Use hyphenated command name |
| `"$WIZARDRY_DIR/..."` | `spell-name` | Use PATH, not full paths |
| `run_spell` for uncastable | `run_sourced_spell` | Uncastable spells must be sourced |

## Debugging

**"env-clear: not found"** → PATH not set up correctly
- Fix: Ensure invoke-wizardry ran successfully
- Check: `echo $PATH` should include wizardry directories

**Background job fails** → Spell not in PATH
- Fix: Call spell by hyphenated name from PATH: `spell-name &`
- NOT: `"$path/spell" &`
