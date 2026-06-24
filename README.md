# iM

优雅的 Quick Look 预览工具。选中文件，按空格 — 语法高亮、暗色模式、数学公式、图表渲染。

<p>
  <a href="https://github.com/xdfnet/iM/blob/main/LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-0ea5e9.svg"></a>
  <img alt="macOS 15+" src="https://img.shields.io/badge/macOS-15%2B-111827.svg">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-f97316.svg">
  <img alt="Quick Look" src="https://img.shields.io/badge/Quick%20Look-first-10b981.svg">
</p>

---

## 支持的文件类型

| 类别 | 文件类型 | 扩展名 |
|------|----------|--------|
| 文档 | Markdown | `.md` `.markdown` `.mdown` `.mkd` `.mkdn` `.mdwn` `.mdtxt` `.mdtext` |
| 配置 | YAML | `.yaml` `.yml` |
| 配置 | JSON | `.json` |
| 配置 | TOML | `.toml` |
| 配置 | XML / Plist | `.xml` `.plist` |
| 配置 | INI | `.ini` `.cfg` `.conf` |
| 脚本 | Shell | `.sh` `.bash` `.zsh` |
| 脚本 | Ruby | `.rb` `.rbw` |
| 脚本 | PHP | `.php` |
| 脚本 | Perl | `.pl` `.pm` |
| 脚本 | Lua | `.lua` |
| 脚本 | R | `.r` |
| Web | HTML | `.html` `.htm` |
| Web | CSS | `.css` |
| Web | SCSS | `.scss` |
| Web | JavaScript | `.js` |
| Web | TypeScript | `.ts` `.tsx` |
| Web | GraphQL | `.graphql` `.gql` |
| 代码 | Swift | `.swift` |
| 代码 | Python | `.py` |
| 代码 | C | `.c` `.h` |
| 代码 | C++ | `.cpp` `.cc` `.cxx` `.hpp` |
| 代码 | Objective-C | `.m` |
| 代码 | Rust | `.rs` |
| 代码 | Go | `.go` |
| 代码 | Kotlin | `.kt` `.kts` |
| 代码 | SQL | `.sql` |
| 其他 | Diff/Patch | `.diff` `.patch` |

## 特性

- **空格即预览** — Finder 选中文件按空格，无需打开任何应用
- **语法高亮** — highlight.js 提供高质量代码着色，亮暗模式自适应
- **数学公式** — KaTeX 行内和块级公式渲染
- **图表渲染** — Mermaid 流程图、时序图、类图等
- **安全净化** — DOMPurify 防止 XSS，自定义 URL scheme 路径遍历防护
- **大文件保护** — JSON 超过 2MB 自动截断提示
- **零操作** — 安装后无需任何设置，即装即用

## 安装

```sh
git clone https://github.com/xdfnet/iM.git
cd iM
make install
```

安装后首次打开 iM 会自动注册 Quick Look 扩展，此后 Finder 空格键即可预览。

## 构建

```sh
make build      # Debug 构建
make release    # Release 构建
make install    # Release 构建 + 安装到 /Applications/
make clean      # 清理构建产物
```

## 架构

```
iM.app（启动即退，仅注册文件类型）
├── PreviewHTML.swift            — 渲染引擎（Markdown → HTML）
├── EscapingHTMLFormatter.swift  — 安全 HTML 格式化
├── Frontmatter.swift            — YAML/TOML 元数据解析
├── AssetSchemeHandler.swift     — md-asset:// 本地资源加载
├── CodeFenceInfo.swift          — 代码块语言检测
├── AppDelegate.swift            — Quick Look 注册器
├── Vendor/                      — 内联 JS 库
│   ├── KaTeX/                   — 数学公式
│   ├── Mermaid/                 — 图表渲染
│   ├── Highlight/               — 代码高亮
│   └── DOMPurify/               — HTML 净化
└── quick-look.appex/            — Quick Look 扩展（核心）
    ├── PreviewProvider.swift     — 文件类型分发
    └── InlineLocalAssets.swift   — 本地图片内联
```

## 新增文件类型

加一行 `case` 即可支持新类型，三步完成：

1. `Info.plist` — 声明文件类型关联
2. `quick-look/Info.plist` — 注册 QL UTI
3. `PreviewProvider.swift` — 添加 `case "ext"` 分发

## 许可

MIT License。详见 [LICENSE](LICENSE)。
