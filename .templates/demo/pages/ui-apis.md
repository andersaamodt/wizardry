---
title: UI & Layout APIs
---

Explore browser APIs for advanced user interface features and layout detection.

## 1. Fullscreen API

Enter and exit fullscreen mode programmatically:

<div class="demo-box">
<h3>🖼️ Fullscreen API</h3>
  
<div id="fullscreen-container" style="padding: 2rem; border: 3px solid #2196f3; border-radius: 8px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-align: center;">
<h2 style="margin: 0 0 1rem 0;">Fullscreen Demo Container</h2>
<p style="margin: 0 0 1rem 0;">Click the button below to make this container fullscreen!</p>
    
<div style="display: flex; gap: 0.5rem; justify-content: center; flex-wrap: wrap;">
<button id="fullscreen-enter" style="padding: 0.75rem 1.5rem; font-size: 1rem; background: #4caf50; color: white; border: none; border-radius: 4px; cursor: pointer;">🖼️ Enter Fullscreen</button>
<button id="fullscreen-exit" style="padding: 0.75rem 1.5rem; font-size: 1rem; background: #f44336; color: white; border: none; border-radius: 4px; cursor: pointer;">❌ Exit Fullscreen</button>
<button id="fullscreen-toggle" style="padding: 0.75rem 1.5rem; font-size: 1rem; background: #ff9800; color: white; border: none; border-radius: 4px; cursor: pointer;">🔄 Toggle</button>
</div>
    
<p id="fullscreen-hint" style="margin: 1rem 0 0 0; font-size: 0.9rem; opacity: 0.9;">Press ESC to exit fullscreen</p>
</div>
  
<div id="fullscreen-output" class="output"></div>
</div>

<script>
(function() {
  const container = document.getElementById('fullscreen-container');
  const output = document.getElementById('fullscreen-output');
  
  function updateStatus() {
    const isFullscreen = document.fullscreenElement === container;
    
    if (isFullscreen) {
      output.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ Fullscreen Active</h4>
<p style="margin: 0;">Container is now fullscreen. Press ESC or click Exit to return.</p>
</div>
      `;
      container.style.padding = '4rem';
    } else {
      output.innerHTML = `
<div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3;">
<h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">ℹ️ Normal Mode</h4>
<p style="margin: 0;">Container is in normal mode. Click Enter Fullscreen to expand.</p>
</div>
      `;
      container.style.padding = '2rem';
    }
  }
  
  document.getElementById('fullscreen-enter').addEventListener('click', async () => {
    try {
      await container.requestFullscreen();
    } catch (error) {
      output.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
  
  document.getElementById('fullscreen-exit').addEventListener('click', async () => {
    try {
      if (document.fullscreenElement) {
        await document.exitFullscreen();
      }
    } catch (error) {
      output.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
  
  document.getElementById('fullscreen-toggle').addEventListener('click', async () => {
    try {
      if (document.fullscreenElement) {
        await document.exitFullscreen();
      } else {
        await container.requestFullscreen();
      }
    } catch (error) {
      output.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  });
  
  // Listen for fullscreen changes
  document.addEventListener('fullscreenchange', updateStatus);
  
  // Initial status
  updateStatus();
})();
</script>

## 2. Intersection Observer API

Detect when elements enter or leave the viewport:

<div class="demo-box">
<h3>👁️ Intersection Observer</h3>
  
<div style="margin-bottom: 1rem;">
<button id="io-start">👁️ Start Observing</button>
<button id="io-stop" style="margin-left: 0.5rem;">⏹️ Stop</button>
<button id="io-scroll" style="margin-left: 0.5rem;">⬇️ Scroll to Boxes</button>
</div>
  
<div id="io-output" class="output"></div>
  
<div id="io-container" style="margin-top: 1rem; max-height: 400px; overflow-y: auto; border: 2px solid #ddd; border-radius: 4px; padding: 1rem;">
<div style="height: 200px; background: #f5f5f5; padding: 1rem; margin-bottom: 1rem; border-radius: 4px;">
<p>Scroll down to see the observed boxes...</p>
</div>
    
<div class="observe-box" data-box="1" style="height: 150px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 1rem; margin-bottom: 1rem; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; font-weight: bold; opacity: 0.3; transition: opacity 0.5s, transform 0.5s; transform: scale(0.95);">
      Box 1
</div>
    
<div class="observe-box" data-box="2" style="height: 150px; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 1rem; margin-bottom: 1rem; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; font-weight: bold; opacity: 0.3; transition: opacity 0.5s, transform 0.5s; transform: scale(0.95);">
      Box 2
</div>
    
<div class="observe-box" data-box="3" style="height: 150px; background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); color: white; padding: 1rem; margin-bottom: 1rem; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; font-weight: bold; opacity: 0.3; transition: opacity 0.5s, transform 0.5s; transform: scale(0.95);">
      Box 3
</div>
    
<div class="observe-box" data-box="4" style="height: 150px; background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); color: white; padding: 1rem; margin-bottom: 1rem; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; font-weight: bold; opacity: 0.3; transition: opacity 0.5s, transform 0.5s; transform: scale(0.95);">
      Box 4
</div>
    
<div style="height: 200px; background: #f5f5f5; padding: 1rem; border-radius: 4px;">
<p>End of scrollable area</p>
</div>
</div>
</div>

<script>
(function() {
  const output = document.getElementById('io-output');
  const boxes = document.querySelectorAll('.observe-box');
  let observer = null;
  let visibleBoxes = new Set();
  
  function updateOutput() {
    const visible = Array.from(visibleBoxes).sort().join(', ');
    output.innerHTML = `
<div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; border: 1px solid #2196f3;">
<h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">👁️ Currently Visible</h4>
<p style="margin: 0;"><strong>Boxes in viewport:</strong> ${visible || 'None'}</p>
<p style="margin: 0.5rem 0 0 0; font-size: 0.9rem; color: #666;">Scroll the container to see boxes enter/exit the viewport</p>
</div>
    `;
  }
  
  document.getElementById('io-start').addEventListener('click', () => {
    if (observer) {
      output.innerHTML = '<p class="error">Already observing. Stop first.</p>';
      return;
    }
    
    observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        const boxNum = entry.target.dataset.box;
        
        if (entry.isIntersecting) {
          // Box entered viewport
          visibleBoxes.add(boxNum);
          entry.target.style.opacity = '1';
          entry.target.style.transform = 'scale(1)';
        } else {
          // Box left viewport
          visibleBoxes.delete(boxNum);
          entry.target.style.opacity = '0.3';
          entry.target.style.transform = 'scale(0.95)';
        }
        
        updateOutput();
      });
    }, {
      root: document.getElementById('io-container'),
      threshold: 0.5
    });
    
    boxes.forEach(box => observer.observe(box));
    
    output.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ Observer Active</h4>
<p style="margin: 0;">Scroll the container to see intersection detection in action!</p>
</div>
    `;
  });
  
  document.getElementById('io-stop').addEventListener('click', () => {
    if (observer) {
      observer.disconnect();
      observer = null;
      visibleBoxes.clear();
      
      // Reset all boxes
      boxes.forEach(box => {
        box.style.opacity = '0.3';
        box.style.transform = 'scale(0.95)';
      });
      
      output.innerHTML = '<p style="color: #7f8c8d;">⏹️ Observer stopped</p>';
    } else {
      output.innerHTML = '<p style="color: #7f8c8d;">Not currently observing</p>';
    }
  });
  
  document.getElementById('io-scroll').addEventListener('click', () => {
    document.getElementById('io-container').scrollTop = 250;
  });
})();
</script>

