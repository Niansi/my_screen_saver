#!/bin/bash
# 屏保安装脚本 - 自动移除隔离属性并安装

echo "═══════════════════════════════════════════════════════════"
echo "  快手图标屏保 - 自动安装脚本"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 检查是否提供了文件路径
if [ -z "$1" ]; then
    echo "❌ 使用方法："
    echo "   将 .saver 文件拖拽到此脚本上，或运行："
    echo "   bash 安装屏保.sh <文件路径>"
    echo ""
    echo "   例如："
    echo "   bash 安装屏保.sh ~/Downloads/KuaiShouIconScreenSaver.saver"
    exit 1
fi

SAVER_FILE="$1"

# 检查文件是否存在
if [ ! -e "$SAVER_FILE" ]; then
    echo "❌ 错误：找不到文件: $SAVER_FILE"
    exit 1
fi

echo "📦 正在处理文件: $SAVER_FILE"
echo ""

# 移除隔离属性
echo "🔓 移除隔离属性..."
sudo xattr -rd com.apple.quarantine "$SAVER_FILE" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ 隔离属性已移除"
else
    echo "⚠️  移除隔离属性失败，可能需要管理员权限"
    echo "   请手动运行: sudo xattr -rd com.apple.quarantine \"$SAVER_FILE\""
fi

echo ""
echo "📥 安装屏保..."
open "$SAVER_FILE"

echo ""
echo "✅ 安装完成！"
echo ""
echo "📝 下一步："
echo "   1. 打开'系统设置' → '桌面与程序坞' → '屏幕保护程序'"
echo "   2. 在列表中选择'KuaiShouIconScreenSaver'"
echo "   3. 点击'屏幕保护程序选项'可以配置动画开关"
echo ""
echo "💡 如果仍然无法预览，请运行："
echo "   sudo xattr -rd com.apple.quarantine ~/Library/Screen\\ Savers/KuaiShouIconScreenSaver.saver"
