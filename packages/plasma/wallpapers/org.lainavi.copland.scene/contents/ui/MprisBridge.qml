import QtQuick

/*
 * Bridges MPRIS now-playing into the WebEngine scene via __coplandSetMedia.
 * Tries private Plasma MPRIS first; falls back to busctl snapshot poller.
 */
Item {
    id: root

    property var webView: null
    property bool pageReady: false

    property string lastJson: ""
    property var pendingPayload: ({
        status: "Stopped",
        title: "",
        artist: "",
        artUrl: ""
    })

    function pushToPage(payload) {
        root.pendingPayload = payload || root.pendingPayload
        if (!root.webView || !root.pageReady)
            return
        var json
        try {
            json = JSON.stringify(root.pendingPayload)
        } catch (e) {
            json = '{"status":"Stopped","title":"","artist":"","artUrl":""}'
        }
        if (json === root.lastJson)
            return
        root.lastJson = json
        // JSON.stringify already produces safe JS object literal text.
        root.webView.runJavaScript(
            "(function(){try{if(window.__coplandSetMedia)window.__coplandSetMedia("
            + json
            + ");}catch(e){}})()"
        )
    }

    function onMediaUpdated(payload) {
        root.pushToPage(payload)
    }

    function flush() {
        // Force re-push after page reload (ignore lastJson dedupe).
        root.lastJson = ""
        root.pushToPage(root.pendingPayload)
    }

    Loader {
        id: backendLoader
        anchors.fill: parent
        source: Qt.resolvedUrl("MprisNative.qml")
        onStatusChanged: {
            if (status !== Loader.Error)
                return
            var src = source.toString()
            if (src.indexOf("MprisNative.qml") !== -1) {
                console.warn("Copland MPRIS: private module unavailable, using busctl poller")
                source = Qt.resolvedUrl("MprisPoller.qml")
                return
            }
            console.warn("Copland MPRIS: no backend available; AUDIO stays idle")
            root.onMediaUpdated({
                status: "Stopped",
                title: "",
                artist: "",
                artUrl: ""
            })
        }
        onLoaded: {
            if (!item)
                return
            item.mediaUpdated.connect(root.onMediaUpdated)
        }
    }
}
