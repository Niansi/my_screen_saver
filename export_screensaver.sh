#!/bin/bash
# 导出屏保文件用于分享 - 自动打包成 zip

cd "$(dirname "$0")"

echo "═══════════════════════════════════════════════════════════"
echo "  快手图标屏保 - 导出打包脚本"
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "🔨 构建 Release 版本..."
xcodebuild -project KuaiShouIconScreenSaver.xcodeproj -scheme KuaiShouIconScreenSaver -configuration Release clean build 2>&1 | grep -E "(BUILD|error)" | tail -3

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ 构建失败！"
    exit 1
fi

# 动态查找构建产物路径
BUILD_DIR=$(xcodebuild -project KuaiShouIconScreenSaver.xcodeproj -scheme KuaiShouIconScreenSaver -configuration Release -showBuildSettings 2>/dev/null | grep -m 1 "BUILT_PRODUCTS_DIR" | sed 's/.*= *//')
if [ -z "$BUILD_DIR" ]; then
    # 如果动态查找失败，尝试使用默认路径
    BUILD_DIR="$HOME/Library/Developer/Xcode/DerivedData/KuaiShouIconScreenSaver-*/Build/Products/Release"
    BUILD_DIR=$(eval echo $BUILD_DIR | head -1)
fi

RELEASE_DIR="$BUILD_DIR"

if [ ! -d "$RELEASE_DIR/KuaiShouIconScreenSaver.saver" ]; then
    echo "❌ 找不到构建产物！路径: $RELEASE_DIR/KuaiShouIconScreenSaver.saver"
    exit 1
fi

echo "✅ 构建成功！"
echo ""

# 创建临时打包目录
PACKAGE_DIR="$HOME/Desktop/KuaiShouIconScreenSaver_Package"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

echo "📦 准备打包文件..."

# 复制屏保文件
cp -R "$RELEASE_DIR/KuaiShouIconScreenSaver.saver" "$PACKAGE_DIR/"

# 重新签名（ad-hoc 签名，不需要开发者账号）
echo "✍️  重新签名（ad-hoc 签名）..."
codesign --force --sign - "$PACKAGE_DIR/KuaiShouIconScreenSaver.saver" >/dev/null 2>&1

# 创建一键安装脚本
cat > "$PACKAGE_DIR/一键安装.sh" << 'INSTALL_SCRIPT'
#!/bin/bash
# 快手图标屏保 - 一键安装脚本
# 自动处理所有 macOS 安全限制

echo "═══════════════════════════════════════════════════════════"
echo "  快手图标屏保 - 一键安装"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SAVER_FILE="$SCRIPT_DIR/KuaiShouIconScreenSaver.saver"

# 检查屏保文件是否存在
if [ ! -d "$SAVER_FILE" ]; then
    echo "❌ 错误：找不到屏保文件: $SAVER_FILE"
    echo ""
    echo "请确保此脚本与 KuaiShouIconScreenSaver.saver 在同一目录下"
    exit 1
fi

echo "📦 正在安装屏保..."
echo ""

# 1. 移除隔离属性（解决"无法打开"问题）
echo "🔓 步骤 1/3: 移除隔离属性..."
xattr -rd com.apple.quarantine "$SAVER_FILE" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ 隔离属性已移除"
else
    echo "   ⚠️  需要管理员权限，请输入密码："
    sudo xattr -rd com.apple.quarantine "$SAVER_FILE" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "   ✅ 隔离属性已移除"
    else
        echo "   ⚠️  移除隔离属性失败，但可以继续安装"
    fi
fi

# 2. 删除旧版本（如果存在）
echo ""
echo "🗑️  步骤 2/3: 清理旧版本..."
OLD_SAVER="$HOME/Library/Screen Savers/KuaiShouIconScreenSaver.saver"
if [ -d "$OLD_SAVER" ]; then
    rm -rf "$OLD_SAVER"
    echo "   ✅ 旧版本已删除"
else
    echo "   ℹ️  未发现旧版本"
fi

# 3. 安装新版本
echo ""
echo "📥 步骤 3/3: 安装屏保..."
open "$SAVER_FILE"

