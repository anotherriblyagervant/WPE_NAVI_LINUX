import QtQuick
import QtWebEngine

WebEngineView {
    id: web
    anchors.fill: parent
    backgroundColor: "#040017"
    url: Qt.resolvedUrl("scene/index.html")
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
