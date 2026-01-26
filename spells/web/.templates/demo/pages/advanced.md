---
title: Advanced Demos
---

# Advanced Interactive Demos

[← Back to Home](/pages/index.html)

## 🖥️ System Information
Get real-time system information from the server:

<div class="demo-box">
  <button hx-get="/cgi/system-info" hx-target="#sysinfo-output" hx-swap="innerHTML">
    Get System Info
  </button>
  <div id="sysinfo-output" class="output"></div>
</div>

## 🎨 Color Picker
Choose a color and see it rendered by the server:

<div class="demo-box">
  <input type="color" id="color-input" value="#3498db" />
  <button hx-get="/cgi/color-picker" hx-vals='js:{color: document.getElementById("color-input").value}' hx-target="#color-output" hx-swap="innerHTML">
    Show Color
  </button>
  <div id="color-output" class="output"></div>
</div>

## 🌡️ Temperature Converter
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

## 📁 File Browser (Demo)
Simulate file upload and browse directories:

<div class="demo-box">
  <input type="text" id="file-input" placeholder="Enter filename (demo)" value="document.pdf" />
  <button hx-get="/cgi/file-info" hx-vals='js:{file: document.getElementById("file-input").value}' hx-target="#file-output" hx-swap="innerHTML">
    Upload (Simulated)
  </button>
  <div id="file-output" class="output"></div>
</div>

<div class="demo-box">
  <button hx-get="/cgi/list-files" hx-target="#files-output" hx-swap="innerHTML">
    List Files
  </button>
  <div id="files-output" class="output"></div>
</div>

## 🔄 Auto-Refresh Demo
This section refreshes every 5 seconds automatically:

<div class="demo-box">
  <div hx-get="/cgi/system-info" hx-trigger="every 5s" hx-swap="innerHTML" class="auto-refresh">
    <p class="meta">Loading...</p>
  </div>
</div>

---

## Navigation
- [Home](/pages/index.html)
- [Advanced Demos](/pages/advanced.html)
- [Poll](/pages/poll.html)
- [Chat](/pages/chat.html)
- [About](/pages/about.html)
- [Home](/pages/index.html)
- [Poll](/pages/poll.html)
- [About](/pages/about.html)
