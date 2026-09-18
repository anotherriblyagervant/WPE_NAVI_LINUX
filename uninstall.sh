#!/usr/bin/env bash
# Copland LAIN — remove registered configs/packages. Never removes host tools.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck source=scripts/lib/fonts.sh
source "$REPO_ROOT/scripts/lib/fonts.sh"

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [options]

Remove Copland configs and Plasma packages registered for this user.
Does NOT uninstall host tools (qt6-qtwebengine, etc.). If install.sh layered
any tools, their names and removal commands are printed.

Options:
  --dry-run       Print actions without deleting
  -v, --verbose   Verbose logging
  -h, --help      Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) COPLAND_DRY_RUN=1 ;;
    -v|--verbose) COPLAND_VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

refuse_root

log "Copland LAIN uninstall (files/packages only)"
[[ "${COPLAND_DRY_RUN}" == "1" ]] && log "mode: dry-run"

TOOLS_INSTALLED=""
FILES=""
PACKAGES=""

if [[ -f "$COPLAND_MANIFEST" ]]; then
  verbose "reading $COPLAND_MANIFEST"
  manifest_read_section "$COPLAND_MANIFEST" tools_installed TOOLS_INSTALLED || true
  manifest_read_section "$COPLAND_MANIFEST" files FILES || true
  manifest_read_section "$COPLAND_MANIFEST" packages PACKAGES || true
else
  warn "no install manifest at $COPLAND_MANIFEST — removing known default paths/ids"
fi

# Defaults if manifest empty
if [[ -z "$(printf '%s' "$PACKAGES" | _manifest_uniq_lines)" ]]; then
  PACKAGES=$'Plasma/Wallpaper:org.lainavi.copland.scene\nPlasma/Theme:org.lainavi.copland\n'
fi
if [[ -z "$(printf '%s' "$FILES" | _manifest_uniq_lines)" ]]; then
  _xd="${XDG_DATA_HOME:-$HOME/.local/share}"
  FILES="${_xd}/color-schemes/CoplandLain.colors
${_xd}/aurorae/themes/org.lainavi.copland
"
fi

# Always include known font paths (flat + legacy), even if the manifest is stale
copland_font_paths_append

_remove_kpackage() {
  local type="$1"
  local id="$2"
  if ! require_cmd kpackagetool6; then
    warn "kpackagetool6 missing; skip remove $type $id"
    return 0
  fi
  if [[ "${COPLAND_DRY_RUN}" == "1" ]]; then
    log "dry-run: kpackagetool6 --type $type --remove $id"
    return 0
  fi
  local installed_list
  installed_list="$(kpackagetool6 --type "$type" --list 2>/dev/null || true)"
  if printf '%s\n' "$installed_list" | grep -Fxq "$id"; then
    kpackagetool6 --type "$type" --remove "$id" || warn "failed to remove $type $id"
    log "removed package: $type $id"
  else
    verbose "package not installed: $type $id"
  fi
}

_remove_font_families() {
  local family pid="$$" used_fontinst=0

  if [[ "${COPLAND_DRY_RUN}" == "1" ]]; then
    while IFS= read -r family || [[ -n "$family" ]]; do
      [[ -z "$family" ]] && continue
      log "dry-run: fontinst uninstall family '$family'"
    done < <(printf '%s' "$COPLAND_FONT_FAMILIES")
    return 0
  fi

  if fontinst_available; then
    used_fontinst=1
    while IFS= read -r family || [[ -n "$family" ]]; do
      [[ -z "$family" ]] && continue
      if fontinst_uninstall_family "$family" "$pid"; then
        log "unregistered font family: $family"
      else
        verbose "fontinst uninstall skipped/failed for '$family'"
      fi
    done < <(printf '%s' "$COPLAND_FONT_FAMILIES")
    fontinst_settle
  else
    verbose "org.kde.fontinst not available — removing font files only"
  fi

  # Tell callers whether fontinst already refreshed config
  COPLAND_FONTINST_USED="$used_fontinst"
}

# Remove kpackages first
while IFS= read -r entry || [[ -n "$entry" ]]; do
  [[ -z "$entry" ]] && continue
  if [[ "$entry" == *:* ]]; then
    _remove_kpackage "${entry%%:*}" "${entry#*:}"
  fi
done < <(printf '%s' "$PACKAGES" | _manifest_uniq_lines)

COPLAND_FONTINST_USED=0
_remove_font_families

while IFS= read -r path || [[ -n "$path" ]]; do
  [[ -z "$path" ]] && continue
  if [[ "${COPLAND_DRY_RUN}" == "1" ]]; then
    log "dry-run: rm -rf $path"
    continue
  fi
  if [[ -e "$path" || -L "$path" ]]; then
    rm -rf "$path"
    log "removed: $path"
  else
    verbose "already gone: $path"
  fi
done < <(printf '%s' "$FILES" | _manifest_uniq_lines)

# Drop entire state dir (manifest + any rpm-ostree failure logs)
if [[ "${COPLAND_DRY_RUN}" == "1" ]]; then
  log "dry-run: rm -rf $COPLAND_STATE_DIR"
else
  if [[ -e "$COPLAND_STATE_DIR" ]]; then
    rm -rf "$COPLAND_STATE_DIR"
    log "removed state dir: $COPLAND_STATE_DIR"
  fi
fi

# Refresh choosers: reconfigure if fontinst was used; always fc-cache as fallback
if [[ "${COPLAND_DRY_RUN}" != "1" ]]; then
  if [[ "${COPLAND_FONTINST_USED}" == "1" ]]; then
    fontinst_reconfigure "$$" || true
  elif fontinst_available; then
    fontinst_reconfigure "$$" || true
    fonts_fc_cache || true
  else
    fonts_fc_cache || true
  fi
fi

log ""
log "Uninstall of Copland files/packages finished."
log "If the desktop still shows Copland look, reselect your previous Wallpaper / Colors /"
log "Plasma Style / Window Decorations / Fonts in System Settings."

_tools="$(printf '%s' "$TOOLS_INSTALLED" | _manifest_uniq_lines)"
if [[ -n "$_tools" ]]; then
  cat <<EOF

Host tools that install.sh newly layered/installed (NOT removed by this script):
$(printf '%s\n' "$_tools" | sed 's/^/  - /')

To remove them manually on Bazzite/Kinoite (requires reboot after deploy):
EOF
  while IFS= read -r pkg || [[ -n "$pkg" ]]; do
    [[ -z "$pkg" ]] && continue
    if [[ "$pkg" == kpackagetool6 || "$pkg" == fc-cache ]]; then
      log "  # $pkg is part of Plasma/fontconfig — do not remove casually"
    else
      log "  sudo rpm-ostree uninstall $pkg"
    fi
  done <<<"$_tools"
  log ""
  log "Then reboot when rpm-ostree reports a new deployment is ready."
else
  log ""
  log "No host tools were recorded as newly installed by install.sh (nothing to uninstall at the OS layer)."
fi
