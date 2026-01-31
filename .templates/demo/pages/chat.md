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

<div class="chat-container">
<div id="room-notification" style="display: none; position: absolute; top: 60px; left: 50%; transform: translateX(-50%); z-index: 1000; max-width: 400px;"></div>

<div class="chat-sidebar">
<div class="chat-sidebar-content">
<h3>Chatrooms</h3>
<div id="room-list" hx-get="/cgi/chat-list-rooms" hx-trigger="load, every 2s" hx-swap="innerHTML settle:0ms">
Loading rooms...
</div>

<div class="room-controls">
<!-- IMPORTANT: Keep all elements on ONE line - Pandoc wraps multi-line inline HTML in <p> tags, breaking flexbox layout -->
<div id="create-room-widget"><a href="#" id="create-room-link" onclick="toggleCreateRoom(); return false;"><span id="create-room-arrow">&#x25B6;</span> Create Room</a><div id="create-room-input-wrapper"><input type="text" id="new-room-name" placeholder="Room name" oninput="validateRoomName()" onkeydown="if(event.key==='Enter' && !document.getElementById('create-room-btn').disabled) { document.getElementById('create-room-btn').click(); }" /><span id="create-room-invalid-icon">&#x1F6AB;</span></div><button id="create-room-btn" disabled hx-get="/cgi/chat-create-room" hx-vals='js:{name: document.getElementById("new-room-name").value}' hx-target="#room-notification" hx-swap="innerHTML" hx-trigger="click" hx-on::before-request="document.getElementById('create-room-btn').disabled = true; document.getElementById('new-room-name').disabled = true; document.getElementById('create-room-btn').innerHTML = 'Creating<span class=\'spinner\'></span>';" hx-on::after-request="if(event.detail.successful) { document.getElementById('new-room-name').value = ''; validateRoomName(); htmx.trigger('#room-list', 'load'); showNotification(); toggleCreateRoom(); }">Create</button></div>
</div>
</div>

<div class="username-widget">
<!-- IMPORTANT: Keep all elements on ONE line - Pandoc wraps multi-line inline HTML in <p> tags, breaking flexbox layout -->
<div class="username-display" id="username-display"><strong id="username-text">@Guest001</strong><button onclick="editUsername()">Change</button></div>
<div class="username-edit" id="username-edit"><h5>Change Handle</h5><div id="username-edit-input-wrapper"><input type="text" id="username-edit-input" placeholder="Your name" /><span id="username-invalid-icon">&#x1F6AB;</span></div><div class="username-edit-buttons"><button onclick="saveUsername()">OK</button><button onclick="cancelUsernameEdit()">Cancel</button></div></div>
</div>
</div>

<div class="chat-main">
<div class="chat-header">
<h3 id="current-room-name">Select a room</h3>
<div class="header-buttons">
<button id="delete-room-btn" style="display: none;" onclick="deleteRoom()">
Delete Room
</button>
<button id="members-btn" style="display: none;" onclick="toggleMembersPanel()" title="Show room members">
<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
<span id="member-count">0</span>
</button>
</div>
</div>

<div class="chat-content-wrapper">
<div id="chat-messages" class="chat-display">
<p class="empty-state-message">Select a room to start chatting</p>
</div>

<div id="members-panel" class="members-panel">
<div class="members-header">
<h4>Who's here</h4>
<button onclick="toggleMembersPanel()" class="members-close-btn">&times;</button>
</div>
<div id="members-list" class="members-list">
<p style="color: #666; font-style: italic;">No members</p>
</div>
</div>
</div>

<div class="chat-input-area" id="chat-input-area" style="display: none;">
<textarea id="message-input" placeholder="Message" rows="1"></textarea>
<button id="send-btn" disabled>Send</button>
</div>
</div>
</div>

## 💬 Real-Time Chat with Multiple Rooms

This chat system uses the **same message format as the MUD `say` command**, making it fully intercompatible! Messages are stored in `.log` files (one per room) with the format `[HH:MM] username: message`.

### How It Works

1. **Each room is a folder** on the server with a `.log` file
2. **Messages use MUD format:** `[HH:MM] player_name: message`
3. **Fully intercompatible:** Someone in the MUD could walk into a chat room folder, use `say`, and web users would see it!
4. **Anyone can create rooms** with custom names
5. **Delete empty rooms** when you're done

---

<script>
// Chat UI Version: v2.1-STABLE (Production: 4KB padding confirmed optimal)

// Generate a random guest name
function generateGuestName() {
  // Use 3-digit random number (001-999) with zero padding
  var num = Math.floor(Math.random() * 999) + 1;
  var paddedNum = ('000' + num).slice(-3);  // Pad with zeros to 3 digits
  return 'Guest' + paddedNum;
}

// Get username without display icon (bullet)
function getUsername() {
  var displayText = document.getElementById('username-text').textContent.trim();
  // Remove @ prefix if present
  return displayText.replace(/^@\s*/, '');
}

// Track current room
window.currentRoom = null;
window.hoveredRoom = null;
window.userHasScrolledUp = false;  // Track if user manually scrolled up
window.messageEventSource = null;  // SSE connection for real-time messages

