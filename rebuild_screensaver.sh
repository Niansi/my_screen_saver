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
# 动态查找构建产物路径，避免硬编码
BUILD_DIR=$(xcodebuild -project KuaiShouIconScreenSaver.xcodeproj -scheme KuaiShouIconScreenSaver -configuration Debug -showBuildSettings 2>/dev/null | grep -m 1 "BUILT_PRODUCTS_DIR" | sed 's/.*= *//')
if [ -z "$BUILD_DIR" ]; then
    # 如果动态查找失败，尝试使用默认路径
    BUILD_DIR="/Users/wuxiangyu/Library/Developer/Xcode/DerivedData/KuaiShouIconScreenSaver-aipzokbeybxymkfxhwjolqmoucst/Build/Products/Debug"
fi

if [ -d "$BUILD_DIR/KuaiShouIconScreenSaver.saver" ]; then
    echo "   找到构建产物: $BUILD_DIR/KuaiShouIconScreenSaver.saver"
    # 先删除旧屏保，确保完全清理
    rm -rf ~/Library/Screen\ Savers/KuaiShouIconScreenSaver.saver
    # 复制新屏保
    cp -R "$BUILD_DIR/KuaiShouIconScreenSaver.saver" ~/Library/Screen\ Savers/
    echo "   ✅ 屏保已安装"
else
    echo "❌ 找不到构建产物！路径: $BUILD_DIR/KuaiShouIconScreenSaver.saver"
    exit 1
fi

echo "✍️  重新签名..."
codesign --force --sign - ~/Library/Screen\ Savers/KuaiShouIconScreenSaver.saver >/dev/null 2>&1

# 验证安装是否成功（codesign 会修改二进制，不能用 MD5 与原始产物比较）
if [ -f ~/Library/Screen\ Savers/KuaiShouIconScreenSaver.saver/Contents/MacOS/KuaiShouIconScreenSaver ]; then
    echo "   ✅ 安装验证通过"
else
    echo "   ❌ 安装失败：找不到已安装的二进制"
    exit 1
fi

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
