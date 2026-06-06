<script>
  import { store } from './notifications.svelte.js';

  let {
    x = 50, y = 5,
    menuX = undefined, menuY = undefined,
    allowStylePicker = true,
    onSave,
    onClose,
  } = $props();

  let soundOn    = $state(store.soundOn);
  let vol        = $state(Math.round(store.soundVol * 100));
  let size       = $state(Math.round(store.notifScale * 100));
  let activeStyle = $state(store.notifStyle);

  // Dragging for panel
  let panelEl = $state(null);
  let previewEl = $state(null);
  let drag = { el: null, offX: 0, offY: 0 };

  // Panel position
  let panelLeft      = $state(menuX !== undefined ? menuX + 'px' : '50%');
  let panelTop       = $state(menuY !== undefined ? menuY + 'px' : '40px');
  let panelTransform = $state(menuX !== undefined ? 'none' : 'translateX(-50%)');

  // Preview position
  let prevLeft = $state(Math.max(0, ((x / 100) * window.innerWidth)  - 160) + 'px');
  let prevTop  = $state(Math.max(0, ((y / 100) * window.innerHeight) - 36)  + 'px');

  function startDrag(el, e) {
    const r = el.getBoundingClientRect();
    drag.el   = el === panelEl ? 'panel' : 'preview';
    drag.offX = e.clientX - r.left;
    drag.offY = e.clientY - r.top;
    e.preventDefault();
  }

  function onMouseMove(e) {
    if (!drag.el) return;
    const nx = e.clientX - drag.offX;
    const ny = e.clientY - drag.offY;
    if (drag.el === 'panel') {
      panelLeft = nx + 'px'; panelTop = ny + 'px'; panelTransform = 'none';
    } else {
      prevLeft = nx + 'px'; prevTop = ny + 'px';
    }
  }

  function onMouseUp() { drag.el = null; }

  function pickStyle(s) { activeStyle = s; }

  function handleSave() {
    // Compute x/y from preview element position
    const raw = previewEl?.getBoundingClientRect();
    const cardW = raw ? raw.width  : 280;
    const cardH = raw ? raw.height : 60;
    const rawL  = parseFloat(prevLeft) || 0;
    const rawT  = parseFloat(prevTop)  || 0;
    const sx = Math.round(Math.min(95, Math.max(5, ((rawL + cardW / 2) / window.innerWidth)  * 100)));
    const sy = Math.round(Math.min(95, Math.max(5, ((rawT + cardH / 2) / window.innerHeight) * 100)));
    const pr = panelEl?.getBoundingClientRect();

    onSave?.({
      x: sx, y: sy,
      menuX: pr ? Math.round(pr.left) : undefined,
      menuY: pr ? Math.round(pr.top)  : undefined,
      sound:  soundOn,
      volume: vol,
      size,
      style:  activeStyle,
    });
  }

  const VALID_STYLES = store.VALID_STYLES;
  const STYLE_META = [
    { key: 'default', label: 'Default', previewClass: 'sp-default', dotColor: '#4ade80', lineColor: '#4ade80' },
    { key: 'minimal', label: 'Minimal', previewClass: 'sp-minimal', dotColor: '#4ade80', lineColor: '#4ade80' },
    { key: 'glass',   label: 'Glass',   previewClass: 'sp-glass',   dotColor: '#93c5fd', lineColor: '#93c5fd' },
    { key: 'toast',   label: 'Toast',   previewClass: 'sp-toast',   dotColor: '#4ade80', lineColor: 'rgba(255,255,255,0.4)' },
    { key: 'bold',    label: 'Bold',    previewClass: 'sp-bold',    dotColor: 'rgba(0,0,0,0.5)', lineColor: 'rgba(0,0,0,0.7)', lineBot: 'rgba(0,0,0,0.4)' },
    { key: 'retro',   label: 'Retro',   previewClass: 'sp-retro',   dotColor: '#00ff7f', lineColor: '#00ff7f', lineBot: 'rgba(0,255,127,0.3)' },
  ];
</script>

<svelte:window onmousemove={onMouseMove} onmouseup={onMouseUp} />