// Handle room selection from list
document.addEventListener('htmx:afterSwap', function(event) {
  if (event.detail.target.id === 'room-list') {
    // Re-validate create room button after room list refreshes (respects validation state)
    validateRoomName();
    
    // Re-enable input field after room list refreshes (only input, not button)
    document.getElementById('new-room-name').disabled = false;
    
    // Reset create button text if it was showing "Creating..."
    var createBtn = document.getElementById('create-room-btn');
    if (createBtn.innerHTML !== 'Create') {
      createBtn.innerHTML = 'Create';
    }
    
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
      var roomName = item.getAttribute('data-room');
      
      // Mark selected room
      if (window.currentRoom === roomName) {
        item.classList.add('room-item-selected');
      }
      
      item.onclick = function() {
        var room = this.getAttribute('data-room');
        joinRoom(room);
      };
      
      // Track hover state to preserve across refreshes (but not for selected room)
      item.addEventListener('mouseenter', function() {
        if (window.currentRoom !== this.getAttribute('data-room')) {
          window.hoveredRoom = this.getAttribute('data-room');
          this.classList.add('room-item-hover');
        }
      });
      item.addEventListener('mouseleave', function() {
        this.classList.remove('room-item-hover');
        if (window.hoveredRoom === this.getAttribute('data-room')) {
          window.hoveredRoom = null;
        }
      });
      
      // Restore hover class if this was the hovered room (but not if it's selected)
      if (window.hoveredRoom && item.getAttribute('data-room') === window.hoveredRoom && window.currentRoom !== roomName) {
        item.classList.add('room-item-hover');
      }
    });
  }
  
  // Auto-fade notifications after 4 seconds
  if (event.detail.target.id === 'room-status') {
    var notification = event.detail.target.querySelector('.demo-result');
    if (notification) {
      setTimeout(function() {
        notification.classList.add('fade-out');
        // Remove from DOM after fade completes
        setTimeout(function() {
          notification.remove();
        }, 500);
      }, 4000);
    }
  }
});

// Join a room
function joinRoom(roomName) {
  
  window.currentRoom = roomName;
  document.getElementById('current-room-name').textContent = roomName;
  document.getElementById('send-btn').disabled = false;
  document.getElementById('chat-input-area').style.display = 'flex';
  
  // Members button visibility will be controlled by loadMembers based on member count
  
  // Get current username and previous room
  var currentUsername = getUsername();
  var previousRoom = localStorage.getItem('previousRoom') || '';
  
  // Store current room as previous room for next switch
  localStorage.setItem('previousRoom', roomName);
  
  // Immediately update room selection styling
  document.querySelectorAll('.room-item').forEach(function(item) {
    if (item.getAttribute('data-room') === roomName) {
      item.classList.add('room-item-selected');
      item.classList.remove('room-item-hover');
    } else {
      item.classList.remove('room-item-selected');
    }
  });
  
  // Reset scroll behavior for new room
  window.userHasScrolledUp = false;
  
  // Focus the message input for immediate typing (prevent page scroll)
  setTimeout(function() {
    var msgInput = document.getElementById('message-input');
    if (msgInput) {
      msgInput.focus({ preventScroll: true });
    }
  }, 100);
  
  // Set up scroll listener
  setupScrollListener();
  
  // Close existing SSE connection if any
  if (window.messageEventSource) {
    window.messageEventSource.close();
    window.messageEventSource = null;
  }
  
  // Clear any existing polling interval
  if (window.messageInterval) {
    clearInterval(window.messageInterval);
    window.messageInterval = null;
  }
  
  // CRITICAL: Capture timestamp BEFORE avatar creation
  // This ensures SSE will capture the avatar creation events
  var joinTimestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
  
  // Create/move avatar and wait for completion before setting up SSE
  // This ensures the avatar exists and join message is logged before SSE starts
  var avatarPromise;
  if (previousRoom && previousRoom !== roomName) {
    // Move avatar from previous room to new room
    avatarPromise = moveAvatar(roomName, currentUsername, previousRoom);
  } else {
    // Create new avatar (first join or rejoining same room)
    avatarPromise = createAvatar(roomName, currentUsername);
  }
  
  // Wait for avatar creation to complete, then set up SSE and load history
  avatarPromise.then(function() {
    // Set up SSE with the timestamp from BEFORE avatar creation
    // This ensures SSE captures the join message and member update events
    setupMessageStream(roomName, joinTimestamp);
    
    // Then load message history via GET
    // Any overlap between SSE and history will be deduplicated by appendMessage
    loadMessages();
  }).catch(function(err) {
    console.error('Failed to complete avatar setup:', err);
    // Still try to set up SSE and load messages even if avatar creation failed
    setupMessageStream(roomName, joinTimestamp);
    loadMessages();
  });
}

