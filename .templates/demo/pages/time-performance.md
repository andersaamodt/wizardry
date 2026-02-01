---
title: Time & Performance Demos
---

# Time & Performance Demos

Explore browser timing APIs and performance measurement tools.

## 1. Timers - setTimeout & setInterval

Schedule code execution with delays and intervals:

<div class="demo-box">
  <h3>⏰ JavaScript Timers</h3>
  
  <div style="display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 1rem;">
    <button id="timer-delay">⏱️ Delayed Action (2s)</button>
    <button id="timer-start-interval">▶️ Start Interval (1s)</button>
    <button id="timer-stop-interval">⏹️ Stop Interval</button>
    <button id="timer-clear">🧹 Clear</button>
  </div>
  
  <div id="timer-output" class="output"></div>
</div>

<script>
(function() {
  const output = document.getElementById('timer-output');
  let intervalId = null;
  let count = 0;
  
  document.getElementById('timer-delay').addEventListener('click', () => {
    output.innerHTML = '<p style="color: #e67e22;">⏳ Waiting 2 seconds...</p>';
    setTimeout(() => {
      output.innerHTML = '<p style="color: #27ae60;">✅ Delayed action executed after 2 seconds!</p>';
    }, 2000);
  });
  
  document.getElementById('timer-start-interval').addEventListener('click', () => {
    if (intervalId) {
      output.innerHTML = '<p class="error">Interval already running</p>';
      return;
    }
    count = 0;
    intervalId = setInterval(() => {
      count++;
      output.innerHTML = `<p style="color: #2980b9;">🔄 Interval tick ${count}</p>`;
    }, 1000);
    output.innerHTML = '<p style="color: #27ae60;">▶️ Started interval (1 second ticks)</p>';
  });
  
  document.getElementById('timer-stop-interval').addEventListener('click', () => {
    if (intervalId) {
      clearInterval(intervalId);
      intervalId = null;
      output.innerHTML = `<p style="color: #c0392b;">⏹️ Stopped interval after ${count} ticks</p>`;
    } else {
      output.innerHTML = '<p class="error">No interval running</p>';
    }
  });
  
  document.getElementById('timer-clear').addEventListener('click', () => {
    if (intervalId) {
      clearInterval(intervalId);
      intervalId = null;
    }
    count = 0;
    output.innerHTML = '<p style="color: #7f8c8d;">🧹 Cleared</p>';
  });
})();
</script>

## 2. requestAnimationFrame - Smooth Animations

Use requestAnimationFrame for frame-synchronized animations:

<div class="demo-box">
  <h3>🎬 Animation Frame Demo</h3>
  
  <canvas id="anim-canvas" width="600" height="200" style="border: 2px solid #ddd; border-radius: 4px; max-width: 100%; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);"></canvas>
  
  <div style="margin-top: 1rem; display: flex; gap: 0.5rem; flex-wrap: wrap;">
    <button id="anim-start">▶️ Start Animation</button>
    <button id="anim-stop">⏹️ Stop Animation</button>
    <button id="anim-reset">🔄 Reset</button>
  </div>
  
  <div id="anim-output" class="output"></div>
</div>

