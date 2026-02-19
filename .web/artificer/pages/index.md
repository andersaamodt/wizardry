---
title: ""
pagetitle: "Artificer"
---
<link id="artificer-theme-stylesheet" rel="stylesheet" href="/static/themes/psionic.css" />
<div class="forge-shell" id="forge-shell">
<aside class="workspace-sidebar" id="workspace-dropzone" tabindex="0">
<div class="workspace-sidebar-head">
<h2>Threads</h2>
<div class="workspace-head-actions">
<button id="add-workspace-btn" class="icon-btn" type="button" aria-label="New project" title="New project"><span aria-hidden="true"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M1.7 5.2h4l1.3 1.6h7.3v6.2H1.7z"/><path d="M11.8 2.8v2.4"/><path d="M10.6 4h2.4"/></svg></span></button>
<button id="organize-btn" class="icon-btn" type="button" aria-label="Organize projects" title="Organize threads"><span aria-hidden="true"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><path d="M2.5 4h11"/><path d="M3.8 8h8.4"/><path d="M5.1 12h5.8"/></svg></span></button>
</div>
</div>
<div id="organize-menu" class="floating-menu organize-menu hidden" role="menu" aria-label="Organize menu">
<p class="organize-title">Organize</p>
<button type="button" data-organize-mode="project"><span>By project</span><span class="check" aria-hidden="true">&check;</span></button>
<button type="button" data-organize-mode="chrono"><span>Chronological list</span><span class="check" aria-hidden="true">&check;</span></button>
<div class="menu-sep"></div>
<p class="organize-group">Sort by</p>
<button type="button" data-organize-sort="created"><span>Created</span><span class="check" aria-hidden="true">&check;</span></button>
<button type="button" data-organize-sort="updated"><span>Updated</span><span class="check" aria-hidden="true">&check;</span></button>
<div class="menu-sep"></div>
<p class="organize-group">Show</p>
<button type="button" data-organize-show="all"><span>All threads</span><span class="check" aria-hidden="true">&check;</span></button>
<button type="button" data-organize-show="relevant"><span>Relevant</span><span class="check" aria-hidden="true">&check;</span></button>
<button type="button" data-organize-show="running"><span>Running</span><span class="check" aria-hidden="true">&check;</span></button>
</div>
<div id="workspace-tree" class="workspace-tree"></div>
<div id="models-pane" class="models-pane hidden">
<div id="models-pane-resizer" class="models-pane-resizer" aria-hidden="true"></div>
<div class="models-box" id="models-box" role="dialog" aria-label="Available models">
<div class="models-box-head"><span class="models-title">Ollama Models</span></div>
<div id="models-box-list" class="models-box-list"></div>
</div>
</div>
<div class="workspace-sidebar-footer">
<button id="settings-btn" class="footer-row footer-gear" type="button" aria-label="Settings" title="Settings">&#9881;</button>
<div class="menu-anchor footer-theme-anchor">
<button id="theme-picker-btn" class="footer-row footer-theme-btn" type="button" aria-haspopup="menu" aria-expanded="false" title="Select theme">Psionic</button>
<div id="theme-picker-menu" class="floating-menu hidden" role="menu" aria-label="Theme selector">
<div id="theme-picker-list" class="menu-list"></div>
</div>
</div>
<button id="model-status-btn" class="footer-row footer-model" type="button" aria-haspopup="dialog" aria-expanded="false" title="Installed Ollama models">Checking models...</button>
</div>
</aside>
<div id="threads-resizer" class="pane-resizer threads-resizer" aria-hidden="true"></div>

