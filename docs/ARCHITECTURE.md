# Linguist 桌面版系统架构

`TranslatorWindow` 通过 `nativeFrameX/Y/Width/Height` 暴露 Platform 层确认的真实原生矩形。外置页面排版面板只使用该矩形计算屏幕位置，避免 `UpdateLayeredWindow` 已移动窗口而 Qt 逻辑坐标尚未同步时发生漂移。原生鼠标按下使用消息携带的客户区坐标做边框命中，避免再次采样全局指针产生竞态。

> **版本**：v0.2.0-dev
> **最后更新**：2026-09-13

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
│  OCRManager / CaptureManager / WindowManager / AuthManager│
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
│   Windows 平台层 (C++/Win32 + Windows Runtime Bridge)   │
│  UI Automation / Graphics.Capture / Clipboard            │
│  Global Hotkey / Mouse Hook / GSMTC / DWM / DPI         │
│  Windows Credential Manager                              │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│        Infrastructure 基础设施                            │
│  SQLite / Config / Cache / Logging / Updater             │
└─────────────────────────────────────────────────────────┘
```

## 2. 窗口管理

账户功能遵守同一分层：`AccountPanel.qml` 只存在于设置窗口并调用 `AuthManager`；Core 负责 HTTPS 协议、会话状态和输入校验；`ISecureCredentialStore` 隔离平台能力，Windows 实现使用凭据管理器。SQLite 的历史和收藏通过不可变用户 ID 做本机命名空间隔离。邮箱、短信、微信供应商密钥只允许存在于独立认证服务，完整边界见 [账户与认证架构](./AUTHENTICATION.md)。

卡片内容量通过 `CardView.desiredWindowWidth/desiredWindowHeight` 映射为窗口尺寸：空内容和简短结果返回 220×200，丰富词典区或较多截图行返回 350×420。`Main.qml` 合并一帧内的连续内容更新后调用 `TranslatorWindow::adjustSizeToContent()`；原生宿主负责 180ms 宽高动画与分层窗口提交，DPI 换算只在原生提交边界发生。交互拉伸期间忽略自动尺寸请求，避免内容状态与用户拖动争用窗口几何。

`AppState::clearText()` 完成数据清理后发出 `textCleared`，Application 编排层调用 `TranslatorWindow::resetCardToDefault()`，同步清除用户保存的卡片宽高并恢复 220×200。随后到达的 QML 自适应高度请求读取新的卡片记忆宽度，避免清空动画被旧宽度覆盖。交通灯只向 QML 上抛语义信号：黄色统一进入 `TranslatorWindow::minimizeToTaskbar()`，绿色负责模式切换。

卡片搜索、药丸搜索和划词入口均以 `AppState.sourceText` 为唯一原文状态。`SelectionManager::textSelected` 调用 `setSourceText()` 后启动翻译，两个视图通过属性绑定同时更新。空文本统一进入 `AppState::clearText()`，由 Core 层清除整组结果与加载状态；QML 只负责触发操作及药丸的最小入口动画。

语言选择仍遵守 UI/Core/Provider 分层：`LanguageSelector` 只发布标准化语言代码，`AppState` 校验并保存源语言与目标语言，`TranslationManager` 原样传给当前 Provider。DeepL 与有道使用各自的自动检测约定；要求明确语言对的免密 MyMemory 兜底由 `FallbackProvider` 在发起请求前执行轻量脚本检测。这样新增语言不会把服务代码映射散落到 QML。

TranslatorWindow 使用原生宿主承载由 `QQuickRenderControl` 绘制的离屏 QML 场景。搜索区域收到鼠标按下时，宿主先恢复原生窗口激活，再由当前卡片或药丸视图将活动焦点交给对应 TextField；随后键盘与输入法事件继续转发给离屏场景。该顺序保证自绘分层窗口首次点击即可输入。

Windows Platform 在创建分层宿主时同时设置 `WS_EX_APPWINDOW` 并清除 `WS_EX_TOOLWINDOW`，确保最小化状态在任务栏有稳定入口。`WindowResizeSession::minimize()` 由 Windows 实现调用 `SW_MINIMIZE`；Core 在调用前进入最小化状态并停止尺寸动画、缩放捕获和整帧提交，恢复后才重新调度绘制，避免排队的 `UpdateLayeredWindow` 把窗口重新呈现。原生鼠标链路独立处理 `WM_SETCURSOR` 与八方向命中，10 逻辑像素边缘和 38 逻辑像素角区共用同一个捕获会话；命中状态回传 `WindowSurface`，由整帧外壳叠加蓝色轮廓反馈。空白区域长按只从 QML 发出移动语义，Win32 调用仍留在窗口/Platform 层。

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
- QML `Main.qml` 同时保留药丸与卡片实例，以 130–160ms 可中断交叉淡入切换内容；只有当前模式接收输入
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
| FallbackProvider | 云端免密 | MyMemory 主翻译、Tatoeba 双语例句、Datamuse 同反义词；ECDICT 补词典信息 |
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

### 3.4 桌面翻译结果汇总

桌面默认按“当前在线引擎 → DeepL → 有道 → FallbackProvider”降级。`FallbackProvider` 并行请求主翻译、例句、同义词和反义词，单项超时只影响对应字段。`AppState` 收到结果后再查询本地 ECDICT：在线内容负责双语例句和语义关系，本地数据补足稳定的中文释义、音标、词形和标签，避免常用英文单词因本地词典提前返回而永远缺少扩展内容。

输入焦点沿“Windows 分层宿主 → `TranslatorWindow` 事件转发 → 离屏 `QQuickWindow` → `SearchInput`”传递。内容区按下时宿主取得键盘焦点，卡片命中输入框后调用 `forceActiveFocus`；回车只发出一次 `translateRequested`，业务调用仍由 `AppState` 完成。

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
CaptureManager 使用 QScreen 捕获鼠标所在显示器
    ↓
裁剪到框选区域
    ↓
OCRManager → IOcrProvider → WindowsOcrProvider
    ↓
TranslationManager 翻译
    ↓
现有 TranslatorWindow 展开为卡片
    ↓
CardView 正文中的 ScreenshotTranslationView 显示原图与对照结果
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
│  - 保存系统媒体快照并向 QML 发出精确属性变更             │
│  - 通过 AppState 信号转发 Play / Pause / Next / Seek    │
│  - 歌词时间戳定位与无系统时间轴时的本地进度降级          │
└──────────────────────────┬──────────────────────────────┘
                           │ GSMTC Platform Adapter
┌──────────────────────────▼──────────────────────────────┐
│   Platform 平台层: WindowsMediaManager + 常驻 PS Bridge │
│  - Windows PowerShell Windows Runtime 投影              │
│  - GlobalSystemMediaTransportControlsSessionManager     │
│  - 监听网易云/QQ音乐/Spotify/Apple Music/Edge 浏览器音频 │
└─────────────────────────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│            Lyrics Provider: LrclibLyricsProvider        │
│  - /api/get 精确匹配 → 300ms 后 /api/search 回退         │
│  - LRC 时间戳解析 / 普通歌词降级 / 会话缓存              │
└─────────────────────────────────────────────────────────┘
```

