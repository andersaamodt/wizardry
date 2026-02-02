---
title: File Upload Demos
---

These demos showcase browser file handling capabilities, including file selection, drag-and-drop, and binary data processing.

## 1. Basic Image Upload & Display

Upload an image and see it displayed instantly:

<div class="demo-box">
<input type="text" id="upload-filename" placeholder="Enter image name (e.g., logo.png)" value="demo-image.png" />
<button hx-get="/cgi/upload-image" hx-vals='js:{filename: document.getElementById("upload-filename").value}' hx-target="#upload-display" hx-swap="innerHTML" hx-trigger="click, keyup[key=='Enter'] from:#upload-filename" class="primary">
    Upload & Display
</button>
<div id="upload-display" class="output">
</div>
</div>

## 2. Drag-and-Drop File Upload

Upload any file type with drag-and-drop. Files are automatically displayed if possible:

<style>
.drop-zone {
  border: 3px dashed #ccc;
  border-radius: 8px;
  padding: 2rem;
  text-align: center;
  background: #fafafa;
  transition: all 0.3s ease;
  cursor: pointer;
  margin: 1rem 0;
}

.drop-zone:hover, .drop-zone.drag-over {
  border-color: #007bff;
  background: #e7f3ff;
  transform: scale(1.02);
}

.drop-zone.drag-over {
  border-color: #28a745;
  background: #d4edda;
}

.file-input-wrapper {
  position: relative;
  overflow: hidden;
  display: inline-block;
}

.file-input-wrapper input[type=file] {
  position: absolute;
  left: -9999px;
}

.file-input-wrapper label {
  display: inline-block;
  padding: 0.75rem 1.5rem;
  background: #007bff;
  color: white;
  border-radius: 4px;
  cursor: pointer;
  transition: background 0.3s;
}

.file-input-wrapper label:hover {
  background: #0056b3;
}
</style>

<div class="demo-box">
<div id="drop-zone" class="drop-zone">
<p style="font-size: 2rem; margin: 0;">📁</p>
<p style="margin: 0.5rem 0;"><strong>Drag and drop a file here</strong></p>
<p style="color: #666; margin: 0.5rem 0;">or</p>
<div class="file-input-wrapper">
<label for="file-input">Choose File</label>
<input type="file" id="file-input" />
</div>
<p style="color: #999; font-size: 0.9rem; margin-top: 1rem;">
Supports: Images, Videos, Audio, PDFs, Text files, and more
</p>
</div>

<div id="drag-drop-output" class="output"></div>
</div>

<script>
(function() {
  const dropZone = document.getElementById('drop-zone');
  const fileInput = document.getElementById('file-input');
  const output = document.getElementById('drag-drop-output');
  
  // Prevent default drag behaviors
  ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
    dropZone.addEventListener(eventName, preventDefaults, false);
    document.body.addEventListener(eventName, preventDefaults, false);
  });
  
  function preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
  }
  
  // Highlight drop zone when item is dragged over it
  ['dragenter', 'dragover'].forEach(eventName => {
    dropZone.addEventListener(eventName, () => {
      dropZone.classList.add('drag-over');
    }, false);
  });
  
  ['dragleave', 'drop'].forEach(eventName => {
    dropZone.addEventListener(eventName, () => {
      dropZone.classList.remove('drag-over');
    }, false);
  });
  
  // Handle dropped files
  dropZone.addEventListener('drop', handleDrop, false);
  fileInput.addEventListener('change', handleFileSelect, false);
  
  function handleDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;
    handleFiles(files);
  }
  
  function handleFileSelect(e) {
    const files = e.target.files;
    handleFiles(files);
  }
  
  function handleFiles(files) {
    if (files.length === 0) return;
    
    const file = files[0];
    const formData = new FormData();
    formData.append('file', file);
    
    output.innerHTML = '<p style="color: #666;">Uploading...</p>';
    
    fetch('/cgi/drag-drop-upload', {
      method: 'POST',
      body: formData
    })
    .then(response => response.text())
    .then(html => {
      output.innerHTML = html;
    })
    .catch(error => {
      output.innerHTML = '<p class="error">Upload failed: ' + error.message + '</p>';
    });
  }
})();
</script>

## 3. File Information

Get detailed metadata about uploaded files:

<div class="demo-box">
<input type="text" id="file-info-input" placeholder="Enter filename" value="document.pdf" hx-get="/cgi/file-info" hx-vals='js:{name: document.getElementById("file-info-input").value}' hx-target="#file-info-output" hx-swap="innerHTML" hx-trigger="keyup[key=='Enter']" />
<button hx-get="/cgi/file-info" hx-vals='js:{name: document.getElementById("file-info-input").value}' hx-target="#file-info-output" hx-swap="innerHTML">
    Get File Info
</button>
<div id="file-info-output" class="output"></div>
</div>

## 4. File Picker API

Use the native browser file picker to select files:

<div class="demo-box">
<button id="file-picker-btn" class="primary">📂 Open File Picker</button>
<div id="file-picker-output" class="output"></div>
</div>

<script>
(function() {
  const btn = document.getElementById('file-picker-btn');
  const output = document.getElementById('file-picker-output');
  
  btn.addEventListener('click', async () => {
    try {
      // Create invisible file input
      const input = document.createElement('input');
      input.type = 'file';
      input.multiple = false;
      
      input.onchange = (e) => {
        const file = e.target.files[0];
        if (!file) return;
        
        output.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; margin-top: 1rem;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ File Selected</h4>
<p style="margin: 0.25rem 0;"><strong>Name:</strong> ${file.name}</p>
<p style="margin: 0.25rem 0;"><strong>Type:</strong> ${file.type || 'unknown'}</p>
<p style="margin: 0.25rem 0;"><strong>Size:</strong> ${(file.size / 1024).toFixed(2)} KB</p>
<p style="margin: 0.25rem 0;"><strong>Last Modified:</strong> ${new Date(file.lastModified).toLocaleString()}</p>
</div>
        `;
      };
      
      input.click();
    } catch (error) {
      output.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
})();
</script>

## 5. Blobs & Binary Data

Demonstrate working with binary data and Blob objects:

<div class="demo-box">
<button id="create-blob-btn">Create Text Blob</button>
<button id="create-binary-btn" style="margin-left: 10px;">Create Binary Blob</button>
<div id="blob-output" class="output"></div>
</div>

<script>
(function() {
  const textBtn = document.getElementById('create-blob-btn');
  const binaryBtn = document.getElementById('create-binary-btn');
  const output = document.getElementById('blob-output');
  
  textBtn.addEventListener('click', () => {
    const text = 'Hello from a Blob! This is binary data masquerading as text.';
    const blob = new Blob([text], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    
    output.innerHTML = `
<div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; margin-top: 1rem;">
<h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">📝 Text Blob Created</h4>
<p style="margin: 0.25rem 0;"><strong>Size:</strong> ${blob.size} bytes</p>
<p style="margin: 0.25rem 0;"><strong>Type:</strong> ${blob.type}</p>
<p style="margin: 0.25rem 0;"><strong>Content:</strong> "${text}"</p>
<a href="${url}" download="demo.txt" style="display: inline-block; margin-top: 0.5rem; padding: 0.5rem 1rem; background: #1976d2; color: white; border-radius: 4px; text-decoration: none;">⬇️ Download Blob</a>
</div>
    `;
  });
  
  binaryBtn.addEventListener('click', () => {
    // Create a small binary file (PNG image header)
    const header = new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10]);
    const blob = new Blob([header], { type: 'application/octet-stream' });
    const url = URL.createObjectURL(blob);
    
    output.innerHTML = `
<div style="background: #f3e5f5; padding: 1rem; border-radius: 4px; margin-top: 1rem;">
<h4 style="margin: 0 0 0.5rem 0; color: #6a1b9a;">🔢 Binary Blob Created</h4>
<p style="margin: 0.25rem 0;"><strong>Size:</strong> ${blob.size} bytes</p>
<p style="margin: 0.25rem 0;"><strong>Type:</strong> ${blob.type}</p>
<p style="margin: 0.25rem 0;"><strong>Data:</strong> PNG header bytes</p>
<p style="margin: 0.25rem 0; font-family: monospace; font-size: 0.9rem;">
          ${Array.from(header).map(b => b.toString(16).padStart(2, '0')).join(' ')}
</p>
<a href="${url}" download="binary.dat" style="display: inline-block; margin-top: 0.5rem; padding: 0.5rem 1rem; background: #7b1fa2; color: white; border-radius: 4px; text-decoration: none;">⬇️ Download Binary Data</a>
</div>
    `;
  });
})();
</script>

---

<div class="info-box">
<h3>🎯 Browser APIs Demonstrated:</h3>
<ul>
<li><strong>File API:</strong> Reading local files selected by users</li>
<li><strong>Drag and Drop API:</strong> Native browser drag-and-drop events</li>
<li><strong>Blob API:</strong> Creating and manipulating binary data</li>
<li><strong>URL.createObjectURL:</strong> Creating downloadable blob URLs</li>
<li><strong>FormData API:</strong> Uploading files via fetch/AJAX</li>
<li><strong>FileReader API:</strong> Reading file contents in various formats</li>
</ul>
  
<p style="margin-top: 1rem;"><strong>💡 Note:</strong> All file operations happen client-side in your browser. The CGI scripts demonstrate server-side file handling when files are uploaded.</p>
</div>

## 6. File System Access API (Advanced)

The File System Access API provides read/write access to files and directories on the user's device:

<div class="demo-box">
<h3>📁 File System Access API</h3>
  
<div style="background: #fff3cd; padding: 1rem; border-radius: 4px; border: 1px solid #ffc107; margin-bottom: 1rem;">
<p style="margin: 0; color: #856404;">
<strong>⚠️ Browser Support:</strong> This API is currently only supported in Chromium-based browsers (Chrome, Edge, Opera). It will not work in Firefox or Safari.
</p>
</div>
  
<h4>Open and Read File</h4>
<div style="margin-bottom: 1.5rem;">
<button id="fs-open-file">📂 Open File</button>
<div id="fs-file-output" class="output" style="margin-top: 0.5rem;"></div>
</div>
  
<h4>Save File</h4>
<div style="margin-bottom: 1.5rem;">
<textarea id="fs-text-content" rows="4" placeholder="Enter content to save..." style="width: 100%; padding: 0.5rem; border: 2px solid #ddd; border-radius: 4px; margin-bottom: 0.5rem;"></textarea>
<button id="fs-save-file">💾 Save As...</button>
<div id="fs-save-output" class="output" style="margin-top: 0.5rem;"></div>
</div>
  
<h4>Directory Picker</h4>
<div>
<button id="fs-open-dir">📁 Open Directory</button>
<div id="fs-dir-output" class="output" style="margin-top: 0.5rem;"></div>
</div>
</div>

<script>
(function() {
  const fileOutput = document.getElementById('fs-file-output');
  const saveOutput = document.getElementById('fs-save-output');
  const dirOutput = document.getElementById('fs-dir-output');
  const textContent = document.getElementById('fs-text-content');
  
  // Check if API is supported
  const isSupported = 'showOpenFilePicker' in window;
  
  if (!isSupported) {
    const warningHTML = `
<div style="background: #ffebee; padding: 1rem; border-radius: 4px; border: 1px solid #f44336;">
<h4 style="margin: 0 0 0.5rem 0; color: #c62828;">❌ File System Access API Not Supported</h4>
<p style="margin: 0.25rem 0;">This browser does not support the File System Access API.</p>
<p style="margin: 0.25rem 0; font-size: 0.9rem;">Try using Chrome, Edge, or another Chromium-based browser.</p>
</div>
    `;
    fileOutput.innerHTML = warningHTML;
    saveOutput.innerHTML = warningHTML;
    dirOutput.innerHTML = warningHTML;
  }
  
  // Open and read a file
  document.getElementById('fs-open-file').addEventListener('click', async () => {
    if (!isSupported) return;
    
    try {
      const [fileHandle] = await window.showOpenFilePicker({
        types: [
          {
            description: 'Text Files',
            accept: {
              'text/*': ['.txt', '.md', '.js', '.html', '.css', '.json']
            }
          },
          {
            description: 'All Files',
            accept: { '*/*': [] }
          }
        ],
        multiple: false
      });
      
      const file = await fileHandle.getFile();
      const contents = await file.text();
      
      fileOutput.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ File Opened</h4>
<p style="margin: 0.25rem 0;"><strong>Name:</strong> ${file.name}</p>
<p style="margin: 0.25rem 0;"><strong>Size:</strong> ${(file.size / 1024).toFixed(2)} KB</p>
<p style="margin: 0.25rem 0;"><strong>Type:</strong> ${file.type || 'unknown'}</p>
<p style="margin: 0.25rem 0;"><strong>Last Modified:</strong> ${new Date(file.lastModified).toLocaleString()}</p>
<details style="margin-top: 0.5rem;">
<summary style="cursor: pointer; color: #2e7d32;">Show file contents (first 500 chars)</summary>
<pre style="margin-top: 0.5rem; background: #fff; padding: 0.5rem; border-radius: 3px; overflow-x: auto; font-size: 0.85rem; max-height: 200px;">${contents.substring(0, 500)}${contents.length > 500 ? '...' : ''}</pre>
</details>
</div>
      `;
    } catch (error) {
      if (error.name === 'AbortError') {
        fileOutput.innerHTML = '<p style="color: #7f8c8d;">File selection cancelled</p>';
      } else {
        fileOutput.innerHTML = `<p class="error">Error: ${error.message}</p>`;
      }
    }
  });
  
  // Save a file
  document.getElementById('fs-save-file').addEventListener('click', async () => {
    if (!isSupported) return;
    
    const content = textContent.value;
    if (!content) {
      saveOutput.innerHTML = '<p class="error">Please enter some content to save</p>';
      return;
    }
    
    try {
      const fileHandle = await window.showSaveFilePicker({
        suggestedName: 'document.txt',
        types: [
          {
            description: 'Text Files',
            accept: { 'text/plain': ['.txt'] }
          },
          {
            description: 'Markdown Files',
            accept: { 'text/markdown': ['.md'] }
          }
        ]
      });
      
      const writable = await fileHandle.createWritable();
      await writable.write(content);
      await writable.close();
      
      saveOutput.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ File Saved</h4>
<p style="margin: 0.25rem 0;"><strong>Saved to:</strong> ${fileHandle.name}</p>
<p style="margin: 0.25rem 0;"><strong>Size:</strong> ${(content.length / 1024).toFixed(2)} KB</p>
</div>
      `;
    } catch (error) {
      if (error.name === 'AbortError') {
        saveOutput.innerHTML = '<p style="color: #7f8c8d;">Save cancelled</p>';
      } else {
        saveOutput.innerHTML = `<p class="error">Error: ${error.message}</p>`;
      }
    }
  });
  
  // Open a directory
  document.getElementById('fs-open-dir').addEventListener('click', async () => {
    if (!isSupported) return;
    
    try {
      const dirHandle = await window.showDirectoryPicker();
      
      const files = [];
      for await (const entry of dirHandle.values()) {
        files.push({
          name: entry.name,
          kind: entry.kind
        });
      }
      
      files.sort((a, b) => {
        if (a.kind !== b.kind) return a.kind === 'directory' ? -1 : 1;
        return a.name.localeCompare(b.name);
      });
      
      const fileList = files.map(f => {
        const icon = f.kind === 'directory' ? '📁' : '📄';
        return `<li>${icon} ${f.name} <span style="color: #666; font-size: 0.9rem;">(${f.kind})</span></li>`;
      }).join('');
      
      dirOutput.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ Directory Opened</h4>
<p style="margin: 0.25rem 0;"><strong>Directory:</strong> ${dirHandle.name}</p>
<p style="margin: 0.25rem 0;"><strong>Contents:</strong> ${files.length} items</p>
<details style="margin-top: 0.5rem;">
<summary style="cursor: pointer; color: #2e7d32;">Show directory contents</summary>
<ul style="margin-top: 0.5rem; padding-left: 1.5rem; max-height: 300px; overflow-y: auto;">
              ${fileList}
</ul>
</details>
</div>
      `;
    } catch (error) {
      if (error.name === 'AbortError') {
        dirOutput.innerHTML = '<p style="color: #7f8c8d;">Directory selection cancelled</p>';
      } else {
        dirOutput.innerHTML = `<p class="error">Error: ${error.message}</p>`;
      }
    }
  });
})();
</script>

<div class="info-box" style="margin-top: 2rem;">
<h3>🎯 File System Access API Features:</h3>
<ul>
<li><strong>showOpenFilePicker:</strong> User-authorized file selection with read access</li>
<li><strong>showSaveFilePicker:</strong> User-authorized file saving with write access</li>
<li><strong>showDirectoryPicker:</strong> Directory selection and enumeration</li>
<li><strong>File Handles:</strong> Persistent references to files for read/write</li>
</ul>
  
<p style="margin-top: 1rem;"><strong>⚠️ Security & Privacy:</strong></p>
<ul>
<li>User must explicitly select files/directories (no silent access)</li>
<li>Permissions must be re-requested for each session</li>
<li>Only works in secure contexts (HTTPS)</li>
<li>Limited to Chromium-based browsers currently</li>
</ul>
  
<p style="margin-top: 1rem;"><strong>💡 Use Cases:</strong></p>
<ul>
<li>Text editors and IDEs that work with local files</li>
<li>Image/video editors that need file system access</li>
<li>Project management tools working with local directories</li>
<li>Any app that benefits from seamless file system integration</li>
</ul>
</div>