<main class="main-shell">
<header class="toolbar">
<div class="toolbar-left">
<h2 id="chat-title" class="toolbar-title">No thread</h2>
<button id="workspace-path-widget" class="path-widget" type="button" title="No project selected" aria-label="Project path"></button>
</div>
<div class="toolbar-right">
<button id="run-action-btn" class="toolbar-btn run-play-btn" type="button" aria-label="Run action" title="Run action">
<span aria-hidden="true">&#9654;</span>
</button>
<div class="menu-anchor split-anchor">
<div class="split-btn">
<button id="open-main-btn" class="toolbar-btn split-main" type="button" title="Open current project"></button>
<button id="open-menu-btn" class="toolbar-btn split-caret" type="button" aria-haspopup="menu" aria-expanded="false" aria-label="Open menu" title="Choose open target"><span aria-hidden="true">&#9662;</span></button>
</div>
<div id="open-menu" class="floating-menu hidden" role="menu" aria-label="Open in">
<button type="button" data-open-target="finder" title="Open in Finder"><span class="menu-icon app-icon finder-icon" aria-hidden="true"></span><span>Finder</span></button>
<button type="button" data-open-target="terminal" title="Open in Terminal"><span class="menu-icon app-icon terminal-app-icon" aria-hidden="true"><svg viewBox="0 0 16 16" fill="none"><rect x="1.2" y="2" width="13.6" height="12" rx="2.2" fill="#181B2A" stroke="#454A66" stroke-width="1"/><path d="M4 6.1l2 1.9L4 9.9" stroke="#D8DEFF" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M7.8 10h4.2" stroke="#D8DEFF" stroke-width="1.2" stroke-linecap="round"/></svg></span><span>Terminal</span></button>
<button type="button" data-open-target="textmate" title="Open in TextMate"><span class="menu-icon app-icon textmate-icon" aria-hidden="true"><svg viewBox="0 0 16 16" fill="none"><circle cx="8" cy="8" r="6.3" fill="#F5ECFF" stroke="#A669D8" stroke-width="1"/><path d="M8 3.2l1.2 2.2 2.3-.8-.9 2.2 2.2 1.2-2.2 1.2.9 2.2-2.3-.8L8 12.8l-1.2-2.2-2.3.8.9-2.2L3.2 8l2.2-1.2-.9-2.2 2.3.8L8 3.2z" fill="#B84FE8"/></svg></span><span>TextMate</span></button>
</div>
</div>
<div class="menu-anchor split-anchor">
<div class="split-btn">
<button id="commit-main-btn" class="toolbar-btn split-main" type="button" title="Primary commit action"></button>
<button id="commit-menu-btn" class="toolbar-btn split-caret" type="button" aria-haspopup="menu" aria-expanded="false" aria-label="Commit menu" title="Choose commit action"><span aria-hidden="true">&#9662;</span></button>
</div>
<div id="commit-menu" class="floating-menu hidden" role="menu" aria-label="Commit actions">
<button type="button" data-commit-action="commit" title="Create commit"><span class="menu-icon" aria-hidden="true">&#10227;</span><span>Commit</span></button>
<button type="button" data-commit-action="push" title="Push current branch"><span class="menu-icon" aria-hidden="true">&#10548;</span><span>Push</span></button>
<button type="button" data-commit-action="commit-push" title="Commit and push"><span class="menu-icon" aria-hidden="true">&#10549;</span><span>Commit and push</span></button>
</div>
</div>
<span class="toolbar-divider commit-terminal-divider" aria-hidden="true"></span>
<button id="terminal-toggle-btn" class="toolbar-btn terminal-icon-btn" type="button" aria-label="Terminal" title="Toggle terminal">
<span aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="15" rx="2"></rect><path d="M8 10l2 2-2 2"></path><path d="M12.5 15h4"></path></svg></span>
</button>
<button id="changes-btn" class="toolbar-btn changes-btn" type="button" title="Open diff panel"><span class="git-delta"><span class="git-add">+0</span> <span class="git-del">-0</span></span></button>
</div>
</header>

