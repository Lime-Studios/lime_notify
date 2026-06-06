// notifications.svelte.js — shared reactive state via Svelte 5 runes

const VALID_STYLES = ['default', 'minimal', 'glass', 'toast', 'bold', 'retro'];
const MAX_NOTIFY = 5;

function createStore() {
  let notifications = $state([]);
  let soundOn       = $state(true);
  let soundVol      = $state(0.5);   // always 0–1
  let notifScale    = $state(1);
  let notifStyle    = $state('default');
  let position      = $state({ x: 95, y: 5 });

  // Audio
  let audioCtx    = null;
  let audioBuffer = null;

  function getAudioContext() {
    if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    if (audioCtx.state === 'suspended') audioCtx.resume();
    return audioCtx;
  }

  function loadSound() {
    // alert.ogg sits next to index.html in the dist root
    fetch('./alert.ogg')
      .then(r => r.arrayBuffer())
      .then(buf => getAudioContext().decodeAudioData(buf))
      .then(decoded => { audioBuffer = decoded; })
      .catch(() => {});
  }

  function playSound() {
    if (!soundOn || !audioBuffer) return;
    try {
      const ctx  = getAudioContext();
      const src  = ctx.createBufferSource();
      const gain = ctx.createGain();
      src.buffer = audioBuffer;
      gain.gain.value = Math.max(0, Math.min(1, soundVol));
      src.connect(gain);
      gain.connect(ctx.destination);
      src.start(0);
    } catch (_) {}
  }

  function applyStyle(style) {
    if (!VALID_STYLES.includes(style)) style = 'default';
    notifStyle = style;
  }

  function applyScale(scale) {
    notifScale = scale;
  }

  function applyPosition(x, y) {
    position = { x, y };
  }

  function dismiss(id) {
    const n = notifications.find(n => n.id === id);
    if (!n || n.removing) return;
    clearTimeout(n.timer);
    notifications = notifications.map(n => n.id === id ? { ...n, removing: true } : n);
    setTimeout(() => {
      notifications = notifications.filter(n => n.id !== id);
    }, 300);
  }

  // sound and volume from NUI messages come as raw booleans / 0–100 integers.
  // The store always holds soundVol as 0–1. Callers pass vol as 0–100.
  function showNotification(type, title, message, duration = 5000, pos, snd, vol, style) {
    if (snd !== undefined) soundOn = snd;
    if (vol !== undefined) soundVol = vol / 100;   // convert 0–100 → 0–1
    if (pos?.x !== undefined) applyPosition(pos.x, pos.y);

    const useStyle = (style && VALID_STYLES.includes(style)) ? style : notifStyle;

    // Enforce max visible
    const active = notifications.filter(n => !n.removing);
    if (active.length >= MAX_NOTIFY) dismiss(active[0].id);

    const id = Date.now() + Math.random();
    const timer = setTimeout(() => dismiss(id), duration);

    notifications = [...notifications, {
      id,
      type:     type    || 'info',
      title:    title   || 'Notification',
      message:  message || '',
      duration,
      style:    useStyle,
      removing: false,
      timer,
    }];

    playSound();
  }

  return {
    get notifications() { return notifications; },
    get soundOn()       { return soundOn; },
    get soundVol()      { return soundVol; },
    get notifScale()    { return notifScale; },
    get notifStyle()    { return notifStyle; },
    get position()      { return position; },

    // Setters — callers in App.svelte pass already-converted values (0–1 for vol, bool for sound)
    set soundOn(v)    { soundOn = v; },
    set soundVol(v)   { soundVol = v; },   // expects 0–1
    set notifScale(v) { notifScale = v; },
    set notifStyle(v) { applyStyle(v); },

    loadSound,
    showNotification,
    dismiss,
    applyStyle,
    applyScale,
    applyPosition,
    VALID_STYLES,
  };
}

export const store = createStore();
