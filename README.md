# iM

极简 macOS Markdown 阅读器。原生 AppKit、秒开渲染、Finder 空格预览。

<p>
  <a href="https://github.com/xdfnet/iM/blob/main/LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-0ea5e9.svg"></a>
  <img alt="macOS 15+" src="https://img.shields.io/badge/macOS-15%2B-111827.svg">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-f97316.svg">
  <img alt="AppKit" src="https://img.shields.io/badge/AppKit-native-2563eb.svg">
  <img alt="Quick Look" src="https://img.shields.io/badge/Quick%20Look-supported-10b981.svg">
  <a href="doc/APPSTORE_CHECKLIST.md"><img alt="App Store Ready" src="https://img.shields.io/badge/App%20Store-ready-22c55e.svg"></a>
</p>

---

## 功能特性

- **原生体验** — 基于 AppKit + WKWebView，遵循 macOS HIG 设计
- **秒开渲染** — 大文件异步渲染，不阻塞主线程
- **Quick Look** — Finder 中空格键直接预览 Markdown 文件
- **数学公式** — 支持 KaTeX 行内和块级公式
- **图表渲染** — 支持 Mermaid 流程图、时序图等
- **代码高亮** — highlight.js 语法高亮，支持 190+ 语言
- **仅查看** — 专注阅读体验，不编辑、不留痕迹
- **轻量后台** — 以 agent 模式运行，不占用程序坞

## 系统要求

| 项目   | 版本                              |
|--------|-----------------------------------|
| macOS  | 15.0 (Sequoia) 或更高             |
| Xcode  | 16+（仅构建时需要）               |
| 架构   | Apple Silicon 或 Intel            |

## 安装

```sh
make install
```

安装后通过 Finder 双击 `.md` 文件即可打开，或使用「文件 → 打开」。

## 构建

```sh
# Debug 构建
make build

# Release 构建
make release

# App Store Archive
make archive
```

构建产物位于 `~/Library/Developer/Xcode/DerivedData/iM-*/Build/Products/`。

## 架构

```text
iM.app
├── iM                    # 主应用
│   ├── AppDelegate.swift          — 应用入口
│   ├── MarkdownDocument.swift     — NSDocument 文档管理
│   ├── DocumentWindowController.swift — 窗口生命周期
│   ├── ContentViewController.swift    — WKWebView 渲染容器
│   ├── MainSplitViewController.swift  — 视图布局
│   ├── MarkdownHTML.swift         — Markdown → HTML 渲染引擎
│   ├── MarkdownFrontmatter.swift   — YAML/TOML frontmatter 剥离
│   ├── EscapingHTMLFormatter.swift — swift-markdown 安全格式化
│   ├── MarkdownAssetSchemeHandler.swift — md-asset:// 本地资源加载
│   ├── CodeFenceInfo.swift        — 代码围栏信息解析
│   ├── FileURLHelpers.swift       — URL 工具方法
│   ├── PrivacyInfo.xcprivacy      — 隐私合规声明
│   └── Vendor/                    — 内联 JS 库
│       ├── KaTeX/                 — 数学公式
│       ├── Mermaid/               — 图表渲染
│       ├── Highlight/             — 代码高亮
│       └── DOMPurify/             — HTML 净化
├── quick-look/                    # Quick Look 扩展
│   ├── PreviewProvider.swift      — QLPreviewingController
│   └── InlineLocalAssets.swift    — 本地图片路径解析
└── doc/                           # 文档
    ├── APPSTORE_CHECKLIST.md      — App Store 上架清单
    └── build-notes.md             — 构建与安装注意事项
```

### 关键技术决策

- **线程安全** — 使用 `Synchronization.Mutex` 实现数据竞争保护，Swift 6 严格并发合规
- **安全策略** — 自定义 `md-asset://` 协议具备路径遍历防护和 Vendor 白名单机制
- **渲染性能** — Vendor JS 采用懒加载策略，大文档异步分片渲染
- **隐私合规** — 最小化 Sandbox 权限，仅请求用户选择的文件只读访问和网络客户端权限

## 发布状态

已提交至 **Mac App Store**（待上架），Category: `Utilities`。

上架流程详见 [doc/APPSTORE_CHECKLIST.md](doc/APPSTORE_CHECKLIST.md)。

## 许可

MIT License。详见 [LICENSE](LICENSE)。

---

*derived from [markdown-preview](https://github.com/pluk-inc/markdown-preview)*