<section class="chat-shell">
<div id="command-approval-inline" class="command-approval-inline hidden" role="region" aria-label="Command approval request">
<div class="command-approval-inline-head">
<strong>Command approval required</strong>
<button id="command-approval-inline-close" class="icon-btn ghost" type="button" aria-label="Close command approval">&times;</button>
</div>
<p id="command-approval-inline-text" class="settings-hint">The agent requested a command.</p>
<pre id="command-approval-inline-command" class="terminal-output"></pre>
<label for="command-approval-inline-match-mode">Remember rule type</label>
<select id="command-approval-inline-match-mode">
<option value="exact">Exact command</option>
<option value="regex">Regex pattern</option>
</select>
<label for="command-approval-inline-pattern">Remember pattern</label>
<input id="command-approval-inline-pattern" placeholder="^git([[:space:]].*)?$" />
<div class="modal-actions two-col">
<button id="command-approval-inline-allow-once" type="button">Allow once</button>
<button id="command-approval-inline-deny-once" class="ghost" type="button">Deny once</button>
</div>
<div class="modal-actions two-col">
<button id="command-approval-inline-allow-remember" type="button">Allow + remember</button>
<button id="command-approval-inline-deny-remember" class="ghost" type="button">Deny + remember</button>
</div>
</div>
<div id="decision-request-inline" class="decision-request-inline hidden" role="region" aria-label="Decision request">
<div class="decision-request-head">
<strong>Decision required</strong>
<button id="decision-request-inline-close" class="icon-btn ghost" type="button" aria-label="Hide decision request">&times;</button>
</div>
<p id="decision-request-inline-question" class="decision-request-question"></p>
<form id="decision-request-form" class="decision-request-form">
<div id="decision-request-options" class="decision-request-options"></div>
<div id="decision-request-other-wrap" class="decision-request-other-wrap hidden">
<label for="decision-request-other-input">Other</label>
<input id="decision-request-other-input" placeholder="Type your decision" />
</div>
<div class="modal-actions">
<button id="decision-request-submit" type="submit">Submit decision</button>
</div>
</form>
</div>
<div id="chat-log" class="chat-log"></div>
<button id="chat-jump-bottom-btn" class="chat-jump-bottom hidden" type="button" aria-label="Jump to latest message">
<span aria-hidden="true">&darr;</span>
</button>
<form id="run-form" class="run-form">
<textarea id="run-prompt" rows="4" placeholder="Ask Artificer to inspect code, make changes, run checks, and summarize results."></textarea>
<div id="attachment-strip" class="attachment-strip hidden" aria-live="polite"></div>
<div class="composer-row">
<button id="attach-btn" class="attach-btn" type="button" aria-label="Attach files" title="Attach files">+</button>
<input id="attachment-picker" type="file" multiple hidden />
<div class="menu-anchor model-anchor">
<button id="model-picker-btn" class="model-picker-btn" type="button" aria-haspopup="menu" aria-expanded="false" title="Select model">Select model</button>
<div id="model-picker-menu" class="floating-menu hidden" role="menu" aria-label="Model selector">
<div id="model-picker-list" class="model-picker-list"></div>
</div>
</div>
<div class="menu-anchor composer-reasoning-anchor">
<button id="reasoning-menu-btn" class="reasoning-btn" type="button" aria-haspopup="menu" aria-expanded="false" title="Reasoning effort"><span class="menu-icon reasoning-brain-icon" aria-hidden="true"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round"><path d="M5.1 3.2c-.9 0-1.8.7-1.8 1.8 0 .4.1.8.4 1.1-.7.4-1.1 1-1.1 1.8 0 1.2.9 2.1 2.1 2.1.1 1.1 1 1.9 2.1 1.9 1 0 1.8-.6 2.1-1.5.2.9 1.1 1.5 2.1 1.5 1.1 0 2-.8 2.1-1.9 1.2 0 2.1-.9 2.1-2.1 0-.8-.4-1.4-1.1-1.8.2-.3.4-.7.4-1.1 0-1-.8-1.8-1.8-1.8-.4 0-.8.1-1.1.4-.4-.8-1.2-1.3-2.1-1.3-.9 0-1.7.5-2.1 1.3-.3-.2-.7-.4-1.1-.4z"></path><path d="M6.3 5.8c-.6.2-.9.6-.9 1.1"></path><path d="M8 5.4v4.3"></path><path d="M9.8 5.9c.6.2.9.6.9 1.1"></path><path d="M6.4 8.6c.4.4 1 .6 1.6.6"></path><path d="M9.6 8.6c-.4.4-1 .6-1.6.6"></path></svg></span><span>Medium</span></button>
<div id="reasoning-menu" class="floating-menu hidden" role="menu" aria-label="Reasoning effort">
<p class="menu-title">Select reasoning</p>
<button type="button" data-reasoning="low"><span class="menu-icon reasoning-brain-icon" aria-hidden="true"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round"><path d="M5.1 3.2c-.9 0-1.8.7-1.8 1.8 0 .4.1.8.4 1.1-.7.4-1.1 1-1.1 1.8 0 1.2.9 2.1 2.1 2.1.1 1.1 1 1.9 2.1 1.9 1 0 1.8-.6 2.1-1.5.2.9 1.1 1.5 2.1 1.5 1.1 0 2-.8 2.1-1.9 1.2 0 2.1-.9 2.1-2.1 0-.8-.4-1.4-1.1-1.8.2-.3.4-.7.4-1.1 0-1-.8-1.8-1.8-1.8-.4 0-.8.1-1.1.4-.4-.8-1.2-1.3-2.1-1.3-.9 0-1.7.5-2.1 1.3-.3-.2-.7-.4-1.1-.4z"></path><path d="M6.3 5.8c-.6.2-.9.6-.9 1.1"></path><path d="M8 5.4v4.3"></path><path d="M9.8 5.9c.6.2.9.6.9 1.1"></path><path d="M6.4 8.6c.4.4 1 .6 1.6.6"></path><path d="M9.6 8.6c-.4.4-1 .6-1.6.6"></path></svg></span><span>Low</span><span class="check" aria-hidden="true">&check;</span></button>
<button type="button" data-reasoning="medium"><span class="menu-icon reasoning-brain-icon" aria-hidden="true"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round"><path d="M5.1 3.2c-.9 0-1.8.7-1.8 1.8 0 .4.1.8.4 1.1-.7.4-1.1 1-1.1 1.8 0 1.2.9 2.1 2.1 2.1.1 1.1 1 1.9 2.1 1.9 1 0 1.8-.6 2.1-1.5.2.9 1.1 1.5 2.1 1.5 1.1 0 2-.8 2.1-1.9 1.2 0 2.1-.9 2.1-2.1 0-.8-.4-1.4-1.1-1.8.2-.3.4-.7.4-1.1 0-1-.8-1.8-1.8-1.8-.4 0-.8.1-1.1.4-.4-.8-1.2-1.3-2.1-1.3-.9 0-1.7.5-2.1 1.3-.3-.2-.7-.4-1.1-.4z"></path><path d="M6.3 5.8c-.6.2-.9.6-.9 1.1"></path><path d="M8 5.4v4.3"></path><path d="M9.8 5.9c.6.2.9.6.9 1.1"></path><path d="M6.4 8.6c.4.4 1 .6 1.6.6"></path><path d="M9.6 8.6c-.4.4-1 .6-1.6.6"></path></svg></span><span>Medium</span><span class="check" aria-hidden="true">&check;</span></button>
<button type="button" data-reasoning="high"><span class="menu-icon reasoning-brain-icon" aria-hidden="true"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round"><path d="M5.1 3.2c-.9 0-1.8.7-1.8 1.8 0 .4.1.8.4 1.1-.7.4-1.1 1-1.1 1.8 0 1.2.9 2.1 2.1 2.1.1 1.1 1 1.9 2.1 1.9 1 0 1.8-.6 2.1-1.5.2.9 1.1 1.5 2.1 1.5 1.1 0 2-.8 2.1-1.9 1.2 0 2.1-.9 2.1-2.1 0-.8-.4-1.4-1.1-1.8.2-.3.4-.7.4-1.1 0-1-.8-1.8-1.8-1.8-.4 0-.8.1-1.1.4-.4-.8-1.2-1.3-2.1-1.3-.9 0-1.7.5-2.1 1.3-.3-.2-.7-.4-1.1-.4z"></path><path d="M6.3 5.8c-.6.2-.9.6-.9 1.1"></path><path d="M8 5.4v4.3"></path><path d="M9.8 5.9c.6.2.9.6.9 1.1"></path><path d="M6.4 8.6c.4.4 1 .6 1.6.6"></path><path d="M9.6 8.6c-.4.4-1 .6-1.6.6"></path></svg></span><span>High</span><span class="check" aria-hidden="true">&check;</span></button>
<button type="button" data-reasoning="extra-high"><span class="menu-icon reasoning-brain-icon" aria-hidden="true"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round"><path d="M5.1 3.2c-.9 0-1.8.7-1.8 1.8 0 .4.1.8.4 1.1-.7.4-1.1 1-1.1 1.8 0 1.2.9 2.1 2.1 2.1.1 1.1 1 1.9 2.1 1.9 1 0 1.8-.6 2.1-1.5.2.9 1.1 1.5 2.1 1.5 1.1 0 2-.8 2.1-1.9 1.2 0 2.1-.9 2.1-2.1 0-.8-.4-1.4-1.1-1.8.2-.3.4-.7.4-1.1 0-1-.8-1.8-1.8-1.8-.4 0-.8.1-1.1.4-.4-.8-1.2-1.3-2.1-1.3-.9 0-1.7.5-2.1 1.3-.3-.2-.7-.4-1.1-.4z"></path><path d="M6.3 5.8c-.6.2-.9.6-.9 1.1"></path><path d="M8 5.4v4.3"></path><path d="M9.8 5.9c.6.2.9.6.9 1.1"></path><path d="M6.4 8.6c.4.4 1 .6 1.6.6"></path><path d="M9.6 8.6c-.4.4-1 .6-1.6.6"></path></svg></span><span>Extra High</span><span class="check" aria-hidden="true">&check;</span></button>
</div>
</div>
<button id="agent-loop-toggle" class="loop-toggle on" type="button" aria-pressed="true" title="Advanced agentive loop">
<span class="loop-label">Loop</span>
<span class="loop-track" aria-hidden="true"><span class="loop-knob"></span></span>
</button>
<div id="queue-controls" class="queue-controls hidden">
<button id="queue-steer-btn" class="queue-btn" type="button">Steer</button>
<button id="queue-cancel-btn" class="queue-btn queue-trash" type="button" aria-label="Delete queued message">&times;</button>
</div>
<button id="run-btn" class="run-fab" type="submit" aria-label="Run agent" title="Send message"><span aria-hidden="true">&uarr;</span></button>
</div>
<div class="session-row">
<div class="menu-anchor">
<button id="permissions-menu-btn" class="toolbar-btn compact-btn" type="button" aria-haspopup="menu" aria-expanded="false" title="Default permissions"><span class="menu-icon mono-icon" aria-hidden="true"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><path d="M8 1.6l4.6 1.8v3.7c0 3-1.7 5.4-4.6 7.2-2.9-1.8-4.6-4.2-4.6-7.2V3.4L8 1.6z"/></svg></span><span>Default permissions</span></button>
<div id="permissions-menu" class="floating-menu hidden" role="menu" aria-label="Permissions menu">
<button type="button" data-permission="default"><span class="menu-icon mono-icon" aria-hidden="true"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><path d="M8 1.6l4.6 1.8v3.7c0 3-1.7 5.4-4.6 7.2-2.9-1.8-4.6-4.2-4.6-7.2V3.4L8 1.6z"/></svg></span><span>Default permissions</span></button>
<button type="button" data-permission="workspace-write"><span class="menu-icon mono-icon" aria-hidden="true"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><path d="M3.1 12.9l2.9-.6 6-6-2.3-2.3-6 6z"/><path d="M8.9 3.7l2.3 2.3"/></svg></span><span>Project write</span></button>
<button type="button" data-permission="read-only"><span class="menu-icon mono-icon" aria-hidden="true"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><path d="M1.8 8s2.3-3.6 6.2-3.6S14.2 8 14.2 8s-2.3 3.6-6.2 3.6S1.8 8 1.8 8z"/><circle cx="8" cy="8" r="1.7"/></svg></span><span>Read only</span></button>
<button type="button" data-permission="full-access"><span class="menu-icon mono-icon" aria-hidden="true"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><circle cx="8" cy="8" r="1.6"/><path d="M8 2.3v1.3"/><path d="M8 12.4v1.3"/><path d="M2.3 8h1.3"/><path d="M12.4 8h1.3"/><path d="M3.9 3.9l.9.9"/><path d="M11.2 11.2l.9.9"/><path d="M12.1 3.9l-.9.9"/><path d="M4.8 11.2l-.9.9"/></svg></span><span>Full access</span></button>
<div class="menu-sep"></div>
<p class="menu-title">Command execution</p>
<div class="command-exec-control" role="group" aria-label="Command execution mode">
<button type="button" data-command-exec="none">None</button>
<button type="button" data-command-exec="ask">Ask me</button>
<button type="button" data-command-exec="all">All</button>
</div>
<div class="menu-sep"></div>
<div class="perm-toggle-row">
<button id="network-toggle-btn" class="perm-access-toggle" type="button" aria-pressed="false" aria-label="Toggle network access" title="Toggle network access">
<span class="perm-toggle-text">Network access</span>
<span class="loop-track" aria-hidden="true"><span class="loop-knob"></span></span>
</button>
</div>
<div class="perm-toggle-row">
<button id="web-toggle-btn" class="perm-access-toggle" type="button" aria-pressed="false" aria-label="Toggle web access" title="Toggle web access">
<span class="perm-toggle-text">Web access</span>
<span class="loop-track" aria-hidden="true"><span class="loop-knob"></span></span>
</button>
</div>
</div>

