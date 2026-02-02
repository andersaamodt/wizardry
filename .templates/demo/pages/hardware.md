---
title: Hardware & Sensors
---

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

## 4. GPS / Geolocation

Access device location using GPS and other positioning methods:

<div class="demo-box">
<h3>📍 Geolocation API</h3>
  
<div style="margin-bottom: 1rem; display: flex; gap: 0.5rem; flex-wrap: wrap;">
<button id="geo-current">📍 Get Current Position</button>
<button id="geo-watch">🔄 Watch Position</button>
<button id="geo-stop">⏹️ Stop Watching</button>
</div>
  
<div id="geo-output" class="output"></div>
  
<div id="geo-display" style="display: none; margin-top: 1rem;">
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1rem;">
<div style="background: #e3f2fd; padding: 1rem; border-radius: 4px;">
<h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">📍 Coordinates</h4>
<p style="margin: 0.25rem 0;"><strong>Latitude:</strong> <span id="geo-lat">-</span>°</p>
<p style="margin: 0.25rem 0;"><strong>Longitude:</strong> <span id="geo-lon">-</span>°</p>
<p style="margin: 0.25rem 0;"><strong>Altitude:</strong> <span id="geo-alt">-</span> m</p>
</div>
      
<div style="background: #f3e5f5; padding: 1rem; border-radius: 4px;">
<h4 style="margin: 0 0 0.5rem 0; color: #6a1b9a;">🎯 Accuracy</h4>
<p style="margin: 0.25rem 0;"><strong>Position:</strong> <span id="geo-acc">-</span> m</p>
<p style="margin: 0.25rem 0;"><strong>Altitude:</strong> <span id="geo-alt-acc">-</span> m</p>
</div>
      
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">🧭 Movement</h4>
<p style="margin: 0.25rem 0;"><strong>Heading:</strong> <span id="geo-heading">-</span>°</p>
<p style="margin: 0.25rem 0;"><strong>Speed:</strong> <span id="geo-speed">-</span> m/s</p>
<p style="margin: 0.25rem 0;"><strong>Updated:</strong> <span id="geo-time">-</span></p>
</div>
</div>
    
<div id="geo-map" style="margin-top: 1rem; padding: 1rem; background: #f8f9fa; border-radius: 4px; text-align: center;">
<a id="geo-map-link" href="#" target="_blank" style="display: inline-block; padding: 0.75rem 1.5rem; background: #4caf50; color: white; border-radius: 4px; text-decoration: none; font-weight: bold;">🗺️ View on OpenStreetMap</a>
</div>
</div>
</div>

