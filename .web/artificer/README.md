# Artificer Template

Artificer is a local-first coding assistant template for wizardry web.

## What It Includes

- Workspace registry (absolute local folders)
- Per-workspace conversations
- Per-conversation model selection
- Multi-step agent loops (plan -> tool actions -> evaluation -> update)
- Git status and git diff after every run
- Filesystem-backed state (no database)
- Scheduler-backed Mode Runtime (stateful governance modes + telemetry + dashboard composites)
- Skill bundles (typed on-disk directive packs) with policy-gated invocation bus
- Mode-to-mode cooperative governance bus (directives exchanged between modes for emergent coordination)
- Persistent agent memory files:
  - `.plan.md` intent register
  - `.state` typed finite-state stance (`INVESTIGATE -> DESIGN -> IMPLEMENT -> VERIFY -> DONE`)
  - `.failures.md` retry/error ledger
  - `.session.log.md` diff-based run narrative
  - `.contract.md` contract-first design artifact

## Runtime Requirements

- Ollama daemon running on the host
- At least one local model installed in Ollama
- A workspace folder you can read

## Generated Structure

When this template is installed into a site:

- `site/pages/index.md` - main app page
- `site/static/style.css` - app styling
- `site/static/app.js` - frontend app logic
- `cgi/artificer-api` - backend API endpoint

## API

All actions are handled by `/cgi/artificer-api` with `action=`:

- `state` (GET)
- `mode_runtime_state` (GET)
- `mode_runtime_update` (POST)
- `mode_runtime_tick` (POST)
- `mode_runtime_skill_invoke` (POST)
- `mode_runtime_skill_create` (POST)
- `mode_runtime_skill_install` (POST)
- `models` (GET)
- `pick_workspace` (GET, macOS native chooser)
- `add_workspace` (POST)
- `delete_workspace` (POST)
- `new_conversation` (POST)
- `get_conversation` (GET)
- `set_model` (POST)
- `get_draft` (GET)
- `save_draft` (POST)
- `upload_attachment` (POST)
- `queue_enqueue` (POST)
- `queue_take` (POST)
- `queue_finish` (POST)
- `queue_cancel` (POST)
- `queue_steer` (POST)
- `git_status` (GET)
- `git_diff` (GET)
- `git_branches` (GET)
- `git_checkout_branch` (POST)
- `git_init` (POST)
- `git_commit` (POST)
- `git_push` (POST)
- `open_in` (POST)
- `git_auth_status` (GET)
- `git_generate_ssh` (POST)
- `run_action` / `terminal_exec` (POST)
- `run` (POST)

## Notes

- Tool execution is intentionally mediated through a command safety policy.
- Patches go through scratch files and gate checks before promotion to workspace files.
- Every run still returns git diff so you can inspect what changed.
- Mode Runtime stores state in `mode-runtime/` under site data:
  - `modes/<mode-id>/` (governance policy, state, long-horizon memory namespace)
  - `skills/<skill-id>/` bundles with `policy.md`, `trigger.yaml`, `tools.json`, `output.schema.json`
  - `invocation-bus/` skill invocation requests/results (stateless skill execution records)
  - `invocation-bus/directives/` cooperative mode-to-mode governance directives
  - `dashboard/` composite panel substrate and scheduler snapshots
- Run-mode picker includes a `More modes` expander that surfaces all runtime governance modes with blurbs, and selecting one applies `Assistant` run mode with that focus profile.
- Composer now separates `Reasoning depth` from `Compute/time budget`:
  - Reasoning controls planning depth/effort per step.
  - Compute budget controls run/queue time ceilings (`Auto`, `Quick`, `Standard`, `Long`, `Until Complete`), is persisted per queued item, and is enforced backend-side.
- Inline directives:
  - Mode tags: `/chat`, `/task`, `/report`, `/assistant`, etc.
  - Explicit skill tags: use `$skill-name` (or any valid `$skill-id`) anywhere in the prompt to trigger that skill during the run.
- Settings include a Skill Manager for invoke/create/install flows:
  - invoke existing skills under a chosen authorization mode
  - create new skill bundles with typed files
  - install external skill bundles from on-disk directories
- Hard-coded typed transitions:
  - `INVESTIGATE -> DESIGN` when investigation commands succeed
  - `DESIGN -> IMPLEMENT` when a contract exists
  - `IMPLEMENT -> VERIFY` after successful scratch-gate promotion
  - `VERIFY -> IMPLEMENT` on verification failure
  - `VERIFY -> DONE` on verification success