<div id="command-approval-modal" class="modal hidden" role="dialog" aria-modal="true" aria-labelledby="command-approval-title">
<div class="modal-card">
<div class="modal-head">
<h3 id="command-approval-title">Command approval required</h3>
<button id="command-approval-close" class="icon-btn ghost" type="button" aria-label="Close command approval">&times;</button>
</div>
<div class="stack">
<p id="command-approval-text" class="settings-hint">The agent requested a command.</p>
<pre id="command-approval-command" class="terminal-output"></pre>
<label for="command-approval-match-mode">Remember rule type</label>
<select id="command-approval-match-mode">
<option value="exact">Exact command</option>
<option value="regex">Regex pattern</option>
</select>
<label for="command-approval-pattern">Remember pattern</label>
<input id="command-approval-pattern" placeholder="^git([[:space:]].*)?$" />
</div>
<div class="modal-actions two-col">
<button id="command-approval-allow-once" type="button">Allow once</button>
<button id="command-approval-deny-once" class="ghost" type="button">Deny once</button>
</div>
<div class="modal-actions two-col">
<button id="command-approval-allow-remember" type="button">Allow + remember</button>
<button id="command-approval-deny-remember" class="ghost" type="button">Deny + remember</button>
</div>
</div>
</div>
</div>
<div class="menu-anchor branch-anchor">
<button id="branch-menu-btn" class="toolbar-btn compact-btn" type="button" aria-haspopup="menu" aria-expanded="false" title="Git branch and repository">No repo</button>
<div id="branch-menu" class="floating-menu hidden" role="menu" aria-label="Branch menu">
<div id="branch-menu-list" class="menu-list"></div>
<div class="menu-sep"></div>
<form id="branch-create-form" class="inline-form">
<input id="branch-create-input" placeholder="new-branch" />
<button id="branch-create-submit" type="submit" disabled>Create</button>
</form>
</div>
</div>
<div class="context-anchor">
<span id="context-window-btn" class="context-window-indicator" aria-label="Context window" title="Context window information will display here.">
<svg viewBox="0 0 16 16" aria-hidden="true"><circle cx="8" cy="8" r="5.4"></circle></svg>
</span>
</div>
</div>
</form>
</section>
</main>