<script>
(function() {
  const output = document.getElementById('geo-output');
  const display = document.getElementById('geo-display');
  const mapLink = document.getElementById('geo-map-link');
  let watchId = null;
  
  function updatePosition(position) {
    const coords = position.coords;
    
    // Update coordinates
    document.getElementById('geo-lat').textContent = coords.latitude.toFixed(6);
    document.getElementById('geo-lon').textContent = coords.longitude.toFixed(6);
    document.getElementById('geo-alt').textContent = coords.altitude !== null ? coords.altitude.toFixed(1) : 'N/A';
    
    // Update accuracy
    document.getElementById('geo-acc').textContent = coords.accuracy.toFixed(1);
    document.getElementById('geo-alt-acc').textContent = coords.altitudeAccuracy !== null ? coords.altitudeAccuracy.toFixed(1) : 'N/A';
    
    // Update movement
    document.getElementById('geo-heading').textContent = coords.heading !== null ? coords.heading.toFixed(1) : 'N/A';
    document.getElementById('geo-speed').textContent = coords.speed !== null ? coords.speed.toFixed(2) : 'N/A';
    document.getElementById('geo-time').textContent = new Date(position.timestamp).toLocaleTimeString();
    
    // Update map link
    mapLink.href = `https://www.openstreetmap.org/?mlat=${coords.latitude}&mlon=${coords.longitude}&zoom=15`;
    
    display.style.display = 'block';
  }
  
  function showError(error) {
    const errorMessages = {
      1: 'Permission denied - please allow location access',
      2: 'Position unavailable - unable to retrieve location',
      3: 'Timeout - location request took too long'
    };
    
    output.innerHTML = `
<div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
<h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ Geolocation Error</h4>
<p style="margin: 0.25rem 0;"><strong>Error Code:</strong> ${error.code}</p>
<p style="margin: 0.25rem 0;"><strong>Message:</strong> ${errorMessages[error.code] || error.message}</p>
<p style="margin: 0.5rem 0 0 0; color: #666; font-size: 0.9rem;">
          Make sure location services are enabled and you've granted permission to this site.
</p>
</div>
    `;
  }
  
  function showSuccess(isWatching) {
    output.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ Location ${isWatching ? 'Tracking Active' : 'Retrieved'}</h4>
<p style="margin: 0;">${isWatching ? 'Continuously monitoring your position. Move around to see updates.' : 'Current position displayed below.'}</p>
</div>
    `;
  }
  
  document.getElementById('geo-current').addEventListener('click', () => {
    if (!navigator.geolocation) {
      output.innerHTML = `
<div style="background: #fff3e0; padding: 1rem; border-radius: 4px; border: 1px solid #ff9800;">
<h4 style="margin: 0 0 0.5rem 0; color: #e65100;">⚠️ Geolocation Not Supported</h4>
<p style="margin: 0;">Your browser does not support the Geolocation API.</p>
</div>
      `;
      return;
    }
    
    output.innerHTML = '<p style="color: #2980b9;">🔍 Getting your location...</p>';
    
    navigator.geolocation.getCurrentPosition(
      (position) => {
        updatePosition(position);
        showSuccess(false);
      },
      showError,
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    );
  });
  
  document.getElementById('geo-watch').addEventListener('click', () => {
    if (!navigator.geolocation) {
      output.innerHTML = `
<div style="background: #fff3e0; padding: 1rem; border-radius: 4px; border: 1px solid #ff9800;">
<h4 style="margin: 0 0 0.5rem 0; color: #e65100;">⚠️ Geolocation Not Supported</h4>
<p style="margin: 0;">Your browser does not support the Geolocation API.</p>
</div>
      `;
      return;
    }
    
    if (watchId !== null) {
      output.innerHTML = '<p class="error">Already watching position. Stop first.</p>';
      return;
    }
    
    output.innerHTML = '<p style="color: #2980b9;">🔄 Starting position tracking...</p>';
    
    watchId = navigator.geolocation.watchPosition(
      (position) => {
        updatePosition(position);
        showSuccess(true);
      },
      showError,
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    );
  });
  
  document.getElementById('geo-stop').addEventListener('click', () => {
    if (watchId !== null) {
      navigator.geolocation.clearWatch(watchId);
      watchId = null;
      output.innerHTML = '<p style="color: #7f8c8d;">⏹️ Stopped watching position</p>';
    } else {
      output.innerHTML = '<p style="color: #7f8c8d;">Not currently watching position</p>';
    }
  });
})();
</script>

## 5. Device Motion & Orientation

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

## 6. Media Recorder API

Record audio and video from camera/microphone to downloadable files:

<div class="demo-box">
<h3>🎬 Media Recorder</h3>
  
<div style="margin-bottom: 1rem;">
<video id="recorder-preview" autoplay muted playsinline style="max-width: 100%; border: 2px solid #ddd; border-radius: 4px; background: #000;"></video>
</div>
  
<div style="display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 1rem;">
<button id="recorder-start-camera">📹 Start Camera</button>
<button id="recorder-start-recording">⏺️ Start Recording</button>
<button id="recorder-stop-recording">⏹️ Stop Recording</button>
<button id="recorder-download">⬇️ Download</button>
<select id="recorder-type" style="padding: 0.5rem;">
<option value="video/webm">Video (WebM)</option>
<option value="video/webm;codecs=vp9">Video VP9 (WebM)</option>
<option value="video/mp4">Video (MP4)</option>
</select>
</div>
  
<video id="recorder-playback" controls style="max-width: 100%; border: 2px solid #ddd; border-radius: 4px; display: none; margin-top: 1rem;"></video>
  
<div id="recorder-output" class="output"></div>
</div>

<script>
(function() {
  const preview = document.getElementById('recorder-preview');
  const playback = document.getElementById('recorder-playback');
  const output = document.getElementById('recorder-output');
  const typeSelect = document.getElementById('recorder-type');
  let stream = null;
  let mediaRecorder = null;
  let recordedChunks = [];
  
  document.getElementById('recorder-start-camera').addEventListener('click', async () => {
    try {
      stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
      preview.srcObject = stream;
      preview.style.display = 'block';
      
      output.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ Camera Ready</h4>
<p style="margin: 0;">Click "Start Recording" to begin capturing video.</p>
</div>
      `;
    } catch (error) {
      output.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
  
  document.getElementById('recorder-start-recording').addEventListener('click', () => {
    if (!stream) {
      output.innerHTML = '<p class="error">Start camera first</p>';
      return;
    }
    
    recordedChunks = [];
    const mimeType = typeSelect.value;
    
    try {
      mediaRecorder = new MediaRecorder(stream, { mimeType });
      
      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          recordedChunks.push(event.data);
        }
      };
      
      mediaRecorder.onstop = () => {
        const blob = new Blob(recordedChunks, { type: mimeType });
        const url = URL.createObjectURL(blob);
        
        playback.src = url;
        playback.style.display = 'block';
        
        document.getElementById('recorder-download').onclick = () => {
          const a = document.createElement('a');
          a.href = url;
          a.download = `recording-${Date.now()}.${mimeType.includes('mp4') ? 'mp4' : 'webm'}`;
          a.click();
        };
        
        output.innerHTML = `
<div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3;">
<h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">🎬 Recording Complete</h4>
<p style="margin: 0.25rem 0;"><strong>Size:</strong> ${(blob.size / 1024).toFixed(2)} KB</p>
<p style="margin: 0.25rem 0;"><strong>Duration:</strong> ${recordedChunks.length} chunks</p>
<p style="margin: 0.5rem 0 0 0;">Playback ready. Click Download to save.</p>
</div>
        `;
      };
      
      mediaRecorder.start(100); // Collect data every 100ms
      
      output.innerHTML = `
<div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
<h4 style="margin: 0 0 0.5rem 0; color: #c62828;">⏺️ Recording...</h4>
<p style="margin: 0;">Click "Stop Recording" when done.</p>
</div>
      `;
    } catch (error) {
      output.innerHTML = `
<p class="error">MediaRecorder not supported with ${mimeType}. Try a different format.</p>
      `;
    }
  });
  
  document.getElementById('recorder-stop-recording').addEventListener('click', () => {
    if (mediaRecorder && mediaRecorder.state !== 'inactive') {
      mediaRecorder.stop();
    } else {
      output.innerHTML = '<p style="color: #7f8c8d;">Not currently recording</p>';
    }
  });
})();
</script>

