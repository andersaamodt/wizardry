---
title: State & Persistence Demos
---

# State & Persistence Demos

Explore browser storage APIs for persisting data across sessions and tabs.

## 1. Local Storage - Persistent Key-Value Store

Local Storage persists across browser sessions and is shared across all tabs from the same origin.

<div class="demo-box">
  <h3>Save to Local Storage</h3>
  <input type="text" id="ls-key" placeholder="Key" value="username" />
  <input type="text" id="ls-value" placeholder="Value" value="wizard123" />
  <button id="ls-set">💾 Save</button>
  <button id="ls-get" style="margin-left: 10px;">📖 Load</button>
  <button id="ls-remove" style="margin-left: 10px;">🗑️ Remove</button>
  <button id="ls-clear" style="margin-left: 10px;">🧹 Clear All</button>
  <div id="ls-output" class="output"></div>
</div>

<script>
(function() {
  const keyInput = document.getElementById('ls-key');
  const valueInput = document.getElementById('ls-value');
  const output = document.getElementById('ls-output');
  
  document.getElementById('ls-set').addEventListener('click', () => {
    const key = keyInput.value;
    const value = valueInput.value;
    localStorage.setItem(key, value);
    output.innerHTML = `<p style="color: #27ae60;">✅ Saved "${key}" = "${value}"</p>`;
    displayAllItems();
  });
  
  document.getElementById('ls-get').addEventListener('click', () => {
    const key = keyInput.value;
    const value = localStorage.getItem(key);
    if (value !== null) {
      output.innerHTML = `<p style="color: #2980b9;">📖 Retrieved "${key}" = "${value}"</p>`;
      valueInput.value = value;
    } else {
      output.innerHTML = `<p style="color: #e67e22;">⚠️ Key "${key}" not found</p>`;
    }
  });
  
  document.getElementById('ls-remove').addEventListener('click', () => {
    const key = keyInput.value;
    localStorage.removeItem(key);
    output.innerHTML = `<p style="color: #c0392b;">🗑️ Removed "${key}"</p>`;
    displayAllItems();
  });
  
  document.getElementById('ls-clear').addEventListener('click', () => {
    localStorage.clear();
    output.innerHTML = `<p style="color: #8e44ad;">🧹 Cleared all local storage</p>`;
  });
  
  function displayAllItems() {
    const items = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      const value = localStorage.getItem(key);
      items.push(`<tr><td style="padding: 0.5rem; border: 1px solid #ddd;">${key}</td><td style="padding: 0.5rem; border: 1px solid #ddd;">${value}</td></tr>`);
    }
    
    if (items.length > 0) {
      output.innerHTML += `
        <div style="margin-top: 1rem; background: #f8f9fa; padding: 1rem; border-radius: 4px;">
          <strong>Current Local Storage (${items.length} items):</strong>
          <table style="width: 100%; margin-top: 0.5rem; border-collapse: collapse;">
            <thead><tr><th style="padding: 0.5rem; border: 1px solid #ddd; background: #e9ecef;">Key</th><th style="padding: 0.5rem; border: 1px solid #ddd; background: #e9ecef;">Value</th></tr></thead>
            <tbody>${items.join('')}</tbody>
          </table>
        </div>
      `;
    }
  }
})();
</script>

## 2. Session Storage - Per-Tab Storage

Session Storage is cleared when the tab closes and is NOT shared between tabs.

<div class="demo-box">
  <h3>Save to Session Storage</h3>
  <input type="text" id="ss-key" placeholder="Key" value="temp-data" />
  <input type="text" id="ss-value" placeholder="Value" value="session-value" />
  <button id="ss-set">💾 Save</button>
  <button id="ss-get" style="margin-left: 10px;">📖 Load</button>
  <button id="ss-remove" style="margin-left: 10px;">🗑️ Remove</button>
  <button id="ss-clear" style="margin-left: 10px;">🧹 Clear All</button>
  <div id="ss-output" class="output"></div>
  <p style="margin-top: 1rem; color: #7f8c8d; font-style: italic;">
    💡 Open this page in a new tab - session storage won't be shared!
  </p>
</div>

