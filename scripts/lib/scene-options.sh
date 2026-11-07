#!/usr/bin/env bash
# Optional Copland scene windows + WORLD CLOCK city choices.
# SPDX-License-Identifier: Apache-2.0
# shellcheck shell=bash

# Expects common.sh already sourced.

# Resolved window choices (0|1). Defaults: both off.
COPLAND_OPT_ENTERPRISE="${COPLAND_OPT_ENTERPRISE:-0}"
COPLAND_OPT_NUMBERS="${COPLAND_OPT_NUMBERS:-0}"

# World clocks — Pixels SoT defaults (Tokyo / NYC). Same zone twice is allowed.
COPLAND_OPT_WORLD1_LABEL="${COPLAND_OPT_WORLD1_LABEL:-TOKYO}"
COPLAND_OPT_WORLD1_TZ="${COPLAND_OPT_WORLD1_TZ:-Asia/Tokyo}"
COPLAND_OPT_WORLD2_LABEL="${COPLAND_OPT_WORLD2_LABEL:-NYC}"
COPLAND_OPT_WORLD2_TZ="${COPLAND_OPT_WORLD2_TZ:-America/New_York}"

# Flag overrides: empty = unset.
COPLAND_FLAG_ENTERPRISE="${COPLAND_FLAG_ENTERPRISE:-}"
COPLAND_FLAG_NUMBERS="${COPLAND_FLAG_NUMBERS:-}"
COPLAND_FLAG_WORLD1="${COPLAND_FLAG_WORLD1:-}"
COPLAND_FLAG_WORLD2="${COPLAND_FLAG_WORLD2:-}"
COPLAND_FLAG_WORLD1_LABEL="${COPLAND_FLAG_WORLD1_LABEL:-}"
COPLAND_FLAG_WORLD2_LABEL="${COPLAND_FLAG_WORLD2_LABEL:-}"

# Preset id|LABEL|IANA (short labels fit the scene title style).
# shellcheck disable=SC2034
COPLAND_WORLD_PRESETS=$'tokyo|TOKYO|Asia/Tokyo\nnyc|NYC|America/New_York\nlondon|LONDON|Europe/London\nparis|PARIS|Europe/Paris\nberlin|BERLIN|Europe/Berlin\nkyiv|KYIV|Europe/Kyiv\nmoscow|MOSCOW|Europe/Moscow\ndubai|DUBAI|Asia/Dubai\nsingapore|SINGAPORE|Asia/Singapore\nhongkong|HK|Asia/Hong_Kong\nseoul|SEOUL|Asia/Seoul\nsydney|SYDNEY|Australia/Sydney\nla|LA|America/Los_Angeles\nchicago|CHICAGO|America/Chicago\nsaopaulo|SAO PAULO|America/Sao_Paulo\nutc|UTC|UTC\n'

scene_options_state_file() {
  printf '%s\n' "$COPLAND_STATE_DIR/scene-options"
}

scene_options_installed_js() {
  printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/plasma/wallpapers/org.lainavi.copland.scene/contents/ui/scene/js/options.js"
}

_scene_opt_bool_js() {
  if [[ "${1:-0}" == "1" ]]; then
    printf 'true'
  else
    printf 'false'
  fi
}

_scene_opt_js_string() {
  # Escape a value for a double-quoted JS string literal.
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  printf '"%s"' "$s"
}

_scene_opt_yn_hint() {
  if [[ "${1:-0}" == "1" ]]; then
    printf '[Y/n]'
  else
    printf '[y/N]'
  fi
}

_scene_opt_parse_bool_val() {
  case "${1:-}" in
    1|true|yes|TRUE|YES) printf '1\n' ;;
    *) printf '0\n' ;;
  esac
}

_scene_opt_trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

_scene_opt_parse_answer() {
  local answer current
  answer="$(_scene_opt_trim "$1")"
  current="$2"
  answer="${answer,,}"
  if [[ -z "$answer" ]]; then
    printf '%s\n' "$current"
    return 0
  fi
  case "$answer" in
    y|yes) printf '1\n' ;;
    n|no)  printf '0\n' ;;
    *)
      warn "unrecognized answer '$answer' — keeping previous ($current)"
      printf '%s\n' "$current"
      ;;
  esac
}

_scene_opt_label_from_tz() {
  # Asia/Tokyo -> TOKYO; America/New_York -> NEW YORK; UTC -> UTC
  local tz="$1" base
  base="${tz##*/}"
  base="${base//_/ }"
  printf '%s\n' "${base^^}"
}

