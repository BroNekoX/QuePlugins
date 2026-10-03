// SPDX-License-Identifier: Apache-2.0
//
// 右下角「今日推荐」弹窗。广告图读 assets/ad.jpg —— 换成你自己合法获得的图就能直接用，
// 图缺了/读不到就退回纯自绘的金红广告底（文字、光效、按钮都是本地绘制的，不会真的跳转）。
pragma ComponentBehavior: Bound

import QtQuick
import QueMusic 1.0

Item {
    id: popup

    property QtObject api

    readonly property real winW: api && api.window ? api.window.width : 1280
    readonly property real winH: api && api.window ? api.window.height : 800

    width: 340
    height: 470
    x: winW - width - 24
    y: winH - height - 46

    transform: Translate { id: slide }
    opacity: 0

    Component.onCompleted: intro.start()

    ParallelAnimation {
        id: intro
        NumberAnimation { target: popup; property: "opacity"; to: 1; duration: 200 }
        NumberAnimation { target: slide; property: "y"; from: 90; to: 0; duration: 440; easing.type: Easing.OutBack }
    }

    // ---------- 外框：金边红底 ----------
    Rectangle {
        anchors.fill: parent
        radius: 8
        border.width: 3
        border.color: "#ffcc33"
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#c40000" }
            GradientStop { position: 0.55; color: "#8a0505" }
            GradientStop { position: 1.0; color: "#3d0000" }
        }
    }

    // 背后的放射金光：老广告的招牌
    Item {
        id: rays
        anchors.fill: parent
        anchors.margins: 4
        clip: true
        opacity: 0.32

        Repeater {
            model: 14
            Rectangle {
                required property int index
                width: 18
                height: popup.height * 2.2
                x: popup.width / 2 - width / 2
                y: -popup.height * 0.6
                color: "#ffd200"
                transformOrigin: Item.Center
                rotation: index * (360 / 14)
            }
        }

        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: 24000
            loops: Animation.Infinite
        }
    }

    // ---------- 顶栏 ----------
    Rectangle {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 3
        height: 40
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ffe066" }
            GradientStop { position: 1.0; color: "#ff9d00" }
        }
        Text {
            anchors.centerIn: parent
            text: "今日推荐"
            color: "#7a2b00"
            font.pixelSize: 20
            font.bold: true
        }
        Text {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "广告"
            color: "#997a2b00"
            font.pixelSize: 11
        }
        SButton {
            x: parent.width - width - 1
            y: 1
            width: 18
            height: 18
            radius: 9
            iconSize: 8
            iconCharacter: "\uf00d"
            buttonColor: "#66000000"
            hoverColor: "#ccffffff"
            iconColor: "#7a2b00"
            shadowEnabled: false
            tipText: "关闭"
            onClicked: popup.api.unmount(popup.parent)
        }
    }

    // ---------- 广告图 ----------
    Item {
        id: heroBox
        anchors.top: titleBar.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 24
        height: 172
        clip: true

        Image {
            id: heroImage
            anchors.fill: parent
            source: popup.api ? popup.api.pluginUrl + "assets/ad.jpg" : ""
            sourceSize: Qt.size(720, 720)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            // 图缺失时整块退回自绘底，不显示空白
            visible: status === Image.Ready
            onStatusChanged: if (status === Image.Error) heroImage.source = ""
        }

        // 自绘底：图挂了也要有广告样
        Rectangle {
            anchors.fill: parent
            visible: !heroImage.visible
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#7a0000" }
                GradientStop { position: 1.0; color: "#2b0000" }
            }
            Repeater {
                model: 8
                Rectangle {
                    required property int index
                    width: 40
                    height: heroBox.height * 2
                    x: index * 44 - 12
                    y: -heroBox.height * 0.5
                    rotation: 26
                    color: "#1affd200"
                }
            }
        }

        // 压在图上的主标语：三层描边做出廉价立体感
        Text {
            anchors.centerIn: parent
            text: "1刀999"
            color: "#000000"
            font.pixelSize: 42
            font.bold: true
            font.italic: true
            x: -2
            y: -2
        }
        Text {
            anchors.centerIn: parent
            text: "1刀999"
            color: "#ff8a00"
            font.pixelSize: 42
            font.bold: true
            font.italic: true
            x: 2
            y: 2
        }
        Text {
            anchors.centerIn: parent
            text: "1刀999"
            color: "#ffe066"
            font.pixelSize: 42
            font.bold: true
            font.italic: true
            style: Text.Outline
            styleColor: "#6b0000"
        }

        // 角标：免费 + 火爆
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            width: 52
            height: 20
            color: "#ff2d2d"
            Text {
                anchors.centerIn: parent
                text: "免费"
                color: "#ffffff"
                font.pixelSize: 12
                font.bold: true
            }
        }
        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: 56
            height: 20
            color: "#ff2d2d"
            Text {
                anchors.centerIn: parent
                text: "火爆"
                color: "#ffffff"
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    // ---------- 文案 ----------
    Column {
        id: copy
        anchors.top: heroBox.bottom
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 28
        spacing: 6

        Text {
            width: parent.width
            text: "高爆率传奇 · 上线送满V"
            color: "#ffe066"
            font.pixelSize: 21
            font.bold: true
            style: Text.Outline
            styleColor: "#6b0000"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: "今日新服开启 · 进服就是大哥 · 装备全靠打"
            color: "#ffd6a0"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: "已有 99999 人在玩 · 仅剩 3 个名额"
            color: "#ffb0b0"
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 520 }
                NumberAnimation { to: 1.0; duration: 520 }
            }
        }
    }

    // ---------- 立即领取 ----------
    Rectangle {
        id: claimButton
        anchors.top: copy.bottom
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 56
        height: 44
        radius: 9
        clip: true
        border.width: 1
        border.color: "#fff6cc"
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#fff3b0" }
            GradientStop { position: 0.45; color: "#ffc400" }
            GradientStop { position: 1.0; color: "#ff8a00" }
        }

        // 循环扫过的白光，让按钮看着"很值钱"
        Rectangle {
            width: 26
            height: claimButton.height * 2
            rotation: 18
            color: "#66ffffff"
            y: -claimButton.height * 0.5
            NumberAnimation on x {
                from: -40
                to: claimButton.width + 20
                duration: 1800
                loops: Animation.Infinite
            }
        }

        Text {
            anchors.centerIn: parent
            text: "立即领取"
            color: "#7a2b00"
            font.pixelSize: 19
            font.bold: true
        }

        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { to: 1.04; duration: 620; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 620; easing.type: Easing.InOutQuad }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.api.toast("领取成功：至尊大礼包 ×1（内含 0 件装备）", 1)
        }
    }

    // ---------- 残忍离开（头 1.5 秒点不动）----------
    Text {
        id: leaveText
        anchors.top: claimButton.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        property bool armed: false
        text: armed ? "残忍离开" : "残忍离开（1.5 秒后才能点）"
        color: armed ? "#ffd6a0" : "#88ffffff"
        font.pixelSize: 11
        opacity: armed ? 0.9 : 0.5

        Timer {
            running: true
            interval: 1500
            onTriggered: leaveText.armed = true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: leaveText.armed ? Qt.PointingHandCursor : Qt.ForbiddenCursor
            onClicked: {
                if (!leaveText.armed)
                    return;
                popup.api.unmount(popup.parent);
            }
        }
    }

    // ---------- 免责声明 ----------
    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        text: "本广告由「恶搞广告」插件提供 · 纯属虚构"
        color: "#66ffffff"
        font.pixelSize: 10
    }
}
