---
title: Chatrooms
---

<div class="chat-container">
<div id="room-notification" style="display: none; position: absolute; top: 60px; left: 50%; transform: translateX(-50%); z-index: 1000; max-width: 400px;"></div>

<div class="chat-sidebar">
<div class="chat-sidebar-content">
<div class="chatrooms-header">
<h3>Chatrooms</h3>
</div>
<div id="room-list" hx-get="/cgi/chat-list-rooms" hx-trigger="load, roomListChanged from:body" hx-swap="morph:innerHTML settle:0ms">
<!-- Requires htmx morph extension (Idiomorph) - ensure it's loaded in page -->
Loading rooms...
</div>

<div class="room-controls">
<!-- IMPORTANT: Keep all elements on ONE line - Pandoc wraps multi-line inline HTML in <p> tags, breaking flexbox layout -->
<div id="create-room-widget"><a href="#" id="create-room-link" onclick="toggleCreateRoom(); return false;"><span id="create-room-arrow">&#x25B6;</span> Create Room</a><div id="create-room-input-wrapper"><input type="text" id="new-room-name" placeholder="Room name" oninput="validateRoomName()" onkeydown="if(event.key==='Enter' && !document.getElementById('create-room-btn').disabled) { document.getElementById('create-room-btn').click(); }" /><span id="create-room-invalid-icon">&#x1F6AB;</span></div><button id="create-room-btn" disabled hx-get="/cgi/chat-create-room" hx-vals='js:{name: document.getElementById("new-room-name").value}' hx-target="#room-notification" hx-swap="innerHTML" hx-trigger="click" hx-on::before-request="document.getElementById('create-room-btn').disabled = true; document.getElementById('new-room-name').disabled = true; document.getElementById('create-room-btn').innerHTML = 'Creating<span class=\'spinner\'></span>';" hx-on::after-request="if(event.detail.successful) { document.getElementById('new-room-name').value = ''; validateRoomName(); htmx.trigger('body', 'roomListChanged'); showNotification(); toggleCreateRoom(); }">Create</button></div>
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

<div class="badge-mode-control">
<label class="toggle-switch">
<input type="checkbox" id="badge-mode-toggle" onchange="toggleBadgeMode()">
<span class="toggle-slider"></span>
<span class="toggle-label">Show unread counts</span>
</label>
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
  var element = document.getElementById('username-text');
  if (!element) {
    return '';
  }
  var displayText = element.textContent.trim();
  // Remove @ prefix if present
  return displayText.replace(/^@\s*/, '');
}

// Track current room
window.currentRoom = null;
window.hoveredRoom = null;
window.userHasScrolledUp = false;  // Track if user manually scrolled up
window.isInitialRoomLoad = false;  // Track if this is the first load of a room
window.messageEventSource = null;  // SSE connection for real-time messages
window.unreadCountsEventSource = null;  // SSE connection for real-time unread counts
window.roomListEventSource = null;  // SSE connection for real-time room list updates

// Unread message tracking
// Store read-up-until timestamp per room in localStorage

function getCurrentTimestamp() {
  // Generate ISO timestamp in format: YYYY-MM-DD HH:MM:SS
  return new Date().toISOString().replace('T', ' ').substring(0, 19);
}

function formatLocalTimestamp(date) {
  // Format date in local time to match server's log-timestamp format: YYYY-MM-DD HH:MM:SS
  // This is critical for SSE timestamp filtering to work correctly
  var year = date.getFullYear();
  var month = String(date.getMonth() + 1).padStart(2, '0');
  var day = String(date.getDate()).padStart(2, '0');
  var hours = String(date.getHours()).padStart(2, '0');
  var minutes = String(date.getMinutes()).padStart(2, '0');
  var seconds = String(date.getSeconds()).padStart(2, '0');
  return year + '-' + month + '-' + day + ' ' + hours + ':' + minutes + ':' + seconds;
}

function getReadTimestamp(roomName) {
  var key = 'chatroom_read_' + roomName;
  return localStorage.getItem(key) || '1970-01-01 00:00:00';
}

function setReadTimestamp(roomName, timestamp) {
  var key = 'chatroom_read_' + roomName;
  localStorage.setItem(key, timestamp);
}

