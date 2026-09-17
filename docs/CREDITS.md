# Credits

Third-party assets bundled in the wallpaper package (also used for optional
system fonts — install from the same paths; see README):

| Asset | Source | Role |
|---|---|---|
| `camera2.gif` | [LAIN Navi](https://steamcommunity.com/sharedfiles/filedetails/?id=3152101588) preset (`3152101588`) | Camera 2 window |
| `copland-logo.gif` | same | Copland OS Enterprise window |
| `smile.gif` | same (runtime copy mildly optimized with gifsicle; 14 frames / 500×352 kept) | SMILE window |
| `Pixeltype.ttf` | [Pixels](https://steamcommunity.com/sharedfiles/filedetails/?id=3122339805) (`3122339805`) | Title / display font (scene + optional Plasma fonts) |
| `FreePixel.ttf` | same | Body font (scene + optional Plasma fonts) |
| LOG ID/task lists, NUMBERS columns, WORDS pools (`words-data.js`) | same (behavior ported from scene scripts) | Fake LOG / WORDS / NUMBERS |

Project-authored chrome (Apache-2.0):

| Asset | Role |
|---|---|
| `packages/color-schemes/CoplandLain.colors` | Plasma color scheme (LAIN palette; single source) |
| `packages/plasma/desktoptheme/org.lainavi.copland/` | Plasma style (inherits active scheme; no duplicate colors) |
| `packages/aurorae/themes/org.lainavi.copland/` | Aurorae window decoration (scene chrome palette; SVGs from `tools/generate-aurorae.py`) |
| `tools/generate-aurorae.py` | Regenerates Aurorae SVG/metadata (committed outputs are what get installed) |

Workshop items by **Gav** (see wallpaper pages for profile).  
Pixels credits (from Workshop description) also mention assets inspired by bemuse and others used in the base scene defaults.

Workshop content remains subject to its authors’ / Steam Workshop terms.  
Project code in this repository is Apache-2.0.
