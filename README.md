# Copland / LAIN desktop for Bazzite

A Copland OS–inspired Plasma desktop look, based on the awesome Wallpaper Engine wallpaper
[LAIN Navi](https://steamcommunity.com/sharedfiles/filedetails/?id=3152101588) (built on [Pixels](https://steamcommunity.com/sharedfiles/filedetails/?id=3122339805))
made by Gav (I\`ll not past direct link to his/her profile because of privacy, check the wallpaper page, but know that I`m grateful to you for good scene and inspiration).

**Stage 1 goal:** the scene lives on your desktop by itself — clocks, calendar, fake system log, cycling words and numbers, LAIN art in Copland-style windows. You set it up once; you don’t click around inside the wallpaper.

Later stages (not this repo’s job yet) can turn pieces into real apps and a fuller NAVI-like environment.

## Works on

- **Bazzite** (Kinoite-style) + **KDE Plasma 6** on **Wayland**
- Install as the Plasma user you want themed (writes only that user’s `~/.local`)
- Missing runtime tools (e.g. Qt WebEngine) may be layered with `rpm-ostree`; Copland configs stay user-level
- Other distros: theme packages may work by hand; the installer tool path is Bazzite/`rpm-ostree` only

## Status

| Piece | Version | What you get |
|---|---|---|
| Wallpaper | **1.1** | Copland layout, LAIN art/fonts, live clock + calendar, world clocks (Tokyo / NYC), fake LOG / WORDS / NUMBERS. Authored at **1920×1080**, **letterboxes** per screen (no crop). |
| Chrome | **1.2** | Color scheme, Plasma style, Aurorae decorations (hardcoded scene fills; inactive stays dark), Pixeltype / Free Pixel fonts |
| Installer | **1.3** | `./install.sh` / `./uninstall.sh` — ensure tools when missing, register everything into System Settings (**no auto-apply**), remove only Copland files on uninstall |

## Quick start (someone else on Bazzite)

Do this on the **Plasma host** as the user whose desktop you want themed. Use a normal Konsole/terminal on Bazzite — **not** only inside Distrobox, and **not** as root.

1. **Get the repo**
   ```bash
   git clone https://github.com/anotherriblyagervant/WPE_NAVI_LINUX.git
   cd WPE_NAVI_LINUX
   ```
2. **Install** (register configs + layer missing tools if your user can):
   ```bash
   ./install.sh
   ```
   Optional: `./install.sh --dry-run` first. If tools are already present: `./install.sh --skip-tools`.
3. **Reboot** if the script layered anything with `rpm-ostree` (it will say so). Qt WebEngine is only usable in the new deployment after reboot.
4. **Pick the look in System Settings** (install does not switch themes for you):
   1. Wallpaper → **Copland LAIN Scene** (repeat per screen if needed)
   2. Colors → **Copland LAIN**
   3. Fonts → **Pixeltype** (General, optional); **Free Pixel** (Fixed width). Re-open Settings if a chooser was already open.
   4. Plasma Style → **Copland LAIN**
   5. Window Decorations → engine **Aurorae** (**v1**, not Aurorae 2) → theme **Copland LAIN**

Safe sandbox (separate Plasma user): [docs/TESTING.md](./docs/TESTING.md).

### Prerequisites

- Logged into Plasma (Wayland) as the target user
- `kpackagetool6` already on the system (normal on Bazzite KDE)
- To **auto-layer** missing packages: an **active local session** owned by a **`wheel`** member. Otherwise the script prints the exact `sudo rpm-ostree install …` command for you to run, then re-run `./install.sh` (or `--skip-tools` after reboot).

### Install options and exit codes

```bash
./install.sh              # tools + register
./install.sh --dry-run
./install.sh --skip-tools # register only
./install.sh -v           # verbose
./uninstall.sh
```

| Exit | Meaning |
|---|---|
| `0` | Configs registered, tools present |
| `2` | Configs registered, but a host tool is still missing (wallpaper needs Qt WebEngine) |
| `1` | Could not run (bad options, missing Plasma tooling, unwritable home) |

**What install does**

1. Checks host tools (`kpackagetool6` required; layers `qt6-qtwebengine` / `fontconfig` via `rpm-ostree` only if absent).
2. Registers into `~/.local`: fonts (via Plasma fontinst), color scheme, wallpaper package, Plasma style, Aurorae theme.
3. Writes `~/.local/share/copland-lain/install-manifest` for uninstall.
4. Does **not** change your active wallpaper, colors, fonts, style, or decorations.

After CSS/JS-only wallpaper tweaks, reselect the wallpaper if Plasma still shows a cached scene.

### Uninstall

```bash
./uninstall.sh
```

- Removes Copland packages/files listed in the manifest (fonts, colors, Aurorae copy, Plasma/wallpaper packages, state dir).
- Does **not** uninstall host tools. If install layered any, it prints `sudo rpm-ostree uninstall …` for you (reboot after deploy).
- Does **not** reset active Settings — reselect your previous theme if Copland is still showing.

## Troubleshooting

| Symptom | What to try |
|---|---|
| Blank / fallback wallpaper, or “QtWebEngine” errors | Install exit was `2`, or you haven’t rebooted after `rpm-ostree` layered `qt6-qtwebengine`. Confirm the QML module exists, reboot, reselect **Copland LAIN Scene**. |
| Script won’t layer packages / asks you to run `sudo` | User not in `wheel`, or no active local graphical session. Run the printed `rpm-ostree` command, reboot, then `./install.sh --skip-tools`. |
| Ran install “inside Distrobox” and nothing showed up | Scripts must run on the **host** Plasma user. Distrobox can’t register that user’s Plasma packages the way you expect. |
| Fonts missing from the chooser | Re-open System Settings after install. Families are **Pixeltype** and **Free Pixel** (from fontinst into `~/.local/share/fonts`). |
| Window decorations look wrong / inactive titlebars go white | Use Aurorae **v1** (not Aurorae 2). Theme name **Copland LAIN**. |
| Look still Copland after uninstall | Uninstall doesn’t change active selections — pick another wallpaper / colors / decorations in Settings. |
| Want to test without risking your main desktop | Follow [docs/TESTING.md](./docs/TESTING.md) (`lain_test` user). |

## Editing Aurorae SVGs

Do not hand-edit `packages/aurorae/themes/org.lainavi.copland/*.svg`. Change palette or glyphs in `tools/generate-aurorae.py`, run `python3 tools/generate-aurorae.py`, commit the regenerated SVGs + metadata, then re-run `./install.sh` (or copy the theme dir) and refresh decorations in Settings.

## Roadmap

- [x] Wallpaper that shows the Copland window layout (static)
- [x] LAIN art and pixel fonts
- [x] Live clock and calendar
- [x] World clocks (Tokyo / NYC)
- [x] Fake system log, words, and numbers
- [x] Scaling for real resolution / multi-monitor
- [x] Matching Plasma colors, fonts, and panel chrome
- [x] Matching Aurorae window decorations
- [x] Install and uninstall that won’t wreck your main desktop
- [x] Test-account workflow (`lain_test`)
- [x] Docs clear enough for someone else on Bazzite

## Credits

Visual design and assets come from the Steam Workshop items linked above (by Gav).
Bundled files are listed in [docs/CREDITS.md](./docs/CREDITS.md).

## License

Project code: Apache-2.0 — see `LICENSE`.

Workshop art and fonts remain subject to their authors’ / Steam Workshop terms.
