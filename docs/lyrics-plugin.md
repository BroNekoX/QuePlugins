# 歌词界面插件规范（apiVersion 1）

一个文件夹就是一套歌词界面，文件夹名即插件 id。宿主在进入沉浸播放页时用 `Loader` 加载入口 QML，
按下表注入数据；插件只负责渲染，不需要（也不应该）访问应用内部接口。

## 目录结构

```
lyrics/example/
  info.json            插件信息，必要
  example.qml          入口 QML，必要（文件名写在 info.json 的 entry 里）
  info.png             预览图，建议（列表与切换面板显示）
  shaders/*.frag(.qsb) 自定义着色器，可选
  resources/…          其它随插件分发的资源
```

## info.json

```json
{
  "apiVersion": 1,
  "name": "基础示例",
  "author": "QueMusic",
  "version": "1.1.0",
  "description": "左封面 + 右歌词列表",
  "entry": "example.qml",
  "preview": "info.png"
}
```

| 字段 | 必要 | 说明 |
| --- | --- | --- |
| `apiVersion` | 否 | 当前只支持 `1`（缺省按 1 处理）；不匹配的插件会被跳过 |
| `name` | 建议 | 显示名，缺省用文件夹名 |
| `entry` / `preview` | 否 | 缺省 `plugin.qml` / `info.png` |
| `author` / `version` / `description` | 否 | 设置页与切换面板展示用 |

`info.json` 解析失败或入口文件不存在时插件被直接忽略，不会影响应用启动。

## 入口契约

根类型是 `Item`（本身就是界面）。**写同名属性就会被注入**，没写的自动跳过，所以只声明用得上的：

```qml
import QtQuick

Item {
    // 播放
    property real position          // 进度 ms
    property bool playing
    property bool mediaActive
    property real playbackRate

    // 歌词
    property var  lyricsModel       // 见「歌词数据」
    property var  translateModel    // 与歌词同下标，无翻译时为空数组
    property int  currentIndex      // 当前行下标（宿主持有）
    property int  lyricMove         // 用户的位置校准 ms

    // 歌曲
    property string title
    property string artist
    property string coverUrl        // 可直接显示的 URL

    // 外观
    property color mainColor        // 封面取色（三主色）
    property color secondColor
    property color thirdColor
    property int   lyricSize        // 「标准歌词大小」0..20
    property int   hideHeight       // 沉浸模式收起控件时为 76，否则 0
    property bool  openTranslate    // 用户是否打开翻译

    // 宿主状态：只读使用即可，要改走 requestStyle
    property bool basicCd           // 黑胶 / 封面卡片
    property int  lyricType         // 0=默认 1=封面 2=歌词
}
```

### 可选成员

| 成员 | 说明 |
| --- | --- |
| `function timerFunction()` | 宿主约每 320ms 调一次，用来推进自定义动画（不要自己起定时器） |
| `property var requestStyle` | 宿主注入的回调；包一层 `function request(k, v) { if (requestStyle) requestStyle(k, v) }` 更好用 |
| `property Component styleOptions` | 追加到播放页「播放器样式」弹窗里的选项区 |

`requestStyle(key, value)` 的键是白名单：`basicCd`（黑胶开关）、`lyricType`（0/1/2）、
`premiumLyricAnime`、`waveDisplay`（0/1）。未登记的键会被忽略，**不要直接写 `Style.settings`**。

## 歌词数据

```js
{ time: 14290, text: "迷い間違い 進めない日々",
  info: [ { time: 14290, text: "迷" }, … ], isOther: false }
```

- 列表已按时间升序；`info` 是逐字/逐词时间轴，可为空数组，有它才能做卡拉 OK 高亮
- `isOther` 为 true 表示作词/作曲这类元信息行，建议弱化显示
- `translateModel[i]` 与 `lyricsModel[i]` 对应，每项 `{ time, text }`

## 着色器（可选）

放在插件目录里，用相对路径引用即可。**必须预编译成 `.qsb`** —— Qt 6 不会在运行时编译 `.frag`
（会报 `Failed to deserialize QShader` 且效果静默消失，界面照常显示只是没有背景）：

```bash
qsb --glsl "100 es,120,150,300 es,310 es,320 es" --hlsl 50 --msl 12 \
    -o shaders/wave.frag.qsb shaders/wave.frag
```

QML 侧 `property color` 对应着色器里的 `vec4`，`property vector2d` 对应 `vec2`；
`layout(std140, binding = 0) uniform buf` 里 `qt_Matrix` 与 `qt_Opacity` 必须保留。
着色器只画背景，不要做全屏模糊或多重离屏渲染，中低端机器容易掉帧。

## 性能与行为

- 页面隐藏时宿主会卸载插件，再次进入重新加载：**关键状态别只留在插件里**
- `currentIndex` 与 `position` 由宿主维护，插件只做显示，不要自己扫描歌词列表
- 逐字高亮只对当前行做（示例用富文本生成当前行），其余行保持纯文本
- 用 `ListView` / `Repeater` 时开 `reuseItems`，避免每帧创建对象

## 调试

把插件文件夹放到可执行文件同级的 `plugins/lyrics/` 下，改完点设置页的「重新扫描」即可看到；
入口报错时插件不会被选中，应用仍能正常启动。

## 提交检查清单

- [ ] `info.json` 有 `name`，`apiVersion` 为 1
- [ ] 根类型是 `Item`，只声明自己需要的注入属性
- [ ] `info.png` 预览图（建议 800×450 内，别超过 300 KB）
- [ ] 1080p 与 2K 下都看过：不遮挡宿主控件、不吃满 CPU
- [ ] 只 `import QtQuick`，或 `import QueMusic 1.0` 使用公开单例，不碰应用内部私有接口
- [ ] 附一张运行截图
