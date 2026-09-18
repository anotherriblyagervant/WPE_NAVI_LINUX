#!/usr/bin/env bash
# Host tool detect / install for Copland LAIN (Bazzite / rpm-ostree).
# SPDX-License-Identifier: Apache-2.0
# shellcheck shell=bash

# Expects common.sh already sourced.

COPLAND_WEBENGINE_PKG="${COPLAND_WEBENGINE_PKG:-qt6-qtwebengine}"
COPLAND_FONTCONFIG_PKG="${COPLAND_FONTCONFIG_PKG:-fontconfig}"
# Colon-separated; overridable so the "tool missing" path can be exercised in tests.
COPLAND_WEBENGINE_QML_DIRS="${COPLAND_WEBENGINE_QML_DIRS:-/usr/lib64/qt6/qml/QtWebEngine:/usr/lib/qt6/qml/QtWebEngine}"

# Set when a layered package needs a reboot before it is usable.
COPLAND_REBOOT_REQUIRED=0

_qt_major_from_plasmashell() {
  local version
  if ! require_cmd plasmashell; then
    printf '6\n'
    return 0
  fi
  version="$(plasmashell --version 2>/dev/null || true)"
  printf '%s\n' "$version" | grep -oE '[0-9]+' | head -1
}

_rpm_installed() {
  local pkg="$1"
  require_cmd rpm || return 1
  rpm -q "$pkg" >/dev/null 2>&1
}

_rpm_nevra() {
  local pkg="$1"
  rpm -q "$pkg" 2>/dev/null || true
}

_webengine_qml_present() {
  local dirs d
  IFS=':' read -r -a dirs <<<"$COPLAND_WEBENGINE_QML_DIRS"
  for d in "${dirs[@]}"; do
    if [[ -n "$d" && -d "$d" ]]; then
      verbose "QtWebEngine QML module found: $d"
      return 0
    fi
  done
  return 1
}

_tool_present_webengine() {
  if _rpm_installed "$COPLAND_WEBENGINE_PKG"; then
    return 0
  fi
  _webengine_qml_present
}

_tool_present_fontconfig() {
  require_cmd fc-cache
}

_ostree_host() {
  require_cmd rpm-ostree && [[ -f /run/ostree-booted || -d /ostree ]]
}

_in_wheel() {
  # Capture first: grep -q can SIGPIPE under pipefail and abort the caller.
  local groups
  groups="$(id -nG 2>/dev/null || true)"
  printf '%s' "$groups" | tr ' ' '\n' | grep -Fxq wheel
}

# Bazzite/Fedora polkit grants rpm-ostree install without a password only for
# an active, local session owned by a wheel member. Anything else needs an
# admin password we must not try to collect from a script.
_can_layer_without_password() {
  _in_wheel || return 1

  if ! require_cmd loginctl; then
    return 0
  fi

  # No session id (SSH, cron, su without login) → do not assume passwordless.
  if [[ -z "${XDG_SESSION_ID:-}" ]]; then
    verbose "no XDG_SESSION_ID — refusing passwordless rpm-ostree"
    return 1
  fi

  local active remote
  active="$(loginctl show-session "$XDG_SESSION_ID" --property=Active --value 2>/dev/null || true)"
  remote="$(loginctl show-session "$XDG_SESSION_ID" --property=Remote --value 2>/dev/null || true)"
  verbose "session $XDG_SESSION_ID active=$active remote=$remote"
  [[ "$active" == "yes" ]] || return 1
  [[ "$remote" == "no" || -z "$remote" ]] || return 1
  return 0
}

_print_manual_tool_instructions() {
  local pkg="$1"
  log ""
  log "Install it yourself, then re-run ./install.sh:"
  log "  sudo rpm-ostree install $pkg"
  log "  # reboot when rpm-ostree reports a new deployment"
  log ""
}