### 8.2 核心机制
- **零侵入监听**：无需用户登录各音乐平台账号即可通过 Windows 10/11 GSMTC 读取当前播放曲目、歌手、专辑、播放状态及播放器公开的时间轴；
- **真实状态优先**：没有系统媒体会话时明确显示未连接，不注入演示歌曲、虚拟歌词或伪进度；
- **编译器兼容边界**：当前桌面版使用 MinGW，Platform 层通过随程序分发的 Windows PowerShell 5.1 桥接 Windows Runtime；桥接常驻监听，控制操作使用短生命周期无窗口进程。
- **封面数据流**：桥接层读取 GSMTC `Thumbnail` 的随机访问流，仅在歌曲变化时缩放并裁成 256px 圆形 PNG，通过快照 Data URL 交给 QML，避免临时文件缓存错图；
- **歌词数据流**：AppState 检测到新歌后调用 `ILyricsProvider`，当前实现使用 LRCLIB；带时间戳歌词由 `MediaSessionService` 按播放位置选择当前行，普通歌词只提供完整浏览；
- **时间轴降级**：优先使用 GSMTC 的 `Position/EndTime`。部分播放器只发布元数据，此时采用歌词匹配结果的总时长并从检测到歌曲后递增，因此应用在歌曲播放中途启动时无法恢复已经播放的精确位置。

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