// Load messages for current room
function loadMessages() {
  if (!window.currentRoom) return;
  
  fetch('/cgi/chat-get-messages?room=' + encodeURIComponent(window.currentRoom))
    .then(function(response) { return response.text(); })
    .then(function(html) {
      var chatMessagesDiv = document.getElementById('chat-messages');
      if (!chatMessagesDiv) return;
      
      // Store scroll position before updating DOM
      var wasAtBottom = chatMessagesDiv.scrollHeight - chatMessagesDiv.scrollTop - chatMessagesDiv.clientHeight < 50;
      var oldScrollHeight = chatMessagesDiv.scrollHeight;
      var oldScrollTop = chatMessagesDiv.scrollTop;
      
      // Get count of existing messages before update
      var oldMessages = chatMessagesDiv.querySelectorAll('.chat-msg');
      var oldMessageCount = oldMessages.length;
      
      // Parse the new HTML
      var tempDiv = document.createElement('div');
      tempDiv.innerHTML = html;
      var newElement = tempDiv.firstElementChild;
      
      if (newElement && newElement.id === 'chat-messages') {
        // Use Idiomorph to morph the element (prevents flicker)
        // Idiomorph is a DOM morphing library that efficiently updates the DOM
        // by comparing old and new HTML and making minimal changes
        if (window.Idiomorph) {
          Idiomorph.morph(chatMessagesDiv, newElement);
        } else {
          // Fallback if idiomorph not available
          chatMessagesDiv.outerHTML = html;
          chatMessagesDiv = document.getElementById('chat-messages');
        }
        
        // Force animation on new messages
        var newMessages = chatMessagesDiv.querySelectorAll('.chat-msg');
        if (newMessages.length > oldMessageCount) {
          // New messages were added - force animation on the new ones
          for (var i = oldMessageCount; i < newMessages.length; i++) {
            var msg = newMessages[i];
            // Remove and re-add animation to force it to play
            msg.style.animation = 'none';
            // Force reflow
            void msg.offsetHeight;
            // Restore the animation with explicit declaration
            msg.style.animation = 'messageAppear 0.51s cubic-bezier(0.25, 0.46, 0.45, 0.94)';
          }
        }
        
        // Color-code messages: light blue for others, light green for user's own
        var currentUsername = getUsername();
        var allMessages = chatMessagesDiv.querySelectorAll('.chat-msg');
        allMessages.forEach(function(msg) {
          var usernameSpan = msg.querySelector('.username');
          if (usernameSpan) {
            var msgUsername = usernameSpan.textContent.replace(':', '').trim();
            if (msgUsername === currentUsername) {
              msg.classList.add('my-message');
            } else {
              msg.classList.remove('my-message');
            }
          }
          
          // Format timestamp tooltips
          var timestampSpan = msg.querySelector('.timestamp');
          if (timestampSpan && timestampSpan.dataset.fullTimestamp) {
            var fullTs = timestampSpan.dataset.fullTimestamp;
            // Format: "YYYY-MM-DD HH:MM:SS" -> human readable
            try {
              // Parse the timestamp properly - add 'T' between date and time for ISO format
              var date = new Date(fullTs.replace(' ', 'T'));
              // Check if date is valid
              if (!isNaN(date.getTime())) {
                var options = { 
                  weekday: 'long', 
                  year: 'numeric', 
                  month: 'long', 
                  day: 'numeric', 
                  hour: 'numeric', 
                  minute: '2-digit'
                };
                var formatted = date.toLocaleString('en-US', options);
                timestampSpan.title = formatted;
              } else {
                // Fallback to showing original timestamp
                timestampSpan.title = fullTs;
              }
            } catch (e) {
              // Keep original timestamp if parsing fails
              timestampSpan.title = fullTs;
            }
          }
        });
        
        // Handle scrolling
        var newScrollHeight = chatMessagesDiv.scrollHeight;
        var scrollHeightDiff = newScrollHeight - oldScrollHeight;
        
        if (scrollHeightDiff > 0 && window.userHasScrolledUp && !wasAtBottom) {
          // New content was added AND user is scrolled up viewing history
          // Adjust scroll position to keep existing messages in place
          chatMessagesDiv.scrollTop = oldScrollTop + scrollHeightDiff;
        } else if (wasAtBottom || !window.userHasScrolledUp) {
          // User is at bottom or hasn't manually scrolled up
          // Smooth scroll to bottom to show latest messages
          scrollToBottom();
        }
      }
      
      // Check avatar count for delete button logic
      updateDeleteButton();
    });
}

// Scroll chat to bottom to show latest messages
function scrollToBottom() {
  var chatMessagesDiv = document.getElementById('chat-messages');
  if (!chatMessagesDiv) return;
  
  // Only scroll if there's actually a scrollbar (content exceeds viewport)
  if (chatMessagesDiv.scrollHeight <= chatMessagesDiv.clientHeight) {
    return;  // No scrollbar, don't scroll
  }
  
  // Smoothly scroll to bottom to show latest messages
  chatMessagesDiv.scrollTo({
    top: chatMessagesDiv.scrollHeight,
    behavior: 'smooth'
  });
}

