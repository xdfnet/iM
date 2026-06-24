/**
 * iM — Quick Look 预览工具
 *
 * 支持的语法高亮语言列表。
 * 基于 highlight.js — 代码块通过 fenced code block 标记语言，
 * 由 PreviewHTML.makeHTML() 渲染为 GitHub 风格高亮。
 */

const SUPPORTED_LANGUAGES = [
  // 文档
  { id: "markdown",     exts: [".md", ".markdown", ".mdown", ".mkd"] },

  // 配置
  { id: "yaml",         exts: [".yaml", ".yml"] },
  { id: "json",         exts: [".json"],          maxBytes: 2 * 1024 * 1024 },
  { id: "toml",         exts: [".toml"] },
  { id: "xml",          exts: [".xml", ".plist"] },

  // 脚本
  { id: "bash",         exts: [".sh", ".bash", ".zsh"] },

  // 编程语言
  { id: "swift",        exts: [".swift"] },
  { id: "python",       exts: [".py"] },
  { id: "javascript",   exts: [".js"] },

  // 样式
  { id: "css",          exts: [".css"] },
];

// 按扩展名查找
function findByExt(ext) {
  return SUPPORTED_LANGUAGES.find(
    (lang) => lang.exts.includes(ext.toLowerCase())
  );
}

console.table(
  SUPPORTED_LANGUAGES.map((l) => ({
    语言: l.id,
    扩展名: l.exts.join(", "),
    限制: l.maxBytes ? `${l.maxBytes / 1024 / 1024}MB` : "—",
  }))
);
