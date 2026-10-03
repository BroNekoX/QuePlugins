// SPDX-License-Identifier: Apache-2.0
//
// QueMusic 歌词界面插件 · 基础示例
// 布局：左侧封面 + 歌曲名 / 歌手名，右侧歌词列表（ListView，当前行居中、放大并逐字高亮）。
// 只 import QtQuick —— 把宿主注入的属性写成同名属性即可，不依赖宿主内部实现。
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

Item {
    id: root

    // ---------- 宿主注入（只写自己用得上的）----------
    property real position: 0            // 播放进度 ms
    property var lyricsModel: []         // { time, text, info, isOther }
    property var translateModel: []      // { time, text }，与歌词同下标
    property int currentIndex: 0         // 当前行下标（宿主持有）
    property int lyricMove: 0            // 用户的位置校准 ms
    property bool openTranslate: true
    property string title: ""
    property string artist: ""
    property string coverUrl: ""
    property color mainColor: "#00ee66"
    property color secondColor: "#00b1ee"
    property color thirdColor: "#9d4edd"
    property int lyricSize: 10           // 「标准歌词大小」0..20

    // ---------- 派生 ----------
    readonly property real margin: Math.max(28, width * 0.045)
    readonly property real coverSize: Math.min(width * 0.24, height * 0.44)
    readonly property int fontSize: 16 + lyricSize
    readonly property real lyricTime: position + lyricMove

    // ---------- 背景：主色渐变 + 压暗，保证歌词可读 ----------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.darker(root.mainColor, 2.6) }
            GradientStop { position: 0.5; color: Qt.darker(root.secondColor, 2.8) }
            GradientStop { position: 1.0; color: Qt.darker(root.thirdColor, 2.0) }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: "#77000000"
    }

    // ---------- 左：封面 + 歌曲名 / 歌手名 ----------
    Column {
        id: leftPane
        x: root.margin
        width: Math.min(root.width * 0.3, root.coverSize * 1.6)
        anchors.verticalCenter: parent.verticalCenter
        spacing: 20

        Item {
            id: coverBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.coverSize
            height: root.coverSize

            // 圆角封面：Image 当源，MultiEffect 用圆角矩形做遮罩
            Image {
                id: coverSource
                anchors.fill: parent
                visible: false
                source: root.coverUrl
                sourceSize: Qt.size(512, 512)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            Rectangle {
                id: coverMask
                anchors.fill: parent
                radius: 18
                color: "#ff000000"
                visible: false
                layer.enabled: true
            }
            MultiEffect {
                anchors.fill: parent
                source: coverSource
                maskEnabled: true
                maskSource: coverMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
        }

        Column {
            width: parent.width
            spacing: 6

            Text {
                id: titleText
                width: parent.width
                text: root.title
                color: "#f2f2f2"
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Math.max(18, root.fontSize * 1.1)
                font.bold: true
            }
            Text {
                width: parent.width
                text: root.artist
                color: "#b0b0b0"
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Math.max(13, root.fontSize * 0.72)
            }
        }
    }

    // ---------- 右：歌词列表 ----------
    ListView {
        id: lyricView
        x: leftPane.x + leftPane.width + root.margin
        width: root.width - x - root.margin
        height: root.height
        clip: true
        reuseItems: true
        model: root.lyricsModel
        currentIndex: root.currentIndex
        highlightMoveDuration: 280
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: height * 0.42
        preferredHighlightEnd: height * 0.58
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: height

        delegate: Item {
            id: line
            required property var modelData
            required property int index

            readonly property bool isCurrent: index === root.currentIndex
            readonly property bool hasTranslate: root.openTranslate
                                                 && index < root.translateModel.length
                                                 && (root.translateModel[index].text || "") !== ""

            width: lyricView.width
            height: lineText.height + (hasTranslate ? transText.height + 6 : 0) + 20

            Text {
                id: lineText
                width: parent.width
                // 只有当前行用富文本做逐字高亮：其余行保持纯文本，开销可控
                textFormat: line.isCurrent ? Text.RichText : Text.PlainText
                text: line.isCurrent ? root.lineHtml(line.modelData, root.lyricTime)
                                     : (line.modelData.text || "")
                color: line.isCurrent ? "#ffffff" : "#8a8a8a"
                wrapMode: Text.Wrap
                font.pixelSize: line.isCurrent ? root.fontSize * 1.2 : root.fontSize
                font.bold: line.isCurrent
                opacity: line.isCurrent ? 1.0 : 0.75
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on font.pixelSize { NumberAnimation { duration: 180 } }
            }

            Text {
                id: transText
                anchors.top: lineText.bottom
                anchors.topMargin: 4
                width: parent.width
                visible: line.hasTranslate
                text: line.hasTranslate ? root.translateModel[line.index].text : ""
                color: "#9a9a9a"
                elide: Text.ElideRight
                font.pixelSize: root.fontSize * 0.8
            }
        }
    }

    // 没有歌词（纯音乐 / 还没拿到）时给一句提示
    Text {
        x: lyricView.x
        y: root.height * 0.45
        width: lyricView.width
        visible: root.lyricsModel.length === 0
        text: root.title + (root.artist ? "  ·  " + root.artist : "")
        color: "#d8d8d8"
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: root.fontSize
    }

    // ---------- 逐字高亮（只处理当前行）----------
    // info 里每个词带自己的时间；已唱的部分用主题色，未唱用灰色
    function lineHtml(line: var, pos: real): string {
        if (!line)
            return "";
        const words = line.info || [];
        if (words.length === 0)
            return escapeHtml(line.text || "");
        const sung = "#" + root.mainColor.toString().slice(-6);
        let html = "";
        for (let i = 0; i < words.length; ++i) {
            const color = pos >= words[i].time ? sung : "#9a9a9a";
            html += "<font color=\"" + color + "\">" + escapeHtml(words[i].text || "") + "</font>";
        }
        return html;
    }

    function escapeHtml(text: var): string {
        return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }
}