## 7. Picture-in-Picture API

Create floating video windows:

<div class="demo-box">
<h3>📺 Picture-in-Picture</h3>
  
<video id="pip-video" controls style="max-width: 100%; border: 2px solid #ddd; border-radius: 4px; background: #000;">
<source src="data:video/mp4;base64,AAAAIGZ0eXBpc29tAAACAGlzb21pc28yYXZjMW1wNDEAAAAIZnJlZQAACKBtZGF0AAACrgYF//+q3EXpvebZSLeWLNgg2SPu73gyNjQgLSBjb3JlIDE0OCByMjY2MyA1YzY1NzA0IC0gSC4yNjQvTVBFRy00IEFWQyBjb2RlYyAtIENvcHlsZWZ0IDIwMDMtMjAxNSAtIGh0dHA6Ly93d3cudmlkZW9sYW4ub3JnL3gyNjQuaHRtbCAtIG9wdGlvbnM6IGNhYmFjPTEgcmVmPTMgZGVibG9jaz0xOjA6MCBhbmFseXNlPTB4MzoweDExMyBtZT1oZXggc3VibWU9NyBwc3k9MSBwc3lfcmQ9MS4wMDowLjAwIG1peGVkX3JlZj0xIG1lX3JhbmdlPTE2IGNocm9tYV9tZT0xIHRyZWxsaXM9MSA4eDhkY3Q9MSBjcW09MCBkZWFkem9uZT0yMSwxMSBmYXN0X3Bza2lwPTEgY2hyb21hX3FwX29mZnNldD0tMiB0aHJlYWRzPTEyIGxvb2thaGVhZF90aHJlYWRzPTIgc2xpY2VkX3RocmVhZHM9MCBucj0wIGRlY2ltYXRlPTEgaW50ZXJsYWNlZD0wIGJsdXJheV9jb21wYXQ9MCBjb25zdHJhaW5lZF9pbnRyYT0wIGJmcmFtZXM9MyBiX3B5cmFtaWQ9MiBiX2FkYXB0PTEgYl9iaWFzPTAgZGlyZWN0PTEgd2VpZ2h0Yj0xIG9wZW5fZ29wPTAgd2VpZ2h0cD0yIGtleWludD0yNTAga2V5aW50X21pbj0yNSBzY2VuZWN1dD00MCBpbnRyYV9yZWZyZXNoPTAgcmNfbG9va2FoZWFkPTQwIHJjPWNyZiBtYnRyZWU9MSBjcmY9MjMuMCBxY29tcD0wLjYwIHFwbWluPTAgcXBtYXg9NjkgcXBzdGVwPTQgaXBfcmF0aW89MS40MCBhcT0xOjEuMDAAgAAAAAwliIQAV/0TAAYdgAAAMAAAG/kAwIFBIBIB" type="video/mp4">
</video>
  
