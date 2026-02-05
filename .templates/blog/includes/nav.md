<nav class="site-nav">
<div class="nav-center">
<a href="/pages/index.html">Home</a>
<a href="/pages/about.html">About</a>
<a href="/pages/tags.html">Tags</a>
</div>
<div class="nav-right">
<a href="/pages/admin.html" class="nav-admin" style="display: none;">Admin</a>
<a href="/pages/ssh-auth.html" class="btn-login">Login</a>
</div>
</nav>

<script>
// Show Admin link only when logged in
(function() {
  // Check if user is logged in (you can replace this with actual auth check)
  // For now, checking for a session cookie or localStorage
  const isLoggedIn = localStorage.getItem('wizardry_auth_token') || 
                     document.cookie.includes('session=');
  
  if (isLoggedIn) {
    const adminLink = document.querySelector('.nav-admin');
    if (adminLink) {
      adminLink.style.display = 'inline-block';
    }
  }
})();
</script>
