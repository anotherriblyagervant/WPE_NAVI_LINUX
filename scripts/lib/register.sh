#!/usr/bin/env bash
# Register Copland configs into the current user's Settings catalogs.
# Does NOT apply/activate wallpaper, colors, style, decorations, or fonts.
# SPDX-License-Identifier: Apache-2.0
# shellcheck shell=bash

# Expects common.sh + fonts.sh already sourced.

_kpackage_install_or_upgrade() {
  local type="$1"
  local path="$2"
  local id="$3"

  if [[ ! -d "$path" ]]; then
    die "package path missing: $path"
  fi

  if [[ "${COPLAND_DRY_RUN}" == "1" ]]; then
    log "dry-run: kpackagetool6 --type $type --install|--upgrade $path (id=$id)"
    manifest_add packages "$type:$id"
    return 0
  fi

  # Read the list first: piping straight into grep -q can SIGPIPE the producer,
  # which pipefail then reports as a failed lookup.
  local installed_list
  installed_list="$(kpackagetool6 --type "$type" --list 2>/dev/null || true)"

  # Prefer upgrade when already present; else install.
  if printf '%s\n' "$installed_list" | grep -Fxq "$id"; then
    verbose "upgrading $type $id"
    kpackagetool6 --type "$type" --upgrade "$path"
  else
    verbose "installing $type $id"
    if ! kpackagetool6 --type "$type" --install "$path"; then
      # Race / already installed
      kpackagetool6 --type "$type" --upgrade "$path"
    fi
  fi
  manifest_add packages "$type:$id"
}

register_fonts() {
  local src dest_dir f base abs pid used_fontinst=0 need_fc_cache=0
  src="$(fonts_src_dir)"
  dest_dir="$(fonts_dest_dir)"
  pid="$$"

  if [[ ! -d "$src" ]] || ! compgen -G "$src/*.ttf" >/dev/null; then
    die "font sources missing under $src"
  fi

  log "registering fonts → $dest_dir"
  if [[ "${COPLAND_DRY_RUN}" == "1" ]]; then
    for f in "$src"/*.ttf; do
      base="$(basename "$f")"
      log "dry-run: install font $base (fontinst or cp → $dest_dir/$base)"
      manifest_add files "$dest_dir/$base"
    done
    if [[ -d "$(fonts_legacy_dir)" ]]; then
      log "dry-run: would also record legacy $(fonts_legacy_dir) for uninstall"
      manifest_add files "$(fonts_legacy_dir)"
    fi
    log "dry-run: fontinst reconfigure (or fc-cache if fontinst unavailable)"
    return 0
  fi

  mkdir -p "$dest_dir"

  if fontinst_available; then
    verbose "using org.kde.fontinst to register fonts for System Settings chooser"
    used_fontinst=1
    for f in "$src"/*.ttf; do
      abs="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
      base="$(basename "$f")"
      if ! fontinst_install_file "$abs" "$pid"; then
        warn "fontinst install failed for $base — copying manually"
        cp -a "$abs" "$dest_dir/$base"
        need_fc_cache=1
      elif [[ ! -f "$dest_dir/$base" ]]; then
        # Ensure expected basename exists for uninstall even if fontinst renames
        cp -a "$abs" "$dest_dir/$base"
      fi
      manifest_add files "$dest_dir/$base"
    done
    fontinst_settle
    fontinst_reconfigure "$pid" || warn "fontinst reconfigure failed"
  else
    warn "org.kde.fontinst not available — copying fonts and running fc-cache only"
    need_fc_cache=1
    for f in "$src"/*.ttf; do
      base="$(basename "$f")"
      cp -a "$f" "$dest_dir/$base"
      manifest_add files "$dest_dir/$base"
    done
  fi

  # fc-cache only when we did not go through fontinst (it already rebuilds config)
  if [[ "$need_fc_cache" == "1" ]] || [[ "$used_fontinst" != "1" ]]; then
    if ! fonts_fc_cache; then
      warn "fc-cache not available; fonts copied but cache not refreshed"
    fi
  fi

  # Only record legacy subdir if it still exists (older installs)
  if [[ -d "$(fonts_legacy_dir)" ]]; then
    manifest_add files "$(fonts_legacy_dir)"
  fi
}

register_color_scheme() {
  local src dest_dir dest
  src="$(colors_src)"
  dest_dir="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes"
  dest="$dest_dir/CoplandLain.colors"

  [[ -f "$src" ]] || die "color scheme missing: $src"
  log "registering color scheme → $dest"
  if [[ "${COPLAND_DRY_RUN}" == "1" ]]; then
    log "dry-run: cp $src → $dest"
  else
    mkdir -p "$dest_dir"
    cp -a "$src" "$dest"
  fi
  manifest_add files "$dest"
}

register_wallpaper() {
  local path id="org.lainavi.copland.scene"
  path="$(wallpaper_pkg_dir)"
  log "registering wallpaper package $id"
  _kpackage_install_or_upgrade "Plasma/Wallpaper" "$path" "$id"
}

register_plasma_style() {
  local path id="org.lainavi.copland"
  path="$(desktoptheme_pkg_dir)"
  log "registering Plasma style $id"
  _kpackage_install_or_upgrade "Plasma/Theme" "$path" "$id"
}

register_aurorae() {
  local src dest_parent dest
  src="$(aurorae_pkg_dir)"
  dest_parent="${XDG_DATA_HOME:-$HOME/.local/share}/aurorae/themes"
  dest="$dest_parent/org.lainavi.copland"

  [[ -d "$src" ]] || die "Aurorae theme missing: $src"
  log "registering Aurorae theme → $dest"
  if [[ "${COPLAND_DRY_RUN}" == "1" ]]; then
    log "dry-run: cp -a $src → $dest"
  else
    mkdir -p "$dest_parent"
    rm -rf "$dest"
    cp -a "$src" "$dest"
  fi
  manifest_add files "$dest"
}

register_all_configs() {
  register_fonts
  register_color_scheme
  register_wallpaper
  register_plasma_style
  register_aurorae
}

print_settings_next_steps() {
  cat <<'EOF'

Nothing was applied automatically. Choose in System Settings:

  1. Wallpaper     → Copland LAIN Scene  (per screen if needed)
  2. Colors        → Copland LAIN
  3. Fonts         → Pixeltype (General) / Free Pixel (Fixed width; optional)
  4. Plasma Style  → Copland LAIN
  5. Window Decorations → engine Aurorae (v1, not Aurorae 2) → theme Copland LAIN

After CSS/JS-only wallpaper tweaks, reselect the wallpaper if Plasma shows a cache.
Prefer Aurorae v1 — SVG fills are more reliable on Plasma 6.7.

Uninstall (removes Copland files only; does not remove host tools):
  ./uninstall.sh
EOF
}
