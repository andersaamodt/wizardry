# Lessons Learned

**Purpose:** Document a lesson learned from EVERY bug found. This is a living record of debugging insights.

**Rules:**
- One sentence per lesson, extremely succinct
- Don't document the same lesson twice—if a lesson recurs, increment the counter at the end: `(3)`
- Maximum 1000 lines total
- When approaching 1000 lines, remove the least-important or most-conquered lessons
- Don't duplicate code policies or lessons already encoded in other AI-facing documentation
- Check this file when creating new code or debugging
- Lessons can be retired here from other documentation when no longer actively needed elsewhere

---

## Lessons

- Spells MUST NOT preload their own prerequisites (die, warn, etc.); they should fail early with require_wizardry if wizardry isn't available.
- When inlining helper functions, use global search-replace to ensure ALL calls are replaced, including those outside the main function body.
- Editing files with text processing tools (sed, awk, perl) can change file permissions - always restore execute bits afterwards.
- The `find -executable` flag is not portable to BSD/macOS; use `find -perm /111` instead to match files with any execute bit.
- When gloss generation fails silently, check that find commands are BSD-compatible and validate WIZARDRY_DIR exists.
- Parse must search WIZARDRY_DIR for spell files as fallback when preloaded functions aren't available (gloss execution in new process).
- Cross-platform shell compatibility requires testing flag availability (e.g., find flags) on both GNU and BSD implementations.
- Common system commands (find, grep, sed, etc.) must be blacklisted in generate-glosses to prevent glossary from overriding them.
- Pipe-based while loops create subshells; use variable with here-document instead to preserve loop counter updates in parent shell.
- Spells should call imps via PATH (has, say, die, etc.) instead of executing scripts as subprocesses with full paths ("${WIZARDRY_DIR}/spells/...").
- Spells are now flat, linear scripts without function wrappers; the castable/uncastable pattern and dual-pattern testing (source-then-invoke) have been deprecated.
- Imps executed as scripts (via PATH) must use `exit` not `return`; bash (Arch's /bin/sh) errors on top-level `return`, while dash (Ubuntu's /bin/sh) silently allows it.


