---
title: Graphics & Media Demos
---

# Graphics & Media Demos

Explore browser graphics rendering and media playback capabilities.

## 1. Canvas 2D Drawing

Draw shapes, text, and images on a 2D canvas:

<div class="demo-box">
  <h3>🎨 Canvas 2D API</h3>
  
  <canvas id="canvas-2d" width="600" height="400" style="border: 2px solid #ddd; border-radius: 4px; max-width: 100%; background: white;"></canvas>
  
  <div style="margin-top: 1rem; display: flex; gap: 0.5rem; flex-wrap: wrap;">
    <button id="canvas-rect">Draw Rectangle</button>
    <button id="canvas-circle">Draw Circle</button>
    <button id="canvas-line">Draw Line</button>
    <button id="canvas-text">Draw Text</button>
    <button id="canvas-gradient">Draw Gradient</button>
    <button id="canvas-clear">Clear Canvas</button>
  </div>
  
  <div id="canvas-output" class="output"></div>
</div>

<script>
(function() {
  const canvas = document.getElementById('canvas-2d');
  const ctx = canvas.getContext('2d');
  const output = document.getElementById('canvas-output');
  
  function randomColor() {
    return `hsl(${Math.random() * 360}, 70%, 60%)`;
  }
  
  document.getElementById('canvas-rect').addEventListener('click', () => {
    ctx.fillStyle = randomColor();
    const x = Math.random() * (canvas.width - 100);
    const y = Math.random() * (canvas.height - 100);
    const w = 50 + Math.random() * 100;
    const h = 50 + Math.random() * 100;
    ctx.fillRect(x, y, w, h);
    output.innerHTML = `<p style="color: #2980b9;">Drew rectangle at (${x.toFixed(0)}, ${y.toFixed(0)})</p>`;
  });
  
  document.getElementById('canvas-circle').addEventListener('click', () => {
    ctx.fillStyle = randomColor();
    ctx.beginPath();
    const x = Math.random() * canvas.width;
    const y = Math.random() * canvas.height;
    const r = 20 + Math.random() * 50;
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fill();
    output.innerHTML = `<p style="color: #27ae60;">Drew circle at (${x.toFixed(0)}, ${y.toFixed(0)}) with radius ${r.toFixed(0)}</p>`;
  });
  
  document.getElementById('canvas-line').addEventListener('click', () => {
    ctx.strokeStyle = randomColor();
    ctx.lineWidth = 2 + Math.random() * 5;
    ctx.beginPath();
    ctx.moveTo(Math.random() * canvas.width, Math.random() * canvas.height);
    ctx.lineTo(Math.random() * canvas.width, Math.random() * canvas.height);
    ctx.stroke();
    output.innerHTML = '<p style="color: #e67e22;">Drew random line</p>';
  });
  
  document.getElementById('canvas-text').addEventListener('click', () => {
    ctx.fillStyle = randomColor();
    ctx.font = '30px Georgia, serif';
    ctx.fillText('Wizardry!', 50 + Math.random() * 200, 50 + Math.random() * 200);
    output.innerHTML = '<p style="color: #8e44ad;">Drew text</p>';
  });
  
  document.getElementById('canvas-gradient').addEventListener('click', () => {
    const gradient = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
    gradient.addColorStop(0, randomColor());
    gradient.addColorStop(0.5, randomColor());
    gradient.addColorStop(1, randomColor());
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    output.innerHTML = '<p style="color: #c0392b;">Drew gradient background</p>';
  });
  
  document.getElementById('canvas-clear').addEventListener('click', () => {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    output.innerHTML = '<p style="color: #7f8c8d;">Cleared canvas</p>';
  });
  
  // Initial gradient
  const initialGradient = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
  initialGradient.addColorStop(0, '#667eea');
  initialGradient.addColorStop(1, '#764ba2');
  ctx.fillStyle = initialGradient;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  
  ctx.fillStyle = 'white';
  ctx.font = 'bold 40px Georgia, serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('Canvas 2D', canvas.width / 2, canvas.height / 2);
})();
</script>

## 2. SVG - Scalable Vector Graphics

Create and manipulate SVG graphics:

<div class="demo-box">
  <h3>📐 SVG Graphics</h3>
  
  <svg id="svg-canvas" width="600" height="300" style="border: 2px solid #ddd; border-radius: 4px; max-width: 100%; background: #f8f9fa;">
    <defs>
      <linearGradient id="svg-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
        <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
      </linearGradient>
    </defs>
    <text x="300" y="150" text-anchor="middle" font-size="40" font-family="Georgia, serif" fill="url(#svg-gradient)" font-weight="bold">SVG Graphics</text>
  </svg>
  
  <div style="margin-top: 1rem; display: flex; gap: 0.5rem; flex-wrap: wrap;">
    <button id="svg-rect">Add Rectangle</button>
    <button id="svg-circle">Add Circle</button>
    <button id="svg-path">Add Path</button>
    <button id="svg-animate">Animate</button>
    <button id="svg-clear">Clear All</button>
  </div>
  
  <div id="svg-output" class="output"></div>
</div>

<script>
(function() {
  const svg = document.getElementById('svg-canvas');
  const output = document.getElementById('svg-output');
  const NS = 'http://www.w3.org/2000/svg';
  
  function randomColor() {
    return `hsl(${Math.random() * 360}, 70%, 60%)`;
  }
  
  document.getElementById('svg-rect').addEventListener('click', () => {
    const rect = document.createElementNS(NS, 'rect');
    rect.setAttribute('x', Math.random() * 500);
    rect.setAttribute('y', Math.random() * 200);
    rect.setAttribute('width', 50 + Math.random() * 100);
    rect.setAttribute('height', 50 + Math.random() * 100);
    rect.setAttribute('fill', randomColor());
    rect.setAttribute('opacity', '0.7');
    rect.setAttribute('rx', '5');
    svg.appendChild(rect);
    output.innerHTML = '<p style="color: #2980b9;">Added SVG rectangle</p>';
  });
  
  document.getElementById('svg-circle').addEventListener('click', () => {
    const circle = document.createElementNS(NS, 'circle');
    circle.setAttribute('cx', Math.random() * 600);
    circle.setAttribute('cy', Math.random() * 300);
    circle.setAttribute('r', 20 + Math.random() * 40);
    circle.setAttribute('fill', randomColor());
    circle.setAttribute('opacity', '0.7');
    svg.appendChild(circle);
    output.innerHTML = '<p style="color: #27ae60;">Added SVG circle</p>';
  });
  
  document.getElementById('svg-path').addEventListener('click', () => {
    const path = document.createElementNS(NS, 'path');
    const x1 = Math.random() * 600;
    const y1 = Math.random() * 300;
    const x2 = Math.random() * 600;
    const y2 = Math.random() * 300;
    const cx = (x1 + x2) / 2 + (Math.random() - 0.5) * 100;
    const cy = (y1 + y2) / 2 + (Math.random() - 0.5) * 100;
    path.setAttribute('d', `M ${x1} ${y1} Q ${cx} ${cy} ${x2} ${y2}`);
    path.setAttribute('stroke', randomColor());
    path.setAttribute('stroke-width', '3');
    path.setAttribute('fill', 'none');
    svg.appendChild(path);
    output.innerHTML = '<p style="color: #e67e22;">Added SVG path (curve)</p>';
  });
  
  document.getElementById('svg-animate').addEventListener('click', () => {
    const circle = document.createElementNS(NS, 'circle');
    circle.setAttribute('cx', '50');
    circle.setAttribute('cy', '150');
    circle.setAttribute('r', '30');
    circle.setAttribute('fill', randomColor());
    
    const animate = document.createElementNS(NS, 'animate');
    animate.setAttribute('attributeName', 'cx');
    animate.setAttribute('from', '50');
    animate.setAttribute('to', '550');
    animate.setAttribute('dur', '3s');
    animate.setAttribute('repeatCount', 'indefinite');
    
    circle.appendChild(animate);
    svg.appendChild(circle);
    output.innerHTML = '<p style="color: #8e44ad;">Added animated circle</p>';
  });
  
  document.getElementById('svg-clear').addEventListener('click', () => {
    // Remove all children except defs and initial text
    Array.from(svg.children).forEach(child => {
      if (child.tagName !== 'defs' && child.tagName !== 'text') {
        svg.removeChild(child);
      }
    });
    output.innerHTML = '<p style="color: #7f8c8d;">Cleared all shapes</p>';
  });
})();
</script>