<div style="margin-top: 1rem; display: flex; gap: 0.5rem; flex-wrap: wrap;">
<button id="pip-enter">📺 Enter PiP</button>
<button id="pip-exit">❌ Exit PiP</button>
<button id="pip-use-camera">📹 Use Camera Feed</button>
</div>
  
<div id="pip-output" class="output"></div>
</div>

<script>
(function() {
  const video = document.getElementById('pip-video');
  const output = document.getElementById('pip-output');
  
  // Create a simple canvas animation as default content
  const canvas = document.createElement('canvas');
  canvas.width = 640;
  canvas.height = 360;
  const ctx = canvas.getContext('2d');
  
  function drawAnimation() {
    const time = Date.now() / 1000;
    ctx.fillStyle = 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    ctx.fillStyle = 'white';
    ctx.font = '48px Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('PiP Demo', canvas.width / 2, canvas.height / 2 - 30);
    
    ctx.font = '24px Arial';
    ctx.fillText(new Date().toLocaleTimeString(), canvas.width / 2, canvas.height / 2 + 20);
    
    // Animated circle
    const x = canvas.width / 2 + Math.cos(time) * 100;
    const y = canvas.height / 2 + Math.sin(time) * 50;
    ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
    ctx.beginPath();
    ctx.arc(x, y, 30, 0, Math.PI * 2);
    ctx.fill();
  }
  
  let animationInterval = setInterval(drawAnimation, 1000 / 30);
  const stream = canvas.captureStream(30);
  video.srcObject = stream;
  video.play();
  
  document.getElementById('pip-enter').addEventListener('click', async () => {
    try {
      if (document.pictureInPictureElement) {
        output.innerHTML = '<p class="error">Already in PiP mode</p>';
        return;
      }
      
      await video.requestPictureInPicture();
      
      output.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">📺 Picture-in-Picture Active</h4>
<p style="margin: 0;">Video is now floating! You can move it around and resize it.</p>
</div>
      `;
    } catch (error) {
      output.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
  
  document.getElementById('pip-exit').addEventListener('click', async () => {
    try {
      if (document.pictureInPictureElement) {
        await document.exitPictureInPicture();
      } else {
        output.innerHTML = '<p style="color: #7f8c8d;">Not in PiP mode</p>';
      }
    } catch (error) {
      output.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
  
  document.getElementById('pip-use-camera').addEventListener('click', async () => {
    try {
      const cameraStream = await navigator.mediaDevices.getUserMedia({ video: true });
      clearInterval(animationInterval);
      video.srcObject = cameraStream;
      video.play();
      
      output.innerHTML = `
<div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3;">
<h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">📹 Camera Feed Active</h4>
<p style="margin: 0;">Now showing camera feed. Try entering PiP mode!</p>
</div>
      `;
    } catch (error) {
      output.innerHTML = `<p class="error">Camera error: ${error.message}</p>`;
    }
  });
  
  video.addEventListener('enterpictureinpicture', () => {
    output.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">📺 Entered PiP Mode</h4>
<p style="margin: 0;">Video is floating on your screen!</p>
</div>
    `;
  });
  
  video.addEventListener('leavepictureinpicture', () => {
    output.innerHTML = '<p style="color: #7f8c8d;">Left PiP mode</p>';
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
<li><strong>Geolocation API:</strong> Access GPS and device location with accuracy data</li>
<li><strong>Device Motion:</strong> Accelerometer and gyroscope data</li>
<li><strong>Device Orientation:</strong> Compass and tilt sensors</li>
<li><strong>Media Recorder API:</strong> Record audio/video to downloadable files</li>
<li><strong>Picture-in-Picture:</strong> Floating video windows</li>
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
<li><strong>Geolocation:</strong> All modern browsers (mobile devices typically more accurate)</li>
<li><strong>Motion Sensors:</strong> Mobile devices only (phones, tablets)</li>
<li><strong>Orientation:</strong> Mobile devices with gyroscope/accelerometer</li>
<li><strong>Media Recorder:</strong> Chrome, Firefox, Edge, Safari (format support varies)</li>
<li><strong>Picture-in-Picture:</strong> Chrome, Edge, Safari (desktop and mobile). Firefox requires Document Picture-in-Picture API (different implementation)</li>
</ul>
</div>