function markRoomAsRead(roomName) {
  // Mark all messages as read up to the last message's server timestamp
  // This prevents issues when client clock is ahead of server clock
  var lastTimestamp = getLastMessageTimestamp();
  if (lastTimestamp) {
    setReadTimestamp(roomName, lastTimestamp);
  }
  // Note: If no messages exist, we intentionally don't set a timestamp.
  // getReadTimestamp() will return epoch '1970-01-01 00:00:00' as default,
  // which is correct for an empty/never-visited room.
  // Immediately update badges for responsive UX
  updateUnreadBadges();
}

function getLastMessageTimestamp() {
  // Get the timestamp of the last message in the current chat display
  // Use server-provided timestamp to avoid client/server clock drift issues
  var chatMessagesDiv = document.getElementById('chat-messages');
  if (!chatMessagesDiv) return null;
  
  var messages = chatMessagesDiv.querySelectorAll('.chat-msg');
  if (messages.length === 0) return null;
  
  // Get the last message's timestamp
  var lastMessage = messages[messages.length - 1];
  var timestampSpan = lastMessage.querySelector('.timestamp');
  if (timestampSpan && timestampSpan.dataset.fullTimestamp) {
    // Return as string - timestamp comparisons use lexicographic comparison
    // which works correctly for 'YYYY-MM-DD HH:MM:SS' format
    // This format is enforced server-side by:
    // - spells/.imps/out/log-timestamp (generates timestamp via date command)
    // - spells/.imps/cgi/chat-get-messages (renders data-full-timestamp attribute)
    return timestampSpan.dataset.fullTimestamp;
  }
  
  return null;
}

// Badge display mode functions
function getBadgeMode() {
  return localStorage.getItem('badgeDisplayMode') || 'number';
}

function setBadgeMode(mode) {
  localStorage.setItem('badgeDisplayMode', mode);
}

function toggleBadgeMode() {
  var toggleCheckbox = document.getElementById('badge-mode-toggle');
  // Inverted: checked = show counts (number mode), unchecked = show dots
  var newMode = toggleCheckbox && toggleCheckbox.checked ? 'number' : 'dot';
  setBadgeMode(newMode);
  
  // Update all visible badges
  updateAllBadgeStyles();
}

function updateAllBadgeStyles() {
  var mode = getBadgeMode();
  
  document.querySelectorAll('.unread-badge').forEach(function(badge) {
    updateBadgeStyle(badge, mode);
  });
}

// Simple dot styling: light violet (1-50), grey (51+), no glow
function updateBadgeStyle(badge, mode) {
  if (!mode) mode = getBadgeMode();
  
  // Get current count from badge
  var count = parseInt(badge.textContent) || 0;
  
  if (mode === 'dot') {
    // Switch to dot mode
    badge.classList.add('dot-mode');
    
    // Simple 2-level system: light violet (1-50), grey (51+)
    if (count > 0) {
      if (count <= 50) {
        badge.classList.add('dot-light-violet');
        badge.classList.remove('dot-grey');
      } else {
        badge.classList.add('dot-grey');
        badge.classList.remove('dot-light-violet');
      }
    }
  } else {
    // Switch to number mode
    badge.classList.remove('dot-mode', 'dot-light-violet', 'dot-grey');
  }
}

function isLogMessage(messageText) {
  // Check if message is from "log:" user (system messages)
  // Format: [YYYY-MM-DD HH:MM:SS] log: message
  var logPattern = /^\[[^\]]+\]\s+log:/;
  return logPattern.test(messageText);
}

function countUnreadMessages(roomName, callback) {
  // Fetch messages and count unreads after last read timestamp
  console.log('[countUnreadMessages] Fetching for room:', roomName);
  fetch('/cgi/chat-get-messages?room=' + encodeURIComponent(roomName))
    .then(function(response) { return response.text(); })
    .then(function(html) {
      var tempDiv = document.createElement('div');
      tempDiv.innerHTML = html;
      
      // Only count regular messages, not system log messages
      var messages = tempDiv.querySelectorAll('.chat-msg');  // Excludes .chat-msg-system
      var readTimestamp = getReadTimestamp(roomName);
      var unreadCount = 0;
      var lastMessageTimestamp = null;
      
      console.log('[countUnreadMessages]', roomName, '- total messages:', messages.length, 'read timestamp:', readTimestamp);
      
      messages.forEach(function(msg) {
        var timestampSpan = msg.querySelector('.timestamp');
        if (timestampSpan && timestampSpan.dataset.fullTimestamp) {
          var msgTimestamp = timestampSpan.dataset.fullTimestamp;
          lastMessageTimestamp = msgTimestamp;  // Keep updating to get the last one
          // Compare timestamps (lexicographic works for ISO format)
          if (msgTimestamp > readTimestamp) {
            unreadCount++;
          }
        }
      });
      
      console.log('[countUnreadMessages]', roomName, '- unread count:', unreadCount, 'last timestamp:', lastMessageTimestamp);
      callback(unreadCount, lastMessageTimestamp);
    })
    .catch(function(err) {
      console.error('Failed to count unread messages for', roomName, err);
      callback(0, null);
    });
}

