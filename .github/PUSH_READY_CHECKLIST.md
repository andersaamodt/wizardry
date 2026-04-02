# Push-Ready Checklist

## Principle
- Keep every repo continuously push-ready; cleanup is not a last-minute release task.
- Commit source, fixtures, and deliberate documentation; keep operator-local state and transient output elsewhere.
- Prefer preventing repo pollution over cleaning it up afterward.

## What Belongs In A Repo
- Source code, stable fixtures, canonical assets, reproducible build configuration, and public documentation.
- Checked-in generated files only when they are intentionally canonical, reproducible, and documented as such.

## What Does Not Belong In A Repo
- Runtime state, logs, assay/test reports, transcripts, screenshots, scratch notes, downloaded model data, compiled executables, packaged release bundles, and local cache.
- Private paths, usernames, tokens, secrets, internal-only checklists, or ad hoc investigation output unless intentionally published.

## Storage Rules
- Put durable operator state under XDG/user-local state directories, not inside the checkout.
- Put transient test and assay output under temp/state directories, not inside the checkout.
- Keep compiled artifacts and release packages ignored locally and published via CI artifacts/releases.
- If a path must exist near the repo for tooling reasons, ignore it and document why it cannot live elsewhere.

## Before Adding A New File Or Path
- Decide whether it is source, fixture, generated artifact, runtime state, or private/operator-local material.
- If it is not source/fixture/public docs, default it out of the repo.
- Document every new durable storage location in the relevant README or AI-facing docs.
- Add `.gitignore` coverage for generated paths that remain adjacent to the repo.

## Checklist Before Push Or Publish
- Worktree is clean or every remaining change is intentional and understood.
- No repo-local logs, assay output, run transcripts, screenshots, or scratch/debug files remain.
- No compiled executables, release bundles, or downloaded dependencies are tracked.
- No personal paths, usernames, secrets, or private notes leaked into tracked files.
- Fixtures are stable and intentional, not copied run output.
- Secondary/generated assets are either reproducible and intentionally committed or ignored and rebuilt.
- Tests and tooling write their output outside the repo, or into ignored paths with a documented reason.
- Human-facing and AI-facing docs point to the real storage/runtime paths, not stale local paths.
