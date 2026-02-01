---
title: Hardware & Sensors
---

# Hardware & Sensors Demos

Explore browser APIs for accessing device hardware like cameras, microphones, and sensors.

## 1. Camera Access (getUserMedia)

Access the device camera and display live video:

<div class="demo-box">
  <h3>📷 Camera Access</h3>
  
  <div style="margin-bottom: 1rem;">
    <video id="camera-video" autoplay playsinline style="max-width: 100%; border: 2px solid #ddd; border-radius: 4px; background: #000;"></video>
  </div>
  
  <div style="display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 1rem;">
    <button id="camera-start">📹 Start Camera</button>
    <button id="camera-stop">⏹️ Stop Camera</button>
    <button id="camera-photo">📸 Take Photo</button>
    <select id="camera-select" style="padding: 0.5rem;">
      <option value="">Select Camera...</option>
    </select>
  </div>
  
  <canvas id="camera-canvas" style="max-width: 100%; border: 2px solid #ddd; border-radius: 4px; display: none;"></canvas>
  
  <div id="camera-output" class="output"></div>
</div>

<script>
(function() {
  const video = document.getElementById('camera-video');
  const canvas = document.getElementById('camera-canvas');
  const ctx = canvas.getContext('2d');
  const output = document.getElementById('camera-output');
  const cameraSelect = document.getElementById('camera-select');
  let stream = null;
  
  // Enumerate cameras
  async function getCameras() {
    try {
      const devices = await navigator.mediaDevices.enumerateDevices();
      const videoDevices = devices.filter(device => device.kind === 'videoinput');
      
      cameraSelect.innerHTML = '<option value="">Select Camera...</option>';
      videoDevices.forEach((device, index) => {
        const option = document.createElement('option');
        option.value = device.deviceId;
        option.text = device.label || `Camera ${index + 1}`;
        cameraSelect.appendChild(option);
      });
      
      return videoDevices;
    } catch (error) {
      output.innerHTML = `<p class="error">Error enumerating devices: ${error.message}</p>`;
      return [];
    }
  }
  
  document.getElementById('camera-start').addEventListener('click', async () => {
    try {
      const constraints = {
        video: cameraSelect.value ? { deviceId: { exact: cameraSelect.value } } : true,
        audio: false
      };
      
      stream = await navigator.mediaDevices.getUserMedia(constraints);
      video.srcObject = stream;
      video.style.display = 'block';
      
      // Update camera list after permission granted
      await getCameras();
      
      const track = stream.getVideoTracks()[0];
      const settings = track.getSettings();
      
      output.innerHTML = `
        <div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
          <h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">📹 Camera Active</h4>
          <p style="margin: 0.25rem 0;"><strong>Camera:</strong> ${track.label}</p>
          <p style="margin: 0.25rem 0;"><strong>Resolution:</strong> ${settings.width}x${settings.height}</p>
          <p style="margin: 0.25rem 0;"><strong>Frame Rate:</strong> ${settings.frameRate} fps</p>
        </div>
      `;
    } catch (error) {
      output.innerHTML = `
        <div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
          <h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ Camera Access Denied</h4>
          <p style="margin: 0.25rem 0;"><strong>Error:</strong> ${error.message}</p>
          <p style="margin: 0.5rem 0 0 0; color: #666; font-size: 0.9rem;">
            Please grant camera permission in your browser settings.
          </p>
        </div>
      `;
    }
  });
  
  document.getElementById('camera-stop').addEventListener('click', () => {
    if (stream) {
      stream.getTracks().forEach(track => track.stop());
      video.srcObject = null;
      video.style.display = 'none';
      canvas.style.display = 'none';
      output.innerHTML = '<p style="color: #7f8c8d;">Camera stopped</p>';
    }
  });
  
  document.getElementById('camera-photo').addEventListener('click', () => {
    if (!stream) {
      output.innerHTML = '<p class="error">Start camera first</p>';
      return;
    }
    
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    ctx.drawImage(video, 0, 0);
    canvas.style.display = 'block';
    
    const dataUrl = canvas.toDataURL('image/png');
    output.innerHTML = `
      <div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3; margin-top: 1rem;">
        <h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">📸 Photo Captured</h4>
        <p style="margin: 0.25rem 0;">Photo shown in canvas above</p>
        <a href="${dataUrl}" download="photo.png" style="display: inline-block; margin-top: 0.5rem; padding: 0.5rem 1rem; background: #1976d2; color: white; border-radius: 4px; text-decoration: none;">⬇️ Download Photo</a>
      </div>
    `;
  });
  
  cameraSelect.addEventListener('change', () => {
    if (stream) {
      document.getElementById('camera-stop').click();
    }
  });
  
  // Initial camera enumeration
  getCameras();
})();
</script>

