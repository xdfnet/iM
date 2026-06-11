# iMarkdown

原生 macOS Markdown 阅读器。开箱即用，干净利落。

## 概述

iMarkdown 是一个极简的 Markdown 文件查看器，秒开、清晰、不打扰。

- 原生 AppKit 实现，基于 WKWebView 渲染
- 支持深色模式
- Finder 空格预览（Quick Look）
- 支持 KaTeX 数学公式、Mermaid 图表、代码高亮

## 支持格式

`.md` `.markdown` `.mdown` `.mdwn` `.mkd` `.mkdn` `.mdtxt` `.mdtext`

## 构建

```sh
xcodebuild -project md-preview.xcodeproj -scheme md-preview -configuration Release build
```

产物：`iMarkdown.app`。依赖 Xcode 16+，macOS 15+。

## 架构

渲染管线极简：

1. `MarkdownDocument` 通过 NSDocument 读取文件
2. `MarkdownHTML.render()` 将 markdown 转换为独立 HTML 页面（KaTeX、Mermaid、highlight.js、DOMPurify 全部内联）
3. 直接由 `WKWebView`（`wantsLayer = true`）渲染，无 NSScrollView 嵌套、无 JS 高度桥接、无需温启动

Quick Look 扩展复用同一套 `MarkdownHTML` 代码，预览效果一致性保证。

## 致谢

基于 [markdown-preview](https://github.com/pluk-inc/markdown-preview) 改造。
