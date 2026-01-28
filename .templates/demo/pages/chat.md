---
title: Chatrooms
---

<nav class="site-nav" style="margin-bottom: 2em; padding: 1em; background: #f5f5f5; border-radius: 5px;">
  <a href="/pages/index.html">Home</a> |
  <a href="/pages/advanced.html">Advanced Demos</a> |
  <a href="/pages/poll.html">Poll</a> |
  <strong>Chatrooms</strong> |
  <a href="/pages/about.html">About</a>
</nav>

# Chatrooms Demo

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
<div class="chat-sidebar">
<h3>Chat Rooms</h3>
<div id="room-list" hx-get="/cgi/chat-list-rooms" hx-trigger="load, every 2s" hx-swap="innerHTML settle:0ms">
Loading rooms...
</div>

<div class="room-controls">
<h4>Create Room</h4>
<input type="text" id="new-room-name" placeholder="Room name" />
<button id="create-room-btn" hx-get="/cgi/chat-create-room" hx-vals='js:{name: document.getElementById("new-room-name").value}' hx-target="#room-status" hx-swap="innerHTML" hx-trigger="click, keyup[key=='Enter'] from:#new-room-name" hx-on::before-request="document.getElementById('create-room-btn').disabled = true; document.getElementById('new-room-name').disabled = true; document.getElementById('create-room-btn').innerHTML = 'Creating<span class=\'spinner\'></span>';" hx-on::after-request="if(event.detail.successful) { document.getElementById('new-room-name').value = ''; htmx.trigger('#room-list', 'load'); }">
Create
</button>
<div id="room-status"></div>
</div>
</div>

<div class="chat-main">
<div class="chat-header">
<h3 id="current-room-name">Select a room</h3>
<button id="delete-room-btn" style="display: none;" onclick="deleteRoom()">
Delete Room
</button>
</div>

<div id="chat-messages" class="chat-display">
<div class="chat-messages">
<p style="color: #666; font-style: italic;">Select a room to start chatting</p>
</div>
</div>

<div class="chat-input-area" id="chat-input-area" style="display: none;">
<input type="text" id="username-input" placeholder="Your name" value="" />
<input type="text" id="message-input" placeholder="Type a message..." />
<button id="send-btn" disabled>Send</button>
</div>
</div>
</div>

<script>
// Generate a random guest name with collision handling
function generateGuestName(digits) {
  digits = digits || 1;
  var max = Math.pow(10, digits) - 1;
  var min = digits === 1 ? 0 : Math.pow(10, digits - 1);
  var num = Math.floor(Math.random() * (max - min + 1)) + min;
  return 'Guest' + num;
}

// Track current room
window.currentRoom = null;
window.hoveredRoom = null;
window.usedGuestNames = {};  // Track guest names used in current session
window.currentDigits = 1;  // Start with 1-digit numbers

// Handle room selection from list
document.addEventListener('htmx:afterSwap', function(event) {
  if (event.detail.target.id === 'room-list') {
    // Re-enable create room button after room list refreshes
    document.getElementById('create-room-btn').disabled = false;
    document.getElementById('new-room-name').disabled = false;
    document.getElementById('create-room-btn').innerHTML = 'Create';
    
    // Re-enable delete room button after room list refreshes
    var deleteBtn = document.getElementById('delete-room-btn');
    deleteBtn.disabled = false;
    deleteBtn.innerHTML = 'Delete Room';
    
    // Remove hover class from all items first (prevents lingering)
    document.querySelectorAll('.room-item').forEach(function(item) {
      item.classList.remove('room-item-hover');
    });
    
    // Add click handlers to room items and restore hover state
    document.querySelectorAll('.room-item').forEach(function(item) {
      item.onclick = function() {
        var room = this.getAttribute('data-room');
        joinRoom(room);
      };
      
      // Track hover state to preserve across refreshes
      item.addEventListener('mouseenter', function() {
        window.hoveredRoom = this.getAttribute('data-room');
        this.classList.add('room-item-hover');
      });
      item.addEventListener('mouseleave', function() {
        this.classList.remove('room-item-hover');
        if (window.hoveredRoom === this.getAttribute('data-room')) {
          window.hoveredRoom = null;
        }
      });
      
      // Restore hover class if this was the hovered room
      if (window.hoveredRoom && item.getAttribute('data-room') === window.hoveredRoom) {
        item.classList.add('room-item-hover');
      }
    });
  }
});

// Join a room
function joinRoom(roomName) {
  window.currentRoom = roomName;
  document.getElementById('current-room-name').textContent = roomName;
  document.getElementById('send-btn').disabled = false;
  document.getElementById('chat-input-area').style.display = 'flex';
  
  // Load messages immediately
  loadMessages();
  
  // Set up auto-refresh every 2 seconds
  if (window.messageInterval) {
    clearInterval(window.messageInterval);
  }
  window.messageInterval = setInterval(loadMessages, 2000);
}

