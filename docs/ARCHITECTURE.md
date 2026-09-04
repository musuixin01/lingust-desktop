# Linguist 系统架构与技术实现方案

## 1. 系统分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                      用户界面层 (Presentation)               │
│  - 桌面悬浮卡片 (FloatingTranslatorCard)                      │
│  - 原位截图卡片 (InPlaceScreenshotCard)                      │
│  - 划词快捷气泡 (SelectionTooltip)                           │
│  - 生词本抽屉 / 设置中心 / 桌面模拟器                         │
└──────────────────────────────┬──────────────────────────────┘
                               │ React 状态管理 / Hooks
┌──────────────────────────────▼──────────────────────────────┐
│                      业务服务层 (Services & Hooks)           │
│  - translationService: 统一多引擎请求调度与离线降级          │
│  - ocrService: 截图 OCR 数据清洗与对齐                      │
│  - storageService: 本地持久化与生词本管理                   │
│  - useDraggable: 桌面边界吸附与平滑阻尼拖动                  │
└──────────────────────────────┬──────────────────────────────┘
                               │ RESTful API (JSON over HTTP)
┌──────────────────────────────▼──────────────────────────────┐
│                   服务端代理与中间件 (Express + Node)         │
│  - /api/translate: 多模型并发负载与 429 容灾熔断             │
│  - /api/ocr-translate: 多模态视觉图文精准对齐                │
│  - /api/test-engine: 引擎可用性心跳探针                      │
└──────┬───────────────────────┬───────────────────────┬──────┘
       │                       │                       │
