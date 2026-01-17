# Exit 139 evidence from recent PRs

## First confirmed appearance (from workflow logs)
- PR #934 shows exit 139 on Ubuntu/macOS/NixOS logs with DEBUG banish output and segfaults; PR #933 shows exit code 127 but no 139. (Source: `./.github/read-test-failures 934` and `./.github/read-test-failures 933` on 2026-01-16)
- Workflow-log scan scope for exit 139 to date: PRs 932–942 via `read-test-failures`. (Source: `./.github/read-test-failures 932`–`942` on 2026-01-16)

## Recent hypothesis workflow results
- Workflow 139-340 (gloss blocks 142–181) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-17)
- Workflow 139-222 (block 35 only, core gloss) completed successfully; block 36 (manage gloss) was suspected after block 35 success and block 35-36 lagging in 139-210. (Source: local gloss block scan via generate-glosses on 2026-01-17)
- Workflow 139-12 (banish direct path with glosses) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-13 (banish gloss function unset) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-16 (banish level 8 with glosses disabled) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-17 (test-magic only) failed with ordinary test failures (exit 1), not exit 139. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-18 (banish level 8 with glosses, no-tests/no-heal) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-19 (banish level 8 with glosses, no-tests with heal) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-20 (banish level 8 with glosses and tests enabled) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-21 (banish level 8 then test-magic) failed with ordinary test failures (exit 1), not exit 139. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-22 (banish level 8 test-helpers-only) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-23 (test-magic no-gloss) failed with ordinary test failures (exit 1), not exit 139. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-24 (test-magic test-helpers-only) failed with ordinary test failures (exit 1), not exit 139. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-25 (banish level 8 no-gloss then test-magic) failed with ordinary test failures (exit 1), not exit 139. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-26 (parse banish level 8) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-27 (manual gloss banish level 8) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-28 (banish level 8 loop with glosses) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-29 (banish level 8 loop with tests) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-30 (banish 8 then test-magic loop) failed with ordinary test failures (exit 1), not exit 139. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-31 (banish level 0 loop with glosses) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-32 (parse banish 0 loop) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-33 (generate-glosses loop) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-34 (subshell invoke loop) exited with code 139 (SIGSEGV) during the subshell banish invocation. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-35 (banish 8 regenerate gloss cache loop) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-36 (test-magic loop) failed with ordinary test failures (exit 1), not exit 139. (Source: GitHub Actions run on 2026-01-16)
- Workflow 139-37 (manual gloss loop) completed successfully; no exit 139 observed. (Source: GitHub Actions run on 2026-01-16)

## PR #933 vs #934 code comparison (local git review)
- PR #933 adds the test-environment detection imp and wires environment fact reporting into banish (level 0) to improve test visibility and tooling checks. (Source: `git show --stat 946405bc` and `git show --stat 5e0c96d1` on 2026-01-16)
- PR #934 introduces function-based gloss generation and relies on parse for first-word invocation, with deeper parsing rules (skip numeric args, recursion guard) plus gloss caching in invoke-wizardry. (Source: `git show --stat 5e0c96d1` on 2026-01-16)
- Commands used for comparison: `git show --stat 946405bc`, `git show --stat 5e0c96d1`, `git log --oneline 946405bc..5e0c96d1`. (Source: local shell history on 2026-01-16)

## PR #942
- Ubuntu unit tests: `. spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose` exits with code 139. (Source: `./.github/read-test-failures 942` on 2026-01-16)
- Arch Linux unit tests: `nix-shell -I nixpkgs=channel:nixos-unstable -p bubblewrap shadow attr --run ". spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose"` segfaults and exits 139. (Source: `./.github/read-test-failures 942` on 2026-01-16)

## PR #944
- Ubuntu repro workflow (`banish 0 --only --no-tests --no-heal`) exits with code 139. (Source: `./.github/read-test-failures 944` on 2026-01-16)
- Arch repro workflow (`banish 0 --only --no-tests --no-heal`) exits with code 139. (Source: `./.github/read-test-failures 944` on 2026-01-16)
- NixOS repro workflow segfaults in nix-shell while running `banish 0 --only --no-tests --no-heal` and exits 139. (Source: `./.github/read-test-failures 944` on 2026-01-16)

## PR #945
- Ubuntu repro workflow (`banish 0 --only --no-tests --no-heal`) exits with code 139. (Source: `./.github/read-test-failures 945` on 2026-01-16)

## PR #941
- All tests passing. (Source: `./.github/read-test-failures 941` on 2026-01-16)

## PR #940
- Ubuntu unit tests: `. spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose` exits with code 139. (Source: `./.github/read-test-failures 940` on 2026-01-16)
- Arch Linux unit tests: `nix-shell -I nixpkgs=channel:nixos-unstable -p bubblewrap shadow attr --run ". spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose"` segfaults and exits 139. (Source: `./.github/read-test-failures 940` on 2026-01-16)

