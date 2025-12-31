# CONTINUATION_NOTES.md

## For the Next Agent: How to Continue This Conversion

**Created:** 2025-12-31  
**Current Status:** 2.6% complete (10 of 390 files converted)  
**Estimated Remaining Effort:** Multiple sessions required

---

## Quick Start

1. **Read these documents first:**
   - `SPIRAL_DEBUG.md` - Current progress tracker
   - `CONVERSION_GUIDE.md` - Detailed conversion patterns
   - This file - Continuation strategy

2. **Current state:**
   - Pattern well-established ✅
   - 10 files converted and tested ✅
   - Average 45% code reduction ✅
   - All conversions working ✅

3. **Next steps:**
   - Continue systematic conversion in batches
   - Focus on imps first (easier, more files)
   - Then tackle remaining spells
   - Update infrastructure last

---

## What's Been Done

### ✅ Completed:
- Documentation and planning
- Conversion pattern established
- Core imps converted (out/, cond/)
- Test spells converted
- **Original `path-wizard` restored** - Simple add/remove PATH utility (from commit 8ff484c0)
- All changes tested and working

### Converted Files (10 total):

**Spells (2):**
- `arcane/forall` - Simple iteration spell
- `arcane/file-list` - File listing utility

**Imps (8):**
- `out/say`, `out/die`, `out/warn`, `out/fail`, `out/info` - Output helpers
- `cond/has`, `cond/is`, `cond/there` - Conditional tests

### Restored Infrastructure:

**`spells/path-wizard`:**
- Original version from early wizardry history (commit 8ff484c0)
- Simple add/remove interface for PATH management
- Works directly with .bashrc file
- Proven to work across all platforms (Linux, macOS, BSD)
- No complex modes or generation - just straightforward PATH manipulation

### Code Reduction Achieved:
- **Spells:** 58% reduction (153 → 65 lines)
- **Imps:** 37% reduction (163 → 103 lines)
- **Overall:** 45% average reduction

---

## Conversion Patterns (Copy-Paste Ready)

### For Spells:

**Find & Replace Pattern:**
1. Rename `spell_name_usage()` → `show_usage()`
2. Move help handler before `set -eu`
3. Change `return 0` → `exit 0` in help
4. Remove `spell_name()` wrapper function
5. Remove `require_wizardry || return 1` line
6. Remove `env_clear` or `env-clear` line
7. Delete entire castable loading block (~30 lines at end)
8. Change all `return N` → `exit N` in main code
9. Optionally replace `say` with `printf '%s\n'`

**Template:**
```sh
#!/bin/sh
# Description

show_usage() {
  cat <<'USAGE'
Usage: spell-name [args]
Description.
USAGE
}

case "${1-}" in
--help|--usage|-h)
  show_usage
  exit 0
  ;;
esac

set -eu

# Main logic (no wrapper function)
```

### For Imps:

**Find & Replace Pattern:**
1. Remove `imp_name()` function wrapper
2. Remove `case "$0" in */imp-name) imp_name "$@" ;; esac`
3. Keep `set -eu` for action imps
4. Do NOT add `set -eu` for conditional imps (cond/, lex/, menu/)
5. Change `return` → `exit` throughout

**Action Imp Template:**
```sh
#!/bin/sh
# imp-name ARG - description
set -eu

# Direct implementation (no function)
```

**Conditional Imp Template:**
```sh
#!/bin/sh
# imp-name ARG - description
# Note: No set -eu (conditional imp)

# Direct implementation
[ condition ] && exit 0
exit 1
```

---

## Recommended Batch Order

### Batch 1 (Next - DO THIS): Remaining `out/` Imps (10-15 files)
```
spells/.imps/out/debug
spells/.imps/out/step  
spells/.imps/out/success
spells/.imps/out/usage-error
spells/.imps/out/print-fail
spells/.imps/out/print-pass
spells/.imps/out/heading-*
spells/.imps/out/else
spells/.imps/out/first-of
spells/.imps/out/ok (alias for quiet)
spells/.imps/out/quiet
spells/.imps/out/disable-palette
```

### Batch 2: Remaining `cond/` Imps (10 files)
```
spells/.imps/cond/yes
spells/.imps/cond/no
spells/.imps/cond/empty
spells/.imps/cond/nonempty
spells/.imps/cond/full
spells/.imps/cond/given
spells/.imps/cond/gone
spells/.imps/cond/newer
spells/.imps/cond/older
spells/.imps/cond/lacks
spells/.imps/cond/in-*
spells/.imps/cond/is-*
```

### Batch 3: `str/` String Imps (15 files)
```
spells/.imps/str/*
```

### Batch 4: `paths/` Path Imps (10 files)
```
spells/.imps/paths/*
```

