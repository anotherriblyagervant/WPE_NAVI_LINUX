# Copland / LAIN desktop for Bazzite

A Copland OS–inspired Plasma desktop look, based on the awesome Wallpaper Engine wallpaper
[LAIN Navi](https://steamcommunity.com/sharedfiles/filedetails/?id=3152101588) (built on [Pixels](https://steamcommunity.com/sharedfiles/filedetails/?id=3122339805))
made by Gav (I`ll not past direct link to his/her profile because of privacy, check the wallpaper page, but know that I\``m grateful to you for good scene and inspiration).

**Stage 1 goal:** the scene lives on your desktop by itself — clocks, calendar, fake system log, cycling words and numbers, LAIN art in Copland-style windows. You set it up once; you don’t click around inside the wallpaper.

Later stages (not this repo’s job yet) can turn pieces into real apps and a fuller NAVI-like environment.

## Works on

- Bazzite + KDE Plasma 6 (Wayland)
- User-level install only (nothing layered into the immutable host)

## Status

Wallpaper package includes the static Copland layout plus LAIN art and pixel fonts.
No installer yet — on the Plasma host:

```bash
kpackagetool6 --type Plasma/Wallpaper --upgrade \
  packages/plasma/wallpapers/org.lainavi.copland.scene
```

## Roadmap (simple → harder)

- [x] Wallpaper that shows the Copland window layout (static)
- [x] LAIN art and pixel fonts
- [ ] Live clock and calendar
- [ ] World clocks (Tokyo / NYC)
- [ ] Fake system log, words, and numbers
- [ ] Scaling for real resolution / multi-monitor
- [ ] Matching Plasma colors, fonts, and panel chrome
- [ ] Install and uninstall that won’t wreck your main desktop
- [ ] Test-account workflow (`lain_test`)
- [ ] Docs clear enough for someone else on Bazzite

## Credits

Visual design and assets come from the Steam Workshop items linked above (by Gav).
Bundled files are listed in [`docs/CREDITS.md`](docs/CREDITS.md).

## License

Project code: Apache-2.0 — see `LICENSE`.

Workshop art and fonts remain subject to their authors’ / Steam Workshop terms.
