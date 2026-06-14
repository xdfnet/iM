# 更新日志

## [2.0.0] — 2026-06-14

### 重大变更

- **项目重命名为 iM。** 从 iMira 更名为 iM，Xcode 项目、源码目录、Bundle ID 全部更新。
- **清理冗余身份。** 移除之前残留的 CLI/SPM 构建产物，统一为 macOS App 单一身份。
- **全新的应用图标。** 透明底蓝色几何单线 "M"，极简风格。

## [1.2.0] — 2026-06-12

### 修复

- **macOS 15 上 WKWebView 不渲染。** Sequoia 下 WKWebView 必须设置 `wantsLayer = true` 才能正确合成，否则无论加载什么内容都是黑屏。
- **内容区域尺寸坍缩为 0。** 窗口根视图设置了 `translatesAutoresizingMaskIntoConstraints = false`，导致 AppKit 无法控制内容视图大小。删除该约束后窗口正常布局。
- **窗口打开到屏幕外。** `setFrameAutosaveName()` 恢复了之前多显示器配置下的位置。已删除自动保存，窗口始终在主屏居中。

### 变更

- **简化渲染架构。** 去掉了复杂的 NSScrollView / FlippedDocumentView / 高度回调 / 温启动 / 懒加载管线。现在直接使用纯 `WKWebView`，加载与 Quick Look 扩展相同的独立 HTML。
- **隐藏程序坞图标。** App 以 agent 模式启动，不在程序坞或 Cmd-Tab 中显示，保留窗口打开能力。
- **重命名为 iMira。** 更新 App 名、项目名、Bundle ID、菜单文案、文档和 Quick Look 扩展标识。
- **重新设计应用图标。** 透明底蓝色几何单线 "M"，极简风格。
- **明确 MIT 开源。** README 加入许可证、平台、技术栈和 Quick Look 支持卡片。
- **精简沙箱权限。** 去掉 `com.apple.security.app-sandbox` 和文件读写例外，仅保留 `network.client` 用于远程资源加载。

### 移除

- 所有不属于 iMira 核心范围的上游功能：文档大纲、文件浏览器、检查器面板、搜索 UI、工具栏、CLI 安装器、编辑器联动、LLM 联动、分享、打印、缩放、文件夹打开、更新组件以及 Sparkle 依赖。

### 清理

- 源码从 30 个文件精简到 11 个，删除了 `MarkdownWebView.swift`、`HairlineSeparator.swift` 以及侧栏、检查器、搜索栏、目录等模块。
- 清除了之前调试版本在 LaunchServices 中的残留记录。
- 清理了 `docs/` 目录中的过时截图和上游素材。
- 重写了 `README.md` 和 `CLAUDE.md`。

## [1.1.0] — 2026-06-11

首个 iMira 版本。从 `pluk-inc/markdown-preview` 复刻并重新品牌化。
