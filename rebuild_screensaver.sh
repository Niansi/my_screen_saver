#!/bin/bash
# 屏保重建脚本 - 清理、构建、安装并重启相关进程

set -e

cd "$(dirname "$0")"

echo "🛑 强制退出所有屏保相关进程..."
killall -9 ScreenSaverEngine   2>/dev/null || true
killall -9 legacyScreenSaver   2>/dev/null || true
killall -9 System\ Preferences 2>/dev/null || true
killall -9 System\ Settings    2>/dev/null || true

# 等文件系统释放句柄
sleep 1

echo "🧹 清理构建缓存..."
xcodebuild -project KuaiShouIconScreenSaver.xcodeproj -scheme KuaiShouIconScreenSaver -configuration Debug clean >/dev/null 2>&1

echo "🔨 重新构建..."
if ! xcodebuild -project KuaiShouIconScreenSaver.xcodeproj -scheme KuaiShouIconScreenSaver -configuration Debug build 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" | tail -5; then
    echo "❌ 构建失败！"
    exit 1
fi

# 动态查找构建产物路径，避免硬编码
BUILD_DIR=$(xcodebuild -project KuaiShouIconScreenSaver.xcodeproj -scheme KuaiShouIconScreenSaver -configuration Debug -showBuildSettings 2>/dev/null | grep -m 1 "BUILT_PRODUCTS_DIR" | sed 's/.*= *//')
if [ -z "$BUILD_DIR" ]; then
    # 如果动态查找失败，尝试使用默认路径
    BUILD_DIR="/Users/wuxiangyu/Library/Developer/Xcode/DerivedData/KuaiShouIconScreenSaver-aipzokbeybxymkfxhwjolqmoucst/Build/Products/Debug"
fi

if [ ! -d "$BUILD_DIR/KuaiShouIconScreenSaver.saver" ]; then
    echo "❌ 找不到构建产物！路径: $BUILD_DIR/KuaiShouIconScreenSaver.saver"
    exit 1
fi

echo "🗑️  删除旧屏保..."
rm -rf ~/Library/Screen\ Savers/KuaiShouIconScreenSaver.saver

echo "📦 安装新屏保..."
cp -R "$BUILD_DIR/KuaiShouIconScreenSaver.saver" ~/Library/Screen\ Savers/
echo "   ✅ 屏保已安装到 ~/Library/Screen Savers/"

echo "✍️  重新签名..."
codesign --force --sign - ~/Library/Screen\ Savers/KuaiShouIconScreenSaver.saver >/dev/null 2>&1

# 验证安装是否成功
if [ -f ~/Library/Screen\ Savers/KuaiShouIconScreenSaver.saver/Contents/MacOS/KuaiShouIconScreenSaver ]; then
    echo "   ✅ 安装验证通过"
else
    echo "   ❌ 安装失败：找不到已安装的二进制"
    exit 1
fi

echo "🔄 注册新 bundle 到系统..."
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
if [ -x "$LSREGISTER" ]; then
    "$LSREGISTER" -f ~/Library/Screen\ Savers/KuaiShouIconScreenSaver.saver 2>/dev/null || true
    echo "   ✅ 系统缓存已刷新"
fi

echo ""
echo "✅ 完成！"
echo ""
echo "🖥️  快速预览方式（任选一种）："
echo "   1. 终端运行: open -b com.apple.ScreenSaver.Engine"
echo "   2. 打开「系统设置 → 桌面与程序坞 → 屏幕保护程序」查看"
echo ""