// Badge cache with per-room timestamps to prevent stale data
window.chatApp = window.chatApp || {};
window.chatApp.badgeCache = {};  // { roomName: { count: N, timestamp: T } }
window.chatApp.BADGE_CACHE_TTL = 5000; // 5 seconds

function updateUnreadBadges() {
  // Update all unread badges in the room list
  // IMPROVED: Batch all fetches first, then update all badges at once to avoid janky sequential updates
  var badges = document.querySelectorAll('.unread-badge');
  
  // Collect all rooms that need badge updates
  var roomsToFetch = [];
  var badgesByRoom = {};
  
  badges.forEach(function(badge) {
    var roomName = badge.getAttribute('data-room');
    if (!roomName) return;
    
    // Don't show badge for current room
    if (roomName === window.currentRoom) {
      badge.classList.add('hidden');
      return;
    }
    
    // Check if we have cached data for this specific room that's still fresh
    var now = Date.now();
    var cached = window.chatApp.badgeCache[roomName];
    if (cached && (now - cached.timestamp) < window.chatApp.BADGE_CACHE_TTL) {
      // Use cached data immediately
      var count = cached.count;
      if (count > 0) {
        badge.textContent = count;
        badge.classList.remove('hidden');
        updateBadgeStyle(badge);
      } else {
        badge.classList.add('hidden');
      }
      return;
    }
    
    // Track which badge belongs to which room
    if (!badgesByRoom[roomName]) {
      badgesByRoom[roomName] = [];
      roomsToFetch.push(roomName);
    }
    badgesByRoom[roomName].push(badge);
  });
  
  // If no rooms to fetch, we're done
  if (roomsToFetch.length === 0) return;
  
  // Batch fetch all unread counts
  var fetchPromises = roomsToFetch.map(function(roomName) {
    return new Promise(function(resolve) {
      countUnreadMessages(roomName, function(count, lastMessageTimestamp) {
        resolve({ room: roomName, count: count });
      });
    });
  });
  
  // Wait for all fetches to complete, then update all badges at once
  Promise.all(fetchPromises).then(function(results) {
    var now = Date.now();
    
    // Update all badges simultaneously
    results.forEach(function(result) {
      // Cache the result with per-room timestamp
      window.chatApp.badgeCache[result.room] = {
        count: result.count,
        timestamp: now
      };
      
      // Query badges efficiently
      // Room names are server-validated to [a-zA-Z0-9_-] which are CSS-safe
      // Use CSS.escape() if available for additional safety
      var roomSelector = result.room;
      if (typeof CSS !== 'undefined' && CSS.escape) {
        roomSelector = CSS.escape(result.room);
      }
      var currentBadges = document.querySelectorAll('.unread-badge[data-room="' + roomSelector + '"]');
      
      currentBadges.forEach(function(badge) {
        // Update badge display
        if (result.count > 0) {
          badge.textContent = result.count;
          badge.classList.remove('hidden');
          // Apply current display mode styling
          updateBadgeStyle(badge);
        } else {
          badge.classList.add('hidden');
        }
      });
    });
  });
}

