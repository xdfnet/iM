# iM

原生 macOS Markdown 阅读器。开箱即用，干净利落。

<p>
  <a href="https://github.com/xdfnet/iM/blob/main/LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-0ea5e9.svg"></a>
  <img alt="macOS 15+" src="https://img.shields.io/badge/macOS-15%2B-111827.svg">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6-f97316.svg">
  <img alt="AppKit" src="https://img.shields.io/badge/AppKit-native-2563eb.svg">
  <img alt="Quick Look" src="https://img.shields.io/badge/Quick%20Look-supported-10b981.svg">
</p>

> 极简 Markdown 阅读器：原生 AppKit、秒开渲染、Finder 空格预览。

## 概述

- 原生 AppKit 实现，基于 WKWebView 渲染
- 支持深色模式
- Finder 空格预览（Quick Look）
- 支持 KaTeX 数学公式、Mermaid 图表、代码高亮
- 以 agent 模式启动，不占用程序坞和 Cmd-Tab

## 安装

```sh
make install
```

## 构建

依赖 Xcode 16+，macOS 15+。

```sh
xcodebuild -project iM.xcodeproj -scheme iM -configuration Release build
```

## 致谢

基于 [markdown-preview](https://github.com/pluk-inc/markdown-preview) 改造。
