---
title: Forms & Input Demos
---

Explore browser input handling, including keyboard events, pointer events, forms, and focus management.

## 1. Keyboard Input & Events

Capture and display keyboard events in real-time:

<div class="demo-box">
<h3>⌨️ Keyboard Event Monitor</h3>
<input type="text" id="keyboard-input" placeholder="Type here to see keyboard events..." style="width: 100%; padding: 0.75rem; font-size: 1rem; border: 2px solid #ddd; border-radius: 4px;" />
<div id="keyboard-output" class="output" style="margin-top: 1rem; font-family: monospace; font-size: 0.9rem;"></div>
</div>

<script>
(function() {
  const input = document.getElementById('keyboard-input');
  const output = document.getElementById('keyboard-output');
  let eventLog = [];

  ['keydown', 'keypress', 'keyup'].forEach(eventType => {
    input.addEventListener(eventType, (e) => {
      const eventInfo = {
        type: eventType,
        key: e.key,
        code: e.code,
        keyCode: e.keyCode,
        charCode: e.charCode,
        shiftKey: e.shiftKey,
        ctrlKey: e.ctrlKey,
        altKey: e.altKey,
        metaKey: e.metaKey,
        repeat: e.repeat,
        timestamp: Date.now()
      };

      eventLog.unshift(eventInfo);
      if (eventLog.length > 10) eventLog = eventLog.slice(0, 10);

      const logHTML = eventLog.map((evt, idx) => {
        const modifiers = [
          evt.shiftKey ? 'Shift' : null,
          evt.ctrlKey ? 'Ctrl' : null,
          evt.altKey ? 'Alt' : null,
          evt.metaKey ? 'Meta' : null
        ].filter(Boolean).join('+');

        const color = evt.type === 'keydown' ? '#2980b9' : evt.type === 'keyup' ? '#27ae60' : '#e67e22';

        return `
<div style="padding: 0.5rem; margin: 0.25rem 0; background: ${idx === 0 ? '#fff3cd' : '#f8f9fa'}; border-left: 3px solid ${color}; border-radius: 3px;">
<strong style="color: ${color};">${evt.type}</strong>: 
            key="${evt.key}" code="${evt.code}"
            ${modifiers ? ` [${modifiers}]` : ''}
            ${evt.repeat ? ' [REPEAT]' : ''}
</div>
        `;
      }).join('');
      
      output.innerHTML = `<div><strong>Recent Events (newest first):</strong></div>${logHTML}`;
    });
  });
})();
</script>

## 2. Pointer Events - Unified Input

Pointer Events work with mouse, touch, and pen input uniformly:

<div class="demo-box">
<h3>🖱️ Pointer Event Tracker</h3>
<div id="pointer-target" style="border: 3px dashed #3498db; border-radius: 8px; padding: 3rem; text-align: center; background: #ecf0f1; cursor: crosshair; user-select: none;">
<p style="margin: 0; font-size: 1.2rem; color: #2c3e50;">Move pointer, click, or touch here</p>
</div>
<div id="pointer-output" class="output" style="margin-top: 1rem;"></div>
</div>

