#!/usr/bin/env bash
# Emit one JSON object (single line) for the active MPRIS player.
# Prefers Playing, then Paused; otherwise Stopped with empty fields.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

idle() {
  printf '%s\n' '{"status":"Stopped","title":"","artist":"","artUrl":""}'
}

if ! command -v busctl >/dev/null 2>&1; then
  idle
  exit 0
fi

# Metadata parsing via python3 + busctl (JSON when available). Errors → idle.
python3 - <<'PY' 2>/dev/null || idle
import json, re, subprocess, sys

def idle():
    print(json.dumps({"status": "Stopped", "title": "", "artist": "", "artUrl": ""}))

def busctl(*args):
    try:
        out = subprocess.check_output(
            ["busctl", "--user", *args],
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=2,
        )
        return out
    except Exception:
        return ""

# Detect once whether busctl --json=short works for get-property.
_json_ok = None

def busctl_json_supported():
    global _json_ok
    if _json_ok is not None:
        return _json_ok
    # Probe with a harmless call shape; empty/invalid dest still exercises --json parsing path.
    raw = busctl("--json=short", "list")
    _json_ok = bool(raw.strip()) and raw.lstrip().startswith(("{", "["))
    return _json_ok

def list_players():
    raw = busctl("list", "--acquired")
    names = []
    for line in raw.splitlines():
        parts = line.split()
        if not parts:
            continue
        name = parts[0]
        if name.startswith("org.mpris.MediaPlayer2."):
            names.append(name)
    return names

def get_prop_json(dest, prop):
    if not busctl_json_supported():
        return None
    raw = busctl("--json=short", "get-property", dest,
                 "/org/mpris/MediaPlayer2",
                 "org.mpris.MediaPlayer2.Player", prop)
    if not raw.strip():
        return None
    try:
        obj = json.loads(raw)
        if isinstance(obj, dict) and "data" in obj:
            return obj["data"]
        return obj
    except Exception:
        # JSON mode claimed support but failed for properties — stick to plain for this run.
        global _json_ok
        _json_ok = False
        return None

def get_prop_plain(dest, prop):
    return busctl("get-property", dest,
                  "/org/mpris/MediaPlayer2",
                  "org.mpris.MediaPlayer2.Player", prop).strip()

def playback_status(dest):
    data = get_prop_json(dest, "PlaybackStatus")
    if isinstance(data, str) and data:
        return data
    plain = get_prop_plain(dest, "PlaybackStatus")
    m = re.search(r'"([^"]+)"', plain)
    return m.group(1) if m else "Stopped"

def unwrap_variant(v):
    while isinstance(v, dict) and "data" in v and "type" in v:
        v = v["data"]
    return v

def metadata_fields(dest):
    title = artist = art = ""
    data = get_prop_json(dest, "Metadata")
    if isinstance(data, dict):
        meta = {k: unwrap_variant(v) for k, v in data.items()}
        t = meta.get("xesam:title")
        if isinstance(t, str):
            title = t
        a = meta.get("xesam:artist")
        if isinstance(a, list) and a:
            artist = str(a[0])
        elif isinstance(a, str):
            artist = a
        u = meta.get("mpris:artUrl")
        if isinstance(u, str):
            art = u
        return title, artist, art

    plain = get_prop_plain(dest, "Metadata")
    def after_key(key):
        idx = plain.find('"%s"' % key)
        if idx < 0:
            idx = plain.find(key)
        if idx < 0:
            return ""
        rest = plain[idx + len(key):]
        m = re.search(r'"([^"]*)"', rest)
        return m.group(1) if m else ""

    return after_key("xesam:title"), after_key("xesam:artist"), after_key("mpris:artUrl")

players = list_players()
if not players:
    idle()
    sys.exit(0)

# Status-only pass first — skip Metadata bus calls when nothing is active.
rank_map = {"Playing": 0, "Paused": 1}
candidates = []
for dest in players:
    status = playback_status(dest)
    rank = rank_map.get(status, 2)
    if rank < 2:
        candidates.append((rank, status, dest))

if not candidates:
    idle()
    sys.exit(0)

candidates.sort(key=lambda x: x[0])
best_rank, best_status, best_dest = candidates[0]
title, artist, art = metadata_fields(best_dest)
print(json.dumps({
    "status": best_status,
    "title": title or "",
    "artist": artist or "",
    "artUrl": art or "",
}, ensure_ascii=False))
PY
