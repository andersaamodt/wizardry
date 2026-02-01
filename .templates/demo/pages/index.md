---
title: web wizardry demo
---

# web wizardry interactive demos

Welcome to the **web wizardry platform** demo site! This showcases real-time interactivity powered by POSIX shell scripts via CGI.

## 🚀 Quick Start Demos

### 1. Echo Chamber
Type something and watch it echo back from the server:

<div class="demo-box">
  <input type="text" id="echo-input" placeholder="Type something..." hx-get="/cgi/echo-text" hx-vals='js:{text: document.getElementById("echo-input").value}' hx-target="#echo-output" hx-swap="innerHTML" hx-trigger="keyup[key=='Enter']" />
  <button hx-get="/cgi/echo-text" hx-vals='js:{text: document.getElementById("echo-input").value}' hx-target="#echo-output" hx-swap="innerHTML">
    Echo!
  </button>
  <div id="echo-output" class="output"></div>
</div>

### 2. Click Counter
Every click increments a counter on the server:

<div class="demo-box">
  <button hx-get="/cgi/counter" hx-target="#counter-output" hx-swap="innerHTML" hx-trigger="click" class="big-button">
    🔢 Click Me!
  </button>
  <button hx-get="/cgi/counter-reset" hx-target="#counter-output" hx-swap="innerHTML" hx-trigger="click" style="margin-left: 10px;">
    🔄 Reset
  </button>
  <div id="counter-output" class="output"></div>
</div>

### 3. Random Quote Generator
Get a random inspirational quote from the server:

<div class="demo-box">
  <button hx-get="/cgi/random-quote" hx-target="#quote-output" hx-swap="innerHTML">
    Get Random Quote
  </button>
  <div id="quote-output" class="output"></div>
</div>

### 4. Real-time Note Saver
Type notes that are saved to the server in real-time:

<div class="demo-box">
  <textarea id="note-input" placeholder="Type your note..." rows="3" hx-post="/cgi/save-note" hx-vals='js:{note: document.getElementById("note-input").value}' hx-target="#note-output" hx-swap="innerHTML" hx-trigger="keyup[key=='Enter' && ctrlKey]"></textarea>
  <button hx-post="/cgi/save-note" hx-vals='js:{note: document.getElementById("note-input").value}' hx-target="#note-output" hx-swap="innerHTML">
    Save Note
  </button>
  <div id="note-output" class="output"></div>
</div>

### 5. Calculator
Simple arithmetic calculator running on the server:

<div class="demo-box">
  <input type="text" id="calc-input" placeholder="e.g., 42 * 3 + 15" hx-get="/cgi/calc" hx-vals='js:{expr: document.getElementById("calc-input").value}' hx-target="#calc-output" hx-swap="innerHTML" hx-trigger="keyup[key=='Enter']" />
  <button hx-get="/cgi/calc" hx-vals='js:{expr: document.getElementById("calc-input").value}' hx-target="#calc-output" hx-swap="innerHTML">
    Calculate
  </button>
  <div id="calc-output" class="output"></div>
</div>

### 6. Text Reverser
Reverse any text using shell commands:

<div class="demo-box">
  <input type="text" id="reverse-input" placeholder="Enter text to reverse" hx-get="/cgi/reverse-text" hx-vals='js:{text: document.getElementById("reverse-input").value}' hx-target="#reverse-output" hx-swap="innerHTML" hx-trigger="keyup[key=='Enter']" />
  <button hx-get="/cgi/reverse-text" hx-vals='js:{text: document.getElementById("reverse-input").value}' hx-target="#reverse-output" hx-swap="innerHTML">
    Reverse
  </button>
  <div id="reverse-output" class="output"></div>
</div>

### 7. Word Counter
Count words, characters, and lines:

<div class="demo-box">
  <textarea id="wordcount-input" placeholder="Paste your text here..." rows="4" hx-get="/cgi/word-count" hx-vals='js:{text: document.getElementById("wordcount-input").value}' hx-target="#wordcount-output" hx-swap="innerHTML" hx-trigger="keyup[key=='Enter' && ctrlKey]"></textarea>
  <button hx-get="/cgi/word-count" hx-vals='js:{text: document.getElementById("wordcount-input").value}' hx-target="#wordcount-output" hx-swap="innerHTML">
    Count Words
  </button>
  <div id="wordcount-output" class="output"></div>
</div>

---

## 8. Image Upload & Display
Upload an image and see it displayed instantly:

<div class="demo-box">
  <input type="text" id="upload-filename" placeholder="Enter image name (e.g., logo.png)" value="demo-image.png" />
  <button hx-get="/cgi/upload-image" hx-vals='js:{filename: document.getElementById("upload-filename").value}' hx-target="#upload-display" hx-swap="innerHTML" hx-trigger="click, keyup[key=='Enter'] from:#upload-filename" class="primary">
    Upload & Display
  </button>
  <div id="upload-display" class="output">
  </div>
</div>

---

## 🎨 More Demos

**Browser API Demos:**
- [State & Persistence](/pages/storage.html) - localStorage, sessionStorage, IndexedDB, cookies
- [Forms & Input](/pages/forms-input.html) - Keyboard, pointer events, forms, clipboard
- [Graphics & Media](/pages/graphics-media.html) - Canvas 2D, SVG, audio, WebGL, WebGPU
- [Time & Performance](/pages/time-performance.html) - Timers, animation frames, performance API
- [Workers & Background](/pages/workers.html) - Web Workers, Service Workers, message passing
- [Hardware & Sensors](/pages/hardware.html) - Camera, microphone, screen capture, motion sensors
- [Security & Permissions](/pages/security.html) - Same-origin policy, permissions API, secure contexts
- [File Upload](/pages/file-upload.html) - File picker, drag-and-drop, blobs, Filesystem Access API
- [More APIs](/pages/misc-apis.html) - Vibration, battery, network info, wake lock, page lifecycle

**Server Demos:**
- [Advanced Demos](/pages/advanced.html) - System info, color picker, custom elements
- [Multi-Room Chat](/pages/chat.html) - Real-time chat with MUD compatibility
- [Interactive Poll](/pages/poll.html) - Real-time voting system
- [About](/pages/about.html) - Learn about web wizardry

---

<div class="info-box">
  <strong>💡 How It Works:</strong> Every button click triggers a CGI script written in POSIX shell. 
  The server executes the script and returns HTML, which htmx swaps into the page. No JavaScript 
  frameworks needed - just shell scripts!

  <h3 style="margin-top: 1.5rem; margin-bottom: 0.75rem;">Technologies Used:</h3>
  <ul style="margin: 0; padding-left: 1.5rem;">
    <li><strong>POSIX Shell Scripts:</strong> Backend logic and CGI handlers</li>
    <li><strong>htmx:</strong> Frontend AJAX without JavaScript frameworks</li>
    <li><strong>nginx:</strong> Fast web server and CGI gateway</li>
    <li><strong>fcgiwrap:</strong> FastCGI wrapper for shell scripts</li>
    <li><strong>Pandoc:</strong> Markdown to HTML conversion</li>
    <li><strong>Wizardry Spells:</strong> Modular shell script utilities</li>
  </ul>
</div>
