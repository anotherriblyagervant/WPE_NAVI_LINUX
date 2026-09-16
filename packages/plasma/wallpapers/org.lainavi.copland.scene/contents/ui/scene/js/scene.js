(() => {
  "use strict";

  const SCENE_W = 1920;
  const SCENE_H = 1080;
  const RESIZE_DEBOUNCE_MS = 100;
  const TICK_MS = 250;
  const BOOT_SCALE_MAX_ATTEMPTS = 40;
  const MONTHS = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  const scene = document.getElementById("scene");
  if (!scene) return;

  const elH = document.getElementById("calH");
  const elM = document.getElementById("calM");
  const elS = document.getElementById("calS");
  const elDay = document.getElementById("calDay");
  const elDayIcon = document.getElementById("calDayIcon");
  const elMonth = document.getElementById("calMonth");
  const elGrid = document.getElementById("calGrid");

  // Live IANA zones (matches Pixels SoT better than fixed hour offsets).
  const worldClocks = [
    {
      timeZone: "Asia/Tokyo",
      timeNode: document.getElementById("city1Time"),
      dayNode: document.getElementById("city1Day"),
      monthNode: document.getElementById("city1Month")
    },
    {
      timeZone: "America/New_York",
      timeNode: document.getElementById("city2Time"),
      dayNode: document.getElementById("city2Day"),
      monthNode: document.getElementById("city2Month")
    }
  ].filter(function (c) {
    return c.timeNode && c.dayNode && c.monthNode;
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
    c.lastTime = "";
    c.lastDay = "";
    c.lastMonth = "";
  });

  const pad = (n) => String(n).padStart(2, "0");

  let resizeTimer = 0;
  let bootScaleTimer = 0;
  let lastCalendarKey = "";
  let lastScale = NaN;
  let lastLocalSecond = -1;

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
    elH.textContent = pad(now.getHours());
    elM.textContent = pad(now.getMinutes());
    elS.textContent = pad(now.getSeconds());
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
        const timeText = bag.hour + ":" + bag.minute + ":" + bag.second;
        if (timeText !== c.lastTime) {
          c.lastTime = timeText;
          c.timeNode.textContent = timeText;
        }
        if (bag.day !== c.lastDay) {
          c.lastDay = bag.day;
          c.dayNode.textContent = bag.day;
        }
        if (bag.month !== c.lastMonth) {
          c.lastMonth = bag.month;
          c.monthNode.textContent = bag.month;
        }
      } catch (err) {
        /* keep last values */
      }
    }
  }

  function tick() {
    try {
      const now = new Date();
      const sec = now.getSeconds();
      if (sec === lastLocalSecond) return;
      lastLocalSecond = sec;

      updateClock(now);
      buildCalendar(now);
      updateWorldClocks(now);
    } catch (err) {
      /* Keep wallpaper visible even if calendar update fails */
    }
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

  bootScale();
  tick();
  window.addEventListener("resize", onResize);
  window.setInterval(tick, TICK_MS);

  if (typeof ResizeObserver !== "undefined") {
    try {
      const ro = new ResizeObserver(onResize);
      ro.observe(document.documentElement);
    } catch (err) {
      /* ignore */
    }
  }
})();