// Set up SSE connection for real-time unread counts
function setupUnreadCountsStream() {
  // Close existing connection if any
  if (window.unreadCountsEventSource) {
    window.unreadCountsEventSource.close();
    window.unreadCountsEventSource = null;
  }
  
  // Get current username for the SSE endpoint
  var username = getUsername();
  var url = '/cgi/chat-unread-counts?username=' + encodeURIComponent(username);
  
  // Create new EventSource connection
  window.unreadCountsEventSource = new EventSource(url);
  
  // Handle counts update events
  window.unreadCountsEventSource.addEventListener('counts', function(event) {
    try {
      var counts = JSON.parse(event.data);
      console.log('[Unread Counts] Received update:', counts);
      
      // Give htmx a moment to finish any DOM updates
      setTimeout(function() {
        // Process each room in the counts
        for (var roomName in counts) {
          if (!counts.hasOwnProperty(roomName)) continue;
          
          // Don't show badge for current room
          if (roomName === window.currentRoom) continue;
          
          var serverCount = counts[roomName] || 0;
          
          // Create closure to capture roomName
          (function(capturedRoomName, capturedServerCount) {
            console.log('[Unread Counts] Processing room:', capturedRoomName, 'serverCount:', capturedServerCount);
            
            // Query for fresh badge element
            var freshBadge = document.querySelector('.unread-badge[data-room="' + capturedRoomName + '"]');
            if (!freshBadge) {
              console.log('[Unread Counts] WARNING: No badge element found for', capturedRoomName, '- DOM might not be ready');
              return;
            }
            
            // Show badges for all rooms (visited and unvisited)
            // Only show badges for rooms with actual unread messages
            // For unvisited rooms, total count is shown (which is fine - user can see there are messages)
            // For visited rooms, accurate unread count is shown (based on read timestamp)
            if (capturedServerCount > 0) {
              // Get accurate unread count (no fallbacks - trust the calculation)
              countUnreadMessages(capturedRoomName, function(accurateCount, lastMessageTimestamp) {
                console.log('[Unread Counts] Badge for', capturedRoomName, '- accurate count:', accurateCount, 'server count:', capturedServerCount);
                
                if (accurateCount > 0) {
                  var wasVisible = !freshBadge.classList.contains('hidden');
                  var oldCount = parseInt(freshBadge.textContent) || 0;
                  
                  // SHOW badge with accurate count
                  freshBadge.textContent = accurateCount;
                  freshBadge.classList.remove('hidden');
                  freshBadge.style.display = 'inline-block';
                  updateBadgeStyle(freshBadge);
                  
                  // Trigger animation if number changed
                  if (wasVisible && oldCount !== accurateCount) {
                    freshBadge.classList.add('updating');
                    setTimeout(function() {
                      freshBadge.classList.remove('updating');
                    }, 400);
                  }
                  
                  console.log('[Unread Counts] Badge SHOWN for', capturedRoomName, ':', accurateCount);
                } else {
                  // No unreads - hide badge
                  freshBadge.classList.add('hidden');
                  freshBadge.style.display = 'none';
                  console.log('[Unread Counts] Badge HIDDEN for', capturedRoomName, '- no unreads');
                }
              });
            } else {
              // Server reports 0 messages - hide badge
              freshBadge.classList.add('hidden');
              freshBadge.style.display = 'none';
              console.log('[Unread Counts] Badge HIDDEN for', capturedRoomName, '- server count 0');
            }
          })(roomName, serverCount);
        }
      }, 100);  // 100ms delay to ensure DOM is ready
    } catch (e) {
      console.error('Error parsing unread counts:', e);
    }
  });
  
  // Handle connection errors
  window.unreadCountsEventSource.addEventListener('error', function(event) {
    console.error('[Unread Counts SSE] Error occurred:', event);
    // EventSource will automatically reconnect
  });
  
  // Log successful connection
  window.unreadCountsEventSource.addEventListener('open', function(event) {
    console.log('[Unread Counts SSE] Connected successfully');
  });
}