Qt 可能在隐藏的 QWindow 第一次显示时替换底层窗口过程，因此 Platform 在整帧提交前校验并恢复挂接，并同时注册 `QAbstractNativeEventFilter` 作为稳定入口；原始 Qt 窗口过程仍被保留并负责所有未处理消息。这样首次显示后的药丸点击不依赖窗口过程是否被 Qt 重新安装。

内部布局重建见 [WINDOW_UI_REBUILD.md](WINDOW_UI_REBUILD.md)。独立工具窗口按需加载并保留已打开状态，顶部可拖动、Escape 触发统一关闭动画。快捷操作窗口已移除，原入口直接打开设置窗口；设置、历史、音乐、截图和页面排版面板由同一个 UtilityWindow 生命周期与动效壳管理。页面排版面板以主卡片为 transient parent，水平居中定位在原生底边下方 2px，显示期间按窗口几何持续同步；屏幕底部空间不足时只在打开阶段上移主卡片。主卡片始终只有一个滚动内容区域。

主窗口外壳在 Platform 层以 GDI+ 在最终物理像素矩形上绘制，QML 提供主题颜色和透明度并负责内部内容。Core 通过 `WindowSurface.cornerRadius` 传递当前帧圆角：高度较小时取半高，较高时封顶为 32 逻辑像素，使药丸与卡片之间的轮廓连续。内容经同一圆角 alpha 遮罩合成后再提交；不使用 SetWindowRgn。场景视口取整数，根 Item 和 contentItem 使用精确 QSizeF。`usesNativeSurface` 为只读能力标志，使 GlassSurface 在真实宿主中不重复绘制。

翻译彩色边缘沿用同一整帧外壳：卡片与药丸各自持有同一 `AuroraBorder.qml` 状态机，它只维护透明度、呼吸强度和光谱相位，并通过 `requestSurfaceFrame()` 请求新帧；`Main.qml` 选择当前模式参数，`TranslatorWindow` 将其写入 `WindowSurface`；Windows Platform 在合成 QML 内容前绘制向内柔光、合成后绘制 1.5px 光谱细线。圆角路径继续复用已验收的 GDI+ 端点，动画不修改 HWND 几何、不创建子窗口，也不把 Canvas 或 ShaderEffect 接入软件场景。

当前模式搜索框的焦点与翻译状态共同决定光环生命周期。Platform 按卡片或药丸当前物理尺寸与圆角生成并缓存逐像素的边缘距离和方位场；每帧用平滑色谱插值与高斯/指数透明度衰减生成内向柔光，再与同一原生外壳合成。光场只改变外壳像素，不改变窗口尺寸、已验收圆角路径或缩放命中区域；因此没有短线接头颗粒，也不会影响右边与下边拖动稳定性。

软件渲染画布由 TranslatorWindow 持久持有，覆盖所有绘制调用的生命周期。Qt 软件场景图按变化区域增量绘制，因此不能在每次提交前清空或替换画布；只有物理尺寸或 DPI 改变时解绑旧目标、重建画布并重新绑定。否则首帧正常、后续帧全透明，进程和 HWND 仍正常存在。

TranslatorWindow 现在是普通 QWindow 宿主；QQuickRenderControl 以 Qt Quick 软件后端把 QML 渲染到 `QImage::Format_ARGB32_Premultiplied`。Platform 层的 WindowsResizeSession 负责读取物理像素矩形、计算八向拖动目标，并通过 `UpdateLayeredWindow` 在一次调用中提交位置、尺寸和像素。Core 不包含 Win32 调用，QML 仍只负责界面和发出交互意图。

