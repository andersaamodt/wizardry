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

- When inlining helper functions, use global search-replace to ensure ALL calls are replaced, including those outside the main function body.
- Editing files with text processing tools (sed, awk, perl) can change file permissions - always restore execute bits afterwards.
- The `find -executable` flag is not portable to BSD/macOS; use `find -perm /111` instead to match files with any execute bit.
- When gloss generation fails silently, check that find commands are BSD-compatible and validate WIZARDRY_DIR exists.
- Parse must search WIZARDRY_DIR for spell files as fallback when preloaded functions aren't available (gloss execution in new process).
- Cross-platform shell compatibility requires testing flag availability (e.g., find flags) on both GNU and BSD implementations.
- All AI-facing documentation files (except README.md) must be in `.github/` directory per documentation policy, never in project root.

