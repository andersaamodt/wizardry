---
title: Additional Browser APIs
---

# Additional Browser APIs

Explore more useful browser capabilities beyond the core APIs.

## 1. Vibration API

Control device vibration (mobile devices):

<div class="demo-box">
  <h3>📳 Vibration API</h3>
  
  <div style="margin-bottom: 1rem; display: flex; gap: 0.5rem; flex-wrap: wrap;">
    <button id="vibrate-short">📳 Short Vibration (200ms)</button>
    <button id="vibrate-long">📳 Long Vibration (1000ms)</button>
    <button id="vibrate-pattern">🎵 Pattern Vibration</button>
    <button id="vibrate-stop">⏹️ Stop</button>
  </div>
  
  <div id="vibrate-output" class="output"></div>
</div>

<script>
(function() {
  const output = document.getElementById('vibrate-output');
  
  function checkSupport() {
    if (!('vibrate' in navigator)) {
      output.innerHTML = `
        <div style="background: #fff3e0; padding: 1rem; border-radius: 4px; border: 1px solid #ff9800;">
          <h4 style="margin: 0 0 0.5rem 0; color: #e65100;">⚠️ Vibration API Not Supported</h4>
          <p style="margin: 0;">This device does not support the Vibration API. Try on a mobile device.</p>
        </div>
      `;
      return false;
    }
    return true;
  }
  
  document.getElementById('vibrate-short').addEventListener('click', () => {
    if (!checkSupport()) return;
    navigator.vibrate(200);
    output.innerHTML = '<p style="color: #2980b9;">📳 Vibrating for 200ms</p>';
  });
  
  document.getElementById('vibrate-long').addEventListener('click', () => {
    if (!checkSupport()) return;
    navigator.vibrate(1000);
    output.innerHTML = '<p style="color: #2980b9;">📳 Vibrating for 1000ms</p>';
  });
  
  document.getElementById('vibrate-pattern').addEventListener('click', () => {
    if (!checkSupport()) return;
    // Pattern: vibrate 200ms, pause 100ms, vibrate 200ms, pause 100ms, vibrate 200ms
    navigator.vibrate([200, 100, 200, 100, 200]);
    output.innerHTML = '<p style="color: #8e44ad;">🎵 Vibration pattern: 200ms x 3 with 100ms pauses</p>';
  });
  
  document.getElementById('vibrate-stop').addEventListener('click', () => {
    if (!checkSupport()) return;
    navigator.vibrate(0);
    output.innerHTML = '<p style="color: #7f8c8d;">⏹️ Vibration stopped</p>';
  });
})();
</script>

## 2. Battery Status API

Monitor device battery level and charging status:

<div class="demo-box">
  <h3>🔋 Battery Status</h3>
  
  <button id="battery-check">🔋 Check Battery Status</button>
  
  <div id="battery-output" class="output"></div>
</div>

