// SPDX-License-Identifier: Apache-2.0
//
// QueMusic 歌词界面插件示例
// 要点：只 import QtQuick；宿主注入的属性写成同名属性即可；资源（着色器）用相对路径。
import QtQuick

Item {
    id: root

    // ---------- 宿主注入（只需要写自己用得上的）----------
    property var lyricsModel: []          // 歌词行：{ time, text, info, isOther }
    property var translateModel: []       // 翻译行：{ time, text }，与歌词同下标
    property int currentIndex: 0          // 当前行下标（宿主持有）
    property real position: 0             // 播放位置(ms)
    property bool playing: false
    property string title: ""
    property string artist: ""
    property color mainColor: "#00ee66"   // 封面取色
    property color secondColor: "#00b1ee"
    property color thirdColor: "#9d4edd"
    property int lyricSize: 10            // 「标准歌词大小」0..20
    property int lyricMove: 0             // 用户的位置校准(ms)
    property int hideHeight: 0            // 沉浸模式收起控件时为 76
    property bool openTranslate: true

    // ---------- 派生数据 ----------
    readonly property int fontSize: 30 + lyricSize * 2
    readonly property real lyricPos: position + lyricMove
    readonly property var current: (currentIndex >= 0 && currentIndex < lyricsModel.length)
                                   ? lyricsModel[currentIndex] : null
    readonly property string prevText: currentIndex > 0 ? (lyricsModel[currentIndex - 1].text || "") : ""
    readonly property string nextText: currentIndex + 1 < lyricsModel.length
                                       ? (lyricsModel[currentIndex + 1].text || "") : ""
    readonly property string translateText: {
        const item = (currentIndex >= 0 && currentIndex < translateModel.length)
                     ? translateModel[currentIndex] : null;
        return item && item.text ? item.text : "";
    }

    Behavior on hideHeight { NumberAnimation { duration: 480; easing.type: Easing.OutExpo } }

    function escapeHtml(text) {
        return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // 逐字高亮：只处理当前行，info 里每个词带自己的时间
    function lineHtml(line, pos) {
        if (!line)
            return "";
        const words = line.info || [];
        if (words.length === 0)
            return escapeHtml(line.text || "");
        const hex = mainColor.toString().replace("#", "");
        const sung = "#" + hex.substring(hex.length - 6);   // 已唱：主题色
        let html = "";
        for (let i = 0; i < words.length; i++) {
            const color = pos >= words[i].time ? sung : "#a8a8a8";
            html += "<font color=\"" + color + "\">" + escapeHtml(words[i].text || "") + "</font>";
        }
        return html;
    }

    // ---------- 背景：插件自带的着色器 ----------
    ShaderEffect {
        anchors.fill: parent
        property color uColorA: root.mainColor
        property color uColorB: root.secondColor
        property color uColorC: root.thirdColor
        property vector2d uResolution: Qt.vector2d(width, height)
        property real uEnergy: root.playing ? 1.0 : 0.4
        property real uTime: 0
        NumberAnimation on uTime {
            from: 0; to: 1000; duration: 1000000; loops: Animation.Infinite; running: root.visible
        }
        fragmentShader: "shaders/wave.frag"
    }
    Rectangle { anchors.fill: parent; color: "#88000000" }   // 压暗，保证歌词可读

    // ---------- 歌词 ----------
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -40
        width: parent.width * 0.78
        spacing: 16

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.prevText
            color: "#a0a0a0"
            opacity: 0.55
            elide: Text.ElideRight
            font.pixelSize: root.fontSize * 0.55
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.RichText
            text: root.lineHtml(root.current, root.lyricPos)
            color: "#ffffff"
            wrapMode: Text.Wrap
            font.pixelSize: root.fontSize
            font.bold: true
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: root.openTranslate && root.translateText !== ""
            text: root.translateText
            color: "#d0d0d0"
            opacity: 0.8
            elide: Text.ElideRight
            font.pixelSize: root.fontSize * 0.6
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.nextText
            color: "#a0a0a0"
            opacity: 0.45
            elide: Text.ElideRight
            font.pixelSize: root.fontSize * 0.55
        }
    }

    // 纯音乐 / 还没拿到歌词
    Text {
        anchors.centerIn: parent
        visible: !root.current
        text: root.title + (root.artist ? "  ·  " + root.artist : "")
        color: "#e0e0e0"
        font.pixelSize: root.fontSize * 0.7
    }

    // ---------- 左下角歌曲信息（沉浸模式淡出）----------
    Column {
        x: 36
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 150 + root.hideHeight
        opacity: root.hideHeight > 0 ? 0 : 1
        spacing: 4
        Behavior on opacity { NumberAnimation { duration: 240 } }

        Text {
            width: root.width * 0.5
            text: root.title
            color: "#f0f0f0"
            elide: Text.ElideRight
            font.pixelSize: 18
            font.bold: true
        }
        Text {
            width: root.width * 0.5
            text: root.artist
            color: "#a8a8a8"
            elide: Text.ElideRight
            font.pixelSize: 14
        }
    }
}
