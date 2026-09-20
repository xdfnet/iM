# CLAUDE.md

## 构建与测试

```sh
# Debug 构建
make build

# Release 构建
make release

# 安装到 /Applications/
make install

# 运行测试
make test

# 清理
make clean
```

## 架构要点

原生 macOS 文件阅读器 + QuickLook 预览工具，基于 WKWebView 渲染 28 种文件类型。

两个入口共用同一条渲染管线：QuickLook 扩展（`quick-look.appex`，空格预览）与宿主 App 内的只读阅读器（NSDocument + WKWebView 窗口）。文件类型分发统一在共享的 `FileContentRenderer`，保证两入口渲染一致。

宿主 App 无文件启动时仅注册扩展并在约 0.5 秒后退出；带文件启动时作为阅读器常驻，关闭最后一个窗口即退出。纯代码 App（无 nib），`@main` 显式实现 `static func main()` 手动创建并持有 `AppDelegate`——合成入口只调 `NSApplicationMain`，不会挂载 delegate。

### 核心模块

- **FileContentRenderer** — 文件类型分发（app / appex / tests 共享）：读文本、Markdown 变体透传、已知语言包围栏、JSON 2MB 截断，再交 PreviewHTML
- **PreviewHTML** — 渲染引擎，Markdown → 完整 HTML（KaTeX/Mermaid/highlight.js/DOMPurify 全部内联）。所有文件类型统一经围栏代码块 → `makeHTML()` 管道渲染
- **EscapingHTMLFormatter** — 基于 swift-markdown 的自定义 HTML 格式化器，HTML 转义安全输出
- **Frontmatter** — YAML/TOML frontmatter 剥离与解析
- **AssetSchemeHandler** — `md-asset://` 自定义 URL scheme，服务本地图片和 Vendor JS
- **CodeFenceInfo** — 代码块信息（语言、info string）解析
- **PreviewProvider** — QuickLook 预览面板（`QLPreviewingController`），调用 FileContentRenderer
- **InlineLocalAssets** — QuickLook 内嵌图片（cid: 协议）
- **ReaderDocument** — 阅读器的只读 `NSDocument`（禁撤销/保存/还原），由 NSDocumentController 负责打开、复用、最近记录
- **ReaderWindowController** — 阅读窗口：WKWebView 加载首屏，外部改动经 `window.iM.update(...)` 增量更新、保留滚动；首次出现数学/图表/代码时整页重载兜底
- **FileWatcher** — `DispatchSource` 文件监听，write/extend 防抖刷新；delete/rename 后重开 fd 以兼容原子保存，真删除则保留旧内容
- **AppDelegate** — 入口：纯代码主菜单、open 事件路由、无文件延迟退出、QL 扩展注册

### Vendor JS

位于 `iM/Vendor/`，编译时通过 Xcode Copy Files 打包到 app bundle：
- DOMPurify（HTML 净化）
- KaTeX（数学公式）
- Mermaid（图表）
- highlight.js（代码高亮，支持全部 28 种文件类型）

### 两个入口

支持的 28 种文件类型以 README 表格为准，两入口通过 `FileContentRenderer.supportedExtensions` 保持一致。JSON 超过 2MB 自动截断并显示提示。

- **Quick Look 扩展（`quick-look.appex`）**：`PreviewProvider` + `InlineLocalAssets`，本地图片走 file baseURL / cid 内联
- **阅读器（app）**：`ReaderDocument` / `ReaderWindowController` / `FileWatcher`，本地图片走 `md-asset://` scheme；严格只读

## 发布流程

1. 更新 `Version.xcconfig` 中的版本号
2. 更新 `CHANGELOG.md` 和 `README.md`
3. `make release`
4. `make install`
