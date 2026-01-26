---
title: Multi-Room Chat
---

# Multi-Room Chat Demo

[← Back to Home](/pages/index.html)

## 💬 Real-Time Chat with Multiple Rooms

This chat system uses the **same message format as the MUD `say` command**, making it fully intercompatible! Messages are stored in `.log` files (one per room) with the format `[HH:MM] username: message`.

### How It Works

1. **Each room is a folder** on the server with a `.log` file
2. **Messages use MUD format:** `[HH:MM] player_name: message`
3. **Fully intercompatible:** Someone in the MUD could walk into a chat room folder, use `say`, and web users would see it!
4. **Anyone can create rooms** with custom names
5. **Delete empty rooms** when you're done

---

## Chat Interface

<div class="chat-container">
  <!-- Room selection sidebar -->
  <div class="chat-sidebar">
    <h3>Chat Rooms</h3>
    <div id="room-list" hx-get="/cgi/chat-list-rooms" hx-trigger="load, every 3s" hx-swap="innerHTML">
      Loading rooms...
    </div>
    
    <div class="room-controls">
      <h4>Create Room</h4>
      <input type="text" id="new-room-name" placeholder="Room name" />
      <button hx-get="/cgi/chat-create-room" hx-vals='js:{room: document.getElementById("new-room-name").value}' hx-target="#room-status" hx-swap="innerHTML">
        Create
      </button>
      <div id="room-status"></div>
    </div>
  </div>
  
  <!-- Chat messages area -->
  <div class="chat-main">
    <div class="chat-header">
      <h3 id="current-room-name">Select a room</h3>
      <button id="delete-room-btn" style="display: none;" hx-get="/cgi/chat-delete-room" hx-vals='js:{room: window.currentRoom}' hx-target="#room-status" hx-swap="innerHTML">
        Delete Room
      </button>
    </div>
    
    <div id="chat-messages" class="chat-display">
      <p class="meta">Select a room to start chatting</p>
    </div>
    
    <div class="chat-input-area">
      <input type="text" id="username-input" placeholder="Your name" value="WebUser" />
      <input type="text" id="message-input" placeholder="Type a message..." />
      <button id="send-btn" disabled>Send</button>
    </div>
  </div>
</div>

<script>
// Track current room
window.currentRoom = null;

// Handle room selection from list
document.addEventListener('htmx:afterSwap', function(event) {
  if (event.detail.target.id === 'room-list') {
    // Add click handlers to room items
    document.querySelectorAll('.room-item').forEach(function(item) {
      item.onclick = function() {
        var room = this.getAttribute('data-room');
        joinRoom(room);
      };
    });
  }
});

// Join a room
function joinRoom(roomName) {
  window.currentRoom = roomName;
  document.getElementById('current-room-name').textContent = 'Room: ' + roomName;
  document.getElementById('send-btn').disabled = false;
  document.getElementById('delete-room-btn').style.display = 'inline-block';
  
  // Load messages
  loadMessages();
  
  // Auto-refresh messages every 2 seconds
  if (window.messageInterval) {
    clearInterval(window.messageInterval);
  }
  window.messageInterval = setInterval(loadMessages, 2000);
}

// Load messages for current room
function loadMessages() {
  if (!window.currentRoom) return;
  
  htmx.ajax('GET', '/cgi/chat-get-messages?room=' + encodeURIComponent(window.currentRoom), {
    target: '#chat-messages',
    swap: 'innerHTML'
  });
}

// Send message
document.addEventListener('DOMContentLoaded', function() {
  var sendBtn = document.getElementById('send-btn');
  var messageInput = document.getElementById('message-input');
  var usernameInput = document.getElementById('username-input');
  
  function sendMessage() {
    if (!window.currentRoom) return;
    
    var msg = messageInput.value.trim();
    var user = usernameInput.value.trim() || 'Anonymous';
    
    if (!msg) return;
    
    // Send via POST
    var formData = 'room=' + encodeURIComponent(window.currentRoom) + 
                   '&user=' + encodeURIComponent(user) + 
                   '&msg=' + encodeURIComponent(msg);
    
    fetch('/cgi/chat-send-message', {
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: formData
    }).then(function() {
      messageInput.value = '';
      loadMessages();
    });
  }
  
  sendBtn.onclick = sendMessage;
  
  messageInput.addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
      sendMessage();
    }
  });
});
</script>

---

## MUD Intercompatibility

The chat system is **fully compatible with the MUD `say` command**! Here's how:

### Message Format

Both use the same `.log` file format:
```
[14:32] Alice: Hello everyone!
[14:33] Bob: Hi Alice!
[14:35] WebUser: This is from the web!
```

### Try It Yourself

1. Create a chat room on the web (e.g., "tavern")
2. In the MUD, navigate to `/tmp/wizardry-chat/tavern/`
3. Use `say "Hello from the MUD!"`
4. The message appears in the web chat!
5. Web users' messages appear in the MUD via `listen`

### Technical Details

- **Storage:** Each room is a directory with a `.log` file
- **Location:** `$TMPDIR/wizardry-chat/ROOMNAME/.log`
- **Format:** `[HH:MM] username: message` (same as MUD)
- **Commands:** Web users and MUD players share the same log
- **Real-time:** Auto-refreshes every 2 seconds

---

## Features Demo

**✓ Multiple chat rooms** - Create as many as you want  
**✓ Real-time updates** - Messages refresh automatically  
**✓ Custom usernames** - Set your display name  
**✓ Room creation** - Anyone can create new rooms  
**✓ Room deletion** - Delete when done  
**✓ MUD compatible** - Full interoperability with MUD `say` command  
**✓ Persistent state** - Messages stored in filesystem  
**✓ No database** - Just `.log` files!

---

## Navigation
- [Home](/pages/index.html)
- [Advanced Demos](/pages/advanced.html)
- [Poll](/pages/poll.html)
- [About](/pages/about.html)