## 3. Advanced Drag & Drop API

Create sortable lists with drag and drop:

<div class="demo-box">
<h3>🔄 Drag & Drop - Sortable List</h3>
  
<div style="margin-bottom: 1rem;">
<button id="dnd-reset">🔄 Reset List</button>
<button id="dnd-add" style="margin-left: 0.5rem;">➕ Add Item</button>
</div>
  
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem;">
<div>
<h4>📋 Task List (drag to reorder)</h4>
<ul id="sortable-list" style="list-style: none; padding: 0; margin: 0;">
<li draggable="true" class="draggable-item" style="padding: 1rem; margin-bottom: 0.5rem; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 8px; cursor: move; user-select: none; transition: transform 0.2s, opacity 0.2s;">
          📌 Task 1: Review code
</li>
<li draggable="true" class="draggable-item" style="padding: 1rem; margin-bottom: 0.5rem; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; border-radius: 8px; cursor: move; user-select: none; transition: transform 0.2s, opacity 0.2s;">
          📌 Task 2: Write tests
</li>
<li draggable="true" class="draggable-item" style="padding: 1rem; margin-bottom: 0.5rem; background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); color: white; border-radius: 8px; cursor: move; user-select: none; transition: transform 0.2s, opacity 0.2s;">
          📌 Task 3: Deploy app
</li>
<li draggable="true" class="draggable-item" style="padding: 1rem; margin-bottom: 0.5rem; background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); color: white; border-radius: 8px; cursor: move; user-select: none; transition: transform 0.2s, opacity 0.2s;">
          📌 Task 4: Update docs
</li>
</ul>
</div>
    
<div>
<h4>📊 Order History</h4>
<div id="dnd-output" class="output" style="min-height: 200px;"></div>
</div>
</div>
</div>

