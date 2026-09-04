# Linguist - Windows 原生桌面端 (WinUI 3 + .NET 10 LTS + Windows App SDK 2.x)

本项目使用 **C# 14 / .NET 10 LTS**、**Windows App SDK (WinUI 3)**、**XAML**、**Win32 DWM API** 以及 **Windows UI Automation** 严格 1:1 纯粹复刻悬浮翻译卡片与药丸胶囊的界面与交互体系。

---

## 架构与技术栈选型

- **核心语言**：C# 14 (.NET 10.0-windows10.0.19041.0)
- **UI 框架**：WinUI 3 (Windows App SDK 最新稳定版) + XAML
- **操作系统底层支持**：
  - **Win32 API & DWM (Desktop Window Manager)** 深度互操作（`DwmSetWindowAttribute`、`DWM_WINDOW_CORNER_PREFERENCE.DWMWCP_ROUND`、`DWMWA_BORDER_COLOR`）
  - 原生支持 **32px 物理大圆角**，无任何 Windows 11 默认 1px 黑边或伪影
  - 原生支持 `WM_NCLBUTTONDOWN` / `HTCAPTION` 实现无感、高帧率平滑拖拽
- **无障碍与自动化**：
  - 全面搭载 `Windows UI Automation`（`AutomationProperties.Name`、`AutomationProperties.AutomationId` 等标准自动化标识）
- **应用模式**：非打包独立模式 (`WindowsPackageType=None`)，即开即用，无需安装 MSIX 证书。

---

## 视觉与组件 1:1 复刻清单

### 1. 悬浮翻译卡片 (`CardView.xaml`)
- **标准规格**：390 × 520 像素，`CornerRadius="32"` 苹果液态磨砂玻璃（Apple Liquid Glass）与镜面高光外圈；
- **顶部操作栏**：
  - 经典三色红黄绿控制点：红（清空内容）、黄（收缩为药丸胶囊）、绿（刷新翻译）；
  - 居中语言互换药丸（`英语 ➔ 中文`）与实时引擎胶囊指示（`● Gemini`）；
  - 右侧工具群：截图框选翻译（Crop）、置顶固定（Pin）、字体比例胶囊（Type 92%）、偏好设置（Sliders）；
- **主内容与输入区**：
  - 大圆角半透玻璃输入框，支持多行自适应伸缩与一键清空；
  - 丰富词典释义模型：单词标题、美式音标 `[ɪˈfɪʃnt]`、发音按钮、生词本红心收藏；
  - 词性蓝色胶囊（`adj.`）与分项释义；
  - 同义词气泡流（`effective`、`productive`、`streamlined`）；
  - 双语对照例句卡片；
  - 快捷操作工具栏：语言对标示、一键复制（带复制成功状态）、生词历史；
- **底部状态栏**：
  - Smart-Select 智能划词状态滑动胶囊；
  - 物理尺寸标示与四角缩放提示。

### 2. 悬浮药丸胶囊 (`PillView.xaml`)
- **标准规格**：高度 46px，`CornerRadius="9999"` 极致胶囊大圆角；
- **左侧微控点**：红绿双点，悬停快捷清空与一键展开回卡片；
- **快捷搜索框**：微型磨砂输入槽，带放大镜图标与 Enter 翻译交互；
- **双语对齐区**：原文 `Efficient` ➔ 译文 `高效的；有效率的；有能力的`，自适应字符截断；
- **右侧快捷按钮群**：朗读发音、一键复制、全功能卡片展开按钮。

---

## 本地编译与运行指南 (Windows 环境)

### 方式一：VS Code (完全支持！)
本项目已内置配置好 `.vscode/launch.json`、`.vscode/tasks.json` 与 `.vscode/extensions.json`：
1. 在 Windows 上安装：
   - **.NET SDK** (.NET 8 LTS 或 .NET 10)
   - VS Code 插件：**C# Dev Kit** (`ms-dotnettools.csdevkit`)
2. 在 VS Code 中打开本工程根目录；
3. 直接按键盘 **F5**（或者按 `Ctrl+Shift+B` 触发构建），VS Code 会自动触发 `dotnet build` 并拉起 Windows 原生大圆角透明窗口进行调试运行！
4. 亦可在 VS Code 内置终端中直接运行：
   ```powershell
   dotnet run --project Linguist.WinUI
   ```

### 方式二：Visual Studio 2026 / 2022
1. 安装 **Visual Studio 2022 (17.8+)** 或 **Visual Studio 2026**，勾选工作负荷：
   - **.NET 桌面开发** (包含 .NET 8 / .NET 10 SDK)
   - **Windows 应用程序开发** (包含 Windows App SDK C# 模板)
2. 双击打开 `Linguist.WinUI/Linguist.WinUI.csproj`。
3. 选择目标平台为 `x64`（或 `ARM64`），启动目标选择 **Linguist.WinUI (Package: None)**。
4. 按 `F5` 即可秒速原生启动运行！

### 方式三：.NET CLI 纯命令行构建
在 Windows Terminal / PowerShell 中进入目录：
```powershell
cd Linguist.WinUI
dotnet restore
dotnet build -c Release -r win-x64
dotnet run
```
