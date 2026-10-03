// SPDX-License-Identifier: Apache-2.0
//
// QueMusic 功能插件示例 · 侧栏「最近播放」
// 演示：把界面挂到 sidebar.bottom（Column，自动参与排版，别写 anchors）；
//      绑定宿主公开单例 Playback 的数据；点击时调用 Playback 的接口切歌。
pragma ComponentBehavior: Bound

import QtQuick
import QueMusic 1.0

QtObject {
    id: plugin

    property QtObject api                    // 宿主注入（早于 Component.onCompleted）

    property Component recentBox: Component {
        Column {
            id: box
            width: parent ? parent.width : 180
            spacing: 2

            Text {
                width: box.width
                topPadding: 6
                bottomPadding: 2
                text: "最近播放"
                color: Style.themes.textColor
                font.pixelSize: Style.settings.textTip
                font.bold: true
            }

            // 只做最近 5 条：model 传数字时 delegate 里用 index，配合 get() 取行
            Repeater {
                model: Math.min(5, Playback.history.count)

                delegate: Item {
                    id: row
                    required property int index

                    readonly property var entry: Playback.history.get(index) || ({})

                    width: box.width
                    height: 28

                    Rectangle {
                        anchors.fill: parent
                        radius: Style.settings.labelRadius / 2
                        color: hover.containsMouse ? Style.themes.hoverColor : "transparent"
                    }

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        text: (row.index + 1) + ". " + (row.entry.title || "")
                        color: Style.themes.textColor
                        elide: Text.ElideRight
                        font.pixelSize: Style.settings.textTip
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // 队列条目：{ name, path, songer, source }
                        onClicked: Playback.playItem({ name: row.entry.title || "",
                                                       path: row.entry.path,
                                                       songer: row.entry.artist || "",
                                                       source: row.entry.source })
                    }
                }
            }
        }
    }

    Component.onCompleted: api.mount("sidebar.bottom", recentBox)
}
