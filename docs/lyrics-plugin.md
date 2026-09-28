# 歌词界面插件规范（apiVersion 1）

歌词界面插件用 QML 写：**一个文件夹就是一个插件**，文件夹名即插件 id。
宿主在进入沉浸播放页时用 `Loader` 加载插件的入口 QML，并把播放进度、歌词数据、配色等
按下面的契约注入进来，因此插件不需要（也不应该）访问应用内部接口。

## 1. 目录结构

```
lyrics/example/               文件夹名 = 插件 id（只用小写字母、数字、- 和 _）
  info.json                   插件信息，必要
  example.qml                 入口 QML，必要（文件名在 info.json 的 entry 里指定）
  info.png                    预览图，建议 16:9 或 1:1，列表与切换面板显示
  shaders/wave.frag           自定义着色器，可选
  resources/…                 其它随插件分发的资源
```

## 2. info.json

```json
{
  "apiVersion": 1,
  "name": "波浪示例",
  "author": "QueMusic",
  "version": "1.0.0",
  "description": "着色器波浪背景 + 逐字高亮 + 双语翻译",
  "entry": "example.qml",
  "preview": "info.png"
}
```

| 字段 | 必要 | 说明 |
| --- | --- | --- |
| `apiVersion` | 否 | 契约版本，当前只支持 `1`（缺省按 1 处理）；不匹配的插件会被跳过 |
| `name` | 建议 | 显示名，缺省用文件夹名 |
| `author` / `version` / `description` | 否 | 设置页与切换面板展示用 |
| `entry` | 否 | 入口 QML 文件名，缺省 `plugin.qml` |
| `preview` | 否 | 预览图文件名，缺省 `info.png` |

入口文件不存在、或 `info.json` 解析失败时，插件会被忽略（不会让应用启动失败）。

## 3. 入口 QML 契约

入口根类型必须是 `Item`。**只要写成同名属性，宿主就会自动绑定**；没写的属性自动跳过，
所以插件可以只实现自己需要的部分。

```qml
import QtQuick

Item {
    // ---- 播放状态 ----
    property real position          // 当前播放位置（毫秒）
    property bool playing           // 是否正在播放
    property bool mediaActive       // 是否有媒体
    property real playbackRate      // 倍速

    // ---- 歌词数据 ----
    property var  lyricsModel       // 歌词行列表，见 §4
    property var  translateModel    // 翻译行列表，见 §4
    property int  currentIndex      // 当前行下标（宿主持有，跟着进度走）
    property int  lyricMove         // 用户设置的位置校准（毫秒），已含在宿主的 currentIndex 里

    // ---- 歌曲信息 ----
    property string title
    property string artist
    property url    coverUrl

    // ---- 外观 ----
    property color mainColor        // 封面取色，主题主色
    property color secondColor
    property color thirdColor
    property int   lyricSize        // 用户在「标准歌词大小」里的取值 0..20
    property int   hideHeight       // 沉浸模式收起控件时为 76，否则 0（用于让出空间）
    property bool  openTranslate    // 用户是否打开翻译
    property bool  basicCd          // 黑胶/封面卡片开关（宿主状态）
    property int   lyricType        // 0=默认 1=封面 2=歌词（宿主状态）
}
```

### 可选成员

| 成员 | 说明 |
| --- | --- |
| `function timerFunction()` | 宿主约每 320ms 调用一次；用于推进自定义动画 |
| `function requestStyle(key, value)` | 请求宿主改样式。白名单：`premiumLyricAnime`、`waveDisplay`（0/1 布尔）、`basicCd`、`lyricType` |
| `property Component styleOptions` | 在播放页「播放器样式」弹窗里追加的选项区域 |

> 样式**不要**直接改 `Style.settings`，一律走 `requestStyle()`，宿主会做白名单与范围校验。

## 4. 歌词数据

`lyricsModel` 每一项：

```js
{ time: 14290, text: "迷い間違い 進めない日々", info: [ { time: 14290, text: "迷" }, … ], isOther: false }
```

