// SPDX-License-Identifier: Apache-2.0
//
// QueMusic 功能插件示例 · 悬浮播放卡
// 演示：在 activate() 里挂界面（此时宿主界面已就绪）、用 url 异步加载插件自带的 QML、
//      把 api 透传给面板，面板自己也能读私有配置、把自己卸掉。
import QtQuick

QtObject {
    id: plugin

    property QtObject api                // 宿主注入
    property var card: null              // api.mount 返回的是异步 Loader

    function activate(): void {
        if (card)
            return;
        // props 会在面板的 Component.onCompleted 之前生效
        card = api.mount("window.overlay", api.pluginUrl + "panel.qml", { api: api });
    }
}
