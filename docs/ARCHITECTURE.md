# Linguist 桌面版系统架构

> **版本**：v0.1.0
> **最后更新**：2026-09-05

## 1. 分层架构

```
┌─────────────────────────────────────────────────────────┐
│                   UI 层 (Qt Quick / QML)                 │
│  PillView / CardView / WordDetailView / HistoryView     │
│  SettingsView / OverlayWindow / GlassSurface / Tokens   │
└──────────────────────────┬──────────────────────────────┘
                           │ property binding / signals
┌──────────────────────────▼──────────────────────────────┐
│              Core 核心层 (C++20)                         │
│  AppState / TranslationManager / SelectionManager        │
│  OCRManager / CaptureManager / WindowManager             │
│  ShortcutManager / MediaManager                          │
└──────────────────────────┬──────────────────────────────┘
                           │ Platform Interfaces
┌──────────────────────────▼──────────────────────────────┐
│         Provider 服务层 (可插拔)                          │
│  ITranslationProvider / IOcrProvider / ISelectionProvider│
│  Gemini / DeepL / 有道 / OpenAI / Local / PaddleOCR     │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│        Windows 平台层 (C++/WinRT + Win32)                │
│  UI Automation / Graphics.Capture / Clipboard            │
│  Global Hotkey / Mouse Hook / GSMTC / DWM / DPI         │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│        Infrastructure 基础设施                            │
│  SQLite / Config / Cache / Logging / Updater             │
└─────────────────────────────────────────────────────────┘
```

## 2. 窗口管理

### 2.1 窗口清单

| 窗口 | 类型 | DWM 背景 | 生命周期 |
|---|---|---|---|
| TranslatorWindow | QQuickWindow | per-pixel 透明 + QML GlassSurface | 常驻（药丸/卡片状态切换） |
| OverlayWindow | QQuickWindow | 半透明遮罩 | 截图时创建 |
| SettingsWindow | QQuickWindow | Mica | 设置时创建 |
| HistoryWindow | QQuickWindow | Mica | 历史记录时创建 |

### 2.2 透明窗口实现

```cpp
// TranslatorWindow 核心设置
setFlag(Qt::FramelessWindowHint);
setFlag(Qt::WindowStaysOnTopHint);
setColor(Qt::transparent);
```

- `QQuickWindow::setDefaultAlphaBuffer(true)` 在创建窗口前启用透明表面
- QML `GlassSurface` 组件绘制半透明颜色、统一圆角和边框，不调用未文档化 DWM Acrylic
- 圆角外保持 alpha=0；不使用 SetWindowRgn 裁剪

### 2.3 状态机

```
Pill (380×46)
  ↓ 点击展开 / 底部下拖 >85px
Card (380×490)
  ↓ 点击黄色最小化 / 顶部上推
Pill
```

- C++ `TranslatorWindow` 管理 `currentMode` 属性和窗口几何
- QML `main.qml` 通过 States + Transitions 做视图切换动画
- 窗口尺寸变化通过 `widthChanged/heightChanged` 信号同步 QML 内容

## 3. 翻译架构

### 3.1 统一接口

```cpp
class ITranslationProvider {
public:
    virtual ~ITranslationProvider() = default;
    virtual QString name() const = 0;
    virtual Task<TranslationResult> translate(
        const QString &text,
        const QString &sourceLang,
        const QString &targetLang) = 0;
    virtual bool isAvailable() const = 0;
};
```

### 3.2 提供商实现

| Provider | 类型 | 说明 |
|---|---|---|
| GeminiProvider | 云端 | Google GenAI SDK，多模型熔断降级池 |
| DeepLProvider | 云端 | Free / Pro 密钥 |
| YoudaoProvider | 云端 | 有道智云 OpenAPI |
| OpenAIProvider | 云端 | GPT-4o 翻译 |
| LocalProvider | 离线 | 内置高频双语词库 |

### 3.3 429 熔断降级池

```
gemini-3.1-flash-lite → gemini-3.5-flash → gemini-flash-lite-latest → gemini-3.8-flash
    ↓ 全部 429
LocalProvider 离线兜底
```

