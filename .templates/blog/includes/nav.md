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
<a href="/pages/ssh-auth.html" class="btn-register">Register</a>
<button class="btn-login" id="login-btn">Login</button>
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

  // Login button functionality
  const loginBtn = document.getElementById('login-btn');
  const registerBtn = document.querySelector('.btn-register');
  const navRight = document.querySelector('.nav-right');
  
  if (loginBtn) {
    loginBtn.addEventListener('click', async function(e) {
      e.preventDefault();
      
      // Check if WebAuthn is available
      if (!window.PublicKeyCredential) {
        console.log('WebAuthn not supported, showing register option');
        showRegisterOption();
        return;
      }
      
      try {
        // Get available credentials (this will prompt the authenticator)
        const credential = await navigator.credentials.get({
          publicKey: {
            challenge: new Uint8Array(32), // Server should provide this
            timeout: 60000,
            userVerification: "preferred"
          }
        });
        
        // If we got a credential, send it to the server for verification
        if (credential) {
          console.log('Credential obtained, verifying with server...');
          
          // Convert ArrayBuffer to Base64
          function arrayBufferToBase64(buffer) {
            const bytes = new Uint8Array(buffer);
            let binary = '';
            for (let i = 0; i < bytes.byteLength; i++) {
              binary += String.fromCharCode(bytes[i]);
            }
            return window.btoa(binary);
          }
          
          // Send to server for verification
          const response = await fetch('/cgi/blog-auth-verify', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              id: credential.id,
              rawId: arrayBufferToBase64(credential.rawId),
              response: {
                authenticatorData: arrayBufferToBase64(credential.response.authenticatorData),
                clientDataJSON: arrayBufferToBase64(credential.response.clientDataJSON),
                signature: arrayBufferToBase64(credential.response.signature),
                userHandle: credential.response.userHandle ? arrayBufferToBase64(credential.response.userHandle) : null
              },
              type: credential.type
            })
          });
          
          if (response.ok) {
            console.log('Authentication successful!');
            const data = await response.json();
            // Check if user is admin
            if (data && data.isAdmin) {
              showAdminOption();
            } else {
              // Regular user, just reload
              window.location.reload();
            }
          } else {
            console.error('Authentication failed');
            showRegisterOption();
          }
        }
        
      } catch (error) {
        console.error('Authentication error:', error);
        // User likely doesn't have credentials registered, show register option
        showRegisterOption();
      }
    });
  }
  
  function showRegisterOption() {
    // Don't slide anything, just show the register button
    // The register button will appear next to Login without moving search
    
    // Show the register link with animation
    setTimeout(() => {
      if (registerBtn) {
        registerBtn.classList.add('show');
      }
    }, 100);
  }
  
  function showAdminOption() {
    // Only slide when we need to make room for Admin link
    // Slide the search (and admin if visible) to the left
    navRight.classList.add('slide-left');
    
    // Show admin link with animation, then reload
    const adminLink = document.querySelector('.nav-admin');
    setTimeout(() => {
      if (adminLink) {
        adminLink.style.display = 'inline';
      }
      setTimeout(() => {
        window.location.reload();
      }, 300);
    }, 100);
  }

  const themeStorageKey = 'wizardry_blog_theme';
  const defaultTheme = 'archmage';

  function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
  }

  const savedTheme = localStorage.getItem(themeStorageKey) || defaultTheme;
  if (!localStorage.getItem(themeStorageKey)) {
    localStorage.setItem(themeStorageKey, savedTheme);
  }
  applyTheme(savedTheme);

  document.addEventListener('DOMContentLoaded', () => {
    const themeSelect = document.getElementById('theme-select');
    if (!themeSelect) {
      return;
    }

    themeSelect.value = savedTheme;
    themeSelect.addEventListener('change', (event) => {
      const nextTheme = event.target.value;
      localStorage.setItem(themeStorageKey, nextTheme);
      applyTheme(nextTheme);
    });
  });
})();
</script>
