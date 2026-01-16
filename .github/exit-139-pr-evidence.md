# Exit 139 evidence from recent PRs

## First confirmed appearance
- PR #934 shows exit 139 on Ubuntu/macOS/NixOS logs with DEBUG banish output and segfaults; PR #933 shows exit code 127 but no 139. (Source: `./.github/read-test-failures 934` and `./.github/read-test-failures 933` on 2026-01-16)
- Scan of the most recent 150 PR bodies (PRs 795–944) for “exit 139”/“Segmentation fault” finds the first match in PR #934. (Source: GitHub API scan of PR bodies on 2026-01-16)

## PR #942
- Ubuntu unit tests: `. spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose` exits with code 139. (Source: `./.github/read-test-failures 942` on 2026-01-16)
- Arch Linux unit tests: `nix-shell -I nixpkgs=channel:nixos-unstable -p bubblewrap shadow attr --run ". spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose"` segfaults and exits 139. (Source: `./.github/read-test-failures 942` on 2026-01-16)

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
