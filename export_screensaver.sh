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
rm -f ~/Desktop/README_安装说明.txt
rm -f ~/Desktop/安装屏保.sh

echo "📦 复制到桌面..."
cp -R "$RELEASE_DIR/KuaiShouIconScreenSaver.saver" ~/Desktop/
cp README_安装说明.txt ~/Desktop/ 2>/dev/null || true
cp 安装屏保.sh ~/Desktop/ 2>/dev/null || true

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
echo "   2. 接收者安装时如果遇到安全提示，请使用以下方法："
echo ""
echo "   ⚠️  如果提示'无法打开，因为 Apple 无法检查其是否包含恶意软件'："
echo "      【推荐】使用桌面上的'安装屏保.sh'脚本自动安装"
echo "      【方法一】右键点击文件 → 选择'打开' → 点击'打开'按钮"
echo "      【方法二】系统设置 → 隐私与安全性 → 点击'仍要打开'"
echo "      【方法三】终端运行: sudo xattr -rd com.apple.quarantine <文件路径>"
echo ""
echo "   3. 安装后，在'系统设置 > 桌面与程序坞 > 屏幕保护程序'中选择使用"
echo ""
echo "   ⚠️  如果安装后无法预览或使用，请在终端运行："
echo "      sudo xattr -rd com.apple.quarantine ~/Library/Screen\\ Savers/KuaiShouIconScreenSaver.saver"
echo ""
echo "📖 详细安装说明请查看桌面上的'README_安装说明.txt'文件"
