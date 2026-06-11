# CLAUDE.md

## 构建与测试

```sh
# Release 构建（需代码签名）
xcodebuild -project md-preview.xcodeproj -scheme md-preview -configuration Release build

# Debug 构建（无需签名）
xcodebuild -project md-preview.xcodeproj -scheme md-preview -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# 运行逻辑测试
swift test --package-path tests/swift-tests

# 直接从 DerivedData 打开（不经过 /Applications/）
open -a "$(find ~/Library/Developer/Xcode/DerivedData/md-preview-*/Build/Products/Release -name 'iMarkdown.app' -type d | head -1)" <文件.md>

# 注册 Quick Look 扩展（安装后执行）
pluginkit -a /Applications/iMarkdown.app/Contents/PlugIns/quick-look.appex
```

## 架构要点

渲染管线极简：

```
Markdown 文件 → NSDocument → MarkdownHTML.render() → WKWebView.loadHTMLString()
```

### 核心模块

- **MarkdownDocument** — NSDocument 子类，通过 Mutex 线程安全读取文件内容
- **ContentViewController** — 持有单个 WKWebView（`wantsLayer = true`，macOS 15 必需）
- **MarkdownHTML** — 将 markdown 渲染为独立 HTML，KaTeX/Mermaid/highlight.js/DOMPurify 全部内联
- **DocumentWindowController** — 窗口生命周期，主屏居中
- **Quick Look 扩展** — 复用同一套 MarkdownHTML 代码

### macOS 15 注意事项

1. WKWebView **必须**设置 `wantsLayer = true`，否则全黑屏不渲染
2. Quick Look 扩展需要有效开发者证书签名（ad-hoc 签名被 `pluginkit` 拒绝）
3. 应用已启用沙箱（仅 `network.client` 权限），沙箱需要完整的开发证书链

### Vendor JS

编译时内联到 HTML 中，不懒加载、不用自定义 URL Scheme。位于 `md-preview/Vendor/`：

- DOMPurify（HTML 净化）
- KaTeX（数学公式）
- Mermaid（图表）
- highlight.js（代码高亮）

## 发布流程

1. 更新 `Version.xcconfig` 中的 `MARKETING_VERSION`
2. 更新 `CHANGELOG.md` 和 `README.md`
3. `xcodebuild -project md-preview.xcodeproj -scheme md-preview -configuration Release build`
4. 如需分发则复制到 `/Applications/`
