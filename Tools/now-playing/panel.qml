// SPDX-License-Identifier: Apache-2.0
//
// 悬浮卡本体：由 now-playing.qml 用 api.mount(url) 异步加载，parent 就是那个 Loader，
// 所以「关闭」只要 api.unmount(parent) 就能把自己摘掉。
// 位置存在插件私有配置里（api.settings），下次启动还在原处。
import QtQuick
import QueMusic 1.0

Rectangle {
    id: card

    property QtObject api                // 入口插件透传进来的宿主接口

    readonly property int gap: 24
    readonly property bool playing: Playback.player.playing
    readonly property string cover: Playback.player.urlStr || "qrc:/QueMusic/resources/app/musicpic.png"

    width: 304
    height: 92
    radius: 16
    color: Style.themes.containColor
    border.width: 1
    border.color: Style.themes.sideColor

    Component.onCompleted: {
        const sx = Number(api.settings.value("x", -1));
        const sy = Number(api.settings.value("y", -1));
        if (sx >= 0 && sy >= 0) {
            x = sx;
            y = sy;
        } else {
            // 上层挂出来的是个尺寸为 0 的 Loader，定位要按主窗口算
            const w = api.window ? api.window.width : width + gap * 2;
            const h = api.window ? api.window.height : height + gap * 2;
            x = w - width - gap;
            y = h - height - gap;
        }
    }

    // 拖动整张卡片，松手时记住位置
    DragHandler {
        target: card
        onActiveChanged: {
            if (active || !card.api)
                return;
            card.api.settings.setValue("x", card.x);
            card.api.settings.setValue("y", card.y);
        }
    }

    QPicture {
        id: coverPic
        x: 12
        width: 64
        height: 64
        radius: 12
        anchors.verticalCenter: parent.verticalCenter
        source: card.cover
        sourceSize: Qt.size(160, 160)
    }

    Column {
        id: info
        x: coverPic.x + coverPic.width + 12
        width: card.width - x - 116
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            width: parent.width
            text: Playback.musicTitle
            color: Style.themes.fontColor
            elide: Text.ElideRight
            font.pixelSize: Style.settings.textmain
            font.bold: true
        }
        Text {
            width: parent.width
            text: Playback.musicArtist
            color: Style.themes.textColor
            elide: Text.ElideRight
            font.pixelSize: Style.settings.textTip
        }
        Text {
            width: parent.width
            text: Playback.fmt(Playback.player.position) + " / "
                  + Playback.fmt(Playback.player.duration)
            color: Style.themes.textColor
            font.pixelSize: Style.settings.textTip
        }
    }

    // 播放控制：直接调 Playback 的公开接口，图标跟着播放状态走
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        SButton {
            width: 32
            height: 32
            radius: 16
            iconSize: 13
            iconCharacter: "\uf048"
            buttonColor: "transparent"
            hoverColor: Style.themes.hoverColor
            iconColor: Style.themes.textColor
            onClicked: Playback.previous()
        }
        SButton {
            width: 34
            height: 34
            radius: 17
            iconSize: 14
            iconCharacter: card.playing ? "\uf04c" : "\uf04b"
            buttonColor: Style.primaryBlurColor
            hoverColor: Style.themes.hoverColor
            iconColor: Style.themes.themeColor
            onClicked: Playback.togglePlay()
        }
        SButton {
            width: 32
            height: 32
            radius: 16
            iconSize: 13
            iconCharacter: "\uf051"
            buttonColor: "transparent"
            hoverColor: Style.themes.hoverColor
            iconColor: Style.themes.textColor
            onClicked: Playback.next(false)
        }
    }

    // 关闭：卸掉承载自己的那个 Loader（也就是 parent）
    SButton {
        x: parent.width - width + 6
        y: -6
        width: 24
        height: 24
        radius: 12
        iconSize: 10
        iconCharacter: "\uf00d"
        buttonColor: Style.themes.primaryColor
        borderWidth: 1
        borderColor: Style.themes.sideColor
        iconColor: Style.themes.textColor
        tipText: "关闭悬浮卡"
        onClicked: card.api.unmount(card.parent)
    }
}
