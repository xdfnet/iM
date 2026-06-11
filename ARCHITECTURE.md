# 架构说明

## 概览

iMarkdown 是一个原生 macOS Markdown 阅读器，架构极简：

```
用户打开文件 → NSDocument → 读取 Markdown → 渲染为 HTML → WKWebView 展示
```

没有中间层，没有缓存，没有复杂的桥接。

## 模块

### 1. MarkdownDocument（NSDocument 子类）

负责文件读写。读取后通过 `Mutex` 线程安全存储 Markdown 文本，调用 `makeWindowControllers()` 创建窗口并传入内容。

```
文件路径 → read(from:ofType:) → markdownStorage → makeWindowControllers()
```

### 2. DocumentWindowController

管理窗口生命周期。创建窗口、设置内容视图控制器（MainSplitViewController）、居中到主屏。收到 Markdown 后传递给渲染链。

### 3. MainSplitViewController

简化容器，仅包含一个 `ContentViewController` 子视图并满铺。

### 4. ContentViewController

核心渲染单元。直接持有一个 `WKWebView`（`wantsLayer = true`），调用 `MarkdownHTML.makeHTML()` 生成 HTML 后通过 `loadHTMLString` 加载。

```swift
func display(markdown: String, assetBaseURL: URL?) {
    let html = MarkdownHTML.makeHTML(from: markdown, allowsScroll: true)
    webView.loadHTMLString(html, baseURL: nil)
}
```

没有外层 NSScrollView，没有高度回调，没有 JavaScript 桥接。

### 5. MarkdownHTML（渲染引擎）

将 Markdown 文本转换为独立 HTML 页面。处理流程：

```
body → 提取 frontmatter → 提取脚注 → 提取数学公式 →
转义 HTML → Mermaid 块 → KaTeX 块 → 脚注引用 → 标题 ID → RTL 检测
```

出产物：
- `html`：完整 HTML 页面（含 DOMPurify、内联的 KaTeX / Mermaid / highlight.js）
- `articleHTML`：仅文章正文（供 JS 更新用）

vendor 加载方式为 `.inline`，所有 JS 库嵌入 HTML 头部，无需网络请求或自定义 URL Scheme。

### 6. Quick Look 扩展（quick-look appex）

复用同样的 `MarkdownHTML.makeHTML()`，此外多一步 `InlineLocalAssets.rewriteRelativeImages()` 用于将本地图片引用转为 `cid:` 附件。

Info.plist 声明支持 `net.daringfireball.markdown` 等 UTI。

## 数据流

```
Markdown 文件
  │
  ▼
MarkdownDocument.read(from:ofType:)
  │
  ▼
MarkdownDocument.makeWindowControllers()
  │
  ▼
DocumentWindowController.display(markdown:, fileURL:)
  │
  ▼
MainSplitViewController.display()
  │
  ▼
ContentViewController.display()
  │
  ├─ MarkdownHTML.makeHTML(from:, allowsScroll:)
  │     │
  │     ├─ MarkdownFrontmatter.split()     → 剥离 YAML/TOML
  │     ├─ extractFootnotes()              → 提取脚注定义
  │     ├─ extractMath()                   → 提取 $$ $ 公式
  │     ├─ EscapingHTMLFormatter.format()  → swift-markdown → HTML
  │     ├─ renderMermaidBlocks()           → 替换 lang=mermaid
  │     ├─ renderMathBlocks()              → 替换 math token
  │     ├─ renderFootnoteReferences()       → 脚注引用编号
  │     ├─ injectHeadingIDs()              → md-heading-N
  │     └─ injectRTLDirection()            → dir=rtl
  │
  └─ WKWebView.loadHTMLString()
        │
        ▼
  Safari WebKit 渲染（Web Content 进程独立渲染）
```

## 关键技术决策

| 决策 | 理由 |
|------|------|
| `wantsLayer = true` | macOS 15 Sequoia 下 WKWebView 必须启用 layer 才能合成渲染 |
| vendor 全部内联 | 无需自定义 URL Scheme，无需网络，Quick Look 和主 app 共享同一渲染路径 |
| 无外层 NSScrollView | WKWebView 自带滚动，消除高度桥接的复杂性 |
| usesWebKit = false | 不使用弃用的 WebKit 1.0，直接使用 WKWebView |
| 无温启动 / 快路径 | 多此一举，直接加载 HTML 实测足够快 |
| 不缓存渲染结果 | 文件重新打开时重新渲染，保证一致性 |

## 文件结构

```
md-preview/                     # 主 app 源码
├── AppDelegate.swift            # 应用生命周期
├── ContentViewController.swift  # WKWebView 包装器
├── DocumentWindowController.swift # 窗口管理
├── MainSplitViewController.swift  # 容器视图
├── MarkdownDocument.swift       # NSDocument 子类
├── MarkdownHTML.swift           # 渲染引擎 + CSS
├── EscapingHTMLFormatter.swift  # swift-markdown → HTML
├── MarkdownFrontmatter.swift    # YAML/TOML frontmatter
├── MarkdownAssetSchemeHandler.swift # URL Scheme（编译依赖）
├── CodeFenceInfo.swift          # 代码围栏语言解析
├── FileURLHelpers.swift         # URL 工具方法
├── md-preview.entitlements      # 授权
├── Assets.xcassets              # 资源
├── AppIcon.icon/                # 应用图标
└── Vendor/                      # 第三方 JS 库
    ├── DOMPurify/               # HTML 净化
    ├── KaTeX/                   # 数学公式渲染
    ├── Mermaid/                 # 图表渲染
    └── Highlight/               # 代码高亮

quick-look/                     # Quick Look 预览扩展
├── PreviewProvider.swift        # QLPreviewProvider 实现
├── PreviewViewController.swift  # QLPreviewingController（未使用）
├── InlineLocalAssets.swift      # 本地图片 → cid: 附件
├── Info.plist
└── quick-look.entitlements

tests/swift-tests/              # 纯逻辑测试
└── Tests/
    ├── MarkdownHelpersTests/    # Markdown 解析 / Frontmatter / 代码围栏
    └── QuickLookHelperTests/    # InlineLocalAssets
```
