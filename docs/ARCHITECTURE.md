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
│  - storageService: 本地持久化与历史记录管理                 │
│  - dataService: 生词本独立持久化与数据导入导出             │
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

### 2.4 生词本独立持久化与数据导入导出 (Independent Wordbook & Data Exchange)
- **生词本与历史解耦**：
  - 生词本独立存储于本地键 `linguist_favorites`，翻译历史存储于 `linguist_history`，两者互不干扰；清空历史绝不误删生词本；
  - 以「原文（忽略大小写）」作为生词唯一身份标识（`favoritesService.isFavoriteByText` / `toggleFavoriteByItem`），避免重复词条；
  - 收藏快照保留完整词条详情（音标、词性、例句、同反义词），卡片收藏按钮、历史星标与生词本数据三方实时联动。
- **数据导入导出流水线**：
  - 导出：`dataExchangeService.exportToFile` 将历史/生词本序列化为带元信息包裹的 JSON（`app` / `type` / `version` / `exportedAt` / `items`）并触发浏览器下载；
  - 导入：`dataExchangeService.importFromFile` 读取文件，兼容包裹结构与裸数组，按「原文」去重后自动分流——带收藏标记的归入生词本，其余归入历史；
  - 剪贴板：`copyToClipboard` 支持将列表以 JSON 文本临时迁移与分享。
- **双语一键发音**：生词本条目提供原文（`sourceLang`）与译文（`targetLang`）双发音靶标，复用 `utils/speech.ts` Web Speech 引擎。


---

## 3. 桌面客户端架构（Electron）

### 3.1 进程模型
- **主进程**（`electron/main.cjs`）：窗口生命周期、系统托盘、全局快捷键、内置后端启动、IPC 调度；
- **渲染进程**：React 19 + Vite 构建的前端，通过 `preload.cjs` 暴露的 `window.electronAPI` 与主进程通信（`contextIsolation:true, nodeIntegration:false`）；
- **内置后端**：主进程 require `dist/server.cjs` 的 `startServer`，在 127.0.0.1 随机端口启动 Express，渲染进程通过 `http://127.0.0.1:<port>` 调用翻译 API。

### 3.2 窗口与卡片几何
- `WINDOW_EDGE=0`（前后端必须一致）：窗口紧贴卡片，无四周留白背景框；
- 窗口尺寸 = 卡片尺寸；卡片在窗口内固定定位于 `(0, 0)`；
- 桌面模式卡片采用深色半透明底（标准 `rgba(15,23,42,0.55)` / 药丸 `rgba(2,6,23,0.6)`）+ `backdrop-blur-3xl` 毛玻璃，保证主题色与文字可读性；
- 拖动：渲染进程检测到拖动后通过 IPC `dragMove(mouseX, mouseY)` 通知主进程，主进程以拖动起始窗口位置为锚 `setPosition`，并 clamp 到屏幕工作区；
- 缩放：渲染进程尺寸变化通过 `useEffect` 同步 IPC `resizeWindow(w, h)`，主进程 `setSize(w+edge*2, h+edge*2)`；药丸/极简形态变化亦同步。

### 3.3 后端启动策略（resolveBackend）
1. 显式 `LINGUIST_DEV_URL` 环境变量 → 直接使用该 URL；
2. 开发模式检测 3000 端口 `/api/health` 返回 200 → 复用外部 dev server；
3. 否则启动内置后端（`LINGUIST_EMBEDDED=1` + `NODE_ENV=production`，端口 31000~35999 随机，staticDir 指向 `dist/`）。

### 3.4 打包与分发
- electron-builder 配置于 `package.json` 的 `build` 字段；
- Windows：NSIS 安装包 + Portable 便携版，输出至 `release/`；
- macOS：dmg + zip（配置预留，需在 macOS 环境执行 `npm run desktop:pack:mac`）；
- asar 打包：`dist/`、`electron/`、`assets/`、`package.json` 及运行时 dependencies 打入 asar；devDependencies（如 vite）不打包——`server.ts` 已将 vite 改为动态 import 仅 dev 分支加载。