## PR #939
- Ubuntu unit tests: `. spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose` exits with code 139. (Source: `./.github/read-test-failures 939` on 2026-01-16)
- Arch Linux unit tests: `nix-shell -I nixpkgs=channel:nixos-unstable -p bubblewrap shadow attr --run ". spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose"` segfaults and exits 139. (Source: `./.github/read-test-failures 939` on 2026-01-16)

## PR #937
- Ubuntu unit tests: no exit 139 in the PR description; failures were standard test failures (no segfaults). (Source: `./.github/read-test-failures 937` on 2026-01-16)
- NixOS unit tests: no exit 139 in the PR description; failures were standard test failures (no segfaults). (Source: `./.github/read-test-failures 937` on 2026-01-16)
- Arch Linux unit tests: no exit 139 in the PR description; failures were standard test failures (no segfaults). (Source: `./.github/read-test-failures 937` on 2026-01-16)

## PR #936
- Ubuntu unit tests: `. spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose` exits with code 139. (Source: `./.github/read-test-failures 936` on 2026-01-16)
- Arch Linux unit tests: `nix-shell -I nixpkgs=channel:nixos-unstable -p bubblewrap shadow attr --run ". spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose"` segfaults and exits 139. (Source: `./.github/read-test-failures 936` on 2026-01-16)

## PR #935
- Ubuntu unit tests: `. spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose` exits with code 139. (Source: `./.github/read-test-failures 935` on 2026-01-16)
- Arch Linux unit tests: `nix-shell -I nixpkgs=channel:nixos-unstable -p bubblewrap shadow attr --run ". spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose"` segfaults and exits 139. (Source: `./.github/read-test-failures 935` on 2026-01-16)

## PR #934
- Ubuntu unit tests: repeated DEBUG banish loop logs followed by exit code 139. (Source: `./.github/read-test-failures 934` on 2026-01-16)
- macOS unit tests: repeated DEBUG banish loop logs followed by exit code 139. (Source: `./.github/read-test-failures 934` on 2026-01-16)
- Nix unit tests: `nix-shell -I nixpkgs=channel:nixos-unstable -p bubblewrap shadow attr --run ". spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose"` segfaults and exits 139. (Source: `./.github/read-test-failures 934` on 2026-01-16)
- PR #934 introduced major gloss/parse changes (centralized `invoke_spell_helper` in generate-glosses, changes to gloss function invocation, parse recursion fixes, and banish level reshuffles). These changes align with the first appearance of exit 139 in CI. (Source: PR #934 API file list on 2026-01-16)

## PR #933
- Ubuntu/Arch/macOS/NixOS unit tests fail with exit code 127 and parse errors (no exit 139). (Source: `./.github/read-test-failures 933` on 2026-01-16)

## PR #932
- Unit tests fail with normal assertion failures (no exit 139 in the PR description). (Source: `./.github/read-test-failures 932` on 2026-01-16)

## Context from lessons learned (treat as a hypothesis, not a conclusion)
- Exit 139 has been observed alongside gloss/parse recursion, but this needs independent confirmation. (Source: `.github/LESSONS.md`)

## Web search notes (general context, not wizardry-specific)
- NixOS forum thread on SIGSEGV/exit 139 when running nix programs: https://discourse.nixos.org/t/segmentation-fault-when-running-any-nix-program-sigsegv-exit-code-139/36659
- Nix issue tracker (general segfault report): https://github.com/NixOS/nix/issues/9640
- General exit 139 explanation reference: https://linuxvox.com/blog/what-error-code-does-a-process-that-segfaults-return/

## PR comment highlights mentioning exit 139
- PR #934 comment notes exit 139 segfaults on Ubuntu/Arch/Nix and speculates about generate-glosses or gloss execution. (Source: https://github.com/andersaamodt/wizardry/pull/934#issuecomment-3736521102)
- PR #936 comment mentions fixing top-level `return` statements thought to cause exit 139 (bitcoin/install-bitcoin, tor/setup-tor). (Source: https://github.com/andersaamodt/wizardry/pull/936#issuecomment-3741623011)
- PR #942 comment reports NixOS still segfaulting after declare blacklist changes. (Source: https://github.com/andersaamodt/wizardry/pull/942#issuecomment-3757416162)
- PR #943 comment notes the declare-only hypothesis was disproven and asks to continue from the 64ths narrowing workflows. (Source: https://github.com/andersaamodt/wizardry/pull/943#issuecomment-3757419625)

## Workflow-log scan tooling
- `.github/scan-exit-139-history.py` attempts to scan the most recent 150 PRs using workflow logs when failure sections are missing, but workflow log downloads require an API token (403 without token). (Source: local run on 2026-01-16; output in `/tmp/exit-139-scan.json`)
