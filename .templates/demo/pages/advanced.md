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
