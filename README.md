# KuaiShouIconScreenSaver

一款运行在 macOS 上的屏保程序，用像素与时间对话，用颜色记录每一分钟的流逝。

---

## 屏保模式

### 快手图标模式

从早上 10:00 到晚上 22:00，整整 720 分钟，屏幕上有 720 个几何图形。

每一个图形代表这一天里的一分钟——圆形、方形、三角形、六边形，以快手橙（RGB 253, 73, 9）为墨，在黑色宇宙中燃烧。随着时间推进，已过去的分钟逐一点亮，未来的分钟仍在沉睡。开启动效后，图形会在每次渲染间以 20fps 的频率呼吸、形变，像是时间本身在律动。

遇到节日，图形会悄悄换成 emoji，把日历里那些特别的刻度染上人情味。

> 时间不会等你，但它会在屏幕上为你留下痕迹。

### Kim 年度回顾模式

暖色的世界。

屏幕被切分成若干横向条带，颜色从顶部的奶白（HSL 38°, 80%, 93%）向底部的琥珀橙（HSL 30°, 68%, 52%）渐变，像是落日余晖凝固在玻璃上。横屏 5 条、竖屏 9 条，每一条都有圆润的上边角，像翻页日历，像一年的章节。

中间条带正中央，可以开启当前时间显示——字体够大，够骄傲，颜色是与条带反向的渐变，深色映在浅色里，浅色映在深色里，互为倒影。

---

## 安装

### 使用安装脚本（推荐）

```bash
bash 安装屏保.sh ~/Downloads/KuaiShouIconScreenSaver.saver
```

脚本会自动移除 macOS 隔离属性并安装到 `~/Library/Screen Savers/`。

### 手动安装

1. 双击 `KuaiShouIconScreenSaver.saver` 文件
2. 系统设置 → 桌面与程序坞 → 屏幕保护程序 → 选择 **KuaiShouIconScreenSaver**

### 遇到"Apple 无法检查其是否包含恶意软件"

macOS Gatekeeper 的正常反应，代码完全开源透明。解决方法任选其一：

**右键打开**（最简单）：右键点击 `.saver` 文件 → 选择「打开」→ 确认打开。

**系统设置放行**：系统设置 → 隐私与安全性 → 底部点击「仍要打开」。

**终端命令**：
```bash
sudo xattr -rd com.apple.quarantine ~/Downloads/KuaiShouIconScreenSaver.saver
```

安装后若仍无法预览，对已安装路径执行同样操作：
```bash
sudo xattr -rd com.apple.quarantine ~/Library/Screen\ Savers/KuaiShouIconScreenSaver.saver
```

---

## 配置

屏保选项面板提供：

| 设置项 | 适用模式 | 说明 |
|--------|---------|------|
| 屏保类型 | 全部 | 快手图标 / Kim 年度回顾 |
| 启用动态效果 | 快手图标 | 图形形变动画（20fps） |
| 显示时间 | Kim 年度回顾 | 在屏幕中央显示当前时间 |

---

## 本地构建

```bash
bash rebuild_screensaver.sh
```

构建产物自动安装到本机，可在系统设置中立即预览。

---

## 技术栈

- Objective-C · ScreenSaver.framework · CoreGraphics · CoreText
- macOS 原生渲染，零依赖，零后台进程