<script>
(function() {
  const list = document.getElementById('sortable-list');
  const output = document.getElementById('dnd-output');
  let draggedItem = null;
  let itemCounter = 5;
  
  const gradients = [
    'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
    'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
    'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
    'linear-gradient(135deg, #fa709a 0%, #fee140 100%)',
    'linear-gradient(135deg, #30cfd0 0%, #330867 100%)'
  ];
  
  function updateOutput(action) {
    const items = Array.from(list.querySelectorAll('.draggable-item')).map((item, index) => 
      `${index + 1}. ${item.textContent.trim()}`
    ).join('<br>');
    
    output.innerHTML = `
<div style="background: #e8f5e9; padding: 1rem; border-radius: 4px; border: 1px solid #4caf50;">
<h4 style="margin: 0 0 0.5rem 0; color: #2e7d32;">✅ ${action}</h4>
<p style="margin: 0.5rem 0; font-weight: bold;">Current Order:</p>
<div style="margin: 0.5rem 0; font-family: monospace; font-size: 0.9rem;">
          ${items}
</div>
</div>
    `;
  }
  
  function initDragAndDrop() {
    const items = list.querySelectorAll('.draggable-item');
    
    items.forEach(item => {
      item.addEventListener('dragstart', (e) => {
        draggedItem = item;
        item.style.opacity = '0.5';
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/html', item.innerHTML);
      });
      
      item.addEventListener('dragend', () => {
        item.style.opacity = '1';
        draggedItem = null;
      });
      
      item.addEventListener('dragover', (e) => {
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
        
        if (item !== draggedItem) {
          const rect = item.getBoundingClientRect();
          const next = (e.clientY - rect.top) / (rect.bottom - rect.top) > 0.5;
          list.insertBefore(draggedItem, next ? item.nextSibling : item);
        }
      });
      
      item.addEventListener('drop', (e) => {
        e.preventDefault();
        updateOutput('Item Reordered');
      });
    });
  }
  
  document.getElementById('dnd-reset').addEventListener('click', () => {
    list.innerHTML = `
<li draggable="true" class="draggable-item" style="padding: 1rem; margin-bottom: 0.5rem; background: ${gradients[0]}; color: white; border-radius: 8px; cursor: move; user-select: none; transition: transform 0.2s, opacity 0.2s;">
        📌 Task 1: Review code
</li>
<li draggable="true" class="draggable-item" style="padding: 1rem; margin-bottom: 0.5rem; background: ${gradients[1]}; color: white; border-radius: 8px; cursor: move; user-select: none; transition: transform 0.2s, opacity 0.2s;">
        📌 Task 2: Write tests
</li>
<li draggable="true" class="draggable-item" style="padding: 1rem; margin-bottom: 0.5rem; background: ${gradients[2]}; color: white; border-radius: 8px; cursor: move; user-select: none; transition: transform 0.2s, opacity 0.2s;">
        📌 Task 3: Deploy app
</li>
<li draggable="true" class="draggable-item" style="padding: 1rem; margin-bottom: 0.5rem; background: ${gradients[3]}; color: white; border-radius: 8px; cursor: move; user-select: none; transition: transform 0.2s, opacity 0.2s;">
        📌 Task 4: Update docs
</li>
    `;
    itemCounter = 5;
    initDragAndDrop();
    updateOutput('List Reset');
  });
  
  document.getElementById('dnd-add').addEventListener('click', () => {
    const li = document.createElement('li');
    li.draggable = true;
    li.className = 'draggable-item';
    li.style.cssText = `padding: 1rem; margin-bottom: 0.5rem; background: ${gradients[itemCounter % gradients.length]}; color: white; border-radius: 8px; cursor: move; user-select: none; transition: transform 0.2s, opacity 0.2s;`;
    li.textContent = `📌 Task ${itemCounter}: New item`;
    list.appendChild(li);
    itemCounter++;
    initDragAndDrop();
    updateOutput('Item Added');
  });
  
  // Initialize
  initDragAndDrop();
  updateOutput('List Initialized');
})();
</script>

---

<div class="info-box">
<h3>🎯 UI & Layout APIs Demonstrated:</h3>
<ul>
<li><strong>Fullscreen API:</strong> Programmatically enter/exit fullscreen mode for immersive experiences</li>
<li><strong>Intersection Observer:</strong> Efficiently detect when elements enter/exit viewport for lazy loading, animations, and scroll effects</li>
<li><strong>Drag & Drop API:</strong> Advanced reorderable lists using native drag and drop events</li>
</ul>
  
<p style="margin-top: 1rem;"><strong>💡 Use Cases:</strong></p>
<ul>
<li><strong>Fullscreen:</strong> Video players, presentations, games, image viewers</li>
<li><strong>Intersection Observer:</strong> Lazy loading images, infinite scroll, animation triggers, analytics</li>
<li><strong>Drag & Drop:</strong> Task management, sortable lists, dashboard customization, file organization</li>
</ul>
  
<p style="margin-top: 1rem;"><strong>⚡ Performance Benefits:</strong></p>
<ul>
<li><strong>Intersection Observer:</strong> Much more efficient than scroll event listeners - doesn't block main thread</li>
<li><strong>Native Drag & Drop:</strong> Browser-optimized with built-in visual feedback and accessibility</li>
</ul>
</div>
