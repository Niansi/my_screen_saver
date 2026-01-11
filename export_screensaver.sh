#!/bin/bash
# 导出屏保文件用于分享

cd "$(dirname "$0")"

echo "🔨 构建 Release 版本..."
xcodebuild -project KuaiShouIconScreenSaver.xcodeproj -scheme KuaiShouIconScreenSaver -configuration Release clean build >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "❌ 构建失败！"
    exit 1
fi

RELEASE_DIR="/Users/wuxiangyu/Library/Developer/Xcode/DerivedData/KuaiShouIconScreenSaver-aipzokbeybxymkfxhwjolqmoucst/Build/Products/Release"

if [ ! -d "$RELEASE_DIR/KuaiShouIconScreenSaver.saver" ]; then
    echo "❌ 找不到构建产物！"
    exit 1
fi

# 删除桌面上的旧文件
rm -rf ~/Desktop/KuaiShouIconScreenSaver.saver

echo "📦 复制到桌面..."
cp -R "$RELEASE_DIR/KuaiShouIconScreenSaver.saver" ~/Desktop/

echo "✍️  重新签名（ad-hoc 签名，其他人也可以使用）..."
codesign --force --sign - ~/Desktop/KuaiShouIconScreenSaver.saver >/dev/null 2>&1

# 计算文件大小
SIZE=$(du -sh ~/Desktop/KuaiShouIconScreenSaver.saver | awk '{print $1}')

echo ""
echo "✅ 完成！"
echo "📁 文件位置: ~/Desktop/KuaiShouIconScreenSaver.saver"
echo "📦 文件大小: $SIZE"
echo ""
echo "💡 分享说明："
echo "   1. 将桌面上的 KuaiShouIconScreenSaver.saver 文件发送给其他人"
echo "   2. 接收者双击该文件即可安装"
echo "   3. 如果 macOS 提示无法打开，需要在'系统设置 > 隐私与安全性'中允许"
echo "   4. 安装后，在'系统设置 > 桌面与程序坞 > 屏幕保护程序'中选择使用"
