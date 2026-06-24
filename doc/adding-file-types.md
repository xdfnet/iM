# 新增文件类型指南

加一种新文件类型只需三步。

## 第一步：声明文件类型关联

编辑 `Info.plist` → `CFBundleDocumentTypes`，添加一个 `<dict>`：

```xml
<dict>
    <key>CFBundleTypeName</key>
    <string>TypeScript Source</string>
    <key>CFBundleTypeRole</key>
    <string>Viewer</string>
    <key>LSHandlerRank</key>
    <string>Alternate</string>
    <key>LSItemContentTypes</key>
    <array>
        <string>public.typescript-source</string>
    </array>
</dict>
```

`LSHandlerRank` 取值：
- `Owner` — 系统默认用 iM 打开此类型（如 Markdown）
- `Alternate` — 备选，不抢占其他应用的关联

## 第二步：注册 QuickLook UTI

编辑 `quick-look/Info.plist` → `QLSupportedContentTypes`，添加对应的系统 UTI：

```xml
<string>public.typescript-source</string>
```

常见系统 UTI：

| UTI | 文件类型 |
|-----|----------|
| `public.shell-script` | `.sh` `.bash` `.zsh` |
| `public.swift-source` | `.swift` |
| `public.python-script` | `.py` |
| `public.xml` | `.xml` `.plist` |
| `com.netscape.javascript-source` | `.js` |
| `public.css` | `.css` |
| `public.yaml` | `.yaml` `.yml` |
| `public.json` | `.json` |
| `public.toml` | `.toml` |

## 第三步：添加分发 case

编辑 `quick-look/PreviewProvider.swift`，在 `switch ext` 中添加一个 case：

```swift
case "ts":
    html = wrapAndRender(language: "typescript", code: text)
```

## 验证

构建安装后用 `qlmanage` 测试：

```bash
make install
qlmanage -p /path/to/sample.ts
```

---

> **原理**：所有代码文件通过 markdown 围栏代码块包装，走统一的 `PreviewHTML.makeHTML()` 渲染管道。这意味着新类型自动获得语法高亮、暗色模式、KaTeX、Mermaid 等全部特性。
