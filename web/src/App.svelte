<script>
  import { onMount } from 'svelte';
  import { store } from './notifications.svelte.js';
  import { ICON_PATHS, CLOSE_PATH } from './icons.js';
  import Editor from './Editor.svelte';

  let editorProps = $state(null);

  // Derived container position styles
  let containerStyle = $derived.by(() => {
    const { x, y } = store.position;
    let styles = [];

    if (x <= 15)      styles.push('left:1vw');
    else if (x >= 85) styles.push('right:1vw');
    else              styles.push(`left:${x}vw`, 'transform:translateX(-50%)');

    if (y <= 15)      styles.push('top:1vh');
    else if (y >= 85) styles.push('bottom:1vh');
    else              styles.push(`top:${y}vh`);

    return styles.join(';');
  });

  let flexDir = $derived(store.position.y >= 85 ? 'column-reverse' : 'column');

  // Hoisted so both onMount and template can call it
  function closeEditor() {
    editorProps = null;
    postNui('closeEditor', {});
  }

  function saveEditor(settings) {
    store.applyPosition(settings.x, settings.y);
    store.applyScale(settings.size / 100);
    store.applyStyle(settings.style);
    store.soundOn  = settings.sound;
    store.soundVol = settings.volume / 100;
    postNui('saveSettings', settings);
    editorProps = null;
  }

  // postNui needs to be accessible outside onMount — store the ref
  let postNui = (endpoint, data) => {
    fetch('https://lime_notify/' + endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    }).catch(() => {});
  };

  onMount(() => {
    store.loadSound();

    // NUI ready handshake — keeps pinging until the client acks with a message
    let nuiReady = false;
    function signalReady() { postNui('nuiReady', {}); }
    const readyTimer = setInterval(() => {
      if (!nuiReady) signalReady();
    }, 500);
    signalReady();

    function handleMessage(e) {
      const d = e.data;
      if (!d?.action) return;

      nuiReady = true; // stop the retry loop, don't clearInterval so it keeps working

      switch (d.action) {
        case 'notify':
          store.showNotification(d.type, d.title, d.message, d.duration, d.position, d.sound, d.volume, d.style);
          break;

        case 'openEditor':
          editorProps = {
            x: d.x ?? 95, y: d.y ?? 5,
            menuX: d.menuX, menuY: d.menuY,
            sound: d.sound, volume: d.volume, size: d.size,
            style: d.style, allowStylePicker: d.allowStyle !== false,
          };
          // Sync store state so live notifications match current settings
          if (d.sound  !== undefined) store.soundOn  = d.sound;
          if (d.volume !== undefined) store.soundVol = d.volume / 100;
          if (d.size   !== undefined) store.applyScale(d.size / 100);
          if (d.style  !== undefined) store.applyStyle(d.style);
          break;

        case 'updateSettings':
          if (d.sound  !== undefined) store.soundOn  = d.sound;
          if (d.volume !== undefined) store.soundVol = d.volume / 100;
          if (d.size   !== undefined) store.applyScale(d.size / 100);
          if (d.style  !== undefined) store.applyStyle(d.style);
          break;

        case 'ping':
          signalReady();
          break;
      }
    }

    window.addEventListener('message', handleMessage);

    function onKeydown(e) {
      if (e.key === 'Escape' && editorProps) closeEditor();
    }
    window.addEventListener('keydown', onKeydown);

    return () => {
      clearInterval(readyTimer);
      window.removeEventListener('message', handleMessage);
      window.removeEventListener('keydown', onKeydown);
    };
  });
</script>

<!-- Notification container -->
<div
  class="notification-container s-{store.notifStyle}"
  style="--scale:{store.notifScale};{containerStyle};flex-direction:{flexDir}"
  id="nc"