// Set up SSE connection for real-time room list updates
function setupRoomListStream() {
  // Close existing connection if any
  if (window.roomListEventSource) {
    window.roomListEventSource.close();
    window.roomListEventSource = null;
  }
  
  var url = '/cgi/chat-room-list-stream';
  
  // Create new EventSource connection
  window.roomListEventSource = new EventSource(url);
  
  // Handle room list update events
  window.roomListEventSource.addEventListener('rooms', function(event) {
    try {
      var rooms = JSON.parse(event.data);
      console.log('[Room List] Received update:', rooms);
      
      // Trigger htmx to refresh the room list
      // Small delay to ensure DOM is ready for htmx processing
      setTimeout(function() {
        htmx.trigger('body', 'roomListChanged');
      }, 100);
    } catch (e) {
      console.error('Error parsing room list:', e);
    }
  });
  
  // Handle connection errors
  window.roomListEventSource.addEventListener('error', function(event) {
    console.error('[Room List SSE] Error occurred:', event);
    // EventSource will automatically reconnect
  });
  
  // Log successful connection
  window.roomListEventSource.addEventListener('open', function(event) {
    console.log('[Room List SSE] Connected successfully');
  });
}

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
        // Don't re-join if already in this room
        if (window.currentRoom === room) return;
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
    
    // Update unread badges after room list is rendered
    updateUnreadBadges();
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
  // Keep send button disabled until SSE connects
  document.getElementById('send-btn').disabled = true;
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
  
  // Trigger badge update for previous room (now that we've left it)
  if (previousRoom && previousRoom !== roomName) {
    // Wait a moment for avatar to move, then update badges
    setTimeout(function() {
      updateUnreadBadges();
    }, 500);
  }
  
  // Reset scroll behavior for new room
  window.userHasScrolledUp = false;
  window.isInitialRoomLoad = true;  // Mark this as initial load
  
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
  
  // Stop heartbeat monitoring
  stopHeartbeat();
  
  // Clear any existing polling interval
  if (window.messageInterval) {
    clearInterval(window.messageInterval);
    window.messageInterval = null;
  }
  
  // CRITICAL: Capture timestamp BEFORE avatar creation
  // This ensures SSE will capture the avatar creation events
  // IMPORTANT: Use local time to match server's log-timestamp format (not UTC)
  var joinTimestamp = formatLocalTimestamp(new Date());
  
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
  
  // Add "Connecting..." status indicator to input area
  var chatInputArea = document.getElementById('chat-input-area');
  
  // Remove any existing connecting message first (prevents duplicates on rapid room switching)
  var existingConnecting = document.getElementById('connecting-status');
  if (existingConnecting) {
    existingConnecting.remove();
  }
  
  var connectingMsg = document.createElement('div');
  connectingMsg.id = 'connecting-status';
  connectingMsg.innerHTML = 'Connecting<span class="spinner-grey"></span>';
  chatInputArea.appendChild(connectingMsg);
  
  // Fade in the connecting message
  setTimeout(function() {
    connectingMsg.classList.add('visible');
  }, 10);
  
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
          // Don't animate on initial room load, only on subsequent updates
          var shouldAnimate = !window.isInitialRoomLoad;
          scrollToBottom(shouldAnimate);
          // Clear the initial load flag after first scroll
          window.isInitialRoomLoad = false;
        }
      }
      
      // Check avatar count for delete button logic
      updateDeleteButton();
      
      // Mark all current messages as read
      markRoomAsRead(window.currentRoom);
    });
}

