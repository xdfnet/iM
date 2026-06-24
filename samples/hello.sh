#!/bin/bash
set -euo pipefail

APP_NAME="iM"
BUILD_DIR="build/Release"
APP_PATH="/Applications/${APP_NAME}.app"

echo "🔨 构建 ${APP_NAME}…"

# 清理旧构建
rm -rf "$BUILD_DIR"

# Release 构建
xcodebuild \
    -project iM.xcodeproj \
    -scheme iM \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE="Automatic" \
    build | xcbeautify

# 安装
if [ -d "$APP_PATH" ]; then
    echo "🗑  移除旧版本…"
    rm -rf "$APP_PATH"
fi

cp -R "${BUILD_DIR}/Build/Products/Release/${APP_NAME}.app" /Applications/

echo "✅ ${APP_NAME} 安装完成"
echo "💡 在 Finder 中选中文件，按空格即可预览"
