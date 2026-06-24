# 更新日志

## [3.0.0] — 2026-06-24

### 重大变更

- **重新定位为纯 Quick Look 预览工具。** 移除 NSDocument 编辑器架构，不再作为阅读器应用运行。App 负责注册 Quick Look 扩展后即退出，所有渲染由 Quick Look 扩展完成。
- **架构精简为 8 个 Swift 文件。** 从 12 个文件降至 6 个核心模块 + 2 个 Quick Look 文件。

### 新增

- **支持 10 种文件类型预览。** Markdown、YAML、JSON、TOML、Shell、Swift、Python、XML、JavaScript、CSS — 统一渲染管线，语法高亮、暗色模式、数学公式、图表渲染。
- **统一渲染管线。** 所有代码文件通过 markdown 围栏代码块包装，经同一 `PreviewHTML.makeHTML()` 管道渲染，视觉体验一致。
- **添加 GitHub 主题。** highlight.js 使用 GitHub 风格语法高亮，亮暗模式自适应。
- **JSON 大文件保护。** 超过 2MB 自动截断并显示提示。
- **字符串/字节精确截断。** 修复 `String.prefix()` 字符截断导致 UTF-8 多字节字符损坏的问题。

### 移除

- **7 个文件删除。** `ContentViewController.swift`、`MainSplitViewController.swift`、`DocumentWindowController.swift`、`MarkdownDocument.swift`、`MarkdownWebView.swift`、`FileURLHelpers.swift`、`MainMenu.xib`。
- **自定义 UTI 声明。** YAML/YML/TOML 改用系统 UTI（`public.yaml`、`public.toml`），移除 `net.daringfireball.im.yaml`、`net.daringfireball.im.toml`。
- **双主题架构。** 移除 Monokai 暗色主题系统，统一为 GitHub 主题自适应。
- **所有文档编辑相关 IBAction。** 不再需要 `@IBAction` 菜单操作方法。

### 重命名

- `MarkdownHTML` → `PreviewHTML`
- `MarkdownFrontmatter` → `Frontmatter`
- `MarkdownAssetScheme` → `AssetSchemeHandler`
- `MarkdownHTMLBundleToken` → `PreviewHTMLBundleToken`

### 修复

- **CSS 层叠冲突。** Monokai 主题 CSS 被 highlight.js GitHub Dark CSS 覆盖，移除双主题架构彻底解决。
- **`.yml`/`.toml` Quick Look 不生效。** 自定义 UTI 不匹配系统类型，切换为系统 UTI 解决。
- **字节截断 Bug。** `text.utf8.count`（字节）与 `String.prefix()`（字符）不匹配，改用逐字符累加字节数截断。
