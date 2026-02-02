---
title: Interactive Poll
---

## 📊 Real-Time Poll

Vote for your favorite and see live results! Each vote is processed by a shell CGI script.

<div class="demo-box poll-container">
<h3>Which programming paradigm do you prefer?</h3>

<div class="poll-buttons">
<button hx-get="/cgi/poll-vote?vote=A" hx-target="#poll-results" hx-swap="morph" hx-ext="morph" class="poll-btn">
🔵 Functional Programming
</button>
<button hx-get="/cgi/poll-vote?vote=B" hx-target="#poll-results" hx-swap="morph" hx-ext="morph" class="poll-btn">
🟢 Object-Oriented
</button>
<button hx-get="/cgi/poll-vote?vote=C" hx-target="#poll-results" hx-swap="morph" hx-ext="morph" class="poll-btn">
🟡 Procedural
</button>
</div>

<div id="poll-results" hx-get="/cgi/poll-vote" hx-trigger="load" hx-swap="morph" hx-ext="morph">
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

