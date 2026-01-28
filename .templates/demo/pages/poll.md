---
title: Interactive Poll
---

<nav class="site-nav" style="margin-bottom: 2em; padding: 1em; background: #f5f5f5; border-radius: 5px;">
  <a href="/pages/index.html">Home</a> |
  <a href="/pages/advanced.html">Advanced Demos</a> |
  <strong>Poll</strong> |
  <a href="/pages/chat.html">Chatrooms</a> |
  <a href="/pages/about.html">About</a>
</nav>

# Interactive Voting Poll

## 📊 Real-Time Poll

Vote for your favorite and see live results! Each vote is processed by a shell CGI script.

<div class="demo-box poll-container">
<h3>Which programming paradigm do you prefer?</h3>

<div class="poll-buttons">
<button hx-get="/cgi/poll-vote?vote=A" hx-target="#poll-results" hx-swap="innerHTML" class="poll-btn">
🔵 Functional Programming
</button>
<button hx-get="/cgi/poll-vote?vote=B" hx-target="#poll-results" hx-swap="innerHTML" class="poll-btn">
🟢 Object-Oriented
</button>
<button hx-get="/cgi/poll-vote?vote=C" hx-target="#poll-results" hx-swap="innerHTML" class="poll-btn">
🟡 Procedural
</button>
</div>

<div id="poll-results" class="output" hx-get="/cgi/poll-vote" hx-trigger="load" hx-swap="innerHTML">
Loading results...
</div>
</div>

---

## How It Works

1. **Click a button** - Your vote is sent to `/cgi/poll-vote`
2. **Shell script runs** - A POSIX shell script processes the vote
3. **Results update** - HTML is returned and swapped into the page
4. **No page reload** - htmx handles the AJAX magic
5. **Pure shell backend** - No Node.js, Python, or PHP needed!

The poll state is stored in a simple text file on the server. Every vote:
- Reads the current vote counts
- Increments the selected option  
- Calculates percentages
- Returns formatted HTML

---

## Custom Component Demo

This is a custom reusable component showing repeated elements:

<div class="component-demo">
<div class="card">
<h4>Component 1</h4>
<p>This card is generated from a template</p>
<button hx-get="/cgi/random-quote" hx-target="#card1-content" hx-swap="innerHTML">Refresh</button>
<div id="card1-content"></div>
</div>

<div class="card">
<h4>Component 2</h4>
<p>Each can be independently updated</p>
<button hx-get="/cgi/random-quote" hx-target="#card2-content" hx-swap="innerHTML">Refresh</button>
<div id="card2-content"></div>
</div>

<div class="card">
<h4>Component 3</h4>
<p>All powered by CGI shell scripts</p>
<button hx-get="/cgi/random-quote" hx-target="#card3-content" hx-swap="innerHTML">Refresh</button>
<div id="card3-content"></div>
</div>
</div>
