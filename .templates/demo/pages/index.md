---
title: Wizardry Web Demo
---

# Wizardry Web Interactive Demos

Welcome to the **Wizardry Web Platform** demo site! This showcases real-time interactivity powered by POSIX shell scripts via CGI.

## 🚀 Quick Start Demos

### 1. Echo Chamber
Type something and watch it echo back from the server:

<div class="demo-box">
  <input type="text" id="echo-input" placeholder="Type something..." hx-get="/cgi/echo-text" hx-vals='js:{text: document.getElementById("echo-input").value}' hx-target="#echo-output" hx-swap="innerHTML" hx-trigger="keyup[keyCode==13]" />
  <button hx-get="/cgi/echo-text" hx-vals='js:{text: document.getElementById("echo-input").value}' hx-target="#echo-output" hx-swap="innerHTML">
    Echo!
  </button>
  <div id="echo-output" class="output"></div>
</div>

### 2. Click Counter
Every click increments a counter on the server:

<div class="demo-box">
  <button hx-get="/cgi/counter" hx-target="#counter-output" hx-swap="innerHTML" class="big-button">
    🔢 Click Me!
  </button>
  <button hx-get="/cgi/counter-reset" hx-target="#counter-output" hx-swap="innerHTML" style="margin-left: 10px;">
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
  <textarea id="note-input" placeholder="Type your note..." rows="3"></textarea>
  <button hx-post="/cgi/save-note" hx-vals='js:{note: document.getElementById("note-input").value}' hx-target="#note-output" hx-swap="innerHTML">
    Save Note
  </button>
  <div id="note-output" class="output"></div>
</div>

### 5. Calculator
Simple arithmetic calculator running on the server:

<div class="demo-box">
  <input type="text" id="calc-input" placeholder="e.g., 42 * 3 + 15" hx-get="/cgi/calc" hx-vals='js:{expr: document.getElementById("calc-input").value}' hx-target="#calc-output" hx-swap="innerHTML" hx-trigger="keyup[keyCode==13]" />
  <button hx-get="/cgi/calc" hx-vals='js:{expr: document.getElementById("calc-input").value}' hx-target="#calc-output" hx-swap="innerHTML">
    Calculate
  </button>
  <div id="calc-output" class="output"></div>
</div>

### 6. Text Reverser
Reverse any text using shell commands:

<div class="demo-box">
  <input type="text" id="reverse-input" placeholder="Enter text to reverse" hx-get="/cgi/reverse-text" hx-vals='js:{text: document.getElementById("reverse-input").value}' hx-target="#reverse-output" hx-swap="innerHTML" hx-trigger="keyup[keyCode==13]" />
  <button hx-get="/cgi/reverse-text" hx-vals='js:{text: document.getElementById("reverse-input").value}' hx-target="#reverse-output" hx-swap="innerHTML">
    Reverse
  </button>
  <div id="reverse-output" class="output"></div>
</div>

### 7. Word Counter
Count words, characters, and lines:

<div class="demo-box">
  <textarea id="wordcount-input" placeholder="Paste your text here..." rows="4" hx-get="/cgi/word-count" hx-vals='js:{text: document.getElementById("wordcount-input").value}' hx-target="#wordcount-output" hx-swap="innerHTML" hx-trigger="keyup[keyCode==13]"></textarea>
  <button hx-get="/cgi/word-count" hx-vals='js:{text: document.getElementById("wordcount-input").value}' hx-target="#wordcount-output" hx-swap="innerHTML">
    Count Words
  </button>
  <div id="wordcount-output" class="output"></div>
</div>
    Count Words
  </button>
  <div id="wordcount-output" class="output"></div>
</div>

---

## 🎨 More Demos

- [Advanced Demos](/pages/advanced.html) - System info, file operations, and more
- [Multi-Room Chat](/pages/chat.html) - Real-time chat with MUD compatibility
- [Interactive Poll](/pages/poll.html) - Real-time voting system
- [About](/pages/about.html) - Learn about Wizardry Web

---

<div class="info-box">
  <strong>💡 How It Works:</strong> Every button click triggers a CGI script written in POSIX shell. 
  The server executes the script and returns HTML, which htmx swaps into the page. No JavaScript 
  frameworks needed - just shell scripts!
</div>
