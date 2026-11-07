import QtQuick
import org.kde.plasma.private.mpris as Mpris

/*
 * Prefer Plasma's MPRIS multiplexer when the private QML module is available.
 * Emits the same payload shape as MprisPoller.
 * Active: ~1 Hz. Idle (Stopped): every ~4s.
 */
Item {
    id: root

    signal mediaUpdated(var payload)

    readonly property int activeIntervalMs: 1000
    readonly property int idleIntervalMs: 4000

    property string lastKey: ""
    property string lastStatus: "Stopped"

    function artistText(player) {
        if (!player)
            return ""
        if (typeof player.artist === "string" && player.artist.length)
            return player.artist
        if (player.artists !== undefined && player.artists && player.artists.length)
            return String(player.artists[0])
        return ""
    }

    function artText(player) {
        if (!player)
            return ""
        if (player.artUrl !== undefined && player.artUrl)
            return String(player.artUrl)
        if (player.track && typeof player.track === "object" && player.track.artUrl)
            return String(player.track.artUrl)
        return ""
    }

    function titleText(player) {
        if (!player)
            return ""
        if (typeof player.title === "string" && player.title.length)
            return player.title
        if (typeof player.track === "string" && player.track.length)
            return player.track
        return ""
    }

    function statusText(player) {
        if (!player)
            return "Stopped"
        var s = player.playbackStatus
        if (s === undefined || s === null)
            return "Stopped"

        // Prefer symbolic enum names from Plasma when present.
        try {
            if (Mpris.PlaybackStatus !== undefined) {
                if (s === Mpris.PlaybackStatus.Playing)
                    return "Playing"
                if (s === Mpris.PlaybackStatus.Paused)
                    return "Paused"
                if (s === Mpris.PlaybackStatus.Stopped)
                    return "Stopped"
            }
        } catch (e) {
            /* fall through to string parse */
        }

        var t = String(s)
        // Avoid brittle numeric-only guesses; match known tokens.
        if (/playing/i.test(t))
            return "Playing"
        if (/paused/i.test(t))
            return "Paused"
        return "Stopped"
    }

    function publish() {
        var player = null
        try {
            player = mux.currentPlayer
        } catch (e) {
            player = null
        }

        var payload
        if (!player) {
            payload = {
                status: "Stopped",
                title: "",
                artist: "",
                artUrl: ""
            }
        } else {
            var st = statusText(player)
            if (st === "Stopped") {
                payload = {
                    status: "Stopped",
                    title: "",
                    artist: "",
                    artUrl: ""
                }
            } else {
                payload = {
                    status: st,
                    title: titleText(player),
                    artist: artistText(player),
                    artUrl: artText(player)
                }
            }
        }

        root.lastStatus = payload.status
        pollTimer.interval =
            root.lastStatus === "Stopped" ? root.idleIntervalMs : root.activeIntervalMs

        var key = payload.status + "\n" + payload.title + "\n" + payload.artist + "\n" + payload.artUrl
        if (key === root.lastKey)
            return
        root.lastKey = key
        root.mediaUpdated(payload)
    }

    Mpris.Multiplexer {
        id: mux
        onCurrentPlayerChanged: root.publish()
    }

    // Some properties update without swapping currentPlayer.
    Timer {
        id: pollTimer
        interval: root.idleIntervalMs
        running: true
        repeat: true
        // Do not also call from Component.onCompleted — avoids a double first poll.
        triggeredOnStart: true
        onTriggered: root.publish()
    }
}
