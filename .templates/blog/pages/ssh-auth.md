---
title: SSH + WebAuthn Authentication Demo
---

# SSH + WebAuthn Authentication

This system integrates with the MUD player system to provide passwordless authentication for the blog using your existing SSH keys.

## How It Works

1. **MUD Player Account**: Your MUD player account (created with `add-player` on the server) has an SSH public key
2. **Registration**: The blog uses your MUD player SSH key fingerprint as your root identity
3. **WebAuthn Binding**: You create WebAuthn credentials bound to your SSH fingerprint
4. **Authentication**: Login uses only WebAuthn (no SSH key needed for routine login)
5. **Admin Access**: Users in the `blog-admin` UNIX group get admin permissions

## Benefits

- **Unified Identity**: Your MUD player account works for website login
- **Phishing-Resistant**: WebAuthn credentials can't be phished
- **UNIX Permissions**: Admin access controlled via UNIX groups (`blog-admin`)
- **Revocable Delegates**: WebAuthn credentials can be revoked without changing SSH identity
- **Multi-Device**: Multiple WebAuthn credentials per SSH identity

## MUD Integration

If you have a MUD player account on this server, you can use it to login! Just enter your player name below, and the system will automatically use your SSH key from your MUD account.

**For server admins:** To give a user admin access to the blog, add them to the `blog-admin` group:
```sh
sudo usermod -aG blog-admin <username>
```

<div class="demo-box">
<h2>🔐 Step 1: Register with MUD Player Account</h2>

<p><strong>Option A: If you have a MUD player account on this server</strong></p>
<p style="font-size: 0.9rem; color: #666; margin-bottom: 1rem;">Just enter your player name - the system will automatically use your SSH key!</p>

<div style="margin-bottom: 1rem;">
<label style="display: block; margin-bottom: 0.5rem;"><strong>MUD Player Name:</strong></label>
<input type="text" id="reg-username-mud" placeholder="Enter your player name" style="width: 100%; padding: 0.75rem; border: 2px solid #ddd; border-radius: 4px; font-size: 1rem; margin-bottom: 0.5rem;">
</div>

<button id="btn-register-mud" style="padding: 0.75rem 1.5rem; font-size: 1rem; background: #27ae60; color: white; border: none; border-radius: 4px; cursor: pointer;">🎮 Register with MUD Account</button>

<div id="output-register-mud" class="output"></div>

<hr style="margin: 2rem 0; border: none; border-top: 1px solid #ddd;">

<p><strong>Option B: Manual SSH key registration (for testing/demo)</strong></p>

<div style="margin-bottom: 1rem;">
<label style="display: block; margin-bottom: 0.5rem;"><strong>Username:</strong></label>
<input type="text" id="reg-username" placeholder="Enter username" style="width: 100%; padding: 0.75rem; border: 2px solid #ddd; border-radius: 4px; font-size: 1rem; margin-bottom: 0.5rem;" value="demo-user">
</div>

<div style="margin-bottom: 1rem;">
<label style="display: block; margin-bottom: 0.5rem;"><strong>SSH Public Key:</strong></label>
<textarea id="reg-ssh-key" placeholder="Paste your SSH public key (e.g., ssh-ed25519 AAAA...)" rows="3" style="width: 100%; padding: 0.75rem; border: 2px solid #ddd; border-radius: 4px; font-size: 0.9rem; font-family: monospace; margin-bottom: 0.5rem;"></textarea>
<p style="font-size: 0.85rem; color: #666; margin: 0;">💡 Get your SSH public key with: <code>cat ~/.ssh/id_ed25519.pub</code></p>
</div>

<button id="btn-register-ssh" style="padding: 0.75rem 1.5rem; font-size: 1rem;">🔑 Register SSH Key</button>

<div id="output-register-ssh" class="output"></div>
</div>

<div class="demo-box">
<h2>🔐 Step 2: Bind WebAuthn Credential</h2>

<p>Create a WebAuthn credential bound to your SSH fingerprint:</p>

<button id="btn-bind-webauthn" style="padding: 0.75rem 1.5rem; font-size: 1rem;">🔗 Bind WebAuthn Credential</button>

