import QtQuick
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root

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
            visible: webLoader.status !== Loader.Ready
        }
    }

    Loader {
        id: webLoader
        anchors.fill: parent
        z: 1
        asynchronous: false
        source: Qt.resolvedUrl("WebEngineScene.qml")
        onStatusChanged: {
            if (status === Loader.Error) {
                statusText.text = "Copland LAIN Scene\n(WebEngine failed to load)"
                statusText.visible = true
            }
        }
    }

    Component.onCompleted: {
        root.loading = false
    }
}
