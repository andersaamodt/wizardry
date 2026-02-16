---
title: Security & Permissions
---

Explore browser security models and permission APIs.

## 1. Same-Origin Policy Demonstration

The Same-Origin Policy restricts how documents or scripts from one origin can interact with resources from another origin:

<div class="demo-box">
<h3>🔒 Same-Origin Policy Test</h3>
  
<p style="margin-bottom: 1rem;">
    Current origin: <strong id="current-origin"></strong>
</p>
  
<div style="margin-bottom: 1rem;">
<label style="display: block; margin-bottom: 0.5rem;"><strong>Try to fetch from URL:</strong></label>
<select id="origin-select" style="width: 100%; padding: 0.5rem; margin-bottom: 0.5rem;">
<option value="same">Same origin (current domain)</option>
<option value="https://api.github.com/zen">Cross-origin (GitHub API - CORS enabled)</option>
<option value="https://example.com">Cross-origin (example.com - no CORS)</option>
</select>
<button id="origin-test">🧪 Test Fetch</button>
</div>
  
<div id="origin-output" class="output"></div>
</div>

<script>
(function() {
  const currentOrigin = window.location.origin;
  document.getElementById('current-origin').textContent = currentOrigin;
  
  const output = document.getElementById('origin-output');
  const select = document.getElementById('origin-select');
  
  document.getElementById('origin-test').addEventListener('click', async () => {
    const selection = select.value;
    let url;
    
    if (selection === 'same') {
      url = window.location.href;
    } else {
      url = selection;
    }
    
    output.innerHTML = `<p style="color: #2980b9;">🔄 Fetching from: ${url}</p>`;
    
    try {
      const response = await fetch(url, { mode: 'cors' });
      const text = await response.text();
      
      output.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ Fetch Successful</h4>
<p style="margin: 0.25rem 0;"><strong>Status:</strong> ${response.status} ${response.statusText}</p>
<p style="margin: 0.25rem 0;"><strong>Origin:</strong> ${new URL(url).origin}</p>
<p style="margin: 0.25rem 0;"><strong>Same Origin:</strong> ${new URL(url).origin === currentOrigin ? 'Yes' : 'No (CORS allowed)'}</p>
<details style="margin-top: 0.5rem;">
<summary style="cursor: pointer; color: #2e7d32;">Show response preview (first 200 chars)</summary>
<pre style="margin-top: 0.5rem; background: #fff; padding: 0.5rem; border-radius: 3px; overflow-x: auto; font-size: 0.85rem;">${text.substring(0, 200)}${text.length > 200 ? '...' : ''}</pre>
</details>
</div>
      `;
    } catch (error) {
      output.innerHTML = `
<div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
<h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ Fetch Failed (Same-Origin Policy)</h4>
<p style="margin: 0.25rem 0;"><strong>Error:</strong> ${error.message}</p>
<p style="margin: 0.25rem 0;"><strong>Target:</strong> ${new URL(url).origin}</p>
<p style="margin: 0.25rem 0;"><strong>Current Origin:</strong> ${currentOrigin}</p>
<p style="margin-top: 0.5rem; color: #666; font-size: 0.9rem;">
            🔒 The Same-Origin Policy blocked this request because the target server doesn't allow CORS from this origin.
</p>
</div>
      `;
    }
  });
})();
</script>

## 2. Permissions API

Query and request browser permissions for sensitive features:

<div class="demo-box">
<h3>🔐 Permissions API</h3>
  
<p style="margin-bottom: 1rem;">Check the status of various browser permissions:</p>
  
<div style="display: grid; gap: 0.5rem; margin-bottom: 1rem;">
<button id="perm-geolocation">📍 Check Geolocation Permission</button>
<button id="perm-notifications">🔔 Check Notifications Permission</button>
<button id="perm-camera">📷 Check Camera Permission</button>
<button id="perm-microphone">🎤 Check Microphone Permission</button>
<button id="perm-clipboard">📋 Check Clipboard Permission</button>
</div>
  
<div id="perm-output" class="output"></div>
</div>

<script>
(function() {
  const output = document.getElementById('perm-output');
  
  async function checkPermission(name, displayName, icon) {
    try {
      if (!navigator.permissions) {
        throw new Error('Permissions API not supported');
      }
      
      const result = await navigator.permissions.query({ name });
      
      const statusColors = {
        granted: '#4caf50',
        denied: '#f44336',
        prompt: '#ff9800'
      };
      
      const statusIcons = {
        granted: '✅',
        denied: '❌',
        prompt: '❓'
      };
      
      const color = statusColors[result.state] || '#7f8c8d';
      const icon_status = statusIcons[result.state] || '❓';
      
      output.innerHTML = `
<div style="background: ${result.state === 'granted' ? '#e8f5e9' : result.state === 'denied' ? '#ffebee' : '#fff3e0'}; padding: 1rem; border-radius: 4px; border: 1px solid ${color};">
<h4 style="margin: 0 0 0.5rem 0; color: ${color};">${icon} ${displayName} Permission</h4>
<p style="margin: 0.25rem 0;"><strong>Status:</strong> ${icon_status} ${result.state.toUpperCase()}</p>
<p style="margin: 0.25rem 0; color: #666; font-size: 0.9rem;">
            ${result.state === 'granted' ? '✅ Permission already granted' : 
              result.state === 'denied' ? '❌ Permission denied by user' : 
              '❓ Permission will be requested when needed'}
</p>
</div>
      `;
      
      // Listen for changes
      result.addEventListener('change', () => {
        output.innerHTML += `<p style="margin-top: 0.5rem; color: #2980b9;">🔄 Permission changed to: ${result.state}</p>`;
      });
    } catch (error) {
      output.innerHTML = `
<div style="background: #fff3cd; padding: 1rem; border-radius: 4px; border: 1px solid #ffc107;">
<h4 style="margin: 0 0 0.5rem 0; color: #856404;">⚠️ ${displayName} Permission Check</h4>
<p style="margin: 0.25rem 0;"><strong>Error:</strong> ${error.message}</p>
<p style="margin: 0.25rem 0; color: #666; font-size: 0.9rem;">
            This permission might not be queryable via the Permissions API, or the API is not supported in this browser.
</p>
</div>
      `;
    }
  }
  
  document.getElementById('perm-geolocation').addEventListener('click', () => {
    checkPermission('geolocation', 'Geolocation', '📍');
  });
  
  document.getElementById('perm-notifications').addEventListener('click', () => {
    // Notifications uses a different API
    const permission = Notification.permission;
    const statusColors = {
      granted: '#4caf50',
      denied: '#f44336',
      default: '#ff9800'
    };
    const color = statusColors[permission] || '#7f8c8d';
    
    output.innerHTML = `
<div style="background: ${permission === 'granted' ? '#e8f5e9' : permission === 'denied' ? '#ffebee' : '#fff3e0'}; padding: 1rem; border-radius: 4px; border: 1px solid ${color};">
<h4 style="margin: 0 0 0.5rem 0; color: ${color};">🔔 Notifications Permission</h4>
<p style="margin: 0.25rem 0;"><strong>Status:</strong> ${permission.toUpperCase()}</p>
<p style="margin: 0.25rem 0; color: #666; font-size: 0.9rem;">
          ${permission === 'granted' ? '✅ Can send notifications' : 
            permission === 'denied' ? '❌ Notifications blocked' : 
            '❓ Will request permission when needed'}
</p>
</div>
    `;
  });
  
  document.getElementById('perm-camera').addEventListener('click', () => {
    checkPermission('camera', 'Camera', '📷');
  });
  
  document.getElementById('perm-microphone').addEventListener('click', () => {
    checkPermission('microphone', 'Microphone', '🎤');
  });
  
  document.getElementById('perm-clipboard').addEventListener('click', () => {
    checkPermission('clipboard-read', 'Clipboard Read', '📋');
  });
})();
</script>

## 3. Secure Context Detection

Some browser features only work in secure contexts (HTTPS):

<div class="demo-box">
<h3>🔐 Secure Context Check</h3>
  
<button id="secure-check">🔍 Check Current Context</button>
  
<div id="secure-output" class="output"></div>
</div>

<script>
(function() {
  const output = document.getElementById('secure-output');
  
  document.getElementById('secure-check').addEventListener('click', () => {
    const isSecure = window.isSecureContext;
    const protocol = window.location.protocol;
    const hostname = window.location.hostname;
    
    // Check which APIs require secure context
    const secureOnlyAPIs = {
      'Geolocation': 'geolocation' in navigator,
      'Service Worker': 'serviceWorker' in navigator,
      'Web Crypto': 'crypto' in window && 'subtle' in crypto,
      'Notifications': 'Notification' in window,
      'Clipboard (async)': 'clipboard' in navigator,
      'getUserMedia': 'mediaDevices' in navigator && 'getUserMedia' in navigator.mediaDevices
    };
    
    const apiTable = Object.entries(secureOnlyAPIs).map(([name, available]) => {
      return `
<tr>
<td style="padding: 0.5rem; border: 1px solid #ddd;">${name}</td>
<td style="padding: 0.5rem; border: 1px solid #ddd; text-align: center;">
            ${available ? '<span style="color: #4caf50;">✅ Available</span>' : '<span style="color: #f44336;">❌ Not Available</span>'}
</td>
</tr>
      `;
    }).join('');
    
    output.innerHTML = `
<div style="background: ${isSecure ? '#e8f5e9' : '#fff3e0'}; padding: 1rem; border-radius: 4px; border: 1px solid ${isSecure ? '#4caf50' : '#ff9800'};">
<h4 style="margin: 0 0 0.5rem 0; color: ${isSecure ? '#2e7d32' : '#e65100'};">
          ${isSecure ? '🔒 Secure Context' : '⚠️ Insecure Context'}
</h4>
<p style="margin: 0.25rem 0;"><strong>Protocol:</strong> ${protocol}</p>
<p style="margin: 0.25rem 0;"><strong>Hostname:</strong> ${hostname}</p>
<p style="margin: 0.25rem 0;"><strong>Is Secure:</strong> ${isSecure ? 'Yes ✅' : 'No ❌'}</p>
        
<h4 style="margin: 1rem 0 0.5rem 0;">Secure-Context-Only APIs:</h4>
<table style="width: 100%; border-collapse: collapse; font-size: 0.9rem;">
<thead>
<tr style="background: #e9ecef;">
<th style="padding: 0.5rem; border: 1px solid #ddd; text-align: left;">API</th>
<th style="padding: 0.5rem; border: 1px solid #ddd; text-align: center;">Status</th>
</tr>
</thead>
<tbody>
            ${apiTable}
</tbody>
</table>
        
<p style="margin-top: 1rem; color: #666; font-size: 0.9rem;">
          ${isSecure ? 
            '✅ All secure-context-only APIs can be used on this page.' : 
            '⚠️ Some APIs may be restricted. Use HTTPS for full functionality.'}
</p>
</div>
    `;
  });
  
  // Auto-check on load
  document.getElementById('secure-check').click();
})();
</script>

## 4. Content Security Policy Info

Display information about Content Security Policy if available:

<div class="demo-box">
<h3>🛡️ Content Security Policy</h3>
  
<button id="csp-check">🔍 Check CSP</button>
  
<div id="csp-output" class="output"></div>
</div>

<script>
(function() {
  const output = document.getElementById('csp-output');
  
  document.getElementById('csp-check').addEventListener('click', () => {
    // Try to detect CSP violations and report
    const violations = [];
    
    // Check if CSP is blocking inline scripts
    try {
      eval('1+1'); // This might be blocked by CSP
    } catch (e) {
      if (e.message.includes('Content Security Policy')) {
        violations.push('Inline script evaluation blocked');
      }
    }
    
    // Check for reporting API
    const hasReportingAPI = 'ReportingObserver' in window;
    
    output.innerHTML = `
<div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3;">
<h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">🛡️ CSP Information</h4>
        
<p style="margin: 0.25rem 0;"><strong>Reporting API Available:</strong> ${hasReportingAPI ? '✅ Yes' : '❌ No'}</p>
        
        ${violations.length > 0 ? `
<h4 style="margin: 1rem 0 0.5rem 0; color: #e65100;">⚠️ Detected Restrictions:</h4>
<ul style="margin: 0; padding-left: 1.5rem; color: #e65100;">
            ${violations.map(v => `<li>${v}</li>`).join('')}
</ul>
        ` : `
<p style="margin-top: 1rem; color: #4caf50;">✅ No CSP restrictions detected (or CSP allows current operations)</p>
        `}
        
<p style="margin-top: 1rem; color: #666; font-size: 0.9rem;">
          💡 Content Security Policy (CSP) helps prevent XSS attacks by controlling which resources can be loaded and executed.
          Check the browser console and network tab for detailed CSP violation reports.
</p>
</div>
    `;
    
    // Set up ReportingObserver if available
    if (hasReportingAPI) {
      const observer = new ReportingObserver((reports, observer) => {
        reports.forEach(report => {
          if (report.type === 'csp-violation') {
            console.log('CSP Violation detected:', report);
          }
        });
      });
      observer.observe();
    }
  });
})();
</script>

## 5. Web Crypto API (SubtleCrypto)

Perform cryptographic operations like hashing, encryption, and key generation:

<div class="demo-box">
<h3>🔐 Web Crypto API</h3>
  
<div style="margin-bottom: 2rem;">
<h4>Hash Generation (SHA-256)</h4>
<textarea id="crypto-hash-input" rows="3" placeholder="Enter text to hash..." style="width: 100%; padding: 0.75rem; border: 2px solid #ddd; border-radius: 4px; font-size: 1rem; margin-bottom: 0.5rem;">Hello, Crypto API!</textarea>
<button id="crypto-hash">🔐 Generate SHA-256 Hash</button>
<div id="crypto-hash-output" class="output"></div>
</div>
  
<div style="margin-bottom: 2rem;">
<h4>Encryption & Decryption (AES-GCM)</h4>
<textarea id="crypto-encrypt-input" rows="3" placeholder="Enter text to encrypt..." style="width: 100%; padding: 0.75rem; border: 2px solid #ddd; border-radius: 4px; font-size: 1rem; margin-bottom: 0.5rem;">Secret message</textarea>
<div style="display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 0.5rem;">
<button id="crypto-generate-key">🔑 Generate Key</button>
<button id="crypto-encrypt">🔒 Encrypt</button>
<button id="crypto-decrypt">🔓 Decrypt</button>
</div>
<div id="crypto-encrypt-output" class="output"></div>
</div>
  
<div>
<h4>Digital Signature (ECDSA)</h4>
<textarea id="crypto-sign-input" rows="3" placeholder="Enter text to sign..." style="width: 100%; padding: 0.75rem; border: 2px solid #ddd; border-radius: 4px; font-size: 1rem; margin-bottom: 0.5rem;">Document to sign</textarea>
<div style="display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 0.5rem;">
<button id="crypto-generate-keypair">🔑 Generate Key Pair</button>
<button id="crypto-sign">✍️ Sign</button>
<button id="crypto-verify">✅ Verify Signature</button>
</div>
<div id="crypto-sign-output" class="output"></div>
</div>
</div>

<script>
(function() {
  const hashInput = document.getElementById('crypto-hash-input');
  const hashOutput = document.getElementById('crypto-hash-output');
  const encryptInput = document.getElementById('crypto-encrypt-input');
  const encryptOutput = document.getElementById('crypto-encrypt-output');
  const signInput = document.getElementById('crypto-sign-input');
  const signOutput = document.getElementById('crypto-sign-output');
  
  let aesKey = null;
  let encryptedData = null;
  let iv = null;
  
  let keyPair = null;
  let signature = null;
  
  // Utility functions
  function arrayBufferToHex(buffer) {
    return Array.from(new Uint8Array(buffer))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
  }
  
  function arrayBufferToBase64(buffer) {
    return btoa(String.fromCharCode(...new Uint8Array(buffer)));
  }
  
  // Hash demo
  document.getElementById('crypto-hash').addEventListener('click', async () => {
    const text = hashInput.value;
    
    if (!text) {
      hashOutput.innerHTML = '<p class="error">Please enter text to hash</p>';
      return;
    }
    
    try {
      const encoder = new TextEncoder();
      const data = encoder.encode(text);
      const hashBuffer = await crypto.subtle.digest('SHA-256', data);
      const hashHex = arrayBufferToHex(hashBuffer);
      
      hashOutput.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">🔐 SHA-256 Hash</h4>
<p style="margin: 0.25rem 0;"><strong>Input:</strong> "${text}"</p>
<p style="margin: 0.25rem 0;"><strong>Hash:</strong></p>
<pre style="margin: 0.5rem 0; padding: 0.5rem; background: #fff; border-radius: 3px; overflow-x: auto; font-size: 0.85rem;">${hashHex}</pre>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">Length: ${hashHex.length} chars (64 hex digits = 256 bits)</p>
</div>
      `;
    } catch (error) {
      hashOutput.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
  
  // Encryption demo
  document.getElementById('crypto-generate-key').addEventListener('click', async () => {
    try {
      aesKey = await crypto.subtle.generateKey(
        { name: 'AES-GCM', length: 256 },
        true,
        ['encrypt', 'decrypt']
      );
      
      encryptOutput.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ AES-256 Key Generated</h4>
<p style="margin: 0;">Ready to encrypt and decrypt messages!</p>
</div>
      `;
    } catch (error) {
      encryptOutput.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
  
  document.getElementById('crypto-encrypt').addEventListener('click', async () => {
    const text = encryptInput.value;
    
    if (!text) {
      encryptOutput.innerHTML = '<p class="error">Please enter text to encrypt</p>';
      return;
    }
    
    if (!aesKey) {
      encryptOutput.innerHTML = '<p class="error">Generate a key first</p>';
      return;
    }
    
    try {
      const encoder = new TextEncoder();
      const data = encoder.encode(text);
      
      // Generate random IV (initialization vector)
      iv = crypto.getRandomValues(new Uint8Array(12));
      
      encryptedData = await crypto.subtle.encrypt(
        { name: 'AES-GCM', iv: iv },
        aesKey,
        data
      );
      
      encryptOutput.innerHTML = `
<div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3;">
<h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">🔒 Encrypted</h4>
<p style="margin: 0.25rem 0;"><strong>Original:</strong> "${text}"</p>
<p style="margin: 0.25rem 0;"><strong>Encrypted (Base64):</strong></p>
<pre style="margin: 0.5rem 0; padding: 0.5rem; background: #fff; border-radius: 3px; overflow-x: auto; font-size: 0.85rem;">${arrayBufferToBase64(encryptedData)}</pre>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">Click Decrypt to retrieve the original text</p>
</div>
      `;
    } catch (error) {
      encryptOutput.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
  
  document.getElementById('crypto-decrypt').addEventListener('click', async () => {
    if (!aesKey || !encryptedData || !iv) {
      encryptOutput.innerHTML = '<p class="error">Encrypt something first</p>';
      return;
    }
    
    try {
      const decryptedData = await crypto.subtle.decrypt(
        { name: 'AES-GCM', iv: iv },
        aesKey,
        encryptedData
      );
      
      const decoder = new TextDecoder();
      const decryptedText = decoder.decode(decryptedData);
      
      encryptOutput.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">🔓 Decrypted Successfully!</h4>
<p style="margin: 0.25rem 0;"><strong>Decrypted Text:</strong> "${decryptedText}"</p>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">The encrypted data was successfully decrypted back to the original text</p>
</div>
      `;
    } catch (error) {
      encryptOutput.innerHTML = `<p class="error">Decryption error: ${error.message}</p>`;
    }
  });
  
  // Digital signature demo
  document.getElementById('crypto-generate-keypair').addEventListener('click', async () => {
    try {
      keyPair = await crypto.subtle.generateKey(
        {
          name: 'ECDSA',
          namedCurve: 'P-256'
        },
        true,
        ['sign', 'verify']
      );
      
      signOutput.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ ECDSA Key Pair Generated</h4>
<p style="margin: 0;">Public/private key pair ready for signing and verification!</p>
</div>
      `;
    } catch (error) {
      signOutput.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
  
  document.getElementById('crypto-sign').addEventListener('click', async () => {
    const text = signInput.value;
    
    if (!text) {
      signOutput.innerHTML = '<p class="error">Please enter text to sign</p>';
      return;
    }
    
    if (!keyPair) {
      signOutput.innerHTML = '<p class="error">Generate a key pair first</p>';
      return;
    }
    
    try {
      const encoder = new TextEncoder();
      const data = encoder.encode(text);
      
      signature = await crypto.subtle.sign(
        {
          name: 'ECDSA',
          hash: { name: 'SHA-256' }
        },
        keyPair.privateKey,
        data
      );
      
      signOutput.innerHTML = `
<div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3;">
<h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">✍️ Signed</h4>
<p style="margin: 0.25rem 0;"><strong>Document:</strong> "${text}"</p>
<p style="margin: 0.25rem 0;"><strong>Signature (Hex):</strong></p>
<pre style="margin: 0.5rem 0; padding: 0.5rem; background: #fff; border-radius: 3px; overflow-x: auto; font-size: 0.85rem;">${arrayBufferToHex(signature)}</pre>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">Click Verify to check the signature</p>
</div>
      `;
    } catch (error) {
      signOutput.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
  
  document.getElementById('crypto-verify').addEventListener('click', async () => {
    const text = signInput.value;
    
    if (!keyPair || !signature) {
      signOutput.innerHTML = '<p class="error">Sign something first</p>';
      return;
    }
    
    try {
      const encoder = new TextEncoder();
      const data = encoder.encode(text);
      
      const isValid = await crypto.subtle.verify(
        {
          name: 'ECDSA',
          hash: { name: 'SHA-256' }
        },
        keyPair.publicKey,
        signature,
        data
      );
      
      if (isValid) {
        signOutput.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ Signature Valid!</h4>
<p style="margin: 0;">The signature is authentic and the document has not been tampered with.</p>
</div>
        `;
      } else {
        signOutput.innerHTML = `
<div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
<h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ Signature Invalid</h4>
<p style="margin: 0;">The signature does not match or the document has been modified.</p>
</div>
        `;
      }
    } catch (error) {
      signOutput.innerHTML = `<p class="error">Verification error: ${error.message}</p>`;
    }
  });
})();
</script>

## 6. WebAuthn API (Passwordless Authentication)

WebAuthn enables strong, phishing-resistant authentication using public key cryptography:

<div class="demo-box">
<h3>🔑 WebAuthn Registration & Authentication</h3>
  
<p style="margin-bottom: 1rem;">
    WebAuthn allows you to create and use credentials for passwordless authentication.
    This demo simulates the registration and authentication flow.
</p>

<div style="margin-bottom: 2rem;">
<h4>Step 1: Registration</h4>
<p style="color: #666; font-size: 0.9rem; margin-bottom: 0.5rem;">Create a new WebAuthn credential (use your device's authenticator: fingerprint, face recognition, or security key)</p>
<div style="margin-bottom: 1rem;">
<label style="display: block; margin-bottom: 0.5rem;"><strong>Username:</strong></label>
<input type="text" id="webauthn-username" placeholder="Enter username" style="width: 100%; padding: 0.75rem; border: 2px solid #ddd; border-radius: 4px; font-size: 1rem; margin-bottom: 0.5rem;" value="demo-user">
</div>
<button id="webauthn-register">🔑 Register with WebAuthn</button>
<div id="webauthn-register-output" class="output"></div>
</div>

<div style="margin-bottom: 2rem;">
<h4>Step 2: Authentication</h4>
<p style="color: #666; font-size: 0.9rem; margin-bottom: 0.5rem;">Sign in using your previously registered credential</p>
<button id="webauthn-authenticate">✅ Authenticate with WebAuthn</button>
<div id="webauthn-authenticate-output" class="output"></div>
</div>

<div>
<h4>Credential Information</h4>
<button id="webauthn-info">ℹ️ Show Credential Details</button>
<div id="webauthn-info-output" class="output"></div>
</div>
</div>

<script>
(function() {
  const registerOutput = document.getElementById('webauthn-register-output');
  const authenticateOutput = document.getElementById('webauthn-authenticate-output');
  const infoOutput = document.getElementById('webauthn-info-output');
  const usernameInput = document.getElementById('webauthn-username');
  
  let storedCredential = null;
  let challenge = null;
  
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
  
  function generateChallenge() {
    return crypto.getRandomValues(new Uint8Array(32));
  }
  
  // Registration
  document.getElementById('webauthn-register').addEventListener('click', async () => {
    const username = usernameInput.value.trim();
    
    if (!username) {
      registerOutput.innerHTML = '<p class="error">Please enter a username</p>';
      return;
    }
    
    if (!window.PublicKeyCredential) {
      registerOutput.innerHTML = `
<div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
<h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ WebAuthn Not Supported</h4>
<p style="margin: 0;">Your browser doesn't support WebAuthn. Try using a modern browser like Chrome, Firefox, Safari, or Edge.</p>
</div>
      `;
      return;
    }
    
    registerOutput.innerHTML = '<p style="color: #2980b9;">🔄 Requesting credential creation...</p>';
    
    try {
      challenge = generateChallenge();
      
      const publicKeyCredentialCreationOptions = {
        challenge: challenge,
        rp: {
          name: "Wizardry Web Demo",
          id: window.location.hostname
        },
        user: {
          id: crypto.getRandomValues(new Uint8Array(16)),
          name: username,
          displayName: username
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
      
      // Store credential info
      storedCredential = {
        id: credential.id,
        rawId: arrayBufferToBase64(credential.rawId),
        type: credential.type,
        username: username
      };
      
      registerOutput.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ Registration Successful!</h4>
<p style="margin: 0.25rem 0;"><strong>Username:</strong> ${username}</p>
<p style="margin: 0.25rem 0;"><strong>Credential ID:</strong></p>
<pre style="margin: 0.5rem 0; padding: 0.5rem; background: #fff; border-radius: 3px; overflow-x: auto; font-size: 0.75rem;">${credential.id.substring(0, 60)}...</pre>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">
            ✅ You can now authenticate using this credential!
</p>
</div>
      `;
    } catch (error) {
      registerOutput.innerHTML = `
<div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
<h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ Registration Failed</h4>
<p style="margin: 0.25rem 0;"><strong>Error:</strong> ${error.message}</p>
<p style="margin-top: 0.5rem; color: #666; font-size: 0.9rem;">
            ${error.name === 'NotAllowedError' ? 
              '🔒 Registration was cancelled or not allowed. Make sure you approve the authentication request.' :
              error.name === 'InvalidStateError' ?
              '⚠️ A credential might already exist for this device.' :
              '❌ Registration failed. Please try again.'}
</p>
</div>
      `;
    }
  });
  
  // Authentication
  document.getElementById('webauthn-authenticate').addEventListener('click', async () => {
    if (!storedCredential) {
      authenticateOutput.innerHTML = '<p class="error">Please register first</p>';
      return;
    }
    
    if (!window.PublicKeyCredential) {
      authenticateOutput.innerHTML = '<p class="error">WebAuthn not supported</p>';
      return;
    }
    
    authenticateOutput.innerHTML = '<p style="color: #2980b9;">🔄 Requesting authentication...</p>';
    
    try {
      const newChallenge = generateChallenge();
      
      const publicKeyCredentialRequestOptions = {
        challenge: newChallenge,
        allowCredentials: [{
          id: base64ToArrayBuffer(storedCredential.rawId),
          type: 'public-key',
          transports: ['internal']
        }],
        timeout: 60000,
        userVerification: "preferred"
      };
      
      const assertion = await navigator.credentials.get({
        publicKey: publicKeyCredentialRequestOptions
      });
      
      authenticateOutput.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ Authentication Successful!</h4>
<p style="margin: 0.25rem 0;"><strong>User:</strong> ${storedCredential.username}</p>
<p style="margin: 0.25rem 0;"><strong>Credential ID:</strong></p>
<pre style="margin: 0.5rem 0; padding: 0.5rem; background: #fff; border-radius: 3px; overflow-x: auto; font-size: 0.75rem;">${assertion.id.substring(0, 60)}...</pre>
<p style="margin: 0.25rem 0;"><strong>Authenticator Data:</strong> ${assertion.response.authenticatorData.byteLength} bytes</p>
<p style="margin: 0.25rem 0;"><strong>Signature:</strong> ${assertion.response.signature.byteLength} bytes</p>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">
            🎉 Authentication verified! In a real application, this signature would be verified server-side.
</p>
</div>
      `;
    } catch (error) {
      authenticateOutput.innerHTML = `
<div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
<h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ Authentication Failed</h4>
<p style="margin: 0.25rem 0;"><strong>Error:</strong> ${error.message}</p>
<p style="margin-top: 0.5rem; color: #666; font-size: 0.9rem;">
            ${error.name === 'NotAllowedError' ? 
              '🔒 Authentication was cancelled or not allowed.' :
              '❌ Authentication failed. The credential might not be recognized.'}
</p>
</div>
      `;
    }
  });
  
  // Show credential info
  document.getElementById('webauthn-info').addEventListener('click', () => {
    if (!storedCredential) {
      infoOutput.innerHTML = '<p class="error">No credential registered yet</p>';
      return;
    }
    
    infoOutput.innerHTML = `
<div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3;">
<h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">ℹ️ Stored Credential Information</h4>
<p style="margin: 0.25rem 0;"><strong>Username:</strong> ${storedCredential.username}</p>
<p style="margin: 0.25rem 0;"><strong>Credential Type:</strong> ${storedCredential.type}</p>
<p style="margin: 0.25rem 0;"><strong>Credential ID (Base64):</strong></p>
<pre style="margin: 0.5rem 0; padding: 0.5rem; background: #fff; border-radius: 3px; overflow-x: auto; font-size: 0.75rem;">${storedCredential.rawId}</pre>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">
          💡 This credential is stored locally in your browser. In a real application, the public key would be stored on the server.
</p>
</div>
    `;
  });
})();
</script>

---

<div class="info-box">
<h3>🎯 Security APIs Demonstrated:</h3>
<ul>
<li><strong>Same-Origin Policy:</strong> Browser's fundamental security mechanism</li>
<li><strong>Permissions API:</strong> Query permission states for sensitive features</li>
<li><strong>Secure Contexts:</strong> HTTPS-only API access detection</li>
<li><strong>CSP:</strong> Content Security Policy information and violation detection</li>
<li><strong>Web Crypto API:</strong> Cryptographic operations (hashing, encryption, signatures)</li>
<li><strong>WebAuthn API:</strong> Passwordless authentication using public key cryptography</li>
</ul>
  
<p style="margin-top: 1rem;"><strong>🔐 Cryptographic Operations:</strong></p>
<ul>
<li><strong>Hashing (SHA-256):</strong> One-way hash for data integrity and password storage</li>
<li><strong>Encryption (AES-GCM):</strong> Symmetric encryption for data confidentiality</li>
<li><strong>Digital Signatures (ECDSA):</strong> Verify authenticity and non-repudiation</li>
<li><strong>Key Generation:</strong> Secure random key creation</li>
</ul>
  
<p style="margin-top: 1rem;"><strong>🔒 Security Principles:</strong></p>
<ul>
<li><strong>Same-Origin Policy:</strong> Prevents malicious scripts from accessing data from other origins</li>
<li><strong>CORS:</strong> Controlled relaxation of same-origin policy via server headers</li>
<li><strong>Secure Contexts:</strong> Sensitive APIs only work over HTTPS</li>
<li><strong>Permissions:</strong> User must grant explicit permission for sensitive features</li>
<li><strong>CSP:</strong> Restricts resource loading to prevent injection attacks</li>
<li><strong>Crypto API:</strong> All operations happen in secure, sandboxed environment</li>
<li><strong>WebAuthn:</strong> Phishing-resistant authentication using hardware-backed cryptographic keys</li>
</ul>
  
<p style="margin-top: 1rem;"><strong>🌐 Origins:</strong></p>
<p style="margin: 0.5rem 0 0.5rem 1rem; font-family: monospace; font-size: 0.9rem;">
    Two URLs have the same origin if they have the same:
</p>
<ul style="margin: 0 0 0 2rem;">
<li>Protocol (http vs https)</li>
<li>Domain (example.com vs other.com)</li>
<li>Port (80 vs 8080)</li>
</ul>
</div>