_scene_opt_timezone_valid() {
  local tz="$1"
  [[ -n "$tz" ]] || return 1
  if [[ "$tz" == "UTC" || "$tz" == "GMT" ]]; then
    return 0
  fi
  if [[ -e "/usr/share/zoneinfo/$tz" ]]; then
    return 0
  fi
  # Some hosts use zoneinfo as a directory tree only; accept known Intl-friendly paths
  # that timedatectl lists when available.
  if command -v timedatectl >/dev/null 2>&1; then
    timedatectl list-timezones 2>/dev/null | grep -Fxq -- "$tz"
    return $?
  fi
  return 1
}

_scene_opt_lookup_preset() {
  # Args: query -> prints id|LABEL|tz on match, return 0/1.
  local query="$1" line id label tz rest q lab_cmp
  q="$(_scene_opt_trim "$query")"
  q="${q,,}"
  q="${q// /}"
  [[ -n "$q" ]] || return 1
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    id="${line%%|*}"
    rest="${line#*|}"
    label="${rest%%|*}"
    tz="${rest#*|}"
    if [[ "${id,,}" == "$q" ]]; then
      printf '%s\n' "$line"
      return 0
    fi
    # Match label ignoring spaces/case (nyc, NYC, "sao paulo").
    lab_cmp="${label,,}"
    lab_cmp="${lab_cmp// /}"
    if [[ "$lab_cmp" == "$q" ]]; then
      printf '%s\n' "$line"
      return 0
    fi
    if [[ "${tz,,}" == "${query,,}" ]]; then
      printf '%s\n' "$line"
      return 0
    fi
  done <<<"$COPLAND_WORLD_PRESETS"
  return 1
}

_scene_opt_resolve_city_spec() {
  # Resolve preset id / label / IANA into "LABEL|tz". Optional label override as $2.
  local spec label_override line rest label tz
  spec="$(_scene_opt_trim "$1")"
  label_override="$(_scene_opt_trim "${2:-}")"
  [[ -n "$spec" ]] || return 1

  if line="$(_scene_opt_lookup_preset "$spec")"; then
    rest="${line#*|}"
    label="${rest%%|*}"
    tz="${rest#*|}"
    if [[ -n "$label_override" ]]; then
      label="$label_override"
    fi
    printf '%s|%s\n' "$label" "$tz"
    return 0
  fi

  # Treat as IANA timezone.
  if _scene_opt_timezone_valid "$spec"; then
    if [[ -n "$label_override" ]]; then
      label="$label_override"
    else
      label="$(_scene_opt_label_from_tz "$spec")"
    fi
    printf '%s|%s\n' "$label" "$spec"
    return 0
  fi

  return 1
}

_scene_opt_apply_kv() {
  local key="$1"
  local val="$2"
  case "$key" in
    enterprise) COPLAND_OPT_ENTERPRISE="$(_scene_opt_parse_bool_val "$val")" ;;
    numbers) COPLAND_OPT_NUMBERS="$(_scene_opt_parse_bool_val "$val")" ;;
    world1_label) COPLAND_OPT_WORLD1_LABEL="$val" ;;
    world1_tz) COPLAND_OPT_WORLD1_TZ="$val" ;;
    world2_label) COPLAND_OPT_WORLD2_LABEL="$val" ;;
    world2_tz) COPLAND_OPT_WORLD2_TZ="$val" ;;
  esac
}

_scene_opt_load_kv_file() {
  local file="$1"
  local line key val
  [[ -f "$file" ]] || return 1
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ "$line" == *=* ]] || continue
    key="${line%%=*}"
    val="${line#*=}"
    _scene_opt_apply_kv "$key" "$val"
  done <"$file"
  return 0
}