<script>
(function() {
  const target = document.getElementById('pointer-target');
  const output = document.getElementById('pointer-output');
  let pointerLog = [];

  ['pointerdown', 'pointerup', 'pointermove', 'pointerenter', 'pointerleave'].forEach(eventType => {
    target.addEventListener(eventType, (e) => {
      const info = {
        type: eventType,
        pointerType: e.pointerType,
        pointerId: e.pointerId,
        x: e.clientX,
        y: e.clientY,
        pressure: e.pressure,
        width: e.width,
        height: e.height,
        isPrimary: e.isPrimary,
        button: e.button,
        buttons: e.buttons
      };

      if (eventType !== 'pointermove') {
        pointerLog.unshift(info);
        if (pointerLog.length > 8) pointerLog = pointerLog.slice(0, 8);
      }

      const currentInfo = `
<div style="background: #e3f2fd; padding: 1rem; border-radius: 4px; margin-bottom: 1rem;">
<h4 style="margin: 0 0 0.5rem 0; color: #1565c0;">Current Pointer State</h4>
<p style="margin: 0.25rem 0;"><strong>Type:</strong> ${info.pointerType} (${info.isPrimary ? 'primary' : 'secondary'})</p>
<p style="margin: 0.25rem 0;"><strong>Position:</strong> (${info.x}, ${info.y})</p>
<p style="margin: 0.25rem 0;"><strong>Pressure:</strong> ${info.pressure.toFixed(2)}</p>
<p style="margin: 0.25rem 0;"><strong>Size:</strong> ${info.width}x${info.height}</p>
</div>
      `;
      
      const logHTML = pointerLog.map((evt, idx) => {
        const colors = {
          pointerdown: '#27ae60',
          pointerup: '#e74c3c',
          pointerenter: '#3498db',
          pointerleave: '#95a5a6'
        };
        const color = colors[evt.type] || '#7f8c8d';
        
        return `
<div style="padding: 0.5rem; margin: 0.25rem 0; background: ${idx === 0 ? '#fff3cd' : '#f8f9fa'}; border-left: 3px solid ${color}; border-radius: 3px; font-size: 0.9rem;">
<strong style="color: ${color};">${evt.type}</strong>: 
            ${evt.pointerType} at (${evt.x}, ${evt.y})
            ${evt.type.includes('down') || evt.type.includes('up') ? ` button=${evt.button}` : ''}
</div>
        `;
      }).join('');
      
      output.innerHTML = currentInfo + (logHTML ? `<div><strong>Event Log:</strong></div>${logHTML}` : '');
    });
  });
})();
</script>

## 3. Native Form Controls

Demonstrate all native HTML form input types:

<div class="demo-box">
<h3>📝 Form Control Showcase</h3>
<form id="form-demo" style="display: grid; gap: 1rem;">

<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: center;">
<label for="input-text"><strong>Text:</strong></label>
<input type="text" id="input-text" placeholder="Enter text" />
</div>
    
<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: center;">
<label for="input-email"><strong>Email:</strong></label>
<input type="email" id="input-email" placeholder="user@example.com" />
</div>
    
<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: center;">
<label for="input-number"><strong>Number:</strong></label>
<input type="number" id="input-number" min="0" max="100" value="50" />
</div>
    
<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: center;">
<label for="input-range"><strong>Range:</strong></label>
<div style="display: flex; gap: 0.5rem; align-items: center;">
<input type="range" id="input-range" min="0" max="100" value="50" style="flex: 1;" />
<span id="range-value">50</span>
</div>
</div>
    
<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: center;">
<label for="input-date"><strong>Date:</strong></label>
<input type="date" id="input-date" />
</div>
    
<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: center;">
<label for="input-time"><strong>Time:</strong></label>
<input type="time" id="input-time" />
</div>
    
<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: center;">
<label for="input-color"><strong>Color:</strong></label>
<input type="color" id="input-color" value="#3498db" />
</div>
    
<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: start;">
<label><strong>Checkboxes:</strong></label>
<div>
<label style="display: block; margin: 0.25rem 0;"><input type="checkbox" id="check1" /> Option 1</label>
<label style="display: block; margin: 0.25rem 0;"><input type="checkbox" id="check2" /> Option 2</label>
<label style="display: block; margin: 0.25rem 0;"><input type="checkbox" id="check3" checked /> Option 3</label>
</div>
</div>
    
<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: start;">
<label><strong>Radio Buttons:</strong></label>
<div>
<label style="display: block; margin: 0.25rem 0;"><input type="radio" name="radio-group" value="a" checked /> Choice A</label>
<label style="display: block; margin: 0.25rem 0;"><input type="radio" name="radio-group" value="b" /> Choice B</label>
<label style="display: block; margin: 0.25rem 0;"><input type="radio" name="radio-group" value="c" /> Choice C</label>
</div>
</div>
    
