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

原生 macOS AppKit Markdown 阅读器，基于 WKWebView 渲染。

### 核心模块

- **MarkdownHTML** — 将 markdown 渲染为独立 HTML，KaTeX/Mermaid/highlight.js/DOMPurify 全部内联
- **EscapingHTMLFormatter** — 基于 swift-markdown 的自定义 HTML 格式化器，HTML 转义安全输出
- **MarkdownFrontmatter** — YAML/TOML frontmatter 剥离与解析
- **ContentViewController** — 主内容视图控制器
- **MarkdownDocument** — NSDocument 子类，管理文件生命周期

### Vendor JS

位于 `iM/Vendor/`，编译时通过 Xcode Copy Files 打包到 app bundle：
- DOMPurify（HTML 净化）
- KaTeX（数学公式）
- Mermaid（图表）
- highlight.js（代码高亮）

## 发布流程

1. 更新 `Version.xcconfig` 中的版本号
2. 更新 `CHANGELOG.md` 和 `README.md`
3. `make release`
4. `make install`
