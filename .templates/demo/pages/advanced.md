---
title: Advanced Demos
---

<nav class="site-nav" style="margin-bottom: 2em; padding: 1em; background: #f5f5f5; border-radius: 5px;">
  <a href="/pages/index.html">Home</a> |
  <strong>Advanced Demos</strong> |
  <a href="/pages/poll.html">Poll</a> |
  <a href="/pages/chat.html">Chatrooms</a> |
  <a href="/pages/about.html">About</a>
</nav>

# Advanced Interactive Demos

## 1. System Information
Get real-time system information from the server:

<div class="demo-box">
  <button hx-get="/cgi/system-info" hx-target="#sysinfo-output" hx-swap="innerHTML">
    Get System Info
  </button>
  <div id="sysinfo-output" class="output"></div>
</div>

## 2. Color Picker
Choose a color and see it rendered by the server:

<div class="demo-box">
  <input type="color" id="color-input" value="#3498db" />
  <button hx-get="/cgi/color-picker" hx-vals='js:{color: document.getElementById("color-input").value}' hx-target="#color-output" hx-swap="innerHTML">
    Show Color
  </button>
  <div id="color-output" class="output"></div>
</div>

## 3. Temperature Converter
Convert between Celsius and Fahrenheit:

<div class="demo-box">
  <input type="number" id="temp-input" placeholder="Temperature" />
  <select id="temp-unit">
    <option value="C">Celsius to Fahrenheit</option>
    <option value="F">Fahrenheit to Celsius</option>
  </select>
  <button hx-get="/cgi/temperature-convert" hx-vals='js:{temp: document.getElementById("temp-input").value, unit: document.getElementById("temp-unit").value}' hx-target="#temp-output" hx-swap="innerHTML">
    Convert
  </button>
  <div id="temp-output" class="output"></div>
</div>

## 4. File Operations & Real-Time Upload

### Image Upload with Instant Display
Demonstrates real-time file upload and display - the uploaded image appears immediately:

<div class="demo-box">
  <h4>Upload & Display Image</h4>
  <input type="text" id="upload-filename" placeholder="Enter image name (e.g., logo.png)" value="demo-image.png" />
  <button hx-get="/cgi/upload-image" hx-vals='js:{filename: document.getElementById("upload-filename").value}' hx-target="#upload-display" hx-swap="innerHTML" class="primary">
    Upload & Display
  </button>
  <div id="upload-display" class="output">
    <p style="color: #666; font-style: italic;">Click Upload to see real-time image generation and display</p>
  </div>
</div>

### File Information
Get details about uploaded files:

<div class="demo-box">
  <input type="text" id="file-input" placeholder="Enter filename" value="document.pdf" />
  <button hx-get="/cgi/file-info" hx-vals='js:{name: document.getElementById("file-input").value}' hx-target="#file-output" hx-swap="innerHTML">
    Get File Info
  </button>
  <div id="file-output" class="output"></div>
</div>

## 5. Directory Browser
<div class="demo-box">
  <button hx-get="/cgi/list-files" hx-target="#files-output" hx-swap="innerHTML">
    List Files
  </button>
  <div id="files-output" class="output"></div>
</div>

## 6. Auto-Refresh Demo
This section refreshes every 5 seconds automatically:

<div class="demo-box">
  <div hx-get="/cgi/system-info" hx-trigger="every 5s" hx-swap="innerHTML" class="auto-refresh">
    <p style="color: #666; font-style: italic;">Loading...</p>
  </div>
</div>

## 7. Custom HTML Elements
Web Wizardry supports custom HTML elements with CSS styling. Here's a custom `<spell-card>` element:

<style>
spell-card {
  display: block;
  position: relative;
  padding: 2rem;
  margin: 1.5rem 0;
  border-radius: 12px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  box-shadow: 0 10px 30px rgba(102, 126, 234, 0.3), 0 1px 8px rgba(0, 0, 0, 0.2);
  color: white;
  overflow: hidden;
  transition: all 0.3s ease;
  border: 2px solid rgba(255, 255, 255, 0.1);
}

spell-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 15px 40px rgba(102, 126, 234, 0.4), 0 2px 12px rgba(0, 0, 0, 0.3);
}

spell-card::before {
  content: '';
  position: absolute;
  top: -50%;
  right: -50%;
  width: 200%;
  height: 200%;
  background: radial-gradient(circle, rgba(255, 255, 255, 0.1) 0%, transparent 70%);
  animation: shimmer 3s infinite;
  pointer-events: none;
}

@keyframes shimmer {
  0%, 100% { transform: translate(0, 0) rotate(0deg); opacity: 0; }
  50% { transform: translate(-30%, -30%) rotate(180deg); opacity: 1; }
}

spell-card[type="fire"] {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
  box-shadow: 0 10px 30px rgba(245, 87, 108, 0.3), 0 1px 8px rgba(0, 0, 0, 0.2);
}

spell-card[type="ice"] {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
  box-shadow: 0 10px 30px rgba(79, 172, 254, 0.3), 0 1px 8px rgba(0, 0, 0, 0.2);
}

spell-card[type="nature"] {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
  box-shadow: 0 10px 30px rgba(67, 233, 123, 0.3), 0 1px 8px rgba(0, 0, 0, 0.2);
}

spell-card .spell-title {
  font-size: 1.8rem;
  font-weight: bold;
  margin: 0 0 0.5rem 0;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
  letter-spacing: 0.5px;
}

spell-card .spell-icon {
  font-size: 3rem;
  position: absolute;
  right: 1.5rem;
  top: 50%;
  transform: translateY(-50%);
  opacity: 0.2;
  text-shadow: 2px 2px 8px rgba(0, 0, 0, 0.2);
}

spell-card .spell-description {
  margin: 0;
  line-height: 1.6;
  font-size: 1rem;
  text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.2);
}
</style>

<div class="demo-box">
  <p style="margin-bottom: 1rem;">Custom HTML elements let you create reusable, styled components. These `<spell-card>` elements demonstrate advanced CSS with gradients, shadows, and animations:</p>
  
  <spell-card>
    <div class="spell-title">⚡ Lightning Bolt</div>
    <div class="spell-icon">⚡</div>
    <div class="spell-description">A basic arcane spell that channels pure electrical energy. Deals moderate damage with high accuracy.</div>
  </spell-card>

  <spell-card type="fire">
    <div class="spell-title">🔥 Fireball</div>
    <div class="spell-icon">🔥</div>
    <div class="spell-description">Conjures a massive sphere of flame that explodes on impact. High damage with area effect.</div>
  </spell-card>

  <spell-card type="ice">
    <div class="spell-title">❄️ Frost Nova</div>
    <div class="spell-icon">❄️</div>
    <div class="spell-description">Freezes all enemies in the vicinity. Applies slow effect and deals cold damage over time.</div>
  </spell-card>

  <spell-card type="nature">
    <div class="spell-title">🌿 Nature's Blessing</div>
    <div class="spell-icon">🌿</div>
    <div class="spell-description">Channels the power of nature to heal allies and remove harmful effects. Restores health gradually.</div>
  </spell-card>
  
  <p style="margin-top: 1.5rem; color: #666; font-style: italic;">
    Hover over the cards to see the animation effects! These elements use pure CSS with no JavaScript required.
  </p>
</div>
