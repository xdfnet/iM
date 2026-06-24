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

原生 macOS QuickLook 预览工具，基于 WKWebView 渲染 10 种文件类型。

宿主 App 启动即退出，仅用于注册 QuickLook 扩展和文件类型绑定；真正的渲染逻辑全部在 `quick-look.appex` 中。

### 核心模块

- **PreviewHTML** — 渲染引擎，Markdown → 完整 HTML（KaTeX/Mermaid/highlight.js/DOMPurify 全部内联）。所有文件类型统一经围栏代码块 → `makeHTML()` 管道渲染
- **EscapingHTMLFormatter** — 基于 swift-markdown 的自定义 HTML 格式化器，HTML 转义安全输出
- **Frontmatter** — YAML/TOML frontmatter 剥离与解析
- **AssetSchemeHandler** — `md-asset://` 自定义 URL scheme，服务本地图片和 Vendor JS
- **CodeFenceInfo** — 代码块信息（语言、info string）解析
- **PreviewProvider** — QuickLook 核心，按文件扩展名分发渲染
- **InlineLocalAssets** — QuickLook 内嵌图片（cid: 协议）
- **AppDelegate** — 极简注册器：注册 QL 扩展 + 退出

### Vendor JS

位于 `iM/Vendor/`，编译时通过 Xcode Copy Files 打包到 app bundle：
- DOMPurify（HTML 净化）
- KaTeX（数学公式）
- Mermaid（图表）
- highlight.js（代码高亮，支持全部 10 种文件类型）

### Quick Look 扩展

支持文件类型：
- 文档：`.md` `.markdown` `.mdown` `.mkd` `.mkdn` `.mdwn` `.mdtxt` `.mdtext`
- 配置：`.yaml` `.yml` `.json` `.toml` `.xml` `.plist`
- 脚本：`.sh` `.bash` `.zsh`
- 代码：`.swift` `.py` `.js`
- 样式：`.css`
- JSON 文件超过 2MB 自动截断并显示提示

## 发布流程

1. 更新 `Version.xcconfig` 中的版本号
2. 更新 `CHANGELOG.md` 和 `README.md`
3. `make release`
4. `make install`
