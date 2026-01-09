#!/bin/bash
# 屏保重建脚本 - 清理、构建、安装并重启相关进程

cd "$(dirname "$0")"

echo "🧹 清理构建缓存..."
xcodebuild -project KuaiShouIconScreenSaver.xcodeproj -scheme KuaiShouIconScreenSaver -configuration Debug clean >/dev/null 2>&1

echo "🔨 重新构建..."
xcodebuild -project KuaiShouIconScreenSaver.xcodeproj -scheme KuaiShouIconScreenSaver -configuration Debug build 2>&1 | grep -E "(BUILD|error)" | tail -3

if [ $? -ne 0 ]; then
    echo "❌ 构建失败！"
    exit 1
fi

echo "🗑️  删除旧屏保..."
rm -rf ~/Library/Screen\ Savers/KuaiShouIconScreenSaver.saver

echo "📦 安装新屏保..."
BUILD_DIR="/Users/wuxiangyu/Library/Developer/Xcode/DerivedData/KuaiShouIconScreenSaver-aipzokbeybxymkfxhwjolqmoucst/Build/Products/Debug"
if [ -d "$BUILD_DIR/KuaiShouIconScreenSaver.saver" ]; then
    cp -R "$BUILD_DIR/KuaiShouIconScreenSaver.saver" ~/Library/Screen\ Savers/
else
    echo "❌ 找不到构建产物！"
    exit 1
fi

echo "✍️  重新签名..."
codesign --force --sign - ~/Library/Screen\ Savers/KuaiShouIconScreenSaver.saver >/dev/null 2>&1

echo "🔄 清理屏保和系统设置缓存..."
killall ScreenSaverEngine 2>/dev/null
killall System\ Preferences 2>/dev/null
killall System\ Settings 2>/dev/null

echo ""
echo "✅ 完成！"
echo "📝 请重新打开系统设置 > 桌面与程序坞 > 屏幕保护程序查看效果"
echo ""
echo "💡 提示：如果还是黑屏，可以尝试："
echo "   1. 完全退出系统设置后重新打开"
echo "   2. 或者重启电脑（这是最彻底的方法）"
