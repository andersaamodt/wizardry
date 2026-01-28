# Troubleshooting CGI and htmx Issues

## Quick Diagnosis

If your CGI buttons don't work, follow these steps:

### Step 1: Verify Your Site Was Rebuilt

The htmx library must be included in your HTML. If you have an existing site, rebuild it:

```bash
build yoursite --full
```

**This is the most common issue!** Old HTML files don't have htmx.

### Step 2: Add Diagnostic Page

Add the diagnostic page to your site to help identify issues:

```bash
# Copy diagnostic template
cp .templates/demo/pages/diagnostics.md ~/sites/yoursite/site/pages/

# Rebuild
build yoursite

# Open in browser
# http://localhost:8080/pages/diagnostics.html
```

### Step 3: Check fcgiwrap is Running

CGI requires fcgiwrap to be running:

```bash
# Check if fcgiwrap is running
ps aux | grep fcgiwrap

# Check for socket file
ls -la ~/sites/yoursite/nginx/fcgiwrap.sock
```

If fcgiwrap is not running, restart your site:

```bash
stop-site yoursite
serve-site yoursite
```

### Step 4: Check nginx Error Log

```bash
# View recent errors
tail -20 ~/sites/yoursite/nginx/error.log

# Watch errors in real-time
tail -f ~/sites/yoursite/nginx/error.log
```

Common errors:
- **"connect() to unix:/path/fcgiwrap.sock failed"** - fcgiwrap not running
- **"Permission denied"** - CGI script not executable
- **"No such file"** - CGI script doesn't exist

### Step 5: Check Browser Console

1. Open your site in browser
2. Press F12 to open Developer Tools
3. Go to Console tab
4. Look for JavaScript errors (red text)
5. Check if htmx is loaded:
   ```javascript
   typeof htmx
   ```
   Should show: `"object"` (not `"undefined"`)

### Step 6: Check Network Tab

1. Open Developer Tools (F12)
2. Go to Network tab
3. Click a CGI button
4. Look for requests to `/cgi/...`

If NO requests appear:
- htmx is not loaded (rebuild site)
- JavaScript error preventing htmx from working

If requests appear but fail:
- Check status code (404, 403, 500, 502)
- Click on request to see details
- Check response tab for error messages

## Common Issues and Solutions

### Issue: Buttons do nothing, no network activity

**Cause:** htmx not loaded

**Solution:**
```bash
build yoursite --full
```

Verify htmx in HTML:
```bash
grep "htmx" ~/sites/yoursite/build/pages/index.html
```

Should show: `<script src="https://unpkg.com/htmx.org@1.9.10"></script>`

### Issue: 502 Bad Gateway

**Cause:** fcgiwrap not running

**Solution:**
```bash
# Check if fcgiwrap installed
command -v fcgiwrap

# Restart site to start fcgiwrap
stop-site yoursite
serve-site yoursite

# Verify fcgiwrap started
ps aux | grep fcgiwrap
```

### Issue: 404 Not Found on /cgi/...

**Cause:** nginx location config or CGI script doesn't exist

**Solution:**

Check nginx config has CGI location block:
```bash
grep "location.*cgi" ~/sites/yoursite/nginx/nginx.conf
```

Should see:
```nginx
location ~ ^/cgi/(.+)$ {
    ...
    fastcgi_pass unix:/path/to/fcgiwrap.sock;
    ...
}
```

If missing, regenerate nginx.conf:
```bash
site-menu yoursite
→ Select "Rebuild nginx.conf"
```

### Issue: 403 Forbidden on /cgi/...

**Cause:** CGI script not executable

**Solution:**

CGI scripts in `~/.wizardry/spells/.imps/cgi/` should be executable:
```bash
ls -la ~/.wizardry/spells/.imps/cgi/ | head -10
```

All should have `x` permission. If not:
```bash
chmod +x ~/.wizardry/spells/.imps/cgi/*
```

### Issue: 500 Internal Server Error

**Cause:** CGI script has an error

**Solution:**

Test the CGI script directly:
```bash
# Set environment
export REQUEST_METHOD=GET
export QUERY_STRING=""

# Run the script
~/.wizardry/spells/.imps/cgi/example-cgi
```

Check for errors in output.

## Testing CGI Manually

### Test 1: Check htmx loads

```bash
# View page source in browser, search for "htmx"
# Or check HTML file:
grep -i htmx ~/sites/yoursite/build/pages/index.html
```

### Test 2: Test CGI script directly

```bash
# In browser, navigate to:
http://localhost:8080/cgi/example-cgi

# Should see HTML response, not error
```

### Test 3: Test with curl

```bash
# Test CGI endpoint
curl http://localhost:8080/cgi/example-cgi

# Should return HTML with "Hello from CGI"
```

### Test 4: Check fcgiwrap socket

```bash
# Socket should exist and be accessible
ls -la ~/sites/yoursite/nginx/fcgiwrap.sock

# Should show: srwxr-xr-x (socket file)
```

## Still Not Working?

If you've tried all the above and it still doesn't work:

1. **Stop and restart everything:**
   ```bash
   stop-site yoursite
   rm -rf ~/sites/yoursite/nginx/
   serve-site yoursite
   ```

2. **Check the diagnostic page:**
   - Add diagnostics.md to your site
   - Build and open in browser
   - Follow the step-by-step checks

3. **Capture full logs:**
   ```bash
   # Start site with full logging
   stop-site yoursite
   serve-site yoursite 2>&1 | tee ~/serve.log
   
   # In another terminal, test the site
   # Then check ~/serve.log for errors
   ```

4. **Check this repository for issues:**
   - Look for similar issues
   - Create new issue with:
     - Output of diagnostic page
     - nginx error log
     - Browser console output
     - Output of `ps aux | grep -E "(nginx|fcgiwrap)"`