// Detect when user manually scrolls
function setupScrollListener() {
  var chatMessagesDiv = document.getElementById('chat-messages');
  if (!chatMessagesDiv) return;
  
  chatMessagesDiv.addEventListener('scroll', function() {
    // Check if user is at the bottom (within 50px tolerance)
    var isAtBottom = chatMessagesDiv.scrollHeight - chatMessagesDiv.scrollTop - chatMessagesDiv.clientHeight < 50;
    
    if (isAtBottom) {
      // User scrolled to bottom, re-enable auto-scroll
      window.userHasScrolledUp = false;
    } else {
      // User scrolled up, disable auto-scroll
      window.userHasScrolledUp = true;
    }
  });
}

// Set up Server-Sent Events for real-time message updates
function setupMessageStream(roomName, sinceTimestamp) {
  if (!roomName) return;
  
  
  // Close existing connection if any
  if (window.messageEventSource) {
    window.messageEventSource.close();
    window.messageEventSource = null;
  }
  
  // Use provided timestamp or generate current one
  // When provided from joinRoom, this will be BEFORE avatar creation
  // This ensures SSE captures the avatar creation events
  if (!sinceTimestamp) {
    var now = new Date();
    sinceTimestamp = now.toISOString().replace('T', ' ').substring(0, 19);
  }
  
  // Create new SSE connection with since parameter
  var url = '/cgi/chat-stream?room=' + encodeURIComponent(roomName) + '&since=' + encodeURIComponent(sinceTimestamp);
  
  try {
    window.messageEventSource = new EventSource(url);
  } catch (e) {
    console.error('[SSE] Failed to create EventSource:', e);
    return;
  }
  
  // Handle connection open
  window.messageEventSource.addEventListener('open', function(event) {
    // Connection established
  });
  
  // Handle incoming messages
  window.messageEventSource.addEventListener('message', function(event) {
    var timestamp = new Date().toISOString();
    // Event data is a single message line: [YYYY-MM-DD HH:MM:SS] username: message
    appendMessage(event.data);
  });
  
  // Handle member list updates
  window.messageEventSource.addEventListener('members', function(event) {
    // Event data is JSON array of members
    updateMemberList(event.data);
  });
  
  // Handle errors
  window.messageEventSource.addEventListener('error', function(event) {
    console.error('[SSE] Error occurred:', event);
    console.error('[SSE] ReadyState:', window.messageEventSource.readyState);
    console.error('[SSE] URL:', window.messageEventSource.url);
    // EventSource automatically reconnects, but we can add custom logic here if needed
    
    // If connection is closed or error persists, log it
    if (window.messageEventSource.readyState === EventSource.CLOSED) {
      console.error('[SSE] Connection CLOSED - EventSource will not reconnect');
    } else if (window.messageEventSource.readyState === EventSource.CONNECTING) {
      console.warn('[SSE] Connection CONNECTING - EventSource attempting to reconnect');
    }
  });
  
  // Optional: Handle ping/keepalive events (currently just ignore them)
  window.messageEventSource.addEventListener('ping', function(event) {
  });
  
  // Add a timeout warning if no events received after 5 seconds
  setTimeout(function() {
    if (window.messageEventSource && window.messageEventSource.readyState === EventSource.CONNECTING) {
      console.warn('[SSE] WARNING: Still CONNECTING after 5 seconds - possible server issue');
      console.warn('[SSE] Check server logs for errors in chat-stream script');
    } else if (window.messageEventSource && window.messageEventSource.readyState === EventSource.OPEN) {
    }
  }, 5000);
  
  // Periodic status logging every 15 seconds for debugging
  var statusInterval = setInterval(function() {
    if (!window.messageEventSource) {
      clearInterval(statusInterval);
      return;
    }
    var states = ['CONNECTING', 'OPEN', 'CLOSED'];
    var state = states[window.messageEventSource.readyState] || 'UNKNOWN';
  }, 15000);
}

// Update member list from SSE data
function updateMemberList(jsonData) {
  try {
    var data = JSON.parse(jsonData);
    var avatars = data.avatars || [];
    
    var membersList = document.getElementById('members-list');
    var memberCount = document.getElementById('member-count');
    var membersBtn = document.getElementById('members-btn');
    var deleteBtn = document.getElementById('delete-room-btn');
    
    if (!membersList || !memberCount) {
      console.error('Member list elements not found');
      return;
    }
    
    var count = avatars.length;
    
    if (count === 0) {
      membersList.innerHTML = '<p style="color: #666; font-style: italic;">No members</p>';
      memberCount.textContent = '0';
    } else {
      memberCount.textContent = count;
      
      // Get current username for highlighting
      var currentUsername = getUsername();
      
      var html = '';
      avatars.forEach(function(avatar) {
        var fontStyle = avatar.is_web ? 'Verdana, sans-serif' : 'Courier New, Courier, monospace';
        var badge = avatar.is_web ? '🌐' : '⚔️';
        var isCurrentUser = (avatar.username === currentUsername);
        
        html += '<div class="member-item' + (isCurrentUser ? ' member-item-current' : '') + '" style="font-family: ' + fontStyle + ';">';
        html += '<span class="member-badge">' + badge + '</span>';
        html += '<span class="member-name">' + avatar.username + '</span>';
        html += '</div>';
      });
      
      membersList.innerHTML = html;
    }
    
    // Update button visibility based on member count
    // Show delete button when 1 or fewer members, members button when more than 1
    if (count <= 1) {
      if (deleteBtn) deleteBtn.style.display = 'inline-block';
      if (membersBtn) membersBtn.style.display = 'none';
    } else {
      if (deleteBtn) deleteBtn.style.display = 'none';
      if (membersBtn) membersBtn.style.display = 'inline-flex';
    }
  } catch (e) {
    console.error('Error parsing member data:', e);
  }
}