<!-- Editor overlay -->
<div class="editor-overlay active" role="dialog" aria-modal="true">
  <div class="editor-grid"></div>

  <!-- Draggable preview notification -->
  <div
    bind:this={previewEl}
    class="notification-container s-{activeStyle}"
    style="position:absolute;display:block;max-width:none;gap:0;pointer-events:auto;left:{prevLeft};top:{prevTop};cursor:move;"
    onmousedown={(e) => startDrag(previewEl, e)}
    role="none"
  >
    <div class="notification n-info editor-preview">
      <div class="n-icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
             stroke-linecap="round" stroke-linejoin="round" width="18" height="18">
          <circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>
        </svg>
      </div>
      <div class="n-body">
        <div class="n-title">Preview</div>
        <div class="n-msg">Drag to reposition</div>
      </div>
    </div>
  </div>

  <!-- Settings panel -->
  <div
    bind:this={panelEl}
    class="editor-panel"
    style="left:{panelLeft};top:{panelTop};transform:{panelTransform};"
  >
    <div
      class="editor-panel-header"
      onmousedown={(e) => startDrag(panelEl, e)}
      role="none"
    >
      <h3>Notification Settings</h3>
      <p>Drag preview or this panel to reposition</p>
    </div>

    <div class="editor-settings">

      {#if allowStylePicker}
        <div class="setting-row style-row">
          <div class="setting-top">
            <span class="setting-label">Style</span>
          </div>
          <div class="style-picker">
            {#each STYLE_META as sm}
              <button
                class="style-option"
                class:active={activeStyle === sm.key}
                onclick={() => pickStyle(sm.key)}
                aria-pressed={activeStyle === sm.key}
              >
                <div class="style-option-preview {sm.previewClass}">
                  <div class="sp-dot" style="color:{sm.dotColor}"></div>
                  <div class="sp-line sp-line-top" style="color:{sm.lineColor}"></div>
                  <div class="sp-line sp-line-bot" style="color:{sm.lineBot || 'rgba(255,255,255,0.25)'}"></div>
                </div>
                <span class="style-option-label">{sm.label}</span>
              </button>
            {/each}
          </div>
        </div>
        <div class="editor-divider"></div>
      {/if}

      <div class="setting-row">
        <div class="setting-top">
          <span class="setting-label">Sound</span>
          <button
            class="toggle"
            class:on={soundOn}
            aria-label="Toggle sound"
            onclick={() => soundOn = !soundOn}
          ></button>
        </div>
      </div>

      <div class="setting-row">
        <div class="setting-top">
          <span class="setting-label">Volume</span>
          <span class="range-value">{vol}%</span>
        </div>
        <input type="range" min="0" max="100" bind:value={vol} class="range-slider" />
      </div>

      <div class="setting-row">
        <div class="setting-top">
          <span class="setting-label">Size</span>
          <span class="range-value">{size}%</span>
        </div>
        <input type="range" min="75" max="200" step="5" bind:value={size} class="range-slider" />
      </div>

    </div>

    <div class="editor-btns">
      <button class="e-btn cancel" onclick={onClose}>Cancel</button>
      <button class="e-btn save"   onclick={handleSave}>Save</button>
    </div>
  </div>
</div>

<style>
  .editor-overlay {
    position: fixed; inset: 0;
    background: rgba(0,0,0,0.75);
    z-index: 10000;
  }
  .editor-grid {
    position: absolute; inset: 0;
    background-image:
      repeating-linear-gradient(0deg,  rgba(255,255,255,0.02) 0,rgba(255,255,255,0.02) 1px,transparent 1px,transparent 60px),
      repeating-linear-gradient(90deg, rgba(255,255,255,0.02) 0,rgba(255,255,255,0.02) 1px,transparent 1px,transparent 60px);
    pointer-events: none;
  }
  .editor-preview {
    cursor: move;
    animation: none !important;
    user-select: none;
    transition: none !important;
  }
  .editor-preview::after, .editor-preview::before { display: none !important; }
  .editor-panel {
    position: fixed;
    background: rgba(16,16,20,0.98);
    border-radius: 14px;
    border: 1px solid rgba(255,255,255,0.08);
    box-shadow: 0 16px 48px -8px rgba(0,0,0,0.6);
    z-index: 10001;
    width: 310px;
    overflow: hidden;
    user-select: none;
  }
  .editor-panel-header {
    cursor: move;
    padding: 18px 22px 14px;
    border-bottom: 1px solid rgba(255,255,255,0.06);
  }
  .editor-panel-header h3 { color:rgba(255,255,255,0.95); font-size:15px; font-weight:600; margin-bottom:3px; }
  .editor-panel-header p  { color:rgba(255,255,255,0.4);  font-size:12px; }
  .editor-settings { padding: 8px 0; }
  .setting-row { display:flex; flex-direction:column; gap:8px; padding:10px 22px; }
  .setting-top { display:flex; justify-content:space-between; align-items:center; }
  .setting-label { color:rgba(255,255,255,0.7); font-size:13px; font-weight:500; }
  .toggle {
    position:relative; width:42px; height:23px;
    background:rgba(255,255,255,0.1); border-radius:12px;
    cursor:pointer; border:none; transition:background 0.2s;
  }
  .toggle.on { background:#34d399; }
  .toggle::after {
    content:''; position:absolute; width:17px; height:17px;
    background:#fff; border-radius:50%; top:3px; left:3px;
    transition:transform 0.2s cubic-bezier(0.22,1,0.36,1);
    box-shadow:0 1px 3px rgba(0,0,0,0.3);
  }
  .toggle.on::after { transform:translateX(19px); }
  .range-slider {
    width:100%; height:4px; border-radius:2px;
    background:rgba(255,255,255,0.08); outline:none;
    -webkit-appearance:none; cursor:pointer;
  }
  .range-slider::-webkit-slider-thumb {
    -webkit-appearance:none; width:15px; height:15px;
    border-radius:50%; background:#fff; cursor:pointer;
    box-shadow:0 1px 4px rgba(0,0,0,0.3);
  }
  .range-slider::-moz-range-thumb {
    width:15px; height:15px; border-radius:50%; background:#fff;
    border:none; box-shadow:0 1px 4px rgba(0,0,0,0.3);
  }
  .range-value { color:rgba(255,255,255,0.5); font-size:12px; font-variant-numeric:tabular-nums; }
  .style-picker { display:grid; grid-template-columns:repeat(3,1fr); gap:6px; }
  .style-option {
    display:flex; flex-direction:column; align-items:center; gap:5px;
    padding:8px 4px 7px; border-radius:8px;
    border:1px solid rgba(255,255,255,0.07); background:rgba(255,255,255,0.03);
    cursor:pointer; transition:background 0.15s,border-color 0.15s;
    font-family:inherit;
  }
  .style-option:hover { background:rgba(255,255,255,0.07); border-color:rgba(255,255,255,0.14); }
  .style-option.active { background:rgba(255,255,255,0.08); border-color:rgba(255,255,255,0.3); }
  .style-option-preview {
    width:44px; height:26px; border-radius:4px; overflow:hidden; position:relative; flex-shrink:0;
  }
  .style-option-label { font-size:10px; color:rgba(255,255,255,0.5); font-weight:500; letter-spacing:0.04em; text-transform:uppercase; }
  .style-option.active .style-option-label { color:rgba(255,255,255,0.9); }
  /* Mini previews */
  .sp-default { background:#111a15; border:1px solid rgba(255,255,255,0.07); border-left:3px solid #4ade80; }
  .sp-minimal { background:rgba(18,18,22,0.95); border:1px solid rgba(255,255,255,0.09); border-radius:13px; }
  .sp-glass   { background:rgba(255,255,255,0.06); border:1px solid rgba(255,255,255,0.13); border-radius:6px; }
  .sp-toast   { background:#18181b; border:1px solid rgba(255,255,255,0.06); border-top:2px solid #4ade80; border-radius:2px; }
  .sp-bold    { background:#4ade80; border-radius:4px; }
  .sp-retro   { background:#0d0d0d; border:1px solid #4ade80; border-radius:0; box-shadow:2px 2px 0 #4ade80; }
  .sp-dot { position:absolute; width:6px; height:6px; border-radius:50%; background:currentColor; top:50%; right:8px; transform:translateY(-50%); }
  .sp-line { position:absolute; left:8px; right:18px; height:2px; background:currentColor; border-radius:1px; }
  .sp-line-top { top:8px; width:55%; right:auto; }
  .sp-line-bot { top:14px; width:35%; right:auto; background:rgba(255,255,255,0.25); }
  .editor-divider { height:1px; background:rgba(255,255,255,0.06); margin:0; }
  .editor-btns { display:flex; gap:8px; padding:14px 22px 18px; border-top:1px solid rgba(255,255,255,0.06); }
  .e-btn { flex:1; padding:9px; border:none; border-radius:8px; font-family:inherit; font-weight:500; font-size:13px; cursor:pointer; transition:background 0.15s,color 0.15s; }
  .e-btn.save   { background:#fff; color:#0a0a0a; }
  .e-btn.save:hover { background:rgba(255,255,255,0.88); }
  .e-btn.cancel { background:rgba(255,255,255,0.06); color:rgba(255,255,255,0.6); border:1px solid rgba(255,255,255,0.08); }
  .e-btn.cancel:hover { background:rgba(255,255,255,0.1); color:rgba(255,255,255,0.8); }
</style>
