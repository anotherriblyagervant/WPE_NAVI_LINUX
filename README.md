# Copland / LAIN desktop for Bazzite

A Copland OS–inspired Plasma desktop look, based on the awesome Wallpaper Engine wallpaper
[LAIN Navi](https://steamcommunity.com/sharedfiles/filedetails/?id=3152101588) (built on [Pixels](https://steamcommunity.com/sharedfiles/filedetails/?id=3122339805))
made by Gav (I\`ll not past direct link to his/her profile because of privacy, check the wallpaper page, but know that I`m grateful to you for good scene and inspiration).

**Stage 1** shipped a static Copland scene (clocks, calendar, fake LOG / WORDS / NUMBERS, LAIN art). **Stage 2** (this repo, theme **2.x**) adds optional scene pieces and, later, interactive modules — still the same visual identity, not a separate project.

By default, **Copland OS Enterprise** and **NUMBERS** are off; **WORLD CLOCK** shows Tokyo and NYC. The installer asks (or you pass flags) to change those.

**AUDIO** shows MPRIS now-playing (title, artist, album art) when a player is Playing/Paused, with lookalike spectrum bars while Playing. With nothing playing it shows “No audio playing.” Bars are visual (not a desktop FFT).

## Works on

- **Bazzite** (Kinoite-style) + **KDE Plasma 6** on **Wayland**
- Install as the Plasma user you want themed (writes only that user’s `~/.local`)
- Missing runtime tools (e.g. Qt WebEngine) may be layered with `rpm-ostree`; Copland configs stay user-level
- Other distros: theme packages may work by hand; the installer tool path is Bazzite/`rpm-ostree` only

## Status

| Piece | Version | What you get |
|---|---|---|
| Wallpaper | **2.0** | Copland layout, LAIN art/fonts, live clock + calendar, configurable world clocks (default Tokyo / NYC), **AUDIO** MPRIS now-playing + tinted/pixelated album art + lookalike bars, fake LOG / WORDS. Optional **Copland OS Enterprise** and **NUMBERS** (default off). Authored at **1920×1080**, **letterboxes** per screen (no crop). Does not tear down the view after a game. |
| Chrome | **1.2** | Color scheme, Plasma style, Aurorae decorations (hardcoded scene fills; inactive stays dark), Pixeltype / Free Pixel fonts |
| Installer | **2.0** | `./install.sh` / `./uninstall.sh` — optional windows + world-clock menu/flags, ensure tools when missing, register into System Settings (**no auto-apply**), plasmashell Qt WebEngine software mode, remove only Copland files on uninstall |

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
   On a TTY, install asks about **Copland OS Enterprise**, **NUMBERS**, and optionally **WORLD CLOCK** cities (defaults: off / off / Tokyo+NYC; re-runs show previous answers). Optional: `./install.sh --dry-run` first. If tools are already present: `./install.sh --skip-tools`.
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
./install.sh              # tools + register (TTY menus)
./install.sh --dry-run
./install.sh --skip-tools # register only
./install.sh -v           # verbose
./install.sh --with-enterprise
./install.sh --without-enterprise
./install.sh --with-numbers
./install.sh --without-numbers
./install.sh --world1=kyiv --world2=london
./install.sh --world1=Europe/Kyiv --world1-label=KYIV --world2=nyc
./uninstall.sh
```

**Optional scene windows** (default: both off)

| Flag | Effect |
|---|---|
| *(none, TTY)* | Menu: include Copland OS Enterprise? / include NUMBERS? Enter keeps the bracketed default (previous install or off). |
| `--with-enterprise` / `--without-enterprise` | Skip window menu for that choice; enable or omit the Enterprise window. |
| `--with-numbers` / `--without-numbers` | Skip window menu for that choice; enable or omit NUMBERS. |

**WORLD CLOCK cities** (default: Tokyo + NYC; same zone twice allowed)

| Flag | Effect |
|---|---|
| *(none, TTY)* | Asks whether to configure cities; **no** keeps current/defaults. **yes** shows presets (tokyo, nyc, london, kyiv, …) plus custom IANA. |
| `--world1=SPEC` / `--world2=SPEC` | Skip world-clock menu; set that slot (preset id/label or IANA timezone). |
| `--world1-label=TEXT` / `--world2-label=TEXT` | Optional display label override for a slot. |

Window flags and world-clock flags are independent (each skips only its own prompts). Choices are stored under `~/.local/share/copland-lain/` and written into the installed wallpaper’s `options.js`. Uninstall removes both.

| Exit | Meaning |
|---|---|
| `0` | Configs registered, tools present |
| `2` | Configs registered, but a host tool is still missing (wallpaper needs Qt WebEngine) |
| `1` | Could not run (bad options, missing Plasma tooling, unwritable home) |

**What install does**

1. Resolves optional windows and world-clock cities (menu and/or flags), then checks host tools (`kpackagetool6` required; layers `qt6-qtwebengine` / `fontconfig` via `rpm-ostree` only if absent).
2. Registers into `~/.local`: fonts (via Plasma fontinst), color scheme, wallpaper package, Plasma style, Aurorae theme; rewrites scene `options.js` for your choices.
3. Writes `~/.local/share/copland-lain/install-manifest` (including `[options]`) and `scene-options` for uninstall / next install.
4. Does **not** change your active wallpaper, colors, fonts, style, or decorations.

After CSS/JS-only wallpaper tweaks or a change to optional windows, reselect the wallpaper (or restart plasmashell) if Plasma still shows a cached scene.

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
| Scene goes black after a game | plasmashell Qt WebEngine was using Vulkan and then failed `CreateSharedImage`. Installer forces software rendering for plasmashell only. Run `./install.sh --skip-tools`, then `systemctl --user restart plasma-plasmashell.service` on the host. You want `view created rev=2.0` and no new `CreateSharedImage failed` lines. |
| Optional windows / world clocks look stale after changing options | Re-run install with the new choice, then reselect the wallpaper or `systemctl --user restart plasma-plasmashell.service`. |
| AUDIO stuck on “No audio playing.” while music plays | Player must expose **MPRIS** (Spotify, Firefox, many players do). Check `busctl --user list \| grep mpris`. Reselect the wallpaper or restart plasmashell after upgrading to **2.0**. Album art needs a working `mpris:artUrl` (missing art shows a placeholder tile). |
| AUDIO bars don’t match “real” spectrum | Expected in 2.0 — bars are a visual lookalike while Playing. True desktop FFT is not shipped yet. |
| GIFs/clocks freeze during a game or heavy load | Expected while the GPU is saturated. Software rendering avoids a permanent black desktop; smooth animation *during* the game is not guaranteed. |
| Wallpaper goes black overnight / after sleep | If the render process dies, the wallpaper reloads it. There is no Debug mode. After install, restart Plasma or the new WebEngine flags are not applied: `systemctl --user restart plasma-plasmashell.service` in a **host** Konsole. Then `journalctl --user -u plasma-plasmashell.service -b \| grep -i "Copland scene"`. |
| Script won’t layer packages / asks you to run `sudo` | User not in `wheel`, or no active local graphical session. Run the printed `rpm-ostree` command, reboot, then `./install.sh --skip-tools`. |
| Ran install “inside Distrobox” and nothing showed up | Scripts must run on the **host** Plasma user. Distrobox can’t register that user’s Plasma packages the way you expect. |
| Fonts missing from the chooser | Re-open System Settings after install. Families are **Pixeltype** and **Free Pixel** (from fontinst into `~/.local/share/fonts`). |
| Window decorations look wrong / inactive titlebars go white | Use Aurorae **v1** (not Aurorae 2). Theme name **Copland LAIN**. |
| Look still Copland after uninstall | Uninstall doesn’t change active selections — pick another wallpaper / colors / decorations in Settings. |
| Want to test without risking your main desktop | Follow [docs/TESTING.md](./docs/TESTING.md) (`lain_test` user). |

## Editing Aurorae SVGs

Do not hand-edit `packages/aurorae/themes/org.lainavi.copland/*.svg`. Change palette or glyphs in `tools/generate-aurorae.py`, run `python3 tools/generate-aurorae.py`, commit the regenerated SVGs + metadata, then re-run `./install.sh` (or copy the theme dir) and refresh decorations in Settings.

## Roadmap

### Stage 1 — Static environment

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

### Stage 2 — Interactive environment (theme 2.x)

- [x] Optional Copland OS Enterprise and NUMBERS windows (installer menu + flags; default off)
- [x] Configurable WORLD CLOCK cities (presets + custom IANA; default Tokyo / NYC)
- [x] AUDIO MPRIS now-playing (title / artist / art) + lookalike bars while Playing
- [ ] Interactive modules (apps/widgets) visually integrated into the Copland scene
- [ ] Installer static vs interactive modes / per-module toggles
- [ ] Module docs, graceful failure, secrets kept out of Git

### Stage 3 — NAVI environment

Not started (separate fuller environment; not this theme’s job yet).

## Credits

Visual design and assets come from the Steam Workshop items linked above (by Gav).
Bundled files are listed in [docs/CREDITS.md](./docs/CREDITS.md).

## License

Project code: Apache-2.0 — see `LICENSE`.

Workshop art and fonts remain subject to their authors’ / Steam Workshop terms.
