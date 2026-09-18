#!/usr/bin/env bash
# Shared Plasma fontinst / font path helpers for Copland LAIN.
# SPDX-License-Identifier: Apache-2.0
# shellcheck shell=bash

# Expects common.sh already sourced.

# Family names as shown in Font Management / choosers (not filenames).
COPLAND_FONT_FAMILIES=$'Free Pixel\nPixeltype\n'

# Filenames we ship (install from package; uninstall removes these + legacy dir).
COPLAND_FONT_FILES=$'FreePixel.ttf\nPixeltype.ttf\n'

fonts_dest_dir() {
  printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
}

fonts_legacy_dir() {
  printf '%s\n' "$(fonts_dest_dir)/copland-lain"
}

# Append every known Copland font path to FILES (for uninstall sweeps).
copland_font_paths_append() {
  local dest legacy base
  dest="$(fonts_dest_dir)"
  legacy="$(fonts_legacy_dir)"
  while IFS= read -r base || [[ -n "$base" ]]; do
    [[ -z "$base" ]] && continue
    FILES+="${dest}/${base}"$'\n'
  done < <(printf '%s' "$COPLAND_FONT_FILES")
  FILES+="${legacy}"$'\n'
}

fontinst_available() {
  require_cmd gdbus || return 1
  gdbus call --session --dest org.kde.fontinst --object-path /FontInst \
    --method org.kde.fontinst.folderName false >/dev/null 2>&1
}

fontinst_reconfigure() {
  local pid="${1:-$$}"
  fontinst_available || return 1
  gdbus call --session --dest org.kde.fontinst --object-path /FontInst \
    --method org.kde.fontinst.reconfigure "$pid" true >/dev/null 2>&1
}

# Install one font file into the user fontinst folder. Returns 0 on dbus accept.
fontinst_install_file() {
  local abs="$1"
  local pid="${2:-$$}"
  fontinst_available || return 1
  # install(file, createAfm=false, toSystem=false, pid, checkConfig=true)
  gdbus call --session --dest org.kde.fontinst --object-path /FontInst \
    --method org.kde.fontinst.install "$abs" false false "$pid" true >/dev/null 2>&1
}

# Unregister a family from Font Management / chooser.
fontinst_uninstall_family() {
  local family="$1"
  local pid="${2:-$$}"
  fontinst_available || return 1
  # name overload, then Regular style=0 overload
  gdbus call --session --dest org.kde.fontinst --object-path /FontInst \
    --method org.kde.fontinst.uninstall "$family" false "$pid" true >/dev/null 2>&1 \
    || gdbus call --session --dest org.kde.fontinst --object-path /FontInst \
      --method org.kde.fontinst.uninstall "$family" 0 false "$pid" true >/dev/null 2>&1
}

fonts_fc_cache() {
  local dest
  dest="$(fonts_dest_dir)"
  require_cmd fc-cache || return 1
  fc-cache -f "$dest" 2>/dev/null
}

# Brief wait so no-reply fontinst calls can settle before Settings opens.
fontinst_settle() {
  sleep 0.5
}