# Try to install a host package. Records tools_installed / tools_conflict.
# Returns 0 on success or skip; 1 when the tool is still missing.
_install_host_pkg() {
  local pkg="$1"
  local reason="$2"

  if _rpm_installed "$pkg"; then
    log "tool already present: $pkg ($(_rpm_nevra "$pkg"))"
    manifest_add tools_skipped "$pkg"
    return 0
  fi

  if ! _ostree_host; then
    err "need package '$pkg' ($reason) but this is not an rpm-ostree host"
    err "install it with your distribution's package manager, then re-run ./install.sh"
    manifest_add tools_conflict "$pkg: not an ostree host; install manually"
    return 1
  fi

  log "tool missing: $pkg ($reason)"

  if [[ "${COPLAND_DRY_RUN}" == "1" ]]; then
    log "dry-run: rpm-ostree install --assumeyes --idempotent $pkg"
    log "dry-run: would require reboot after a real layer"
    manifest_add tools_installed "$pkg"
    return 0
  fi

  # Never try to drive a polkit password prompt from this script.
  if ! _can_layer_without_password; then
    err "cannot layer '$pkg' without an admin password."
    err "rpm-ostree needs an active local session owned by a 'wheel' member (this user: $(id -nG 2>/dev/null || true))."
    manifest_add tools_conflict "$pkg: needs admin rights (not wheel/active/local)"
    _print_manual_tool_instructions "$pkg"
    return 1
  fi

  local log_dir log_file rc=0
  log_dir="${COPLAND_STATE_DIR}/logs"
  mkdir -p "$log_dir"
  log_file="$(mktemp "${log_dir}/rpm-ostree-XXXXXX.log")"
  log "layering $pkg via rpm-ostree — this downloads metadata and can take several minutes"
  if ! rpm-ostree install --assumeyes --idempotent "$pkg" 2>&1 | tee "$log_file"; then
    rc=1
  fi

  if [[ "$rc" -ne 0 ]]; then
    err "failed to install $pkg"
    if grep -qiE 'conflict|protected|not found|unable|authoriz' "$log_file"; then
      err "the present package stack (or missing authorization) blocked '$pkg'."
    fi
    err "full output: $log_file"
    manifest_add tools_conflict "$pkg: rpm-ostree install failed (log: $log_file)"
    _print_manual_tool_instructions "$pkg"
    return 1
  fi

  rm -f "$log_file"
  log "layered host tool: $pkg"
  manifest_add tools_installed "$pkg"
  COPLAND_REBOOT_REQUIRED=1
  return 0
}

# Hard requirement: we cannot register Plasma packages without this.
require_plasma_tooling() {
  if ! require_cmd kpackagetool6; then
    die "kpackagetool6 not found. Run this on a Bazzite/Kinoite Plasma 6 host (not inside Distrobox alone)."
  fi
  log "tool already present: kpackagetool6 ($(command -v kpackagetool6))"
  manifest_add tools_skipped "kpackagetool6"
}

# Ensure optional-but-needed runtime tools. Returns 1 if any is still missing.
ensure_host_tools() {
  local failed=0
  local qt_major
  qt_major="$(_qt_major_from_plasmashell)"
  verbose "plasmashell Qt/Plasma major hint: ${qt_major:-unknown}"

  if [[ -n "$qt_major" && "$qt_major" != "6" ]]; then
    local cmsg="Plasma/Qt major is $qt_major but this project expects Qt6 WebEngine ($COPLAND_WEBENGINE_PKG)"
    err "$cmsg"
    manifest_add tools_conflict "$COPLAND_WEBENGINE_PKG: $cmsg"
    failed=1
  elif _tool_present_webengine; then
    if _rpm_installed "$COPLAND_WEBENGINE_PKG"; then
      log "tool already present: $COPLAND_WEBENGINE_PKG ($(_rpm_nevra "$COPLAND_WEBENGINE_PKG"))"
    else
      log "tool already present: QtWebEngine QML module on disk"
    fi
    manifest_add tools_skipped "$COPLAND_WEBENGINE_PKG"
  else
    _install_host_pkg "$COPLAND_WEBENGINE_PKG" "QML import QtWebEngine for the wallpaper" || failed=1
  fi

  if _tool_present_fontconfig; then
    log "tool already present: fc-cache ($(command -v fc-cache))"
    manifest_add tools_skipped "fc-cache"
    if _rpm_installed "$COPLAND_FONTCONFIG_PKG"; then
      manifest_add tools_skipped "$COPLAND_FONTCONFIG_PKG"
    fi
  else
    _install_host_pkg "$COPLAND_FONTCONFIG_PKG" "fc-cache for user fonts" || failed=1
  fi

  return "$failed"
}
