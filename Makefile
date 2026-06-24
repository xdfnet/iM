XCODE_PROJECT = iM.xcodeproj
SCHEME = iM

.PHONY: build release install clean test run archive

build:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) -configuration Debug build \
		CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual

release:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) -configuration Release build \
		CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual

archive:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) -configuration Release \
		-archivePath ~/Desktop/iM.xcarchive archive

install: release
	sudo rm -rf /Applications/iM.app
	cp -R "$$(find ~/Library/Developer/Xcode/DerivedData/iM-*/Build/Products/Release -name 'iM.app' -type d | head -1)" /Applications/iM.app
	# 注册到 LaunchServices（文件类型关联），QuickLook 扩展由 app 首次启动时自注册
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f /Applications/iM.app 2>/dev/null
	@echo "Installed /Applications/iM.app — 空格预览即可使用"

clean:
	rm -rf ~/Library/Developer/Xcode/DerivedData/iM-*
	rm -rf ~/Library/Developer/Xcode/DerivedData/iM
	rm -rf ~/Desktop/iM.xcarchive
	rm -rf .build
	# 清理 LaunchServices 中已不存在的 DerivedData 注册（避免重复条目累积）
	@echo "=== 清理残留的 LaunchServices 注册 ==="
	@for path in $$(/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -dump 2>/dev/null | grep "iM\.app" | grep "DerivedData" | sed 's/.*path:[[:space:]]*//; s/[[:space:]]*(0x[0-9a-fA-F]*)//'); do \
		if [ ! -d "$$path" ]; then \
			dir=$$(dirname "$$path"); \
			mkdir -p "$$dir" 2>/dev/null; \
			touch "$$path"; \
			/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -u "$$path" 2>/dev/null; \
			rm -rf "$$dir"; \
			echo "  清理: $$path"; \
		fi; \
	done
	@echo "=== 完成 ==="

test:
	swift test --package-path iMTests/swift-tests

run:
	open -a /Applications/iM.app $(file)