### Batch 5: `fs/` Filesystem Imps (10 files)
```
spells/.imps/fs/*
```

### Batch 6: Simple Spells - `arcane/` (10 files)
```
spells/arcane/copy
spells/arcane/trash
spells/arcane/read-magic
spells/arcane/jump-trash
(pick shortest/simplest ones)
```

### Batch 7: Simple Spells - `divination/` (5 files)
```
spells/divination/detect-distro
spells/divination/detect-magic
(simpler ones first)
```

### Batch 8-N: Continue systematically
- More imps (sys/, text/, input/, etc.)
- More spells (cantrips/, system/, menu/, etc.)

---

## Testing Strategy

After EACH batch:

```sh
# Test a converted spell
cd /home/runner/work/wizardry/wizardry
./spells/arcane/forall --help

# Test a converted imp
./spells/.imps/out/say "test"

# If any tests exist for the files, run them
./spells/system/test-magic --only "pattern"
```

**Don't move to next batch until current batch works!**

---

## File Tracking

### Count Remaining Files:
```sh
cd /home/runner/work/wizardry/wizardry

# Spells with castable
grep -l "castable" spells/*/* spells/*/*/* 2>/dev/null | wc -l

# Imps with self-execute
grep -l "case.*0.*in" spells/.imps/*/* 2>/dev/null | wc -l
```

### Find Shortest Files (easiest to convert):
```sh
for f in spells/arcane/*; do
  [ -f "$f" ] && echo "$(wc -l < "$f") $f"
done | sort -n | head -10
```

---

## Progress Tracking

After each batch, update:

1. **SPIRAL_DEBUG.md:**
   - Add files to "Files Converted So Far"
   - Update phase status
   - Update totals

2. **Git commit:**
   ```sh
   git add .
   git commit -m "Convert batch N: <description>"
   git push
   ```

3. **Update PR description** with current progress

---

## Common Issues & Solutions

### Issue: Spell uses imps that aren't converted yet
**Solution:** Either:
- Convert the needed imp first, OR
- Replace imp call with inline code temporarily

### Issue: Tests fail after conversion
**Solution:**
- Check if test expects function names (old pattern)
- Most tests should work with direct execution
- May need to update test later (Phase 10)

### Issue: Not sure if imp is conditional or action
**Check:**
- Conditional: Returns exit codes, used in `if`/`&&`/`||`, no `set -eu`
- Action: Produces output or side effects, has `set -eu`

### Issue: Spell has complex helper functions
**Solution:**
- Keep helper functions that are used 2+ times
- Inline single-use helpers
- May need to refactor to multiple spells

---

## When to Stop and Ask

Stop and ask the user if you encounter:

1. **Bootstrap scripts** - These need special handling
2. **Complex menu spells** - May need architectural changes
3. **spells/cantrips/colors** - This is source-only, special case
4. **Arcana (.arcana/*) ** - These may have different rules
5. **Infrastructure files** - invoke-wizardry, word-of-binding, etc.

These require more careful consideration!

---

## Infrastructure Changes (Later Phases)

**Don't touch these yet - focus on spell/imp conversion first:**

- `spells/.imps/sys/invoke-wizardry` - Remove in Phase 6
- `spells/.imps/sys/word-of-binding` - Remove in Phase 6
- `spells/.imps/sys/castable` - Remove in Phase 6
- `spells/.imps/sys/uncastable` - Remove in Phase 6
- `spells/system/generate-glosses` - Remove in Phase 6
- `install` script - Update PATH in Phase 7
- Test infrastructure - Update in Phase 10

---

## Success Criteria for This Session

A good stopping point is when you've:
- Converted 30-50 total files (we're at 10 now)
- Tested all conversions
- Updated documentation
- Clear notes for next session

Don't try to finish everything - this is a marathon!

---

## Key Mantras

1. **Test after every batch** - Don't let problems accumulate
2. **Update docs frequently** - Next agent needs clear status
3. **Systematic, not random** - Work through imp families and spell categories in order
4. **Simple before complex** - Convert easy files first to build confidence
5. **It's okay to be incomplete** - Document where you stopped clearly

---

## Quick Reference Commands

```sh
# Navigate to repo
cd /home/runner/work/wizardry/wizardry

# Test spell
./spells/arcane/forall --help

# Test imp
./spells/.imps/out/say "test"

# Count lines in file
wc -l spells/arcane/forall

# Find files with pattern
grep -l "castable" spells/*/* 2>/dev/null

# Commit progress
git add -A
git commit -m "Convert batch: description"
git push
```

---

## Summary

**You're in good shape!** The pattern is clear, examples work, documentation is solid. Just continue systematically:

1. Pick next batch (recommend: finish `out/` imps)
2. Convert 10-15 files
3. Test each one
4. Commit and update docs
5. Repeat

Good luck! 🎯
