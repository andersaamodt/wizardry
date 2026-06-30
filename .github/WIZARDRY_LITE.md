# Wizardry lite for local coding models

Use this compact guide when a local LLM needs wizardry context without reading
the full `.github/` library every round.

## Default stance

- Wizardry is POSIX shell first: use `#!/bin/sh`, `set -eu`, `[ ]`, `=`,
  `printf`, `command -v`, quoted variables, and no Bash-only syntax.
- Keep spells transparent, file-first, menu-discoverable, and novice-readable.
- Prefer small, general, repeatable fixes over one-off patches or clever hacks.
- Treat checklist files as work contracts: mark `[x]` only after the item is
  actually implemented and verified.
- Keep runtime state, logs, caches, build output, and scratch files out of repo
  checkouts; use temp or XDG/user-local state paths.
- Preserve unrelated work. Do not overwrite, delete, reset, or discard changes
  unless the user explicitly asked for that.
- Use the normal wizardry vocabulary and structure where it clarifies behavior:
  spells in `spells/`, imps under `spells/.imps/`, mirrored tests under
  `.tests/`, arcana for first-class install/configure flows.
- Do not use Homebrew for wizardry-family installs. Make project dependencies
  first-class wizardry installables when they belong to the project.

## Coding rules that matter most

- Spells need a concise `--help`/usage block; that usage is part of the spec.
- Tests mirror the spell or imp path; meaningful behavior changes need tests.
- Run actual verification before claiming success. Prefer focused tests plus
  `checkbashisms` and `lint-magic` for touched shell scripts.
- Error messages should describe what happened, not bark instructions.
- Avoid new functions in simple spells/imps; keep orchestration flat or extract
  reusable behavior into imps when it is genuinely shared.
- Do not add Python, Rust, generated binaries, dependency caches, or app state
  to wizardry unless the user or existing project architecture authorizes it.

## Escalate to full docs when

- You are creating or changing a spell, imp, installer, menu, parser, glossary,
  test harness, release path, desktop/app bridge, or cross-platform behavior.
- You are unsure about POSIX portability, shell quoting, temp/state storage,
  generated files, git/publish readiness, or whether a dependency belongs in
  wizardry.
- A bug touches security, filesystem boundaries, user data, destructive actions,
  package installation, network/device access, or GUI/runtime state.
- A test fails in a surprising way, a fix feels like an exception, or the code
  contradicts this lite guide.
- You need exact templates, policy language, or canonical detail.

Read, as needed:

- `.github/CODEX.md` for project instructions and required commands.
- `.github/FULL_SPEC.md` for canonical technical rules.
- `.github/SHELL_CODE_PATTERNS.md` for POSIX shell patterns.
- `.github/PUSH_READY_CHECKLIST.md` for repo hygiene and storage boundaries.
- `.github/tests.md` and `.github/adversarial-testing.md` for testing rules.
- `.github/LESSONS.md` for known bug classes and debugging lessons.

## Neighboring wizardry-family docs

- Consult `~/git/wizardry-apps/.github/` when work touches generated apps,
  desktop/web/mobile app templates, GUI standards, hosted-site behavior,
  App Forge, native adapter expectations, Deployments-managed website source,
  or app runtime/state placement.
- Consult `~/git/theurgy/.github/` when shell orchestration should cross into
  compiled/native runtime machinery: app packaging, host bridges, native
  desktop/mobile execution, long-running daemons, platform-specific installers,
  or performance-sensitive runtime cores.
- Consult `~/git/phronesis/` when a finding should become reusable policy,
  audit method, exception schema, decision record, cross-repo standard,
  semantic/semanthesis guidance, or a durable family-wide lesson.
