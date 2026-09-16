/*
 * Copland LAIN Scene — Plasma 6 wallpaper host
 * SPDX-License-Identifier: Apache-2.0
 */

import QtQuick
import QtWebEngine

WallpaperItem {
    id: root

    WebEngineView {
        id: web
        anchors.fill: parent
        backgroundColor: "#040017"
        url: Qt.resolvedUrl("scene/index.html")
        settings.localContentCanAccessFileUrls: true
        settings.localContentCanAccessRemoteUrls: false
        settings.javascriptEnabled: true
        settings.playbackRequiresUserGesture: false

        onLoadingChanged: function (loadRequest) {
            if (loadRequest.status === WebEngineView.LoadSucceededStatus
                    || loadRequest.status === WebEngineView.LoadFailedStatus) {
                root.loading = false
            }
        }
    }

    Component.onCompleted: {
        // Fallback if LoadSucceeded never fires
        root.loading = false
    }
}
