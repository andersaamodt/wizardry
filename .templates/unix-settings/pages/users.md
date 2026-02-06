---
title: Users
---

# Users

<p class="lede">Human identity, groups, login capability, and privilege state. Roster entries are derived directly from the host OS.</p>

<div class="panel roster" id="users-roster" hx-get="/cgi/unix-roster?domain=users" hx-trigger="load">
  <div class="notice">Loading live user roster…</div>
</div>

<div class="panel">
  <h2>Identity Controls <span class="help" title="Identity is surfaced only when it materially affects the action.">?</span></h2>
  <p class="muted">Execution identity is managed by the system. Selection appears only when multiple identities materially differ.</p>
</div>

<div class="action-drawer" id="action-drawer">
  Select a user action to reveal confirmation, command preview, and escape hatches.
</div>
