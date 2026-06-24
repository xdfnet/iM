# 架构深入

## 总览

```
Finder 空格键
    │
    ▼
┌─────────────────────────────────────────┐
│  quick-look.appex（Quick Look 扩展）      │
│                                          │
│  PreviewProvider                         │
│    │  文件扩展名分发                      │
│    ├─ .md  → PreviewHTML.makeHTML()      │
│    ├─ .sh  → wrapAsFencedCode("bash")    │
│    ├─ .py  → wrapAsFencedCode("python")  │
│    └─ ...  → PreviewHTML.makeHTML()      │
│              │                            │
│              ▼                            │
│         PreviewHTML                       │
│           │  Markdown → HTML              │
│           │  KaTeX + Mermaid + hljs       │
│           ▼                               │
│         WKWebView 渲染                    │
└─────────────────────────────────────────┘
```

## 双层架构

### 宿主 App（`iM.app`）

启动即退出，只做两件事：
1. 注册 QuickLook 扩展到 LaunchServices
2. 声明文件类型关联（CFBundleDocumentTypes / UTExportedTypeDeclarations）

不需要窗口、菜单、Dock 图标。`LSUIElement=YES` + `NSApp.setActivationPolicy(.accessory)` 确保无感运行。

### Quick Look 扩展（`quick-look.appex`）

所有渲染逻辑在此。WKWebView 加载独立 HTML，不依赖网络 — KaTeX、Mermaid、highlight.js、DOMPurify 全部内联。

## 渲染管道

### 统一入口：`PreviewHTML.makeHTML()`

```swift
PreviewHTML.makeHTML(from: markdownString, allowsScroll: true) → HTML
```

内部流程：

```
Markdown 文本
  │
  ├─ 1. Frontmatter.split()         剥离 YAML/TOML 元数据
  │
  ├─ 2. EscapingHTMLFormatter       解析为 AST 并格式化为 HTML
  │      └─ swift-markdown 引擎
  │      └─ 代码块 → <pre><code class="language-xxx">
  │      └─ GitHub Alerts → <div class="markdown-alert">
  │      └─ 普通文本 → HTML 实体转义
  │
  ├─ 3. 嵌入 Vendor JS/CSS          全部内联到 HTML
  │      ├─ DOMPurify               运行时净化（防 XSS）
  │      ├─ KaTeX                   数学公式渲染
  │      ├─ Mermaid                 图表渲染
  │      └─ highlight.js            代码语法高亮
  │
  └─ 4. 返回完整 HTML               交付给 WKWebView
```

### 代码文件适配

非 Markdown 文件通过 `wrapAndRender()` 包装：

```swift
func wrapAndRender(language: String, code: String) -> String {
    let wrapped = "```\(language)\n\(code)\n```"
    return PreviewHTML.makeHTML(from: wrapped, allowsScroll: true)
}
```

纯代码文件变成 markdown 围栏代码块，走相同渲染管线 — 统一视觉体验。

## 安全设计

### EscapingHTMLFormatter

基于 swift-markdown 的 `MarkupFormatter`，所有文本内容都经过 HTML 实体转义。用户输入中的 `<script>` 等标签不会被执行，而是呈现为纯文本。

### DOMPurify

运行时 HTML 净化层。即使格式化器产生非预期的 HTML，DOMPurify 在渲染前也会过滤危险标签和属性。

### AssetSchemeHandler

`md-asset://` 自定义 URL scheme 处理本地资源请求：
- 路径遍历防护（`../` 拒绝）
- MIME 类型识别（UTType）
- 仅允许与调用方相同的 bundle 访问

## Vendor JS 加载

所有 JS 库编译时通过 Xcode Copy Files 打包到 app bundle，运行时内联到 HTML：

```swift
// PreviewHTML 内部
enum VendorLoading {
    static func inlineAll(into html: String) -> String {
        // 从 Bundle 读取 purify/js, katex/js, mermaid/js, highlight/js
        // 以 <script> 标签形式嵌入 HTML
    }
}
```

不依赖 CDN，离线可用，渲染速度更快。

## 文件类型分发

`PreviewProvider.preparePreviewOfFile(at:)` 是文件路由入口：

| 扩展名 | 渲染方式 | 特殊处理 |
|--------|----------|----------|
| `.md` 等 | `makeHTML(from:)` 直接渲染 | 无 |
| `.json` | `makeHTML(from:text:maxBytes:)` | 2MB 截断保护 |
| `.yaml` `.toml` 等 | `wrapAndRender(language:code:)` | 围栏代码块 |
| 未知扩展 | `makeHTML(from:)` 直接渲染 | Markdown 尝试 |

## 测试

```bash
make test
# 37 个单元测试，覆盖 CodeFenceInfo / EscapingHTMLFormatter /
# Frontmatter / InlineLocalAssets 四个核心模块
```

`iMTests/swift-tests/` 通过符号链接引用源码文件，SPM 编译时无需复制代码。