宿主把鼠标、滚轮、键盘、输入法和焦点事件转发给离屏 QQuickWindow。`TranslatorRenderControl::renderWindow()` 返回可见的 `TranslatorWindow`，而宿主的 `focusObject()` 返回离屏场景当前文本焦点；Windows 输入法因此可以查询预编辑状态、周边文本和光标矩形，并把中文组合文本提交给真实 QML 编辑器。动画及普通场景更新由 renderRequested/sceneChanged 合并到下一次事件循环；交互缩放直接用最新指针位置同步生成完整帧。

`TranslationManager` 为每次翻译建立单调递增的请求代次，只允许当前 Provider 的结果进入 `AppState`。各网络 Provider 进一步丢弃自身较旧的网络回复，延迟重试和 UI 最短加载计时也核对当前代次。语言方向改变会在 Core 中统一触发重译，因此顶部选择器、交换按钮和设置入口不会形成不同状态机；ECDICT 中文字段仅在 `EN → ZH` 方向补充。

边缘命中由 TranslatorWindow 在转发 QML 之前判断：卡片与药丸都使用原生八向命中，直边使用 8px 区域，四角使用 34px 区域。药丸高度限制为 38–72px，并与卡片分别记忆最后一次缩放尺寸；切换模式恢复对应几何。缩放抓取属于真实宿主窗口，红绿灯等位于圆角内部的控件仍交给 QML。

Windows 分层窗口在 `WM_MOUSEMOVE` 时注册 `TME_LEAVE`。收到 `WM_MOUSELEAVE` 后，TranslatorWindow 先调用根视图的 `handlePointerLeave()` 清理业务悬浮状态，再向离屏 QQuickWindow 发送窗口外鼠标移动与 `QEvent::Leave`，同时覆盖业务状态和 Qt 指针状态两条复位路径。原生左键按下会先调用根视图的 `prepareKeyboardFocus(x, y)`；卡片和药丸分别判断自己的搜索区域并聚焦对应 TextField，然后再把同一指针事件转发给离屏场景。

每个原生 `WM_MOUSEMOVE` 先进入离屏场景，让 QML 指针处理器完成按钮命中与视觉反馈，再调用根视图的 `handlePointerMove(x, y)` 最终确认窗口级边缘状态。药丸以真实局部坐标判断最右 32px 操作热区和最小状态最左 16px 红绿灯热区，不依赖 HoverHandler 在透明分层窗口边缘是否及时重算。

药丸的横向布局使用 QML `TextMetrics` 测量当前原词、首条词典释义和词性前缀。搜索框在预设上下限内按内容宽度增长，核心译文先预留测量宽度，操作组再把剩余空间量化为完整的 23px 按钮数量。最右侧展开状态改写这组约束：搜索退出布局，普通宽度的红绿灯继续占用实际宽度，143px 完整操作组固定右边缘，译文填充中间剩余空间。因此普通状态优先可读内容，显式悬浮状态优先完整操作，两个状态共享同一行且不产生覆盖。

药丸操作通过明确信号连接到宿主：`screenshotRequested` 打开独立截图窗口，`settingsRequested` 打开设置窗口，`expandRequested` 切换卡片；复制、朗读和音乐模式直接调用 `AppState`。通用 `IconButton` 的执行环仅确认输入已被接收，业务完成状态仍由对应属性或目标窗口表达。普通宽度下右侧完整展开继续保留红绿灯；最小宽度遵循既有左边缘揭示规则，避免完整操作组与红绿灯在 160px 内互相覆盖。

截图入口由 `AppState::screenshotRequested` 统一路由。主窗口先隐藏 140ms，`CaptureManager` 再抓取鼠标所在屏幕并显示独立 `ScreenCaptureOverlay`；选区按屏幕 DPI 转换为图像像素。裁剪结果连同当前源语言交给 `WindowsOcrProvider`，后者在后台保存临时 PNG，通过隐藏的 PowerShell WinRT 桥选择对应 `Windows.Media.Ocr` 语言引擎，并在引擎最大图像尺寸内对小图做高质量放大。OCR 行进入独立的 `TranslationManager` 串行翻译，每行完成后只回填对应 `ocrLines` 项，不写普通搜索的 `sourceText/translatedText`，也不根据换行猜测对齐。框选结束后恢复同一个 `TranslatorWindow`、切换为卡片并让 `CardView` 正文进入 `screenshotMode`；卡片顶部展示可隐藏的小缩略图，点击后才按需创建独立 `ScreenshotPreview` 工具窗查看原图。当前版本一次框选一个显示器；跨越多显示器边界的单个选区不在支持范围内。

