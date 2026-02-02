---
title: CGI Diagnostics
---

This page helps diagnose issues with CGI functionality.

## 1. htmx Library Check

<div id="htmx-check" style="padding: 10px; margin: 10px 0; border: 2px solid #ccc; border-radius: 5px;">
  <script>
  (function() {
    var el = document.getElementById('htmx-check');
    if (typeof htmx !== 'undefined') {
      el.innerHTML = '<strong style="color: green;">✅ htmx is loaded!</strong><br>Version: ' + (htmx.version || 'unknown');
      el.style.background = '#d4edda';
      el.style.borderColor = '#c3e6cb';
    } else {
      el.innerHTML = '<strong style="color: red;">❌ htmx is NOT loaded!</strong><br>The page needs to be rebuilt with the updated build spell.';
      el.style.background = '#f8d7da';
      el.style.borderColor = '#f5c6cb';
    }
  })();
  </script>
</div>

## 2. Simple CGI Test

Click this button to test if CGI is working:

<div style="margin: 20px 0;">
  <button 
    hx-get="/cgi/debug-test" 
    hx-target="#cgi-result"
    hx-swap="innerHTML"
    style="padding: 10px 20px; font-size: 16px; cursor: pointer; background: #007bff; color: white; border: none; border-radius: 5px;">
    Test CGI
  </button>
</div>

<div id="cgi-result" style="padding: 10px; margin: 10px 0; border: 2px dashed #ccc; border-radius: 5px; min-height: 50px;">
  <em>Click the button above to test CGI...</em>
</div>

## 3. htmx Event Logging

<div id="event-log" style="padding: 10px; margin: 10px 0; border: 1px solid #ccc; border-radius: 5px; max-height: 300px; overflow-y: auto; font-family: monospace; font-size: 12px; background: #f8f9fa;">
  <strong>htmx Event Log:</strong><br>
  <div id="log-content"></div>
</div>

<script>
// Log htmx events for debugging
if (typeof htmx !== 'undefined') {
  var logEl = document.getElementById('log-content');
  var events = ['htmx:beforeRequest', 'htmx:afterRequest', 'htmx:responseError', 'htmx:sendError', 'htmx:configRequest'];
  
  events.forEach(function(eventName) {
    document.body.addEventListener(eventName, function(evt) {
      var time = new Date().toLocaleTimeString();
      var msg = time + ' - ' + eventName;
      
      if (evt.detail) {
        if (evt.detail.xhr) {
          msg += ' - Status: ' + evt.detail.xhr.status;
          msg += ' - URL: ' + (evt.detail.pathInfo ? evt.detail.pathInfo.requestPath : 'unknown');
        }
        if (evt.detail.error) {
          msg += ' - Error: ' + evt.detail.error;
        }
      }
      
      var line = document.createElement('div');
      line.textContent = msg;
      line.style.padding = '2px 0';
      line.style.borderBottom = '1px solid #dee2e6';
      logEl.appendChild(line);
      
      // Auto-scroll to bottom
      document.getElementById('event-log').scrollTop = document.getElementById('event-log').scrollHeight;
    });
  });
  
  // Add a startup message
  var line = document.createElement('div');
  line.textContent = new Date().toLocaleTimeString() + ' - Event logging initialized';
  line.style.padding = '2px 0';
  line.style.color = '#28a745';
  logEl.appendChild(line);
} else {
  document.getElementById('event-log').innerHTML = '<em style="color: red;">htmx not loaded - cannot log events</em>';
}
</script>

## 4. Direct CGI Test

Try accessing the CGI endpoint directly (will open in new tab):

<a href="/cgi/debug-test" target="_blank" style="display: inline-block; padding: 10px 20px; background: #28a745; color: white; text-decoration: none; border-radius: 5px;">
  Open /cgi/debug-test directly
</a>

## 5. Troubleshooting Steps

If the test above fails, check:

1. **Has the site been rebuilt?**
   ```bash
   build yoursite --full
   ```

2. **Is fcgiwrap running?**
   ```bash
   ps aux | grep fcgiwrap
   ```

3. **Check nginx error log:**
   ```bash
   cat ~/sites/yoursite/nginx/error.log
   ```

4. **Is fcgiwrap socket accessible?**
   ```bash
   ls -la ~/sites/yoursite/nginx/fcgiwrap.sock
   ```

5. **Check browser console (F12) for JavaScript errors**

6. **Check Network tab (F12) - are requests being sent?**

## Common Issues

- **No network requests**: htmx not loaded or JavaScript error
- **404 errors**: nginx config issue or CGI script doesn't exist
- **403 errors**: Permission issue on CGI scripts
- **502 errors**: fcgiwrap not running or socket issue
- **500 errors**: CGI script has an error

---

[← Back to Home](/pages/index.html)