_scene_opt_load_manifest_options() {
  local file="$COPLAND_MANIFEST"
  local line key val in=0
  [[ -f "$file" ]] || return 1
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "[options]" ]]; then
      in=1
      continue
    fi
    if [[ "$line" == \[*\] ]]; then
      in=0
      continue
    fi
    if [[ "$in" -eq 1 && -n "$line" && "$line" != \#* && "$line" == *=* ]]; then
      key="${line%%=*}"
      val="${line#*=}"
      _scene_opt_apply_kv "$key" "$val"
    fi
  done <"$file"
  return 0
}

_scene_opt_reset_defaults() {
  COPLAND_OPT_ENTERPRISE=0
  COPLAND_OPT_NUMBERS=0
  COPLAND_OPT_WORLD1_LABEL=TOKYO
  COPLAND_OPT_WORLD1_TZ=Asia/Tokyo
  COPLAND_OPT_WORLD2_LABEL=NYC
  COPLAND_OPT_WORLD2_TZ=America/New_York
}

load_scene_options() {
  local state
  _scene_opt_reset_defaults
  state="$(scene_options_state_file)"
  if _scene_opt_load_kv_file "$state"; then
    verbose "loaded scene options from state"
    return 0
  fi
  if _scene_opt_load_manifest_options; then
    verbose "loaded scene options from manifest"
    return 0
  fi
  verbose "no prior scene options; using defaults"
}

window_options_flags_set() {
  [[ -n "${COPLAND_FLAG_ENTERPRISE}" || -n "${COPLAND_FLAG_NUMBERS}" ]]
}

world_clock_flags_set() {
  [[ -n "${COPLAND_FLAG_WORLD1}" || -n "${COPLAND_FLAG_WORLD2}" || \
     -n "${COPLAND_FLAG_WORLD1_LABEL}" || -n "${COPLAND_FLAG_WORLD2_LABEL}" ]]
}

apply_window_option_flags() {
  if [[ -n "${COPLAND_FLAG_ENTERPRISE}" ]]; then
    COPLAND_OPT_ENTERPRISE="$COPLAND_FLAG_ENTERPRISE"
  fi
  if [[ -n "${COPLAND_FLAG_NUMBERS}" ]]; then
    COPLAND_OPT_NUMBERS="$COPLAND_FLAG_NUMBERS"
  fi
}

apply_world_clock_flags() {
  local resolved
  if [[ -n "${COPLAND_FLAG_WORLD1}" ]]; then
    if ! resolved="$(_scene_opt_resolve_city_spec "$COPLAND_FLAG_WORLD1" "${COPLAND_FLAG_WORLD1_LABEL}")"; then
      die "invalid --world1 value: $COPLAND_FLAG_WORLD1 (use a preset id or IANA timezone)"
    fi
    COPLAND_OPT_WORLD1_LABEL="${resolved%%|*}"
    COPLAND_OPT_WORLD1_TZ="${resolved#*|}"
  elif [[ -n "${COPLAND_FLAG_WORLD1_LABEL}" ]]; then
    COPLAND_OPT_WORLD1_LABEL="$COPLAND_FLAG_WORLD1_LABEL"
  fi

  if [[ -n "${COPLAND_FLAG_WORLD2}" ]]; then
    if ! resolved="$(_scene_opt_resolve_city_spec "$COPLAND_FLAG_WORLD2" "${COPLAND_FLAG_WORLD2_LABEL}")"; then
      die "invalid --world2 value: $COPLAND_FLAG_WORLD2 (use a preset id or IANA timezone)"
    fi
    COPLAND_OPT_WORLD2_LABEL="${resolved%%|*}"
    COPLAND_OPT_WORLD2_TZ="${resolved#*|}"
  elif [[ -n "${COPLAND_FLAG_WORLD2_LABEL}" ]]; then
    COPLAND_OPT_WORLD2_LABEL="$COPLAND_FLAG_WORLD2_LABEL"
  fi
}

scene_options_can_prompt() {
  [[ -r /dev/tty && -w /dev/tty ]]
}

_scene_opt_print_world_presets() {
  local line id label tz rest n=1
  printf '  Presets:\n' >/dev/tty
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    id="${line%%|*}"
    rest="${line#*|}"
    label="${rest%%|*}"
    tz="${rest#*|}"
    printf '    %2d) %-10s  %s  (%s)\n' "$n" "$id" "$label" "$tz" >/dev/tty
    n=$((n + 1))
  done <<<"$COPLAND_WORLD_PRESETS"
  printf '     c) custom IANA timezone (e.g. Europe/Kyiv)\n' >/dev/tty
}

_scene_opt_pick_world_slot() {
  # Args: slot_no current_label current_tz -> sets COPLAND_OPT_WORLD{n}_*
  local slot="$1"
  local cur_label="$2"
  local cur_tz="$3"
  local ans line rest label tz n count resolved custom_tz custom_label

  count="$(printf '%s' "$COPLAND_WORLD_PRESETS" | grep -c . || true)"

  printf '\n  City %s — current %s (%s)\n' "$slot" "$cur_label" "$cur_tz" >/dev/tty
  printf '  Pick preset number, preset id, IANA zone, or Enter to keep: ' >/dev/tty
  IFS= read -r ans </dev/tty || ans=""
  ans="$(_scene_opt_trim "$ans")"
  if [[ -z "$ans" ]]; then
    label="$cur_label"
    tz="$cur_tz"
  elif [[ "${ans,,}" == "c" || "${ans,,}" == "custom" ]]; then
    printf '  IANA timezone: ' >/dev/tty
    IFS= read -r custom_tz </dev/tty || custom_tz=""
    custom_tz="$(_scene_opt_trim "$custom_tz")"
    [[ -n "$custom_tz" ]] || die "custom timezone required for city $slot"
    _scene_opt_timezone_valid "$custom_tz" || die "unknown timezone: $custom_tz"
    printf '  Display label [%s]: ' "$(_scene_opt_label_from_tz "$custom_tz")" >/dev/tty
    IFS= read -r custom_label </dev/tty || custom_label=""
    custom_label="$(_scene_opt_trim "$custom_label")"
    if [[ -z "$custom_label" ]]; then
      custom_label="$(_scene_opt_label_from_tz "$custom_tz")"
    fi
    label="$custom_label"
    tz="$custom_tz"
  elif [[ "$ans" =~ ^[0-9]+$ ]]; then
    n=1
    line=""
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -z "$line" ]] && continue
      if [[ "$n" -eq "$ans" ]]; then
        break
      fi
      n=$((n + 1))
      line=""
    done <<<"$COPLAND_WORLD_PRESETS"
    [[ -n "$line" ]] || die "preset number out of range (1-$count)"
    rest="${line#*|}"
    label="${rest%%|*}"
    tz="${rest#*|}"
  else
    if ! resolved="$(_scene_opt_resolve_city_spec "$ans")"; then
      die "unknown city/timezone for city $slot: $ans"
    fi
    label="${resolved%%|*}"
    tz="${resolved#*|}"
  fi

  if [[ "$slot" == "1" ]]; then
    COPLAND_OPT_WORLD1_LABEL="$label"
    COPLAND_OPT_WORLD1_TZ="$tz"
  else
    COPLAND_OPT_WORLD2_LABEL="$label"
    COPLAND_OPT_WORLD2_TZ="$tz"
  fi
}