<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: center;">
<label for="input-select"><strong>Select:</strong></label>
<select id="input-select">
<option value="">-- Choose --</option>
<option value="fire">🔥 Fire</option>
<option value="water">💧 Water</option>
<option value="earth">🌍 Earth</option>
<option value="air">💨 Air</option>
</select>
</div>
    
<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: start;">
<label for="input-textarea"><strong>Textarea:</strong></label>
<textarea id="input-textarea" rows="3" placeholder="Enter multiple lines..."></textarea>
</div>
    
<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: center;">
<label for="input-file"><strong>File:</strong></label>
<input type="file" id="input-file" />
</div>
    
<div style="display: grid; grid-template-columns: 150px 1fr; gap: 0.5rem; align-items: center;">
<div></div>
<button type="submit" style="padding: 0.75rem 1.5rem; background: #27ae60; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 1rem;">Submit Form</button>
</div>
</form>
  
<div id="form-output" class="output" style="margin-top: 1rem;"></div>
</div>

<script>
(function() {
  const form = document.getElementById('form-demo');
  const output = document.getElementById('form-output');
  const rangeInput = document.getElementById('input-range');
  const rangeValue = document.getElementById('range-value');

  // Update range display
  rangeInput.addEventListener('input', () => {
    rangeValue.textContent = rangeInput.value;
  });

  form.addEventListener('submit', (e) => {
    e.preventDefault();

    const formData = new FormData(form);
    const data = {
      text: document.getElementById('input-text').value,
      email: document.getElementById('input-email').value,
      number: document.getElementById('input-number').value,
      range: document.getElementById('input-range').value,
      date: document.getElementById('input-date').value,
      time: document.getElementById('input-time').value,
      color: document.getElementById('input-color').value,
      checkboxes: [
        document.getElementById('check1').checked ? 'Option 1' : null,
        document.getElementById('check2').checked ? 'Option 2' : null,
        document.getElementById('check3').checked ? 'Option 3' : null
      ].filter(Boolean),
      radio: formData.get('radio-group'),
      select: document.getElementById('input-select').value,
      textarea: document.getElementById('input-textarea').value,
      file: document.getElementById('input-file').files[0]?.name || 'None'
    };

    output.innerHTML = `
<div style="background: #d4edda; padding: 1rem; border-radius: 4px; border: 1px solid #c3e6cb;">
<h4 style="margin: 0 0 0.5rem 0; color: #155724;">✅ Form Submitted</h4>
<pre style="background: #fff; padding: 1rem; border-radius: 4px; overflow-x: auto; margin: 0;">${JSON.stringify(data, null, 2)}</pre>
</div>
    `;
  });
})();
</script>

## 4. Focus Management

Programmatically control focus and tab order:

<div class="demo-box">
<h3>🎯 Focus Control</h3>
<div style="display: flex; gap: 1rem; margin-bottom: 1rem;">
<input type="text" id="focus-input-1" placeholder="Input 1" tabindex="1" style="flex: 1;" />
<input type="text" id="focus-input-2" placeholder="Input 2" tabindex="2" style="flex: 1;" />
<input type="text" id="focus-input-3" placeholder="Input 3" tabindex="3" style="flex: 1;" />
</div>
  
<div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
<button id="focus-btn-1">Focus Input 1</button>
<button id="focus-btn-2">Focus Input 2</button>
<button id="focus-btn-3">Focus Input 3</button>
<button id="focus-cycle">Cycle Focus</button>
<button id="focus-blur">Blur All</button>
</div>
  
<div id="focus-output" class="output" style="margin-top: 1rem;"></div>
</div>

