// SPDX-License-Identifier: Apache-2.0
//
// QueMusic 功能插件示例 · 恶搞广告（整活向，纯属虚构）
// 一次往四个扩展点塞满「1刀999」：标题栏 VIP 徽章、底栏「手气不错」、侧栏传奇卡片、
// 覆盖层跑马灯横幅 + 右下角「今日推荐」弹窗。
// 广告图读 assets/ad.jpg —— 换成你自己合法获得的图即可（插件自带的是自绘/生成素材）。
// 演示：Component 同步挂载（标题栏必须同步）、url 异步挂载 + props 透传、私有配置、api.unmount 自卸。
pragma ComponentBehavior: Bound

import QtQuick
import QueMusic 1.0

QtObject {
    id: plugin

    property QtObject api

    property var banner: null            // 覆盖层跑马灯（api.mount 返回的是异步 Loader）
    property var popup: null             // 右下角「今日推荐」弹窗

    function activate(): void {
        // 标题栏整块是窗口拖拽区，必须在初始化时挂好，宿主随后统一标记「可命中」
        api.mount("titlebar", vipBadge);
        api.mount("player", luckyButton);
        api.mount("sidebar.bottom", sideCard);

        banner = api.mount("window.overlay", api.pluginUrl + "banner.qml", { api: api });
        // 学真广告：进应用先缓一下，再「啪」地弹出来
        popupTimer.start();
    }

    function showPopup(): void {
        if (popup)
            return;
        popup = api.mount("window.overlay", api.pluginUrl + "popup.qml", { api: api });
    }

    // 弹窗关掉后再点 VIP 徽章可以再叫出来一次，方便反复看
    function reopenPopup(): void {
        if (popup) {
            api.unmount(popup);
            popup = null;
        }
        showPopup();
    }

    property Timer popupTimer: Timer {
        interval: 1600
        onTriggered: plugin.showPopup()
    }

    // ---------- 标题栏：会呼吸的 VIP 徽章 ----------
    property Component vipBadge: Component {
        Item {
            width: 46
            height: 40

            Rectangle {
                anchors.centerIn: parent
                width: 36
                height: 25
                radius: 6
                border.width: 1
                border.color: "#fff6cc"
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#fff3b0" }
                    GradientStop { position: 0.5; color: "#ffb800" }
                    GradientStop { position: 1.0; color: "#e07b00" }
                }

                Text {
                    anchors.centerIn: parent
                    text: "VIP"
                    color: "#7a2b00"
                    font.pixelSize: 14
                    font.bold: true
                    font.italic: true
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.6; duration: 720; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 720; easing.type: Easing.InOutQuad }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        plugin.api.toast("至尊 VIP 特权已激活：今日推荐再看一次", 1);
                        plugin.reopenPopup();
                    }
                }
            }
        }
    }

    // ---------- 底栏：手气不错 ----------
    property Component luckyButton: Component {
        SButton {
            width: 40
            height: 40
            radius: 40
            iconCharacter: "\uf0e7"
            iconColor: "#ffb800"
            buttonColor: "transparent"
            hoverColor: Style.themes.hoverColor
            shadowEnabled: false
            tipText: "手气不错 · 点击就送"
            onClicked: plugin.api.toast("恭喜抽中屠龙宝刀 ×1（并不存在）", 1)
        }
    }

    // ---------- 侧栏：传奇广告卡片 ----------
    property Component sideCard: Component {
        Rectangle {
            id: card
            width: parent ? parent.width : 180
            height: 214
            radius: 10
            clip: true
            border.width: 2
            border.color: "#ffcc33"
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#c40000" }
                GradientStop { position: 1.0; color: "#4d0000" }
            }

            // 顶部广告图（缺图就退回自绘的红底斜纹）
            Image {
                id: cardImage
                width: parent.width
                height: 88
                source: plugin.api ? plugin.api.pluginUrl + "assets/ad.jpg" : ""
                sourceSize: Qt.size(720, 720)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
                onStatusChanged: if (status === Image.Error) cardImage.source = ""
            }

            Rectangle {
                width: parent.width
                height: 88
                visible: !cardImage.visible
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#7a0000" }
                    GradientStop { position: 1.0; color: "#2b0000" }
                }

                Repeater {
                    model: 6
                    Rectangle {
                        required property int index
                        width: 26
                        height: 200
                        x: index * 34 - 10
                        y: -60
                        rotation: 24
                        color: "#22ffd200"
                    }
                }
            }

            // 压在图上的大字（三层偏移做出廉价立体感）
            Text {
                x: -1
                y: 13
                width: parent.width
                text: "高爆率传奇"
                horizontalAlignment: Text.AlignHCenter
                color: "#000000"
                font.pixelSize: 24
                font.bold: true
                font.italic: true
            }
            Text {
                x: 2
                y: 15
                width: parent.width
                text: "高爆率传奇"
                horizontalAlignment: Text.AlignHCenter
                color: "#ff8a00"
                font.pixelSize: 24
                font.bold: true
                font.italic: true
            }
            Text {
                y: 14
                width: parent.width
                text: "高爆率传奇"
                horizontalAlignment: Text.AlignHCenter
                color: "#ffe066"
                font.pixelSize: 24
                font.bold: true
                font.italic: true
                style: Text.Outline
                styleColor: "#6b0000"
            }

            Column {
                anchors.top: cardImage.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 4

                Text {
                    width: parent.width
                    text: "1刀999 · 上线送满V"
                    color: "#fff3b0"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: "装备全靠打 · 元宝爆满地"
                    color: "#ffd6a0"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: parent.width
                    height: 32
                    radius: 8
                    border.width: 1
                    border.color: "#fff6cc"
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#ffe066" }
                        GradientStop { position: 1.0; color: "#ff9d00" }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "立即试玩"
                        color: "#7a2b00"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: plugin.api.toast("正在为您打开传奇官网…… 没有官网，只有这个提示", 0)
                    }
                }
            }

            // 左上角「限时」斜标
            Rectangle {
                x: -22
                y: 14
                width: 90
                height: 20
                rotation: -32
                color: "#ff2d2d"
                Text {
                    anchors.centerIn: parent
                    text: "限时"
                    color: "#ffffff"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }
    }
}