<script>
(function() {
  const keyInput = document.getElementById('ss-key');
  const valueInput = document.getElementById('ss-value');
  const output = document.getElementById('ss-output');
  
  document.getElementById('ss-set').addEventListener('click', () => {
    const key = keyInput.value;
    const value = valueInput.value;
    sessionStorage.setItem(key, value);
    output.innerHTML = `<p style="color: #27ae60;">✅ Saved "${key}" = "${value}" (this tab only)</p>`;
    displayAllItems();
  });
  
  document.getElementById('ss-get').addEventListener('click', () => {
    const key = keyInput.value;
    const value = sessionStorage.getItem(key);
    if (value !== null) {
      output.innerHTML = `<p style="color: #2980b9;">📖 Retrieved "${key}" = "${value}"</p>`;
      valueInput.value = value;
    } else {
      output.innerHTML = `<p style="color: #e67e22;">⚠️ Key "${key}" not found</p>`;
    }
  });
  
  document.getElementById('ss-remove').addEventListener('click', () => {
    const key = keyInput.value;
    sessionStorage.removeItem(key);
    output.innerHTML = `<p style="color: #c0392b;">🗑️ Removed "${key}"</p>`;
    displayAllItems();
  });
  
  document.getElementById('ss-clear').addEventListener('click', () => {
    sessionStorage.clear();
    output.innerHTML = `<p style="color: #8e44ad;">🧹 Cleared all session storage</p>`;
  });
  
  function displayAllItems() {
    const items = [];
    for (let i = 0; i < sessionStorage.length; i++) {
      const key = sessionStorage.key(i);
      const value = sessionStorage.getItem(key);
      items.push(`<tr><td style="padding: 0.5rem; border: 1px solid #ddd;">${key}</td><td style="padding: 0.5rem; border: 1px solid #ddd;">${value}</td></tr>`);
    }
    
    if (items.length > 0) {
      output.innerHTML += `
        <div style="margin-top: 1rem; background: #f8f9fa; padding: 1rem; border-radius: 4px;">
          <strong>Current Session Storage (${items.length} items):</strong>
          <table style="width: 100%; margin-top: 0.5rem; border-collapse: collapse;">
            <thead><tr><th style="padding: 0.5rem; border: 1px solid #ddd; background: #e9ecef;">Key</th><th style="padding: 0.5rem; border: 1px solid #ddd; background: #e9ecef;">Value</th></tr></thead>
            <tbody>${items.join('')}</tbody>
          </table>
        </div>
      `;
    }
  }
})();
</script>

## 3. IndexedDB - Structured Object Database

IndexedDB provides a transactional database system for storing structured data, including files and blobs.

<div class="demo-box">
  <h3>IndexedDB Operations</h3>
  <input type="text" id="idb-id" placeholder="ID" value="1" />
  <input type="text" id="idb-name" placeholder="Name" value="Alice" />
  <input type="text" id="idb-email" placeholder="Email" value="alice@example.com" />
  <button id="idb-add">➕ Add</button>
  <button id="idb-get" style="margin-left: 10px;">🔍 Get by ID</button>
  <button id="idb-getall" style="margin-left: 10px;">📋 Get All</button>
  <button id="idb-delete" style="margin-left: 10px;">❌ Delete</button>
  <button id="idb-clear" style="margin-left: 10px;">🧹 Clear All</button>
  <div id="idb-output" class="output"></div>
</div>

