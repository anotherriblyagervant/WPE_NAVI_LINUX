# Testing

Target: **Bazzite + KDE Plasma 6 (Wayland)**. Prefer a dedicated Plasma user for install and visual checks so experiments never rewrite your primary `~/.local`.

## Safe rule

Use a test account (`lain_test` below). Do not point early install/uninstall experiments at your everyday desktop session.

`./install.sh` and `./uninstall.sh` always act on the **current user’s** home. Log in as the test user before you run them.

## 1. Create the user

On the Plasma host, as an admin account:

```bash
sudo useradd -m -s /bin/bash lain_test
sudo passwd lain_test
```

Do **not** pass `-G <group_name>` — group is often missing on Bazzite/Fedora. The account gets its own private group by default.

Do **not** add `lain_test` to `wheel` unless you intentionally want that session to layer packages with `rpm-ostree`. Host tools (`qt6-qtwebengine`, etc.) are system-wide: once they exist on the machine (layered from your admin account), the test user only needs to register configs.

## 2. Log in

1. Log out or switch user.
2. At the SDDM login screen, choose **lain_test**.
3. Pick **Plasma (Wayland)** if the greeter offers a session type.

## 3. Get the repo

As `lain_test`, either clone a copy:

```bash
git clone https://github.com/anotherriblyagervant/WPE_NAVI_LINUX.git
cd WPE_NAVI_LINUX
```

or use the existing tree under another home if that path is readable (parent directories need traverse permission, e.g. `o+x` or an ACL):

```bash
cd /home/{YOUR_ADMIN}/{PATH_TO_REPO}/WPE_NAVI_LINUX
```

Run everything from the **repo root on the Plasma host** (not as root; not only inside Distrobox).

## 4. Install as `lain_test`

If Qt WebEngine (and the rest) are already on the host:

```bash
./install.sh --skip-tools
```

If you need the script to check/layer tools **and** `lain_test` is in `wheel` with an active local session:

```bash
./install.sh
```

Otherwise run `./install.sh` from your admin account once to layer tools (reboot if `rpm-ostree` deployed), then register as `lain_test` with `--skip-tools`.

Dry-run first if you want:

```bash
./install.sh --dry-run --skip-tools
```

## 5. Apply in System Settings

Install only registers packages — it does not switch the active look. As `lain_test`:

1. Wallpaper → **Copland LAIN Scene** (per screen if needed)
2. Colors → **Copland LAIN**
3. Fonts → **Pixeltype** (General, optional); **Free Pixel** (Fixed width). Re-open Settings if a chooser was already open.
4. Plasma Style → **Copland LAIN**
5. Window Decorations → engine **Aurorae** (**v1**, not Aurorae 2) → theme **Copland LAIN**

## 6. Uninstall check

Still as `lain_test`:

```bash
./uninstall.sh
```

Confirm Copland wallpaper / Plasma style / colors / Aurorae / fonts are gone from Settings catalogs. Host tools must still be installed (uninstall never removes them). Reselect a non-Copland look if the desktop still shows Copland chrome.

## 7. Tear down (optional)

From an admin account:

```bash
sudo userdel -r lain_test
```

`-r` removes `/home/lain_test` (and `/var/home/lain_test` on Bazzite layouts that use it).

## Visual checklist

- [ ] Copland LAIN Scene wallpaper loads (not a blank/fallback screen)
- [ ] Pixeltype / Free Pixel appear in the Fonts chooser (not only under Installed fonts)
- [ ] Inactive Aurorae windows stay dark muted cyan (not white)
- [ ] After `./uninstall.sh` on `lain_test`, the primary user’s desktop is unchanged
