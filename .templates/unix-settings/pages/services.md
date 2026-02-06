---
title: Services
---

# Services

<p class="lede">Durable system services, enablement, runtime state, and failure signals.</p>

<div class="panel roster" id="services-roster" hx-get="/cgi/unix-roster?domain=services" hx-trigger="load">
  <div class="notice">Loading live services roster…</div>
</div>

<div class="panel">
  <h2>Risk Context <span class="help" title="Destructive controls are marked red and require explicit confirmation.">?</span></h2>
  <p class="muted">Service mutations are explicit and per-action. No ambient changes occur in this interface.</p>
</div>

<div class="action-drawer" id="action-drawer">
  Select a service action to reveal confirmation, command preview, and escape hatches.
</div>