<div id="output-bind-webauthn" class="output"></div>
</div>

<div class="demo-box">
<h2>✅ Step 3: Authenticate with WebAuthn</h2>

<p>Sign in using your WebAuthn credential (no SSH key required):</p>

<button id="btn-login" style="padding: 0.75rem 1.5rem; font-size: 1rem;">🔓 Login with WebAuthn</button>

<div id="output-login" class="output"></div>
</div>

<div class="demo-box">
<h2>📋 Manage Delegates</h2>

<p>View and manage your WebAuthn delegates:</p>

<button id="btn-list-delegates" style="padding: 0.75rem 1.5rem; font-size: 1rem;">📋 List Delegates</button>

<div id="output-delegates" class="output"></div>
</div>

<script>
(function() {
  // State
  let currentUser = null;
  let sshFingerprint = null;
  let bindingChallenge = null;
  let webauthnCredential = null;
  
  const regUsername = document.getElementById('reg-username');
  const regSshKey = document.getElementById('reg-ssh-key');
  const regUsernameMud = document.getElementById('reg-username-mud');
  const outputRegister = document.getElementById('output-register-ssh');
  const outputRegisterMud = document.getElementById('output-register-mud');
  const outputBind = document.getElementById('output-bind-webauthn');
  const outputLogin = document.getElementById('output-login');
  const outputDelegates = document.getElementById('output-delegates');
  
  // Utility functions
  function arrayBufferToBase64(buffer) {
    return btoa(String.fromCharCode(...new Uint8Array(buffer)));
  }
  
  function base64ToArrayBuffer(base64) {
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
  }
  
  function base64urlEncode(buffer) {
    return arrayBufferToBase64(buffer)
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');
  }
  
  function showError(output, message) {
    output.innerHTML = `
<div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336; margin-top: 1rem;">
<h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ Error</h4>
<p style="margin: 0;">${message}</p>
</div>
    `;
  }
  
  function showSuccess(output, message) {
    output.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50; margin-top: 1rem;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ Success</h4>
<p style="margin: 0;">${message}</p>
</div>
    `;
  }
  
  // Step 1A: Register with MUD Player Account
  document.getElementById('btn-register-mud').addEventListener('click', async () => {
    const username = regUsernameMud.value.trim();
    
    if (!username) {
      showError(outputRegisterMud, 'Please enter your MUD player name');
      return;
    }
    
    outputRegisterMud.innerHTML = '<p style="color: #2980b9; margin-top: 1rem;">🔄 Looking up MUD player account...</p>';
    
    try {
      const params = new URLSearchParams({
        username: username
      });
      
      const response = await fetch('/cgi/ssh-auth-register-mud?' + params.toString());
      const data = await response.json();
      
      if (data.success) {
        currentUser = data.username;
        sshFingerprint = data.fingerprint;
        bindingChallenge = data.challenge;
        
        const adminBadge = data.is_admin ? ' <span style="background: #f39c12; color: white; padding: 0.2rem 0.5rem; border-radius: 3px; font-size: 0.8rem;">ADMIN</span>' : '';
        
        outputRegisterMud.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50; margin-top: 1rem;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ MUD Player Found!${adminBadge}</h4>
<p style="margin: 0.5rem 0;"><strong>Username:</strong> ${data.username}</p>
<p style="margin: 0.5rem 0;"><strong>SSH Fingerprint:</strong></p>
<pre style="margin: 0.5rem 0; padding: 0.5rem; background: #fff; border-radius: 3px; overflow-x: auto; font-family: monospace; font-size: 0.85rem;">${data.fingerprint}</pre>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">
            🎮 Using SSH key from your MUD account. Now proceed to bind a WebAuthn credential.
</p>
</div>
        `;
      } else {
        showError(outputRegisterMud, data.error || 'Registration failed');
      }
    } catch (error) {
      showError(outputRegisterMud, 'Network error: ' + error.message);
    }
  });
  
  // Step 1B: Register SSH Public Key (Manual)
  document.getElementById('btn-register-ssh').addEventListener('click', async () => {
    const username = regUsername.value.trim();
    const sshKey = regSshKey.value.trim();
    
    if (!username || !sshKey) {
      showError(outputRegister, 'Please enter both username and SSH public key');
      return;
    }
    
    outputRegister.innerHTML = '<p style="color: #2980b9; margin-top: 1rem;">🔄 Registering SSH public key...</p>';
    
    try {
      const params = new URLSearchParams({
        username: username,
        ssh_public_key: sshKey
      });
      
      const response = await fetch('/cgi/ssh-auth-register?' + params.toString());
      const data = await response.json();
      
      if (data.success) {
        currentUser = data.username;
        sshFingerprint = data.fingerprint;
        bindingChallenge = data.challenge;
        
        outputRegister.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50; margin-top: 1rem;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ SSH Key Registered</h4>
<p style="margin: 0.5rem 0;"><strong>Username:</strong> ${data.username}</p>
<p style="margin: 0.5rem 0;"><strong>SSH Fingerprint:</strong></p>
<pre style="margin: 0.5rem 0; padding: 0.5rem; background: #fff; border-radius: 3px; overflow-x: auto; font-family: monospace; font-size: 0.85rem;">${data.fingerprint}</pre>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">
            🔐 This fingerprint is your root identity. Now proceed to bind a WebAuthn credential.
</p>
</div>
        `;
      } else {
        showError(outputRegister, data.error || 'Registration failed');
      }
    } catch (error) {
      showError(outputRegister, 'Network error: ' + error.message);
    }
  });
  
  // Step 2: Bind WebAuthn Credential
  document.getElementById('btn-bind-webauthn').addEventListener('click', async () => {
    if (!currentUser || !sshFingerprint || !bindingChallenge) {
      showError(outputBind, 'Please register your SSH key first');
      return;
    }
    
    if (!window.PublicKeyCredential) {
      showError(outputBind, 'WebAuthn not supported in this browser');
      return;
    }
    
    outputBind.innerHTML = '<p style="color: #2980b9; margin-top: 1rem;">🔄 Creating WebAuthn credential...</p>';
    
    try {
      // Convert challenge from base64
      const challengeBuffer = base64ToArrayBuffer(bindingChallenge);
      
      const publicKeyCredentialCreationOptions = {
        challenge: challengeBuffer,
        rp: {
          name: "Wizardry Blog - SSH Auth",
          id: window.location.hostname
        },
        user: {
          id: Uint8Array.from(sshFingerprint, c => c.charCodeAt(0)),
          name: currentUser,
          displayName: `${currentUser} (SSH: ${sshFingerprint.substring(0, 16)}...)`
        },
        pubKeyCredParams: [
          { alg: -7, type: "public-key" },  // ES256
          { alg: -257, type: "public-key" } // RS256
        ],
        authenticatorSelection: {
          authenticatorAttachment: "platform",
          requireResidentKey: false,
          userVerification: "preferred"
        },
        timeout: 60000,
        attestation: "none"
      };
      
      const credential = await navigator.credentials.create({
        publicKey: publicKeyCredentialCreationOptions
      });
      
      webauthnCredential = credential;
      
      // Extract public key from response (simplified - in production use CBOR)
      const publicKeyBase64 = arrayBufferToBase64(credential.response.getPublicKey ? 
        credential.response.getPublicKey() : new Uint8Array(0));
      
      // Bind credential to SSH fingerprint via CGI
      const params = new URLSearchParams({
        username: currentUser,
        credential_id: credential.id,
        public_key: publicKeyBase64,
        fingerprint: sshFingerprint
      });
      
      const response = await fetch('/cgi/ssh-auth-bind-webauthn?' + params.toString());
      const data = await response.json();
      
      if (data.success) {
        outputBind.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50; margin-top: 1rem;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ WebAuthn Credential Bound</h4>
<p style="margin: 0.5rem 0;"><strong>Delegate ID:</strong></p>
<pre style="margin: 0.5rem 0; padding: 0.5rem; background: #fff; border-radius: 3px; overflow-x: auto; font-family: monospace; font-size: 0.85rem;">${data.delegate_id}</pre>
<p style="margin: 0.5rem 0;"><strong>Credential ID:</strong></p>
<pre style="margin: 0.5rem 0; padding: 0.5rem; background: #fff; border-radius: 3px; overflow-x: auto; font-family: monospace; font-size: 0.85rem;">${credential.id.substring(0, 60)}...</pre>
<p style="margin: 0.5rem 0;"><strong>Bound to SSH Fingerprint:</strong> ${data.fingerprint.substring(0, 16)}...</p>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">
            🎉 Your WebAuthn credential is now bound to your SSH identity. You can now login!
</p>
</div>
        `;
      } else {
        showError(outputBind, data.error || 'Binding failed');
      }
    } catch (error) {
      showError(outputBind, 'WebAuthn error: ' + error.message);
    }
  });
  
  // Step 3: Login with WebAuthn
  document.getElementById('btn-login').addEventListener('click', async () => {
    if (!webauthnCredential) {
      showError(outputLogin, 'Please bind a WebAuthn credential first');
      return;
    }
    
    if (!window.PublicKeyCredential) {
      showError(outputLogin, 'WebAuthn not supported in this browser');
      return;
    }
    
    outputLogin.innerHTML = '<p style="color: #2980b9; margin-top: 1rem;">🔄 Authenticating...</p>';
    
    try {
      // Generate new challenge
      const newChallenge = crypto.getRandomValues(new Uint8Array(32));
      
      const publicKeyCredentialRequestOptions = {
        challenge: newChallenge,
        allowCredentials: [{
          id: base64ToArrayBuffer(arrayBufferToBase64(webauthnCredential.rawId)),
          type: 'public-key',
          transports: ['internal']
        }],
        timeout: 60000,
        userVerification: "preferred"
      };
      
      const assertion = await navigator.credentials.get({
        publicKey: publicKeyCredentialRequestOptions
      });
      
      // Authenticate via CGI
      const params = new URLSearchParams({
        credential_id: assertion.id
      });
      
      const response = await fetch('/cgi/ssh-auth-login?' + params.toString());
      const data = await response.json();
      
      if (data.success) {
        // Store session token in localStorage
        localStorage.setItem('session_token', data.session_token);
        
        outputLogin.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50; margin-top: 1rem;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ Authentication Successful!</h4>
<p style="margin: 0.5rem 0;"><strong>Logged in as:</strong> ${data.username}</p>
<p style="margin: 0.5rem 0;"><strong>SSH Fingerprint:</strong></p>
<pre style="margin: 0.5rem 0; padding: 0.5rem; background: #fff; border-radius: 3px; overflow-x: auto; font-family: monospace; font-size: 0.85rem;">${data.fingerprint}</pre>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">
            🎉 Login successful! The server resolved: WebAuthn credential → SSH fingerprint → account
</p>
<p style="margin: 1rem 0 0 0;">
<a href="admin.html" style="display: inline-block; padding: 0.75rem 1.5rem; background: #3498db; color: white; text-decoration: none; border-radius: 4px; font-weight: bold;">🎛️ Go to Admin Panel</a>
</p>
</div>
        `;
      } else {
        showError(outputLogin, data.error || 'Authentication failed');
      }
    } catch (error) {
      showError(outputLogin, 'Authentication error: ' + error.message);
    }
  });
  
  // List Delegates
  document.getElementById('btn-list-delegates').addEventListener('click', async () => {
    if (!currentUser) {
      showError(outputDelegates, 'Please register first');
      return;
    }
    
    outputDelegates.innerHTML = '<p style="color: #2980b9; margin-top: 1rem;">🔄 Loading delegates...</p>';
    
    try {
      const params = new URLSearchParams({
        username: currentUser
      });
      
      const response = await fetch('/cgi/ssh-auth-list-delegates?' + params.toString());
      const data = await response.json();
      
      if (data.success) {
        const delegates = data.delegates || [];
        
        if (delegates.length === 0) {
          outputDelegates.innerHTML = `
<div style="background: #fff3e0; padding: 1rem; border-radius: 4px; border: 1px solid #ff9800; margin-top: 1rem;">
<h4 style="margin: 0 0 0.5rem 0; color: #e65100;">ℹ️ No Delegates</h4>
<p style="margin: 0;">No WebAuthn credentials have been bound to this SSH identity yet.</p>
</div>
          `;
        } else {
          let delegatesHtml = delegates.map(d => `
<div style="border: 1px solid #ddd; border-radius: 4px; padding: 0.75rem; margin-bottom: 0.5rem; background: #f9f9f9;">
<p style="margin: 0.25rem 0;"><strong>Delegate ID:</strong> <code style="font-size: 0.85rem;">${d.delegate_id}</code></p>
<p style="margin: 0.25rem 0;"><strong>Credential ID:</strong> <code style="font-size: 0.85rem;">${d.credential_id.substring(0, 40)}...</code></p>
<p style="margin: 0.25rem 0;"><strong>Created:</strong> ${d.created_at}</p>
</div>
          `).join('');
          
          outputDelegates.innerHTML = `
<div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3; margin-top: 1rem;">
<h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">📋 WebAuthn Delegates</h4>
<p style="margin: 0.5rem 0;"><strong>SSH Fingerprint:</strong> ${data.fingerprint.substring(0, 16)}...</p>
<p style="margin: 0.5rem 0;"><strong>Total Delegates:</strong> ${delegates.length}</p>
<div style="margin-top: 1rem;">
${delegatesHtml}
</div>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">
            💡 All these delegates are bound to the same SSH identity and can be revoked independently.
</p>
</div>
          `;
        }
      } else {
        showError(outputDelegates, data.error || 'Failed to load delegates');
      }
    } catch (error) {
      showError(outputDelegates, 'Network error: ' + error.message);
    }
  });
})();
</script>

<style>
.demo-box {
  background: #f5f7fa;
  border: 2px solid #3498db;
  border-radius: 8px;
  padding: 1.5rem;
  margin: 2rem 0;
}

.demo-box h2 {
  margin-top: 0;
  color: #2c3e50;
}

.output {
  min-height: 20px;
}

button {
  background: #3498db;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  transition: background 0.3s;
}

button:hover {
  background: #2980b9;
}

button:active {
  background: #21618c;
}

code {
  background: #ecf0f1;
  padding: 0.2rem 0.4rem;
  border-radius: 3px;
  font-family: monospace;
  font-size: 0.9rem;
}

pre {
  background: #2c3e50;
  color: #ecf0f1;
  padding: 1rem;
  border-radius: 4px;
  overflow-x: auto;
  font-size: 0.85rem;
}
</style>

## Key Features

### ✅ Phishing-Resistant
WebAuthn credentials cannot be phished because they're bound to the domain and require user verification.

### 🔐 Root Identity Protection
Your SSH private key never touches the web. The SSH fingerprint is just an identifier.

### 🔄 Flexible Delegation
Create multiple WebAuthn credentials (different devices) bound to one SSH identity.

### ❌ Revocable Without Identity Change
Lose a device? Revoke its delegate without changing your SSH key or re-registering.

### 🚀 Recovery Path
Lost all WebAuthn delegates? Use SSH-based re-binding as a recovery mechanism.

## Security Properties

1. **SSH fingerprint** = Stable, long-term identity
2. **WebAuthn credential** = Short-lived, revocable delegate
3. **Authentication** = WebAuthn-only (never SSH key directly)
4. **Resolution chain** = `credential_id → delegate → fingerprint → account`
5. **Revocation** = Delete delegate, identity unchanged

## Use Cases

- **Primary Authentication**: Daily login with biometrics
- **Multi-Device**: Bind multiple devices to one SSH identity
- **Device Loss**: Revoke lost device's delegate
- **Recovery**: Re-bind new WebAuthn credential using SSH key

---

**Note**: This is a demonstration. In production, you would:
- Verify WebAuthn signatures server-side
- Use proper CBOR decoding for credential data
- Implement session management
- Add CSRF protection
- Use HTTPS (required for WebAuthn)