## 2. Microphone Access (Audio Input)

Access the device microphone and visualize audio:

<div class="demo-box">
  <h3>🎤 Microphone Access</h3>
  
  <canvas id="mic-canvas" width="600" height="200" style="border: 2px solid #ddd; border-radius: 4px; max-width: 100%; background: #000;"></canvas>
  
  <div style="margin-top: 1rem; display: flex; gap: 0.5rem; flex-wrap: wrap;">
    <button id="mic-start">🎤 Start Microphone</button>
    <button id="mic-stop">⏹️ Stop</button>
    <select id="mic-select" style="padding: 0.5rem;">
      <option value="">Select Microphone...</option>
    </select>
  </div>
  
  <div id="mic-output" class="output"></div>
</div>

<script>
(function() {
  const canvas = document.getElementById('mic-canvas');
  const ctx = canvas.getContext('2d');
  const output = document.getElementById('mic-output');
  const micSelect = document.getElementById('mic-select');
  let audioContext = null;
  let analyser = null;
  let stream = null;
  let animationId = null;
  
  // Enumerate microphones
  async function getMicrophones() {
    try {
      const devices = await navigator.mediaDevices.enumerateDevices();
      const audioDevices = devices.filter(device => device.kind === 'audioinput');
      
      micSelect.innerHTML = '<option value="">Select Microphone...</option>';
      audioDevices.forEach((device, index) => {
        const option = document.createElement('option');
        option.value = device.deviceId;
        option.text = device.label || `Microphone ${index + 1}`;
        micSelect.appendChild(option);
      });
      
      return audioDevices;
    } catch (error) {
      output.innerHTML = `<p class="error">Error enumerating devices: ${error.message}</p>`;
      return [];
    }
  }
  
  function visualize() {
    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);
    
    function draw() {
      animationId = requestAnimationFrame(draw);
      
      analyser.getByteFrequencyData(dataArray);
      
      ctx.fillStyle = '#000';
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      
      const barWidth = (canvas.width / bufferLength) * 2.5;
      let x = 0;
      
      for (let i = 0; i < bufferLength; i++) {
        const barHeight = (dataArray[i] / 255) * canvas.height;
        
        const hue = (i / bufferLength) * 360;
        ctx.fillStyle = `hsl(${hue}, 100%, 50%)`;
        ctx.fillRect(x, canvas.height - barHeight, barWidth, barHeight);
        
        x += barWidth + 1;
      }
    }
    
    draw();
  }
  
  document.getElementById('mic-start').addEventListener('click', async () => {
    try {
      const constraints = {
        audio: micSelect.value ? { deviceId: { exact: micSelect.value } } : true,
        video: false
      };
      
      stream = await navigator.mediaDevices.getUserMedia(constraints);
      
      audioContext = new (window.AudioContext || window.webkitAudioContext)();
      analyser = audioContext.createAnalyser();
      const source = audioContext.createMediaStreamSource(stream);
      source.connect(analyser);
      
      analyser.fftSize = 256;
      
      visualize();
      
      // Update mic list after permission granted
      await getMicrophones();
      
      const track = stream.getAudioTracks()[0];
      const settings = track.getSettings();
      
      output.innerHTML = `
        <div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
          <h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">🎤 Microphone Active</h4>
          <p style="margin: 0.25rem 0;"><strong>Device:</strong> ${track.label}</p>
          <p style="margin: 0.25rem 0;"><strong>Sample Rate:</strong> ${settings.sampleRate} Hz</p>
          <p style="margin: 0.25rem 0;"><strong>Channels:</strong> ${settings.channelCount}</p>
        </div>
      `;
    } catch (error) {
      output.innerHTML = `
        <div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
          <h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ Microphone Access Denied</h4>
          <p style="margin: 0.25rem 0;"><strong>Error:</strong> ${error.message}</p>
          <p style="margin: 0.5rem 0 0 0; color: #666; font-size: 0.9rem;">
            Please grant microphone permission in your browser settings.
          </p>
        </div>
      `;
    }
  });
  
  document.getElementById('mic-stop').addEventListener('click', () => {
    if (animationId) {
      cancelAnimationFrame(animationId);
      animationId = null;
    }
    if (stream) {
      stream.getTracks().forEach(track => track.stop());
      stream = null;
    }
    if (audioContext) {
      audioContext.close();
      audioContext = null;
    }
    
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    output.innerHTML = '<p style="color: #7f8c8d;">Microphone stopped</p>';
  });
  
  micSelect.addEventListener('change', () => {
    if (stream) {
      document.getElementById('mic-stop').click();
    }
  });
  
  // Initial microphone enumeration
  getMicrophones();
})();
</script>

