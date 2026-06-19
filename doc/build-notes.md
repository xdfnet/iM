# 构建与安装注意事项

## 开发证书已吊销

当前开发证书已被吊销，无法使用正常的代码签名。`Makefile` 已配置为 ad-hoc 签名（`CODE_SIGN_IDENTITY="-"`），`make build` / `make release` / `make install` 均可直接使用，无需额外操作。

```sh
# 直接构建安装
make build     # Debug 构建（ad-hoc 签名）
make install   # Release 构建 + 安装到 /Applications（ad-hoc 签名）
```

ad-hoc 签名用 `-` 作为签名身份，Xcode 会自动生成本地签名并附带 hardened runtime（`-o runtime`），满足 macOS 26 要求。

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
