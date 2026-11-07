(() => {
  "use strict";

  const LOG_ROWS = 21;
  const MONTHS = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  // Pixels SoT pools (3122339805).
  const LOG_IDS = [
    "338213", "287798", "971321", "300110", "756060", "526058", "817287",
    "490509", "132122", "931222", "845608", "739596", "415818", "249769",
    "421314", "178397", "938855", "622157", "266072", "373851"
  ];
  const LOG_TASKS = [
    "Service Host: DNS Client",
    "Application Frame Host",
    "Service Host: Local Service",
    "System Interrupts",
    "Service Host: Local System",
    "Session Manager",
    " ",
    "Make My Day",
    "Service Host: Event Log",
    "System Setting Broker",
    "explorer",
    "Service Host: DHCP Client",
    "Service Host: Network Connection Broker",
    "Runtime Broker",
    "Service Host: Network Location Awareness",
    "Service Host: Network Store Interface Service",
    "SYSTEM",
    "Service Host: Network Connected Devices",
    "Not Found",
    "Service Host: Network List Service"
  ];
  const NUM_COLS = [
    [98246151, 36287797, 25324785, 93131225, 29545298, 12754167, 54843095, 33058221, 76256912],
    [47948253, 85153922, 24526578, 14431864, 89273665, 30364993, 73701901, 93963211, 83561299],
    [46660625, 17851525, 98779248, 60244042, 41699268, 90777138, 74665774, 43481580, 33464182]
  ];
  // Highlighted rows (0-based): 7th, 4th, 8th — stay fixed while values rotate.
  const NUM_HI_ROWS = [6, 3, 7];

  const scene = document.getElementById("scene");
  if (!scene) return;

  const rawOpts =
    typeof window !== "undefined" && window.COPLAND_SCENE_OPTIONS
      ? window.COPLAND_SCENE_OPTIONS
      : {};
  const sceneOpts = {
    enterprise: rawOpts.enterprise === true,
    numbers: rawOpts.numbers === true
  };

  function removeWindow(selector) {
    const el = scene.querySelector(selector);
    if (el && el.parentNode) el.parentNode.removeChild(el);
  }

  if (sceneOpts.enterprise) {
    const logo = scene.querySelector(".win-eyes img[data-src]");
    if (logo) {
      logo.setAttribute("src", logo.getAttribute("data-src"));
      logo.removeAttribute("data-src");
    }
  } else {
    removeWindow(".win-eyes");
  }
  if (!sceneOpts.numbers) removeWindow(".win-numbers");

  const scaleRoot = document.documentElement;
  const SCENE_W = 1920;
  const SCENE_H = 1080;
  const RESIZE_DEBOUNCE_MS = 50;
  let lastFitKey = "";
  let fitTimer = 0;

  function applyFit(w, h) {
    w = Math.round(Number(w) || 0);
    h = Math.round(Number(h) || 0);
    if (w < 2 || h < 2) return false;

    // Letterbox (contain): fit 1920×1080 inside the WebEngine widget without cropping.
    const scale = Math.min(w / SCENE_W, h / SCENE_H);
    const key = w + "x" + h + ":" + scale;
    if (key === lastFitKey) return true;
    lastFitKey = key;

    const ox = Math.round((w - SCENE_W * scale) / 2);
    const oy = Math.round((h - SCENE_H * scale) / 2);
    scaleRoot.style.setProperty("--scene-scale", String(scale));
    scaleRoot.style.setProperty("--scene-ox", ox + "px");
    scaleRoot.style.setProperty("--scene-oy", oy + "px");
    return true;
  }

  function fitFromWindow() {
    let w = window.innerWidth;
    let h = window.innerHeight;
    if (window.visualViewport && window.visualViewport.width >= 2) {
      w = Math.min(w, window.visualViewport.width);
      h = Math.min(h, window.visualViewport.height);
    }
    if (document.documentElement.clientWidth >= 2) {
      w = Math.min(w, document.documentElement.clientWidth);
      h = Math.min(h, document.documentElement.clientHeight);
    }
    return applyFit(w, h);
  }

  function fitScene() {
    fitFromWindow();
  }

  function onFitResize() {
    window.clearTimeout(fitTimer);
    fitTimer = window.setTimeout(fitScene, RESIZE_DEBOUNCE_MS);
  }

  const elH = document.getElementById("calH");
  const elM = document.getElementById("calM");
  const elS = document.getElementById("calS");
  const elDay = document.getElementById("calDay");
  const elDayIcon = document.getElementById("calDayIcon");
  const elMonth = document.getElementById("calMonth");
  const elGrid = document.getElementById("calGrid");

  // Live IANA zones. Defaults match Pixels SoT (Tokyo / NYC); installer may override via options.js.
  const worldClockDefaults = [
    { label: "TOKYO", timeZone: "Asia/Tokyo" },
    { label: "NYC", timeZone: "America/New_York" }
  ];
  const worldClockOpts = Array.isArray(rawOpts.worldClocks)
    ? rawOpts.worldClocks
    : [];

  function worldClockConfig(index) {
    const fallback = worldClockDefaults[index] || worldClockDefaults[0];
    const raw = worldClockOpts[index] || {};
    const label =
      typeof raw.label === "string" && raw.label.trim()
        ? raw.label.trim()
        : fallback.label;
    const timeZone =
      typeof raw.timeZone === "string" && raw.timeZone.trim()
        ? raw.timeZone.trim()
        : fallback.timeZone;
    return { label: label, timeZone: timeZone };
  }

  const worldClocks = [
    {
      cfg: worldClockConfig(0),
      nameNode: document.getElementById("city1Name"),
      timeNode: document.getElementById("city1Time"),
      hNode: document.getElementById("city1H"),
      minNode: document.getElementById("city1Min"),
      secNode: document.getElementById("city1Sec"),
      dayNode: document.getElementById("city1Day"),
      monthNode: document.getElementById("city1Month")
    },
    {
      cfg: worldClockConfig(1),
      nameNode: document.getElementById("city2Name"),
      timeNode: document.getElementById("city2Time"),
      hNode: document.getElementById("city2H"),
      minNode: document.getElementById("city2Min"),
      secNode: document.getElementById("city2Sec"),
      dayNode: document.getElementById("city2Day"),
      monthNode: document.getElementById("city2Month")
    }
  ].filter(function (c) {
    return c.hNode && c.minNode && c.secNode && c.dayNode && c.monthNode;
  });

  worldClocks.forEach(function (c) {
    c.timeZone = c.cfg.timeZone;
    if (c.nameNode) c.nameNode.textContent = c.cfg.label;
    if (c.timeNode) {
      c.timeNode.setAttribute("aria-label", c.cfg.label + " time");
    }
    try {
      c.fmt = new Intl.DateTimeFormat("en-US", {
        timeZone: c.timeZone,
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        hourCycle: "h23",
        day: "2-digit",
        month: "long"
      });
    } catch (err) {
      /* Invalid IANA id — fall back so the rest of the scene still runs. */
      c.timeZone = "UTC";
      c.fmt = new Intl.DateTimeFormat("en-US", {
        timeZone: "UTC",
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        hourCycle: "h23",
        day: "2-digit",
        month: "long"
      });
    }
    c.lastHour = "";
    c.lastMin = "";
    c.lastSec = "";
    c.lastDay = "";
    c.lastMonth = "";
  });

  const pad = (n) => String(n).padStart(2, "0");

  function pick(arr) {
    return arr[(Math.random() * arr.length) | 0];
  }

  function setPreLines(el, text) {
    if (!el) return;
    el.textContent = text;
  }

  function joinRing(buf, count, next) {
    if (count <= 0) return "";
    if (count < LOG_ROWS) {
      let s = buf[0];
      for (let i = 1; i < count; i++) s += "\n" + buf[i];
      return s;
    }
    let s = buf[next];
    for (let i = 1; i < LOG_ROWS; i++) s += "\n" + buf[(next + i) % LOG_ROWS];
    return s;
  }

  const elLogTime = document.getElementById("logTime");
  const elLogId = document.getElementById("logId");
  const elLogTask = document.getElementById("logTask");
  const logTimes = new Array(LOG_ROWS);
  const logIds = new Array(LOG_ROWS);
  const logTasks = new Array(LOG_ROWS);
  let logCount = 0;
  let logNext = 0;

  const numbersEnabled = sceneOpts.numbers;
  const elNums = numbersEnabled
    ? [
        document.getElementById("num1"),
        document.getElementById("num2"),
        document.getElementById("num3")
      ]
    : [];
  const numCols = numbersEnabled
    ? NUM_COLS.map(function (col) {
        return col.slice();
      })
    : [];
  const numSpans = [];

  function initNumColumns() {
    if (!numbersEnabled) return;
    for (let i = 0; i < elNums.length; i++) {
      const el = elNums[i];
      const values = numCols[i];
      if (!el || !values) {
        numSpans[i] = null;
        continue;
      }
      const hiRow = NUM_HI_ROWS[i];
      const spans = [];
      const frag = document.createDocumentFragment();
      for (let r = 0; r < values.length; r++) {
        const span = document.createElement("span");
        span.className = r === hiRow ? "num num--hi" : "num";
        span.textContent = String(values[r]);
        spans.push(span);
        frag.appendChild(span);
      }
      fillGrid(el, frag);
      numSpans[i] = spans;
    }
  }

  const elWords = [
    document.getElementById("words1"),
    document.getElementById("words2"),
    document.getElementById("words3"),
    document.getElementById("words4")
  ];
  const wordPools = (typeof window !== "undefined" && window.COPLAND_WORDS) || null;

  let tickTimer = 0;
  let lastCalendarKey = "";
  let lastCalH = "";
  let lastCalM = "";
  let lastCalS = "";
  let resumeCooldownUntil = 0;
  const RESUME_COOLDOWN_MS = 1500;

  function bumpHeartbeat() {
    window.__coplandBeat = Date.now();
  }

  function resyncClocks() {
    if (tickTimer) {
      window.clearTimeout(tickTimer);
      tickTimer = 0;
    }
    const now = new Date();
    try {
      updateClock(now);
    } catch (err) {
      /* keep wallpaper visible */
    }
    try {
      buildCalendar(now);
    } catch (err) {
      /* keep wallpaper visible */
    }
    try {
      updateWorldClocks(now);
    } catch (err) {
      /* keep wallpaper visible */
    }
    bumpHeartbeat();
    scheduleNextTick();
  }

  function resumeScene() {
    const nowMs = Date.now();
    if (nowMs < resumeCooldownUntil) return;
    resumeCooldownUntil = nowMs + RESUME_COOLDOWN_MS;
    // Catch the clock up if timers were paused. Do not restart GIFs or reshuffle
    // LOG / WORDS / NUMBERS — that blanks a frame and jumps the scene.
    resyncClocks();
  }

  function updateClock(now) {
    if (!elH || !elM || !elS) return;
    const h = pad(now.getHours());
    const m = pad(now.getMinutes());
    const s = pad(now.getSeconds());
    if (h !== lastCalH) {
      lastCalH = h;
      elH.textContent = h;
    }
    if (m !== lastCalM) {
      lastCalM = m;
      elM.textContent = m;
    }
    if (s !== lastCalS) {
      lastCalS = s;
      elS.textContent = s;
    }
  }

  function isDaytime(now) {
    const h = now.getHours();
    return h >= 6 && h < 20;
  }

  function fillGrid(el, frag) {
    if (typeof el.replaceChildren === "function") {
      el.replaceChildren(frag);
      return;
    }
    while (el.firstChild) el.removeChild(el.firstChild);
    el.appendChild(frag);
  }

  function buildCalendar(now) {
    if (!elMonth || !elGrid) return;

    const year = now.getFullYear();
    const month = now.getMonth();
    const today = now.getDate();
    const daytime = isDaytime(now);
    const key = year + "-" + month + "-" + today + "-" + (daytime ? "d" : "n");
    if (key === lastCalendarKey) return;
    lastCalendarKey = key;

    if (elDay) elDay.textContent = pad(today);
    elMonth.textContent = MONTHS[month];
    if (elDayIcon) {
      elDayIcon.classList.toggle("is-day", daytime);
      elDayIcon.classList.toggle("is-night", !daytime);
      elDayIcon.title = daytime ? "day" : "night";
    }

    const firstDow = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const frag = document.createDocumentFragment();

    for (let i = 0; i < firstDow; i++) {
      const empty = document.createElement("span");
      empty.className = "cal-day cal-day--empty";
      empty.setAttribute("aria-hidden", "true");
      frag.appendChild(empty);
    }
    for (let day = 1; day <= daysInMonth; day++) {
      const cell = document.createElement("span");
      cell.className = "cal-day";
      cell.textContent = pad(day);
      if (day === today) cell.classList.add("cal-day--today");
      frag.appendChild(cell);
    }

    fillGrid(elGrid, frag);
  }

  function partsFromFormatter(fmt, now) {
    const bag = {};
    const parts = fmt.formatToParts(now);
    for (let i = 0; i < parts.length; i++) {
      const p = parts[i];
      if (p.type !== "literal") bag[p.type] = p.value;
    }
    return bag;
  }

  function updateWorldClocks(now) {
    for (let i = 0; i < worldClocks.length; i++) {
      const c = worldClocks[i];
      try {
        const bag = partsFromFormatter(c.fmt, now);
        if (!bag.hour || !bag.minute || !bag.second) continue;

        if (bag.hour !== c.lastHour) {
          c.lastHour = bag.hour;
          c.hNode.textContent = bag.hour;
        }
        if (bag.minute !== c.lastMin) {
          c.lastMin = bag.minute;
          c.minNode.textContent = bag.minute;
        }
        if (bag.second !== c.lastSec) {
          c.lastSec = bag.second;
          c.secNode.textContent = bag.second;
        }
        if (bag.day && bag.day !== c.lastDay) {
          c.lastDay = bag.day;
          c.dayNode.textContent = bag.day;
        }
        if (bag.month && bag.month !== c.lastMonth) {
          c.lastMonth = bag.month;
          c.monthNode.textContent = bag.month;
        }
      } catch (err) {
        /* keep last values for this city */
      }
    }
  }

  function updateLog(now) {
    const stamp =
      pad(now.getHours()) + ":" + pad(now.getMinutes()) + ":" + pad(now.getSeconds());

    logTimes[logNext] = stamp;
    logIds[logNext] = pick(LOG_IDS);
    logTasks[logNext] = pick(LOG_TASKS);
    logNext = (logNext + 1) % LOG_ROWS;
    if (logCount < LOG_ROWS) logCount += 1;

    setPreLines(elLogTime, joinRing(logTimes, logCount, logNext));
    setPreLines(elLogId, joinRing(logIds, logCount, logNext));
    setPreLines(elLogTask, joinRing(logTasks, logCount, logNext));
  }

  function updateNumbers() {
    if (!numbersEnabled) return;
    for (let i = 0; i < numCols.length; i++) {
      const col = numCols[i];
      const spans = numSpans[i];
      if (!col || !spans) continue;
      col.push(col.shift());
      for (let r = 0; r < col.length; r++) {
        spans[r].textContent = String(col[r]);
      }
    }
  }

  function buildWordColumn() {
    if (!wordPools) return "—\n—\n—\n—\n—\n—\n—\n—\n—";
    const adj = wordPools.adj;
    const nouns = wordPools.nouns;
    const verbs = wordPools.verbs;
    const adv = wordPools.adverbs;
    // Pixels column pattern: adj, noun, verb, adv, adj, noun, verb, adv, adj
    return [
      pick(adj), pick(nouns), pick(verbs), pick(adv),
      pick(adj), pick(nouns), pick(verbs), pick(adv),
      pick(adj)
    ].join("\n");
  }

  function updateWords() {
    for (let i = 0; i < elWords.length; i++) {
      setPreLines(elWords[i], buildWordColumn());
    }
  }

  function tick() {
    const now = new Date();
    try {
      updateClock(now);
    } catch (err) {
      /* keep wallpaper visible */
    }
    try {
      buildCalendar(now);
    } catch (err) {
      /* keep wallpaper visible */
    }
    try {
      updateWorldClocks(now);
    } catch (err) {
      /* keep wallpaper visible */
    }
    try {
      updateLog(now);
    } catch (err) {
      /* keep wallpaper visible */
    }
    try {
      updateNumbers();
    } catch (err) {
      /* keep wallpaper visible */
    }
    try {
      updateWords();
    } catch (err) {
      /* keep wallpaper visible */
    }
    bumpHeartbeat();
  }

  function scheduleNextTick() {
    // Fire once per second near the boundary instead of polling 4×/s.
    const delay = Math.max(32, 1000 - (Date.now() % 1000) + 8);
    tickTimer = window.setTimeout(function () {
      tick();
      scheduleNextTick();
    }, delay);
  }

  function onVisibilityChange() {
    if (document.visibilityState === "visible") {
      resumeScene();
    }
  }

  function onPageResume() {
    resumeScene();
  }

  /* ---- AUDIO / MPRIS now-playing (lookalike bars; optional spectrum[] hook) ---- */
  const elAudioIdle = document.getElementById("audioIdle");
  const elAudioPlayer = document.getElementById("audioPlayer");
  const elAudioTitle = document.getElementById("audioTitle");
  const elAudioArtist = document.getElementById("audioArtist");
  const elAudioArt = document.getElementById("audioArt");
  const elAudioArtFallback = document.getElementById("audioArtFallback");
  const elAudioBars = document.getElementById("audioBars");

  const AUDIO_BAR_COUNT = 66;
  const AUDIO_BAR_FPS = 18;
  const AUDIO_BAR_SPACING = 0.3; // fraction of bar slot left empty (Simple Audio Bars-ish)

  let mediaStatus = "Stopped";
  let mediaArtUrl = "";
  let mediaSpectrum = null;
  let audioBarTimer = 0;
  let audioBarLevels = new Array(AUDIO_BAR_COUNT);
  let audioBarTargets = new Array(AUDIO_BAR_COUNT);
  let audioBarsLive = false;
  let audioBarColor = "";
  let audioBarCtx = null;
  for (let i = 0; i < AUDIO_BAR_COUNT; i++) {
    audioBarLevels[i] = 0;
    audioBarTargets[i] = 0;
  }

  function setHidden(el, hidden) {
    if (!el) return;
    if (hidden) el.setAttribute("hidden", "");
    else el.removeAttribute("hidden");
  }

  function normalizeMediaStatus(status) {
    const s = String(status || "Stopped").trim().toLowerCase();
    if (s === "playing") return "Playing";
    if (s === "paused") return "Paused";
    return "Stopped";
  }

  function showAudioIdle() {
    setHidden(elAudioIdle, false);
    setHidden(elAudioPlayer, true);
  }

  function showAudioPlayer() {
    setHidden(elAudioIdle, true);
    setHidden(elAudioPlayer, false);
  }

  function setAlbumArt(url) {
    const next = typeof url === "string" ? url.trim() : "";
    if (!elAudioArt) return;
    // Same URL already shown — skip reload/flicker.
    if (next && next === mediaArtUrl && elAudioArt.getAttribute("src") === next) {
      return;
    }
    mediaArtUrl = next;
    if (!mediaArtUrl) {
      elAudioArt.removeAttribute("src");
      setHidden(elAudioArt, true);
      setHidden(elAudioArtFallback, false);
      return;
    }
    elAudioArt.onload = function () {
      setHidden(elAudioArt, false);
      setHidden(elAudioArtFallback, true);
    };
    elAudioArt.onerror = function () {
      elAudioArt.removeAttribute("src");
      setHidden(elAudioArt, true);
      setHidden(elAudioArtFallback, false);
    };
    elAudioArt.src = mediaArtUrl;
  }

  function audioBarFillColor() {
    if (audioBarColor) return audioBarColor;
    audioBarColor =
      getComputedStyle(document.documentElement).getPropertyValue("--base").trim() ||
      "#0083bc";
    return audioBarColor;
  }

  function paintAudioBars() {
    if (!elAudioBars) return;
    if (!audioBarCtx) audioBarCtx = elAudioBars.getContext("2d");
    const ctx = audioBarCtx;
    if (!ctx) return;
    const w = elAudioBars.width;
    const h = elAudioBars.height;
    ctx.clearRect(0, 0, w, h);

    const slot = w / AUDIO_BAR_COUNT;
    const gap = slot * AUDIO_BAR_SPACING;
    const barW = Math.max(1, slot - gap);
    ctx.fillStyle = audioBarFillColor();

    for (let i = 0; i < AUDIO_BAR_COUNT; i++) {
      const level = Math.max(0, Math.min(1, audioBarLevels[i] || 0));
      const barH = Math.max(level > 0.02 ? 2 : 0, Math.round(level * h * 0.92));
      if (barH <= 0) continue;
      const x = Math.round(i * slot + gap * 0.5);
      ctx.fillRect(x, h - barH, Math.floor(barW), barH);
    }
  }

  function seedAudioTargets(fromSpectrum) {
    if (fromSpectrum && fromSpectrum.length) {
      for (let i = 0; i < AUDIO_BAR_COUNT; i++) {
        const src = fromSpectrum[i % fromSpectrum.length];
        audioBarTargets[i] = Math.max(0, Math.min(1, Number(src) || 0));
      }
      return;
    }
    // Lookalike motion: smoothed pseudo-spectrum weighted toward bass bins.
    for (let i = 0; i < AUDIO_BAR_COUNT; i++) {
      const bass = 1 - i / (AUDIO_BAR_COUNT + 8);
      const n = Math.random();
      audioBarTargets[i] = Math.max(0.04, Math.min(1, n * 0.75 + bass * 0.35));
    }
  }

  function stepAudioBars(playing) {
    if (playing) {
      // Real spectrum when provided; otherwise retarget lookalike motion periodically.
      if (mediaSpectrum) seedAudioTargets(mediaSpectrum);
      else if (Math.random() < 0.35) seedAudioTargets(null);
      audioBarsLive = false;
      for (let i = 0; i < AUDIO_BAR_COUNT; i++) {
        audioBarLevels[i] += (audioBarTargets[i] - audioBarLevels[i]) * 0.28;
        if (audioBarLevels[i] > 0.01) audioBarsLive = true;
      }
    } else {
      // Paused: decay in place (freeze-ish).
      audioBarsLive = false;
      for (let i = 0; i < AUDIO_BAR_COUNT; i++) {
        audioBarLevels[i] *= 0.86;
        if (audioBarLevels[i] < 0.01) audioBarLevels[i] = 0;
        else audioBarsLive = true;
      }
    }
    paintAudioBars();
  }

  function stopAudioBarLoop() {
    if (audioBarTimer) {
      window.clearTimeout(audioBarTimer);
      audioBarTimer = 0;
    }
  }

  function clearAudioBars() {
    for (let i = 0; i < AUDIO_BAR_COUNT; i++) audioBarLevels[i] = 0;
    audioBarsLive = false;
    paintAudioBars();
  }

  function scheduleAudioBarLoop() {
    stopAudioBarLoop();
    const playing = mediaStatus === "Playing";
    const paused = mediaStatus === "Paused";
    if (!playing && !paused) {
      clearAudioBars();
      return;
    }
    const tickBars = function () {
      stepAudioBars(mediaStatus === "Playing");
      if (mediaStatus === "Playing" || mediaStatus === "Paused") {
        const stillMoving = mediaStatus === "Playing" || audioBarsLive;
        if (stillMoving) {
          audioBarTimer = window.setTimeout(tickBars, 1000 / AUDIO_BAR_FPS);
        } else {
          audioBarTimer = 0;
          paintAudioBars();
        }
      } else {
        audioBarTimer = 0;
      }
    };
    tickBars();
  }

  function applyMediaState(state) {
    state = state || {};
    const prevStatus = mediaStatus;
    mediaStatus = normalizeMediaStatus(state.status);
    if (Array.isArray(state.spectrum)) mediaSpectrum = state.spectrum;
    else mediaSpectrum = null;

    const title = typeof state.title === "string" ? state.title : "";
    const artist = typeof state.artist === "string" ? state.artist : "";
    const artUrl = typeof state.artUrl === "string" ? state.artUrl : "";
    const statusChanged = prevStatus !== mediaStatus;

    if (mediaStatus === "Stopped") {
      showAudioIdle();
      stopAudioBarLoop();
      clearAudioBars();
      setAlbumArt("");
      return;
    }

    showAudioPlayer();
    if (elAudioTitle) elAudioTitle.textContent = title || "Unknown title";
    if (elAudioArtist) elAudioArtist.textContent = artist || "";
    setAlbumArt(artUrl);

    // Only (re)start the bar timer on status transitions — avoids stutter on 1 Hz metadata.
    if (statusChanged) {
      if (mediaStatus === "Playing") seedAudioTargets(mediaSpectrum);
      scheduleAudioBarLoop();
    } else if (mediaStatus === "Playing" && mediaSpectrum) {
      seedAudioTargets(mediaSpectrum);
    }
  }

  window.__coplandSetMedia = function (state) {
    try {
      applyMediaState(state);
    } catch (err) {
      try {
        showAudioIdle();
      } catch (e2) {
        /* keep wallpaper visible */
      }
    }
  };

  // Start idle; QML bridge pushes MPRIS when available.
  showAudioIdle();
  paintAudioBars();

  initNumColumns();
  fitScene();
  bumpHeartbeat();
  window.addEventListener("resize", onFitResize);
  if (window.visualViewport) {
    window.visualViewport.addEventListener("resize", onFitResize);
  }
  document.addEventListener("visibilitychange", onVisibilityChange);
  window.addEventListener("resume", onPageResume);
  window.addEventListener("pageshow", function (ev) {
    if (ev.persisted) resumeScene();
  });
  tick();
  scheduleNextTick();
})();
