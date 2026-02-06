<nav class="site-nav">
  <div class="nav-brand">
    <strong>UNIX Settings</strong>
    <span>Live constitutional interface</span>
  </div>
  <div class="nav-links">
    <a href="/pages/index.html">Overview</a>
    <a href="/pages/users.html">Users</a>
    <a href="/pages/services.html">Services</a>
    <a href="/pages/network.html">Network</a>
    <a href="/pages/storage.html">Storage</a>
    <a href="/pages/system.html">System</a>
    <a href="/pages/software.html">Software</a>
    <a href="/pages/configuration.html">Configuration</a>
  </div>
</nav>

<script>
(function() {
  const currentPath = window.location.pathname;
  const nav = document.querySelector('.nav-links');
  if (!nav) return;
  nav.querySelectorAll('a').forEach(link => {
    const href = link.getAttribute('href');
    if (currentPath === href || currentPath.endsWith(href)) {
      link.classList.add('active');
    }
  });
})();
</script>
