#!/usr/bin/env bash
# Copland LAIN — register configs for System Settings + ensure host tools.
# Does NOT apply/activate the look.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck source=scripts/lib/tools.sh
source "$REPO_ROOT/scripts/lib/tools.sh"
# shellcheck source=scripts/lib/fonts.sh
source "$REPO_ROOT/scripts/lib/fonts.sh"
# shellcheck source=scripts/lib/register.sh
source "$REPO_ROOT/scripts/lib/register.sh"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Ensure runtime tools are present and register Copland configs so they appear
in System Settings. Does not switch your active wallpaper, colors, fonts,
Plasma style, or window decorations.

Options:
  --dry-run       Print actions without changing the system
  -v, --verbose   Verbose logging
  --skip-tools    Only register configs; do not check or layer host tools
  -h, --help      Show this help

Configs are always registered, even if a host tool is missing: only the
wallpaper needs Qt WebEngine. Layering a tool needs an active local session
owned by a 'wheel' member; otherwise the exact sudo command is printed.

Exit codes:
  0  everything registered, tools present
  2  configs registered, but a host tool is still missing
  1  install could not run (bad options, missing Plasma tooling, unwritable home)

Target: the current user ($HOME). Refuses to run as root.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) COPLAND_DRY_RUN=1 ;;
    -v|--verbose) COPLAND_VERBOSE=1 ;;
    --skip-tools) COPLAND_SKIP_TOOLS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

refuse_root

log "Copland LAIN install (configs + tools)"
log "repo: $REPO_ROOT"
log "user: $COPLAND_TARGET_USER  home: $HOME"
[[ "${COPLAND_DRY_RUN}" == "1" ]] && log "mode: dry-run"

# Package tree must exist before we touch the host.
[[ -d "$(wallpaper_pkg_dir)" ]] || die "wallpaper package missing: $(wallpaper_pkg_dir)"
[[ -f "$(wallpaper_pkg_dir)/metadata.json" ]] || die "wallpaper package incomplete (no metadata.json)"
[[ -w "${XDG_DATA_HOME:-$HOME/.local/share}" ]] || \
  [[ -w "$HOME" ]] || die "home data dir not writable"

require_plasma_tooling

TOOLS_MISSING=0
if [[ "${COPLAND_SKIP_TOOLS}" == "1" ]]; then
  log "skipping host tool checks (--skip-tools)"
else
  ensure_host_tools || TOOLS_MISSING=1
fi

# Configs are harmless without the tools, so register them either way.
register_all_configs
write_manifest

log ""
log "Install finished."
print_settings_next_steps

if [[ -n "$(printf '%s' "$MANIFEST_TOOLS_INSTALLED" | _manifest_uniq_lines)" ]]; then
  log ""
  log "Host tools layered by this run:"
  printf '%s' "$MANIFEST_TOOLS_INSTALLED" | _manifest_uniq_lines | sed 's/^/  - /'
fi

if [[ "$TOOLS_MISSING" == "1" ]]; then
  log ""
  warn "A required host tool is still missing (see errors above)."
  warn "Colors, fonts, Plasma style, and window decorations work now;"
  warn "the wallpaper scene will show a load error until Qt WebEngine is present."
fi

if [[ "$COPLAND_REBOOT_REQUIRED" == "1" ]]; then
  log ""
  log "REBOOT REQUIRED: layered packages become active only after you reboot"
  log "into the new rpm-ostree deployment. Pick the wallpaper after rebooting."
fi

[[ "$TOOLS_MISSING" == "1" ]] && exit 2
exit 0
