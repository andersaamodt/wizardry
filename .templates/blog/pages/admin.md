---
title: Blog Admin
---

# Blog Admin Panel

<div id="auth-status" style="padding: 1rem; margin-bottom: 1rem; border-radius: 4px;"></div>

<div id="admin-panel" style="display: none;">

## Settings

<div class="demo-box">
<h3>Site Configuration</h3>

<div style="margin-bottom: 1rem;">
<label style="display: block; margin-bottom: 0.5rem;"><strong>Site Title:</strong></label>
<input type="text" id="site-title" style="width: 100%; padding: 0.5rem; border: 2px solid #ddd; border-radius: 4px;">
</div>

<div style="margin-bottom: 1rem;">
<label style="display: flex; align-items: center; gap: 0.5rem;">
<input type="checkbox" id="registration-enabled">
<strong>Enable User Registration</strong>
</label>
<p style="font-size: 0.9rem; color: #666; margin: 0.5rem 0 0 1.5rem;">
Allow new users to register with their MUD player SSH keys
</p>
</div>

<button id="btn-save-config" style="padding: 0.75rem 1.5rem; background: #3498db; color: white; border: none; border-radius: 4px; cursor: pointer;">💾 Save Settings</button>

<div id="output-config" class="output"></div>
</div>

## Compose New Post

<div class="demo-box">
<h3>✍️ Markdown Composer</h3>

<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">

<div>
<h4 style="margin-top: 0;">Editor</h4>

<div style="margin-bottom: 1rem;">
<label style="display: block; margin-bottom: 0.5rem;"><strong>Post Title:</strong></label>
<input type="text" id="post-title" placeholder="My Amazing Post" style="width: 100%; padding: 0.5rem; border: 2px solid #ddd; border-radius: 4px;">
</div>

<div style="margin-bottom: 1rem;">
<label style="display: block; margin-bottom: 0.5rem;"><strong>Tags (comma-separated):</strong></label>
<input type="text" id="post-tags" placeholder="tech, tutorial, wizardry" style="width: 100%; padding: 0.5rem; border: 2px solid #ddd; border-radius: 4px;">
</div>

<div style="margin-bottom: 1rem;">
<label style="display: block; margin-bottom: 0.5rem;"><strong>Summary:</strong></label>
<input type="text" id="post-summary" placeholder="A brief description" style="width: 100%; padding: 0.5rem; border: 2px solid #ddd; border-radius: 4px;">
</div>

<div style="margin-bottom: 1rem;">
<label style="display: block; margin-bottom: 0.5rem;"><strong>Content (Markdown):</strong></label>
<textarea id="post-content" rows="15" placeholder="# Your post content here&#10;&#10;Write in **Markdown**!&#10;&#10;- Lists work&#10;- Code blocks too&#10;&#10;```sh&#10;echo 'Hello, World!'&#10;```" style="width: 100%; padding: 0.75rem; border: 2px solid #ddd; border-radius: 4px; font-family: monospace; font-size: 0.9rem;"></textarea>
</div>

<div style="display: flex; gap: 0.5rem;">
<button id="btn-save-draft" style="padding: 0.75rem 1.5rem; background: #95a5a6; color: white; border: none; border-radius: 4px; cursor: pointer;">💾 Save as Draft</button>
<button id="btn-publish" style="padding: 0.75rem 1.5rem; background: #27ae60; color: white; border: none; border-radius: 4px; cursor: pointer;">🚀 Publish</button>
</div>

<div id="output-compose" class="output"></div>
</div>

<div>
<h4 style="margin-top: 0;">Live Preview</h4>
<div id="markdown-preview" style="border: 2px solid #ddd; border-radius: 4px; padding: 1rem; min-height: 400px; background: white; overflow-y: auto; max-height: 600px;">
<p style="color: #999; font-style: italic;">Preview will appear here...</p>
</div>
</div>

</div>
</div>

## Manage Drafts

<div class="demo-box">
<h3>📝 Draft Posts</h3>

<button id="btn-refresh-drafts" style="padding: 0.5rem 1rem; background: #3498db; color: white; border: none; border-radius: 4px; cursor: pointer; margin-bottom: 1rem;">🔄 Refresh</button>

<div id="drafts-list" style="margin-top: 1rem;"></div>
</div>

</div>