// Append a single message to the chat display
function appendMessage(messageLine) {
  var chatMessagesDiv = document.getElementById('chat-messages');
  if (!chatMessagesDiv) return;
  
  // Clear empty state message if present (first message arriving)
  var emptyStateMsg = chatMessagesDiv.querySelector('.empty-state-message');
  if (emptyStateMsg) {
    chatMessagesDiv.innerHTML = '';  // Clear empty state
  }
  
  // Parse the message line format: [YYYY-MM-DD HH:MM:SS] username: message
  var match = messageLine.match(/^\[([^\]]+)\]\s+([^:]+):\s+(.*)$/);
  if (!match) return;  // Invalid format
  
  var fullTimestamp = match[1];
  var username = match[2];
  var message = match[3];
  
  // Duplicate detection: check if this exact message already exists
  // Create a unique ID from timestamp + username + message
  var messageId = fullTimestamp + '|' + username + '|' + message;
  var existingMessages = chatMessagesDiv.querySelectorAll('.chat-msg, .chat-msg-system');
  for (var i = 0; i < existingMessages.length; i++) {
    var existingMsg = existingMessages[i];
    if (existingMsg.dataset.messageId === messageId) {
      return;  // Already have this message, skip duplicate
    }
  }
  
  // Extract HH:MM from timestamp for display
  var displayTime = fullTimestamp.length >= 16 ? fullTimestamp.substring(11, 16) : fullTimestamp;
  
  // Check if this is a system message
  if (username === 'log') {
    // Store scroll position before adding
    var wasAtBottom = chatMessagesDiv.scrollHeight - chatMessagesDiv.scrollTop - chatMessagesDiv.clientHeight < 50;
    
    var messageDiv = document.createElement('div');
    messageDiv.className = 'chat-msg-system';
    messageDiv.dataset.messageId = messageId;
    messageDiv.textContent = message;
    chatMessagesDiv.appendChild(messageDiv);
    
    // Auto-scroll if user is at bottom (same as regular messages)
    if (wasAtBottom || !window.userHasScrolledUp) {
      scrollToBottom();
    }
  } else {
    // Regular message - generate color from username hash
    var hue = hashUsername(username);
    var color = 'hsl(' + hue + ', 70%, 35%)';
    
    // Determine font family (assume web user for simplicity, or check later)
    var fontFamily = 'Verdana, sans-serif';
    
    // Create message element
    var messageDiv = document.createElement('div');
    messageDiv.className = 'chat-msg';
    messageDiv.style.fontFamily = fontFamily;
    messageDiv.dataset.messageId = messageId;
    
    // Add username
    var usernameSpan = document.createElement('span');
    usernameSpan.className = 'username';
    usernameSpan.style.color = color;
    usernameSpan.style.fontWeight = 'bold';
    usernameSpan.textContent = username + ':';
    messageDiv.appendChild(usernameSpan);
    
    // Add message text
    messageDiv.appendChild(document.createTextNode(' ' + message));
    
    // Add timestamp
    var timestampSpan = document.createElement('span');
    timestampSpan.className = 'timestamp';
    timestampSpan.dataset.fullTimestamp = fullTimestamp;
    timestampSpan.textContent = displayTime;
    
    // Format tooltip
    try {
      var date = new Date(fullTimestamp.replace(' ', 'T'));
      if (!isNaN(date.getTime())) {
        var options = { 
          weekday: 'long', 
          year: 'numeric', 
          month: 'long', 
          day: 'numeric', 
          hour: 'numeric', 
          minute: '2-digit'
        };
        timestampSpan.title = date.toLocaleString('en-US', options);
      } else {
        timestampSpan.title = fullTimestamp;
      }
    } catch (e) {
      timestampSpan.title = fullTimestamp;
    }
    
    messageDiv.appendChild(timestampSpan);
    
    // Check if this is user's own message
    var currentUsername = getUsername();
    if (username === currentUsername) {
      messageDiv.classList.add('my-message');
    }
    
    // Store scroll position before adding
    var wasAtBottom = chatMessagesDiv.scrollHeight - chatMessagesDiv.scrollTop - chatMessagesDiv.clientHeight < 50;
    
    // Append to display
    chatMessagesDiv.appendChild(messageDiv);
    
    // Apply animation
    messageDiv.style.animation = 'messageAppear 0.51s cubic-bezier(0.25, 0.46, 0.45, 0.94)';
    
    // Auto-scroll if user is at bottom
    if (wasAtBottom || !window.userHasScrolledUp) {
      scrollToBottom();
    }
  }
}

