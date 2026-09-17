import QtQuick
import QtWebEngine

/*
 * Letterbox is done in scene.js from the WebEngine widget size (DOM).
 * QML runJavaScript / Item.scale / zoomFactor do not affect this wallpaper host.
 * Load the page once; ?v= only busts QtWebEngine cache on package upgrades.
 */
Item {
    id: root
    anchors.fill: parent

    readonly property string sceneRev: "1.1"

    Rectangle {
        anchors.fill: parent
        color: "#040017"
        z: 0
    }

    WebEngineView {
        id: web
        anchors.fill: parent
        z: 1
        backgroundColor: "#040017"
        url: Qt.resolvedUrl("scene/index.html") + "?v=" + root.sceneRev
        settings.localContentCanAccessFileUrls: true
        settings.localContentCanAccessRemoteUrls: false
        settings.javascriptEnabled: true
        settings.playbackRequiresUserGesture: false

        onLoadingChanged: function (request) {
            if (request.status === WebEngineView.LoadFailedStatus) {
                console.warn("Copland scene load failed:", request.errorString, request.url)
            }
        }
    }
}