<script>
(function() {
  const canvas = document.getElementById('anim-canvas');
  const ctx = canvas.getContext('2d');
  const output = document.getElementById('anim-output');
  
  let animationId = null;
  let x = 0;
  let startTime = null;
  let frameCount = 0;
  
  function animate(timestamp) {
    if (!startTime) startTime = timestamp;
    const elapsed = timestamp - startTime;
    
    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Draw gradient background
    const gradient = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
    gradient.addColorStop(0, '#667eea');
    gradient.addColorStop(1, '#764ba2');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    // Draw animated circle
    ctx.fillStyle = '#fff';
    ctx.beginPath();
    const radius = 20;
    const y = canvas.height / 2;
    x = (x + 2) % (canvas.width + radius * 2) - radius;
    ctx.arc(x, y, radius, 0, Math.PI * 2);
    ctx.fill();
    
    // Draw trail
    ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
    for (let i = 1; i <= 5; i++) {
      const trailX = x - i * 25;
      if (trailX >= -radius) {
        ctx.beginPath();
        ctx.arc(trailX, y, radius * (1 - i * 0.15), 0, Math.PI * 2);
        ctx.fill();
      }
    }
    
    frameCount++;
    const fps = (frameCount / (elapsed / 1000)).toFixed(1);
    
    // Draw FPS
    ctx.fillStyle = 'rgba(255, 255, 255, 0.9)';
    ctx.font = '14px monospace';
    ctx.fillText(`FPS: ${fps}`, 10, 20);
    ctx.fillText(`Frame: ${frameCount}`, 10, 40);
    
    animationId = requestAnimationFrame(animate);
  }
  
  document.getElementById('anim-start').addEventListener('click', () => {
    if (animationId) {
      output.innerHTML = '<p class="error">Animation already running</p>';
      return;
    }
    startTime = null;
    animationId = requestAnimationFrame(animate);
    output.innerHTML = '<p style="color: #27ae60;">▶️ Animation started</p>';
  });
  
  document.getElementById('anim-stop').addEventListener('click', () => {
    if (animationId) {
      cancelAnimationFrame(animationId);
      animationId = null;
      output.innerHTML = `<p style="color: #c0392b;">⏹️ Animation stopped at frame ${frameCount}</p>`;
    } else {
      output.innerHTML = '<p class="error">No animation running</p>';
    }
  });
  
  document.getElementById('anim-reset').addEventListener('click', () => {
    if (animationId) {
      cancelAnimationFrame(animationId);
      animationId = null;
    }
    x = 0;
    frameCount = 0;
    startTime = null;
    
    // Clear and redraw initial state
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    const gradient = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
    gradient.addColorStop(0, '#667eea');
    gradient.addColorStop(1, '#764ba2');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    output.innerHTML = '<p style="color: #7f8c8d;">🔄 Animation reset</p>';
  });
})();
</script>

## 3. Performance API - High-Resolution Timing

Measure code execution time with microsecond precision:

<div class="demo-box">
  <h3>⚡ Performance Measurement</h3>
  
  <div style="display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 1rem;">
    <button id="perf-measure-fast">📊 Measure Fast Operation</button>
    <button id="perf-measure-slow">📊 Measure Slow Operation</button>
    <button id="perf-show-marks">📋 Show All Marks</button>
    <button id="perf-clear">🧹 Clear Marks</button>
  </div>
  
  <div id="perf-output" class="output"></div>
</div>

