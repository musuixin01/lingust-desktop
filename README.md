# Linguist 桌面悬浮翻译卡片 (Desktop Edition)

> **版本**：v0.2.0-dev
> **状态**：账户功能开发版
> **技术栈**：Qt 6 Quick / QML + C++20 + Windows Runtime 媒体桥接

轻量优雅、毛玻璃质感的桌面悬浮翻译卡片。支持多态药丸/卡片形态、四核翻译引擎、原地截图 OCR、全局划词与双语发音。

卡片默认使用 220×200px 紧凑尺寸；包含例句、同反义词、词形变化或较多截图翻译行时平滑展开为 350×420px 阅读卡片。页面排版面板作为独立液态玻璃小窗居中贴合在卡片底边下方 2px，拖动或缩放卡片时持续同步位置，不占用正文空间。搜索框支持 Windows 中文输入法的预编辑、候选窗和提交文本；切换或交换语言后立即按新方向重译，迟到的旧请求不会覆盖当前结果。

程序从空翻译状态启动，不预填演示单词。空药丸在红绿灯感应区右侧保留液态玻璃搜索入口，悬浮不展开，点击后才进入输入；有文字时入口按文字宽度增长，清空、点击窗口其他区域或切换应用后恢复最小状态。点击药丸搜索框与卡片一致，会启动柔和的流光呼吸，收回后停止呼吸并自然消散；两种输入框均显示闪烁光标。划词或输入后，原文会立即同步到卡片和药丸搜索框。

---

## 核心特性

窗口与界面重建：正式边框复用已验收的独立测试框 GDI+ 代码。主卡片与药丸采用深色液态玻璃层次；两种模式均可从四边、四角缩放并分别记忆尺寸。边缘悬浮会显示方向光标和蓝色柔光反馈，按下后持续捕获；顶部可直接移动，空白正文长按约 280ms 也可移动。右上角直接打开偏好设置，设置、历史、音乐和截图使用统一主题的独立小窗，按 Escape 平滑关闭。交接与恢复位置见 [窗口重建说明](docs/WINDOW_UI_REBUILD.md)。

| 模块 | 功能 |
|---|---|
| 多态悬浮卡片 | 药丸 (Pill) ↔ 完整卡片 (Card) 平滑状态切换；两种模式都支持自由拖拽与八向拉伸，并分别记忆尺寸 |
| 多引擎翻译与词典 | Gemini AI / DeepL / 有道智云 / ECDICT 离线词库；无密钥时自动使用免密在线兜底，单词结果包含双语例句、同义词与反义词 |
| 截图翻译 | 药丸、卡片、托盘与 `Ctrl+Shift+S` 均进入真实屏幕框选；Windows OCR 按当前源语言识别后回到现有翻译卡片，以紧凑的原文一行、译文一行连续对照；顶部小原图可隐藏或点击放大，识别文字不会进入普通搜索框 |
| 多语言翻译 | 源语言可自动检测，也可自由选择中、英、日、韩、法、德、西、葡、意、俄、阿、越、泰语；目标语言可从同组实际语言中选择，已有文本会立即按新方向重译 |
| 全局划词 | UI Automation → Clipboard 安全兜底 → OCR 三级降级 |
| 生词本与历史 | SQLite 持久化，普通翻译与截图翻译筛选、收藏标记、关键词检索、双语发音 |
| 账户 | 仅在设置中显示登录/注册；支持邮箱密码、手机号验证码与微信扫码协议，刷新令牌由 Windows 凭据管理器保存，历史和收藏按账户隔离 |
| 系统音乐 | 药丸音乐模式显示封面、进度、歌词及上一首、播放/暂停、下一首；控制当前 Windows 系统媒体会话 |
| 灵动岛系统音乐 | 通过 Windows GSMTC 自动读取当前播放器的歌曲、歌手、专辑、封面与播放状态；真实封面唱片随播放旋转，外环显示进度，药丸显示当前歌词，展开卡片可滚动浏览多行歌词，并支持切歌、播放/暂停及可用的进度跳转 |