<script>
(function() {
  let db;
  const DB_NAME = 'WizardryDemoDB';
  const STORE_NAME = 'users';
  
  // Initialize IndexedDB
  const request = indexedDB.open(DB_NAME, 1);
  
  request.onerror = () => {
    document.getElementById('idb-output').innerHTML = '<p class="error">IndexedDB not available</p>';
  };
  
  request.onsuccess = (event) => {
    db = event.target.result;
    document.getElementById('idb-output').innerHTML = '<p style="color: #27ae60;">✅ IndexedDB initialized</p>';
  };
  
  request.onupgradeneeded = (event) => {
    db = event.target.result;
    const objectStore = db.createObjectStore(STORE_NAME, { keyPath: 'id' });
    objectStore.createIndex('name', 'name', { unique: false });
    objectStore.createIndex('email', 'email', { unique: true });
  };
  
  document.getElementById('idb-add').addEventListener('click', () => {
    const transaction = db.transaction([STORE_NAME], 'readwrite');
    const objectStore = transaction.objectStore(STORE_NAME);
    const item = {
      id: parseInt(document.getElementById('idb-id').value),
      name: document.getElementById('idb-name').value,
      email: document.getElementById('idb-email').value,
      timestamp: new Date().toISOString()
    };
    
    const request = objectStore.add(item);
    request.onsuccess = () => {
      document.getElementById('idb-output').innerHTML = `<p style="color: #27ae60;">✅ Added user: ${JSON.stringify(item)}</p>`;
    };
    request.onerror = () => {
      document.getElementById('idb-output').innerHTML = '<p class="error">Error: ID already exists or invalid data</p>';
    };
  });
  
  document.getElementById('idb-get').addEventListener('click', () => {
    const transaction = db.transaction([STORE_NAME]);
    const objectStore = transaction.objectStore(STORE_NAME);
    const id = parseInt(document.getElementById('idb-id').value);
    const request = objectStore.get(id);
    
    request.onsuccess = () => {
      if (request.result) {
        document.getElementById('idb-output').innerHTML = `
          <p style="color: #2980b9;">📖 Found user:</p>
          <pre style="background: #f8f9fa; padding: 1rem; border-radius: 4px; overflow-x: auto;">${JSON.stringify(request.result, null, 2)}</pre>
        `;
      } else {
        document.getElementById('idb-output').innerHTML = `<p style="color: #e67e22;">⚠️ No user found with ID ${id}</p>`;
      }
    };
  });
  
  document.getElementById('idb-getall').addEventListener('click', () => {
    const transaction = db.transaction([STORE_NAME]);
    const objectStore = transaction.objectStore(STORE_NAME);
    const request = objectStore.getAll();
    
    request.onsuccess = () => {
      const results = request.result;
      if (results.length > 0) {
        document.getElementById('idb-output').innerHTML = `
          <p style="color: #2980b9;">📋 Found ${results.length} users:</p>
          <pre style="background: #f8f9fa; padding: 1rem; border-radius: 4px; overflow-x: auto;">${JSON.stringify(results, null, 2)}</pre>
        `;
      } else {
        document.getElementById('idb-output').innerHTML = '<p style="color: #7f8c8d;">No users in database</p>';
      }
    };
  });
  
  document.getElementById('idb-delete').addEventListener('click', () => {
    const transaction = db.transaction([STORE_NAME], 'readwrite');
    const objectStore = transaction.objectStore(STORE_NAME);
    const id = parseInt(document.getElementById('idb-id').value);
    const request = objectStore.delete(id);
    
    request.onsuccess = () => {
      document.getElementById('idb-output').innerHTML = `<p style="color: #c0392b;">🗑️ Deleted user with ID ${id}</p>`;
    };
  });
  
  document.getElementById('idb-clear').addEventListener('click', () => {
    const transaction = db.transaction([STORE_NAME], 'readwrite');
    const objectStore = transaction.objectStore(STORE_NAME);
    const request = objectStore.clear();
    
    request.onsuccess = () => {
      document.getElementById('idb-output').innerHTML = '<p style="color: #8e44ad;">🧹 Cleared all users from database</p>';
    };
  });
})();
</script>

## 4. Cookies - Client-Server State

Cookies are sent with every HTTP request and can be set with expiration times.

<div class="demo-box">
  <h3>Cookie Management</h3>
  <input type="text" id="cookie-name" placeholder="Cookie name" value="theme" />
  <input type="text" id="cookie-value" placeholder="Cookie value" value="dark" />
  <input type="number" id="cookie-days" placeholder="Days" value="7" style="width: 80px;" />
  <button id="cookie-set">🍪 Set Cookie</button>
  <button id="cookie-get" style="margin-left: 10px;">📖 Get Cookie</button>
  <button id="cookie-delete" style="margin-left: 10px;">🗑️ Delete Cookie</button>
  <button id="cookie-showall" style="margin-left: 10px;">📋 Show All</button>
  <div id="cookie-output" class="output"></div>
</div>