// Scroll chat to bottom to show latest messages
function scrollToBottom(animate) {
  var chatMessagesDiv = document.getElementById('chat-messages');
  if (!chatMessagesDiv) return;
  
  // Only scroll if there's actually a scrollbar (content exceeds viewport)
  if (chatMessagesDiv.scrollHeight <= chatMessagesDiv.clientHeight) {
    return;  // No scrollbar, don't scroll
  }
  
  // Default to animated scrolling if not specified
  if (animate === undefined) {
    animate = true;
  }
  
  // Scroll to bottom - animate only when requested
  chatMessagesDiv.scrollTo({
    top: chatMessagesDiv.scrollHeight,
    behavior: animate ? 'smooth' : 'auto'
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

// Connection state tracking
window.sseReconnectAttempts = 0;
window.sseMaxReconnectAttempts = 3;  // Give up after 3 attempts
window.sseReconnectTimeout = null;
window.sseLastSuccessfulConnection = null;
window.sseHeartbeatTimeout = null;
window.sseHeartbeatInterval = 45000;  // 45 seconds - server pings every 15s, so this allows 3 missed pings
window.sseSpinnerElement = null;  // Global spinner to prevent animation reset

// Reset heartbeat timer - call this whenever we receive ANY event from server
function resetHeartbeat(roomName) {
  // Clear existing timeout
  if (window.sseHeartbeatTimeout) {
    clearTimeout(window.sseHeartbeatTimeout);
    window.sseHeartbeatTimeout = null;
  }
  
  // Set new timeout
  window.sseHeartbeatTimeout = setTimeout(function() {
    console.error('[SSE] Heartbeat timeout - no events received for', window.sseHeartbeatInterval / 1000, 'seconds');
    
    // Connection is dead - close it and trigger reconnection
    if (window.messageEventSource) {
      console.log('[SSE] Closing dead connection');
      window.messageEventSource.close();
      window.messageEventSource = null;
    }
    
    // Trigger reconnection logic
    if (window.sseReconnectAttempts < window.sseMaxReconnectAttempts) {
      window.sseReconnectAttempts++;
      console.log('[SSE] Reconnect attempt', window.sseReconnectAttempts, 'of', window.sseMaxReconnectAttempts, '(heartbeat timeout)');
      
      updateConnectionStatus('reconnecting', false);
      
      // Wait 2 seconds before reconnecting
      window.sseReconnectTimeout = setTimeout(function() {
        if (window.currentRoom === roomName) {
          console.log('[SSE] Auto-reconnecting to room:', roomName);
          setupMessageStream(roomName, formatLocalTimestamp(new Date()));
        }
      }, 2000);
    } else {
      // Max attempts reached - show connection lost
      console.error('[SSE] Max reconnection attempts reached - giving up');
      updateConnectionStatus('lost', true);
    }
  }, window.sseHeartbeatInterval);
}

// Stop heartbeat monitoring
function stopHeartbeat() {
  if (window.sseHeartbeatTimeout) {
    clearTimeout(window.sseHeartbeatTimeout);
    window.sseHeartbeatTimeout = null;
  }
}

// Update connection status UI
function updateConnectionStatus(status, isClickable) {
  var statusElement = document.getElementById('connecting-status');
  var sendBtn = document.getElementById('send-btn');
  var chatInputArea = document.getElementById('chat-input-area');
  var createRoomLink = document.getElementById('create-room-link');
  var usernameChangeBtn = document.querySelector('.username-display button');
  
  // Determine if we should use alternate positioning (when no room selected)
  var useAlternatePosition = !chatInputArea || chatInputArea.style.display === 'none';
  
  // If element doesn't exist and we need to show a status, create it
  if (!statusElement && status !== 'connected') {
    statusElement = document.createElement('div');
    statusElement.id = 'connecting-status';
    
    if (useAlternatePosition) {
      // Position in center of empty message box when input area is hidden
      var chatMessages = document.getElementById('chat-messages');
      if (chatMessages) {
        chatMessages.appendChild(statusElement);
        statusElement.classList.add('no-room-position');
      }
    } else if (chatInputArea) {
      chatInputArea.appendChild(statusElement);
      statusElement.classList.remove('no-room-position');
    } else {
      // Can't create status element
      console.warn('[SSE] Cannot show connection status - no suitable parent found');
      return;
    }
  } else if (statusElement) {
    // Update positioning if needed
    if (useAlternatePosition && !statusElement.classList.contains('no-room-position')) {
      // Move to alternate position
      var chatMessages = document.getElementById('chat-messages');
      if (chatMessages) {
        chatMessages.appendChild(statusElement);
        statusElement.classList.add('no-room-position');
      }
    } else if (!useAlternatePosition && statusElement.classList.contains('no-room-position')) {
      // Move back to input area
      if (chatInputArea) {
        chatInputArea.appendChild(statusElement);
        statusElement.classList.remove('no-room-position');
      }
    }
  }
  
  // Clear any existing timeout
  if (window.sseReconnectTimeout) {
    clearTimeout(window.sseReconnectTimeout);
    window.sseReconnectTimeout = null;
  }
  
  // Manage disabled state for Create Room link and username Change button
  var isDisconnected = (status === 'lost' || status === 'reconnecting');
  if (createRoomLink) {
    if (isDisconnected) {
      createRoomLink.classList.add('disabled');
      createRoomLink.onclick = function(e) { e.preventDefault(); return false; };
    } else {
      createRoomLink.classList.remove('disabled');
      createRoomLink.onclick = function() { toggleCreateRoom(); return false; };
    }
  }
  if (usernameChangeBtn) {
    usernameChangeBtn.disabled = isDisconnected;
  }
  
  if (status === 'connected') {
    // Connection successful - fade out status message
    if (statusElement) {
      statusElement.classList.remove('visible', 'connection-lost');
      setTimeout(function() {
        if (statusElement && statusElement.parentNode) {
          statusElement.remove();
        }
      }, 300);  // Match transition duration
    }
    if (sendBtn) sendBtn.disabled = false;
    window.sseReconnectAttempts = 0;  // Reset counter on success
    window.sseLastSuccessfulConnection = Date.now();
  } else if (status === 'connecting') {
    // Show connecting with spinner
    // Use global spinner to prevent animation reset
    statusElement.classList.remove('connection-lost');
    
    // Get or create the global spinner
    if (!window.sseSpinnerElement) {
      window.sseSpinnerElement = document.createElement('span');
      window.sseSpinnerElement.className = 'spinner-grey';
    }
    
    // Clear content and set text with spinner
    statusElement.textContent = 'Connecting';
    statusElement.appendChild(window.sseSpinnerElement);
    
    statusElement.classList.add('visible');
    statusElement.onclick = null;
    statusElement.onmouseenter = null;
    statusElement.onmouseleave = null;
    if (sendBtn) sendBtn.disabled = true;
  } else if (status === 'reconnecting') {
    // Show reconnecting with spinner
    // Use global spinner to prevent animation reset
    
    // Remove connection-lost styling first to prevent layout shift
    statusElement.classList.remove('connection-lost');
    
    // Get or create the global spinner
    if (!window.sseSpinnerElement) {
      window.sseSpinnerElement = document.createElement('span');
      window.sseSpinnerElement.className = 'spinner-grey';
    }
    
    // Clear content and set text with spinner
    statusElement.textContent = 'Reconnecting';
    statusElement.appendChild(window.sseSpinnerElement);
    
    // Ensure visible class is present (no fade needed if already visible)
    statusElement.classList.add('visible');
    
    statusElement.onclick = null;
    statusElement.onmouseenter = null;
    statusElement.onmouseleave = null;
    if (sendBtn) sendBtn.disabled = true;
  } else if (status === 'lost') {
    // Show disconnected (clickable pill, no spinner)
    
    // First, set content and styling while keeping invisible
    statusElement.classList.remove('visible');
    statusElement.classList.add('connection-lost');
    statusElement.innerHTML = 'Disconnected';
    
    // Force reflow then add visible class for fade-in
    statusElement.offsetHeight;
    statusElement.classList.add('visible');
    
    // Setup handlers
    statusElement.onclick = function() {
      attemptReconnection(window.currentRoom);
    };
    // Add hover effect to change text
    statusElement.onmouseenter = function() {
      this.innerHTML = 'Retry';
    };
    statusElement.onmouseleave = function() {
      this.innerHTML = 'Disconnected';
    };
    if (sendBtn) sendBtn.disabled = true;
  }
}

// Attempt to reconnect to SSE
function attemptReconnection(roomName) {
  if (!roomName) return;
  
  console.log('[SSE] Manual reconnection attempt for room:', roomName);
  window.sseReconnectAttempts = 0;  // Reset attempts for manual reconnection
  
  // Show "Reconnecting" message
  updateConnectionStatus('reconnecting', false);
  
  // Close existing connection
  if (window.messageEventSource) {
    window.messageEventSource.close();
    window.messageEventSource = null;
  }
  
  // Use timestamp from before manual reconnection
  var sinceTimestamp = formatLocalTimestamp(new Date());
  setupMessageStream(roomName, sinceTimestamp);
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
    // IMPORTANT: Use local time to match server's log-timestamp format (not UTC)
    sinceTimestamp = formatLocalTimestamp(new Date());
  }
  
  // Create new SSE connection with since parameter
  var url = '/cgi/chat-stream?room=' + encodeURIComponent(roomName) + '&since=' + encodeURIComponent(sinceTimestamp);
  
  try {
    window.messageEventSource = new EventSource(url);
  } catch (e) {
    console.error('[SSE] Failed to create EventSource:', e);
    updateConnectionStatus('lost', true);
    return;
  }
  
  // Track connection state
  var connectionEstablished = false;
  var errorCount = 0;
  
  // Handle connection open
  window.messageEventSource.addEventListener('open', function(event) {
    console.log('[SSE] Connection OPEN - ready to receive messages');
    connectionEstablished = true;
    errorCount = 0;
    
    updateConnectionStatus('connected', false);
    
    // Start heartbeat monitoring
    resetHeartbeat(roomName);
  });
  
  // Handle incoming messages
  window.messageEventSource.addEventListener('message', function(event) {
    var timestamp = new Date().toISOString();
    // Event data is a single message line: [YYYY-MM-DD HH:MM:SS] username: message
    appendMessage(event.data);
    
    // Update last successful connection time
    window.sseLastSuccessfulConnection = Date.now();
    
    // Reset heartbeat timer - we received an event
    resetHeartbeat(roomName);
  });
  
  // Handle member list updates
  window.messageEventSource.addEventListener('members', function(event) {
    // Event data is JSON array of members
    updateMemberList(event.data);
    
    // Reset heartbeat timer - we received an event
    resetHeartbeat(roomName);
  });
  
  // Handle errors
  window.messageEventSource.addEventListener('error', function(event) {
    console.error('[SSE] Error occurred:', event);
    console.error('[SSE] ReadyState:', window.messageEventSource.readyState);
    console.error('[SSE] URL:', window.messageEventSource.url);
    
    // Stop heartbeat monitoring during error state
    stopHeartbeat();
    
    errorCount++;
    
    if (window.messageEventSource.readyState === EventSource.CLOSED) {
      console.error('[SSE] Connection CLOSED - server unavailable');
      
      // Determine if we should try to reconnect
      if (window.sseReconnectAttempts < window.sseMaxReconnectAttempts) {
        window.sseReconnectAttempts++;
        console.log('[SSE] Reconnect attempt', window.sseReconnectAttempts, 'of', window.sseMaxReconnectAttempts);
        
        updateConnectionStatus('reconnecting', false);
        
        // Wait 2 seconds before reconnecting
        window.sseReconnectTimeout = setTimeout(function() {
          if (window.currentRoom === roomName) {
            console.log('[SSE] Auto-reconnecting to room:', roomName);
            setupMessageStream(roomName, formatLocalTimestamp(new Date()));
          }
        }, 2000);
      } else {
        // Max attempts reached - show connection lost
        console.error('[SSE] Max reconnection attempts reached - giving up');
        updateConnectionStatus('lost', true);
      }
    } else if (window.messageEventSource.readyState === EventSource.CONNECTING) {
      console.warn('[SSE] Connection CONNECTING - EventSource attempting to reconnect');
      
      // If we've been connecting for too long, consider it lost
      if (!connectionEstablished && errorCount > 2) {
        console.error('[SSE] Connection attempts failing - server may be down');
        updateConnectionStatus('reconnecting', false);
      }
    }
  });
  
  // Optional: Handle ping/keepalive events (currently just ignore them)
  window.messageEventSource.addEventListener('ping', function(event) {
    // Update last successful connection time
    window.sseLastSuccessfulConnection = Date.now();
    
    // Reset heartbeat timer - we received a ping
    resetHeartbeat(roomName);
  });
  
  // Add a timeout warning if connection not established after 5 seconds
  setTimeout(function() {
    if (window.messageEventSource && !connectionEstablished) {
      if (window.messageEventSource.readyState === EventSource.CONNECTING) {
        console.warn('[SSE] WARNING: Still CONNECTING after 5 seconds - possible server issue');
        updateConnectionStatus('reconnecting', false);
      } else if (window.messageEventSource.readyState === EventSource.CLOSED) {
        console.error('[SSE] Connection failed within 5 seconds');
        if (window.sseReconnectAttempts < window.sseMaxReconnectAttempts) {
          window.sseReconnectAttempts++;
          updateConnectionStatus('reconnecting', false);
          window.sseReconnectTimeout = setTimeout(function() {
            if (window.currentRoom === roomName) {
              setupMessageStream(roomName, formatLocalTimestamp(new Date()));
            }
          }, 2000);
        } else {
          updateConnectionStatus('lost', true);
        }
      }
    }
  }, 5000);
  
  // Periodic connection health check every 30 seconds
  var healthCheckInterval = setInterval(function() {
    if (!window.messageEventSource || window.currentRoom !== roomName) {
      clearInterval(healthCheckInterval);
      return;
    }
    
    // If no activity for 60 seconds, connection might be stale
    if (window.sseLastSuccessfulConnection && 
        (Date.now() - window.sseLastSuccessfulConnection) > 60000 &&
        window.messageEventSource.readyState !== EventSource.CONNECTING) {
      console.warn('[SSE] No activity for 60 seconds - connection may be stale');
    }
  }, 30000);
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
    
    // Mark regular message as read (current room only, not system log messages)
    if (window.currentRoom) {
      var currentReadTimestamp = getReadTimestamp(window.currentRoom);
      if (fullTimestamp > currentReadTimestamp) {
        setReadTimestamp(window.currentRoom, fullTimestamp);
      }
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
      htmx.trigger('body', 'roomListChanged');
    })
    .catch(function(err) {
      console.error('Failed to delete room:', err);
      htmx.trigger('body', 'roomListChanged');
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
      // Only send if button is not disabled
      if (!sendBtn.disabled) {
        sendMessage();
      }
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

// Initialize unread counts SSE connection on page load
document.addEventListener('DOMContentLoaded', function() {
  setupUnreadCountsStream();
  setupRoomListStream();
  
  // Initialize toggle checkbox based on saved mode
  // Inverted: checked = show counts (number mode)
  var mode = getBadgeMode();
  var toggleCheckbox = document.getElementById('badge-mode-toggle');
  if (toggleCheckbox) {
    toggleCheckbox.checked = (mode === 'number');
  }
  
  // Apply initial badge styles
  updateAllBadgeStyles();
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
  
  // Stop heartbeat monitoring
  stopHeartbeat();
  
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