- 捕获 429 后标记模型冷却 60 秒，自动切换下一个候选
- 全部不可用时降级到离线词库，确保前端永远有响应

## 4. 全局划词

### 4.1 三级降级策略

```
用户划词
    ↓
1. UI Automation (ISelectionProvider / TextPattern)
   覆盖：Chrome / Edge / Office / PDF 阅读器 / IDE / 传统 Win32
    ↓ 失败
2. Clipboard (模拟 Ctrl+C + GetClipboardSequenceNumber 安全恢复)
   覆盖：部分自绘软件、不支持 UIA 的应用
    ↓ 失败
3. OCR (框选区域文字识别)
   覆盖：游戏、视频、图片等无法获取文本的场景
```

### 4.2 Clipboard 安全恢复

```
记录 GetClipboardSequenceNumber() → seq0
    ↓
模拟 Ctrl+C
    ↓
异步等待 sequence 变化（短超时）
    ↓
读取文本
    ↓
比对 sequence：
  - 仍是我们的修改 → 恢复原剪贴板
  - 被用户插队修改 → 不恢复，避免覆盖用户新内容
```

## 5. 截图 OCR

### 5.1 流程

```
快捷键触发
    ↓
OverlayWindow 全屏透明遮罩
    ↓
鼠标框选区域 (X, Y, W, H)
    ↓
Windows.Graphics.Capture 捕获显示器
    ↓
裁剪到框选区域
    ↓
OCRManager → IOcrProvider
    ↓
TranslationManager 翻译
    ↓
InPlaceScreenshotCard 原位显示对照结果
```

### 5.2 OCR Provider

| Provider | 要求 | 说明 |
|---|---|---|
| WindowsOcr | Windows 10+ | `Windows.Media.Ocr.OcrEngine`，系统内置，默认 |
| WindowsAiOcr | NPU 设备 | `Microsoft.Windows.AI.Imaging.TextRecognizer`，高精度可选 |
| PaddleOcr | 本地运行库 | 高精度离线 OCR，可选分发 |

## 6. 线程模型

```
Main Thread (UI)
├── QML 渲染
├── Window 管理
└── AppState 状态

Worker Thread Pool (QThreadPool)
├── OCR 识别
├── 截图图像处理
├── API 网络请求
└── SQLite 数据库

可选 Worker Process
├── 本地 AI 推理
├── PaddleOCR
└── 大模型本地推理
```

- UI 线程绝不执行 OCR、网络请求和图片处理
- 所有耗时操作通过 `QThreadPool` + `QRunnable` 或 `QtConcurrent` 执行
- 结果通过信号槽回传 UI 线程

## 7. 跨平台预留

当前仅实现 Windows 平台，但架构预留跨平台能力：

```
platform/
├── interfaces/       # 纯虚接口，平台无关
├── windows/          # Windows 实现
└── macos/            # 未来 macOS 实现（预留）
```

QML UI + C++ Core + Providers 三层完全平台无关，新增平台只需实现 `platform/<os>/` 目录。

## 8. 灵动岛音乐与 Windows 系统音频媒体总线架构 (GSMTC Integration)

### 8.1 架构拓扑

```
┌─────────────────────────────────────────────────────────┐
│              UI 层 (PillView & MusicIslandCard)          │
│  - 唱片旋转动画 / 3柱动态音频均衡器 / 双语歌词同步跑马灯  │
│  - 交互进度条 / 上下曲 / 播放暂停 / 翻译-音乐一键互换    │
└──────────────────────────┬──────────────────────────────┘
                           │ Q_PROPERTY bindings / Q_INVOKABLE calls
┌──────────────────────────▼──────────────────────────────┐
│             Core 核心层: MediaSessionService             │
│  - 状态机控制 (Play / Pause / Next / Seek)              │
│  - 歌词时间戳解析器 (Timestamp Lyric Parser)            │
│  - 内置白噪音/专注歌单 (Lofi / Coding Beats)            │
└──────────────────────────┬──────────────────────────────┘
                           │ GSMTC Platform Adapter
┌──────────────────────────▼──────────────────────────────┐
│      Platform 平台层: WindowsMediaManager (C++/WinRT)   │
│  - Windows.Media.Control                                │
│  - GlobalSystemMediaTransportControlsSessionManager     │
│  - 监听网易云/QQ音乐/Spotify/Apple Music/Edge 浏览器音频 │
└─────────────────────────────────────────────────────────┘
```

