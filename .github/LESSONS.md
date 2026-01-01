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