// Hash username to generate consistent color (same as server-side AWK)
function hashUsername(username) {
  var hash = 0;
  var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  
  for (var i = 0; i < username.length; i++) {
    var char = username.charAt(i);
    var asciiVal = chars.indexOf(char);
    if (asciiVal === -1) asciiVal = char.charCodeAt(0);  // Use actual ASCII value for non-alphanumeric
    hash += asciiVal * (i + 1);
  }
  
  // Map to 12 distinct hues (30 degree steps)
  return (hash % 12) * 30;
}

// Avatar management functions
function createAvatar(roomName, username) {
  var formData = 'room=' + encodeURIComponent(roomName) + 
                 '&user=' + encodeURIComponent(username);
  
  return fetch('/cgi/chat-create-avatar', {
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: formData
  }).then(function() {
    loadMembers();  // Refresh member list
  }).catch(function(err) {
    console.error('Failed to create avatar:', err);
    throw err;  // Re-throw to propagate error
  });
}

function moveAvatar(newRoom, username, oldRoom) {
  var payload = JSON.stringify({
    room: newRoom,
    username: username,
    oldRoom: oldRoom
  });
  
  return fetch('/cgi/chat-move-avatar', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: payload
  }).then(function(response) {
    return response.text();  // Get as text first to see what we're receiving
  }).then(function(text) {
    var data = JSON.parse(text);
    if (data.success) {
      loadMembers();  // Refresh member list
    } else {
      console.error('Failed to move avatar:', data.error);
      // Fallback to creating new avatar
      return createAvatar(newRoom, username);
    }
  }).catch(function(err) {
    console.error('Failed to move avatar:', err);
    // Fallback to creating new avatar
    return createAvatar(newRoom, username);
  });
}

function deleteAvatar(roomName, username) {
  var formData = 'room=' + encodeURIComponent(roomName) + 
                 '&user=' + encodeURIComponent(username);
  
  fetch('/cgi/chat-delete-avatar', {
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: formData
  }).then(function() {
    loadMembers();  // Refresh member list
  }).catch(function(err) {
    console.error('Failed to delete avatar:', err);
  });
}

function loadMembers() {
  if (!window.currentRoom) return;
  
  fetch('/cgi/chat-list-avatars?room=' + encodeURIComponent(window.currentRoom))
    .then(function(response) { return response.json(); })
    .then(function(data) {
      if (data.error) {
        console.error('Error loading members:', data.error);
        return;
      }
      
      var membersList = document.getElementById('members-list');
      var memberCount = document.getElementById('member-count');
      var membersBtn = document.getElementById('members-btn');
      var deleteBtn = document.getElementById('delete-room-btn');
      var count = data.avatars ? data.avatars.length : 0;
      
      if (!data.avatars || data.avatars.length === 0) {
        membersList.innerHTML = '<p style="color: #666; font-style: italic;">No members</p>';
        memberCount.textContent = '0';
      } else {
        memberCount.textContent = data.avatars.length;
        
        // Get current username for highlighting
        var currentUsername = getUsername();
        
        var html = '';
        data.avatars.forEach(function(avatar) {
          var fontStyle = avatar.is_web ? 'Verdana, sans-serif' : 'Courier New, Courier, monospace';
          var badge = avatar.is_web ? '🌐' : '⚔️';
          var isCurrentUser = (avatar.username === currentUsername);
          var fontWeight = isCurrentUser ? 'font-weight: bold;' : '';
          html += '<div class="member-item" style="font-family: ' + fontStyle + ';">' + 
                  '<span class="member-badge">' + badge + '</span>' +
                  '<span class="member-name" style="' + fontWeight + '" title="' + avatar.username + '">' + avatar.username + '</span>' +
                  '</div>';
        });
        membersList.innerHTML = html;
      }
      
      // Update both buttons synchronously based on same count
      if (count <= 1) {
        // Show delete button, hide members button
        deleteBtn.style.display = 'inline-block';
        membersBtn.style.display = 'none';
      } else {
        // Hide delete button, show members button
        deleteBtn.style.display = 'none';
        membersBtn.style.display = 'inline-flex';
      }
    })
    .catch(function(err) {
      console.error('Failed to load members:', err);
    });
}

function updateDeleteButton() {
  if (!window.currentRoom) return;
  
  fetch('/cgi/chat-count-avatars?room=' + encodeURIComponent(window.currentRoom))
    .then(function(response) { return response.json(); })
    .then(function(data) {
      if (data.error) {
        console.error('Error counting avatars:', data.error);
        return;
      }
      
      var deleteBtn = document.getElementById('delete-room-btn');
      var membersBtn = document.getElementById('members-btn');
      
      // Update both buttons synchronously based on same count
      if (data.count <= 1) {
        // Show delete button, hide members button
        deleteBtn.style.display = 'inline-block';
        membersBtn.style.display = 'none';
      } else {
        // Hide delete button, show members button
        deleteBtn.style.display = 'none';
        membersBtn.style.display = 'inline-flex';
      }
    })
    .catch(function(err) {
      console.error('Failed to count avatars:', err);
    });
}

function toggleMembersPanel() {
  var panel = document.getElementById('members-panel');
  panel.classList.toggle('open');
  
  // Update button appearance and tooltip
  var btn = document.getElementById('members-btn');
  if (panel.classList.contains('open')) {
    btn.classList.add('active');
    btn.title = 'Hide room members';
  } else {
    btn.classList.remove('active');
    btn.title = 'Show room members';
  }
}

