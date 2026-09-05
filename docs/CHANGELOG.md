# Linguist 桌面版更新日志

本项目严格遵循 [Semantic Versioning 2.0.0](https://semver.org/lang/zh-CN/) 语义化版本规范。

---

## [Unreleased] - 开发中

### [Added]
- 项目骨架初始化：CMake + Qt 6 Quick + C++20
- 透明窗口实现：Frameless + DWM Desktop Acrylic
- TranslatorWindow 窗口管理类：药丸/卡片状态机、窗口几何管理
- AppState 状态管理：翻译结果、设置、收藏、字号等 QML 上下文属性
- QML 设计系统：DesignTokens 单例（颜色/间距/圆角/字号/动画 Token）
- GlassSurface 毛玻璃表面组件：半透明背景 + 圆角 + 边框 + 投影 + 拖拽光环
- TrafficLights 红绿灯组件：清空/最小化/刷新
- HoverScrollText 悬停滚动文本组件：溢出检测 + 双向平滑滚动
- MarqueeText 循环跑马灯组件：药丸模式译文无限滚动
- IconButton 圆形图标按钮组件
- LanguageSelector 语言选择器组件
- SearchInput 搜索输入框组件
- WordDetailView 单词详情组件：音标/词性/释义/例句/同反义词
- PillView 药丸视图：全圆角毛玻璃 + 搜索框 + 原文|译文跑马灯 + 操作按钮
- CardView 卡片视图：顶部栏 + 搜索框 + 单词详情 + 底部栏 + 8向拉伸手柄
- main.qml 状态机：pill ↔ card 视图切换过渡动画
- 16 个 SVG 图标资源（lucide 风格描边图标）
- Demo 翻译数据：Efficient 单词完整释义

### [Fixed]
- GlassSurface.qml: `Qt5Compat.GraphicalEffects` → `QtQuick.Effects`（Qt 6.11 内置，无需 5Compat 模块）
- CMakeLists.txt: 移除 `Qt6::5Compat` 依赖（用户未安装该模块）
- TranslatorWindow.cpp: 移除 `setAttribute(Qt::WA_TranslucentBackground)`（QWindow 无此方法，改用 `setColor(Qt::transparent)`）
- TranslatorWindow.cpp: 手动定义 Windows 11 DWM 常量（`DWMWA_SYSTEMBACKDROP_TYPE`/`DWMSBT_TRANSIENTWINDOW` 等），兼容 MinGW 旧版头文件
- Application.cpp: 添加 `#include <QQuickItem>`（修复 qobject_cast 不完全类型错误）
- CMakeLists.txt: 添加 MSVC `/utf-8` 编译选项、输出目录配置
- 全部 QML 文件: Row/Column → RowLayout/ColumnLayout，修复布局属性误用

### [Docs]
- README.md 项目说明与构建指南（含 MSVC/MinGW 双路径）
- docs/ARCHITECTURE.md 系统架构设计
- docs/CHANGELOG.md 更新日志
- AGENTS.md 项目规约

### [Build]
- 首次成功编译：Qt 6.11.2 + MinGW 13.1 + Ninja，输出 `build/bin/lingust.exe`（3.6MB）
- windeployqt 自动部署运行时依赖（34 个 DLL + QML 插件，约 60MB）

---

## 版本说明

- **v0.1.x**：UI 预览阶段，实现药丸/卡片视觉效果与状态切换
- **v0.2.x**：接入翻译引擎（Gemini/DeepL/有道/离线）
- **v0.3.x**：全局划词（UIA + Clipboard + OCR）
- **v0.4.x**：截图 OCR 与原地对照
- **v0.5.x**：生词本、历史记录、TTS 发音
- **v0.6.x**：音乐控制（GSMTC）
- **v1.0.0**：托盘、开机启动、自动更新、崩溃恢复，正式发布
