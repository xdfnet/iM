"""Quick Look 预览文件分类器。

根据文件扩展名将文件路由到对应的预览渲染器。
"""

import json
from pathlib import Path


EXTENSION_MAP: dict[str, str] = {
    ".md": "markdown",
    ".markdown": "markdown",
    ".yaml": "yaml",
    ".yml": "yaml",
    ".json": "json",
    ".toml": "toml",
    ".xml": "xml",
    ".plist": "xml",
    ".sh": "bash",
    ".bash": "bash",
    ".zsh": "bash",
    ".swift": "swift",
    ".py": "python",
    ".js": "javascript",
    ".css": "css",
}


def classify(filepath: str) -> str | None:
    """返回文件对应的 highlight.js 语言标识符。"""
    ext = Path(filepath).suffix.lower()
    return EXTENSION_MAP.get(ext)


def is_large_json(filepath: str, limit_mb: float = 2.0) -> bool:
    """检查 JSON 文件是否超过大小限制。"""
    path = Path(filepath)
    if path.suffix.lower() != ".json":
        return False
    return path.stat().st_size > limit_mb * 1024 * 1024


if __name__ == "__main__":
    for f in ["README.md", "config.json", "script.py", "style.css"]:
        lang = classify(f)
        print(f"{f:>16}  →  {lang}")

    large = is_large_json("huge.json")
    print(f"\nhuge.json 超限: {large}")