<script>
(function() {
  function setCookie(name, value, days) {
    let expires = "";
    if (days) {
      const date = new Date();
      date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
      expires = "; expires=" + date.toUTCString();
    }
    document.cookie = name + "=" + (value || "") + expires + "; path=/";
  }
  
  function getCookie(name) {
    const nameEQ = name + "=";
    const ca = document.cookie.split(';');
    for (let i = 0; i < ca.length; i++) {
      let c = ca[i];
      while (c.charAt(0) === ' ') c = c.substring(1, c.length);
      if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length);
    }
    return null;
  }
  
  function deleteCookie(name) {
    document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:01 GMT; path=/';
  }
  
  document.getElementById('cookie-set').addEventListener('click', () => {
    const name = document.getElementById('cookie-name').value;
    const value = document.getElementById('cookie-value').value;
    const days = parseInt(document.getElementById('cookie-days').value);
    setCookie(name, value, days);
    document.getElementById('cookie-output').innerHTML = `<p style="color: #27ae60;">✅ Set cookie "${name}" = "${value}" (expires in ${days} days)</p>`;
  });
  
  document.getElementById('cookie-get').addEventListener('click', () => {
    const name = document.getElementById('cookie-name').value;
    const value = getCookie(name);
    if (value !== null) {
      document.getElementById('cookie-output').innerHTML = `<p style="color: #2980b9;">📖 Cookie "${name}" = "${value}"</p>`;
      document.getElementById('cookie-value').value = value;
    } else {
      document.getElementById('cookie-output').innerHTML = `<p style="color: #e67e22;">⚠️ Cookie "${name}" not found</p>`;
    }
  });
  
  document.getElementById('cookie-delete').addEventListener('click', () => {
    const name = document.getElementById('cookie-name').value;
    deleteCookie(name);
    document.getElementById('cookie-output').innerHTML = `<p style="color: #c0392b;">🗑️ Deleted cookie "${name}"</p>`;
  });
  
  document.getElementById('cookie-showall').addEventListener('click', () => {
    const cookies = document.cookie;
    if (cookies) {
      const cookieList = cookies.split(';').map(c => {
        const [name, value] = c.trim().split('=');
        return `<tr><td style="padding: 0.5rem; border: 1px solid #ddd;">${name}</td><td style="padding: 0.5rem; border: 1px solid #ddd;">${value}</td></tr>`;
      }).join('');
      
      document.getElementById('cookie-output').innerHTML = `
        <div style="margin-top: 1rem; background: #f8f9fa; padding: 1rem; border-radius: 4px;">
          <strong>All Cookies:</strong>
          <table style="width: 100%; margin-top: 0.5rem; border-collapse: collapse;">
            <thead><tr><th style="padding: 0.5rem; border: 1px solid #ddd; background: #e9ecef;">Name</th><th style="padding: 0.5rem; border: 1px solid #ddd; background: #e9ecef;">Value</th></tr></thead>
            <tbody>${cookieList}</tbody>
          </table>
        </div>
      `;
    } else {
      document.getElementById('cookie-output').innerHTML = '<p style="color: #7f8c8d;">No cookies set</p>';
    }
  });
})();
</script>

## 5. Storage Quota & Usage

Check how much storage space is available and used:

<div class="demo-box">
  <button id="quota-check">📊 Check Storage Quota</button>
  <div id="quota-output" class="output"></div>
</div>

