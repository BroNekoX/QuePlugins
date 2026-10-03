# 功能插件规范（apiVersion 1）

一个文件夹就是一个插件，文件夹名即插件 id，目录约定与歌词界面插件相同。
区别是它**不换界面，而是往界面里加东西**：宿主给每个启用的插件注入一份 `api`，
插件自己决定往哪儿挂按钮、面板、HUD。功能插件可以同时启用多个。

## 目录结构

```
Tools/now-playing/
  info.json            插件信息，必要
  now-playing.qml      入口 QML，必要（文件名写在 info.json 的 entry 里）
  panel.qml            插件自己的其它 QML，可选
  info.png             预览图，建议
  resources/…          其它随插件分发的资源
```

`info.json` 字段与歌词界面插件完全相同，`apiVersion` 必须为 `1`。

## 入口契约

根类型是 `QtObject`（纯逻辑）或 `Item`，**必须声明 `api` 属性**：宿主以初始属性注入，
早于 `Component.onCompleted`，所以在里面直接读就是真值。

```qml
import QtQuick
import QueMusic 1.0

QtObject {
    id: plugin
    property QtObject api

    property Component barButton: Component {
        SButton { iconCharacter: "\uf005"; onClicked: api.toast("你好", 1) }
    }

    Component.onCompleted: api.mount("player", barButton)
}
```

两个坑：

- 根是 `QtObject` 时**没有默认属性**，`Component { … }` 不能当子对象写，要写成属性值；
  需要多个子对象就把根换成 `Item`。
- 根对象本身不参与显示，界面一律经 `api.mount()` 挂到扩展点上。

需要等宿主界面完全就绪再挂载的（整窗覆盖层、标题栏），写一个 `function activate()`，
宿主会在注入 `api` 之后调用一次；其余情况用 `Component.onCompleted` 即可。

## 接口对象 api

身份：

| 成员 | 说明 |
| --- | --- |
| `api.pluginId` / `api.pluginName` / `api.pluginDir` | 插件 id / 显示名 / 目录本地路径 |
| `api.pluginUrl` | 插件目录 URL。加载插件自带文件要用 `api.pluginUrl + "panel.qml"` —— 相对路径会按「写这个 Loader 的 QML 文件」所在目录解析 |
| `api.window` | 主窗口，创建 `Window` / `Popup` 或找 `parent` 用 |
| `api.settings` | 插件私有配置（按插件 id 自动持久化）：`api.settings.value("k", 默认值)` / `setValue("k", v)` |

挂界面：

| 方法 | 说明 |
| --- | --- |
| `api.mount(slot, source, props)` | 把界面挂到扩展点并返回建出来的对象。`source` 传 `Component` 会同步创建，传 url 会建一个异步 `Loader`（返回值就是它，真身看 `.item`）。`props` 是初始属性，如 `{ x: 24, y: 88 }`。**挂进 `Row` / `Column` 的对象不要写 `anchors`**，位置由容器排 |
| `api.slot(name)` | 取扩展点容器（`Item`）；宿主没开这个扩展点时返回 `null` |
| `api.unmount(obj)` | 立刻回收一个挂出来的对象（比如面板里的「关闭」按钮 `api.unmount(parent)` 自卸） |

其它：

| 成员 | 说明 |
| --- | --- |
| `api.toast(text, type)` | 弹提示：`0` 警告、`1` 成功 |
| `api.warn(text)` | 控制台打一条带插件 id 的警告 |
| `api.destroyAll()` | 回收全部挂出来的对象（宿主卸载插件时自动调用，一般不用管） |

## 扩展点

名字是稳定契约，目前开放四个：

| 扩展点 | 位置 | 容器 |
| --- | --- | --- |
| `titlebar` | 标题栏（窗口按钮之前） | `Row` |
| `player` | 底栏（时间与音量之前） | `Row` |
| `sidebar.bottom` | 左侧边栏底部（宽 180） | `Column` |
| `window.overlay` | 整窗覆盖层（`z` 最上，空白处不吃鼠标） | `Item`，铺满窗口，插件自己定位 |

- 标题栏整块是窗口拖拽区：往 `titlebar` 挂的对象必须在初始化时（`Component.onCompleted` /
  `activate()`）就挂好，宿主随后统一给它们标记「可命中」；拖到定时器或异步回调里再挂，点击会被拖拽吞掉。
- 宿主没开某个扩展点时 `api.mount()` 返回 `null` 并在控制台留一条警告，插件可据此降级。

## 示例

| 插件 | 演示的东西 |
| --- | --- |
| [`Tools/play-history`](../Tools/play-history) | 挂到 `sidebar.bottom`、绑定宿主单例 `Playback.history`、点击调 `Playback.playItem()` |
| [`Tools/now-playing`](../Tools/now-playing) | `activate()` 里挂 `window.overlay`、url 异步加载自带面板、`DragHandler` 拖动后存 `api.settings`、`api.unmount(parent)` 自卸 |
| [`Tools/fake-ads`](../Tools/fake-ads) | 一次挂满四个扩展点、自绘金红广告样式、跑马灯动画、延迟弹出与自卸（整活向，演示 overlay 的 `api.window` 定位） |

## 资源与 API

- `import QueMusic 1.0` 可用公开单例与组件：`Style`（主题与设置）、`Playback`（播放 / 队列 / 历史）、
  `Options`（应用设置）、`MusicApi`（在线接口），以及 `SButton` / `QPicture` / `QMenu` 等 UI 组件。
- **不要**依赖应用内部的局部 `id`、上下文属性或未公开的私有组件，不同版本可能改名或消失。
- 插件是 QML，以应用权限运行（能联网、能读写文件），所以只安装可信插件。

## 生命周期与性能

- 只有启用中的插件会被加载，入口异步编译，不占首帧；停用 / 删除时宿主回收 `api.mount()` 建出来的一切。
- 自己 `Qt.createComponent` / `createObject` 出来的对象**不会**被自动回收，记得自己 `destroy()`。
- 加载失败（编译不过、建不出根对象、缺 `api` 属性）的插件会被自动停用并提示，修好后重新启用即可。
- 别在 `Component.onCompleted` 里做重活：费时的界面用 `api.mount(slot, url)` 异步加载。
- 不要用轮询 `Timer` 取播放状态，直接绑定 `Playback` 的属性。

## 调试

1. 把插件文件夹放到可执行文件同级的 `plugins/function/` 下，改完点设置页的「重新扫描」。
2. 运行应用的终端里会打印 QML 错误（含插件 id）。
3. 设置页 → 插件 → 功能：能看到列表、启用开关，以及加载失败被自动停用的状态。

## 提交检查清单

- [ ] `info.json` 有 `name`，`apiVersion` 为 1
- [ ] 根类型是 `QtObject` / `Item`，且声明了 `property QtObject api`
- [ ] 挂进 `Row` / `Column` 的对象没有写 `anchors`
- [ ] `info.png` 预览图；1080p 与 2K 下不遮挡宿主原有控件、不吃满 CPU
- [ ] 只用公开接口，不碰应用内部实现
- [ ] 附一张运行截图
