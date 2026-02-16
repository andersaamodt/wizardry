---
title: ""
---
<div class="forge-shell" id="forge-shell">
<aside class="workspace-sidebar" id="workspace-dropzone" tabindex="0">
<div class="workspace-sidebar-head">
<h2>Workspaces</h2>
<div class="workspace-head-actions">
<button id="organize-btn" class="icon-btn" type="button" aria-label="Organize workspaces">&#8801;</button>
<button id="add-workspace-btn" class="icon-btn" type="button" aria-label="Add workspace">+</button>
</div>
</div>
<div id="organize-menu" class="floating-menu hidden" role="menu" aria-label="Organize menu">
<button type="button" data-organize-sort="updated">Sort by Updated</button>
<button type="button" data-organize-sort="name">Sort by Name</button>
</div>
<div id="workspace-tree" class="workspace-tree"></div>
<div class="workspace-sidebar-footer">
<button id="model-status-btn" class="footer-row" type="button" aria-haspopup="dialog" aria-expanded="false">Checking models...</button>
<button id="settings-btn" class="footer-row footer-gear" type="button" aria-label="Settings">&#9881;</button>
</div>
<div class="models-box hidden" id="models-box" role="dialog" aria-label="Available models">
<div class="models-box-head"><span class="models-title">Ollama Models</span><button id="refresh-models-btn" type="button">Refresh</button></div>
<div id="models-box-list" class="models-box-list"></div>
</div>
</aside>

<main class="main-shell">
<header class="toolbar">
<div class="toolbar-left">
<div class="menu-anchor">
<button id="open-menu-btn" class="toolbar-btn" type="button" aria-haspopup="menu" aria-expanded="false">Open</button>
<div id="open-menu" class="floating-menu hidden" role="menu" aria-label="Open in">
<button type="button" data-open-target="finder">Finder</button>
<button type="button" data-open-target="terminal">Terminal</button>
<button type="button" data-open-target="textmate">TextMate</button>
</div>
</div>
<div class="menu-anchor">
<button id="branch-menu-btn" class="toolbar-btn" type="button" aria-haspopup="menu" aria-expanded="false">Branch</button>
<div id="branch-menu" class="floating-menu hidden" role="menu" aria-label="Branch menu">
<div id="branch-menu-list" class="menu-list"></div>
<div class="menu-sep"></div>
<form id="branch-create-form" class="inline-form">
<input id="branch-create-input" placeholder="new-branch" />
<button type="submit">Create</button>
</form>
</div>
</div>
<button id="create-repo-btn" class="toolbar-btn" type="button">Create Repo</button>
<div class="menu-anchor">
<button id="commit-menu-btn" class="toolbar-btn" type="button" aria-haspopup="menu" aria-expanded="false">Commit</button>
<div id="commit-menu" class="floating-menu hidden" role="menu" aria-label="Commit menu">
<button type="button" data-commit-action="commit-modal">Commit...</button>
<button type="button" data-commit-action="push">Push</button>
<button type="button" data-commit-action="commit-push">Commit and push...</button>
</div>
</div>
<button id="run-action-btn" class="toolbar-btn" type="button">Run Action</button>
</div>
<div class="toolbar-right">
<div class="menu-anchor">
<button id="permissions-menu-btn" class="toolbar-btn" type="button" aria-haspopup="menu" aria-expanded="false">Default permissions</button>
<div id="permissions-menu" class="floating-menu hidden" role="menu" aria-label="Permissions menu">
<button type="button" data-permission="default">Default permissions</button>
<button type="button" data-permission="workspace-write">Workspace write</button>
<button type="button" data-permission="read-only">Read only</button>
<button type="button" data-permission="full-access">Full access</button>
<div class="menu-sep"></div>
<div class="perm-toggle-row">
<span>Network access</span>
<button id="network-toggle-btn" class="slide-toggle" type="button" aria-pressed="false" aria-label="Toggle network access"><span class="slide-knob"></span></button>
</div>
<div class="perm-toggle-row">
<span>Web access</span>
<button id="web-toggle-btn" class="slide-toggle" type="button" aria-pressed="false" aria-label="Toggle web access"><span class="slide-knob"></span></button>
</div>
</div>
</div>
<button id="terminal-toggle-btn" class="toolbar-btn" type="button">Terminal</button>
<button id="changes-btn" class="toolbar-btn changes-btn" type="button"><span class="git-delta"><span class="git-add">+0</span> <span class="git-del">-0</span></span></button>
</div>
</header>

<section class="chat-shell">
<div class="chat-head">
<h2 id="chat-title">Conversation</h2>
</div>
<div id="chat-log" class="chat-log"></div>
<form id="run-form" class="run-form">
<textarea id="run-prompt" rows="4" placeholder="Ask Artificer to inspect code, make changes, run checks, and summarize results."></textarea>
<div id="attachment-strip" class="attachment-strip hidden" aria-live="polite"></div>
<div class="composer-row">
<button id="attach-btn" class="attach-btn" type="button" aria-label="Attach files">Attach</button>
<input id="attachment-picker" type="file" multiple hidden />
<div class="menu-anchor model-anchor">
<button id="model-picker-btn" class="model-picker-btn" type="button" aria-haspopup="menu" aria-expanded="false">Select model</button>
<div id="model-picker-menu" class="floating-menu hidden" role="menu" aria-label="Model selector">
<div id="model-picker-list" class="model-picker-list"></div>
</div>
</div>
<div id="queue-controls" class="queue-controls hidden">
<button id="queue-steer-btn" class="queue-btn" type="button">Steer</button>
<button id="queue-cancel-btn" class="queue-btn queue-trash" type="button" aria-label="Delete queued message">&times;</button>
</div>
<button id="run-btn" class="run-fab" type="submit" aria-label="Run agent"><span aria-hidden="true">&uarr;</span></button>
</div>
</form>
</section>
</main>