<script src="https://cdn.jsdelivr.net/npm/marked@11.0.0/marked.min.js"></script>
<script>
(function() {
  const authStatus = document.getElementById('auth-status');
  const adminPanel = document.getElementById('admin-panel');
  let sessionToken = localStorage.getItem('session_token');
  let isAdmin = false;
  let username = '';
  
  // Check authentication status
  async function checkAuth() {
    if (!sessionToken) {
      showAuthMessage('Not logged in. Please <a href="ssh-auth.html">login</a> first.', 'error');
      return;
    }
    
    try {
      const response = await fetch('/cgi/ssh-auth-check-session?session_token=' + encodeURIComponent(sessionToken));
      const data = await response.json();
      
      if (data.authenticated && data.is_admin) {
        isAdmin = true;
        username = data.username;
        showAuthMessage('Logged in as: <strong>' + username + '</strong> (Admin)', 'success');
        adminPanel.style.display = 'block';
        loadConfig();
        loadDrafts();
      } else if (data.authenticated) {
        showAuthMessage('Logged in as: <strong>' + data.username + '</strong> (No admin permissions)', 'warning');
      } else {
        showAuthMessage('Session expired. Please <a href="ssh-auth.html">login</a> again.', 'error');
        localStorage.removeItem('session_token');
      }
    } catch (error) {
      showAuthMessage('Error checking authentication: ' + error.message, 'error');
    }
  }
  
  function showAuthMessage(message, type) {
    const colors = {
      success: '#e8f5e9',
      error: '#ffebee',
      warning: '#fff3e0'
    };
    const borderColors = {
      success: '#4caf50',
      error: '#f44336',
      warning: '#ff9800'
    };
    authStatus.style.background = colors[type] || '#f5f5f5';
    authStatus.style.border = '1px solid ' + (borderColors[type] || '#ddd');
    authStatus.innerHTML = message;
  }
  
  // Load configuration
  async function loadConfig() {
    try {
      const response = await fetch('/cgi/blog-get-config');
      const data = await response.json();
      
      if (data.success) {
        document.getElementById('site-title').value = data.site_title || 'My Blog';
        document.getElementById('registration-enabled').checked = data.registration_enabled !== 'false';
      }
    } catch (error) {
      console.error('Error loading config:', error);
    }
  }
  
  // Save configuration
  document.getElementById('btn-save-config').addEventListener('click', async () => {
    const output = document.getElementById('output-config');
    const siteTitle = document.getElementById('site-title').value;
    const regEnabled = document.getElementById('registration-enabled').checked ? 'true' : 'false';
    
    try {
      const params = new URLSearchParams({
        session_token: sessionToken,
        site_title: siteTitle,
        registration_enabled: regEnabled
      });
      
      const response = await fetch('/cgi/blog-update-config?' + params.toString());
      const data = await response.json();
      
      if (data.success) {
        output.innerHTML = '<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50; margin-top: 1rem;"><strong>✅ Settings saved!</strong></div>';
      } else {
        output.innerHTML = '<div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336; margin-top: 1rem;"><strong>❌ Error:</strong> ' + (data.error || 'Unknown error') + '</div>';
      }
    } catch (error) {
      output.innerHTML = '<div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336; margin-top: 1rem;"><strong>❌ Error:</strong> ' + error.message + '</div>';
    }
  });
  
  // Live markdown preview
  const contentArea = document.getElementById('post-content');
  const previewArea = document.getElementById('markdown-preview');
  
  function updatePreview() {
    const markdown = contentArea.value;
    if (markdown.trim()) {
      previewArea.innerHTML = marked.parse(markdown);
    } else {
      previewArea.innerHTML = '<p style="color: #999; font-style: italic;">Preview will appear here...</p>';
    }
  }
  
  contentArea.addEventListener('input', updatePreview);
  
  // Load drafts
  async function loadDrafts() {
    const draftsList = document.getElementById('drafts-list');
    draftsList.innerHTML = '<p style="color: #666;">Loading drafts...</p>';
    
    try {
      const response = await fetch('/cgi/blog-list-drafts?session_token=' + encodeURIComponent(sessionToken));
      const data = await response.json();
      
      if (data.success) {
        if (data.drafts && data.drafts.length > 0) {
          let html = '<div style="display: grid; gap: 0.5rem;">';
          data.drafts.forEach(draft => {
            html += '<div style="border: 1px solid #ddd; border-radius: 4px; padding: 0.75rem; background: #f9f9f9;">';
            html += '<strong>' + draft.title + '</strong>';
            html += '<br><span style="font-size: 0.85rem; color: #666;">' + draft.filename + '</span>';
            html += '</div>';
          });
          html += '</div>';
          draftsList.innerHTML = html;
        } else {
          draftsList.innerHTML = '<p style="color: #666;">No drafts found.</p>';
        }
      } else {
        draftsList.innerHTML = '<p style="color: #f44336;">Error loading drafts: ' + (data.error || 'Unknown error') + '</p>';
      }
    } catch (error) {
      draftsList.innerHTML = '<p style="color: #f44336;">Error: ' + error.message + '</p>';
    }
  }
  
  document.getElementById('btn-refresh-drafts').addEventListener('click', loadDrafts);
  
  // Save draft / publish (placeholder - needs backend implementation)
  document.getElementById('btn-save-draft').addEventListener('click', () => {
    const output = document.getElementById('output-compose');
    output.innerHTML = '<div style="background: #fff3e0; padding: 1rem; border-radius: 4px; border: 1px solid #ff9800; margin-top: 1rem;"><strong>ℹ️ Note:</strong> Draft saving functionality coming soon! Posts are file-backed, so drafts would be saved to the site/pages/posts/ directory.</div>';
  });
  
  document.getElementById('btn-publish').addEventListener('click', () => {
    const output = document.getElementById('output-compose');
    output.innerHTML = '<div style="background: #fff3e0; padding: 1rem; border-radius: 4px; border: 1px solid #ff9800; margin-top: 1rem;"><strong>ℹ️ Note:</strong> Publishing functionality coming soon! Published posts would be saved with visibility: "public" in the front matter.</div>';
  });
  
  // Initialize
  checkAuth();
})();
</script>

<style>
.demo-box {
  background: #f5f7fa;
  border: 2px solid #3498db;
  border-radius: 8px;
  padding: 1.5rem;
  margin: 2rem 0;
}

.output {
  min-height: 20px;
}

button:hover {
  opacity: 0.9;
}

button:active {
  opacity: 0.8;
}

#markdown-preview h1, #markdown-preview h2, #markdown-preview h3 {
  margin-top: 1rem;
  margin-bottom: 0.5rem;
}

#markdown-preview p {
  margin: 0.5rem 0;
}

#markdown-preview code {
  background: #f4f4f4;
  padding: 0.2rem 0.4rem;
  border-radius: 3px;
  font-family: monospace;
}

#markdown-preview pre {
  background: #2c3e50;
  color: #ecf0f1;
  padding: 1rem;
  border-radius: 4px;
  overflow-x: auto;
}

#markdown-preview pre code {
  background: none;
  padding: 0;
  color: inherit;
}

@media (max-width: 768px) {
  .demo-box > div > div {
    grid-template-columns: 1fr !important;
  }
}
</style>
