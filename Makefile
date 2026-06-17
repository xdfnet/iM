XCODE_PROJECT = iM.xcodeproj
SCHEME = iM

.PHONY: build release install clean test run archive

build:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) -configuration Debug build \
		CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

release:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) -configuration Release build

archive:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) -configuration Release \
		-archivePath ~/Desktop/iM.xcarchive archive

install: release
	sudo rm -rf /Applications/iM.app
	cp -R "$$(find ~/Library/Developer/Xcode/DerivedData/iM-*/Build/Products/Release -name 'iM.app' -type d | head -1)" /Applications/iM.app
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f /Applications/iM.app 2>/dev/null
	pluginkit -a /Applications/iM.app/Contents/PlugIns/quick-look.appex 2>/dev/null
	@echo "Installed /Applications/iM.app"

clean:
	rm -rf ~/Library/Developer/Xcode/DerivedData/iM-*
	rm -rf ~/Desktop/iM.xcarchive
	rm -rf .build

test:
	swift test --package-path tests/swift-tests

run:
	open -a /Applications/iM.app $(file)