## 3. Audio Playback

Basic audio playback using HTML5 audio elements:

<div class="demo-box">
  <h3>🔊 Audio Player</h3>
  
  <div style="background: #f8f9fa; padding: 1rem; border-radius: 4px; margin-bottom: 1rem;">
    <audio id="audio-player" controls style="width: 100%;">
      <source src="data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=" type="audio/wav">
      Your browser does not support audio playback.
    </audio>
  </div>
  
  <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
    <button id="audio-play">▶️ Play</button>
    <button id="audio-pause">⏸️ Pause</button>
    <button id="audio-stop">⏹️ Stop</button>
    <button id="audio-volume-up">🔊 Volume Up</button>
    <button id="audio-volume-down">🔉 Volume Down</button>
  </div>
  
  <div id="audio-output" class="output"></div>
  
  <div style="margin-top: 1rem; padding: 1rem; background: #fff3cd; border-radius: 4px; border: 1px solid #ffc107;">
    <p style="margin: 0; color: #856404;">
      <strong>💡 Note:</strong> This demo uses a minimal audio data URL. In a real application, you would load actual audio files (MP3, WAV, OGG, etc.).
    </p>
  </div>
</div>

<script>
(function() {
  const audio = document.getElementById('audio-player');
  const output = document.getElementById('audio-output');
  
  // Generate a simple tone using Web Audio API
  function generateTone() {
    const audioContext = new (window.AudioContext || window.webkitAudioContext)();
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    oscillator.frequency.value = 440; // A4 note
    oscillator.type = 'sine';
    
    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 1);
    
    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + 1);
    
    output.innerHTML = '<p style="color: #27ae60;">🎵 Playing 440Hz tone (A4 note)</p>';
  }
  
  document.getElementById('audio-play').addEventListener('click', () => {
    generateTone();
  });
  
  document.getElementById('audio-pause').addEventListener('click', () => {
    audio.pause();
    output.innerHTML = '<p style="color: #e67e22;">⏸️ Paused</p>';
  });
  
  document.getElementById('audio-stop').addEventListener('click', () => {
    audio.pause();
    audio.currentTime = 0;
    output.innerHTML = '<p style="color: #c0392b;">⏹️ Stopped</p>';
  });
  
  document.getElementById('audio-volume-up').addEventListener('click', () => {
    audio.volume = Math.min(1, audio.volume + 0.1);
    output.innerHTML = `<p style="color: #2980b9;">🔊 Volume: ${Math.round(audio.volume * 100)}%</p>`;
  });
  
  document.getElementById('audio-volume-down').addEventListener('click', () => {
    audio.volume = Math.max(0, audio.volume - 0.1);
    output.innerHTML = `<p style="color: #2980b9;">🔉 Volume: ${Math.round(audio.volume * 100)}%</p>`;
  });
  
  audio.addEventListener('ended', () => {
    output.innerHTML = '<p style="color: #7f8c8d;">✅ Audio playback finished</p>';
  });
})();
</script>

## 4. Web Audio API - Programmable Audio

Create and manipulate audio using the Web Audio API:

<div class="demo-box">
  <h3>🎹 Web Audio Synthesizer</h3>
  
  <div style="margin-bottom: 1rem;">
    <label style="display: block; margin-bottom: 0.5rem;"><strong>Frequency:</strong> <span id="freq-value">440</span> Hz</label>
    <input type="range" id="freq-slider" min="100" max="1000" value="440" style="width: 100%;" />
  </div>
  
  <div style="margin-bottom: 1rem;">
    <label style="display: block; margin-bottom: 0.5rem;"><strong>Wave Type:</strong></label>
    <select id="wave-type" style="width: 100%; padding: 0.5rem;">
      <option value="sine">Sine Wave</option>
      <option value="square">Square Wave</option>
      <option value="sawtooth">Sawtooth Wave</option>
      <option value="triangle">Triangle Wave</option>
    </select>
  </div>
  
  <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
    <button id="synth-start">▶️ Start Oscillator</button>
    <button id="synth-stop">⏹️ Stop Oscillator</button>
    <button id="synth-beep">🔔 Play Beep</button>
  </div>
  
  <div id="synth-output" class="output"></div>