<aside id="diff-panel" class="diff-panel hidden" aria-label="Git diff panel">
<div class="diff-panel-head">
<h3>Uncommitted changes</h3>
<button id="diff-close-btn" class="icon-btn" type="button" aria-label="Close diff panel">&times;</button>
</div>
<div id="diff-summary" class="diff-summary">No changes.</div>
<div id="diff-view" class="diff-view"></div>
</aside>

<section id="terminal-panel" class="terminal-panel hidden" aria-label="Terminal panel">
<div class="terminal-head">
<div id="terminal-cwd" class="terminal-cwd">Terminal</div>
<div class="terminal-actions">
<button id="terminal-clear-btn" class="ghost-btn" type="button">Clear</button>
<button id="terminal-close-btn" class="ghost-btn" type="button">Close</button>
</div>
</div>
<pre id="terminal-output" class="terminal-output"></pre>
<form id="terminal-form" class="terminal-form">
<input id="terminal-input" autocomplete="off" placeholder="Type a command and press Enter" />
<button type="submit">Run</button>
</form>
</section>
</div>

<div id="workspace-modal" class="modal hidden" role="dialog" aria-modal="true" aria-labelledby="workspace-modal-title">
<div class="modal-card">
<div class="modal-head">
<h3 id="workspace-modal-title">Add Workspace</h3>
<button id="workspace-modal-close" class="icon-btn ghost" type="button" aria-label="Close add workspace form">&times;</button>
</div>
<form id="workspace-form" class="stack">
<label for="workspace-path">Folder path</label>
<div class="browse-row">
<input id="workspace-path" name="workspace-path" placeholder="/absolute/path/to/project" required readonly />
<button id="workspace-browse-btn" type="button">Browse</button>
</div>
<input id="workspace-dir-picker" type="file" webkitdirectory directory hidden />
<label for="workspace-name">Label (optional)</label>
<input id="workspace-name" name="workspace-name" placeholder="my project" />
<div class="modal-actions">
<button id="workspace-add-submit" class="ctx-workspace" type="submit">Add Workspace</button>
<button id="workspace-cancel-btn" class="ghost" type="button">Cancel</button>
</div>
</form>
</div>
</div>

<div id="commit-modal" class="modal hidden" role="dialog" aria-modal="true" aria-labelledby="commit-modal-title">
<div class="modal-card">
<div class="modal-head">
<h3 id="commit-modal-title">Commit your changes</h3>
<button id="commit-modal-close" class="icon-btn ghost" type="button" aria-label="Close commit dialog">&times;</button>
</div>
<div class="stack">
<div class="info-row"><span>Branch</span><strong id="commit-branch-label">-</strong></div>
<div class="info-row"><span>Changes</span><strong id="commit-changes-label"><span class="git-delta"><span class="git-add">+0</span> <span class="git-del">-0</span></span></strong></div>
<label class="toggle-row"><input id="commit-include-unstaged" type="checkbox" checked /> Include unstaged</label>
<label for="commit-message">Commit message</label>
<textarea id="commit-message" rows="3" placeholder="Leave blank to autogenerate a commit message."></textarea>
<label for="commit-next-step">Next step</label>
<select id="commit-next-step">
<option value="commit">Commit</option>
<option value="commit-push">Commit and push</option>
</select>
</div>
<div class="modal-actions">
<button id="commit-continue-btn" type="button">Continue</button>
</div>
</div>
</div>

<div id="run-action-modal" class="modal hidden" role="dialog" aria-modal="true" aria-labelledby="run-action-title">
<div class="modal-card">
<div class="modal-head">
<h3 id="run-action-title">Run Action</h3>
<button id="run-action-close" class="icon-btn ghost" type="button" aria-label="Close run action dialog">&times;</button>
</div>
<form id="run-action-form" class="stack">
<label for="run-action-command">Command to run</label>
<textarea id="run-action-command" rows="4" placeholder="eg: npm install&#10;npm test"></textarea>
<div class="modal-actions">
<button type="submit">Save and run</button>
</div>
</form>
</div>
</div>

<div id="settings-modal" class="modal hidden" role="dialog" aria-modal="true" aria-labelledby="settings-title">
<div class="modal-card">
<div class="modal-head">
<h3 id="settings-title">Settings</h3>
<button id="settings-close-btn" class="icon-btn ghost" type="button" aria-label="Close settings">&times;</button>
</div>
<div class="stack">
<div class="info-row"><span>GitHub CLI</span><strong id="gh-auth-status">Checking...</strong></div>
<div class="info-row"><span>SSH key</span><strong id="ssh-key-status">Checking...</strong></div>
<label for="ssh-email">SSH key email (optional)</label>
<input id="ssh-email" placeholder="you@example.com" />
<div class="modal-actions two-col">
<button id="refresh-auth-btn" type="button">Refresh status</button>
<button id="generate-ssh-btn" type="button">Generate SSH key</button>
</div>
<label for="ssh-pub-output">SSH public key</label>
<textarea id="ssh-pub-output" rows="3" readonly placeholder="No SSH key detected yet."></textarea>
<div class="modal-actions two-col">
<a class="link-btn" href="https://github.com/settings/keys" target="_blank" rel="noopener">GitHub SSH keys</a>
<a class="link-btn" href="https://cli.github.com/manual/gh_auth_login" target="_blank" rel="noopener">GitHub auth docs</a>
</div>
</div>
</div>
</div>

<script src="/static/app.js"></script>
