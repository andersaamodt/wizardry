<div class="pane-bar">
  <div class="pane-controls">
    <button class="pane-button" type="button" data-nav="back" aria-label="Go back" title="Go back">◀</button>
    <button class="pane-button" type="button" data-nav="forward" aria-label="Go forward" title="Go forward">▶</button>
  </div>
  <button class="theme-toggle" type="button" aria-label="Cycle theme" title="Cycle theme"></button>
</div>

<script>
(function() {
  const themeButton = document.querySelector('.theme-toggle');
  const themes = ['light', 'dark', 'wizard'];
  const storageKey = 'unix-settings-theme';
  const savedTheme = window.localStorage.getItem(storageKey) || 'wizard';
  document.documentElement.setAttribute('data-theme', savedTheme);
  if (themeButton) {
    themeButton.dataset.theme = savedTheme;
    themeButton.addEventListener('click', () => {
      const current = document.documentElement.getAttribute('data-theme') || 'wizard';
      const next = themes[(themes.indexOf(current) + 1) % themes.length];
      document.documentElement.setAttribute('data-theme', next);
      themeButton.dataset.theme = next;
      window.localStorage.setItem(storageKey, next);
    });
  }

  const navButtons = document.querySelectorAll('[data-nav]');
  navButtons.forEach(button => {
    button.addEventListener('click', () => {
      if (button.dataset.nav === 'back') {
        window.history.back();
      } else {
        window.history.forward();
      }
    });
  });

  const main = document.querySelector('main');
  const sizeKey = 'unix-settings-pane-size';
  document.body.classList.add('page-enter');
  if (main) {
    const stored = window.localStorage.getItem(sizeKey);
    if (stored) {
      try {
        const parsed = JSON.parse(stored);
        if (parsed.width && parsed.height) {
          main.style.width = parsed.width;
          main.style.height = parsed.height;
        }
      } catch (e) {
        window.localStorage.removeItem(sizeKey);
      }
    }
  }
  requestAnimationFrame(() => {
    document.body.classList.add('page-active');
    document.body.classList.remove('page-enter');
    if (main) {
      const targetWidth = `${main.scrollWidth}px`;
      const targetHeight = `${main.scrollHeight}px`;
      main.style.width = targetWidth;
      main.style.height = targetHeight;
      window.localStorage.setItem(sizeKey, JSON.stringify({
        width: targetWidth,
        height: targetHeight
      }));
    }
  });

  const links = document.querySelectorAll('a[href^="/pages/"]');
  links.forEach(link => {
    link.addEventListener('click', event => {
      if (!main) return;
      event.preventDefault();
      const target = link.getAttribute('href');
      const currentWidth = `${main.scrollWidth}px`;
      const currentHeight = `${main.scrollHeight}px`;
      main.style.width = currentWidth;
      main.style.height = currentHeight;
      window.localStorage.setItem(sizeKey, JSON.stringify({
        width: currentWidth,
        height: currentHeight
      }));
      document.body.classList.add('page-exit');
      document.body.classList.remove('page-active');
      window.dispatchEvent(new CustomEvent('unix-settings:navigate', { detail: { path: target } }));
      setTimeout(() => {
        window.location.href = target;
      }, 200);
    });
  });
})();
</script>