</div>

<script>
(function() {
  const freqSlider = document.getElementById('freq-slider');
  const freqValue = document.getElementById('freq-value');
  const waveType = document.getElementById('wave-type');
  const output = document.getElementById('synth-output');
  
  let audioContext = null;
  let oscillator = null;
  let gainNode = null;
  
  freqSlider.addEventListener('input', () => {
    freqValue.textContent = freqSlider.value;
    if (oscillator) {
      oscillator.frequency.value = freqSlider.value;
    }
  });
  
  document.getElementById('synth-start').addEventListener('click', () => {
    if (oscillator) {
      output.innerHTML = '<p class="error">Oscillator already running</p>';
      return;
    }
    
    audioContext = new (window.AudioContext || window.webkitAudioContext)();
    oscillator = audioContext.createOscillator();
    gainNode = audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    oscillator.frequency.value = freqSlider.value;
    oscillator.type = waveType.value;
    gainNode.gain.value = 0.3;
    
    oscillator.start();
    output.innerHTML = `<p style="color: #27ae60;">▶️ Playing ${waveType.value} wave at ${freqSlider.value}Hz</p>`;
  });
  
  document.getElementById('synth-stop').addEventListener('click', () => {
    if (oscillator) {
      oscillator.stop();
      oscillator = null;
      output.innerHTML = '<p style="color: #c0392b;">⏹️ Stopped oscillator</p>';
    } else {
      output.innerHTML = '<p class="error">No oscillator running</p>';
    }
  });
  
  document.getElementById('synth-beep').addEventListener('click', () => {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    
    osc.connect(gain);
    gain.connect(ctx.destination);
    
    osc.frequency.value = 800;
    osc.type = 'sine';
    
    gain.gain.setValueAtTime(0.3, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.5);
    
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.5);
    
    output.innerHTML = '<p style="color: #2980b9;">🔔 Beep!</p>';
  });
  
  waveType.addEventListener('change', () => {
    if (oscillator) {
      oscillator.type = waveType.value;
      output.innerHTML = `<p style="color: #8e44ad;">Changed to ${waveType.value} wave</p>`;
    }
  });
})();
</script>

---

<div class="info-box">
  <h3>🎯 Graphics & Media APIs Demonstrated:</h3>
  <ul>
    <li><strong>Canvas 2D Context:</strong> Immediate-mode raster graphics with shapes, text, gradients</li>
    <li><strong>SVG:</strong> Retained-mode vector graphics with DOM manipulation</li>
    <li><strong>HTML5 Audio:</strong> Basic audio playback with media element controls</li>
    <li><strong>Web Audio API:</strong> Low-level audio synthesis and processing</li>
  </ul>
  
  <p style="margin-top: 1rem;"><strong>💡 Canvas vs SVG:</strong></p>
  <ul>
    <li><strong>Canvas:</strong> Better for dynamic, high-performance graphics (games, animations)</li>
    <li><strong>SVG:</strong> Better for scalable, interactive graphics (charts, diagrams)</li>
    <li><strong>Canvas:</strong> Pixel-based, drawn with JavaScript API calls</li>
    <li><strong>SVG:</strong> Vector-based, manipulated through DOM</li>
  </ul>
  
  <p style="margin-top: 1rem;"><strong>🔊 Audio Playback:</strong></p>
  <ul>
    <li><strong>HTML5 Audio:</strong> Simple playback of audio files</li>
    <li><strong>Web Audio API:</strong> Real-time synthesis, effects, and audio graph manipulation</li>
  </ul>
  
  <p style="margin-top: 1rem; padding: 1rem; background: #fff3cd; border-radius: 4px; border: 1px solid #ffc107;">
    <strong>⚠️ Advanced Graphics Skipped:</strong> WebGL and WebGPU demos are not included as they require specialized 3D graphics knowledge and complex shader programming. These are marked as 🔴 deep/specialized features.
  </p>
</div>
