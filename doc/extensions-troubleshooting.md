# 扩展重复注册排查指南

> 系统设置 → 通用 → 扩展 中显示多个 iM 扩展条目的问题排查与解决。

## 问题现象

系统设置的扩展列表中出现多个 iM 扩展（如 2～3 个），但实际只安装了一份。

## 常见原因

### 1. Xcode DerivedData 残留注册（最常见）

**根本原因**：Xcode 每次 `make build` 或 Run（⌘R）时，LaunchServices 会自动注册构建产物。Debug / Release 构建产物分别在：

```
~/Library/Developer/Xcode/DerivedData/iM-*/Build/Products/Debug/iM.app
~/Library/Developer/Xcode/DerivedData/iM-*/Build/Products/Release/iM.app
```

每次 `make build` 或 Xcode 运行，系统都会注册一份。不同 DerivedData 目录会产生多条注册记录，系统设置中就会显示多个 iM 条目。

**解决方法**：

```bash
# 1. 查看所有已注册的 iM.app 路径
/System/Library/Frameworks/CoreServices.framework/Frameworks/\
  LaunchServices.framework/Support/lsregister -dump 2>/dev/null | grep "iM\.app"

# 2. 取消注册 DerivedData 中的构建产物
lsregister -u ~/Library/Developer/Xcode/DerivedData/iM-*/Build/Products/Debug/iM.app
lsregister -u ~/Library/Developer/Xcode/DerivedData/iM-*/Build/Products/Release/iM.app

# 3. 如果目录已删除导致 lsregister -u 找不到路径
#    需要重建临时 bundle，再取消注册，最后清理临时文件
mkdir -p /tmp/dummy/iM.app/Contents/MacOS
cat > /tmp/dummy/iM.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>net.daringfireball.im</string>
  <key>CFBundleExecutable</key><string>iM</string>
</dict></plist>
EOF
echo '#!/bin/sh' > /tmp/dummy/iM.app/Contents/MacOS/iM
chmod +x /tmp/dummy/iM.app/Contents/MacOS/iM
lsregister -u /tmp/dummy/iM.app
rm -rf /tmp/dummy
```

### 2. 系统设置界面缓存未刷新

重新注册后系统设置的 UI 缓存可能还显示旧数据（概率较低）。

**解决方法**：

1. Cmd+Q 完全退出系统设置，再重新打开
2. 如果还不行，注销登录重新进

### 3. 其他 Markdown 扩展混淆

系统中有多个 Markdown 预览扩展（iMarkdown、QLMarkdown 等），在 QuickLook 列表中可能看起来相似。用以下命令区分实际注册的项：

```bash
pluginkit -m -A -v | grep "quicklook"
```

## 诊断命令速查

```bash
# 查看所有扩展注册（含路径）
pluginkit -m -A -v

# 查看 iM QuickLook 扩展
pluginkit -m -v | grep net.daringfireball.im

# 查看 LaunchServices 注册
lsregister -dump 2>/dev/null | grep "iM\.app"

# 查看系统设置扩展缓存数据库
sqlite3 ~/Library/Preferences/com.apple.LaunchServices/\
  com.apple.LaunchServices.SettingsStore.sql "SELECT * FROM Election;"

# 查看 BTM 后台活动记录
sfltool dumpbtm | grep daringfireball
```

## 预防建议

- `make clean` 会清理 DerivedData，减少残留注册
- 避免直接在 Xcode 中 Run（⌘R）后频繁重装到 `/Applications`
- 如果只是调试 QuickLook，优先用 `qlmanage -p <file>` 而不是安装到系统
- 重装前可以先取消注册旧版本：`lsregister -u /Applications/iM.app && pluginkit -r /Applications/iM.app/Contents/PlugIns/quick-look.appex`

## 相关文档

- [Mac系统扩展管理参考](https://support.apple.com/guide/mac-help/mchl53f4b73/mac) — Apple 官方文档