### 8.2 核心机制
- **零侵入监听**：无需用户登录各音乐平台账号即可通过 Windows 10/11 系统的 GSMTC 广播自动截获当前播放曲目、歌手、封面与播放状态；
- **自包含离线回退**：未开启第三方音乐软件时，系统内置 Lofi 学习与午夜专注双语音乐会话，随时提供沉浸式心流体验。

## 9. Web PWA 与桌面端多窗口对齐架构 (Window Management Alignment)

为恪守「设置/截图/历史记录使用独立窗口」的铁律，Web PWA 客户端全面对齐原生桌面多窗口机制：

```
┌─────────────────────────────────────────────────────────┐
│              App.tsx 全局多窗口与视图调度器             │
├───────────────────┬───────────────────┬─────────────────┤
│ FloatingCard      │ SettingsWindow    │ HistoryWindow   │
│ (TranslatorWindow)│ (独立设置窗口)    │ (独立生词窗口)  │
│ - 药丸/卡片切换   │ - 自由拖拽平移    │ - 自由拖拽平移  │
│ - 词典/中英对照   │ - macOS红绿灯     │ - macOS红绿灯   │
│ - 灵动岛音乐      │ - 最小化为药丸    │ - 最小化为药丸  │
│ - 8向边缘拉伸     │ - 5大分类选项卡   │ - 实时检索收藏  │
└───────────────────┴───────────────────┴─────────────────┘
```

- **非阻塞多任务体验**：各窗口无强制全屏暗色 Backdrop 遮挡，用户可并列排布查词卡片、设置面板与生词记录，获得与桌面双屏/多窗口操作无异的高效体验；
- **自包含最小化**：支持将设置与历史记录独立收敛为桌面微型药丸胶囊，随用随展。




## 10. Windows 透明窗口缩放同步（2026-09-08）

### 分层窗口整帧提交（2026-09-09）

**当前实现（测试框复用版）**：Platform 使用 GDI+ 承载测试框四圆弧与内描边，替代下方历史阶段的 Core/QPainter 外壳。QML 只输出持久内容画布；Platform 合成内容后使用同款 UpdateLayeredWindow 整帧提交。平台挂接 HWND 窗口过程，统一处理边框拖动、内容区鼠标输入和捕获丢失，再通过抽象回调交给 Core；不再使用缩放计时轮询。外部 WM_WINDOWPOSCHANGED/WM_DPICHANGED 请求重绘，自身提交通过状态防止重入。

内部布局重建见 [WINDOW_UI_REBUILD.md](WINDOW_UI_REBUILD.md)。独立工具窗口按需加载并保留已打开状态，顶部可拖动、Escape 关闭。主卡片始终只有一个滚动内容区域。

主窗口外壳由 Core 内的 QPainter 在最终物理像素矩形上绘制，QML 提供主题颜色和透明度并负责内部内容。内容经圆角 alpha 遮罩合成后再由 Platform 提交；不使用 SetWindowRgn。场景视口取整数，根 Item 和 contentItem 使用精确 QSizeF。`usesNativeSurface` 为只读能力标志，使 GlassSurface 在真实宿主中不重复绘制。

软件渲染画布由 TranslatorWindow 持久持有，覆盖所有绘制调用的生命周期。Qt 软件场景图按变化区域增量绘制，因此不能在每次提交前清空或替换画布；只有物理尺寸或 DPI 改变时解绑旧目标、重建画布并重新绑定。否则首帧正常、后续帧全透明，进程和 HWND 仍正常存在。

TranslatorWindow 现在是普通 QWindow 宿主；QQuickRenderControl 以 Qt Quick 软件后端把 QML 渲染到 `QImage::Format_ARGB32_Premultiplied`。Platform 层的 WindowsResizeSession 负责读取物理像素矩形、计算八向拖动目标，并通过 `UpdateLayeredWindow` 在一次调用中提交位置、尺寸和像素。Core 不包含 Win32 调用，QML 仍只负责界面和发出交互意图。

