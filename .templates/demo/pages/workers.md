---
title: Workers & Background Processing
---

# Workers & Background Processing Demos

Explore browser APIs for running JavaScript in background threads without blocking the UI.

## 1. Web Workers - Background Threads

Web Workers allow you to run JavaScript in background threads, separate from the main UI thread:

<div class="demo-box">
  <h3>⚙️ Web Worker Demo</h3>
  
  <div style="margin-bottom: 1rem;">
    <label style="display: block; margin-bottom: 0.5rem;"><strong>Calculate Fibonacci Number:</strong></label>
    <input type="number" id="fib-input" value="40" min="1" max="45" style="width: 100px; padding: 0.5rem; margin-right: 0.5rem;" />
    <button id="fib-worker-btn" style="margin-right: 0.5rem;">🧵 Calculate in Worker</button>
    <button id="fib-main-btn">🔴 Calculate in Main Thread (blocks UI)</button>
  </div>
  
  <div style="margin-bottom: 1rem;">
    <button id="test-ui-btn" style="background: #e67e22; color: white; border: none; padding: 0.5rem 1rem; border-radius: 4px; cursor: pointer;">
      🧪 Test UI Responsiveness (click me repeatedly)
    </button>
    <span id="ui-counter" style="margin-left: 1rem; font-weight: bold;">Clicks: 0</span>
  </div>
  
  <div id="worker-output" class="output"></div>
</div>

<script>
(function() {
  const fibInput = document.getElementById('fib-input');
  const output = document.getElementById('worker-output');
  const uiCounter = document.getElementById('ui-counter');
  let clickCount = 0;
  
  // Test UI responsiveness
  document.getElementById('test-ui-btn').addEventListener('click', () => {
    clickCount++;
    uiCounter.textContent = `Clicks: ${clickCount}`;
  });
  
  // Fibonacci calculation function (runs slowly)
  function fibonacci(n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
  }
  
  // Main thread calculation (blocks UI)
  document.getElementById('fib-main-btn').addEventListener('click', () => {
    const n = parseInt(fibInput.value);
    output.innerHTML = '<p style="color: #e67e22;">🔴 Calculating in main thread (UI will freeze)...</p>';
    
    // Use setTimeout to allow UI to update
    setTimeout(() => {
      const start = performance.now();
      const result = fibonacci(n);
      const duration = performance.now() - start;
      
      output.innerHTML = `
        <div style="background: #fff3e0; padding: 1rem; border-radius: 4px; border: 1px solid #ff9800;">
          <h4 style="margin: 0 0 0.5rem 0; color: #e65100;">🔴 Main Thread Result</h4>
          <p style="margin: 0.25rem 0;"><strong>Fibonacci(${n}):</strong> ${result}</p>
          <p style="margin: 0.25rem 0;"><strong>Duration:</strong> ${duration.toFixed(2)} ms</p>
          <p style="margin: 0.25rem 0; color: #e65100;"><strong>⚠️ UI was blocked during calculation!</strong></p>
        </div>
      `;
    }, 100);
  });
  
  // Web Worker calculation (non-blocking)
  document.getElementById('fib-worker-btn').addEventListener('click', () => {
    const n = parseInt(fibInput.value);
    output.innerHTML = '<p style="color: #2980b9;">🧵 Calculating in Web Worker (UI remains responsive)...</p>';
    
    // Create worker from inline code
    const workerCode = `
      self.addEventListener('message', function(e) {
        const n = e.data;
        const start = performance.now();
        
        function fibonacci(n) {
          if (n <= 1) return n;
          return fibonacci(n - 1) + fibonacci(n - 2);
        }
        
        const result = fibonacci(n);
        const duration = performance.now() - start;
        
        self.postMessage({ result, duration });
      });
    `;
    
    const blob = new Blob([workerCode], { type: 'application/javascript' });
    const workerUrl = URL.createObjectURL(blob);
    const worker = new Worker(workerUrl);
    
    const start = performance.now();
    
    worker.addEventListener('message', (e) => {
      const { result, duration } = e.data;
      const totalDuration = performance.now() - start;
      
      output.innerHTML = `
        <div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
          <h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">🧵 Web Worker Result</h4>
          <p style="margin: 0.25rem 0;"><strong>Fibonacci(${n}):</strong> ${result}</p>
          <p style="margin: 0.25rem 0;"><strong>Calculation Time:</strong> ${duration.toFixed(2)} ms</p>
          <p style="margin: 0.25rem 0;"><strong>Total Time (incl. overhead):</strong> ${totalDuration.toFixed(2)} ms</p>
          <p style="margin: 0.25rem 0; color: #2e7d32;"><strong>✅ UI remained responsive during calculation!</strong></p>
        </div>
      `;
      
      worker.terminate();
      URL.revokeObjectURL(workerUrl);
    });
    
    worker.addEventListener('error', (e) => {
      output.innerHTML = `<p class="error">Worker error: ${e.message}</p>`;
      worker.terminate();
      URL.revokeObjectURL(workerUrl);
    });
    
    worker.postMessage(n);
  });
})();
</script>