## 3. Screen Capture (getDisplayMedia)

Capture screen, window, or tab content:

<div class="demo-box">
  <h3>🖥️ Screen Capture</h3>
  
  <div style="margin-bottom: 1rem;">
    <video id="screen-video" autoplay playsinline style="max-width: 100%; border: 2px solid #ddd; border-radius: 4px; background: #000;"></video>
  </div>
  
  <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
    <button id="screen-start">🖥️ Start Screen Capture</button>
    <button id="screen-stop">⏹️ Stop</button>
    <button id="screen-screenshot">📸 Take Screenshot</button>
  </div>
  
  <canvas id="screen-canvas" style="max-width: 100%; border: 2px solid #ddd; border-radius: 4px; display: none; margin-top: 1rem;"></canvas>
  
  <div id="screen-output" class="output"></div>
</div>

<script>
(function() {
  const video = document.getElementById('screen-video');
  const canvas = document.getElementById('screen-canvas');
  const ctx = canvas.getContext('2d');
  const output = document.getElementById('screen-output');
  let stream = null;
  
  document.getElementById('screen-start').addEventListener('click', async () => {
    try {
      stream = await navigator.mediaDevices.getDisplayMedia({
        video: { mediaSource: 'screen' },
        audio: false
      });
      
      video.srcObject = stream;
      video.style.display = 'block';
      
      const track = stream.getVideoTracks()[0];
      const settings = track.getSettings();
      
      output.innerHTML = `
        <div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
          <h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">🖥️ Screen Capture Active</h4>
          <p style="margin: 0.25rem 0;"><strong>Display Surface:</strong> ${settings.displaySurface || 'screen'}</p>
          <p style="margin: 0.25rem 0;"><strong>Resolution:</strong> ${settings.width}x${settings.height}</p>
          <p style="margin: 0.25rem 0;"><strong>Frame Rate:</strong> ${settings.frameRate} fps</p>
        </div>
      `;
      
      // Listen for user stopping the share
      track.addEventListener('ended', () => {
        document.getElementById('screen-stop').click();
      });
    } catch (error) {
      output.innerHTML = `
        <div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
          <h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ Screen Capture Cancelled</h4>
          <p style="margin: 0.25rem 0;"><strong>Error:</strong> ${error.message}</p>
          <p style="margin: 0.5rem 0 0 0; color: #666; font-size: 0.9rem;">
            User cancelled screen sharing or permission was denied.
          </p>
        </div>
      `;
    }
  });
  
  document.getElementById('screen-stop').addEventListener('click', () => {
    if (stream) {
      stream.getTracks().forEach(track => track.stop());
      video.srcObject = null;
      video.style.display = 'none';
      canvas.style.display = 'none';
      output.innerHTML = '<p style="color: #7f8c8d;">Screen capture stopped</p>';
    }
  });
  
  document.getElementById('screen-screenshot').addEventListener('click', () => {
    if (!stream) {
      output.innerHTML = '<p class="error">Start screen capture first</p>';
      return;
    }
    
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    ctx.drawImage(video, 0, 0);
    canvas.style.display = 'block';
    
    const dataUrl = canvas.toDataURL('image/png');
    output.innerHTML = `
      <div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3; margin-top: 1rem;">
        <h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">📸 Screenshot Captured</h4>
        <p style="margin: 0.25rem 0;">Screenshot shown in canvas above</p>
        <a href="${dataUrl}" download="screenshot.png" style="display: inline-block; margin-top: 0.5rem; padding: 0.5rem 1rem; background: #1976d2; color: white; border-radius: 4px; text-decoration: none;">⬇️ Download Screenshot</a>
      </div>
    `;
  });
})();
</script>

