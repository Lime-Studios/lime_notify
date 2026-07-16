<script>
  import { onMount } from 'svelte';
  import { store } from './notifications.svelte.js';
  import { ICON_PATHS, CLOSE_PATH } from './icons.js';
  import Editor from './Editor.svelte';

  let editorProps = $state(null);

  let containerStyle = $derived.by(() => {
    const { x, y } = store.position;
    let styles = [];
    if (x <= 15)      styles.push('left:1.2vw');
    else if (x >= 85) styles.push('right:1.2vw');
    else              styles.push(`left:${x}vw`, 'transform:translateX(-50%)');
    if (y <= 15)      styles.push('top:1.5vh');
    else if (y >= 85) styles.push('bottom:1.5vh');
    else              styles.push(`top:${y}vh`);
    return styles.join(';');
  });

  let flexDir = $derived(store.position.y >= 85 ? 'column-reverse' : 'column');

  const postNui = (endpoint, data) => {
    fetch('https://lime_notify/' + endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    }).catch(() => {});
  };

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

  function cardClicked(notif) {
    postNui('notifyClicked', { id: notif.id });
  }

  onMount(() => {
    store.loadSound();

    let nuiReady = false;
    const signalReady = () => postNui('nuiReady', {});
    const readyTimer = setInterval(() => { if (!nuiReady) signalReady(); }, 500);
    signalReady();

    function handleMessage(e) {
      const d = e.data;
      if (!d?.action) return;
      nuiReady = true;

      switch (d.action) {
        case 'notify':
          store.showNotification(d.type, d.title, d.message, d.duration, d.position, d.sound, d.volume, d.style, d.id);
          if (d.size !== undefined) store.applyScale(d.size / 100);
          break;
        case 'progress':
          store.showProgress(d.id, d.title, d.message, d.duration, d.type, d.style);
          if (d.position?.x !== undefined) store.applyPosition(d.position.x, d.position.y);
          if (d.size !== undefined) store.applyScale(d.size / 100);
          break;
        case 'dismiss':
          store.dismiss(d.id);
          break;
        case 'openEditor':
          editorProps = {
            x: d.x ?? 95, y: d.y ?? 5,
            menuX: d.menuX, menuY: d.menuY,
            sound: d.sound, volume: d.volume, size: d.size,
            style: d.style, allowStylePicker: d.allowStyle !== false,
          };
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
    const onKeydown = (e) => { if (e.key === 'Escape' && editorProps) closeEditor(); };
    window.addEventListener('keydown', onKeydown);

    return () => {
      clearInterval(readyTimer);
      window.removeEventListener('message', handleMessage);
      window.removeEventListener('keydown', onKeydown);
    };
  });
</script>

{#snippet card(notif)}
  <div
    class="notification n-{notif.type}"
    class:removing={notif.removing}
    class:is-progress={notif.progress}
    class:sticky={notif.duration === 0}
    style="--dur:{notif.duration}ms"
    onclick={() => cardClicked(notif)}
    role="status"
  >
    <div class="n-icon">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"
           stroke-linecap="round" stroke-linejoin="round">
        {@html ICON_PATHS[notif.type] || ICON_PATHS.info}
      </svg>
    </div>
    <div class="n-body">
      <div class="n-title">
        {@html notif.titleHtml}
        {#if notif.count > 1}
          {#key notif.bump}
            <span class="n-count">×{notif.count}</span>
          {/key}
        {/if}
      </div>
      {#if notif.message}<div class="n-msg">{@html notif.messageHtml}</div>{/if}
    </div>
    <button class="n-close" aria-label="Dismiss"
      onclick={(e) => { e.stopPropagation(); store.dismiss(notif.id); }}>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"
           stroke-linecap="round" stroke-linejoin="round">
        {@html CLOSE_PATH}
      </svg>
    </button>
    {#if notif.progress}
      <div class="n-progress fill"></div>
    {:else if notif.duration > 0}
      <div class="n-progress"></div>
    {/if}
  </div>
{/snippet}

<div
  class="notification-container s-{store.notifStyle}"
  style="--scale:{store.notifScale};{containerStyle};flex-direction:{flexDir}"
>
  {#each store.notifications as notif (notif.id)}
    {#if notif.style !== store.notifStyle}
      <div class="notification-container s-{notif.style}" style="position:static;display:block;max-width:none;gap:0;">
        {@render card(notif)}
      </div>
    {:else}
      {@render card(notif)}
    {/if}
  {/each}
  {#if store.overflowCount > 0}
    <div class="overflow-chip">+{store.overflowCount} more</div>
  {/if}
</div>

{#if editorProps}
  <Editor
    x={editorProps.x}
    y={editorProps.y}
    menuX={editorProps.menuX}
    menuY={editorProps.menuY}
    initialSound={editorProps.sound}
    initialVolume={editorProps.volume}
    initialSize={editorProps.size}
    initialStyle={editorProps.style}
    allowStylePicker={editorProps.allowStylePicker}
    onSave={saveEditor}
    onClose={closeEditor}
  />
{/if}

<style>
  :global(.notification-container) {
    position: fixed;
    z-index: 9999;
    display: flex;
    flex-direction: column;
    gap: calc(10px * var(--scale, 1));
    max-width: calc(380px * var(--scale, 1));
    pointer-events: none;
  }

  /* ── Shared structure ─────────────────────────────────────────── */
  :global(.notification) {
    display: flex;
    align-items: center;
    gap: calc(12px * var(--scale, 1));
    position: relative;
    overflow: hidden;
    pointer-events: auto;
    will-change: transform, opacity;
  }
  :global(.n-icon) {
    flex-shrink: 0;
    display: flex; align-items: center; justify-content: center;
  }
  :global(.n-icon svg) {
    width: calc(17px * var(--scale, 1));
    height: calc(17px * var(--scale, 1));
  }
  :global(.n-body) { flex: 1; min-width: 0; }
  :global(.n-title) {
    font-weight: 650;
    font-size: calc(13px * var(--scale, 1));
    letter-spacing: -0.01em;
    color: #fff;
    margin-bottom: calc(1px * var(--scale, 1));
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  }
  :global(.n-msg) {
    font-size: calc(12px * var(--scale, 1));
    color: rgba(255,255,255,0.6);
    line-height: 1.45;
    font-weight: 450;
  }
  :global(.n-close) {
    width: calc(22px * var(--scale, 1));
    height: calc(22px * var(--scale, 1));
    border: none; background: transparent;
    border-radius: calc(6px * var(--scale, 1));
    cursor: pointer; color: rgba(255,255,255,0.25);
    flex-shrink: 0;
    display: flex; align-items: center; justify-content: center;
    transition: background 0.15s, color 0.15s;
  }
  :global(.n-close svg) { width: calc(11px * var(--scale,1)); height: calc(11px * var(--scale,1)); }
  :global(.n-close:hover) { background: rgba(255,255,255,0.1); color: #fff; }
  :global(.n-progress) {
    position: absolute; bottom: 0; left: 0;
    height: calc(2.5px * var(--scale, 1));
    width: 100%;
    background: var(--accent);
    border-radius: 0 2px 2px 0;
    animation: progressShrink var(--dur) linear forwards;
    box-shadow: 0 0 8px var(--accent), 0 0 3px var(--accent);
  }

  /* Type accents — one variable drives everything */
  :global(.n-success) { --accent:#34d97b; --accent-soft:rgba(52,217,123,0.14); --accent-glow:rgba(52,217,123,0.35); }
  :global(.n-error)   { --accent:#ff5d5d; --accent-soft:rgba(255,93,93,0.14);  --accent-glow:rgba(255,93,93,0.35); }
  :global(.n-warning),
  :global(.n-warn)    { --accent:#ffb324; --accent-soft:rgba(255,179,36,0.14); --accent-glow:rgba(255,179,36,0.32); }
  :global(.n-info)    { --accent:#4da3ff; --accent-soft:rgba(77,163,255,0.14); --accent-glow:rgba(77,163,255,0.35); }
  :global(.n-claimed) { --accent:#ffd34d; --accent-soft:rgba(255,211,77,0.14); --accent-glow:rgba(255,211,77,0.32); }

  /* ════ 1. DEFAULT — premium card, colored glow, gradient icon chip ════ */
  :global(.s-default .notification) {
    border-radius: calc(12px * var(--scale, 1));
    padding: calc(13px * var(--scale, 1)) calc(15px * var(--scale, 1));
    background: linear-gradient(160deg, #17181d 0%, #101116 100%);
    border: 1px solid rgba(255,255,255,0.07);
    box-shadow:
      0 1px 0 rgba(255,255,255,0.05) inset,
      0 12px 32px -8px rgba(0,0,0,0.85),
      0 4px 24px -6px var(--accent-glow);
    min-width: calc(280px * var(--scale, 1));
    max-width: calc(360px * var(--scale, 1));
    animation: springRight 0.45s cubic-bezier(0.34, 1.4, 0.44, 1) both;
  }
  :global(.s-default .notification.removing) { animation: exitRight 0.25s cubic-bezier(0.55,0,1,0.45) forwards; }
  :global(.s-default .n-icon) {
    width: calc(38px * var(--scale, 1));
    height: calc(38px * var(--scale, 1));
    border-radius: calc(10px * var(--scale, 1));
    background: linear-gradient(145deg, var(--accent-soft), transparent 80%);
    border: 1px solid var(--accent-soft);
    color: var(--accent);
    box-shadow: 0 0 16px -4px var(--accent-glow) inset;
  }

  /* ════ 2. MINIMAL — floating pill, pulsing dot, no chrome ════ */
  :global(.s-minimal .notification) {
    border-radius: calc(100px * var(--scale, 1));
    padding: calc(10px * var(--scale, 1)) calc(16px * var(--scale, 1)) calc(10px * var(--scale, 1)) calc(18px * var(--scale, 1));
    background: rgba(14,14,18,0.97);
    border: 1px solid rgba(255,255,255,0.1);
    box-shadow: 0 8px 24px -6px rgba(0,0,0,0.7);
    min-width: calc(220px * var(--scale, 1));
    max-width: calc(340px * var(--scale, 1));
    animation: fadeScale 0.3s cubic-bezier(0.22,1,0.36,1) both;
  }
  :global(.s-minimal .notification.removing) { animation: fadeScaleOut 0.22s ease-in forwards; }
  :global(.s-minimal .n-icon) {
    width: calc(8px * var(--scale, 1));
    height: calc(8px * var(--scale, 1));
    border-radius: 50%;
    background: var(--accent);
    box-shadow: 0 0 10px var(--accent), 0 0 4px var(--accent);
    animation: dotPulse 2s ease-in-out infinite;
  }
  :global(.s-minimal .n-icon svg) { display: none; }
  :global(.s-minimal .n-title) { font-size: calc(12.5px * var(--scale,1)); font-weight: 600; }
  :global(.s-minimal .n-progress) { height: calc(1.5px * var(--scale,1)); box-shadow: none; opacity: 0.7; }

  /* ════ 3. GLASS — true frosted blur, gradient edge light ════ */
  :global(.s-glass .notification) {
    border-radius: calc(14px * var(--scale, 1));
    padding: calc(13px * var(--scale, 1)) calc(15px * var(--scale, 1));
    background: linear-gradient(135deg, rgba(32,34,42,0.96), rgba(22,23,29,0.94));
    border: 1px solid rgba(255,255,255,0.16);
    box-shadow:
      0 1px 0 rgba(255,255,255,0.12) inset,
      0 12px 40px -8px rgba(0,0,0,0.6);
    min-width: calc(280px * var(--scale, 1));
    max-width: calc(360px * var(--scale, 1));
    animation: glassDrop 0.4s cubic-bezier(0.22,1.3,0.4,1) both;
  }
  :global(.s-glass .notification.removing) { animation: glassLift 0.25s ease-in forwards; }
  :global(.s-glass .notification::before) {
    content: ''; position: absolute; inset: 0;
    background: radial-gradient(ellipse 70% 90% at 12% 50%, var(--accent-soft), transparent 65%);
    pointer-events: none;
  }
  :global(.s-glass .n-icon) {
    width: calc(36px * var(--scale, 1));
    height: calc(36px * var(--scale, 1));
    border-radius: calc(10px * var(--scale, 1));
    background: rgba(255,255,255,0.1);
    border: 1px solid rgba(255,255,255,0.18);
    color: var(--accent);
  }
  :global(.s-glass .n-msg) { color: rgba(255,255,255,0.72); }

  /* ════ 4. TOAST — wide bar, accent edge beam ════ */
  :global(.s-toast .notification) {
    border-radius: calc(8px * var(--scale, 1));
    padding: calc(12px * var(--scale, 1)) calc(16px * var(--scale, 1)) calc(12px * var(--scale, 1)) calc(19px * var(--scale, 1));
    background: #121317;
    border: 1px solid rgba(255,255,255,0.07);
    box-shadow: 0 10px 36px -8px rgba(0,0,0,0.85);
    min-width: calc(300px * var(--scale, 1));
    max-width: calc(380px * var(--scale, 1));
    animation: riseUp 0.35s cubic-bezier(0.22,1.3,0.4,1) both;
  }
  :global(.s-toast .notification.removing) { animation: sinkDown 0.22s ease-in forwards; }
  :global(.s-toast .notification::before) {
    content: ''; position: absolute; left: 0; top: 0; bottom: 0;
    width: calc(3.5px * var(--scale, 1));
    background: linear-gradient(180deg, var(--accent), transparent 140%);
    box-shadow: 0 0 12px var(--accent-glow);
  }
  :global(.s-toast .n-icon) {
    width: calc(34px * var(--scale, 1));
    height: calc(34px * var(--scale, 1));
    border-radius: calc(8px * var(--scale, 1));
    background: var(--accent-soft);
    color: var(--accent);
  }
  :global(.s-toast .n-progress) { border-radius: 0; }

  /* ════ 5. BOLD — deep tinted card, big accent presence ════ */
  :global(.s-bold .notification) {
    border-radius: calc(12px * var(--scale, 1));
    padding: calc(14px * var(--scale, 1)) calc(16px * var(--scale, 1));
    background:
      linear-gradient(140deg, var(--accent-soft), transparent 55%),
      #0e0f13;
    border: 1px solid var(--accent-glow);
    box-shadow:
      0 0 0 1px rgba(0,0,0,0.4),
      0 12px 36px -6px var(--accent-glow),
      0 8px 24px -8px rgba(0,0,0,0.8);
    min-width: calc(280px * var(--scale, 1));
    max-width: calc(360px * var(--scale, 1));
    animation: springRight 0.45s cubic-bezier(0.34, 1.4, 0.44, 1) both;
  }
  :global(.s-bold .notification.removing) { animation: exitRight 0.25s cubic-bezier(0.55,0,1,0.45) forwards; }
  :global(.s-bold .n-icon) {
    width: calc(40px * var(--scale, 1));
    height: calc(40px * var(--scale, 1));
    border-radius: 50%;
    background: var(--accent);
    color: #0a0a0c;
    box-shadow: 0 0 20px -2px var(--accent-glow), 0 4px 12px -4px var(--accent-glow);
  }
  :global(.s-bold .n-title) { font-size: calc(13.5px * var(--scale,1)); font-weight: 700; }

  /* ════ 6. RETRO — CRT terminal, scanlines, block cursor ════ */
  :global(.s-retro .notification) {
    border-radius: 0;
    padding: calc(11px * var(--scale, 1)) calc(15px * var(--scale, 1));
    background: rgba(6, 10, 7, 0.96);
    border: 1px solid var(--accent);
    box-shadow:
      0 0 0 1px rgba(0,0,0,0.8),
      0 0 20px -4px var(--accent-glow),
      0 0 44px -12px var(--accent-glow);
    min-width: calc(280px * var(--scale, 1));
    max-width: calc(370px * var(--scale, 1));
    font-family: 'Consolas', 'Courier New', monospace;
    animation: crtOn 0.22s cubic-bezier(0.2, 0.9, 0.4, 1.2) both;
  }
  :global(.s-retro .notification.removing) { animation: crtOff 0.18s ease-in forwards; }
  :global(.s-retro .notification::before) {
    content: ''; position: absolute; inset: 0;
    background: repeating-linear-gradient(0deg,
      transparent 0, transparent 2px,
      rgba(0,0,0,0.22) 2px, rgba(0,0,0,0.22) 3px);
    pointer-events: none;
  }
  :global(.s-retro .n-icon) {
    width: calc(30px * var(--scale, 1));
    height: calc(30px * var(--scale, 1));
    border: 1px solid var(--accent);
    color: var(--accent);
    background: var(--accent-soft);
  }
  :global(.s-retro .n-title) {
    font-family: inherit;
    font-size: calc(11px * var(--scale,1));
    text-transform: uppercase;
    letter-spacing: 0.12em;
    color: var(--accent);
    text-shadow: 0 0 6px var(--accent-glow);
  }
  :global(.s-retro .n-title::after) {
    content: '█';
    margin-left: 4px;
    animation: blink 1s steps(2) infinite;
    font-size: 0.8em;
  }
  :global(.s-retro .n-msg) {
    font-family: inherit;
    font-size: calc(11.5px * var(--scale,1));
    color: rgba(255,255,255,0.75);
  }
  :global(.s-retro .n-progress) { box-shadow: 0 0 10px var(--accent); }

  /* ── Animations ──────────────────────────────────────────────── */
  @keyframes -global-springRight {
    from { transform: translate3d(60px,0,0) scale(0.92); opacity: 0; }
    to   { transform: translate3d(0,0,0) scale(1); opacity: 1; }
  }
  @keyframes -global-exitRight {
    from { transform: translate3d(0,0,0); opacity: 1; max-height: calc(90px * var(--scale,1)); }
    to   { transform: translate3d(50px,0,0); opacity: 0; max-height: 0; margin: 0; padding-top: 0; padding-bottom: 0; }
  }
  @keyframes -global-fadeScale {
    from { transform: scale(0.9); opacity: 0; }
    to   { transform: scale(1); opacity: 1; }
  }
  @keyframes -global-fadeScaleOut {
    from { transform: scale(1); opacity: 1; max-height: calc(70px * var(--scale,1)); }
    to   { transform: scale(0.92); opacity: 0; max-height: 0; margin: 0; padding-top: 0; padding-bottom: 0; }
  }
  @keyframes -global-glassDrop {
    from { transform: translate3d(0,-18px,0) scale(0.96); opacity: 0; }
    to   { transform: translate3d(0,0,0) scale(1); opacity: 1; }
  }
  @keyframes -global-glassLift {
    from { transform: translate3d(0,0,0); opacity: 1; max-height: calc(90px * var(--scale,1)); }
    to   { transform: translate3d(0,-14px,0); opacity: 0; max-height: 0; margin: 0; padding-top: 0; padding-bottom: 0; }
  }
  @keyframes -global-riseUp {
    from { transform: translate3d(0,22px,0); opacity: 0; }
    to   { transform: translate3d(0,0,0); opacity: 1; }
  }
  @keyframes -global-sinkDown {
    from { transform: translate3d(0,0,0); opacity: 1; max-height: calc(90px * var(--scale,1)); }
    to   { transform: translate3d(0,16px,0); opacity: 0; max-height: 0; margin: 0; padding-top: 0; padding-bottom: 0; }
  }
  @keyframes -global-crtOn {
    from { transform: scaleY(0.05) scaleX(0.85); opacity: 0.6; filter: brightness(2.5); }
    60%  { transform: scaleY(1.04) scaleX(1); filter: brightness(1.3); }
    to   { transform: scale(1); opacity: 1; filter: brightness(1); }
  }
  @keyframes -global-crtOff {
    from { transform: scale(1); opacity: 1; max-height: calc(90px * var(--scale,1)); filter: brightness(1); }
    to   { transform: scaleY(0.03); opacity: 0; max-height: 0; margin: 0; padding-top: 0; padding-bottom: 0; filter: brightness(2.5); }
  }
  @keyframes -global-dotPulse {
    0%, 100% { box-shadow: 0 0 10px var(--accent), 0 0 4px var(--accent); }
    50%      { box-shadow: 0 0 4px var(--accent); }
  }
  @keyframes -global-blink {
    50% { opacity: 0; }
  }
  @keyframes -global-progressShrink {
    from { width: 100%; }
    to   { width: 0; }
  }

  /* ── New feature styles ─────────────────────────────── */
  :global(.n-count) {
    display: inline-block;
    margin-left: 6px;
    padding: 1px 7px;
    border-radius: 100px;
    background: var(--accent);
    color: #0a0a0c;
    font-size: calc(10px * var(--scale, 1));
    font-weight: 800;
    vertical-align: 1px;
    animation: countPop 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  }
  @keyframes -global-countPop {
    from { transform: scale(1.6); }
    to   { transform: scale(1); }
  }
  :global(.n-progress.fill) {
    animation: progressFill var(--dur) linear forwards;
  }
  @keyframes -global-progressFill {
    from { width: 0; }
    to   { width: 100%; }
  }
  :global(.notification.sticky .n-progress:not(.fill)) { display: none; }
  :global(.notification) { cursor: pointer; }
  :global(.overflow-chip) {
    align-self: center;
    padding: calc(4px * var(--scale,1)) calc(12px * var(--scale,1));
    border-radius: 100px;
    background: rgba(14,14,18,0.9);
    border: 1px solid rgba(255,255,255,0.12);
    color: rgba(255,255,255,0.6);
    font-size: calc(11px * var(--scale,1));
    font-weight: 600;
    pointer-events: none;
    animation: fadeScale 0.25s ease-out both;
  }
</style>