## 2. Service Workers - Network Interception

Service Workers can intercept network requests and manage caching for offline functionality:

<div class="demo-box">
  <h3>🔧 Service Worker Status</h3>
  
  <button id="sw-register">📝 Register Service Worker</button>
  <button id="sw-unregister" style="margin-left: 0.5rem;">❌ Unregister</button>
  <button id="sw-check" style="margin-left: 0.5rem;">🔍 Check Status</button>
  
  <div id="sw-output" class="output"></div>
</div>

<script>
(function() {
  const output = document.getElementById('sw-output');
  
  function checkServiceWorkerSupport() {
    if (!('serviceWorker' in navigator)) {
      output.innerHTML = '<p class="error">❌ Service Workers not supported in this browser</p>';
      return false;
    }
    return true;
  }
  
  document.getElementById('sw-register').addEventListener('click', async () => {
    if (!checkServiceWorkerSupport()) return;
    
    output.innerHTML = '<p style="color: #2980b9;">📝 Registering Service Worker...</p>';
    
    try {
      // Create a simple service worker inline
      const swCode = `
        self.addEventListener('install', (event) => {
          console.log('Service Worker installing...');
          self.skipWaiting();
        });
        
        self.addEventListener('activate', (event) => {
          console.log('Service Worker activated');
          return self.clients.claim();
        });
        
        self.addEventListener('fetch', (event) => {
          console.log('Fetch intercepted:', event.request.url);
          // Pass through all requests (we're just demonstrating interception)
          event.respondWith(fetch(event.request));
        });
      `;
      
      const blob = new Blob([swCode], { type: 'application/javascript' });
      const swUrl = URL.createObjectURL(blob);
      
      const registration = await navigator.serviceWorker.register(swUrl);
      
      output.innerHTML = `
        <div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
          <h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ Service Worker Registered</h4>
          <p style="margin: 0.25rem 0;"><strong>Scope:</strong> ${registration.scope}</p>
          <p style="margin: 0.25rem 0;"><strong>State:</strong> ${registration.active ? 'Active' : 'Installing'}</p>
          <p style="margin: 0.25rem 0; color: #666; font-size: 0.9rem;">
            💡 The Service Worker is now intercepting network requests for this origin.
          </p>
        </div>
      `;
    } catch (error) {
      output.innerHTML = `<p class="error">Registration failed: ${error.message}</p>`;
    }
  });
  
  document.getElementById('sw-unregister').addEventListener('click', async () => {
    if (!checkServiceWorkerSupport()) return;
    
    try {
      const registration = await navigator.serviceWorker.getRegistration();
      if (registration) {
        await registration.unregister();
        output.innerHTML = '<p style="color: #27ae60;">✅ Service Worker unregistered</p>';
      } else {
        output.innerHTML = '<p style="color: #7f8c8d;">No Service Worker registered</p>';
      }
    } catch (error) {
      output.innerHTML = `<p class="error">Unregister failed: ${error.message}</p>`;
    }
  });
  
  document.getElementById('sw-check').addEventListener('click', async () => {
    if (!checkServiceWorkerSupport()) return;
    
    try {
      const registration = await navigator.serviceWorker.getRegistration();
      if (registration) {
        const state = registration.active ? 'Active' : 
                     registration.installing ? 'Installing' : 
                     registration.waiting ? 'Waiting' : 'Unknown';
        
        output.innerHTML = `
          <div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3;">
            <h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">🔍 Service Worker Status</h4>
            <p style="margin: 0.25rem 0;"><strong>Registered:</strong> Yes</p>
            <p style="margin: 0.25rem 0;"><strong>State:</strong> ${state}</p>
            <p style="margin: 0.25rem 0;"><strong>Scope:</strong> ${registration.scope}</p>
          </div>
        `;
      } else {
        output.innerHTML = '<p style="color: #7f8c8d;">No Service Worker registered</p>';
      }
    } catch (error) {
      output.innerHTML = `<p class="error">Check failed: ${error.message}</p>`;
    }
  });
  
  // Initial check
  if (checkServiceWorkerSupport()) {
    navigator.serviceWorker.getRegistration().then(registration => {
      if (registration) {
        output.innerHTML = '<p style="color: #2980b9;">ℹ️ A Service Worker is currently registered. Click "Check Status" for details.</p>';
      }
    });
  }
})();
</script>