<script>
(function() {
  const output = document.getElementById('battery-output');
  
  document.getElementById('battery-check').addEventListener('click', async () => {
    if (!('getBattery' in navigator)) {
      output.innerHTML = `
        <div style="background: #fff3e0; padding: 1rem; border-radius: 4px; border: 1px solid #ff9800;">
          <h4 style="margin: 0 0 0.5rem 0; color: #e65100;">⚠️ Battery API Not Supported</h4>
          <p style="margin: 0;">This browser does not support the Battery Status API.</p>
        </div>
      `;
      return;
    }
    
    try {
      const battery = await navigator.getBattery();
      
      const level = (battery.level * 100).toFixed(0);
      const charging = battery.charging;
      const chargingTime = battery.chargingTime;
      const dischargingTime = battery.dischargingTime;
      
      const batteryIcon = level > 75 ? '🔋' : level > 50 ? '🔋' : level > 25 ? '🪫' : '🪫';
      const statusColor = charging ? '#4caf50' : level > 25 ? '#2196f3' : '#f44336';
      
      output.innerHTML = `
        <div style="background: ${charging ? '#e8f5e9' : '#e3f2fd'}; padding: 1rem; border-radius: 4px; border: 1px solid ${statusColor};">
          <h4 style="margin: 0 0 0.5rem 0; color: ${statusColor};">${batteryIcon} Battery Status</h4>
          <p style="margin: 0.25rem 0;"><strong>Level:</strong> ${level}%</p>
          <div style="margin: 0.5rem 0; background: #fff; border-radius: 4px; height: 30px; position: relative; overflow: hidden; border: 1px solid ${statusColor};">
            <div style="position: absolute; left: 0; top: 0; height: 100%; background: ${charging ? 'linear-gradient(90deg, #4caf50, #8bc34a)' : 'linear-gradient(90deg, #2196f3, #03a9f4)'}; width: ${level}%; transition: width 0.3s;"></div>
            <div style="position: absolute; left: 0; right: 0; top: 0; bottom: 0; display: flex; align-items: center; justify-content: center; font-weight: bold; color: #2c3e50;">
              ${level}%
            </div>
          </div>
          <p style="margin: 0.25rem 0;"><strong>Charging:</strong> ${charging ? '⚡ Yes' : '❌ No'}</p>
          ${charging && chargingTime !== Infinity ? `<p style="margin: 0.25rem 0;"><strong>Time to Full:</strong> ${Math.round(chargingTime / 60)} minutes</p>` : ''}
          ${!charging && dischargingTime !== Infinity ? `<p style="margin: 0.25rem 0;"><strong>Time Remaining:</strong> ${Math.round(dischargingTime / 60)} minutes</p>` : ''}
        </div>
      `;
      
      // Listen for changes
      battery.addEventListener('levelchange', () => {
        document.getElementById('battery-check').click();
      });
      
      battery.addEventListener('chargingchange', () => {
        document.getElementById('battery-check').click();
      });
    } catch (error) {
      output.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
})();
</script>

## 3. Network Information API

Get information about the network connection:

<div class="demo-box">
  <h3>📶 Network Information</h3>
  
  <button id="network-check">📶 Check Network</button>
  
  <div id="network-output" class="output"></div>
</div>

<script>
(function() {
  const output = document.getElementById('network-output');
  
  function updateNetworkInfo() {
    const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
    
    if (!connection) {
      output.innerHTML = `
        <div style="background: #fff3e0; padding: 1rem; border-radius: 4px; border: 1px solid #ff9800;">
          <h4 style="margin: 0 0 0.5rem 0; color: #e65100;">⚠️ Network Information API Not Supported</h4>
          <p style="margin: 0;">This browser does not support the Network Information API.</p>
        </div>
      `;
      return;
    }
    
    const type = connection.effectiveType || connection.type || 'unknown';
    const downlink = connection.downlink;
    const rtt = connection.rtt;
    const saveData = connection.saveData;
    
    const typeColors = {
      'slow-2g': '#f44336',
      '2g': '#ff9800',
      '3g': '#ffc107',
      '4g': '#4caf50',
      '5g': '#2196f3',
      'wifi': '#2196f3',
      'ethernet': '#4caf50'
    };
    
    const color = typeColors[type] || '#7f8c8d';
    
    output.innerHTML = `
      <div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid ${color};">
        <h4 style="margin: 0 0 0.5rem 0; color: ${color};">📶 Network Status</h4>
        <p style="margin: 0.25rem 0;"><strong>Connection Type:</strong> ${type.toUpperCase()}</p>
        ${downlink ? `<p style="margin: 0.25rem 0;"><strong>Downlink:</strong> ${downlink} Mbps</p>` : ''}
        ${rtt ? `<p style="margin: 0.25rem 0;"><strong>Round-Trip Time:</strong> ${rtt} ms</p>` : ''}
        <p style="margin: 0.25rem 0;"><strong>Data Saver:</strong> ${saveData ? '✅ Enabled' : '❌ Disabled'}</p>
        <p style="margin: 0.5rem 0 0 0; color: #666; font-size: 0.9rem;">
          ${type === '4g' || type === '5g' || type === 'wifi' || type === 'ethernet' ? '✅ Fast connection detected' : '⚠️ Slow connection - consider reducing data usage'}
        </p>
      </div>
    `;
  }
  
  document.getElementById('network-check').addEventListener('click', updateNetworkInfo);
  
  // Listen for network changes
  const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
  if (connection) {
    connection.addEventListener('change', updateNetworkInfo);
  }
})();
</script>

## 4. Wake Lock API

Prevent screen from sleeping (useful for presentations, recipes, etc.):

<div class="demo-box">
  <h3>🔆 Wake Lock</h3>
  
  <div style="margin-bottom: 1rem;">
    <button id="wakelock-request">🔆 Request Wake Lock</button>
    <button id="wakelock-release" style="margin-left: 0.5rem;">💤 Release</button>
  </div>
  
  <div id="wakelock-output" class="output"></div>
</div>

<script>
(function() {
  const output = document.getElementById('wakelock-output');
  let wakeLock = null;
  
  document.getElementById('wakelock-request').addEventListener('click', async () => {
    if (!('wakeLock' in navigator)) {
      output.innerHTML = `
        <div style="background: #fff3e0; padding: 1rem; border-radius: 4px; border: 1px solid #ff9800;">
          <h4 style="margin: 0 0 0.5rem 0; color: #e65100;">⚠️ Wake Lock API Not Supported</h4>
          <p style="margin: 0;">This browser does not support the Wake Lock API.</p>
        </div>
      `;
      return;
    }
    
    try {
      wakeLock = await navigator.wakeLock.request('screen');
      
      output.innerHTML = `
        <div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
          <h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">🔆 Wake Lock Active</h4>
          <p style="margin: 0;">Screen will stay on until wake lock is released or tab loses focus.</p>
        </div>
      `;
      
      wakeLock.addEventListener('release', () => {
        output.innerHTML = '<p style="color: #7f8c8d;">💤 Wake lock released</p>';
      });
    } catch (error) {
      output.innerHTML = `
        <div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
          <h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ Wake Lock Failed</h4>
          <p style="margin: 0;"><strong>Error:</strong> ${error.message}</p>
        </div>
      `;
    }
  });
  
  document.getElementById('wakelock-release').addEventListener('click', async () => {
    if (wakeLock) {
      await wakeLock.release();
      wakeLock = null;
      output.innerHTML = '<p style="color: #2980b9;">💤 Wake lock manually released</p>';
    } else {
      output.innerHTML = '<p style="color: #7f8c8d;">No active wake lock</p>';
    }
  });
})();
</script>

## 5. Page Lifecycle API

Monitor page lifecycle states (active, passive, hidden, frozen, terminated):

<div class="demo-box">
  <h3>🔄 Page Lifecycle</h3>
  
  <div id="lifecycle-status" style="padding: 1rem; border-radius: 4px; font-size: 1.2rem; font-weight: bold; text-align: center; margin-bottom: 1rem;"></div>
  
  <div id="lifecycle-output" class="output"></div>
</div>

<script>
(function() {
  const status = document.getElementById('lifecycle-status');
  const output = document.getElementById('lifecycle-output');
  let eventLog = [];
  
  function updateLifecycle(event) {
    const timestamp = new Date().toLocaleTimeString();
    const state = document.visibilityState;
    
    // Update current status
    const colors = {
      visible: '#4caf50',
      hidden: '#ff9800'
    };
    
    status.style.background = state === 'visible' ? '#e8f5e9' : '#fff3e0';
    status.style.color = colors[state] || '#7f8c8d';
    status.style.border = `2px solid ${colors[state] || '#7f8c8d'}`;
    status.textContent = `Page State: ${state.toUpperCase()}`;
    
    // Log event
    if (event) {
      eventLog.unshift({
        time: timestamp,
        event: event.type,
        state: state
      });
      
      if (eventLog.length > 10) eventLog = eventLog.slice(0, 10);
      
      const logHTML = eventLog.map((evt, idx) => {
        const color = evt.state === 'visible' ? '#4caf50' : '#ff9800';
        return `
          <div style="padding: 0.5rem; margin: 0.25rem 0; background: ${idx === 0 ? '#fff3cd' : '#f8f9fa'}; border-left: 3px solid ${color}; border-radius: 3px; font-size: 0.9rem;">
            <strong>${evt.time}</strong>: ${evt.event} → ${evt.state}
          </div>
        `;
      }).join('');
      
      output.innerHTML = `
        <div>
          <strong>Event Log:</strong>
          ${logHTML}
        </div>
      `;
    }
  }
  
  // Listen to lifecycle events
  document.addEventListener('visibilitychange', updateLifecycle);
  window.addEventListener('focus', updateLifecycle);
  window.addEventListener('blur', updateLifecycle);
  
  // Initial state
  updateLifecycle(null);
  
  output.innerHTML = `
    <p style="color: #2980b9;">
      Try switching tabs, minimizing the browser, or bringing it to focus to see lifecycle events.
    </p>
  `;
})();
</script>

---

<div class="info-box">
  <h3>🎯 Additional APIs Demonstrated:</h3>
  <ul>
    <li><strong>Vibration API:</strong> Control device vibration patterns (mobile only)</li>
    <li><strong>Battery Status:</strong> Monitor battery level and charging status</li>
    <li><strong>Network Information:</strong> Detect connection type and quality</li>
    <li><strong>Wake Lock:</strong> Prevent screen from sleeping</li>
    <li><strong>Page Lifecycle:</strong> Monitor page visibility and focus states</li>
  </ul>
  
  <p style="margin-top: 1rem;"><strong>💡 Use Cases:</strong></p>
  <ul>
    <li><strong>Vibration:</strong> Game feedback, notifications, tactile UI</li>
    <li><strong>Battery:</strong> Adaptive features based on battery level</li>
    <li><strong>Network:</strong> Adaptive content quality, offline fallbacks</li>
    <li><strong>Wake Lock:</strong> Presentations, recipes, games, video playback</li>
    <li><strong>Lifecycle:</strong> Pause animations/updates when hidden, save battery</li>
  </ul>
  
  <p style="margin-top: 1rem;"><strong>⚠️ Browser Support:</strong></p>
  <ul>
    <li><strong>Vibration:</strong> Mobile browsers (Chrome, Firefox, Safari)</li>
    <li><strong>Battery:</strong> Chrome, Edge (deprecated in some browsers)</li>
    <li><strong>Network Information:</strong> Chrome, Edge, Opera</li>
    <li><strong>Wake Lock:</strong> Chrome, Edge, Opera (HTTPS required)</li>
    <li><strong>Page Lifecycle:</strong> All modern browsers</li>
  </ul>
</div>
