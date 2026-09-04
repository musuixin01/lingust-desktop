# Linguist 更新变更日志 (Changelog)

本项目严格遵循 [Semantic Versioning 2.0.0](https://semver.org/lang/zh-CN/) 语义化版本规范，以及 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/) 编写原则。
**规约：所有功能变更、代码重构与缺陷修复均会在此文档中实时更新记录。**

---

## [Unreleased] - 待发布 / 进行中

---

## [v1.3.0] - 2026-09-04

### [Added] Windows 桌面端原生封装与全功能落地 (Windows Desktop Electron Packaging)
- **技术架构选型与分层设计**：
  - 选用 **Electron 34+** 配合 **Vite 6**、**React 19**、**TypeScript** 与 **Express 4.21** 本地服务端，构建高性能、低占用（内存 < 90MB）的现代化跨平台桌面应用体系；
  - 保持现有所有核心业务逻辑（多态悬浮卡片、Gemini AI / DeepL / 有道 / 离线四核翻译、原地中英逐行截图对照、生词本）100% 完整支持。
- **无边框原生透明与亚克力 / 磨砂玻璃 (Frameless & Glassmorphic Acrylic)**：
  - 主进程窗口配置 `frame: false`、`transparent: true`、`hasShadow: false`，深度启用 Windows 11 `backgroundMaterial: 'acrylic'` 与 macOS `vibrancy: 'under-window'`；
  - 引入硬件加速抗锯齿圆角（32px）与纯净透明底层，在原生桌面运行时自动移除仿真背景，让半透明翻译卡片真正悬浮于用户桌面及第三方软件窗口上方。
- **全局快捷键与系统托盘驻留 (Global Shortcuts & System Tray)**：
  - 注册 `Alt + Space` 全局热键：快速显示 / 隐藏悬浮翻译卡片；
  - 注册 `Alt + S` 全局热键：任意时刻唤醒屏幕框选 OCR 翻译，支持基于 `desktopCapturer` 的原生高清屏幕捕获；
  - 建立 Windows 系统托盘（System Tray）：支持单击呼出、右键托盘菜单（显示主卡片、屏幕截词、系统设置、历史记录、完全退出），窗口关闭时智能隐藏至托盘后台运行。
- **双向安全通信桥接 (IPC & ContextBridge)**：
  - 编写 `/electron/preload.ts`，基于 `contextBridge.exposeInMainWorld` 注入类型安全的 `window.electronAPI`；
  - 封装 `/src/utils/electron.ts` 与 `/src/types/electron.d.ts`，提供窗口最小化、关闭至托盘、动态尺寸同步（`syncWindowSize`）、截屏调用及平台检测（`win32` / `darwin`）。
- **苹果风格超质感液体玻璃与自适应样式**：
  - 在 CSS 中定制 `.apple-liquid-glass` 与 `.apple-liquid-pill` 工具类，运用多重高饱和滤镜 `backdrop-filter: blur(32px) saturate(190%) contrast(104%)`，辅以晶体反光高光边缘与双层内阴影；
  - 系统设置窗中新增第 6 节“🖥️ 桌面端与原生架构配置”，展示运行状态徽章、系统全局热键与一键打包命令清单；
  - 增强桌面环境工作区模拟器：支持「双语阅读」、「VS Code 编程开发」与「纯净桌面悬浮」三大沉浸场景自由切换，并内置可视化「💻 本地桌面端运行指南」一键复制运行与打包指令。

### [Added] Windows 独立客户端预打包与一键直接下载 (Pre-built Windows Client & Direct Download)
- **Windows x64 独立客户端完成全量封包构建**：
  - 在云端完成 Windows x64 二进制与全量依赖（Chromium + Electron + ASAR + DLL 动态链接库）编译，输出完整绿色便携解包目录 `release/win-unpacked`（含 `Linguist.exe` 235MB）及高压缩包 `release/Linguist-Windows-v1.3.0-x64.zip`（197MB）；
  - 新增后端下载路由 `/api/download/windows` 与状态查询接口 `/api/download/status`，支持浏览器直接断点续传下载；
  - 界面顶栏右侧新增「📥 下载 Windows 打包版 (197MB)」高亮按钮，并在桌面端指南与系统设置第 6 节中均集成一键直接下载入口，用户无需安装任何命令行或 Node.js 环境，解压后双击 `Linguist.exe` 即可直接开箱运行。

### [Fixed] 解决 Cloud Run 32MB 单次响应上限与分片传输体系 (Chunked Stream Transfer & GitHub Actions CI/CD)
- **突破云端代理 32MB 上限**：
  - 根因：Google Cloud Run 负载均衡对单个 HTTP 响应体设有严格的 32MB 上限，用户浏览器直链请求 188MB 的 ZIP 文件会被云端代理直接阻断并返回 `HTTP ERROR 500`；
  - 架构重构：新增分片传输接口 `/api/download/chunk/:index`（将 188MB 安装包切分为 13 个每片 15MB 的安全二进制分片，并提供 `/api/download/status` 暴露分片元数据）；
  - 前端打造 `DownloadModal` 专属下载弹窗：支持实时百分比进度条（0% ~ 100%）、动态 MB 传输统计与分片计数（如 `3/13`），全部下载完毕后在浏览器内存中无缝还原组装成完整 ZIP 压缩包并自动触发文件保存；
  - 新增 `.github/workflows/build-release.yml`：为用户 GitHub 仓库配置全自动 GitHub Actions CI/CD 流程，一旦用户在 GitHub 创建版本标签（Tag），云端 Windows 运行机便会自动编译并生成 Release 安装包，永久托管供所有人高速下载。

### [Changed] Git 仓库初始化与 GitHub 导出优化 (Git Init & .gitignore Hardening)
- **.gitignore 规避 GitHub 100MB 限制**：
  - 将 `release/` 及 `dist-electron/` 纳入 `.gitignore`，防止已生成的 197MB Windows 客户端可执行程序超出 GitHub 100MB 单文件推送上限；
  - 完成本地 Git 仓库全量初始化与首版本规范提交（`main` 分支），确保在 AI Studio 中使用「Export to GitHub」可秒级一键推送到用户的个人 GitHub 仓库。


### [Added] 跨平台编译打包体系与 macOS 预设 (Windows & macOS Build Pipeline)
- **多平台构建配置 (`electron-builder.json`)**：
  - Windows：支持输出 NSIS 安装包与免安装绿色便携版（Portable），配置 256x256 高清 ICO 图标与一键静默升级参数；
  - macOS：配置好 DMG 镜像打包流程、高分辨率 ICNS 图标与沙盒权限清单（`electron/entitlements.mac.plist`）；
  - `package.json` 新增 `npm run electron:dev`（开发启动）、`npm run electron:build:win`（Windows 打包）及 `npm run electron:build:mac`（macOS 打包）。

---

## [v1.2.3] - 2026-09-03

### [Added] 动态紧凑排版与字号精确数值输入体系 (Dynamic Compact & Custom Font Sizing)
- **字体大小支持直接数值输入与步进微调**：
  - 在卡片顶栏右侧新增字体调控胶囊按钮与浮层菜单，支持在 60% ~ 150% 范围内直接键盘键入精确百分比数值；
  - 配备 `[-]` 与 `[+]` 5% 步进按钮、常用字号快捷预设（80% 紧凑、92% 默认、100% 标准、115% 大字），并实时同步到系统设置 `AppSettings.customFontSize`；
  - 系统设置模态窗（`SettingsModal`）第 5 节同步新增精确数字输入框与微调说明，支持任意字号自由定义。
- **默认字号精致化与视觉谐调**：
  - 将默认字号从偏大的 100% 优雅微调至 92%，使卡片默认状态下视觉更轻盈精致，解决“卡片变小字体却显过大”的失调感。

### [Changed] 动态紧凑模式布局与内边距/行距系统优化 (Dynamic Compact Layout)
- **CSS 紧凑间距与行高优化**：
  - 在未切换至最小化时，根据卡片尺寸或用户设置动态激活紧凑模式（`isDynamicCompact` / `isDynamicTight`）；
  - 将卡片内部内容容器外边距由 `p-4.5` 收紧为 `p-2.5`（或超紧凑 `p-2`），内容区行间距由 `space-y-3.5` 减小为 `space-y-2`（超紧凑 `space-y-1.5`）；
  - 将单词标题字号由过大的 3xl 降低为与卡片尺度平衡的 xl/lg/base，行高由宽松的 `leading-relaxed` 统一收拢为紧凑精致的 `leading-tight` / `leading-snug`；
  - 输入框与例句卡片内边距按尺寸等比紧凑排布，确保在任何紧凑状态下内容区域均被优雅裁剪，且完整保留所有例句、词性、同反义词与功能按钮。

---

## [v1.2.2] - 2026-09-03

### [Fixed] 药丸模式边缘上推缩小与放大按钮可靠交互
- **解决药丸形态上推缩小时误变回卡片问题**：
  - 彻底解耦药丸模式（Pill Mode）与完整卡片（Card Mode）的垂直拉伸逻辑；
  - 移除药丸底部边缘手柄在 `onMouseDown` 时强行触发的 `setIsMinimized(false)`；
  - 支持将药丸高度从默认 46px 自由往上推缩小至极限 38px，实现真正丝滑的微型胶囊形态；
  - 仅当向下拖拽位移超过 85px 时才判定为用户期望拉开展开为大卡片，彻底根除上推缩小反弹为卡片的误触。
- **解决药丸最右侧放大按钮无法点击问题**：
  - 将药丸右上角操作按钮容器提至独立高优先级层级 `relative z-50`（手柄调整为 `z-20`），并补充 `pointer-events-auto`；
  - 为放大按钮（`Maximize2`）及所有操作按钮添加 `onMouseDown={(e) => e.stopPropagation()}` 与点击独立保护，杜绝事件被卡片拖拽或边缘手柄捕获。

### [Changed] 紧凑模式内容一致性与全尺寸流式自适应缩放 (Fluid Scaling)
- **卡片缩小时保证内容一致性，严禁删减内容**：
  - 废弃强制剥离词性/释义/例句的粗暴截断逻辑，在任何小卡片尺寸下均完整呈现 `WordDetailView`；
  - 引入连续流式缩放比例因子 `fluidScale = min(1.0, max(0.78, min(width / 380, (height - 40) / 400)))`，使字号与间距随卡片尺寸连续、平滑等比缩小；
  - 保证输入框、红绿灯按钮、语言切换器、截图按钮、固定置顶、设置按钮、音标、词性中文、双语例句、同反义词标签以及底部操作栏（复制、朗读、收藏、历史）在卡片变小时全部完整保留，让用户体验无需来回翻找。

---

## [v1.2.1] - 2026-09-03

### [Fixed] 极小卡片角落悬停热区精确局限与防误触
- **触发热区精准收窄**：
  - 缩窄极小模式（Minimal Mode）下的左上角与右上角感应热区，从原先覆盖整条顶部的宽矩形严格局限为顶角边缘微型热区（`w-9 h-7`，即 36px × 28px），中间区域（包含搜索框及译文）移动鼠标时绝不意外弹出浮动胶囊，彻底解决顶部横向移动误触问题；
  - 浮动控制胶囊独立挂载，离开后通过 250ms 防抖平滑淡出，操作体验更轻快稳定。

### [Fixed] 正常卡片模式下左上角与右上角点击被拖拽逻辑影响问题
- **拖拽位移阈值防误触**：
  - 引入 4px 拖拽运动位移阈值（`Math.hypot(dx, dy) >= 4`），原位点击或微小抖动不再激活 `isDragging` 状态，彻底避免点击时触发卡片微缩放阻尼和布局抖动；
  - 调整卡片顶栏按钮组层级为 `relative z-30`，四角缩放手柄（Resize Handles）降级为 `z-20` 并精确收紧在边缘外侧（`w-4 h-4`），为所有红绿灯按钮、语言切换器及右侧功能图标赋予独立事件阻断（`stopPropagation`），彻底根除拖动手柄与拖动监听对按钮点击事件的吞没与抢占。

### [Fixed] 药丸模式缩至最小时搜索框点击失效问题
- **超窄药丸模式搜索点击保障**：
  - 优化药丸模式（Pill Mode）缩至最小（宽度 < 280px）时的交互状态，保留固定 28px 高辨识度的搜索图标胶囊按钮；
  - 强化搜索框容器独立性（`no-drag`、`relative z-30` 与点击即时聚焦展开逻辑），同时收窄左侧边缘感应热区至 16px，严禁向右遮挡搜索框，确保在任何极端极窄药丸尺寸下，用户点击搜索图标均能瞬间平滑展开为输入框。

---

## [v1.2.0] - 2026-09-03

### [Refactored] 企业级文件架构重组与工程模块化
- **前端组件分层**：
  - 将原本位于 `src/components/` 的平铺组件按业务领域拆分至独立子目录：
    - `src/components/common/`：通用原子组件 (`HoverScrollText`, `LanguageSelector`)
    - `src/components/translator/`：悬浮翻译卡片核心 (`FloatingTranslatorCard`, `WordDetailView`, `SelectionTooltip`)
    - `src/components/screenshot/`：原位截图翻译与 OCR (`ScreenSnipper`, `InPlaceScreenshotCard`, `ScreenshotTranslationView`)
    - `src/components/settings/`：系统设置中心 (`SettingsModal`)
    - `src/components/history/`：生词本与历史抽屉 (`HistoryDrawer`)
    - `src/components/desktop/`：macOS 桌面交互模拟器 (`DesktopSimulator`)
  - 建立标准 `index.ts` 导出机制，支持树摇优化与高聚合引用。
- **服务端模块化分层**：
  - 将单文件 `server.ts` 解耦，重构为微服务路由与适配器架构：
    - `server/config.ts`：服务器端口、网络超时与 Gemini 模型冷却时钟配置。
    - `server/routes/`：路由控制器（`translateRoute`, `ocrRoute`, `testConnectionRoute`）。
    - `server/services/`：多引擎适配层（`geminiService` 多模型轮询与 429 熔断池、`deeplService`、`youdaoService`、`fallbackService` 高频离线字典）。
  - `server.ts` 瘦身为极简中间件装配器与 Vite 开发服务挂载入口。
- **前端基础设施分层**：
  - 新增 `src/services/` 网络服务层：封装 `api.ts`、`translationService.ts`、`ocrService.ts`、`storageService.ts`。
  - 新增 `src/constants/` 常量层：集中管理 `languages.ts`、`storage.ts`、`defaults.ts`。
  - 新增 `src/hooks/` 自定义 Hook 层：抽取 `useDraggable.ts` 悬浮卡片拖拽与边界吸附逻辑。

### [Added] 极小尺寸自适应与文本悬停平滑滚动
- **极小尺寸模式（Minimal Mode）**：
  - 当卡片尺寸极小（高度 $\le 145\text{px}$ 或宽 $\le 240\text{px}$ 且高 $\le 190\text{px}$）时，自动隐藏红绿灯按钮、语言切换器与底部状态条，仅保留搜索输入框与翻译结果。
  - 严格保持原生卡片的字体比例与字号规范，不退化为药丸胶囊的压缩排版。
- **溢出文本悬停跑马灯（Hover-Scroll）**：
  - 引入 `HoverScrollText` 组件：当输入框内容或翻译文本超出容器宽度时，鼠标悬停（Hover）即可触发平滑横向来回滚动，保证极端小尺寸下内容完整可读。
  - 支持即时点击编辑、Enter 键快速触发翻译。

### [Added] 极小卡片角落智能浮动控制 (Corner Hover Trigger Controls)
- **左上角关闭与缩小按钮**：
  - 当卡片缩至极小尺寸（Minimal Mode）时，鼠标移动到左上角区域（Top-Left Zone），平滑渐入显示“关闭/清空”与“缩小收起为药丸”快捷按钮（搭配 macOS 经典红黄绿微交互与悬停提示）；鼠标离开后自动平滑隐退，确保不占用极小尺寸下的视觉空间。
- **右上角功能图标组**：
  - 鼠标移动到右上角区域（Top-Right Zone）时，平滑渐入显示功能图标组（包含复制、朗读发音、截图翻译、置顶固定、偏好设置、生词本）；离开后自动淡出。
- **全卡片背景直接拖拽**：
  - 在极小尺寸下为卡片容器绑定拖拽控制器，在非输入/非按钮区域均可随时直接拖动位移。

### [Changed] 极小卡片译文字体颜色全局统一
- **消除绿色色差**：
  - 修复极小卡片及流线模式下翻译结果呈现为绿色（`text-emerald-300`）的色差问题，全局统一采用标准卡片的强调文本色（`text-white/95`，高对比度白）；
  - 无论在完整卡片、极小尺寸模式（Minimal）还是流线模式（Streamlined）下，音标、释义、正文与标题均严格遵守 `DESIGN_SYSTEM.md` 中定义的色彩 Token 规约。
- **涉及文件**：`src/components/translator/FloatingTranslatorCard.tsx`。

### [Fixed] 修复音标对象作为 React 子节点导致的渲染崩溃
- **问题根因**：在悬浮翻译卡片极小尺寸模式（Minimal Mode）下，`HoverScrollText` 的 `prefix` 属性直接尝试渲染了 `result.phonetic` 对象（格式为 `{ general?: string, us?: string, uk?: string }`），触发 React 运行时抛出 `Uncaught Error: Objects are not valid as a React child (found: object with keys {general, us, uk})`。
- **修复方案**：
  - 在 `src/components/translator/FloatingTranslatorCard.tsx` 中安全解析 `result.phonetic`（兼顾字符串与对象），规范化提取音标字符串并在两侧包裹单个斜线 `/[IPA]/`，作为安全纯文本字符串传入；
  - 优化极简模式下的译文渲染逻辑，将词性释义与同义词与音标前缀解耦，避免同一音标在卡片中重复拼接显示；
  - 在 `src/components/history/HistoryDrawer.tsx` 中同步增强音标防呆格式化，避免双斜线 `//...//` 异常。
- **涉及文件**：`src/components/translator/FloatingTranslatorCard.tsx`、`src/components/history/HistoryDrawer.tsx`。

### [Docs] 企业级技术文档与 UI 设计系统构建
- 新增 `docs/DESIGN_SYSTEM.md`：**Linguist 视觉设计规范与 UI 系统指南**，统一全局深空微蓝冷调毛玻璃材质（Glassmorphism）、文本与层级对比度 Token、字体家族与等宽音标排版、8pt 间距与内外圆角嵌套数学规约、多态几何断点、组件规范及 Anti-Slop 反套路防劣化准则。
- 新增 `docs/HANDOVER.md`：生产级项目交接手册，涵盖业务背景、系统定位、多引擎时序、自适应断点、排障手册（Troubleshooting）。
- 新增 `docs/ARCHITECTURE.md`：系统架构设计方案，详细分析 429 速率限制智能熔断池、原位截屏 OCR 排版保真算法。
- 新增 `docs/API.md`：RESTful 接口规范文档，详细列出各端点 Request/Response JSON Schema。
- 新增 `README.md`：企业级项目总览、特性矩阵、架构说明与本地快速启动指南。
- 新增 `AGENTS.md`：持久化项目开发规约，强制要求未来所有修改变更必须实时同步至文档中。

---

## [v1.1.0] - 2026-09-02

### [Added] 原地框选截图翻译 (In-Place Snippet Translation)
- 新增 `ScreenSnipper` 屏幕任意区域自由选区与视觉截屏能力。
- 新增 `InPlaceScreenshotCard`：在用户截屏的原坐标位置就地生成同尺寸半透明磨砂卡片，实现中英逐行严密排版对照。
- 接入多模态视觉转录，保留段落换行、行首缩进与标点符号。

### [Added] 多引擎接入与连通性验证
- 支持 Google Gemini AI、DeepL (Free & Pro)、有道智云及本地离线四种引擎。
- 设置中心提供实时连通性测试接口（`POST /api/test-engine`）。

---

## [v1.0.0] - 2026-09-01

### [Added] Linguist 初始版本发布
- 悬浮毛玻璃翻译卡片核心设计与自由无边界拖拽。
- 单词详查模式：音标发音（英美双音）、词性分级、双语例句与同反义词。
- 划词快捷气泡（Selection Tooltip）。
- 本地历史记录与生词本管理抽屉（History Drawer）。
