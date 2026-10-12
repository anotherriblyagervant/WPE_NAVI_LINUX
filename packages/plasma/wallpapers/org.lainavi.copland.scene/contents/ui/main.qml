import QtQuick
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root

    property int failStreak: 0
    property bool recreatePending: false

    function recreateScene(reason) {
        if (root.recreatePending)
            return
        root.recreatePending = true
        root.failStreak += 1
        // 1s, 2s, 4s … capped at 5 min so a dead renderer cannot reload-storm.
        var delay = Math.min(300000, 1000 * Math.pow(2, Math.min(root.failStreak - 1, 8)))
        console.warn("Copland scene recreate:", reason, "delayMs=", delay, "failStreak=", root.failStreak)
        webLoader.active = false
        recreateTimer.interval = delay
        recreateTimer.restart()
    }

    function noteHealthy() {
        if (root.failStreak !== 0)
            console.warn("Copland scene healthy again")
        root.failStreak = 0
    }

    // Full-bleed letterbox bars while WebEngine boots / per-screen contain.
    Rectangle {
        anchors.fill: parent
        color: "#040017"
        z: 0

        Text {
            id: statusText
            anchors.centerIn: parent
            color: "#0083bc"
            text: "Copland LAIN Scene"
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 24
            visible: !webLoader.active || webLoader.status !== Loader.Ready
        }
    }

    Loader {
        id: webLoader
        anchors.fill: parent
        z: 1
        active: true
        asynchronous: false
        source: Qt.resolvedUrl("WebEngineScene.qml")
        onLoaded: {
            if (item) {
                item.recreateRequested.connect(root.recreateScene)
                item.healthy.connect(root.noteHealthy)
            }
        }
        onStatusChanged: {
            if (status === Loader.Error) {
                statusText.text = "Copland LAIN Scene\n(WebEngine failed to load)"
                statusText.visible = true
                root.recreateScene("WebEngineScene failed to load")
            }
        }
    }

    Timer {
        id: recreateTimer
        interval: 1000
        repeat: false
        onTriggered: {
            root.recreatePending = false
            webLoader.active = true
        }
    }

    Component.onCompleted: {
        root.loading = false
        console.warn("Copland scene wallpaper host started")
    }
}
