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
- The `find -executable` flag is not portable to BSD/macOS; use `find -perm /111` (GNU) with fallbacks to `-perm +111` (BSD) and manual `[ -x ]` check.
- When gloss generation fails silently, check that find commands are BSD-compatible and validate WIZARDRY_DIR exists.
- Parse must search WIZARDRY_DIR for spell files as fallback when preloaded functions aren't available (gloss execution in new process).
- Cross-platform shell compatibility requires testing flag availability (e.g., find flags) on both GNU and BSD implementations.
- Common system commands (find, grep, sed, etc.) must be blacklisted in generate-glosses to prevent glossary from overriding them.
- Pipe-based while loops create subshells; use variable with here-document instead to preserve loop counter updates in parent shell.
- Spells should call imps via PATH (has, say, die, etc.) instead of executing scripts as subprocesses with full paths ("${WIZARDRY_DIR}/spells/...").
- Spells are now flat, linear scripts without function wrappers; the castable/uncastable pattern and dual-pattern testing (source-then-invoke) have been deprecated.
- Imps executed as scripts (via PATH) must use `exit` not `return`; bash (Arch's /bin/sh) errors on top-level `return`, while dash (Ubuntu's /bin/sh) silently allows it.
- Shell builtins like `disable` (bash builtin for disabling commands/functions) must be blacklisted in generate-glosses to prevent creating first-word glosses that conflict.
- Always establish realistic unit tests for every feature BEFORE writing or fixing code; tests are the fastest path to working code and catch edge cases immediately (TDD).
- Aliases for hyphenated sourced-only spells must expand to space-separated form (jump to marker) not hyphenated (jump-to-marker) to route through first-word glosses.
- Parse must skip both functions AND aliases when trying system commands as fallback; aliases cause wrong behavior (expansion before exec).
- First-word glosses must check BOTH real spell files AND synonym files when looking for uncastable spells to source.
- Shell builtin `read` CANNOT be overridden as it breaks while loops; must be blacklisted in generate-glosses even though read-magic exists.
- Spells executed directly (not sourced) must use `exit` not `return` for flow control; `return` outside a function causes "not within a function" errors.
- Use shell parameter expansion ${file##*/} instead of basename for 100x speedup when processing many files (e.g., generate-glosses with 396 files).
- Variable `$_i` (imps directory shorthand) is not preserved by env-clear; use `${WIZARDRY_DIR}/spells/.imps` instead when referencing imp paths after sourcing env-clear.


- When a file is sourced (`. filename`), using `exit` exits the parent shell; use `return` instead (discovered via doppelganger failing to create directories) (3)
- Bootstrap imps (env-clear, invoke-thesaurus, invoke-wizardry) must use inline sourced-only checks, not call the uncastable imp, because they're sourced before PATH is properly set up (discovered via doppelganger compile failure)
- Sourced-only scripts (invoke-wizardry, env-clear, invoke-thesaurus) must use `return 0` not `exit 0` for normal completion to avoid exiting parent shell (2)
- Test helper imps that are sourced (skip-if-compiled) must define functions and use self-execute pattern, not use bare `exit` statements which exit the calling test
- When implementing a feature across "all items" (e.g., adding colors to all install-menu entries), systematically verify each item is covered rather than assuming completion - PR #874 added colors to core-status and tor-status, but mud-status was never created, leaving one menu item without colors.
- The word-of-binding function-preloading paradigm was deprecated in favor of simpler PATH-based imp execution.
- .imps/sys directory must be in PATH so system imps like require-wizardry are directly callable as commands (PR #594).
- Circular dependency during sourcing: imps must be available before spells call them; add all imp families to PATH before sourcing (PR #595).
- Scripts must verify prerequisites exist before calling them to avoid "command not found" errors during bootstrap (PR #596).
- Consolidated AI documentation improves consistency by guaranteeing all critical information is read from a single entry point (PR #598).
- Sourcing a file with `set -eu` permanently affects the parent shell's mode; restore permissive mode with `set +eu` after sourcing (PR #599).
- macOS Terminal.app opens login shells by default, requiring .bash_profile to source .bashrc for shell configuration availability (PR #600).
- invoke-wizardry must auto-detect its location using shell-specific variables (BASH_SOURCE[0], ${(%):-%x}) instead of hardcoding $HOME/.wizardry (PR #601).
- RC file manipulation should use inline markers (. "/path" # wizardry: marker-name) instead of separate comment lines for consistent editing (PR #602).
- Menu exit handlers must validate parent PID exists before sending kill signals to prevent terminating unintended processes (PR #606).
- Always establish realistic unit tests for every feature BEFORE writing or fixing code; tests are the fastest path to working code and catch edge cases immediately.
- Default prompts for optional features should match expected common usage patterns (e.g., MUD defaults to "yes" for installation) (PR #607).
- Failed subtests must cause their parent test to fail; testing system integrity requires meta-tests that validate the testing infrastructure itself (PR #609).
- Compiled spells in doppelganger mode are standalone without invoke-wizardry/env-clear; tests must skip infrastructure-dependent checks in compiled mode (PR #610).
- Self-execute pattern case matching on $0 depends on path format; verify patterns match both relative and resolved absolute paths on all platforms (PR #611).
- Stub system requires strict PATH ordering with stub directory first to successfully override real commands with mocked versions (PR #612).
- Bubblewrap (bwrap) sandboxing compatibility varies by platform; graceful fallback ensures tests run successfully without sandboxing where unavailable (PR #613).
- Boolean logic with && || chains can cause unexpected early returns due to short-circuit evaluation; use explicit if-then-fi for clarity (PR #614).
- Testing system regressions are prevented by making test infrastructure itself testable with dedicated validation test files (PR #615).
- Pipe output buffering in pipelines requires explicit stdbuf -oL on all stages, not just the first command, to ensure line-by-line output (PR #616).
- Common structural tests should run by default for individual spell testing to ensure complete validation coverage (PR #617).
- Subprocess invocations must redirect stdin from /dev/null (< /dev/null) to prevent blocking if any subprocess attempts to read stdin (PR #619).
- Performance profiling infrastructure with --profile flag enables systematic identification of bottlenecks (e.g., common-tests.sh: 67s → 64s via grep reduction) (PR #622).
- Infinite recursion in command_not_found_handle requires a guard flag (_IN_CNF_HANDLER) to detect re-entry and prevent terminal hangs (PR #623).
- macOS login shell modifications (.zprofile sourcing .zshrc) must be tracked during install and completely removed during uninstall to prevent stale code (PR #624).
- Toggleable features in configuration files allow users to selectively disable functionality for isolating and debugging complex issues (PR #626).
- Installation cancellation or interruption should trigger cleanup of downloaded wizardry directory to avoid leaving partial installations (PR #627).
- Debug logging with timestamps, file paths, and success/failure counts helps diagnose complex shell initialization and sourcing issues (PR #629).
- Glob patterns stored in variables don't expand in POSIX sh; use `set -- "$dir"/*` to populate positional parameters for reliable shell glob expansion (PR #668).
- Negated assignment patterns `if ! var=$(cmd)` can trigger zsh parse errors when sourced; separate into assignment then condition for cross-shell compatibility (PR #669).
- AWK regex patterns in shell strings require double backslashes (\\) not quadruple (\\\\) for proper pattern escaping in extraction operations (PR #670).
- Bootstrap spells in `.arcana/core` run before wizardry installation and must not depend on wizardry imps (castable, require-wizardry, env-clear) (PR #672).
- Multi-cd shell patterns for path calculation (`cd dir1 && cd dir2`) create 2-3 extra process forks per execution; use parameter expansion ${var%/*} for significant performance improvement (PR #674).
