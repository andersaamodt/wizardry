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
</div>

## 5. WebGL - 3D Graphics

Basic WebGL demonstration with a rotating triangle:

<div class="demo-box">
  <h3>🎮 WebGL 3D Graphics</h3>
  
  <canvas id="webgl-canvas" width="600" height="400" style="border: 2px solid #ddd; border-radius: 4px; max-width: 100%; background: #000;"></canvas>
  
  <div style="margin-top: 1rem; display: flex; gap: 0.5rem; flex-wrap: wrap;">
    <button id="webgl-start">▶️ Start Animation</button>
    <button id="webgl-stop">⏹️ Stop</button>
    <button id="webgl-reset">🔄 Reset</button>
    <label style="display: flex; align-items: center; gap: 0.5rem;">
      <span>Speed:</span>
      <input type="range" id="webgl-speed" min="0.5" max="5" step="0.5" value="1" style="width: 100px;" />
      <span id="webgl-speed-value">1x</span>
    </label>
  </div>
  
  <div id="webgl-output" class="output"></div>
</div>

<script>
(function() {
  const canvas = document.getElementById('webgl-canvas');
  const output = document.getElementById('webgl-output');
  const speedSlider = document.getElementById('webgl-speed');
  const speedValue = document.getElementById('webgl-speed-value');
  
  let gl = null;
  let program = null;
  let animationId = null;
  let rotation = 0;
  let speed = 1;
  
  speedSlider.addEventListener('input', () => {
    speed = parseFloat(speedSlider.value);
    speedValue.textContent = speed + 'x';
  });
  
  function initWebGL() {
    gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
    
    if (!gl) {
      output.innerHTML = `
        <div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
          <h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ WebGL Not Supported</h4>
          <p style="margin: 0;">Your browser does not support WebGL.</p>
        </div>
      `;
      return false;
    }
    
    // Vertex shader
    const vertexShaderSource = `
      attribute vec4 aPosition;
      attribute vec4 aColor;
      uniform float uRotation;
      varying vec4 vColor;
      
      void main() {
        float c = cos(uRotation);
        float s = sin(uRotation);
        mat4 rotation = mat4(
          c, s, 0, 0,
          -s, c, 0, 0,
          0, 0, 1, 0,
          0, 0, 0, 1
        );
        gl_Position = rotation * aPosition;
        vColor = aColor;
      }
    `;
    
    // Fragment shader
    const fragmentShaderSource = `
      precision mediump float;
      varying vec4 vColor;
      
      void main() {
        gl_FragColor = vColor;
      }
    `;
    
    // Compile shaders
    const vertexShader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertexShader, vertexShaderSource);
    gl.compileShader(vertexShader);
    
    const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragmentShader, fragmentShaderSource);
    gl.compileShader(fragmentShader);
    
    // Create program
    program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);
    gl.useProgram(program);
    
    // Triangle vertices (x, y, z)
    const vertices = new Float32Array([
      0.0,  0.6, 0.0,   // Top
      -0.6, -0.6, 0.0,  // Bottom left
      0.6, -0.6, 0.0    // Bottom right
    ]);
    
    // Colors (r, g, b, a)
    const colors = new Float32Array([
      1.0, 0.0, 0.0, 1.0,  // Red
      0.0, 1.0, 0.0, 1.0,  // Green
      0.0, 0.0, 1.0, 1.0   // Blue
    ]);
    
    // Position buffer
    const positionBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);
    
    const aPosition = gl.getAttribLocation(program, 'aPosition');
    gl.vertexAttribPointer(aPosition, 3, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(aPosition);
    
    // Color buffer
    const colorBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, colors, gl.STATIC_DRAW);
    
    const aColor = gl.getAttribLocation(program, 'aColor');
    gl.vertexAttribPointer(aColor, 4, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(aColor);
    
    // Set clear color
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    
    output.innerHTML = `
      <div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
        <h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ WebGL Initialized</h4>
        <p style="margin: 0.25rem 0;"><strong>Renderer:</strong> ${gl.getParameter(gl.RENDERER)}</p>
        <p style="margin: 0.25rem 0;"><strong>Version:</strong> ${gl.getParameter(gl.VERSION)}</p>
      </div>
    `;
    
    return true;
  }
  
  function render() {
    if (!gl || !program) return;
    
    gl.clear(gl.COLOR_BUFFER_BIT);
    
    const uRotation = gl.getUniformLocation(program, 'uRotation');
    gl.uniform1f(uRotation, rotation);
    
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    
    rotation += 0.02 * speed;
    
    animationId = requestAnimationFrame(render);
  }
  
  document.getElementById('webgl-start').addEventListener('click', () => {
    if (!gl) {
      if (!initWebGL()) return;
    }
    
    if (!animationId) {
      render();
      output.innerHTML = '<p style="color: #27ae60;">▶️ Animation started</p>';
    }
  });
  
  document.getElementById('webgl-stop').addEventListener('click', () => {
    if (animationId) {
      cancelAnimationFrame(animationId);
      animationId = null;
      output.innerHTML = '<p style="color: #7f8c8d;">⏹️ Animation stopped</p>';
    }
  });
  
  document.getElementById('webgl-reset').addEventListener('click', () => {
    rotation = 0;
    if (gl) {
      gl.clear(gl.COLOR_BUFFER_BIT);
      const uRotation = gl.getUniformLocation(program, 'uRotation');
      gl.uniform1f(uRotation, 0);
      gl.drawArrays(gl.TRIANGLES, 0, 3);
    }
    output.innerHTML = '<p style="color: #2980b9;">🔄 Reset to initial position</p>';
  });
  
  // Auto-initialize
  initWebGL();
})();
</script>

