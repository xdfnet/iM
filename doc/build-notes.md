# 构建与安装注意事项

## 开发证书已吊销

当前开发证书已被吊销，无法使用正常的代码签名。构建时需要绕过签名：

```sh
# Release 构建
xcodebuild -project iM.xcodeproj -scheme iM -configuration Release build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

但直接用 `make install`（内部执行 `make release`）会失败，因为 `make release` 没有传免签名参数。

**推荐方式：**

```sh
xcodebuild -project iM.xcodeproj -scheme iM -configuration Release build \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual
  
# 然后手动复制到 /Applications
cp -R "$(find ~/Library/Developer/Xcode/DerivedData/iM-*/Build/Products/Release -name 'iM.app' -type d | head -1)" /Applications/iM.app
```

用 Xcode 命令行直接构建（传 `-` 作为签名身份）会自动带上硬化运行时（`-o runtime`），这是 macOS 26 所要求的。

## QuickLook 插件注册

构建安装后需要手动注册文件类型关联，否则 Finder 空格预览仍然显示源码：

```sh
# 注册 LaunchServices
/System/Library/Frameworks/CoreServices.framework/Frameworks/\
  LaunchServices.framework/Versions/Current/Support/lsregister -f /Applications/iM.app

# 设置 iM 为 .md 文件的默认处理器
swift -e '
import Foundation
LSSetDefaultRoleHandlerForContentType("public.markdown" as CFString, .viewer, "net.daringfireball.im" as CFString)
LSSetDefaultRoleHandlerForContentType("net.daringfireball.markdown" as CFString, .viewer, "net.daringfireball.im" as CFString)
'

# 注册 QuickLook 插件
pluginkit -a /Applications/iM.app
pluginkit -a /Applications/iM.app/Contents/PlugIns/quick-look.appex
pluginkit -e use -p com.apple.quicklook.preview -i net.daringfireball.im.quicklook

# 重置 QuickLook
qlmanage -r
killall quicklookd 2>/dev/null
```

## 系统要求

- macOS 15+（开发目标）
- 已在 macOS 26.6 (Sequoia) 上验证
- Xcode 16+
