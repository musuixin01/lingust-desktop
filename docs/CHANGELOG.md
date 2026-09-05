# Linguist 桌面版更新日志

本项目严格遵循 [Semantic Versioning 2.0.0](https://semver.org/lang/zh-CN/) 语义化版本规范。

---

## [Unreleased] - 开发中

### [Added]
- 项目骨架初始化：CMake + Qt 6 Quick + C++20
- 透明窗口实现：Frameless + per-pixel alpha 圆角
- TranslatorWindow 窗口管理类：药丸/卡片状态机、窗口几何管理、尺寸动画
- AppState 状态管理：翻译结果、设置、收藏、字号等 QML 上下文属性
- QML 设计系统：DesignTokens 单例（颜色/间距/圆角/字号/动画 Token）
- GlassSurface 毛玻璃表面组件：半透明背景 + 圆角 + 边框 + 投影 + 自动漫游高光
- TrafficLights 红绿灯组件：清空/最小化/刷新
- HoverScrollText 悬停滚动文本组件：溢出检测 + 双向平滑滚动
- MarqueeText 循环跑马灯组件：药丸模式译文无限滚动
- IconButton 圆形图标按钮组件
- LanguageSelector 语言选择器组件
- SearchInput 搜索输入框组件
- WordDetailView 单词详情组件：音标/词性/释义/例句/同反义词/美英发音
- PillView 药丸视图：全圆角纯黑 + 搜索框 + 原文|译文跑马灯 + 操作按钮
- CardView 卡片视图：顶部栏 + Flickable 内容区 + 操作工具栏 + 底部栏 + 8向拉伸手柄
- SettingsView 设置页面：引擎选择/API密钥/划词开关/自动发音/紧凑模式/透明度/字体大小
- Main.qml 状态机：pill ↔ card 视图切换过渡动画 + 尺寸动画
- 16 个 SVG 图标资源（lucide 风格描边图标）
- Demo 翻译数据：Efficient 单词完整释义

### 翻译引擎
- TranslationManager 翻译管理器：统一 Provider 接口，可插拔引擎
- GeminiProvider：Gemini 2.0 Flash API，支持单词详情 JSON 解析
- DeepLProvider：DeepL API（Free/Pro 自动识别）
- YoudaoProvider：有道翻译 API，SHA256 签名，单词详情解析
- 离线模式：原文回退

### 数据持久化
- DatabaseManager：SQLite 数据库管理
- 历史记录表：自动保存翻译记录，支持查询/清空/删除
- 收藏表：生词收藏，支持添加/删除/查询
- 数据库路径：%APPDATA%/Linguist/lingust.db

### 全局划词
- SelectionManager：Clipboard 方案全局划词翻译
- 模拟 Ctrl+C 复制选中文本
- GetClipboardSequenceNumber 安全恢复剪贴板
- 异步等待剪贴板变化（短超时轮询）

### TTS 发音
- SAPI.SpVoice 语音合成（mshta vbscript 调用，启动快）
- 美式英语：Microsoft Zira Desktop
- 英式英语：Microsoft Hazel Desktop
- 中文：Microsoft Huihui Desktop
- 美音/英音按钮切换

### 系统集成
- TrayManager：系统托盘图标 + 右键菜单
- 托盘菜单：显示主窗口/截图翻译/设置/退出
- 开机启动：注册表 HKCU\...\Run
- QApplication 替代 QGuiApplication（支持 Widgets/托盘）
- setQuitOnLastWindowClosed(false)：关窗不退出

### 截图 OCR 框架
- CaptureManager：全屏截图（QScreen::grabWindow）
- OcrManager：OCR 引擎管理
- IOcrProvider：OCR Provider 接口（可插拔）
- 待实现：截图覆盖层、区域选择、Windows OCR / PaddleOCR

### [Fixed]
- GlassSurface.qml: `Qt5Compat.GraphicalEffects` → `QtQuick.Effects`（Qt 6.11 内置，无需 5Compat 模块）
- CMakeLists.txt: 移除 `Qt6::5Compat` 依赖（用户未安装该模块）
- TranslatorWindow.cpp: 移除 `setAttribute(Qt::WA_TranslucentBackground)`（QWindow 无此方法，改用 `setColor(Qt::transparent)`）
- TranslatorWindow.cpp: 手动定义 Windows 11 DWM 常量（`DWMWA_SYSTEMBACKDROP_TYPE`/`DWMSBT_TRANSIENTWINDOW` 等），兼容 MinGW 旧版头文件
- Application.cpp: 添加 `#include <QQuickItem>`（修复 qobject_cast 不完全类型错误）
- CMakeLists.txt: 添加 MSVC `/utf-8` 编译选项、输出目录配置
- 全部 QML 文件: Row/Column → RowLayout/ColumnLayout，修复布局属性误用
- 窗口圆角：放弃系统级毛玻璃（DWM Acrylic 与 per-pixel alpha 冲突），改用 QML 模拟毛玻璃质感
- QML 颜色：全部改用十六进制 `#aarrggbb`（Qt 6.11 rgba() 字符串解析报错）
- Singleton 注册：C++ qmlRegisterSingletonType 手动注册（QTP0004 自动识别漏识别 pragma Singleton）
- moc 崩溃：SelectionManager.h 移除 Windows 特定类型声明（HWND/DWORD 导致 moc 访问冲突）
- include 路径：统一相对路径，修复跨目录引用

### [Docs]
- README.md 项目说明与构建指南（含 MSVC/MinGW 双路径）
- docs/ARCHITECTURE.md 系统架构设计
- docs/CHANGELOG.md 更新日志
- AGENTS.md 项目规约

### [Build]
- Qt 6.11.2 + MinGW 13.1 + Ninja，输出 `build/bin/lingust.exe`
- 依赖模块：Core/Gui/Qml/Quick/QuickControls2/Network/Sql/Widgets
- 编译参数：-j 2（避免 cc1plus out of memory）

---

## 版本说明

- **v0.1.x**：UI 预览阶段，实现药丸/卡片视觉效果与状态切换
- **v0.2.x**：接入翻译引擎（Gemini/DeepL/有道/离线）✅
- **v0.3.x**：全局划词（UIA + Clipboard + OCR）✅（Clipboard 方案）
- **v0.4.x**：截图 OCR 与原地对照（框架已搭，待完善）
- **v0.5.x**：生词本、历史记录、TTS 发音 ✅
- **v0.6.x**：音乐控制（GSMTC）（待实现）
- **v1.0.0**：托盘、开机启动、自动更新、崩溃恢复，正式发布（托盘/开机启动 ✅）
