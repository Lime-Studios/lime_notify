<script>
  let {
    x = 95, y = 5,
    menuX = undefined, menuY = undefined,
    initialSound = true,
    initialVolume = 50,
    initialSize = 100,
    initialStyle = 'default',
    allowStylePicker = true,
    onSave,
    onClose,
  } = $props();

  let soundOn     = $state(initialSound !== false);
  let vol         = $state(initialVolume ?? 50);
  let size        = $state(initialSize ?? 100);
  let activeStyle = $state(initialStyle || 'default');

  let panelEl   = $state(null);
  let previewEl = $state(null);
  let drag      = $state({ el: null, offX: 0, offY: 0 });

  let dropdownOpen = $state(false);
  let moveMode     = $state(false);   // hides panel, free-drag the preview

  const PRESETS = [
    { key: 'top-left',      label: 'Top Left',      x: 5,  y: 5  },
    { key: 'top-center',    label: 'Top Center',    x: 50, y: 5  },
    { key: 'top-right',     label: 'Top Right',     x: 95, y: 5  },
    { key: 'middle-left',   label: 'Middle Left',   x: 5,  y: 50 },
    { key: 'middle-center', label: 'Middle Center', x: 50, y: 50 },
    { key: 'middle-right',  label: 'Middle Right',  x: 95, y: 50 },
    { key: 'bottom-left',   label: 'Bottom Left',   x: 5,  y: 95 },
    { key: 'bottom-center', label: 'Bottom Center', x: 50, y: 95 },
    { key: 'bottom-right',  label: 'Bottom Right',  x: 95, y: 95 },
  ];

  // svelte-ignore state_referenced_locally
  let panelPos = $state({
    left: menuX !== undefined ? menuX : Math.round(window.innerWidth * 0.05),
    top:  menuY !== undefined ? menuY : Math.round(Math.max(20, window.innerHeight / 2 - 250)),
  });

  // svelte-ignore state_referenced_locally
  let prev = $state({
    left: Math.max(8, (x / 100) * window.innerWidth  - 160),
    top:  Math.max(8, (y / 100) * window.innerHeight - 40),
  });

  // Current position as % (from preview center)
  let curPct = $derived({
    x: Math.round(Math.min(95, Math.max(5, ((prev.left + 160) / window.innerWidth)  * 100))),
    y: Math.round(Math.min(95, Math.max(5, ((prev.top  + 40)  / window.innerHeight) * 100))),
  });

  // Matching preset, or "Custom"
  let currentLabel = $derived.by(() => {
    const hit = PRESETS.find(p => Math.abs(p.x - curPct.x) <= 6 && Math.abs(p.y - curPct.y) <= 6);
    return hit ? hit.label : 'Custom position';
  });

  function pick(p) {
    prev = {
      left: Math.min(window.innerWidth  - 330, Math.max(8, (p.x / 100) * window.innerWidth  - 160)),
      top:  Math.min(window.innerHeight - 90,  Math.max(8, (p.y / 100) * window.innerHeight - 40)),
    };
    dropdownOpen = false;
  }

  function startDrag(which, e) {
    const el = which === 'panel' ? panelEl : previewEl;
    if (!el) return;
    const r = el.getBoundingClientRect();
    drag = { el: which, offX: e.clientX - r.left, offY: e.clientY - r.top };
    e.preventDefault();
  }

  function onMouseMove(e) {
    if (!drag.el) return;
    const nx = e.clientX - drag.offX;
    const ny = e.clientY - drag.offY;
    if (drag.el === 'panel') {
      const r = panelEl?.getBoundingClientRect();
      panelPos = {
        left: Math.min(window.innerWidth  - (r?.width  ?? 300), Math.max(0, nx)),
        top:  Math.min(window.innerHeight - (r?.height ?? 520), Math.max(0, ny)),
      };
    } else {
      const r = previewEl?.getBoundingClientRect();
      prev = {
        left: Math.min(window.innerWidth  - (r?.width  ?? 320), Math.max(0, nx)),
        top:  Math.min(window.innerHeight - (r?.height ?? 70),  Math.max(0, ny)),
      };
    }
  }

  const onMouseUp = () => { drag = { el: null, offX: 0, offY: 0 }; };

  function handleSave() {
    onSave?.({
      x: curPct.x, y: curPct.y,
      menuX: Math.round(panelPos.left),
      menuY: Math.round(panelPos.top),
      sound: soundOn, volume: vol, size, style: activeStyle,
    });
  }

  function onKey(e) {
    if (e.key !== 'Escape') return;
    if (moveMode)          { moveMode = false; e.stopPropagation(); }
    else if (dropdownOpen) { dropdownOpen = false; e.stopPropagation(); }
  }

  const STYLES = [
    { key: 'default', label: 'Default' },
    { key: 'minimal', label: 'Minimal' },
    { key: 'glass',   label: 'Glass'   },
    { key: 'toast',   label: 'Toast'   },
    { key: 'bold',    label: 'Bold'    },
    { key: 'retro',   label: 'Retro'   },
  ];