截图逐行翻译完成后，Core 把合并后的原文、译文、`kind=screenshot` 和预览地址写入现有 SQLite 历史表；数据库使用只增列迁移兼容旧用户数据。历史窗口按类型筛选，打开截图项时由 `AppState::openHistoryItem()` 重建对应的 `ocrLines`，继续复用同一个 `TranslatorWindow/CardView`，不另建截图结果窗口。

Qt 官方将 QQuickRenderControl 定义为由应用完全控制的离屏场景图渲染机制；软件后端可以把 QQuickRenderTarget 指向 QPaintDevice：[QQuickRenderControl](https://doc.qt.io/qt-6/qquickrendercontrol.html)、[QQuickRenderTarget::fromPaintDevice](https://doc.qt.io/qt-6/qquickrendertarget.html#fromPaintDevice)。

应用入口不再强制 basic 同线程渲染循环，交由 Qt 在 Windows/D3D11 上选择默认 threaded 渲染。threaded 在专用线程准备画面，界面线程可继续处理原生缩放事件；仍允许开发者用 Qt 环境变量做诊断对照。窗口表面关闭整窗 4× MSAA，圆角矩形继续使用 Qt Quick 自带抗锯齿，减少实时改变透明交换表面时的额外解析工作。

所有 QML 边/角手柄走 `TranslatorWindow.beginInteractiveResize/endInteractiveResize`。Core 定义 `WindowResizeSession` 接口，Application 注入 `platform/windows/window/WindowsResizeSession`。Windows 实现保存按下时的物理像素矩形和指针，在单次 SetWindowPos 中应用最新尺寸和位置，固定边不经过逻辑像素反复取整。Core 保留 Qt 坐标回退。待提交帧期间暂停继续改变几何，frameSwapped 通过队列连接回到界面线程后应用最新输入；5–16ms 定时器只负责空闲时检测指针和松手，并非垂直同步。松手/取消应用最终位置并写回当前模式的记忆尺寸，切换模式先结束交互，交互期间不接受内容高度动画。此方案没有新增窗口、没有区域裁剪，Win32 调用仅位于 Platform 层。

参考：[Qt 渲染循环](https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph.html)、[Qt Windows 图形后端](https://doc.qt.io/qt-6/windows-graphics.html)、[Qt Quick Rectangle 抗锯齿](https://doc.qt.io/qt-6/qml-qtquick-rectangle.html)、[Microsoft DirectComposition 架构](https://learn.microsoft.com/windows/win32/directcomp/architecture-and-components)。

物理像素适配器依据 [GetWindowRect](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowrect) 的右/下边界排他规则及 [SetWindowPos](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos) 的位置、尺寸更新接口实现；依赖 Qt 默认的 per-monitor DPI awareness，不支持用环境设置禁用 DPI 感知后仍声称物理像素稳定。

### 透明轮廓的绘制责任（2026-09-08）

GlassSurface 统一负责主卡片/药丸的透明轮廓、底色、高光和描边；业务工具栏保持透明底色。以同尺寸圆角矩形代替越界动态高光，避免跨层轮廓不一致。保留 Windows 默认 D3D11/threaded 后端。卡片始终为 32px 圆角，删除交互时变成 40px 的补偿。早期探针将不同时刻的几何和截图混用，不能确认桌面合成器是剩余闪动的根因。frameSwapped 只表示帧已排队呈现，不是屏幕呈现完成；参见 [Qt 信号定义](https://doc.qt.io/qt-6/qquickwindow.html#frameSwapped)。

完整音乐详情使用独立的 `360 × 300` 紧凑窗口。药丸只承载摘要和常用控制，因此所有可见内容均处于各自原生窗口边界内，不需要扩大透明宿主窗口。