// Leave room and return to empty state
function leaveRoom() {
  // Delete avatar before leaving
  if (window.currentRoom) {
    var currentUsername = getUsername();
    deleteAvatar(window.currentRoom, currentUsername);
  }
  
  window.currentRoom = null;
  document.getElementById('current-room-name').textContent = 'Select a room';
  document.getElementById('send-btn').disabled = true;
  document.getElementById('delete-room-btn').style.display = 'none';
  document.getElementById('members-btn').style.display = 'none';
  document.getElementById('chat-input-area').style.display = 'none';
  
  // Close members panel
  var panel = document.getElementById('members-panel');
  var btn = document.getElementById('members-btn');
  panel.classList.remove('open');
  btn.classList.remove('active');
  
  // Stop auto-refresh
  if (window.messageInterval) {
    clearInterval(window.messageInterval);
  }
  
  // Clear messages
  document.getElementById('chat-messages').innerHTML = '<p class="empty-state-message">Create or join a room to chat</p>';
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
  var usernameText = document.getElementById('username-text');
  
  // Initialize with a guest name
  var guestName = generateGuestName();
  usernameText.textContent = '@' + guestName;
  
  // Set initial height explicitly to prevent shrinking on first keystroke
  messageInput.style.height = '2.5rem';
  
  // Auto-expand textarea as user types
  messageInput.addEventListener('input', function() {
    // Calculate based on content, with min/max constraints (using rems)
    var baseFontSize = 16;  // Assuming 16px base font size
    var minHeightRem = 2.5;  // Minimum 2.5rem (one line)
    var maxHeightRem = 8;    // Max 8rem (~5 lines)
    var minHeight = minHeightRem * baseFontSize;
    var maxHeight = maxHeightRem * baseFontSize;
    
    // Get current scroll height
    var currentScrollHeight = this.scrollHeight;
    
    // Calculate new height based on content - allow both expansion and contraction
    var newHeightPx = Math.max(currentScrollHeight, minHeight);
    newHeightPx = Math.min(newHeightPx, maxHeight);
    var newHeightRem = newHeightPx / baseFontSize;
    
    // Only update if the new height is different from current to avoid unnecessary reflows
    var newHeightStr = newHeightRem + 'rem';
    if (this.style.height !== newHeightStr) {
      this.style.height = newHeightStr;
    }
    
    // Show scrollbar only when content exceeds max height
    if (currentScrollHeight > maxHeight) {
      this.style.overflowY = 'auto';
    } else {
      this.style.overflowY = 'hidden';
    }
  });
  
  function sendMessage() {
    if (!window.currentRoom) return;
    
    var msg = messageInput.value.trim();
    var user = getUsername() || 'Anonymous';
    
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
      messageInput.value = '';
      // Reset textarea height to initial (2.5rem matches min-height)
      messageInput.style.height = '2.5rem';
      // Don't reload messages - SSE will deliver the new message in real-time!
      // (Reloading causes duplication: message appears via GET, then again via SSE)
    });
  }
  
  sendBtn.onclick = sendMessage;
  
  messageInput.addEventListener('keypress', function(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();  // Prevent newline
      sendMessage();
    }
    // Shift+Enter adds a newline (default behavior)
  });
});

// Username editing functions
function editUsername() {
  var display = document.getElementById('username-display');
  var edit = document.getElementById('username-edit');
  var input = document.getElementById('username-edit-input');
  var currentName = getUsername();
  var okButton = document.querySelector('#username-edit button:first-child');
  
  display.classList.add('hidden');
  edit.classList.add('open');
  input.value = currentName;
  
  // Store initial value and validate
  input.dataset.initialValue = currentName;
  validateUsername();
  
  // Focus after animation starts
  setTimeout(function() {
    input.focus();
    input.select();
  }, 50);
}

function saveUsername() {
  var display = document.getElementById('username-display');
  var edit = document.getElementById('username-edit');
  var input = document.getElementById('username-edit-input');
  var text = document.getElementById('username-text');
  
  var oldName = input.dataset.initialValue || '';
  var newName = input.value.trim();
  if (newName && newName !== oldName) {
    // If user is in a room, rename avatar
    if (window.currentRoom) {
      var formData = 'room=' + encodeURIComponent(window.currentRoom) + 
                     '&old_user=' + encodeURIComponent(oldName) + 
                     '&new_user=' + encodeURIComponent(newName);
      
      fetch('/cgi/chat-rename-avatar', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formData
      }).then(function() {
        // Refresh members list immediately after rename
        loadMembers();
      }).catch(function(err) {
        console.error('Failed to rename avatar:', err);
      });
    }
    
    // Set username for display
    text.textContent = '@' + newName;
  }
  
  edit.classList.remove('open');
  display.classList.remove('hidden');
}

function cancelUsernameEdit() {
  var display = document.getElementById('username-display');
  var edit = document.getElementById('username-edit');
  
  edit.classList.remove('open');
  display.classList.remove('hidden');
}

