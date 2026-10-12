import QtQuick
import QtWebEngine

/*
 * Letterbox is done in scene.js from the WebEngine widget size (DOM).
 * QML Item.scale / zoomFactor do not affect this wallpaper host.
 * ?v= busts QtWebEngine cache on package upgrades.
 * A dead render process is recreated by the parent. A live page is left alone:
 * tearing the view down after a game is what turned a freeze into a black desktop.
 */
Item {
    id: root
    anchors.fill: parent

    signal recreateRequested(string reason)
    signal healthy()

    readonly property string sceneRev: "1.4"
    readonly property url sceneUrl: Qt.resolvedUrl("scene/index.html") + "?v=" + root.sceneRev

    readonly property int heartbeatIntervalMs: 20000
    readonly property int heartbeatStaleMs: 75000
    readonly property int probeTimeoutMs: 8000

    property bool probeWaiting: false
    property double probeSentAt: 0
    property bool pageReady: false

    function ensureActiveLifecycle() {
        if (web.lifecycleState !== WebEngineView.LifecycleState.Active)
            web.lifecycleState = WebEngineView.LifecycleState.Active
    }

    function onProbeResult(beat) {
        root.probeWaiting = false
        var n = Number(beat) || 0
        if (n <= 0) {
            root.recreateRequested("missing heartbeat")
            return
        }
        if (Date.now() - n > root.heartbeatStaleMs) {
            root.recreateRequested("stale heartbeat")
            return
        }
        root.healthy()
    }

    function checkHeartbeat() {
        if (!root.pageReady || web.loading)
            return
        var now = Date.now()
        // A hung renderer never invokes the runJavaScript callback.
        if (root.probeWaiting) {
            if (now - root.probeSentAt >= root.probeTimeoutMs) {
                root.probeWaiting = false
                console.warn("Copland scene javascript probe timed out")
                root.recreateRequested("javascript probe timed out")
            }
            return
        }
        root.probeWaiting = true
        root.probeSentAt = now
        web.runJavaScript(
            "(function(){ try { return window.__coplandBeat || 0; } catch (e) { return 0; } })()",
            root.onProbeResult
        )
    }

    // Local scene only. No disk cache, so a reused ?v= cannot replay an older page.
    WebEngineProfile {
        id: sceneProfile
        storageName: "copland-lain-scene"
        httpCacheType: WebEngineProfile.NoCache
        persistentCookiesPolicy: WebEngineProfile.NoPersistentCookies
    }

    Rectangle {
        anchors.fill: parent
        color: "#040017"
        z: 0
    }

    WebEngineView {
        id: web
        anchors.fill: parent
        z: 1
        profile: sceneProfile
        backgroundColor: "#040017"
        url: root.sceneUrl
        settings.localContentCanAccessFileUrls: true
        settings.localContentCanAccessRemoteUrls: false
        settings.javascriptEnabled: true

        Component.onCompleted: {
            console.warn("Copland scene view created rev=" + root.sceneRev)
            root.ensureActiveLifecycle()
        }

        onRecommendedStateChanged: {
            if (recommendedState === WebEngineView.LifecycleState.Active)
                root.ensureActiveLifecycle()
        }

        onLifecycleStateChanged: {
            if (visible && lifecycleState !== WebEngineView.LifecycleState.Active)
                root.ensureActiveLifecycle()
        }

        onLoadingChanged: function (request) {
            if (request.status === WebEngineView.LoadSucceededStatus) {
                root.pageReady = true
                root.probeWaiting = false
                root.ensureActiveLifecycle()
                root.healthy()
                console.warn("Copland scene loaded")
                return
            }
            if (request.status === WebEngineView.LoadFailedStatus) {
                console.warn("Copland scene load failed:", request.errorString, request.url)
                root.recreateRequested("load failed")
            }
        }

        onRenderProcessTerminated: function (terminationStatus, exitCode) {
            console.warn("Copland scene render process terminated:", terminationStatus, exitCode)
            root.recreateRequested("render process terminated")
        }
    }

    Timer {
        id: heartbeatTimer
        interval: root.heartbeatIntervalMs
        running: true
        repeat: true
        onTriggered: root.checkHeartbeat()
    }

    Connections {
        target: Qt.application
        function onStateChanged() {
            if (Qt.application.state === Qt.ApplicationActive)
                root.ensureActiveLifecycle()
        }
    }
}