// Load messages for current room
function loadMessages() {
  if (!window.currentRoom) return;
  
  fetch('/cgi/chat-get-messages?room=' + encodeURIComponent(window.currentRoom))
    .then(function(response) { return response.text(); })
    .then(function(html) {
      var chatMessagesDiv = document.getElementById('chat-messages');
      if (!chatMessagesDiv) return;
      
      // Parse the new HTML
      var tempDiv = document.createElement('div');
      tempDiv.innerHTML = html;
      var newElement = tempDiv.firstElementChild;
      
      if (newElement && newElement.id === 'chat-messages') {
        // Use idiomorph to morph the element (prevents flicker)
        if (window.Idiomorph) {
          Idiomorph.morph(chatMessagesDiv, newElement);
        } else {
          // Fallback if idiomorph not available
          chatMessagesDiv.outerHTML = html;
        }
        
        // Scroll to bottom to show latest messages
        scrollToBottom();
      }
      
      // Check if room is empty (for delete button logic)
      var isEmpty = html.indexOf('No messages yet') !== -1 || 
                    html.indexOf('class="chat-msg"') === -1;
      
      if (isEmpty) {
        document.getElementById('delete-room-btn').style.display = 'inline-block';
      } else {
        document.getElementById('delete-room-btn').style.display = 'none';
      }
    });
}

// Scroll chat to bottom to show latest messages
function scrollToBottom() {
  var chatMessagesDiv = document.getElementById('chat-messages');
  if (chatMessagesDiv) {
    chatMessagesDiv.scrollTop = chatMessagesDiv.scrollHeight;
  }
}

// Leave room and return to empty state
function leaveRoom() {
  window.currentRoom = null;
  document.getElementById('current-room-name').textContent = 'Select a room';
  document.getElementById('send-btn').disabled = true;
  document.getElementById('delete-room-btn').style.display = 'none';
  document.getElementById('chat-input-area').style.display = 'none';
  
  // Stop auto-refresh
  if (window.messageInterval) {
    clearInterval(window.messageInterval);
  }
  
  // Clear messages
  document.getElementById('chat-messages').innerHTML = '<div class="chat-messages"><p style="color: #666; font-style: italic;">Create or join a room to chat</p></div>';
}

// Delete room with blocking behavior
function deleteRoom() {
  if (!window.currentRoom) return;
  
  var roomToDelete = window.currentRoom;
  var deleteBtn = document.getElementById('delete-room-btn');
  
  // Disable button and show loading state
  deleteBtn.disabled = true;
  deleteBtn.innerHTML = 'Deleting<span class="spinner"></span>';
  
  // Leave the room first
  leaveRoom();
  
  // Delete the room
  fetch('/cgi/chat-delete-room?room=' + encodeURIComponent(roomToDelete))
    .then(function() {
      htmx.trigger('#room-list', 'load');
    })
    .catch(function(err) {
      console.error('Failed to delete room:', err);
      htmx.trigger('#room-list', 'load');
    });
}

// Send message
document.addEventListener('DOMContentLoaded', function() {
  var sendBtn = document.getElementById('send-btn');
  var messageInput = document.getElementById('message-input');
  var usernameInput = document.getElementById('username-input');
  
  // Initialize with a guest name
  var guestName = generateGuestName(window.currentDigits);
  usernameInput.value = guestName;
  window.usedGuestNames[guestName] = true;
  
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
    }).then(function(response) {
      return response.text();
    }).then(function(text) {
      // Check for name collision error
      if (text.indexOf('name collision') !== -1 || text.indexOf('already in use') !== -1) {
        // Increment digits and try again
        window.currentDigits++;
        if (window.currentDigits > 6) window.currentDigits = 1;  // Reset after 6 digits
        var newName = generateGuestName(window.currentDigits);
        usernameInput.value = newName;
        window.usedGuestNames[newName] = true;
        // Retry sending the message
        sendMessage();
      } else {
        messageInput.value = '';
        // Reload messages immediately to show the new message
        loadMessages();
      }
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
2. In the MUD, navigate to `~/sites/.sitedata/SITENAME/chatrooms/tavern/`
3. Use `say "Hello from the MUD!"`
4. The message appears in the web chat!
5. Web users' messages appear in the MUD via `listen`

### Technical Details

- **Storage:** Each room is a directory with a `.log` file
- **Location:** `~/sites/.sitedata/SITENAME/chatrooms/ROOMNAME/.log`
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