宿主把鼠标、滚轮、键盘、输入法和焦点事件转发给离屏 QQuickWindow。动画及普通场景更新由 renderRequested/sceneChanged 合并到下一次事件循环；交互缩放直接用最新指针位置同步生成完整帧。该架构以用户已确认稳定的独立空框为基础，但项目业务场景必须重新完成八向拖动和输入功能验证。

边缘命中由 TranslatorWindow 在转发 QML 之前判断：直边使用 6px 区域，四角仅使用 32px 圆角的可见外弧带。这样缩放抓取属于真实宿主窗口，红绿灯等位于圆角内部的控件仍交给 QML。

Qt 官方将 QQuickRenderControl 定义为由应用完全控制的离屏场景图渲染机制；软件后端可以把 QQuickRenderTarget 指向 QPaintDevice：[QQuickRenderControl](https://doc.qt.io/qt-6/qquickrendercontrol.html)、[QQuickRenderTarget::fromPaintDevice](https://doc.qt.io/qt-6/qquickrendertarget.html#fromPaintDevice)。

应用入口不再强制 basic 同线程渲染循环，交由 Qt 在 Windows/D3D11 上选择默认 threaded 渲染。threaded 在专用线程准备画面，界面线程可继续处理原生缩放事件；仍允许开发者用 Qt 环境变量做诊断对照。窗口表面关闭整窗 4× MSAA，圆角矩形继续使用 Qt Quick 自带抗锯齿，减少实时改变透明交换表面时的额外解析工作。

所有 QML 边/角手柄走 `TranslatorWindow.beginInteractiveResize/endInteractiveResize`。Core 定义 `WindowResizeSession` 接口，Application 注入 `platform/windows/window/WindowsResizeSession`。Windows 实现保存按下时的物理像素矩形和指针，在单次 SetWindowPos 中应用最新尺寸和位置，固定边不经过逻辑像素反复取整。Core 保留 Qt 坐标回退。待提交帧期间暂停继续改变几何，frameSwapped 通过队列连接回到界面线程后应用最新输入；5–16ms 定时器只负责空闲时检测指针和松手，并非垂直同步。松手/取消应用最终位置，切换模式先结束交互，交互期间不接受内容高度动画。此方案没有新增窗口、没有区域裁剪，Win32 调用仅位于 Platform 层。

参考：[Qt 渲染循环](https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph.html)、[Qt Windows 图形后端](https://doc.qt.io/qt-6/windows-graphics.html)、[Qt Quick Rectangle 抗锯齿](https://doc.qt.io/qt-6/qml-qtquick-rectangle.html)、[Microsoft DirectComposition 架构](https://learn.microsoft.com/windows/win32/directcomp/architecture-and-components)。

物理像素适配器依据 [GetWindowRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowrect) 的右/下边界排他规则及 [SetWindowPos](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos) 的位置、尺寸更新接口实现；依赖 Qt 默认的 per-monitor DPI awareness，不支持用环境设置禁用 DPI 感知后仍声称物理像素稳定。

### 透明轮廓的绘制责任（2026-09-08）

GlassSurface 统一负责主卡片/药丸的透明轮廓、底色、高光和描边；业务工具栏保持透明底色。以同尺寸圆角矩形代替越界动态高光，避免跨层轮廓不一致。保留 Windows 默认 D3D11/threaded 后端。卡片始终为 32px 圆角，删除交互时变成 40px 的补偿。早期探针将不同时刻的几何和截图混用，不能确认桌面合成器是剩余闪动的根因。frameSwapped 只表示帧已排队呈现，不是屏幕呈现完成；参见 [Qt 信号定义](https://doc.qt.io/qt-6/qquickwindow.html#frameSwapped)。

完整音乐详情使用独立的 `360 × 300` 紧凑窗口。药丸只承载摘要和常用控制，因此所有可见内容均处于各自原生窗口边界内，不需要扩大透明宿主窗口。
