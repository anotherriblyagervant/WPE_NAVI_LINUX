import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

/*
 * Poll MPRIS via bundled mpris-snapshot.sh.
 * Used when org.kde.plasma.private.mpris is unavailable to the wallpaper.
 * Active media: ~1 Hz. Idle (Stopped): every ~4s to cut bash/python/busctl cost.
 */
Item {
    id: root

    signal mediaUpdated(var payload)

    readonly property int activeIntervalMs: 1000
    readonly property int idleIntervalMs: 4000

    readonly property string snapshotCmd: {
        var u = Qt.resolvedUrl("mpris-snapshot.sh").toString()
        if (u.indexOf("file://") === 0) {
            // file:///path → /path
            var path = decodeURIComponent(u.substring(7))
            if (path.charAt(0) !== "/")
                path = "/" + path
            return "bash " + shellQuote(path)
        }
        return "bash mpris-snapshot.sh"
    }

    property string lastRaw: ""
    property string lastStatus: "Stopped"

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function requestSnapshot() {
        // Re-connect each tick; executable engine runs the command once per connect.
        if (exec.connectedSources.indexOf(root.snapshotCmd) !== -1)
            exec.disconnectSource(root.snapshotCmd)
        exec.connectSource(root.snapshotCmd)
    }

    function parseAndEmit(raw) {
        var text = String(raw || "").trim()
        if (!text)
            text = '{"status":"Stopped","title":"","artist":"","artUrl":""}'
        if (text === root.lastRaw)
            return
        root.lastRaw = text
        try {
            var payload = JSON.parse(text)
            if (payload && payload.status)
                root.lastStatus = String(payload.status)
            else
                root.lastStatus = "Stopped"
            pollTimer.interval =
                root.lastStatus === "Stopped" ? root.idleIntervalMs : root.activeIntervalMs
            root.mediaUpdated(payload)
        } catch (e) {
            root.lastStatus = "Stopped"
            pollTimer.interval = root.idleIntervalMs
            root.mediaUpdated({
                status: "Stopped",
                title: "",
                artist: "",
                artUrl: ""
            })
        }
    }

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        interval: 0

        onNewData: function (sourceName, data) {
            // stdout is under "stdout" for the executable engine.
            var out = data["stdout"] !== undefined ? data["stdout"] : data["output"]
            root.parseAndEmit(out)
            disconnectSource(sourceName)
        }
    }

    Timer {
        id: pollTimer
        interval: root.idleIntervalMs
        running: true
        repeat: true
        // Do not also call from Component.onCompleted — avoids a double first poll.
        triggeredOnStart: true
        onTriggered: root.requestSnapshot()
    }
}