</script>

<svelte:window onmousemove={onMouseMove} onmouseup={onMouseUp} onkeydown={onKey} />

<div class="overlay" class:move-mode={moveMode} role="dialog" aria-modal="true">
  <div class="grid-bg"></div>

  <!-- Live preview — draggable only in move mode -->
  <div
    bind:this={previewEl}
    class="notification-container s-{activeStyle} preview-wrap"
    class:draggable={moveMode}
    class:dragging={drag.el === 'preview'}
    style="--scale:{size / 100};left:{prev.left}px;top:{prev.top}px;"
    onmousedown={(e) => moveMode && startDrag('preview', e)}
    role="none"
  >
    <div class="notification n-info preview-card">
      <div class="n-icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"
             stroke-linecap="round" stroke-linejoin="round" width="17" height="17">
          <circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>
        </svg>
      </div>
      <div class="n-body">
        <div class="n-title">Notification preview</div>
        <div class="n-msg">{moveMode ? 'Drag me where you want alerts' : 'This is where alerts appear'}</div>
      </div>
      {#if moveMode}
        <div class="drag-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"
               stroke-linecap="round" stroke-linejoin="round">
            <path d="M5 9l-3 3 3 3M9 5l3-3 3 3M15 19l-3 3-3-3M19 9l3 3-3 3M2 12h20M12 2v20"/>
          </svg>
        </div>
      {/if}
    </div>
  </div>

  <!-- Move mode toolbar -->
  {#if moveMode}
    <div class="move-bar">
      <div class="move-info">
        <span class="move-title">Move mode</span>
        <span class="move-sub">Drag the preview · {curPct.x}% · {curPct.y}%</span>
      </div>
      <button class="btn ghost sm" onclick={() => moveMode = false}>Cancel</button>
      <button class="btn primary sm" onclick={() => moveMode = false}>Done</button>
    </div>
  {/if}

  <!-- Settings panel -->
  <div
    bind:this={panelEl}
    class="panel"
    class:hidden={moveMode}
    class:dragging={drag.el === 'panel'}
    style="left:{panelPos.left}px;top:{panelPos.top}px;"
  >
    <div class="panel-header" onmousedown={(e) => startDrag('panel', e)} role="none">
      <div class="grip"><span></span><span></span><span></span></div>
      <div class="header-text">
        <h3>Notifications</h3>
        <p>Position · Style · Sound</p>
      </div>
      <button class="header-close" aria-label="Close" onclick={onClose}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="12" height="12">
          <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
        </svg>
      </button>
    </div>

    <div class="panel-body">
      <!-- Position: dropdown + move button -->
      <div class="section">
        <span class="label">Position</span>
        <div class="select-wrap">
          <button class="select" class:open={dropdownOpen} onclick={() => dropdownOpen = !dropdownOpen}>
            <span class="select-val">{currentLabel}</span>
            <svg class="chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"
                 width="13" height="13" stroke-linecap="round" stroke-linejoin="round">
              <polyline points="6 9 12 15 18 9"/>
            </svg>
          </button>
          {#if dropdownOpen}
            <div class="menu">
              {#each PRESETS as p}
                <button class="menu-item" class:on={currentLabel === p.label} onclick={() => pick(p)}>
                  <span class="mini-screen">
                    <span class="mini-dot" style="left:{p.x === 5 ? 12 : p.x === 50 ? 50 : 88}%;top:{p.y === 5 ? 18 : p.y === 50 ? 50 : 82}%"></span>
                  </span>
                  {p.label}
                  {#if currentLabel === p.label}
                    <svg class="tick" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"
                         width="12" height="12" stroke-linecap="round" stroke-linejoin="round">
                      <path d="M20 6 9 17l-5-5"/>
                    </svg>
                  {/if}
                </button>
              {/each}
            </div>
          {/if}
        </div>
        <button class="move-btn" onclick={() => { moveMode = true; dropdownOpen = false; }}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="13" height="13"
               stroke-linecap="round" stroke-linejoin="round">
            <path d="M5 9l-3 3 3 3M9 5l3-3 3 3M15 19l-3 3-3-3M19 9l3 3-3 3M2 12h20M12 2v20"/>
          </svg>
          Move position
        </button>
      </div>

      {#if allowStylePicker}
        <div class="section">
          <span class="label">Style</span>
          <div class="style-grid">
            {#each STYLES as s}
              <button class="style-card thumb-{s.key}" class:active={activeStyle === s.key}
                onclick={() => activeStyle = s.key} aria-pressed={activeStyle === s.key}>
                <span class="thumb">
                  <span class="t-dot"></span>
                  <span class="t-lines"><i></i><i></i></span>
                </span>
                <span class="style-name">{s.label}</span>
              </button>
            {/each}
          </div>
        </div>
      {/if}

      <div class="section row">
        <span class="label">Sound</span>
        <button class="toggle" class:on={soundOn} aria-label="Toggle sound"
          onclick={() => soundOn = !soundOn}></button>
      </div>

      <div class="section">
        <div class="slider-head">
          <span class="label">Volume</span>
          <span class="val">{vol}%</span>
        </div>
        <input type="range" min="0" max="100" bind:value={vol} class="slider" disabled={!soundOn} />
      </div>

      <div class="section">
        <div class="slider-head">
          <span class="label">Size</span>
          <span class="val">{size}%</span>
        </div>
        <input type="range" min="75" max="200" step="5" bind:value={size} class="slider" />
      </div>
    </div>

    <div class="panel-footer">
      <button class="btn ghost" onclick={onClose}>Cancel</button>
      <button class="btn primary" onclick={handleSave}>Save changes</button>
    </div>
  </div>
</div>

<style>
  .overlay {
    position: fixed; inset: 0;
    background: rgba(3,4,7,0.74);
    z-index: 10000;
    font-family: 'Plus Jakarta Sans Variable', system-ui, sans-serif;
    transition: background 0.2s;
  }
  .overlay.move-mode { background: rgba(3,4,7,0.42); }
  .grid-bg {
    position: absolute; inset: 0;
    background-image:
      repeating-linear-gradient(0deg,  rgba(255,255,255,0.03) 0,rgba(255,255,255,0.03) 1px,transparent 1px,transparent 72px),
      repeating-linear-gradient(90deg, rgba(255,255,255,0.03) 0,rgba(255,255,255,0.03) 1px,transparent 1px,transparent 72px);
    mask-image: radial-gradient(ellipse at center, black 30%, transparent 85%);
    pointer-events: none;
  }

  /* ── Preview ── */
  :global(.preview-wrap) {
    position: absolute !important;
    display: block !important;
    max-width: none !important;
    gap: 0 !important;
    pointer-events: none;
  }
  :global(.preview-wrap.draggable) { pointer-events: auto; cursor: grab; }
  :global(.preview-wrap.dragging)  { cursor: grabbing; filter: brightness(1.12); }
  :global(.preview-card) { animation: none !important; user-select: none; }
  :global(.preview-wrap.draggable .preview-card) {
    outline: 1.5px dashed rgba(52,217,123,0.6);
    outline-offset: 5px;
  }
  :global(.preview-card .n-progress) { display: none; }
  :global(.drag-icon) { color: rgba(255,255,255,0.35); flex-shrink: 0; display: flex; }

  /* ── Move bar ── */
  .move-bar {
    position: fixed; bottom: 32px; left: 50%; transform: translateX(-50%);
    display: flex; align-items: center; gap: 10px;
    padding: 11px 12px 11px 18px;
    background: linear-gradient(172deg, #17181e, #0f1015);
    border: 1px solid rgba(52,217,123,0.28);
    border-radius: 14px;
    box-shadow: 0 20px 56px -12px rgba(0,0,0,0.9), 0 0 32px -12px rgba(52,217,123,0.4);
    z-index: 10002;
    animation: barUp 0.28s cubic-bezier(0.22,1.3,0.4,1) both;
  }
  @keyframes barUp {
    from { transform: translate(-50%, 16px); opacity: 0; }
    to   { transform: translate(-50%, 0);    opacity: 1; }
  }
  .move-info { display: flex; flex-direction: column; margin-right: 6px; }
  .move-title { color: #fff; font-size: 12.5px; font-weight: 700; }
  .move-sub   { color: rgba(255,255,255,0.42); font-size: 11px; font-weight: 500; font-variant-numeric: tabular-nums; }

  /* ── Panel ── */
  .panel {
    position: fixed; width: 300px;
    background: linear-gradient(172deg, #17181e 0%, #101116 60%, #0d0e12 100%);
    border: 1px solid rgba(255,255,255,0.09);
    border-radius: 18px;
    box-shadow:
      0 1px 0 rgba(255,255,255,0.06) inset,
      0 32px 80px -16px rgba(0,0,0,0.9),
      0 8px 32px -8px rgba(52,217,123,0.07);
    z-index: 10001;
    user-select: none;
    transition: opacity 0.18s, transform 0.18s;
  }
  .panel.hidden { opacity: 0; transform: scale(0.96); pointer-events: none; }

  .panel-header {
    display: flex; align-items: center; gap: 12px;
    padding: 16px 16px 14px 18px;
    cursor: grab;
    border-bottom: 1px solid rgba(255,255,255,0.06);
    background: linear-gradient(90deg, rgba(52,217,123,0.06), transparent 55%);
    border-radius: 18px 18px 0 0;
  }
  .panel.dragging .panel-header { cursor: grabbing; }
  .grip { display: flex; flex-direction: column; gap: 3px; }
  .grip span { width: 14px; height: 2px; border-radius: 1px; background: rgba(255,255,255,0.22); }
  .header-text { flex: 1; }
  .header-text h3 { color: #fff; font-size: 14.5px; font-weight: 700; letter-spacing: -0.01em; }
  .header-text p  { color: rgba(255,255,255,0.38); font-size: 11px; font-weight: 500; margin-top: 1px; }
  .header-close {
    width: 26px; height: 26px; border: none; border-radius: 8px;
    background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.4);
    cursor: pointer; display: flex; align-items: center; justify-content: center;
    transition: all 0.15s;
  }
  .header-close:hover { background: rgba(255,93,93,0.15); color: #ff5d5d; }

  .panel-body { padding: 6px 18px 10px; }
  .section { padding: 11px 0; }
  .section.row { display: flex; justify-content: space-between; align-items: center; }
  .section + .section { border-top: 1px solid rgba(255,255,255,0.045); }
  .label {
    display: block; color: rgba(255,255,255,0.45);
    font-size: 10.5px; font-weight: 700;
    letter-spacing: 0.08em; text-transform: uppercase;
    margin-bottom: 9px;
  }
  .section.row .label { margin-bottom: 0; }
  .slider-head { display: flex; justify-content: space-between; align-items: baseline; }
  .val { color: #34d97b; font-size: 12px; font-weight: 700; font-variant-numeric: tabular-nums; }

  /* ── Dropdown ── */
  .select-wrap { position: relative; }
  .select {
    width: 100%;
    display: flex; align-items: center; justify-content: space-between;
    padding: 10px 12px;
    background: rgba(255,255,255,0.04);
    border: 1px solid rgba(255,255,255,0.09);
    border-radius: 10px;
    color: #fff; font-family: inherit; font-size: 12.5px; font-weight: 600;
    cursor: pointer; transition: all 0.15s;
  }
  .select:hover { background: rgba(255,255,255,0.07); border-color: rgba(255,255,255,0.18); }
  .select.open { border-color: rgba(52,217,123,0.5); background: rgba(52,217,123,0.07); }
  .chev { color: rgba(255,255,255,0.4); transition: transform 0.2s; flex-shrink: 0; }
  .select.open .chev { transform: rotate(180deg); color: #34d97b; }

  .menu {
    position: absolute; top: calc(100% + 5px); left: 0; right: 0;
    background: #14151a;
    border: 1px solid rgba(255,255,255,0.11);
    border-radius: 11px;
    padding: 5px;
    box-shadow: 0 20px 44px -10px rgba(0,0,0,0.9);
    z-index: 20;
    max-height: 232px; overflow-y: auto;
    animation: menuIn 0.15s cubic-bezier(0.22,1,0.36,1) both;
  }
  @keyframes menuIn {
    from { opacity: 0; transform: translateY(-5px); }
    to   { opacity: 1; transform: translateY(0); }
  }
  .menu::-webkit-scrollbar { width: 4px; }
  .menu::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.15); border-radius: 2px; }
  .menu-item {
    width: 100%; display: flex; align-items: center; gap: 9px;
    padding: 7px 8px; border: none; border-radius: 7px;
    background: transparent; color: rgba(255,255,255,0.65);
    font-family: inherit; font-size: 12px; font-weight: 550;
    cursor: pointer; text-align: left; transition: all 0.12s;
  }
  .menu-item:hover { background: rgba(255,255,255,0.07); color: #fff; }
  .menu-item.on { background: rgba(52,217,123,0.11); color: #34d97b; }
  .mini-screen {
    width: 24px; height: 15px; flex-shrink: 0; position: relative;
    border: 1px solid rgba(255,255,255,0.22); border-radius: 3px;
    background: rgba(255,255,255,0.03);
  }
  .mini-dot {
    position: absolute; width: 4px; height: 4px; border-radius: 1px;
    background: currentColor; transform: translate(-50%, -50%);
  }
  .tick { margin-left: auto; flex-shrink: 0; }

  .move-btn {
    width: 100%; margin-top: 7px;
    display: flex; align-items: center; justify-content: center; gap: 7px;
    padding: 9px; border-radius: 10px;
    background: rgba(52,217,123,0.09);
    border: 1px solid rgba(52,217,123,0.3);
    color: #34d97b; font-family: inherit;
    font-size: 12px; font-weight: 700;
    cursor: pointer; transition: all 0.15s;
  }
  .move-btn:hover {
    background: rgba(52,217,123,0.16);
    border-color: rgba(52,217,123,0.55);
    box-shadow: 0 0 18px -6px rgba(52,217,123,0.6);
  }

  /* ── Style thumbnails ── */
  .style-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 6px; }
  .style-card {
    display: flex; flex-direction: column; align-items: center; gap: 6px;
    padding: 7px 4px 6px;
    border: 1px solid rgba(255,255,255,0.07);
    border-radius: 10px; background: rgba(255,255,255,0.02);
    cursor: pointer; transition: all 0.15s; font-family: inherit;
  }
  .style-card:hover { background: rgba(255,255,255,0.055); border-color: rgba(255,255,255,0.15); }
  .style-card.active {
    background: rgba(52,217,123,0.09);
    border-color: rgba(52,217,123,0.5);
    box-shadow: 0 0 16px -6px rgba(52,217,123,0.5);
  }
  .style-name { font-size: 10px; font-weight: 650; color: rgba(255,255,255,0.5); }
  .style-card.active .style-name { color: #34d97b; }
  .thumb {
    width: 100%; height: 26px;
    display: flex; align-items: center; gap: 5px;
    padding: 0 7px; position: relative; overflow: hidden;
  }
  .t-dot { width: 8px; height: 8px; border-radius: 3px; background: #34d97b; flex-shrink: 0; }
  .t-lines { display: flex; flex-direction: column; gap: 3px; flex: 1; }
  .t-lines i { display: block; height: 2.5px; border-radius: 2px; background: rgba(255,255,255,0.45); }
  .t-lines i:first-child { width: 75%; }
  .t-lines i:last-child  { width: 45%; background: rgba(255,255,255,0.2); }
  .thumb-default .thumb { background: #16171c; border: 1px solid rgba(255,255,255,0.09); border-radius: 6px; box-shadow: 0 2px 8px -2px rgba(52,217,123,0.35); }
  .thumb-minimal .thumb { background: #101014; border: 1px solid rgba(255,255,255,0.1); border-radius: 100px; }
  .thumb-minimal .t-dot { border-radius: 50%; width: 6px; height: 6px; box-shadow: 0 0 5px #34d97b; }
  .thumb-glass .thumb   { background: linear-gradient(135deg, rgba(70,75,92,0.95), rgba(40,43,54,0.9)); border: 1px solid rgba(255,255,255,0.22); border-radius: 7px; }
  .thumb-toast .thumb   { background: #121317; border: 1px solid rgba(255,255,255,0.08); border-left: 3px solid #34d97b; border-radius: 4px; }
  .thumb-bold .thumb    { background: linear-gradient(140deg, rgba(52,217,123,0.25), #0e0f13 60%); border: 1px solid rgba(52,217,123,0.45); border-radius: 6px; }
  .thumb-bold .t-dot    { border-radius: 50%; }
  .thumb-retro .thumb   { background: #060a07; border: 1px solid #34d97b; border-radius: 0; box-shadow: 0 0 6px -1px rgba(52,217,123,0.6); }
  .thumb-retro .t-dot   { border-radius: 0; }

  /* ── Toggle / sliders ── */
  .toggle {
    position: relative; width: 40px; height: 23px;
    background: rgba(255,255,255,0.1); border-radius: 12px;
    cursor: pointer; border: none; transition: background 0.2s;
  }
  .toggle.on { background: #34d97b; box-shadow: 0 0 12px -2px rgba(52,217,123,0.5); }
  .toggle::after {
    content: ''; position: absolute; width: 17px; height: 17px;
    background: #fff; border-radius: 50%; top: 3px; left: 3px;
    transition: transform 0.2s cubic-bezier(0.22,1,0.36,1);
    box-shadow: 0 1px 3px rgba(0,0,0,0.35);
  }
  .toggle.on::after { transform: translateX(17px); }
  .slider {
    width: 100%; height: 4px; border-radius: 2px;
    background: rgba(255,255,255,0.09); outline: none;
    -webkit-appearance: none; cursor: pointer; transition: opacity 0.2s;
  }
  .slider:disabled { opacity: 0.3; cursor: default; }
  .slider::-webkit-slider-thumb {
    -webkit-appearance: none; width: 14px; height: 14px;
    border-radius: 50%; background: #34d97b; cursor: pointer;
    box-shadow: 0 0 8px rgba(52,217,123,0.55), 0 1px 3px rgba(0,0,0,0.4);
    transition: transform 0.12s;
  }
  .slider::-webkit-slider-thumb:hover { transform: scale(1.2); }

  /* ── Buttons ── */
  .panel-footer {
    display: flex; gap: 8px;
    padding: 13px 18px 16px;
    border-top: 1px solid rgba(255,255,255,0.06);
  }
  .btn {
    flex: 1; padding: 10px; border: none; border-radius: 10px;
    font-family: inherit; font-weight: 700; font-size: 12.5px;
    cursor: pointer; transition: all 0.15s;
  }
  .btn.sm { flex: none; padding: 8px 16px; font-size: 12px; }
  .btn.primary { background: #34d97b; color: #06130b; flex: 1.6; }
  .btn.primary.sm { flex: none; }
  .btn.primary:hover { background: #4ae68c; box-shadow: 0 6px 20px -6px rgba(52,217,123,0.6); }
  .btn.ghost { background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.55); border: 1px solid rgba(255,255,255,0.08); }
  .btn.ghost:hover { background: rgba(255,255,255,0.09); color: #fff; }
</style>
