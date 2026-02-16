# Artificer Template

Artificer is a local-first coding assistant template for wizardry web.

## What It Includes

- Workspace registry (absolute local folders)
- Per-workspace conversations
- Per-conversation model selection
- Multi-step agent loops (plan -> tool actions -> evaluation -> update)
- Git status and git diff after every run
- Filesystem-backed state (no database)
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
- Hard-coded typed transitions:
  - `INVESTIGATE -> DESIGN` when investigation commands succeed
  - `DESIGN -> IMPLEMENT` when a contract exists
  - `IMPLEMENT -> VERIFY` after successful scratch-gate promotion
  - `VERIFY -> IMPLEMENT` on verification failure
  - `VERIFY -> DONE` on verification success