<script>
(function() {
  const output = document.getElementById('perf-output');
  
  function heavyComputation(iterations) {
    let result = 0;
    for (let i = 0; i < iterations; i++) {
      result += Math.sqrt(i) * Math.sin(i);
    }
    return result;
  }
  
  document.getElementById('perf-measure-fast').addEventListener('click', () => {
    performance.mark('fast-start');
    const result = heavyComputation(10000);
    performance.mark('fast-end');
    performance.measure('fast-operation', 'fast-start', 'fast-end');
    
    const measure = performance.getEntriesByName('fast-operation')[0];
    output.innerHTML = `
      <div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
        <h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">⚡ Fast Operation (10,000 iterations)</h4>
        <p style="margin: 0.25rem 0;"><strong>Duration:</strong> ${measure.duration.toFixed(3)} ms</p>
        <p style="margin: 0.25rem 0;"><strong>Start Time:</strong> ${measure.startTime.toFixed(3)} ms</p>
        <p style="margin: 0.25rem 0;"><strong>Result:</strong> ${result.toFixed(2)}</p>
      </div>
    `;
  });
  
  document.getElementById('perf-measure-slow').addEventListener('click', () => {
    performance.mark('slow-start');
    const result = heavyComputation(1000000);
    performance.mark('slow-end');
    performance.measure('slow-operation', 'slow-start', 'slow-end');
    
    const measure = performance.getEntriesByName('slow-operation')[0];
    output.innerHTML = `
      <div style="background: #fff3e0; padding: 1rem; border-radius: 4px; border: 1px solid #ff9800;">
        <h4 style="margin: 0 0 0.5rem 0; color: #e65100;">🐌 Slow Operation (1,000,000 iterations)</h4>
        <p style="margin: 0.25rem 0;"><strong>Duration:</strong> ${measure.duration.toFixed(3)} ms</p>
        <p style="margin: 0.25rem 0;"><strong>Start Time:</strong> ${measure.startTime.toFixed(3)} ms</p>
        <p style="margin: 0.25rem 0;"><strong>Result:</strong> ${result.toFixed(2)}</p>
      </div>
    `;
  });
  
  document.getElementById('perf-show-marks').addEventListener('click', () => {
    const marks = performance.getEntriesByType('mark');
    const measures = performance.getEntriesByType('measure');
    
    if (marks.length === 0 && measures.length === 0) {
      output.innerHTML = '<p style="color: #7f8c8d;">No performance marks or measures recorded</p>';
      return;
    }
    
    let html = '<div style="background: #f8f9fa; padding: 1rem; border-radius: 4px;">';
    
    if (marks.length > 0) {
      html += '<h4 style="margin: 0 0 0.5rem 0; color: #2c3e50;">Performance Marks:</h4>';
      html += '<ul style="margin: 0; padding-left: 1.5rem;">';
      marks.forEach(mark => {
        html += `<li>${mark.name}: ${mark.startTime.toFixed(3)} ms</li>`;
      });
      html += '</ul>';
    }
    
    if (measures.length > 0) {
      html += '<h4 style="margin: 1rem 0 0.5rem 0; color: #2c3e50;">Performance Measures:</h4>';
      html += '<ul style="margin: 0; padding-left: 1.5rem;">';
      measures.forEach(measure => {
        html += `<li>${measure.name}: ${measure.duration.toFixed(3)} ms</li>`;
      });
      html += '</ul>';
    }
    
    html += '</div>';
    output.innerHTML = html;
  });
  
  document.getElementById('perf-clear').addEventListener('click', () => {
    performance.clearMarks();
    performance.clearMeasures();
    output.innerHTML = '<p style="color: #7f8c8d;">🧹 Cleared all performance marks and measures</p>';
  });
})();
</script>

## 4. Page Visibility API

Detect when the page is visible or hidden:

<div class="demo-box">
  <h3>👁️ Page Visibility Monitor</h3>
  
  <div id="visibility-status" style="padding: 1rem; border-radius: 4px; font-size: 1.2rem; font-weight: bold; text-align: center; margin-bottom: 1rem;"></div>
  
  <div id="visibility-output" class="output"></div>
  
  <p style="margin-top: 1rem; color: #7f8c8d; font-style: italic;">
    💡 Try switching to another tab or minimizing the browser to see the visibility change!
  </p>
</div>

<script>
(function() {
  const status = document.getElementById('visibility-status');
  const output = document.getElementById('visibility-output');
  let eventLog = [];
  
  function updateVisibility() {
    const isVisible = !document.hidden;
    const visibilityState = document.visibilityState;
    
    status.style.background = isVisible ? '#d4edda' : '#f8d7da';
    status.style.color = isVisible ? '#155724' : '#721c24';
    status.style.border = isVisible ? '2px solid #c3e6cb' : '2px solid #f5c6cb';
    status.textContent = isVisible ? '👁️ Page is VISIBLE' : '🙈 Page is HIDDEN';
    
    const timestamp = new Date().toLocaleTimeString();
    eventLog.unshift({
      time: timestamp,
      state: visibilityState,
      visible: isVisible
    });
    
    if (eventLog.length > 10) eventLog = eventLog.slice(0, 10);
    
    const logHTML = eventLog.map((evt, idx) => {
      const color = evt.visible ? '#27ae60' : '#e74c3c';
      return `
        <div style="padding: 0.5rem; margin: 0.25rem 0; background: ${idx === 0 ? '#fff3cd' : '#f8f9fa'}; border-left: 3px solid ${color}; border-radius: 3px;">
          <strong>${evt.time}</strong>: ${evt.state} ${evt.visible ? '(visible)' : '(hidden)'}
        </div>
      `;
    }).join('');
    
    output.innerHTML = `<div><strong>Visibility Event Log:</strong></div>${logHTML}`;
  }
  
  // Initial state
  updateVisibility();
  
  // Listen for visibility changes
  document.addEventListener('visibilitychange', updateVisibility);
})();
</script>

