---
title: Display & Sessions
---

# Display & Sessions

<p class="lede">Observational display stack view. Identifies the active graphics protocol, session owner, compositor, desktop environment, GPUs, drivers, and outputs without asserting configurability.</p>

<div class="panel roster" id="display-roster" hx-get="/cgi/unix-roster?domain=display-sessions" hx-trigger="load">
  <div class="notice">Loading live display/session probe…</div>
</div>

<div class="panel">
  <h2>Authority Notes <span class="help" title="When control would be dishonest, it is explicitly marked unavailable.">?</span></h2>
  <p class="muted">All display data includes a source-of-authority note (login manager, compositor, DE config, declarative system, or vendor default).</p>
</div>

<div class="action-drawer" id="action-drawer">
  Display stack controls are observational by default. Any future actions must be explicit, per-action, and fully revealed.
</div>
