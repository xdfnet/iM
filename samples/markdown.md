# iM — 优雅的 Quick Look 预览

空格键预览 Markdown，支持 **粗体**、*斜体*、`内联代码`、~~删除线~~。

## 表格

| 特性 | 状态 | 备注 |
|------|------|------|
| KaTeX 数学 | ✅ | 行内与块级 |
| Mermaid 图表 | ✅ | 流程图/时序图 |
| 语法高亮 | ✅ | highlight.js |
| 暗色模式 | ✅ | 自适应 |

## 数学公式

行内公式：$E = mc^2$，再如 $\sqrt{3x-1}+(1+x)^2$。

块级公式：

$$
f(x) = \int_{-\infty}^\infty \hat{f}(\xi) \, e^{2 \pi i \xi x} \, d\xi
$$

## 代码高亮

```swift
struct Release: Decodable, Identifiable {
    let id: String
    let version: String
    let publishedAt: Date

    var isLatest: Bool {
        version.hasPrefix("3.")
    }
}
```

## Mermaid 图表

```mermaid
flowchart LR
    Markdown --> PreviewHTML
    PreviewHTML --> HTML
    HTML --> WKWebView
    WKWebView --> Preview
```

## 列表

- 无需打开任何应用
- 支持 10 种文件类型
- 自动语法高亮
- 暗色模式自适应

---

> [!TIP]
> 安装后在 Finder 中选中文件，按空格键即可预览。