echo ""
echo "✅ 安装完成！"
echo ""
echo "📝 下一步操作："
echo "   1. 打开'系统设置' → '桌面与程序坞' → '屏幕保护程序'"
echo "   2. 在列表中选择'KuaiShouIconScreenSaver'"
echo "   3. 点击'屏幕保护程序选项'可以配置动画开关"
echo ""
echo "💡 如果仍然无法预览，请运行以下命令："
echo "   sudo xattr -rd com.apple.quarantine ~/Library/Screen\\ Savers/KuaiShouIconScreenSaver.saver"
echo ""
read -p "按回车键退出..."
INSTALL_SCRIPT

chmod +x "$PACKAGE_DIR/一键安装.sh"

# 创建 README 文件
cat > "$PACKAGE_DIR/README.txt" << 'README'
═══════════════════════════════════════════════════════════
  快手图标屏保 - 安装说明
═══════════════════════════════════════════════════════════

📦 安装方法（推荐）：

   方法一：一键安装（最简单）
   ───────────────────────────────────────────────────────
   1. 双击运行"一键安装.sh"
   2. 如果提示需要权限，请输入密码
   3. 安装完成后，打开"系统设置" → "桌面与程序坞" → "屏幕保护程序"
   4. 选择"KuaiShouIconScreenSaver"即可使用

   方法二：手动安装
   ───────────────────────────────────────────────────────
   1. 双击"KuaiShouIconScreenSaver.saver"文件
   2. 如果提示"无法打开"，请：
      a) 右键点击文件 → 选择"打开" → 点击"打开"按钮
      或
      b) 打开"系统设置" → "隐私与安全性" → 点击"仍要打开"
   3. 安装完成后，在"系统设置"中选择使用

⚠️  如果遇到问题：

   问题1：提示"无法打开，因为 Apple 无法检查其是否包含恶意软件"
   ───────────────────────────────────────────────────────
   这是 macOS 的正常安全提示，解决方法：
   
   【推荐】运行"一键安装.sh"脚本，会自动处理
   
   【手动解决】在终端运行：
   sudo xattr -rd com.apple.quarantine ~/Downloads/KuaiShouIconScreenSaver.saver
   （将路径替换为实际文件路径）

   问题2：安装后无法预览或使用
   ───────────────────────────────────────────────────────
   在终端运行：
   sudo xattr -rd com.apple.quarantine ~/Library/Screen\ Savers/KuaiShouIconScreenSaver.saver

   问题3：双击脚本没有反应
   ───────────────────────────────────────────────────────
   在终端运行：
   bash 一键安装.sh
   （在解压后的文件夹中运行）

📖 功能说明：

   • 显示 720 个图形，从早上 10:00 到晚上 22:00 逐步填充
   • 支持多种图形类型：圆形、三角形、长方形
   • 支持平滑的图形切换动画
   • 支持节日 emoji 显示（春节、中秋、国庆等）
   • 可在设置中开启/关闭动画效果

💡 提示：

   • 此屏保不需要开发者账号即可使用
   • 使用 ad-hoc 签名，安全可靠
   • 如果遇到任何问题，请查看上述解决方案

═══════════════════════════════════════════════════════════
README

# 打包成 zip
ZIP_FILE="$HOME/Desktop/KuaiShouIconScreenSaver.zip"
rm -f "$ZIP_FILE"

echo ""
echo "📦 正在打包..."
cd "$PACKAGE_DIR"
zip -r "$ZIP_FILE" . >/dev/null 2>&1

# 计算文件大小
ZIP_SIZE=$(du -sh "$ZIP_FILE" | awk '{print $1}')
SAVER_SIZE=$(du -sh "$PACKAGE_DIR/KuaiShouIconScreenSaver.saver" | awk '{print $1}')

echo ""
echo "✅ 打包完成！"
echo ""
echo "📁 文件位置: $ZIP_FILE"
echo "📦 ZIP 大小: $ZIP_SIZE"
echo "📦 屏保大小: $SAVER_SIZE"
echo ""
echo "📋 包含文件："
echo "   • KuaiShouIconScreenSaver.saver (屏保文件)"
echo "   • 一键安装.sh (一键安装脚本)"
echo "   • README.txt (安装说明)"
echo ""
echo "💡 分享说明："
echo "   1. 将 $ZIP_FILE 发送给朋友"
echo "   2. 朋友解压后，双击运行'一键安装.sh'即可"
echo "   3. 所有 macOS 安全问题都会自动处理"
echo ""
echo "🎉 完成！可以分享给朋友了！"
