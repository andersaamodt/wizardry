---
title: UNIX Settings
---

# UNIX Settings

<p class="lede">UNIX Settings is a live, constitutional interface to system authority. Every fact is pulled from the host at render time. Every action is explicit, per-action, and fully revealed.</p>

<div class="panel">
  <h3>Authority & Identity</h3>
  <ul>
    <li>Default execution identity is the site user. Privileged actions require SSH-linked admin authentication.</li>
    <li>Privilege escalation is per-action and never session-wide.</li>
    <li>No sudo passwords are requested or accepted in the web interface.</li>
  </ul>
  <p class="notice">Controls are write-capable, but mutations are never implicit or optimistic. If an action would lie, it is disabled with an explanation.</p>
</div>

<div class="panel">
  <h3>Domains</h3>
  <div class="domain-grid">
    <a class="domain-card" href="/pages/users.html">
      <strong>Users</strong>
      <span>Human identity, groups, login capability, privilege state.</span>
    </a>
    <a class="domain-card" href="/pages/services.html">
      <strong>Services</strong>
      <span>Durable daemons, enablement, runtime state, failure signals.</span>
    </a>
    <a class="domain-card" href="/pages/network.html">
      <strong>Network</strong>
      <span>Interfaces, addresses, listeners, reachability, firewall posture.</span>
    </a>
    <a class="domain-card" href="/pages/storage.html">
      <strong>Storage</strong>
      <span>Mounted filesystems, usage, persistence, coarse health.</span>
    </a>
    <a class="domain-card" href="/pages/system.html">
      <strong>System</strong>
      <span>OS identity, load, pressure, time state, critical logs.</span>
    </a>
    <a class="domain-card" href="/pages/software.html">
      <strong>Software</strong>
      <span>Installed packages, updates, rollback capability.</span>
    </a>
    <a class="domain-card" href="/pages/configuration.html">
      <strong>Configuration</strong>
      <span>Canonical config sources and authority boundaries.</span>
    </a>
  </div>
</div>

<div class="panel roster" id="system-summary" hx-get="/cgi/unix-roster?domain=system-summary" hx-trigger="load">
  <div class="notice">Loading live system summary…</div>
</div>

<div class="panel">
  <h3>Principles</h3>
  <ul>
    <li>System state is always live, never cached as authority.</li>
    <li>Failures are surfaced with concise explanations and raw output.</li>
    <li>Escape hatches reveal the underlying command, file, and man page.</li>
  </ul>
</div>
