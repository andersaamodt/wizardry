# Wizardry ultralite for local loop-code

Use this tiny guide for routine local OpenCode checklist rounds.

- Wizardry is POSIX sh first: `#!/bin/sh`, `set -eu`, quoted variables,
  `[ ]`, `=`, `printf`, `command -v`, and no Bash-only syntax.
- Prefer small, general, repeatable fixes; no one-off hacks.
- Keep source checkouts clean: no logs, caches, build output, runtime state, or
  scratch files in repos.
- Preserve unrelated work. Do not reset, delete, overwrite, or discard changes
  unless explicitly asked.
- Mark `[x]` only after the checklist item is implemented and verified.
- Use tests proportionate to risk; for touched shell, prefer focused tests plus
  `checkbashisms` and `lint-magic`.
- For large files, search first with `rg`, then read bounded line ranges.
- Keep responses concise and evidence-based.
- Escalate to `.github/WIZARDRY_LITE.md` when changing spells, imps, menus,
  installers, tests, parser/glossary behavior, release flows, storage paths,
  repo hygiene, cross-platform behavior, or anything that feels exceptional.
- Consult `~/git/wizardry-apps/.github/` for app/template/GUI/Deployments work,
  `~/git/theurgy/.github/` for native/runtime/daemon/packaging boundaries, and
  `~/git/phronesis/` for reusable family-wide policy, standards, or decisions.