// Validate username in realtime
function validateUsername() {
  var input = document.getElementById('username-edit-input');
  var okButton = document.querySelector('#username-edit button:first-child');
  var invalidIcon = document.getElementById('username-invalid-icon');
  
  if (!input || !okButton) return;
  
  var username = input.value.trim();
  var initialValue = input.dataset.initialValue || '';
  
  // Check if username matches valid format pattern
  var hasValidFormat = /^[a-zA-Z0-9_-]+$/.test(username);
  var isDifferent = username !== initialValue;
  
  // Button enabled only if: non-empty, valid format, AND different from initial
  var canSave = username.length > 0 && hasValidFormat && isDifferent;
  okButton.disabled = !canSave;
  
  // Show error styling ONLY if user typed something with invalid format
  // Don't show error for unchanged username (even though button is disabled)
  if (username.length > 0 && !hasValidFormat) {
    input.style.borderColor = '#dc3545';  // Red for invalid format
    if (invalidIcon) invalidIcon.classList.add('show');
  } else {
    input.style.borderColor = '';  // Reset to default
    if (invalidIcon) invalidIcon.classList.remove('show');
  }
}

// Add Enter and Escape key support for username editing
document.addEventListener('DOMContentLoaded', function() {
  var input = document.getElementById('username-edit-input');
  var okButton = document.querySelector('#username-edit button:first-child');
  
  if (input && okButton) {
    // Monitor input changes with validation
    input.addEventListener('input', function() {
      validateUsername();
    });
    
    input.addEventListener('keypress', function(e) {
      if (e.key === 'Enter') {
        if (!okButton.disabled) {
          saveUsername();
        }
      }
    });
    input.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') {
        cancelUsernameEdit();
      }
    });
  }
});

// Toggle Create Room widget
function toggleCreateRoom() {
  var widget = document.getElementById('create-room-widget');
  var arrow = document.getElementById('create-room-arrow');
  
  if (!widget.classList.contains('open')) {
    widget.classList.add('open');
    // Change arrow to down-pointing when open
    if (arrow) arrow.innerHTML = '&#x25BC;';  // ▼ down-pointing filled triangle
    
    // Scroll the sidebar to the bottom to show the create room panel
    // Wait for panel expansion to complete before scrolling
    setTimeout(function() {
      var sidebarContent = document.querySelector('.chat-sidebar-content');
      if (sidebarContent) {
        // Smooth scroll to bottom with extra padding to ensure panel is fully visible
        sidebarContent.scrollTo({
          top: sidebarContent.scrollHeight + 100,  // Extra 100px to ensure we reach bottom
          behavior: 'smooth'
        });
      }
    }, 320);  // Wait for 300ms panel animation + 20ms buffer
    
    // Focus on input after animation starts
    setTimeout(function() {
      var input = document.getElementById('new-room-name');
      if (input) {
        input.focus({ preventScroll: true });
        // Validate to ensure button state is correct
        validateRoomName();
      }
    }, 150);
  } else {
    widget.classList.remove('open');
    // Change arrow back to right-pointing when closed
    if (arrow) arrow.innerHTML = '&#x25B6;';  // ▶ right-pointing filled triangle
  }
}

// Validate room name in realtime
function validateRoomName() {
  var input = document.getElementById('new-room-name');
  var button = document.getElementById('create-room-btn');
  var invalidIcon = document.getElementById('create-room-invalid-icon');
  
  if (!input || !button) return;
  
  var roomName = input.value.trim();
  
  // Room name must be non-empty and match pattern: alphanumeric, dash, underscore only
  var isValid = roomName.length > 0 && /^[a-zA-Z0-9_-]+$/.test(roomName);
  
  // Enable/disable button based on validation
  button.disabled = !isValid;
  
  // Add visual feedback to input and show/hide invalid icon
  if (roomName.length > 0 && !isValid) {
    input.style.borderColor = '#dc3545';  // Red for invalid
    if (invalidIcon) invalidIcon.classList.add('show');
  } else {
    input.style.borderColor = '';  // Reset to default
    if (invalidIcon) invalidIcon.classList.remove('show');
  }
}

// Show notification and auto-hide after 4 seconds
function showNotification() {
  var notification = document.getElementById('room-notification');
  notification.style.display = 'block';
  setTimeout(function() {
    var content = notification.querySelector('.demo-result');
    if (content) {
      content.classList.add('fade-out');
      setTimeout(function() {
        notification.style.display = 'none';
        notification.innerHTML = '';
      }, 500);
    }
  }, 4000);
}

// Clean up avatar when user leaves the page
window.addEventListener('beforeunload', function() {
  
  // Close SSE connection
  if (window.messageEventSource) {
    window.messageEventSource.close();
    window.messageEventSource = null;
  }
  
  if (window.currentRoom) {
    var currentUsername = getUsername();
    // Use sendBeacon for reliable cleanup on page unload
    var formData = new URLSearchParams();
    formData.append('room', window.currentRoom);
    formData.append('user', currentUsername);
    navigator.sendBeacon('/cgi/chat-delete-avatar', formData);
  }
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