prompt_window_options() {
  local ans ent_hint num_hint
  log ""
  log "Optional scene windows (default: off; Enter keeps the value in brackets):"
  ent_hint="$(_scene_opt_yn_hint "$COPLAND_OPT_ENTERPRISE")"
  printf '  Include Copland OS Enterprise window? %s ' "$ent_hint" >/dev/tty
  IFS= read -r ans </dev/tty || ans=""
  COPLAND_OPT_ENTERPRISE="$(_scene_opt_parse_answer "$ans" "$COPLAND_OPT_ENTERPRISE")"

  num_hint="$(_scene_opt_yn_hint "$COPLAND_OPT_NUMBERS")"
  printf '  Include NUMBERS window? %s ' "$num_hint" >/dev/tty
  IFS= read -r ans </dev/tty || ans=""
  COPLAND_OPT_NUMBERS="$(_scene_opt_parse_answer "$ans" "$COPLAND_OPT_NUMBERS")"
}

prompt_world_clock_options() {
  local ans
  log ""
  log "WORLD CLOCK cities (default: TOKYO + NYC; same timezone twice is allowed)."
  log "  Current: $COPLAND_OPT_WORLD1_LABEL ($COPLAND_OPT_WORLD1_TZ) / $COPLAND_OPT_WORLD2_LABEL ($COPLAND_OPT_WORLD2_TZ)"
  printf '  Configure WORLD CLOCK cities? %s ' "$(_scene_opt_yn_hint 0)" >/dev/tty
  IFS= read -r ans </dev/tty || ans=""
  ans="$(_scene_opt_parse_answer "$ans" 0)"
  if [[ "$ans" != "1" ]]; then
    log "  Keeping WORLD CLOCK cities unchanged."
    return 0
  fi
  _scene_opt_print_world_presets
  _scene_opt_pick_world_slot 1 "$COPLAND_OPT_WORLD1_LABEL" "$COPLAND_OPT_WORLD1_TZ"
  _scene_opt_pick_world_slot 2 "$COPLAND_OPT_WORLD2_LABEL" "$COPLAND_OPT_WORLD2_TZ"
}

