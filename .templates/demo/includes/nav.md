<nav class="site-nav" style="margin-bottom: 2em; padding: 1em; background: #f5f5f5; border-radius: 5px;">
  <a href="/pages/index.html">Home</a> |
  <a href="/pages/storage.html">Storage</a> |
  <a href="/pages/forms-input.html">Forms</a> |
  <a href="/pages/graphics-media.html">Graphics</a> |
  <a href="/pages/time-performance.html">Time</a> |
  <a href="/pages/workers.html">Workers</a> |
  <a href="/pages/hardware.html">Hardware</a> |
  <a href="/pages/ui-apis.html">UI APIs</a> |
  <a href="/pages/security.html">Security</a> |
  <a href="/pages/file-upload.html">Files</a> |
  <a href="/pages/misc-apis.html">More APIs</a> |
  <a href="/pages/advanced.html">Advanced</a> |
  <a href="/pages/poll.html">Poll</a> |
  <a href="/pages/chat.html">Chat</a> |
  <a href="/pages/about.html">About</a>
</nav>

<script>
// Highlight current page in navigation
(function() {
  const currentPath = window.location.pathname;
  const nav = document.querySelector('.site-nav');
  if (nav) {
    const links = nav.querySelectorAll('a');
    links.forEach(link => {
      if (link.getAttribute('href') === currentPath || 
          currentPath.endsWith(link.getAttribute('href'))) {
        // Replace link with bold text for current page
        const span = document.createElement('span');
        span.textContent = link.textContent;
        span.style.fontWeight = 'bold';
        span.style.color = 'black';
        link.parentNode.replaceChild(span, link);
      }
    });
  }
})();
</script>