## 4. Device Motion & Orientation

Access device accelerometer and gyroscope data:

<div class="demo-box">
  <h3>📱 Device Motion Sensors</h3>
  
  <div style="margin-bottom: 1rem;">
    <button id="motion-start">📱 Start Monitoring</button>
    <button id="motion-stop" style="margin-left: 0.5rem;">⏹️ Stop</button>
  </div>
  
  <div id="motion-output" class="output"></div>
  
  <div id="motion-display" style="display: none; margin-top: 1rem;">
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem;">
      <div style="background: #e3f2fd; padding: 1rem; border-radius: 4px;">
        <h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">🔄 Rotation (°/s)</h4>
        <p style="margin: 0.25rem 0;"><strong>Alpha (Z):</strong> <span id="rot-alpha">-</span></p>
        <p style="margin: 0.25rem 0;"><strong>Beta (X):</strong> <span id="rot-beta">-</span></p>
        <p style="margin: 0.25rem 0;"><strong>Gamma (Y):</strong> <span id="rot-gamma">-</span></p>
      </div>
      
      <div style="background: #f3e5f5; padding: 1rem; border-radius: 4px;">
        <h4 style="margin: 0 0 0.5rem 0; color: #6a1b9a;">⚡ Acceleration (m/s²)</h4>
        <p style="margin: 0.25rem 0;"><strong>X:</strong> <span id="accel-x">-</span></p>
        <p style="margin: 0.25rem 0;"><strong>Y:</strong> <span id="accel-y">-</span></p>
        <p style="margin: 0.25rem 0;"><strong>Z:</strong> <span id="accel-z">-</span></p>
      </div>
      
      <div style="background: #e8f5e9; padding: 1rem; border-radius: 4px;">
        <h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">🧭 Orientation (°)</h4>
        <p style="margin: 0.25rem 0;"><strong>Alpha:</strong> <span id="orient-alpha">-</span></p>
        <p style="margin: 0.25rem 0;"><strong>Beta:</strong> <span id="orient-beta">-</span></p>
        <p style="margin: 0.25rem 0;"><strong>Gamma:</strong> <span id="orient-gamma">-</span></p>
      </div>
    </div>
  </div>
</div>