免密兜底会把待翻译文本或单词发送给 [MyMemory](https://mymemory.translated.net/doc/spec.php)、[Tatoeba](https://api.tatoeba.org/) 和 [Datamuse](https://www.datamuse.com/api/)。断网时英文单词仍由本地 ECDICT 给出基础释义；双语例句和同反义词需要网络。

---

## 技术架构

```
Qt Quick/QML (UI 层)
    ↓ property binding / signals
C++20 Core (AppState, TranslationManager, SelectionManager,
    OCRManager, CaptureManager, WindowManager, ShortcutManager, AuthManager)
    ↓ Platform Interfaces (ITranslationProvider, IOcrProvider, ...)
    ↓
C++/Win32 + Windows Runtime 媒体桥接 (Windows 平台实现)
```

### 窗口设计原则
- **分层 QWindow 宿主 + 离屏 QML 场景**，完整画面与窗口物理尺寸一次提交，QML 继续负责圆角、排版和控件
- Qt 窗口层负责 Frameless / AlwaysOnTop / 多屏 DPI；GlassSurface 在 QML 内模拟深色玻璃
- **独立紧贴窗口**：TranslatorWindow（Pill↔Card）/ OverlayWindow / SettingsWindow
- 不使用 SetWindowRgn，避免圆角锯齿和失焦边框问题

---

## 快速开始

### 安装版

从项目发布页下载 `Linguist-Setup-0.1.0-win64.exe`，按向导安装即可。默认安装到当前用户的 `%LOCALAPPDATA%\Programs\Linguist`，不需要管理员权限；可选创建桌面快捷方式，也可从 Windows“已安装的应用”完整卸载。

当前安装包未签名，Windows SmartScreen 可能显示未知发布者。安装包 SHA-256 文件与安装程序放在同一发布目录，可用于完整性校验。

### 环境要求
- Qt 6.8+（本机验证为 Qt 6.11.2 MinGW 64-bit）
- CMake 3.16+（Qt 安装器或 VS 自带）
- Ninja 与 C++20 编译器（MinGW 13.1 或兼容 MSVC）
- Windows 10 1809+

### Qt 安装指引

运行浏览器中已打开的 Qt 在线安装器，安装时选择：

1. **Qt 版本**：Qt 6.8 或更高版本
2. **编译器组件**：选择 MinGW 64-bit，并保持 Qt 库和编译器套件一致
3. **附加模块**：Qt Quick、Qt Quick Controls、Qt Network、Qt SQL
4. **开发工具**：
   - CMake
   - Ninja
   - Qt Creator（推荐，用于编辑 QML 和调试）

当前脚本默认路径：`D:\DevTools\QT\6.11.2\mingw_64`

### 构建

**方式一：Qt Creator（推荐）**
1. 打开 Qt Creator
2. 文件 → 打开文件或项目 → 选择 `CMakeLists.txt`
3. 配置 Kit：选择 **Desktop Qt 6.5.3 MSVC2022 64bit**
4. 点击左下角运行按钮（或 Ctrl+R）

**方式二：命令行**

```bash
# 打开 "x64 Native Tools Command Prompt for VS 2022"
cd "D:\AI Lab\AI Library\Doubao Workspace\lingust-desktop"

# 配置（使用 Ninja 或 NMake）
cmake -B build -G "Ninja" -DCMAKE_PREFIX_PATH="D:/DevTools/QT/6.11.2/mingw_64" -DCMAKE_BUILD_TYPE=Release

# 编译
cmake --build build

# 运行
.\build\bin\lingust.exe
```

生成安装包：`powershell -ExecutionPolicy Bypass -File .\scripts\package_windows.ps1 -InstallPackagingTool`。完整发布流程见 [Windows 构建、安装与发布](./docs/RELEASE.md)。

---

## 项目目录

```
lingust-desktop/
├── app/                    # 应用入口
│   ├── main.cpp
│   └── Application.h/cpp
├── ui/                     # QML 界面
│   ├── main.qml            # 主入口（状态机）
│   ├── components/         # 基础组件（DesignTokens, GlassSurface, ...）
│   ├── pill/               # 药丸视图
│   ├── card/               # 卡片视图
│   ├── overlay/            # 截图遮罩
│   └── settings/           # 设置页面
├── core/                   # C++ 核心层
│   ├── state/              # AppState 状态管理
│   ├── window/             # TranslatorWindow 窗口管理
│   ├── translation/        # 翻译调度
│   ├── selection/          # 划词管理
│   ├── ocr/                # OCR 调度
│   ├── capture/            # 截图管理
│   ├── media/              # 音乐控制
│   └── auth/               # 认证会话与安全存储接口
├── platform/               # 平台抽象
│   ├── interfaces/         # ITranslationProvider, IOcrProvider, ...
│   └── windows/            # Windows 平台实现
├── providers/              # 翻译/OCR 提供商
├── infrastructure/         # 基础设施（SQLite/Config/Logging/Updater）
├── resources/              # 图标等资源
├── docs/                   # 项目文档
└── CMakeLists.txt
```

---

## 文档索引

- [架构设计](./docs/ARCHITECTURE.md)
- [设计规范](./docs/DESIGN_SYSTEM.md)
- [更新日志](./docs/CHANGELOG.md)
- [Windows 构建、安装与发布](./docs/RELEASE.md)
- [全局功能验证记录](./docs/VALIDATION.md)
- [v0.1.0 版本说明](./docs/RELEASE_NOTES_0.1.0.md)
- [账户与认证架构](./docs/AUTHENTICATION.md)

---

## 许可证

MIT License


## 桌面工具栏交互与验证（2026-09-08）

四边/四角缩放合并高频输入，Windows 使用物理像素固定未拖动的边；按下、拖动和松手均保持标准 32px 大圆角。四角沿可见圆弧拖动。按钮按下即时反馈。极窄窗口可使用工具栏横向滚动条访问全部操作；正常宽度下顶部空白区域仍用于拖动窗口。

运行桌面 QML 回归检查（需 Python 3、对应 Qt 的 qmltestrunner 及运行库）：

```powershell
python scripts/test_toolbars.py --qt-bin "D:/DevTools/QT/6.11.2/mingw_64/bin"
```

报告与截图输出到 `build/toolbar-check/`。该检查使用 UI 状态夹具，验证布局和交互，不代表真实翻译、OCR、系统媒体或物理输入延迟已验证。


### 窄卡片与药丸使用补充

长单词和音标会自动换行，窄卡片中的美/英发音独立成行。卡片、药丸和划词共用同一搜索原文：划词后立即出现在两种搜索框中，清空任一搜索框会同时清除译文和词典详情；药丸搜索为空时自动收回最小入口。药丸可从四边或四角调整大小；搜索框按原词实际长度在正常上限内自动增长，译文只显示带词性颜色的首条核心释义。核心内容优先使用横向空间，右侧操作按剩余宽度逐项收起；出现隐藏操作后，悬浮窗口真实最右 32px 会展开完整操作组并推动其他内容让位，同时保留普通药丸的红绿灯；最小药丸悬浮最左 16px 会显示缩小的红绿灯。搜索在所有允许宽度下都支持直接点击、键盘输入和回车翻译，聚焦后显示蓝色描边与清晰光标；等待结果时显示三色波浪点，翻译完成且鼠标离开药丸后自动收起。所有图标点击都有执行环反馈，药丸截图按钮进入屏幕框选并把结果显示在现有卡片。长原词与长译文只在各自区域悬浮时滚动，离开窗口立即回到开头。红绿灯外框默认缩小，悬浮后与圆点同步放大到标准尺寸。

药丸中的词性与第一条重要释义始终位于同一行。音乐模式读取 Windows 当前媒体会话，不提供内置演示歌曲；播放器若不公开时间轴，界面会保留歌曲信息和控制按钮，并在歌词匹配成功后使用歌曲总时长提供估算进度。

歌词由 LRCLIB 按当前歌名和歌手联网匹配，因此音乐元数据会发送至 `lrclib.net`。同步歌词存在时会跟随进度高亮；只有普通歌词时仍可在卡片中完整滚动浏览。播放器没有公开 GSMTC 时间轴时，应用使用歌词记录的总时长并从检测到当前歌曲后估算位置，启动时已经播放的部分可能存在偏差。

当前本机验证环境为 Qt 6.11.2 + MinGW 13.1；独立菜单要求 Qt ≥6.8，前文旧 Qt 6.5/6.7 安装示例不适用于当前源码。Windows 默认 `QSG_RENDER_LOOP=basic`；排查显卡差异时可在启动前设置 `QSG_RENDER_LOOP=threaded` 对比，应用尊重显式配置。