┌──────▼──────┐         ┌──────▼──────┐         ┌──────▼──────┐
│  Gemini AI  │         │  DeepL API  │         │  有道智云   │
│ (GoogleGenAI│         │ (Free & Pro)│         │ (OpenAPI v3)│
└─────────────┘         └─────────────┘         └─────────────┘
```

## 2. 核心技术亮点

### 2.1 429 速率限制智能熔断池 (Smart Model Fallback Pool)
针对大模型免费/高并发配额超限（HTTP 429）痛点，服务端设计了基于内存时钟的自动冷却机制：
- 预先配置低延迟、高配额的模型优先级列表：
  1. `gemini-3.1-flash-lite` (速度极快、消耗极小)
  2. `gemini-3.5-flash` (兼顾精度与上下文)
  3. `gemini-flash-lite-latest` (高可用保障)
  4. `gemini-3.8-flash` (高质量分析)
- 一旦捕获某模型 429 配额错误，立刻标记该模型冷却 60 秒，无感知自动切换至后续候选模型；
- 若全部在线模型不可用，静默平滑降级至内置高频双语兜底库与网络公共词典，确保前端永远拿到有效响应。

### 2.2 原地框选截图与段落结构保真 (In-Place OCR Alignment)
- 利用前端 `ScreenSnipper` 动态获取截图区域在屏幕坐标系下的 $(X, Y, W, H)$。
- 截图完成后直接在**截屏原始位置生成同等大小的半透明磨砂卡片**，让用户如同在原地直接看透译文。
- 多模态提示词强制要求 AI 保留换行符、缩进与段落形态，实现真正的中英逐行严密对齐。

### 2.3 极小尺寸下自适应排版与悬停滚动 (Hover-Scroll)
- 当卡片缩小至极限高度（$\le 145\text{px}$）或宽度较窄时，自动移除外围冗余控件，聚焦核心“输入框+释义”。
- 配合 CSS 原生动态 `@keyframes` 与平滑过渡，在鼠标移入时依内容溢出距离自动平滑来回循环滚动，保证小卡片空间利用率达到极致。

### 2.4 Electron 原生桌面端分层与无边框磨砂架构 (Desktop Native Architecture)
- **主进程与渲染进程解耦设计**：
  - 主进程 (`/electron/main.ts`)：专责原生窗口生命周期、系统托盘（System Tray）、全局快捷键注册（`Alt+Space`, `Alt+S`）、以及通过 `desktopCapturer` 调用底层显示器捕获；
  - 预加载安全桥 (`/electron/preload.ts`)：基于 Electron `contextBridge` 与严格沙箱规范向渲染层注入强类型 `window.electronAPI`；
  - 渲染进程 (`/src/`)：自适应检测是否运行于原生环境（`isElectron()`），若为原生环境则剔除仿真壁纸并激活窗口穿透、原生拖拽区（`-webkit-app-region: drag`）与窗口尺寸 1:1 双向同步；
  - 脱机与内嵌服务容灾：在打包或便携版中，主进程自启动内嵌 Express 服务并支持 `file://` 与 `localhost:3000` 端口双向回落，`vite.config.ts` 采用 `base: './'` 相对路径彻底杜绝离线灰白屏。
- **无冲突原生透明与苹果液态玻璃材质 (True Transparent Frameless & Liquid Glass)**：
  - 规避 Windows 平台 `backgroundMaterial: 'acrylic'` 与 `transparent: true` 互斥产生黑灰方形底框的问题，显式设定 `backgroundColor: '#00000000'`，关闭 OS 窗体黑灰硬边阴影（`hasShadow: false`）；
  - 全局根容器（`html, body, #root`）重置为纯透明，卡片主体直接填充无边框窗口（`100vw × 100vh`），卡片圆角（32px）和液态玻璃模糊滤镜直接呈现在桌面上；
  - 彻底解耦窗口被动缩放递归，窗体拉伸由 Windows/macOS 原生边框驱动，仅在模式切换（卡片 ↔ 药丸）时主动通知主进程重设窗口大小，彻底消除启动后卡片被持续压缩至最小形态的自激死循环。

### 2.5 智能语种嗅探与剪贴板自动识别联动 (Heuristic Language Detection on Paste)
- **非拉丁字符与专有文字集断言**：针对日文平假名/片假名（`[\u3040-\u309F\u30A0-\u30FF]`）、韩文谚文（`[\uAC00-\uD7AF]`）、俄文西里尔字母（`[\u0400-\u04FF]`）、中文 CJK 汉字体系，结合字符集排他性进行零延迟判定；
- **拉丁语族（EN/FR/DE/ES/IT/PT）字符与词频加权**：
  - 提取特定单语言标识（如德语 `ß`、西班牙语 `ñ/¿/¡`、葡萄牙语 `ã/õ/ão`、法语缩合与特殊音标等）；
  - 结合常见高频核心介词、连词及系统离线词库进行加权打分匹配，确保短语及句子识别准确率；
- **组件剪贴板事件流接管**：
  - 在 `FloatingTranslatorCard` 的输入框（极简胶囊、紧凑搜索栏、多行文本域）监听 `onPaste`；
  - 捕获文本后即时触发语种识别，自动同步更新 `sourceLang` 状态；
  - 遇到源与目标语言冲突时自动反转/调整目标语种，同时触发轻量 Toast 反馈胶囊与即时翻译调度。

## 3. 跨平台构建与发布流水线 (Build Pipeline)

- **Windows 构建目标**：
  - 执行 `npm run electron:build:win`；
  - 基于 `electron-builder` 打包出 NSIS 安装程序（带一键安装向导、桌面快捷方式与开机自启选项）以及 Portable 免安装绿色便携单文件版。
- **macOS 构建目标**：
  - 执行 `npm run electron:build:mac`；
  - 产出高保真 DMG 挂载磁盘镜像与 Zip 包，嵌入安全沙盒授权文件（`entitlements.mac.plist`）。
- **Web / 桌面混合启动模式**：
  - Web 沙盒预览：`npm run dev` 启动 Vite + Express 本地容灾服务；
  - 桌面原生调试：`npm run electron:dev` 启动本地 Vite 与 Electron 原生无边框桌面窗口。