<script>
(function() {
  const output = document.getElementById('motion-output');
  const display = document.getElementById('motion-display');
  let isMonitoring = false;
  
  function handleMotion(event) {
    if (!isMonitoring) return;
    
    // Rotation rate (gyroscope)
    if (event.rotationRate) {
      document.getElementById('rot-alpha').textContent = event.rotationRate.alpha ? event.rotationRate.alpha.toFixed(2) : '0.00';
      document.getElementById('rot-beta').textContent = event.rotationRate.beta ? event.rotationRate.beta.toFixed(2) : '0.00';
      document.getElementById('rot-gamma').textContent = event.rotationRate.gamma ? event.rotationRate.gamma.toFixed(2) : '0.00';
    }
    
    // Acceleration
    if (event.acceleration) {
      document.getElementById('accel-x').textContent = event.acceleration.x ? event.acceleration.x.toFixed(2) : '0.00';
      document.getElementById('accel-y').textContent = event.acceleration.y ? event.acceleration.y.toFixed(2) : '0.00';
      document.getElementById('accel-z').textContent = event.acceleration.z ? event.acceleration.z.toFixed(2) : '0.00';
    }
  }
  
  function handleOrientation(event) {
    if (!isMonitoring) return;
    
    document.getElementById('orient-alpha').textContent = event.alpha ? event.alpha.toFixed(2) : '0.00';
    document.getElementById('orient-beta').textContent = event.beta ? event.beta.toFixed(2) : '0.00';
    document.getElementById('orient-gamma').textContent = event.gamma ? event.gamma.toFixed(2) : '0.00';
  }
  
  document.getElementById('motion-start').addEventListener('click', async () => {
    try {
      // Request permission on iOS 13+
      if (typeof DeviceMotionEvent !== 'undefined' && typeof DeviceMotionEvent.requestPermission === 'function') {
        const permission = await DeviceMotionEvent.requestPermission();
        if (permission !== 'granted') {
          output.innerHTML = '<p class="error">Motion sensor permission denied</p>';
          return;
        }
      }
      
      if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
        const permission = await DeviceOrientationEvent.requestPermission();
        if (permission !== 'granted') {
          output.innerHTML = '<p class="error">Orientation sensor permission denied</p>';
          return;
        }
      }
      
      isMonitoring = true;
      display.style.display = 'block';
      
      window.addEventListener('devicemotion', handleMotion);
      window.addEventListener('deviceorientation', handleOrientation);
      
      output.innerHTML = `
        <div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
          <h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">📱 Sensors Active</h4>
          <p style="margin: 0;">Move or rotate your device to see sensor data update in real-time.</p>
        </div>
      `;
    } catch (error) {
      output.innerHTML = `
        <div style="background: #fff3e0; padding: 1rem; border-radius: 4px; border: 1px solid #ff9800;">
          <h4 style="margin: 0 0 0.5rem 0; color: #e65100;">⚠️ Sensors Not Available</h4>
          <p style="margin: 0.25rem 0;"><strong>Error:</strong> ${error.message}</p>
          <p style="margin: 0.5rem 0 0 0; color: #666; font-size: 0.9rem;">
            Device motion sensors may not be available on desktop browsers. Try on a mobile device.
          </p>
        </div>
      `;
    }
  });
  
  document.getElementById('motion-stop').addEventListener('click', () => {
    isMonitoring = false;
    window.removeEventListener('devicemotion', handleMotion);
    window.removeEventListener('deviceorientation', handleOrientation);
    display.style.display = 'none';
    output.innerHTML = '<p style="color: #7f8c8d;">Sensor monitoring stopped</p>';
  });
})();
</script>

---

<div class="info-box">
  <h3>🎯 Hardware APIs Demonstrated:</h3>
  <ul>
    <li><strong>getUserMedia (Video):</strong> Access device cameras with resolution/FPS control</li>
    <li><strong>getUserMedia (Audio):</strong> Access microphones with real-time visualization</li>
    <li><strong>getDisplayMedia:</strong> Capture screen, window, or tab content</li>
    <li><strong>Device Motion:</strong> Accelerometer and gyroscope data</li>
    <li><strong>Device Orientation:</strong> Compass and tilt sensors</li>
  </ul>
  
  <p style="margin-top: 1rem;"><strong>⚠️ Privacy & Permissions:</strong></p>
  <ul>
    <li>All hardware APIs require explicit user permission</li>
    <li>Permissions are per-origin and persist across sessions</li>
    <li>HTTPS required for most hardware access (secure context)</li>
    <li>Users can revoke permissions at any time</li>
  </ul>
  
  <p style="margin-top: 1rem;"><strong>📱 Device Compatibility:</strong></p>
  <ul>
    <li><strong>Camera/Microphone:</strong> Widely supported on all platforms</li>
    <li><strong>Screen Capture:</strong> Desktop browsers (Chrome, Firefox, Edge)</li>
    <li><strong>Motion Sensors:</strong> Mobile devices only (phones, tablets)</li>
    <li><strong>Orientation:</strong> Mobile devices with gyroscope/accelerometer</li>
  </ul>
</div>