## 5. Performance Navigation Timing

Get detailed page load performance metrics:

<div class="demo-box">
  <h3>📊 Page Load Performance</h3>
  
  <button id="perf-nav-show">📈 Show Navigation Timing</button>
  
  <div id="perf-nav-output" class="output"></div>
</div>

<script>
(function() {
  const output = document.getElementById('perf-nav-output');
  
  document.getElementById('perf-nav-show').addEventListener('click', () => {
    const perfData = performance.getEntriesByType('navigation')[0];
    
    if (!perfData) {
      output.innerHTML = '<p class="error">Navigation timing data not available</p>';
      return;
    }
    
    const metrics = {
      'DNS Lookup': perfData.domainLookupEnd - perfData.domainLookupStart,
      'TCP Connection': perfData.connectEnd - perfData.connectStart,
      'Request Time': perfData.responseStart - perfData.requestStart,
      'Response Time': perfData.responseEnd - perfData.responseStart,
      'DOM Processing': perfData.domComplete - perfData.domLoading,
      'DOM Interactive': perfData.domInteractive - perfData.domLoading,
      'DOM Content Loaded': perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart,
      'Page Load': perfData.loadEventEnd - perfData.loadEventStart,
      'Total Load Time': perfData.loadEventEnd - perfData.fetchStart
    };
    
    let html = `
      <div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3;">
        <h4 style="margin: 0 0 1rem 0; color: #1565c0;">📊 Navigation Performance Metrics</h4>
        <table style="width: 100%; border-collapse: collapse;">
          <thead>
            <tr style="background: #bbdefb;">
              <th style="padding: 0.5rem; border: 1px solid #90caf9; text-align: left;">Metric</th>
              <th style="padding: 0.5rem; border: 1px solid #90caf9; text-align: right;">Duration (ms)</th>
            </tr>
          </thead>
          <tbody>
    `;
    
    Object.entries(metrics).forEach(([name, value]) => {
      const color = value > 100 ? '#ff9800' : value > 50 ? '#ffc107' : '#4caf50';
      html += `
        <tr>
          <td style="padding: 0.5rem; border: 1px solid #90caf9;">${name}</td>
          <td style="padding: 0.5rem; border: 1px solid #90caf9; text-align: right; font-weight: bold; color: ${color};">
            ${value.toFixed(2)}
          </td>
        </tr>
      `;
    });
    
    html += `
          </tbody>
        </table>
        <p style="margin: 1rem 0 0 0; color: #1565c0; font-size: 0.9rem;">
          <strong>Transfer Size:</strong> ${(perfData.transferSize / 1024).toFixed(2)} KB
        </p>
      </div>
    `;
    
    output.innerHTML = html;
  });
})();
</script>

---

<div class="info-box">
  <h3>🎯 Time & Performance APIs Demonstrated:</h3>
  <ul>
    <li><strong>setTimeout/setInterval:</strong> Schedule delayed and repeated code execution</li>
    <li><strong>requestAnimationFrame:</strong> Frame-synchronized animations (typically 60 FPS)</li>
    <li><strong>Performance API:</strong> High-resolution timestamps and performance measurement</li>
    <li><strong>Page Visibility API:</strong> Detect when page is visible/hidden</li>
    <li><strong>Navigation Timing:</strong> Detailed page load performance metrics</li>
  </ul>
  
  <p style="margin-top: 1rem;"><strong>💡 Best Practices:</strong></p>
  <ul>
    <li><strong>Use requestAnimationFrame</strong> for smooth animations instead of setInterval</li>
    <li><strong>Pause animations/updates</strong> when page is hidden to save resources</li>
    <li><strong>Use Performance API</strong> for accurate timing measurements</li>
    <li><strong>Monitor page load metrics</strong> to optimize user experience</li>
  </ul>
  
  <p style="margin-top: 1rem; padding: 1rem; background: #fff3cd; border-radius: 4px; border: 1px solid #ffc107;">
    <strong>⚠️ Idle Scheduling Skipped:</strong> The Idle Callback API (requestIdleCallback) is marked as 🔴 deep/experimental. It's useful for advanced performance optimization but not essential for most applications.
  </p>
</div>
