(() => {
  "use strict";

  const SCENE_W = 1920;
  const SCENE_H = 1080;
  const RESIZE_DEBOUNCE_MS = 100;

  const scene = document.getElementById("scene");
  if (!scene) return;

  let resizeTimer = 0;

  function scaleScene() {
    let scale = Math.min(window.innerWidth / SCENE_W, window.innerHeight / SCENE_H);
    // Avoid subpixel scale blur on pixel fonts at native 1080p
    if (Math.abs(scale - 1) < 0.015) {
      scale = 1;
    } else {
      // Snap to 0.5% steps to reduce fractional rasterization mush
      scale = Math.round(scale * 200) / 200;
    }
    scene.style.transform = `scale(${scale})`;
  }

  function onResize() {
    window.clearTimeout(resizeTimer);
    resizeTimer = window.setTimeout(scaleScene, RESIZE_DEBOUNCE_MS);
  }

  scaleScene();
  window.addEventListener("resize", onResize);
})();
