// notifications.svelte.js — shared reactive state via Svelte 5 runes

const VALID_STYLES = ['default', 'minimal', 'glass', 'toast', 'bold', 'retro'];
const VALID_TYPES  = { success: 1, error: 1, warning: 1, warn: 1, info: 1, claimed: 1 };
const MAX_VISIBLE = 5;

// Any unregistered type falls back to info
function normalizeType(t) {
  return VALID_TYPES[t] ? t : 'info';
}

// ── Rich text: escape HTML, then apply **bold** and GTA ~x~ color codes ──────
const GTA_COLORS = {
  r: '#ff5d5d', g: '#34d97b', b: '#4da3ff', y: '#ffd34d',
  o: '#ffb324', p: '#c77dff', w: '#ffffff',
};

export function richText(str) {
  if (!str) return '';
  let out = String(str)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  out = out.replace(/\*\*(.+?)\*\*/g, '<b>$1</b>');
  out = out.replace(/~([rgbyopw])~(.*?)(?=~[rgbyopws]~|$)/g,
    (_, c, text) => `<span style="color:${GTA_COLORS[c]}">${text}</span>`);
  out = out.replace(/~s~/g, '');
  return out;
}

function createStore() {
  let notifications = $state([]);   // visible
  let overflow      = $state([]);   // queued beyond MAX_VISIBLE
  let soundOn       = $state(true);
  let soundVol      = $state(0.5);
  let notifScale    = $state(1);
  let notifStyle    = $state('default');
  let position      = $state({ x: 95, y: 5 });

  let audioCtx = null, audioBuffer = null;

  function getAudioContext() {
    if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    if (audioCtx.state === 'suspended') audioCtx.resume();
    return audioCtx;
  }

  function loadSound() {
    fetch('./alert.ogg')
      .then(r => r.arrayBuffer())
      .then(buf => getAudioContext().decodeAudioData(buf))
      .then(d => { audioBuffer = d; })
      .catch(() => {});
  }

  function playSound() {
    if (!soundOn || !audioBuffer) return;
    try {
      const ctx = getAudioContext();
      const src = ctx.createBufferSource();
      const gain = ctx.createGain();
      src.buffer = audioBuffer;
      gain.gain.value = Math.max(0, Math.min(1, soundVol));
      src.connect(gain); gain.connect(ctx.destination);
      src.start(0);
    } catch (_) {}
  }

  const applyStyle    = (s) => { notifStyle = VALID_STYLES.includes(s) ? s : 'default'; };
  const applyScale    = (s) => { notifScale = s; };
  const applyPosition = (x, y) => { position = { x, y }; };

  function promoteOverflow() {
    if (!overflow.length) return;
    const next = overflow[0];
    overflow = overflow.slice(1);
    pushCard(next);
  }

  function finalizeRemove(id) {
    notifications = notifications.filter(n => n.id !== id);
    promoteOverflow();
  }

  function dismiss(id) {
    const n = notifications.find(n => n.id === id);
    if (!n) {
      // might still be queued
      overflow = overflow.filter(q => q.id !== id);
      return;
    }
    if (n.removing) return;
    clearTimeout(n.timer);
    notifications = notifications.map(n => n.id === id ? { ...n, removing: true } : n);
    setTimeout(() => finalizeRemove(id), 300);
  }

  function pushCard(card) {
    if (card.duration > 0) {
      card.timer = setTimeout(() => dismiss(card.id), card.duration);
    }
    notifications = [...notifications, card];
    playSound();
  }

  // duration = 0 → sticky until dismissed
  function showNotification(type, title, message, duration = 5000, pos, snd, vol, style, id) {
    if (snd !== undefined) soundOn = snd;
    if (vol !== undefined) soundVol = vol / 100;
    if (pos?.x !== undefined) applyPosition(pos.x, pos.y);

    const useStyle = (style && VALID_STYLES.includes(style)) ? style : notifStyle;
    type    = normalizeType(type);
    title   = title   || 'Notification';
    message = message || '';

    // Grouping: identical visible card gets a counter instead of a duplicate
    const twin = notifications.find(n =>
      !n.removing && !n.progress &&
      n.type === type && n.title === title && n.message === message
    );
    if (twin) {
      clearTimeout(twin.timer);
      const count = (twin.count || 1) + 1;
      notifications = notifications.map(n =>
        n.id === twin.id ? { ...n, count, bump: (n.bump || 0) + 1 } : n
      );
      if (duration > 0) {
        const t = setTimeout(() => dismiss(twin.id), duration);
        notifications = notifications.map(n => n.id === twin.id ? { ...n, timer: t } : n);
      }
      playSound();
      return twin.id;
    }

    const card = {
      id: id ?? (Date.now() + Math.random()),
      type, title, message,
      titleHtml: richText(title),
      messageHtml: richText(message),
      duration,
      style: useStyle,
      removing: false,
      count: 1,
      progress: false,
      timer: null,
    };

    const active = notifications.filter(n => !n.removing);
    if (active.length >= MAX_VISIBLE) {
      overflow = [...overflow, card];
      return card.id;
    }

    pushCard(card);
    return card.id;
  }

  // Progress notification: fill bar animates 0→100 over duration, then auto-dismiss
  function showProgress(id, title, message, duration = 5000, type = 'info', style) {
    const useStyle = (style && VALID_STYLES.includes(style)) ? style : notifStyle;
    const card = {
      id: id ?? (Date.now() + Math.random()),
      type: normalizeType(type),
      title: title || 'Working…',
      message: message || '',
      titleHtml: richText(title || 'Working…'),
      messageHtml: richText(message || ''),
      duration,
      style: useStyle,
      removing: false,
      count: 1,
      progress: true,
      timer: null,
    };
    const active = notifications.filter(n => !n.removing);
    if (active.length >= MAX_VISIBLE) {
      overflow = [...overflow, card];
    } else {
      pushCard(card);
    }
    return card.id;
  }

  return {
    get notifications() { return notifications; },
    get overflowCount() { return overflow.length; },
    get soundOn()       { return soundOn; },
    get soundVol()      { return soundVol; },
    get notifScale()    { return notifScale; },
    get notifStyle()    { return notifStyle; },
    get position()      { return position; },

    set soundOn(v)  { soundOn = v; },
    set soundVol(v) { soundVol = v; },

    loadSound,
    showNotification,
    showProgress,
    dismiss,
    applyStyle,
    applyScale,
    applyPosition,
    VALID_STYLES,
  };
}

export const store = createStore();
