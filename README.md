# Copland / LAIN desktop for Bazzite

A Copland OS–inspired Plasma desktop look, based on the awesome Wallpaper Engine wallpaper
[LAIN Navi](https://steamcommunity.com/sharedfiles/filedetails/?id=3152101588) (built on [Pixels](https://steamcommunity.com/sharedfiles/filedetails/?id=3122339805))
made by Gav (I`ll not past direct link to his/her profile because of privacy, check the wallpaper page, but know that I`m grateful to you for good scene and inspiration).

**Stage 1 goal:** the scene lives on your desktop by itself — clocks, calendar, fake system log, cycling words and numbers, LAIN art in Copland-style windows. You set it up once; you don’t click around inside the wallpaper.

Later stages (not this repo’s job yet) can turn pieces into real apps and a fuller NAVI-like environment.

## Works on

- Bazzite + KDE Plasma 6 (Wayland)
- User-level install only (nothing layered into the immutable host)

## Status

**Wallpaper** (package **1.1**): Copland layout, LAIN art/fonts, live clock + calendar, world clocks (Tokyo / NYC), cycling fake LOG / WORDS / NUMBERS. Authored at **1920×1080** and **letterboxes** per screen (no crop).

**Chrome** (1.2): optional user-level **color scheme** (palette for apps/panels), **Plasma style** (inherits that scheme), **Aurorae window decorations** with hardcoded scene fills (cyan tiles; inactive stays dark — not ColorScheme-remapped), and the same **Pixeltype / FreePixel** fonts from the wallpaper package. No full installer — apply manually below; this does not replace the later “safe install/uninstall” roadmap item.

### Wallpaper

From the repo root on the Plasma host:

```bash
# Install (first time)
kpackagetool6 --type Plasma/Wallpaper --install \
  packages/plasma/wallpapers/org.lainavi.copland.scene

# Update (already installed)
kpackagetool6 --type Plasma/Wallpaper --upgrade \
  packages/plasma/wallpapers/org.lainavi.copland.scene

# Remove
kpackagetool6 --type Plasma/Wallpaper --remove \
  org.lainavi.copland.scene
```

Then pick **Copland LAIN Scene** in *System Settings → Wallpaper* (per screen if you use more than one). After CSS/JS-only tweaks, reselect the wallpaper if Plasma still shows a cached scene.

### Colors, fonts, and panel chrome (manual)

Run these as the Plasma user you want themed. Nothing is written outside that user’s home.

**1. Fonts** (only copy from the wallpaper package; do not add a second fonts tree):

```bash
mkdir -p ~/.local/share/fonts/copland-lain
cp packages/plasma/wallpapers/org.lainavi.copland.scene/contents/ui/scene/assets/fonts/*.ttf \
  ~/.local/share/fonts/copland-lain/
fc-cache -f ~/.local/share/fonts/copland-lain
```

Then in *System Settings → Fonts*, try **FreePixel** for general/fixed width and **Pixeltype** for small headings if you like. Bitmap-style fonts do not suit every UI control; approximate is fine.

**2. Color scheme** (palette source of truth — apply this before or with the Plasma style):

```bash
mkdir -p ~/.local/share/color-schemes
cp packages/color-schemes/CoplandLain.colors ~/.local/share/color-schemes/
plasma-apply-colorscheme CoplandLain
```

Or choose **Copland LAIN** under *System Settings → Colors*.

**3. Plasma style (panel / plasmoid chrome):**

The theme package has no bundled `colors` file; panel chrome follows the **active** color scheme (step 2). SVGs inherit from Breeze where we did not ship custom assets.

```bash
# Install (first time)
kpackagetool6 --type Plasma/Theme --install \
  packages/plasma/desktoptheme/org.lainavi.copland

# Update
kpackagetool6 --type Plasma/Theme --upgrade \
  packages/plasma/desktoptheme/org.lainavi.copland

# Remove
kpackagetool6 --type Plasma/Theme --remove \
  org.lainavi.copland
```

Then select **Copland LAIN** under *System Settings → Appearance → Plasma Style* (or *Plasma Style*). Your panel layout (floating, thickness, applets) is unchanged; only colors/chrome follow the theme + color scheme.

**4. Window decorations (Aurorae):**

```bash
mkdir -p ~/.local/share/aurorae/themes
cp -a packages/aurorae/themes/org.lainavi.copland \
  ~/.local/share/aurorae/themes/
```

Then pick **Copland LAIN** under *System Settings → Appearance → Window Decorations*.
Prefer the **Aurorae** engine (v1), not **Aurorae 2** — SVG button/title fills are more reliable on v1 in Plasma 6.7. If System Settings flips you back to Aurorae 2, re-run the `kwriteconfig6` commands below.

Or from a terminal (same Plasma user):

```bash
# Prefer the helper when available
# SVG themes are more reliable on Aurorae v1 than v2 on Plasma 6.7
plasma-apply-aurorae org.lainavi.copland 2>/dev/null || {
  kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 \
    --key library org.kde.kwin.aurorae
  kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 \
    --key theme __aurorae__svg__org.lainavi.copland
}
qdbus6 org.kde.KWin /KWin reconfigure
```

After upgrading theme files, re-copy into `~/.local/share/aurorae/themes/` and
reconfigure KWin (or briefly switch decoration away and back) so SVG caches refresh.

**Editing Aurorae SVGs:** do not hand-edit the files under
`packages/aurorae/themes/org.lainavi.copland/*.svg`. Change palette or glyphs in
`tools/generate-aurorae.py`, then run `python3 tools/generate-aurorae.py` from the
repo root and commit the regenerated SVGs + metadata. Install still only needs
the committed theme directory (no generator on the Plasma host).

**Undo chrome:** switch Colors, Plasma Style, and Window Decorations back to Breeze/Vapor (or whatever you used), remove the Plasma style package, delete `~/.local/share/color-schemes/CoplandLain.colors` and `~/.local/share/aurorae/themes/org.lainavi.copland/`, and optionally remove `~/.local/share/fonts/copland-lain/`.

## Roadmap (simple → harder)

- [x] Wallpaper that shows the Copland window layout (static)
- [x] LAIN art and pixel fonts
- [x] Live clock and calendar
- [x] World clocks (Tokyo / NYC)
- [x] Fake system log, words, and numbers
- [x] Scaling for real resolution / multi-monitor
- [x] Matching Plasma colors, fonts, and panel chrome
- [x] Matching Aurorae window decorations
- [ ] Install and uninstall that won’t wreck your main desktop
- [ ] Test-account workflow (`lain_test`)
- [ ] Docs clear enough for someone else on Bazzite



## Credits

Visual design and assets come from the Steam Workshop items linked above (by Gav).
Bundled files are listed in [docs/CREDITS.md](./docs/CREDITS.md).

## License

Project code: Apache-2.0 — see `LICENSE`.

Workshop art and fonts remain subject to their authors’ / Steam Workshop terms.