- `time`：该行开始时间（毫秒），列表已按时间升序
- `info`：**逐字/逐词时间轴**，可为空数组。有它就能做卡拉 OK 逐字高亮（见示例的 `lineHtml()`）
- `isOther`：true 表示是元信息行（作词/作曲等），可以弱化显示

`translateModel` 每一项 `{ time, text }`，与 `lyricsModel` 同下标对应；没有翻译时为空数组。

## 5. 着色器

着色器文件放在插件目录里，用**相对路径**引用即可（QML 会相对入口文件解析）：

```qml
ShaderEffect {
    anchors.fill: parent
    property color    uColorA: mainColor
    property color    uColorB: secondColor
    property color    uColorC: thirdColor
    property vector2d uResolution: Qt.vector2d(width, height)
    property real     uTime: 0
    NumberAnimation on uTime { from: 0; to: 1000; duration: 1000000; loops: Animation.Infinite }
    fragmentShader: "shaders/wave.frag"
}
```

- 顶点着色器可直接省略（用 Qt 默认的）。
- 片元着色器写法（Qt 6 规范）：

```glsl
#version 450 core
layout(location = 0) in vec2 qt_TexCoord0;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;      // 必须
    float qt_Opacity;    // 必须
    vec4 uColorA;        // 之后按名字对应 QML 里的 property
    vec2 uResolution;
    float uTime;
};

layout(location = 0) out vec4 fragColor;
```

- **建议**：直接提交 `.frag` 源文件即可（Qt 会在运行时编译）。若你的 Qt 环境不支持运行时编译，
  可以预编译一份：`qsb --qt6 shaders/wave.frag -o shaders/wave.frag.qsb`
  ```qml
  fragmentShader: "shaders/wave.frag.qsb"
  ```
- 颜色是 `vec4`，QML 里对应 `property color`；`uResolution` 用 `property vector2d`。
- 着色器只画背景：别做全屏模糊/多重 ShaderEffectSource，中低端机器容易掉帧。

## 6. 资源与 API

- 相对路径（图片、着色器、JS）按入口 QML 所在目录解析，插件应当自包含。
- 可以 `import QueMusic 1.0` 使用公开单例：`Style`（主题与设置）、`Playback`（播放列表/播放控制）、
  `MusicApi`（歌词接口）、`QueMusicConfig` 等；这些是公开接口，跨版本尽量兼容。
- **不要**依赖应用内部的局部 `id`、上下文属性或 `components/` 里的私有组件（不同版本可能改名或消失）。
- 插件是 QML，理论上能做任何 QML 能做的事（网络、写文件），因此**只安装可信插件**。

## 7. 生命周期与性能

- 沉浸播放页隐藏（或退出）时，宿主会卸载插件；再次进入重新加载，所以**不要**把关键状态只存在插件里，
  需要持久化的设置用 `requestStyle()` 交给宿主。
- `currentIndex` 与 `position` 已经由宿主维护，插件只做「显示」，不要自己扫描歌词列表。
- 逐字高亮请只对**当前行**做（示例用富文本一次性生成当前行 HTML），不要给每行都建一堆 `Text`。
- 行内容用 `ListView`/`Repeater` 时开启 `reuseItems` 或复用绑定，避免每帧创建对象。
- 插件里不要跑定时器轮询播放进度，用注入的 `position` 绑定即可。

## 8. 调试

1. 直接把插件文件夹放到**可执行文件同级**的 `plugins/lyrics/` 下，改完点设置页的「重新扫描」即可看到。
2. 运行应用的终端里会打印 QML 错误；入口报错时插件不会被选中，应用仍可正常启动。
3. 建议在插件里先只放一个 `Rectangle` 打通链路，再逐步加效果。

## 9. 提交检查清单

- [ ] `info.json` 有 `name`，`apiVersion` 为 1
- [ ] 入口 QML 根类型是 `Item`，只声明自己需要的注入属性
- [ ] `info.png` 预览图（建议 800×450 以内，别超过 300 KB）
- [ ] 在 1080p 与 2K 分辨率下都看过：不遮挡宿主左上角按钮、不吃满 CPU
- [ ] 不使用应用内部私有接口（只 `import QueMusic 1.0` 的公开单例）
- [ ] 附带一张运行截图