<script>
(function() {
  const inputs = [
    document.getElementById('focus-input-1'),
    document.getElementById('focus-input-2'),
    document.getElementById('focus-input-3')
  ];
  const output = document.getElementById('focus-output');
  let currentFocus = 0;

  // Track focus events
  inputs.forEach((input, idx) => {
    input.addEventListener('focus', () => {
output.innerHTML = `<p style="color: #2980b9;">🎯 Input ${idx + 1} gained focus</p>`;
    });

    input.addEventListener('blur', () => {
output.innerHTML = `<p style="color: #95a5a6;">⭕ Input ${idx + 1} lost focus</p>`;
    });
  });

  document.getElementById('focus-btn-1').addEventListener('click', () => inputs[0].focus());
  document.getElementById('focus-btn-2').addEventListener('click', () => inputs[1].focus());
  document.getElementById('focus-btn-3').addEventListener('click', () => inputs[2].focus());

  document.getElementById('focus-cycle').addEventListener('click', () => {
    currentFocus = (currentFocus + 1) % inputs.length;
    inputs[currentFocus].focus();
  });

  document.getElementById('focus-blur').addEventListener('click', () => {
    document.activeElement.blur();
output.innerHTML = '<p style="color: #7f8c8d;">All inputs blurred</p>';
  });
})();
</script>

## 5. Clipboard API

Read from and write to the system clipboard:

<div class="demo-box">
<h3>📋 Clipboard Operations</h3>

<div style="margin-bottom: 1rem;">
<textarea id="clipboard-text" rows="3" placeholder="Enter text to copy..." style="width: 100%; padding: 0.5rem; border: 2px solid #ddd; border-radius: 4px;"></textarea>
</div>
  
<div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
<button id="clipboard-copy">📄 Copy to Clipboard</button>
<button id="clipboard-paste">📋 Paste from Clipboard</button>
<button id="clipboard-clear">🧹 Clear</button>
</div>
  
<div id="clipboard-output" class="output" style="margin-top: 1rem;"></div>
</div>

<script>
(function() {
  const textarea = document.getElementById('clipboard-text');
  const output = document.getElementById('clipboard-output');

  document.getElementById('clipboard-copy').addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(textarea.value);
output.innerHTML = `<p style="color: #27ae60;">✅ Copied to clipboard: "${textarea.value}"</p>`;
    } catch (err) {
output.innerHTML = `<p class="error">Failed to copy: ${err.message}</p>`;
    }
  });

  document.getElementById('clipboard-paste').addEventListener('click', async () => {
    try {
      const text = await navigator.clipboard.readText();
      textarea.value = text;
output.innerHTML = `<p style="color: #2980b9;">📋 Pasted from clipboard: "${text}"</p>`;
    } catch (err) {
output.innerHTML = `<p class="error">Failed to paste: ${err.message}. You may need to grant clipboard permissions.</p>`;
    }
  });

  document.getElementById('clipboard-clear').addEventListener('click', () => {
    textarea.value = '';
output.innerHTML = '<p style="color: #7f8c8d;">🧹 Cleared text area</p>';
  });
})();
</script>

---

<div class="info-box">
<h3>🎯 Input APIs Demonstrated:</h3>
<ul>
<li><strong>Keyboard Events:</strong> keydown, keypress, keyup with modifier detection</li>
<li><strong>Pointer Events:</strong> Unified mouse/touch/pen input handling</li>
<li><strong>Form Controls:</strong> All native HTML5 input types</li>
<li><strong>Focus Management:</strong> Programmatic focus control and tab order</li>
<li><strong>Clipboard API:</strong> Async read/write system clipboard</li>
</ul>

<p style="margin-top: 1rem;"><strong>💡 Key Benefits:</strong></p>
<ul>
<li>Pointer Events work consistently across mouse, touch, and pen</li>
<li>Native form controls are accessible and work with screen readers</li>
<li>Clipboard API provides secure, permission-based clipboard access</li>
<li>Focus management enables keyboard navigation and accessibility</li>
</ul>
</div>
