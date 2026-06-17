# iM Mac App Store 上架待办清单

> 本文档记录将 iM 发布到 Mac App Store 的全部步骤。按顺序执行。

---

## Phase 1：开发者账户与 App Store Connect

- [ ] **拥有有效的 Apple Developer 账号**（$99/年，[developer.apple.com](https://developer.apple.com)）
- [ ] **在 App Store Connect 创建 App**
  - [ ] 登录 [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → App → 新建
  - [ ] 填写基本信息：
    - **名称：** iM
    - **Bundle ID：** `net.daringfireball.im`
    - **SKU：** 例如 `IM_1`
    - **用途：** macOS App（不是 iOS）
- [ ] **填写 App 信息**
  - [ ] 副标题（可选）：极简 Markdown 阅读器
  - [ ] 分类：`实用工具 (Utilities)`
  - [ ] 年龄分级：4+
  - [ ] 定价与销售范围

---

## Phase 2：证书与签名

> 当前项目中 `CODE_SIGN_STYLE = Automatic`，Xcode 会自动管理大部分签名。提交通用只需要切换到 Distribution 证书。

- [ ] **在 Apple Developer 后台生成分发证书**
  - [ ] 登录 [developer.apple.com](https://developer.apple.com) → Certificates → 新建
  - [ ] 选择 **Mac App Store**
  - [ ] 下载 `.cer` 并双击导入钥匙串
- [ ] **生成 Mac App Store Distribution Provisioning Profile**
  - [ ] Certificates → Profiles → 新建 → **Mac App Store**
  - [ ] 关联 App ID `net.daringfireball.im`
  - [ ] 关联刚刚下载的证书
  - [ ] 下载并双击安装（Xcode 会自动识别）
- [ ] **在 Xcode 中切换签名方式**
  - [ ] 打开 `iM.xcodeproj` → target `iM` → Signing & Capabilities
  - [ ] 将 `Code Sign Identity` 从 `Apple Development` 改为 `Apple Distribution`
  - [ ] 确认 Provisioning Profile 已自动选中

---

## Phase 3：App 截图与预览素材

- [ ] **制作 Mac App Store 截图**（必须）
  - 尺寸要求：截取 1280×800 或 1440×900 或 2880×1800 等 16:10 比例的屏幕
  - 建议 3 张：
    1. 主界面 — 显示一篇带代码块和标题排版的 Markdown 文章
    2. 渲染效果 — 展示 KaTeX 公式 和/或 Mermaid 图表
    3. Finder 集成 — 显示 Quick Look 空格预览效果
  - 截图上**不能**包含设备边框或模拟器边框
- [ ] **准备 App 预览视频**（可选，但有加分）
  - 30 秒以内，展示核心操作流程

---

## Phase 4：TestFlight 内部测试（可选但推荐）

- [ ] **在 App Store Connect 启用 TestFlight**
- [ ] **添加内部测试员**（你的 Apple ID）
- [ ] **用 Distribution 签名构建上传**
  ```sh
  make archive
  ```
- [ ] **通过 Xcode Organizer 上传 Archive**
  - Window → Organizer → 选择 archive → **Distribute App** → **TestFlight**
- [ ] **在 TestFlight 中安装并验证**
  - 确认文件打开正常
  - 确认 Quick Look 扩展正常
  - 确认沙箱环境无异常

---

## Phase 5：最终检查

### 5.1 代码与构建

- [ ] **用 Release 配置构建，确认无错误**
  ```sh
  make release
  ```
- [ ] **Archive 并验证**
  ```sh
  make archive
  ```
  - 打开生成的 `~/Desktop/iM.xcarchive`
  - 使用 **Validate App** 按钮检查签名和沙箱合规
- [ ] **确认 Markdown 文件双击打开正常**
  - Finder 中双击 `.md` 文件 → iM 打开并渲染
- [ ] **确认 Quick Look 空格预览正常**
  - 选中 `.md` 文件 → 按空格键
- [ ] **确认无私有 API 调用**
  ```sh
  # 检查符号表中的非公开 API 引用
  nm -m /Applications/iM.app/Contents/MacOS/iM 2>/dev/null | grep "OBJC_CLASS.*NS" | sort -u
  ```
  所有 NS 前缀的类都应是公开的 AppKit/Foundation/WebKit 类
- [ ] **确认含隐私清单**
  ```sh
  grep -r "PrivacyInfo" /Applications/iM.app
  ```

### 5.2 沙箱验证

- [ ] 从 Finder 拖拽非用户选择的路径（如 `/tmp/test.md`）到 iM → 应弹出权限提示或优雅拒绝
- [ ] 通过 `文件 → 打开` 对话框选择文件 → 正常打开
- [ ] 在 `文件 → 打开最近使用` 中重新打开 → 正常打开
- [ ] 打开包含本地图片的 Markdown → 图片正常显示

### 5.3 元数据

- [ ] **应用描述**（准备一段简洁的英文/中文介绍）
- [ ] **关键词**（例如：Markdown, reader, preview, writing, notes）
- [ ] **支持 URL**（可以是 GitHub repo 地址）
- [ ] **隐私政策 URL**（如需，可用 [app-privacy-policy-generator](https://app-privacy-policy-generator.firebaseapp.com/) 生成）

---

## Phase 6：提交上架

- [ ] **Final Archive**
  ```sh
  make archive
  ```
- [ ] **上传到 App Store Connect**
  - Xcode → Window → Organizer → **Distribute App** → **App Store Connect**
  - 选择 Development Team
  - 选择 Distribution 证书
  - 确认 Sandbox 合规
  - 上传
- [ ] **在 App Store Connect 填写提交信息**
  - 截图
  - 描述
  - 关键词
  - 版本号（当前 `Version.xcconfig` 中为 `2.0.0`）
  - 审核备注（可选）：说明 WKWebView 的使用理由（Markdown→HTML 渲染）
- [ ] **点击「提交以供审核」**

---

## Phase 7：审核与发布

- [ ] **等待审核**（通常 1-3 个工作日）
  - 如果被拒：仔细阅读拒绝理由 → 修改 → 重新提交
  - 常见被拒原因 & 应对：
    - *Sandbox 权限不足* → 检查 `iM.entitlements` 中 `com.apple.security.files.user-selected.read-only` 和 `com.apple.security.network.client`
    - *UI 不符合 HIG* → 检查菜单栏、窗口行为
    - *缺少隐私政策* → 补充 URL
- [ ] **审核通过 → 手动发布或自动发布**
- [ ] **在 App Store 中搜索确认**
  - `macOS` → `App Store` → 搜索 iM

---

## 参考资料

| 项目 | 链接 |
|---|---|
| Apple Developer 账户 | https://developer.apple.com/account |
| App Store Connect | https://appstoreconnect.apple.com |
| 开发者协议 & 指南 | https://developer.apple.com/app-store/review/guidelines/ |
| 隐私政策生成器 | https://app-privacy-policy-generator.firebaseapp.com/ |
| Mac App Store 截图要求 | https://developer.apple.com/help/app-store-connect/ |

---

## 当前版本信息

```
MARKETING_VERSION = 2.0.0
CURRENT_PROJECT_VERSION = 1
Bundle ID: net.daringfireball.im
Deployment Target: macOS 15.0
```

> 上架前如需修改版本号，编辑 `Version.xcconfig`。
