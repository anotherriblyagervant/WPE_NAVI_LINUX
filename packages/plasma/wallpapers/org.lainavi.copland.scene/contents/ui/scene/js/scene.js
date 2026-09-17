(() => {
  "use strict";

  const SCENE_W = 1920;
  const SCENE_H = 1080;
  const RESIZE_DEBOUNCE_MS = 100;
  const BOOT_SCALE_MAX_ATTEMPTS = 40;
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

  const elH = document.getElementById("calH");
  const elM = document.getElementById("calM");
  const elS = document.getElementById("calS");
  const elDay = document.getElementById("calDay");
  const elDayIcon = document.getElementById("calDayIcon");
  const elMonth = document.getElementById("calMonth");
  const elGrid = document.getElementById("calGrid");

  // Live IANA zones (Pixels SoT). DESIGN.md listed fixed offsets for a sample locale.
  const worldClocks = [
    {
      timeZone: "Asia/Tokyo",
      hNode: document.getElementById("city1H"),
      minNode: document.getElementById("city1Min"),
      secNode: document.getElementById("city1Sec"),
      dayNode: document.getElementById("city1Day"),
      monthNode: document.getElementById("city1Month")
    },
    {
      timeZone: "America/New_York",
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
    c.fmt = new Intl.DateTimeFormat("en-US", {
      timeZone: c.timeZone,
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hourCycle: "h23",
      day: "2-digit",
      month: "long"
    });
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

  const elNums = [
    document.getElementById("num1"),
    document.getElementById("num2"),
    document.getElementById("num3")
  ];
  const numCols = NUM_COLS.map(function (col) {
    return col.slice();
  });
  const numSpans = [];

  function initNumColumns() {
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

  let resizeTimer = 0;
  let bootScaleTimer = 0;
  let tickTimer = 0;
  let lastCalendarKey = "";
  let lastScale = NaN;
  let lastCalH = "";
  let lastCalM = "";
  let lastCalS = "";

  function scaleScene() {
    const w = window.innerWidth;
    const h = window.innerHeight;
    if (w < 2 || h < 2) return false;

    let scale = Math.min(w / SCENE_W, h / SCENE_H);
    if (Math.abs(scale - 1) < 0.015) {
      scale = 1;
    } else {
      scale = Math.round(scale * 200) / 200;
    }
    if (scale !== lastScale) {
      lastScale = scale;
      scene.style.transform = "scale(" + scale + ")";
    }
    return true;
  }

  function stopBootScale() {
    if (bootScaleTimer) {
      window.clearInterval(bootScaleTimer);
      bootScaleTimer = 0;
    }
  }

  function onResize() {
    window.clearTimeout(resizeTimer);
    resizeTimer = window.setTimeout(function () {
      if (scaleScene()) stopBootScale();
    }, RESIZE_DEBOUNCE_MS);
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
  }

  function scheduleNextTick() {
    // Fire once per second near the boundary instead of polling 4×/s.
    const delay = Math.max(32, 1000 - (Date.now() % 1000) + 8);
    tickTimer = window.setTimeout(function () {
      tick();
      scheduleNextTick();
    }, delay);
  }

  function bootScale() {
    if (scaleScene()) return;
    let attempts = 0;
    bootScaleTimer = window.setInterval(function () {
      attempts += 1;
      if (scaleScene() || attempts > BOOT_SCALE_MAX_ATTEMPTS) {
        stopBootScale();
      }
    }, 50);
  }

  initNumColumns();
  bootScale();
  tick();
  scheduleNextTick();
  window.addEventListener("resize", onResize);

  if (typeof ResizeObserver !== "undefined") {
    try {
      const ro = new ResizeObserver(onResize);
      ro.observe(document.documentElement);
    } catch (err) {
      /* ignore */
    }
  }
})();