<script>
(function() {
  document.getElementById('quota-check').addEventListener('click', async () => {
    const output = document.getElementById('quota-output');
    
    if (navigator.storage && navigator.storage.estimate) {
      try {
        const estimate = await navigator.storage.estimate();
        const usage = estimate.usage || 0;
        const quota = estimate.quota || 0;
        const percentUsed = ((usage / quota) * 100).toFixed(2);
        
        output.innerHTML = `
          <div style="margin-top: 1rem; background: #e8f5e9; padding: 1rem; border-radius: 4px;">
            <h4 style="margin: 0 0 1rem 0; color: #2e7d32;">📊 Storage Quota Information</h4>
            <p style="margin: 0.25rem 0;"><strong>Used:</strong> ${(usage / 1024 / 1024).toFixed(2)} MB</p>
            <p style="margin: 0.25rem 0;"><strong>Available:</strong> ${(quota / 1024 / 1024).toFixed(2)} MB</p>
            <p style="margin: 0.25rem 0;"><strong>Percentage Used:</strong> ${percentUsed}%</p>
            <div style="margin-top: 0.5rem; background: #fff; border-radius: 4px; height: 30px; position: relative; overflow: hidden; border: 1px solid #4caf50;">
              <div style="position: absolute; left: 0; top: 0; height: 100%; background: linear-gradient(90deg, #4caf50, #8bc34a); width: ${percentUsed}%; transition: width 0.3s;"></div>
              <div style="position: absolute; left: 0; right: 0; top: 0; bottom: 0; display: flex; align-items: center; justify-content: center; font-weight: bold; color: #2e7d32; text-shadow: 0 0 3px white;">
                ${percentUsed}%
              </div>
            </div>
          </div>
        `;
        
        // Check if persistent storage is available
        if (navigator.storage.persisted) {
          const persistent = await navigator.storage.persisted();
          output.innerHTML += `
            <p style="margin-top: 0.5rem; color: ${persistent ? '#27ae60' : '#e67e22'};">
              ${persistent ? '✅' : '⚠️'} Persistent Storage: ${persistent ? 'Enabled' : 'Not Enabled'}
            </p>
          `;
        }
      } catch (error) {
        output.innerHTML = `<p class="error">Error checking quota: ${error.message}</p>`;
      }
    } else {
      output.innerHTML = '<p class="error">Storage API not supported in this browser</p>';
    }
  });
})();
</script>

---

<div class="info-box">
  <h3>🎯 Storage APIs Comparison:</h3>
  <table style="width: 100%; border-collapse: collapse; margin-top: 1rem;">
    <thead>
      <tr style="background: #e9ecef;">
        <th style="padding: 0.75rem; border: 1px solid #ddd; text-align: left;">API</th>
        <th style="padding: 0.75rem; border: 1px solid #ddd; text-align: left;">Scope</th>
        <th style="padding: 0.75rem; border: 1px solid #ddd; text-align: left;">Persistence</th>
        <th style="padding: 0.75rem; border: 1px solid #ddd; text-align: left;">Typical Size</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="padding: 0.75rem; border: 1px solid #ddd;"><strong>LocalStorage</strong></td>
        <td style="padding: 0.75rem; border: 1px solid #ddd;">Origin</td>
        <td style="padding: 0.75rem; border: 1px solid #ddd;">Permanent</td>
        <td style="padding: 0.75rem; border: 1px solid #ddd;">~5-10MB</td>
      </tr>
      <tr>
        <td style="padding: 0.75rem; border: 1px solid #ddd;"><strong>SessionStorage</strong></td>
        <td style="padding: 0.75rem; border: 1px solid #ddd;">Tab</td>
        <td style="padding: 0.75rem; border: 1px solid #ddd;">Session only</td>
        <td style="padding: 0.75rem; border: 1px solid #ddd;">~5-10MB</td>
      </tr>
      <tr>
        <td style="padding: 0.75rem; border: 1px solid #ddd;"><strong>IndexedDB</strong></td>
        <td style="padding: 0.75rem; border: 1px solid #ddd;">Origin</td>
        <td style="padding: 0.75rem; border: 1px solid #ddd;">Permanent</td>
        <td style="padding: 0.75rem; border: 1px solid #ddd;">~50MB-unlimited</td>
      </tr>
      <tr>
        <td style="padding: 0.75rem; border: 1px solid #ddd;"><strong>Cookies</strong></td>
        <td style="padding: 0.75rem; border: 1px solid #ddd;">Origin</td>
        <td style="padding: 0.75rem; border: 1px solid #ddd;">Configurable</td>
        <td style="padding: 0.75rem; border: 1px solid #ddd;">~4KB per cookie</td>
      </tr>
    </tbody>
  </table>
  
  <p style="margin-top: 1rem;"><strong>💡 When to use each:</strong></p>
  <ul>
    <li><strong>LocalStorage:</strong> Simple key-value data that needs to persist</li>
    <li><strong>SessionStorage:</strong> Temporary data specific to one tab/session</li>
    <li><strong>IndexedDB:</strong> Large amounts of structured data, offline apps</li>
    <li><strong>Cookies:</strong> Data that needs to be sent to server with requests</li>
  </ul>
</div>