<aside id="diff-panel" class="diff-panel hidden" aria-label="Git diff panel">
<div id="diff-resizer" class="pane-resizer diff-resizer" aria-hidden="true"></div>
<div class="diff-panel-head">
<h3>Uncommitted changes</h3>
<button id="diff-close-btn" class="icon-btn" type="button" aria-label="Close diff panel">&times;</button>
</div>
<div id="diff-summary" class="diff-summary">No changes.</div>
<div id="diff-view" class="diff-view"></div>
</aside>

<section id="terminal-panel" class="terminal-panel hidden" aria-label="Terminal panel">
<pre id="terminal-output" class="terminal-output" tabindex="0" aria-label="Terminal output"></pre>
</section>
</div>

<div id="workspace-modal" class="modal hidden" role="dialog" aria-modal="true" aria-labelledby="workspace-modal-title">
<div class="modal-card">
<div class="modal-head">
<h3 id="workspace-modal-title">Add Project</h3>
<button id="workspace-modal-close" class="icon-btn ghost" type="button" aria-label="Close add project form">&times;</button>
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
<button id="workspace-add-submit" class="ctx-workspace" type="submit">Add Project</button>
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
<label for="github-username">GitHub username (optional)</label>
<input id="github-username" placeholder="your-github-username" />
<label for="ssh-email">SSH key email/comment (optional)</label>
<input id="ssh-email" placeholder="you@example.com" />
<div class="modal-actions two-col">
<button id="refresh-auth-btn" type="button">Refresh status</button>
<button id="generate-ssh-btn" type="button">Generate SSH key</button>
</div>
<div class="modal-actions two-col">
<button id="choose-ssh-btn" type="button">Choose existing SSH key</button>
<button id="clear-ssh-btn" class="ghost" type="button">Use auto-detected key</button>
</div>
<label for="selected-ssh-path">Selected SSH key</label>
<input id="selected-ssh-path" readonly placeholder="Using auto-detected SSH key." />
<label for="ssh-pub-output">SSH public key</label>
<textarea id="ssh-pub-output" rows="3" readonly placeholder="No SSH key detected yet."></textarea>
<p class="settings-hint">Git over SSH uses your key. GitHub username/email is optional metadata.</p>
<p class="settings-links"><a href="https://github.com/settings/keys" target="_blank" rel="noopener">GitHub SSH keys</a> <span aria-hidden="true">&middot;</span> <a href="https://cli.github.com/manual/gh_auth_login" target="_blank" rel="noopener">GitHub auth docs</a></p>
</div>
</div>
</div>

<script src="/static/artificer-app.js?v=20260219-approvalux04"></script>
