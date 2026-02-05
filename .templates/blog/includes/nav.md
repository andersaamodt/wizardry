<nav class="site-nav">
<div class="nav-center">
<a href="/pages/index.html" data-page="index">Home</a>
<a href="/pages/about.html" data-page="about">About</a>
<a href="/pages/tags.html" data-page="tags">Tags</a>
</div>
<div class="nav-right">
<form class="nav-search" method="get" action="/cgi/blog-search">
<input type="text" name="q" placeholder="Search..." />
<button type="submit" aria-label="Search">
<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="7" cy="7" r="5.5" stroke="currentColor" stroke-width="1.5"/>
<path d="M11 11L14.5 14.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
</svg>
</button>
</form>
<a href="/pages/admin.html" class="nav-admin" style="display: none;">Admin</a>
<a href="/pages/ssh-auth.html" class="btn-login">Login</a>
</div>
</nav>

<script>
// Show Admin link only when logged in
(function() {
  const isLoggedIn = localStorage.getItem('wizardry_auth_token') || 
                     document.cookie.includes('session=');
  
  if (isLoggedIn) {
    const adminLink = document.querySelector('.nav-admin');
    if (adminLink) {
      adminLink.style.display = 'inline-block';
    }
  }

  // Highlight current page in nav
  const currentPath = window.location.pathname;
  const navLinks = document.querySelectorAll('.nav-center a[data-page]');
  
  navLinks.forEach(link => {
    const href = link.getAttribute('href');
    if (currentPath.includes(href) || 
        (currentPath === '/' && href.includes('index.html')) ||
        (currentPath.endsWith('/') && href.includes('index.html'))) {
      link.classList.add('active');
    }
  });
})();
</script>
