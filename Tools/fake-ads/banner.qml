// SPDX-License-Identifier: Apache-2.0
//
// 底部跑马灯广告条：贴在底栏上方，文案从右往左无限滚。
// 演示：overlay 里用 api.window 的尺寸定位（api.mount 建出来的 Loader 自身是 0 尺寸）。
import QtQuick
import QueMusic 1.0

Item {
    id: banner

    property QtObject api

    readonly property real winW: api && api.window ? api.window.width : 1280
    readonly property real winH: api && api.window ? api.window.height : 800
    readonly property string adText: "1刀999 · 超高爆率 · 点击就送屠龙宝刀 · 上线送满V · 元宝爆满地 · 装备全靠打 · 今日推荐高爆传奇 · 进服就是大哥 · "

    x: 0
    y: winH - 158                      // 抬到底栏上方，免得压住宿主的播放控件
    width: winW
    height: 34

    Rectangle {
        anchors.fill: parent
        border.width: 1
        border.color: "#ffcc33"
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#7d0000" }
            GradientStop { position: 0.5; color: "#c40000" }
            GradientStop { position: 1.0; color: "#7d0000" }
        }
    }

    // 跑马灯：两份文案首尾相接，滚过一份宽度就重置，视觉上无缝
    Item {
        id: viewport
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 108
        clip: true

        property real offset          // 由下面的 NumberAnimation 驱动

        Text {
            id: ticker
            x: viewport.width - viewport.offset
            y: (viewport.height - height) / 2
            text: banner.adText + banner.adText
            color: "#ffe066"
            font.pixelSize: 15
            font.bold: true
            style: Text.Outline
            styleColor: "#5a0000"
        }

        NumberAnimation on offset {
            from: 0
            to: viewport.width + ticker.width / 2
            duration: 18000
            loops: Animation.Infinite
        }
    }

    // 右侧：VIP 角标 + 关闭
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 20
            radius: 5
            border.width: 1
            border.color: "#fff6cc"
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#fff3b0" }
                GradientStop { position: 1.0; color: "#ff9d00" }
            }
            Text {
                anchors.centerIn: parent
                text: "VIP"
                color: "#7a2b00"
                font.pixelSize: 12
                font.bold: true
                font.italic: true
            }
        }

        SButton {
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            radius: 11
            iconSize: 9
            iconCharacter: "\uf00d"
            buttonColor: "#66000000"
            hoverColor: "#99ffffff"
            iconColor: "#ffe066"
            shadowEnabled: false
            tipText: "关掉这条广告"
            onClicked: banner.api.unmount(banner.parent)
        }
    }
}
