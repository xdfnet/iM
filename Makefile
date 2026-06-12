APP_NAME = iMira
LEGACY_APP_NAME = iMarkdown
XCODE_PROJECT = iMira.xcodeproj
SCHEME = iMira

DERIVED = $(shell ls -td ~/Library/Developer/Xcode/DerivedData/iMira-*/Build/Products/Release 2>/dev/null | head -1)
APP_PATH = $(DERIVED)/$(APP_NAME).app

.PHONY: build release run open install test clean

# Debug 构建（无需签名）
build:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) -configuration Debug build \
		CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Release 构建（需开发者证书）
release:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) -configuration Release build

# 运行
run: build
	open -a "$(APP_PATH)" $(file)

# 直接打开（不重新构建）
open:
	open -a "$(APP_PATH)" $(file)

# 构建并安装到 /Applications/
install: release
	rm -rf /Applications/$(LEGACY_APP_NAME).app
	rm -rf /Applications/$(APP_NAME).app
	cp -R "$(APP_PATH)" /Applications/$(APP_NAME).app
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -trusted /Applications/$(APP_NAME).app 2>/dev/null
	pluginkit -a /Applications/$(APP_NAME).app/Contents/PlugIns/quick-look.appex 2>/dev/null
	@echo "Installed /Applications/$(APP_NAME).app"

# 运行测试
test:
	swift test --package-path tests/swift-tests

# 清理构建缓存
clean:
	rm -rf ~/Library/Developer/Xcode/DerivedData/iMira-*
	rm -rf .build
