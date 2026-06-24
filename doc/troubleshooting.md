# 常见问题排查

iM 开发与使用中的常见问题及解决方案。

## 扩展重复注册

> 系统设置 → 通用 → 扩展 中显示多个 iM 扩展条目。

### 1. Xcode DerivedData 残留（最常见）

**原因**：每次 `make build` 或 Xcode Run 时，LaunchServices 自动注册构建产物，不同 DerivedData 目录产生多条记录。

**解决**：

```bash
# 查看所有已注册路径
lsregister -dump 2>/dev/null | grep "iM\.app"

# 取消注册 DerivedData 中的构建产物
lsregister -u ~/Library/Developer/Xcode/DerivedData/iM-*/Build/Products/Debug/iM.app
lsregister -u ~/Library/Developer/Xcode/DerivedData/iM-*/Build/Products/Release/iM.app
```

如果目录已删除导致 `lsregister -u` 找不到路径，`make clean` 会自动处理残留注册。

### 2. 系统设置 UI 缓存

重新注册后系统设置可能还显示旧数据。

1. Cmd+Q 完全退出系统设置，再重新打开
2. 如仍存在，注销重新登录

### 3. 同类型扩展混淆

多个 Markdown 预览扩展共存时列表相似，用以下命令区分：

```bash
pluginkit -m -A -v | grep "quicklook"
```

---

## QuickLook 空格预览不生效

**原因**：扩展未正确注册，或文件类型没关联到 iM。

**解决**：

```bash
# 1. 确认扩展已注册
pluginkit -m -v | grep net.daringfireball.im.quicklook

# 2. 未找到则重新注册
pluginkit -a /Applications/iM.app/Contents/PlugIns/quick-look.appex

# 3. 修复后还需刷新 LaunchServices
/System/Library/Frameworks/CoreServices.framework/Frameworks/\
  LaunchServices.framework/Support/lsregister -f /Applications/iM.app

# 4. 重启 QuickLook 守护进程
qlmanage -r cache && qlmanage -r
```

---

## 构建签名错误

**现象**：`make build` 报签名错误。

**原因**：项目使用 ad-hoc 签名（`CODE_SIGN_IDENTITY="-"`），不需要开发者证书。

```bash
# 确认 Makefile 使用了 CODE_SIGN_IDENTITY="-"
make build

# 如果仍然报错，清理 DerivedData
make clean && make build
```

---

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

# 直接测试预览效果
qlmanage -p /path/to/file.md

# 查看 QL 进程日志
log stream --predicate 'subsystem=="com.apple.quicklook"' --level debug
```

## 预防建议

- `make clean` 会清理 DerivedData，减少残留注册
- 调试 QuickLook 优先用 `qlmanage -p <file>` 而不是安装到系统
- 重装前取消注册旧版本：`lsregister -u /Applications/iM.app && pluginkit -r /Applications/iM.app/Contents/PlugIns/quick-look.appex`
- 避免在 Xcode 中 Run 后频繁重装到 `/Applications`