resolve_scene_options() {
  load_scene_options

  # Windows: flags and menu are independent of world-clock prompts.
  if window_options_flags_set; then
    apply_window_option_flags
    log "scene windows (from flags): enterprise=$COPLAND_OPT_ENTERPRISE numbers=$COPLAND_OPT_NUMBERS"
  elif scene_options_can_prompt; then
    prompt_window_options
    log "scene windows (from menu): enterprise=$COPLAND_OPT_ENTERPRISE numbers=$COPLAND_OPT_NUMBERS"
  else
    log "scene windows (non-interactive; previous or defaults): enterprise=$COPLAND_OPT_ENTERPRISE numbers=$COPLAND_OPT_NUMBERS"
  fi

  if world_clock_flags_set; then
    apply_world_clock_flags
    log "world clocks (from flags): $COPLAND_OPT_WORLD1_LABEL/$COPLAND_OPT_WORLD1_TZ + $COPLAND_OPT_WORLD2_LABEL/$COPLAND_OPT_WORLD2_TZ"
  elif scene_options_can_prompt; then
    prompt_world_clock_options
    log "world clocks (from menu): $COPLAND_OPT_WORLD1_LABEL/$COPLAND_OPT_WORLD1_TZ + $COPLAND_OPT_WORLD2_LABEL/$COPLAND_OPT_WORLD2_TZ"
  else
    log "world clocks (non-interactive; previous or defaults): $COPLAND_OPT_WORLD1_LABEL/$COPLAND_OPT_WORLD1_TZ + $COPLAND_OPT_WORLD2_LABEL/$COPLAND_OPT_WORLD2_TZ"
  fi
}

write_options_js_content() {
  cat <<EOF
/* Copland scene options. Written by install.sh — do not edit by hand. */
window.COPLAND_SCENE_OPTIONS = {
  enterprise: $(_scene_opt_bool_js "$COPLAND_OPT_ENTERPRISE"),
  numbers: $(_scene_opt_bool_js "$COPLAND_OPT_NUMBERS"),
  worldClocks: [
    { label: $(_scene_opt_js_string "$COPLAND_OPT_WORLD1_LABEL"), timeZone: $(_scene_opt_js_string "$COPLAND_OPT_WORLD1_TZ") },
    { label: $(_scene_opt_js_string "$COPLAND_OPT_WORLD2_LABEL"), timeZone: $(_scene_opt_js_string "$COPLAND_OPT_WORLD2_TZ") }
  ]
};
EOF
}

save_scene_options_state() {
  local dest
  dest="$(scene_options_state_file)"
  if [[ "${COPLAND_DRY_RUN}" == "1" ]]; then
    log "dry-run: would write $dest (enterprise=$COPLAND_OPT_ENTERPRISE numbers=$COPLAND_OPT_NUMBERS world=$COPLAND_OPT_WORLD1_TZ+$COPLAND_OPT_WORLD2_TZ)"
    manifest_add files "$dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  {
    printf '# Copland LAIN scene options (written by install.sh)\n'
    printf 'enterprise=%s\n' "$COPLAND_OPT_ENTERPRISE"
    printf 'numbers=%s\n' "$COPLAND_OPT_NUMBERS"
    printf 'world1_label=%s\n' "$COPLAND_OPT_WORLD1_LABEL"
    printf 'world1_tz=%s\n' "$COPLAND_OPT_WORLD1_TZ"
    printf 'world2_label=%s\n' "$COPLAND_OPT_WORLD2_LABEL"
    printf 'world2_tz=%s\n' "$COPLAND_OPT_WORLD2_TZ"
  } >"$dest"
  manifest_add files "$dest"
  verbose "wrote scene options state $dest"
}

apply_scene_options_to_wallpaper() {
  local dest dest_dir
  dest="$(scene_options_installed_js)"
  dest_dir="$(dirname "$dest")"
  if [[ "${COPLAND_DRY_RUN}" == "1" ]]; then
    log "dry-run: would write $dest (enterprise=$COPLAND_OPT_ENTERPRISE numbers=$COPLAND_OPT_NUMBERS world=$COPLAND_OPT_WORLD1_TZ+$COPLAND_OPT_WORLD2_TZ)"
    manifest_add files "$dest"
    return 0
  fi
  if [[ ! -d "$dest_dir" ]]; then
    die "installed wallpaper scene dir missing after register: $dest_dir (cannot write options.js)"
  fi
  write_options_js_content >"$dest"
  manifest_add files "$dest"
  verbose "wrote installed options.js $dest"
}

record_scene_options_manifest() {
  MANIFEST_OPTIONS=""
  MANIFEST_OPTIONS+="enterprise=${COPLAND_OPT_ENTERPRISE}"$'\n'
  MANIFEST_OPTIONS+="numbers=${COPLAND_OPT_NUMBERS}"$'\n'
  MANIFEST_OPTIONS+="world1_label=${COPLAND_OPT_WORLD1_LABEL}"$'\n'
  MANIFEST_OPTIONS+="world1_tz=${COPLAND_OPT_WORLD1_TZ}"$'\n'
  MANIFEST_OPTIONS+="world2_label=${COPLAND_OPT_WORLD2_LABEL}"$'\n'
  MANIFEST_OPTIONS+="world2_tz=${COPLAND_OPT_WORLD2_TZ}"$'\n'
}