>
  {#each store.notifications as notif (notif.id)}
    {@const iconPath = ICON_PATHS[notif.type] || ICON_PATHS.info}
    {@const needsWrap = notif.style !== store.notifStyle}

    {#if needsWrap}
      <div class="notification-container s-{notif.style}" style="position:static;display:block;max-width:none;gap:0;">
        <div
          class="notification n-{notif.type}"
          class:removing={notif.removing}
          style="--dur:{notif.duration}ms"
        >
          <div class="n-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                 stroke-linecap="round" stroke-linejoin="round">
              {@html iconPath}
            </svg>
          </div>
          <div class="n-body">
            <div class="n-title">{notif.title}</div>
            {#if notif.message}<div class="n-msg">{notif.message}</div>{/if}
          </div>
          <button class="n-close" aria-label="Dismiss" onclick={() => store.dismiss(notif.id)}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"
                 stroke-linecap="round" stroke-linejoin="round">
              {@html CLOSE_PATH}
            </svg>
          </button>
        </div>
      </div>
    {:else}
      <div
        class="notification n-{notif.type}"
        class:removing={notif.removing}
        style="--dur:{notif.duration}ms"
      >
        <div class="n-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
               stroke-linecap="round" stroke-linejoin="round">
            {@html iconPath}
          </svg>
        </div>
        <div class="n-body">
          <div class="n-title">{notif.title}</div>
          {#if notif.message}<div class="n-msg">{notif.message}</div>{/if}
        </div>
        <button class="n-close" aria-label="Dismiss" onclick={() => store.dismiss(notif.id)}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"
               stroke-linecap="round" stroke-linejoin="round">
            {@html CLOSE_PATH}
          </svg>
        </button>
      </div>
    {/if}
  {/each}
</div>

<!-- Editor (conditional) -->
{#if editorProps}
  <Editor
    x={editorProps.x}
    y={editorProps.y}
    menuX={editorProps.menuX}
    menuY={editorProps.menuY}
    allowStylePicker={editorProps.allowStylePicker}
    onSave={saveEditor}
    onClose={closeEditor}
  />
{/if}

<style>
  /* ─── CONTAINER ─────────────────────────────────────── */
  :global(.notification-container) {
    position: fixed;
    z-index: 9999;
    display: flex;
    flex-direction: column;
    gap: calc(8px * var(--scale, 1));
    max-width: calc(360px * var(--scale, 1));
    pointer-events: none;
  }

  /* ════ STYLE: DEFAULT ════ */
  :global(.s-default .notification) {
    border-radius: calc(6px * var(--scale, 1));
    padding: calc(10px * var(--scale, 1)) calc(14px * var(--scale, 1)) calc(10px * var(--scale, 1)) calc(10px * var(--scale, 1));
    border: 1px solid rgba(255,255,255,0.07);
    border-left: calc(3px * var(--scale, 1)) solid currentColor;
    box-shadow: 0 4px 20px -2px rgba(0,0,0,0.7);
    display: flex; align-items: center;
    gap: calc(10px * var(--scale, 1));
    position: relative; overflow: hidden;
    min-width: calc(240px * var(--scale, 1));
    max-width: calc(320px * var(--scale, 1));
    pointer-events: auto;
    animation: slideIn 0.28s cubic-bezier(0.22,1,0.36,1) both;
    will-change: transform, opacity;
  }
  :global(.s-default .notification::after) {
    content:''; position:absolute; bottom:0; left:0;
    height: calc(2px * var(--scale, 1));
    background: currentColor; opacity:0.35;
    animation: progressShrink var(--dur) linear forwards;
    will-change: width;
  }
  :global(.s-default .n-success) { color:#4ade80; background:#111a15; border-color:rgba(74,222,128,0.3); }
  :global(.s-default .n-success .n-icon) { background:#1a3325; border-color:rgba(74,222,128,0.3); }
  :global(.s-default .n-error)   { color:#f87171; background:#1a1113; border-color:rgba(248,113,113,0.3); }
  :global(.s-default .n-error   .n-icon) { background:#331a1c; border-color:rgba(248,113,113,0.3); }
  :global(.s-default .n-warning, .s-default .n-warn) { color:#fbbf24; background:#1a1710; border-color:rgba(251,191,36,0.3); }
  :global(.s-default .n-warning .n-icon, .s-default .n-warn .n-icon) { background:#332a0f; border-color:rgba(251,191,36,0.3); }
  :global(.s-default .n-info)    { color:#60a5fa; background:#111520; border-color:rgba(96,165,250,0.3); }
  :global(.s-default .n-info    .n-icon) { background:#172035; border-color:rgba(96,165,250,0.3); }
  :global(.s-default .n-claimed) { color:#f5c842; background:#1a1810; border-color:rgba(245,200,66,0.3); }
  :global(.s-default .n-claimed .n-icon) { background:#332e0f; border-color:rgba(245,200,66,0.3); }

  /* ════ STYLE: MINIMAL ════ */
  :global(.s-minimal .notification) {
    border-radius: calc(100px * var(--scale, 1));
    padding: calc(9px * var(--scale, 1)) calc(18px * var(--scale, 1)) calc(9px * var(--scale, 1)) calc(12px * var(--scale, 1));
    background: rgba(18,18,22,0.95);
    border: 1px solid rgba(255,255,255,0.09);
    box-shadow: 0 2px 16px -2px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.04);
    display:flex; align-items:center;
    gap: calc(9px * var(--scale, 1));
    position:relative; overflow:hidden;
    min-width: calc(200px * var(--scale, 1));
    max-width: calc(320px * var(--scale, 1));
    pointer-events: auto;
    animation: slideInLeft 0.3s cubic-bezier(0.22,1,0.36,1) both;
  }
  :global(.s-minimal .notification::after) {
    content:''; position:absolute; bottom:0; left:0;
    height: calc(1px * var(--scale, 1));
    background: currentColor; opacity:0.4;
    animation: progressShrink var(--dur) linear forwards;
  }
  :global(.s-minimal .n-icon)  { background:transparent !important; border:none !important; }
  :global(.s-minimal .n-title) { letter-spacing:0.02em; text-transform:none; font-size:calc(12.5px * var(--scale,1)); }
  :global(.s-minimal .n-success) { color:#4ade80; }
  :global(.s-minimal .n-error)   { color:#f87171; }
  :global(.s-minimal .n-warning, .s-minimal .n-warn) { color:#fbbf24; }
  :global(.s-minimal .n-info)    { color:#60a5fa; }
  :global(.s-minimal .n-claimed) { color:#f5c842; }

  /* ════ STYLE: GLASS ════ */
  :global(.s-glass .notification) {
    border-radius: calc(12px * var(--scale, 1));
    padding: calc(12px * var(--scale, 1)) calc(16px * var(--scale, 1)) calc(12px * var(--scale, 1)) calc(12px * var(--scale, 1));
    background: rgba(20,22,30,0.88);
    border: 1px solid rgba(255,255,255,0.13);
    display:flex; align-items:center;
    gap: calc(12px * var(--scale, 1));
    position:relative; overflow:hidden;
    min-width: calc(240px * var(--scale, 1));
    max-width: calc(330px * var(--scale, 1));
    pointer-events: auto;
    animation: glassIn 0.35s cubic-bezier(0.22,1,0.36,1) both;
  }
  :global(.s-glass .notification::before) {
    content:''; position:absolute; inset:0;
    background: radial-gradient(ellipse 80% 60% at 20% 50%, var(--glow-color, rgba(96,165,250,0.12)) 0%, transparent 70%);
    pointer-events: none;
  }
  :global(.s-glass .notification::after) {
    content:''; position:absolute; bottom:0; left:0;
    height: calc(2px * var(--scale, 1));
    background: linear-gradient(90deg, currentColor, transparent); opacity:0.6;
    animation: progressShrink var(--dur) linear forwards;
  }
  :global(.s-glass .n-icon)  { background:rgba(255,255,255,0.06) !important; border-color:rgba(255,255,255,0.1) !important; }
  :global(.s-glass .n-title) { color:rgba(255,255,255,0.98); }
  :global(.s-glass .n-msg)   { color:rgba(255,255,255,0.65); }
  :global(.s-glass .n-success) { color:#6ee7a0; --glow-color:rgba(74,222,128,0.15); }
  :global(.s-glass .n-error)   { color:#fca5a5; --glow-color:rgba(248,113,113,0.15); }
  :global(.s-glass .n-warning, .s-glass .n-warn) { color:#fcd34d; --glow-color:rgba(251,191,36,0.15); }
  :global(.s-glass .n-info)    { color:#93c5fd; --glow-color:rgba(96,165,250,0.15); }
  :global(.s-glass .n-claimed) { color:#fde68a; --glow-color:rgba(245,200,66,0.15); }

  /* ════ STYLE: TOAST ════ */
  :global(.s-toast .notification) {
    border-radius: calc(4px * var(--scale, 1));
    padding: calc(12px * var(--scale, 1)) calc(16px * var(--scale, 1));
    background: #18181b;
    border: 1px solid rgba(255,255,255,0.06);
    border-top: calc(2px * var(--scale, 1)) solid currentColor;
    box-shadow: 0 8px 32px -4px rgba(0,0,0,0.8), 0 1px 0 rgba(255,255,255,0.03) inset;
    display:flex; align-items:center;
    gap: calc(12px * var(--scale, 1));
    position:relative; overflow:hidden;
    min-width: calc(280px * var(--scale, 1));
    max-width: calc(360px * var(--scale, 1));
    pointer-events: auto;
    animation: toastUp 0.3s cubic-bezier(0.22,1,0.36,1) both;
  }
  :global(.s-toast .notification::after) {
    content:''; position:absolute; bottom:0; left:0;
    height: calc(2px * var(--scale, 1));
    background: rgba(255,255,255,0.07);
    animation: progressShrink var(--dur) linear forwards;
  }
  :global(.s-toast .n-icon)  { background:rgba(255,255,255,0.04) !important; border-color:rgba(255,255,255,0.06) !important; }
  :global(.s-toast .n-title) { font-size:calc(11.5px * var(--scale,1)); }
  :global(.s-toast .n-success) { color:#4ade80; }
  :global(.s-toast .n-error)   { color:#f87171; }
  :global(.s-toast .n-warning, .s-toast .n-warn) { color:#fbbf24; }
  :global(.s-toast .n-info)    { color:#60a5fa; }
  :global(.s-toast .n-claimed) { color:#f5c842; }

  /* ════ STYLE: BOLD ════ */
  :global(.s-bold .notification) {
    border-radius: calc(8px * var(--scale, 1));
    padding: calc(11px * var(--scale, 1)) calc(15px * var(--scale, 1)) calc(11px * var(--scale, 1)) calc(11px * var(--scale, 1));
    border: none;
    box-shadow: 0 4px 24px -4px rgba(0,0,0,0.5);
    display:flex; align-items:center;
    gap: calc(10px * var(--scale, 1));
    position:relative; overflow:hidden;
    min-width: calc(240px * var(--scale, 1));
    max-width: calc(320px * var(--scale, 1));
    pointer-events: auto;
    animation: slideIn 0.3s cubic-bezier(0.22,1,0.36,1) both;
  }
  :global(.s-bold .notification::after) {
    content:''; position:absolute; bottom:0; left:0;
    height: calc(3px * var(--scale, 1));
    background: rgba(0,0,0,0.25);
    animation: progressShrink var(--dur) linear forwards;
  }
  :global(.s-bold .n-icon)  { background:rgba(0,0,0,0.15) !important; border:1px solid rgba(0,0,0,0.15) !important; }
  :global(.s-bold .n-title) { color:rgba(0,0,0,0.9) !important; }
  :global(.s-bold .n-msg)   { color:rgba(0,0,0,0.65) !important; }
  :global(.s-bold .n-close) { color:rgba(0,0,0,0.4) !important; }
  :global(.s-bold .n-close:hover) { background:rgba(0,0,0,0.1) !important; color:rgba(0,0,0,0.7) !important; }
  :global(.s-bold .n-success) { color:#4ade80; background:#4ade80; }
  :global(.s-bold .n-error)   { color:#f87171; background:#f87171; }
  :global(.s-bold .n-warning, .s-bold .n-warn) { color:#fbbf24; background:#fbbf24; }
  :global(.s-bold .n-info)    { color:#60a5fa; background:#60a5fa; }
  :global(.s-bold .n-claimed) { color:#f5c842; background:#f5c842; }

  /* ════ STYLE: RETRO ════ */
  :global(.s-retro .notification) {
    border-radius: 0;
    padding: calc(8px * var(--scale, 1)) calc(14px * var(--scale, 1));
    background: #0d0d0d;
    border: calc(1px * var(--scale, 1)) solid currentColor;
    box-shadow: calc(3px * var(--scale,1)) calc(3px * var(--scale,1)) 0 currentColor;
    display:flex; align-items:center;
    gap: calc(10px * var(--scale, 1));
    position:relative; overflow:hidden;
    min-width: calc(240px * var(--scale, 1));
    max-width: calc(340px * var(--scale, 1));
    pointer-events: auto;
    animation: retroIn 0.15s steps(4) both;
    font-family: 'Courier New', Courier, monospace;
  }
  :global(.s-retro .notification::after) {
    content:''; position:absolute; bottom:0; left:0;
    height: calc(2px * var(--scale, 1));
    background: currentColor; opacity:0.5;
    animation: progressShrink var(--dur) linear forwards;
  }
  :global(.s-retro .n-icon)  { background:transparent !important; border:calc(1px * var(--scale,1)) solid currentColor !important; border-radius:0 !important; }
  :global(.s-retro .n-title) { font-family:'Courier New',Courier,monospace; font-size:calc(10px * var(--scale,1)); text-transform:uppercase; letter-spacing:0.15em; color:currentColor !important; }
  :global(.s-retro .n-msg)   { font-family:'Courier New',Courier,monospace; font-size:calc(11px * var(--scale,1)); color:rgba(255,255,255,0.6) !important; }
  :global(.s-retro .n-success) { color:#00ff7f; }
  :global(.s-retro .n-error)   { color:#ff4444; }
  :global(.s-retro .n-warning, .s-retro .n-warn) { color:#ffcc00; }
  :global(.s-retro .n-info)    { color:#00cfff; }
  :global(.s-retro .n-claimed) { color:#ffaa00; }

  /* ─── SHARED INTERNALS ──────────────────────────────── */
  :global(.n-icon) {
    flex-shrink: 0;
    width: calc(36px * var(--scale, 1));
    height: calc(36px * var(--scale, 1));
    display:flex; align-items:center; justify-content:center;
    border-radius: calc(5px * var(--scale, 1));
    background: rgba(255,255,255,0.05);
    border: 1px solid rgba(255,255,255,0.08);
  }
  :global(.n-icon svg) {
    width: calc(18px * var(--scale, 1));
    height: calc(18px * var(--scale, 1));
  }
  :global(.n-body) { flex:1; min-width:0; }
  :global(.n-title) {
    font-weight:700;
    font-size: calc(11px * var(--scale, 1));
    color: rgba(255,255,255,0.95);
    letter-spacing:0.07em; text-transform:uppercase;
    margin-bottom: calc(2px * var(--scale, 1));
    white-space:nowrap; overflow:hidden; text-overflow:ellipsis;
  }
  :global(.n-msg) {
    font-size: calc(12px * var(--scale, 1));
    color: rgba(255,255,255,0.55);
    line-height: 1.4;
  }
  :global(.n-close) {
    width: calc(20px * var(--scale, 1));
    height: calc(20px * var(--scale, 1));
    border:none; background:transparent;
    border-radius: calc(4px * var(--scale, 1));
    cursor:pointer; color:rgba(255,255,255,0.2);
    flex-shrink:0; display:flex; align-items:center; justify-content:center;
    transition: background 0.15s, color 0.15s;
  }
  :global(.n-close svg) { width:calc(12px * var(--scale,1)); height:calc(12px * var(--scale,1)); }
  :global(.n-close:hover) { background:rgba(255,255,255,0.08); color:rgba(255,255,255,0.5); }

  /* ─── ANIMATIONS ────────────────────────────────────── */
  @keyframes -global-slideIn {
    from { transform: translate3d(40px,0,0); opacity:0; }
    to   { transform: translate3d(0,0,0);    opacity:1; }
  }
  @keyframes -global-slideInLeft {
    from { transform: translate3d(-30px,0,0) scale(0.95); opacity:0; }
    to   { transform: translate3d(0,0,0) scale(1); opacity:1; }
  }
  @keyframes -global-glassIn {
    from { transform: translate3d(0,-12px,0) scale(0.96); opacity:0; }
    to   { transform: translate3d(0,0,0) scale(1);        opacity:1; }
  }
  @keyframes -global-toastUp {
    from { transform: translate3d(0,20px,0); opacity:0; }
    to   { transform: translate3d(0,0,0);    opacity:1; }
  }
  @keyframes -global-retroIn {
    from { transform: scaleX(0); opacity:0; transform-origin:left; }
    to   { transform: scaleX(1); opacity:1; }
  }
  @keyframes -global-slideOut {
    from { transform:translate3d(0,0,0); opacity:1; max-height:calc(80px * var(--scale,1)); margin-bottom:calc(8px * var(--scale,1)); }
    to   { transform:translate3d(40px,0,0); opacity:0; max-height:0; margin-bottom:0; }
  }
  @keyframes -global-progressShrink {
    from { width:100%; }
    to   { width:0; }
  }

  :global(.notification.removing) {
    animation: slideOut 0.28s cubic-bezier(0.55,0,1,0.45) forwards !important;
    overflow: hidden;
  }
</style>
