# QuePlugins

QueMusic 的官方插件仓库。

## 目录

```
lyrics/<插件id>/    歌词界面插件：换界面，同时只能用一套
Tools/<插件id>/     功能插件：往扩展点加东西，可以同时启用多个
Network/            音乐平台插件（规划中）
docs/               开发规范
```

两类插件的目录约定与 `info.json` 字段完全一致，区别只在入口契约：

| | 歌词界面插件 | 功能插件 |
| --- | --- | --- |
| 入口根类型 | `Item`，本身就是界面 | `QtObject` / `Item`，必须声明 `property QtObject api` |
| 数据来源 | 宿主按契约注入进度、歌词、配色 | 宿主注入 `api`，插件自己 `api.mount()` 往扩展点挂界面 |
| 规范 | [lyrics-plugin.md](docs/lyrics-plugin.md) | [function-plugin.md](docs/function-plugin.md) |

## 安装

1. QueMusic → 设置 → 插件 → 歌词界面 / 功能 → **安装插件**，选插件文件夹
   （也可以点「打开插件目录」手动放进去）
2. 歌词界面插件点**启用**，之后在播放页左上角第二个按钮随时切换；
   功能插件装好即启用，界面出现在标题栏 / 底栏 / 侧栏 / 整窗覆盖层这些**扩展点**上
3. 加载失败的插件会被自动停用，原因打印在运行日志里

## 插件列表

| 插件 | 类型 | 说明 |
| --- | --- | --- |
| [lyrics/example](lyrics/example) | 歌词界面 | 基础示例：左封面 + 右歌词列表，含逐字高亮与翻译 |
| [Tools/play-history](Tools/play-history) | 功能 | 侧栏「最近播放」，点一条切回那首 |
| [Tools/now-playing](Tools/now-playing) | 功能 | 悬浮播放卡：封面 + 播放控制，可拖动、位置会记住 |
| [Tools/fake-ads](Tools/fake-ads) | 功能 | 恶搞广告：满屏「1刀999」与 VIP 角标（整活向，纯属虚构；广告图可自行替换） |

## 提交插件

1. Fork 本仓库，新建 `lyrics/<插件id>/` 或 `Tools/<插件id>/`
   （id 只用小写字母、数字、`-`、`_`）
2. 按对应规范补齐 `info.json` 与入口 QML，建议附 `info.png` 预览图
3. 发 PR，描述里附一张运行截图

> 插件是 QML 代码，以应用权限运行，请只安装你信任的插件。

## 许可

与本仓库一致（Apache-2.0），插件内可另行声明。