## 3. Message Passing Between Worker and Main Thread

Demonstrate bidirectional communication between workers and the main thread:

<div class="demo-box">
  <h3>💬 Worker Communication</h3>
  
  <div style="margin-bottom: 1rem;">
    <input type="text" id="msg-input" placeholder="Send message to worker..." style="width: 70%; padding: 0.5rem; margin-right: 0.5rem;" />
    <button id="msg-send">📤 Send</button>
  </div>
  
  <div id="msg-output" class="output"></div>
</div>

<script>
(function() {
  const msgInput = document.getElementById('msg-input');
  const output = document.getElementById('msg-output');
  let messageWorker = null;
  let messageLog = [];
  
  // Create worker
  const workerCode = `
    self.addEventListener('message', function(e) {
      const msg = e.data;
      
      // Process message
      const response = {
        original: msg,
        processed: msg.toUpperCase().split('').reverse().join(''),
        timestamp: new Date().toISOString(),
        length: msg.length
      };
      
      // Send response back to main thread
      self.postMessage(response);
    });
  `;
  
  const blob = new Blob([workerCode], { type: 'application/javascript' });
  const workerUrl = URL.createObjectURL(blob);
  messageWorker = new Worker(workerUrl);
  
  messageWorker.addEventListener('message', (e) => {
    const response = e.data;
    messageLog.unshift({
      type: 'received',
      data: response
    });
    
    if (messageLog.length > 5) messageLog = messageLog.slice(0, 5);
    updateMessageLog();
  });
  
  function updateMessageLog() {
    const logHTML = messageLog.map((msg, idx) => {
      if (msg.type === 'sent') {
        return `
          <div style="padding: 0.75rem; margin: 0.5rem 0; background: #e3f2fd; border-left: 4px solid #2196f3; border-radius: 3px;">
            <div style="font-weight: bold; color: #1565c0;">📤 Sent to Worker:</div>
            <div style="margin-top: 0.25rem; font-family: monospace;">"${msg.data}"</div>
          </div>
        `;
      } else {
        return `
          <div style="padding: 0.75rem; margin: 0.5rem 0; background: #e8f5e9; border-left: 4px solid #4caf50; border-radius: 3px;">
            <div style="font-weight: bold; color: #2e7d32;">📥 Received from Worker:</div>
            <div style="margin-top: 0.25rem;">
              <div><strong>Original:</strong> "${msg.data.original}"</div>
              <div><strong>Processed:</strong> "${msg.data.processed}"</div>
              <div style="font-size: 0.9rem; color: #666;">Length: ${msg.data.length} chars | ${new Date(msg.data.timestamp).toLocaleTimeString()}</div>
            </div>
          </div>
        `;
      }
    }).join('');
    
    output.innerHTML = logHTML || '<p style="color: #7f8c8d;">No messages yet. Send a message to the worker!</p>';
  }
  
  document.getElementById('msg-send').addEventListener('click', () => {
    const message = msgInput.value;
    if (!message) return;
    
    messageLog.unshift({
      type: 'sent',
      data: message
    });
    
    if (messageLog.length > 10) messageLog = messageLog.slice(0, 10);
    updateMessageLog();
    
    messageWorker.postMessage(message);
    msgInput.value = '';
  });
  
  msgInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
      document.getElementById('msg-send').click();
    }
  });
  
  // Initial message
  output.innerHTML = '<p style="color: #2980b9;">💬 Worker ready. Type a message and click Send!</p>';
})();
</script>

---

<div class="info-box">
  <h3>🎯 Worker APIs Demonstrated:</h3>
  <ul>
    <li><strong>Web Workers:</strong> Background JavaScript execution without blocking UI</li>
    <li><strong>Service Workers:</strong> Network request interception and offline capabilities</li>
    <li><strong>Message Passing:</strong> Bidirectional communication via postMessage</li>
    <li><strong>Worker Lifecycle:</strong> Creation, termination, and error handling</li>
  </ul>
  
  <p style="margin-top: 1rem;"><strong>💡 Use Cases:</strong></p>
  <ul>
    <li><strong>Web Workers:</strong> Heavy computations, data processing, image manipulation</li>
    <li><strong>Service Workers:</strong> Offline functionality, background sync, push notifications</li>
    <li><strong>Message Passing:</strong> Coordinating work between main thread and workers</li>
  </ul>
  
  <p style="margin-top: 1rem; padding: 1rem; background: #fff3cd; border-radius: 4px; border: 1px solid #ffc107;">
    <strong>⚠️ Shared Workers Skipped:</strong> Shared Workers (🔴 deep) allow multiple tabs/windows to share a single worker instance. They have limited browser support and complex lifecycle management, so they're not included in this demo.
  </p>
</div>
