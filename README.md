# Copland / LAIN desktop for Bazzite

A Copland OS–inspired Plasma desktop look, based on the awesome Wallpaper Engine wallpaper
[LAIN Navi](https://steamcommunity.com/sharedfiles/filedetails/?id=3152101588) (built on [Pixels](https://steamcommunity.com/sharedfiles/filedetails/?id=3122339805))
made by Gav (I`ll not past direct link to his/her profile because of privacy, check the wallpaper page, but know that I`m grateful to you for good scene and inspiration).

**Stage 1 goal:** the scene lives on your desktop by itself — clocks, calendar, fake system log, cycling words and numbers, LAIN art in Copland-style windows. You set it up once; you don’t click around inside the wallpaper.

Later stages (not this repo’s job yet) can turn pieces into real apps and a fuller NAVI-like environment.

## Works on

- Bazzite + KDE Plasma 6 (Wayland)
- Install as the Plasma user you want themed (writes only that user’s `~/.local`)
- Missing runtime tools (e.g. Qt WebEngine) may be layered with `rpm-ostree` when needed; Copland configs stay user-level

## Status

**Wallpaper** (package **1.1**): Copland layout, LAIN art/fonts, live clock + calendar, world clocks (Tokyo / NYC), cycling fake LOG / WORDS / NUMBERS. Authored at **1920×1080** and **letterboxes** per screen (no crop).

**Chrome** (1.2): optional user-level **color scheme** (palette for apps/panels), **Plasma style** (inherits that scheme), **Aurorae window decorations** with hardcoded scene fills (cyan tiles; inactive stays dark — not ColorScheme-remapped), and the same **Pixeltype / FreePixel** fonts from the wallpaper package.

**Installer** (1.3): `./install.sh` / `./uninstall.sh` ensure host tools when missing, register all chrome + wallpaper configs into System Settings (no auto-apply), and remove only Copland files on uninstall (host tools are listed, not removed).

### Install / uninstall

From the repo root on the **Plasma host** (not as root; not only inside Distrobox):

```bash
./install.sh          # ensure tools + register all configs for Settings
./install.sh --dry-run
./uninstall.sh        # remove Copland files/packages only (never removes host tools)
```

Options: `-v` / `--verbose`, `--skip-tools` (install only; register configs without checking or layering host tools).

Install exit codes: `0` all good, `2` configs registered but a host tool is still missing, `1` could not run.

**What install does**

1. Checks host tools (`kpackagetool6` must already exist; `qt6-qtwebengine` / `fontconfig` are layered with `rpm-ostree` only if absent). Tools already present are skipped. Layering needs an **active local session owned by a `wheel` member** — otherwise the script does not try to collect a password, it prints the exact `sudo rpm-ostree install …` command instead. Layered packages need a **reboot** before the wallpaper works.
2. Registers into your `~/.local` so they appear in System Settings (this happens even if a tool is missing — only the wallpaper needs Qt WebEngine):
   - Fonts → *Fonts* (Pixeltype / Free Pixel — registered via Plasma fontinst into `~/.local/share/fonts`)
   - Color scheme → *Colors* (Copland LAIN)
   - Wallpaper package → *Wallpaper* (Copland LAIN Scene)
   - Plasma style → *Plasma Style* (Copland LAIN)
   - Aurorae theme → *Window Decorations* (Copland LAIN)
3. Writes `~/.local/share/copland-lain/install-manifest` (for uninstall).
4. Does **not** switch your active look — you choose everything in Settings.

**After install, pick in System Settings**

1. Wallpaper → **Copland LAIN Scene** (per screen if needed)
2. Colors → **Copland LAIN**
3. Fonts → **Pixeltype** under General (optional); **Free Pixel** under Fixed width (it is monospace). Re-open System Settings if a chooser was already open.
4. Plasma Style → **Copland LAIN**
5. Window Decorations → engine **Aurorae** (**v1**, not Aurorae 2) → theme **Copland LAIN**

After CSS/JS-only wallpaper tweaks, reselect the wallpaper if Plasma still shows a cached scene.

**What uninstall does**

- Removes the Copland wallpaper/Plasma packages and files listed in the manifest (fonts, colors, Aurorae copy, manifest).
- Does **not** uninstall host tools. If `install.sh` layered any (recorded in the manifest), it prints their names and `sudo rpm-ostree uninstall …` commands for you to run manually (reboot after ostree deploy).
- Does **not** change active Settings selections — if the look still shows Copland, reselect your previous theme there.

### Editing Aurorae SVGs

Do not hand-edit `packages/aurorae/themes/org.lainavi.copland/*.svg`. Change palette or glyphs in `tools/generate-aurorae.py`, run `python3 tools/generate-aurorae.py`, commit the regenerated SVGs + metadata, then re-run `./install.sh` (or copy the theme dir) and refresh decorations in Settings.

## Roadmap (simple → harder)

- [x] Wallpaper that shows the Copland window layout (static)
- [x] LAIN art and pixel fonts
- [x] Live clock and calendar
- [x] World clocks (Tokyo / NYC)
- [x] Fake system log, words, and numbers
- [x] Scaling for real resolution / multi-monitor
- [x] Matching Plasma colors, fonts, and panel chrome
- [x] Matching Aurorae window decorations
- [x] Install and uninstall that won’t wreck your main desktop
- [ ] Test-account workflow (`lain_test`)
- [ ] Docs clear enough for someone else on Bazzite

## Credits

Visual design and assets come from the Steam Workshop items linked above (by Gav).
Bundled files are listed in [docs/CREDITS.md](./docs/CREDITS.md).

## License

Project code: Apache-2.0 — see `LICENSE`.

Workshop art and fonts remain subject to their authors’ / Steam Workshop terms.