## 6. WebGPU - Next-Gen Graphics

Basic WebGPU demonstration (if supported):

<div class="demo-box">
  <h3>⚡ WebGPU Graphics</h3>
  
  <div style="background: #fff3cd; padding: 1rem; border-radius: 4px; border: 1px solid #ffc107; margin-bottom: 1rem;">
    <p style="margin: 0; color: #856404;">
      <strong>⚠️ Browser Support:</strong> WebGPU is an emerging standard with growing browser support. Check your browser's compatibility before relying on this API in production.
    </p>
  </div>
  
  <canvas id="webgpu-canvas" width="600" height="400" style="border: 2px solid #ddd; border-radius: 4px; max-width: 100%; background: #000;"></canvas>
  
  <div style="margin-top: 1rem;">
    <button id="webgpu-render">🎨 Render Triangle</button>
  </div>
  
  <div id="webgpu-output" class="output"></div>
</div>

<script>
(function() {
  const canvas = document.getElementById('webgpu-canvas');
  const output = document.getElementById('webgpu-output');
  
  async function initWebGPU() {
    if (!navigator.gpu) {
      output.innerHTML = `
        <div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
          <h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ WebGPU Not Supported</h4>
          <p style="margin: 0.25rem 0;">Your browser does not support WebGPU.</p>
          <p style="margin: 0.25rem 0; font-size: 0.9rem;">Try Chrome Canary or enable WebGPU flag in Chrome.</p>
        </div>
      `;
      return null;
    }
    
    try {
      const adapter = await navigator.gpu.requestAdapter();
      if (!adapter) {
        throw new Error('No adapter found');
      }
      
      const device = await adapter.requestDevice();
      const context = canvas.getContext('webgpu');
      
      const format = navigator.gpu.getPreferredCanvasFormat();
      context.configure({
        device: device,
        format: format
      });
      
      output.innerHTML = `
        <div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
          <h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ WebGPU Initialized</h4>
          <p style="margin: 0.25rem 0;"><strong>Adapter:</strong> ${adapter.name || 'Unknown'}</p>
          <p style="margin: 0.25rem 0;"><strong>Format:</strong> ${format}</p>
        </div>
      `;
      
      return { device, context, format };
    } catch (error) {
      output.innerHTML = `
        <div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
          <h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ WebGPU Initialization Failed</h4>
          <p style="margin: 0.25rem 0;"><strong>Error:</strong> ${error.message}</p>
        </div>
      `;
      return null;
    }
  }
  
  document.getElementById('webgpu-render').addEventListener('click', async () => {
    const gpu = await initWebGPU();
    if (!gpu) return;
    
    const { device, context, format } = gpu;
    
    // Simple shader that draws a gradient triangle
    const shaderCode = `
      @vertex
      fn vertexMain(@builtin(vertex_index) i : u32) -> @builtin(position) vec4f {
        const pos = array(
          vec2f(0.0, 0.6),
          vec2f(-0.6, -0.6),
          vec2f(0.6, -0.6)
        );
        return vec4f(pos[i], 0.0, 1.0);
      }
      
      @fragment
      fn fragmentMain(@builtin(position) pos : vec4f) -> @location(0) vec4f {
        return vec4f(pos.x / 600.0, pos.y / 400.0, 1.0, 1.0);
      }
    `;
    
    const shaderModule = device.createShaderModule({ code: shaderCode });
    
    const pipeline = device.createRenderPipeline({
      layout: 'auto',
      vertex: {
        module: shaderModule,
        entryPoint: 'vertexMain'
      },
      fragment: {
        module: shaderModule,
        entryPoint: 'fragmentMain',
        targets: [{ format: format }]
      }
    });
    
    const commandEncoder = device.createCommandEncoder();
    const textureView = context.getCurrentTexture().createView();
    
    const renderPass = commandEncoder.beginRenderPass({
      colorAttachments: [{
        view: textureView,
        clearValue: { r: 0.0, g: 0.0, b: 0.0, a: 1.0 },
        loadOp: 'clear',
        storeOp: 'store'
      }]
    });
    
    renderPass.setPipeline(pipeline);
    renderPass.draw(3);
    renderPass.end();
    
    device.queue.submit([commandEncoder.finish()]);
    
    output.innerHTML = `
      <div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3;">
        <h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">🎨 Triangle Rendered</h4>
        <p style="margin: 0;">A gradient triangle has been drawn using WebGPU shaders.</p>
      </div>
    `;
  });
})();
</script>

<div class="info-box">
  <h3>🎯 3D Graphics APIs:</h3>
  <ul>
    <li><strong>WebGL:</strong> OpenGL ES 2.0/3.0 for web, widely supported</li>
    <li><strong>WebGPU:</strong> Modern GPU API, experimental but more powerful</li>
  </ul>
  
  <p style="margin-top: 1rem;"><strong>🎨 WebGL vs WebGPU:</strong></p>
  <ul>
    <li><strong>WebGL:</strong> Mature, compatible with all modern browsers, OpenGL-based</li>
    <li><strong>WebGPU:</strong> Next-gen, better performance, modern shader language (WGSL)</li>
    <li><strong>WebGL:</strong> Uses GLSL shaders (OpenGL Shading Language)</li>
    <li><strong>WebGPU:</strong> Uses WGSL shaders (WebGPU Shading Language)</li>
  </ul>
  
  <p style="margin-top: 1rem;"><strong>💡 Use Cases:</strong></p>
  <ul>
    <li>3D games and interactive experiences</li>
    <li>Data visualization and scientific computing</li>
    <li>Image/video processing with GPU acceleration</li>
    <li>CAD and 3D modeling tools</li>
  </ul>
</div>
