# 🌐 Linguist 桌面悬浮翻译卡片 (Linguist Desktop Floating Translator)

<div align="center">

![TypeScript](https://img.shields.io/badge/TypeScript-5.8-blue?logo=typescript)
![React](https://img.shields.io/badge/React-19.0-61dafb?logo=react)
![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-4.1-38b2ac?logo=tailwind-css)
![Express](https://img.shields.io/badge/Express-4.21-lightgrey?logo=express)
![Google Gemini](https://img.shields.io/badge/Google_Gemini-2.4-orange?logo=google)
![License](https://img.shields.io/badge/License-MIT-green)

**轻量优雅、毛玻璃质感的全能桌面悬浮翻译卡片与高保真词典。**  
支持 Google Gemini AI 语境理解、DeepL 神经翻译、有道智云及 100% 离线脱机词库；配备自由悬浮拖拽、自适应卡片几何断点、原地框选截图逐行对照等企业级交互。

[在线体验](https://ais-dev-tfalt4gnuqjcgjvauvvgey-914692639781.asia-southeast1.run.app) • [UI 风格规范](./docs/DESIGN_SYSTEM.md) • [更新日志](./docs/CHANGELOG.md) • [架构文档](./docs/ARCHITECTURE.md) • [接口文档](./docs/API.md) • [交接说明](./docs/HANDOVER.md)

</div>

---

## ✨ 核心特性矩阵

| 核心模块 | 功能亮点 |
| :--- | :--- |
| 🪟 **多态悬浮卡片** | 任意边缘平滑拉伸、自由无阻尼拖拽与八向吸附。自适应标准展开态、紧凑态、极小化搜索模式及胶囊药丸跑马灯（Pill Mode）。 |
| 🧠 **四核翻译体系** | **Gemini AI 语境引擎**（深度词典、音标、双语例句与同义词）+ **DeepL 神经翻译** + **有道智云** + **100% 零网络离线词库**。 |
| 🛡️ **智能容灾熔断** | 内置模型负载倒换池（`3.1-flash-lite` $\rightarrow$ `3.5-flash` $\rightarrow$ `flash-lite-latest`），遇 429 速率限制自动冷却 60 秒并无缝降级。 |
| 📸 **原位框选截图翻译** | 屏幕任意区域自由截取，原位悬浮生成对照卡片，精准保留原文档段落与排版，呈现中英逐行严密对齐。 |
| 📜 **超长文本悬停跑马灯** | 在最小化卡片状态下，搜索框和翻译结果超出边界时，鼠标悬停即自动触发平滑双向滚动（Hover-Scroll）。 |
| 📚 **生词本与历史管理** | 本地极速持久化存储，支持收藏标记、多维度关键词检索、双语一键发音与批量清空。 |
| 🎙️ **双语真声发音** | 原生 Web Speech 引擎支持美音、英音、中文等多种自然发音与音调调节。 |

---

## 🏗️ 项目架构与工程目录

```text
/
├── server.ts                       # 服务端装配入口 (Express + Vite 中间件)
├── server/                         # 服务端模块化目录
│   ├── config.ts                   # 服务端口与模型配置
│   ├── routes/                     # 路由分发 (/api/translate, /api/ocr-translate, etc.)
│   └── services/                   # 引擎调度适配层 (Gemini, DeepL, 有道, 离线字典)
├── src/                            # 前端核心源码
│   ├── components/                 # 分类组件库
│   │   ├── common/                 # 基础原子组件 (HoverScrollText, LanguageSelector)
│   │   ├── translator/             # 悬浮翻译卡片核心 (FloatingTranslatorCard, WordDetailView)
│   │   ├── screenshot/             # 截图与原地对照 (ScreenSnipper, InPlaceScreenshotCard)
│   │   ├── settings/               # 设置模态框 (SettingsModal)
│   │   ├── history/                # 生词本抽屉 (HistoryDrawer)
│   │   └── desktop/                # 桌面仿真环境 (DesktopSimulator)
│   ├── constants/                  # 多语种、存储 Key、初始常量
│   ├── services/                   # 前端网络请求层与持久化服务
│   ├── hooks/                      # 拖拽与响应式自定义 Hook (useDraggable)
│   ├── utils/                      # 离线词典算法 (offlineEngine) 与语音 (speech)
│   ├── types.ts                    # 全局 TypeScript 接口规约
│   ├── App.tsx                     # 根应用视图
│   └── main.tsx                    # React 19 应用入口
└── docs/                           # 企业级全套文档
    ├── HANDOVER.md                 # 生产级交接与排障说明
    ├── ARCHITECTURE.md             # 系统架构设计
    └── API.md                      # RESTful 接口规范
```

---

## 🚀 快速上手 (Quick Start)

### 1. 安装环境要求
- **Node.js**: >= 20.0.0
- **包管理器**: npm (或 pnpm / bun)

### 2. 配置环境变量
在项目根目录下创建或编辑 `.env` 文件：

```env
# Gemini API Key（服务端专用，切勿在前端代码中硬编码）
GEMINI_API_KEY=your_gemini_api_key_here

# 服务端口
PORT=3000
```

### 3. 运行开发环境

**Web 浏览器开发预览**：
```bash
npm install
npm run dev
```
访问：`http://localhost:3000`

**桌面端原生调试 (Windows / macOS)**：
```bash
npm run electron:dev
```

---

## 🖥️ 桌面客户端打包与发布 (Desktop Packaging)

Linguist 采用现代化 Electron 34+ 跨平台无边框技术架构，深度支持 **Windows 11 原生亚克力（Acrylic/Mica）** 与 **macOS 原生超质感磨砂玻璃（Liquid Glass & Vibrancy）**。

### 1. Windows 客户端构建 (NSIS 安装包 & 便携免安装版)
```bash
npm run electron:build:win
```
- **输出产物**：位于 `release/` 目录；
- **安装包 (`.exe`)**：带有一键向导、桌面快捷方式、系统托盘常驻与开机启动支持；
- **便携版 (`-portable.exe`)**：单文件免安装即开即用，适合 U 盘随身携带与企业纯净环境。

### 2. macOS 客户端构建 (DMG 镜像 & 应用程序包)
```bash
npm run electron:build:mac
```
- **输出产物**：位于 `release/` 目录；
- 产出高保真 `.dmg` 挂载镜像与 `.zip`，支持 Retina 视网膜屏幕与原生系统快捷键。

### 3. 全局桌面快捷键
- **`Alt + Space`**：全局呼出 / 隐藏悬浮翻译卡片；
- **`Alt + S`**：全局随时框选截屏翻译（支持中英逐行原位严密对齐）；
- **系统托盘驻留**：关闭主窗口自动最小化至右下角系统托盘，双击随时唤出。

---

## 🛠️ 构建与部署规范 (Build & Deploy)

### 静态检查
```bash
npm run lint
```

### 生产打包
```bash
npm run build
```
执行过程将自动完成：
1. Vite 生产静态资源构建至 `dist/`；
2. esbuild 将后端 TypeScript 服务代码捆绑编译为高性能 CommonJS 单文件 `dist/server.cjs`。

### 启动生产服务
```bash
npm start
```

---

## 📖 技术文档指引

- **[UI 风格规范指南 (DESIGN_SYSTEM.md)](./docs/DESIGN_SYSTEM.md)**：全局视觉设计语言、毛玻璃材质、色彩与文本 Token、内外圆角嵌套几何、排版比例与 Anti-Slop 反套路准则。
- **[版本更新日志 (CHANGELOG.md)](./docs/CHANGELOG.md)**：记录所有版本特性迭代、代码重构、缺陷修复及变更历史（实时同步更新）。
- **[企业交接文档 (HANDOVER.md)](./docs/HANDOVER.md)**：包含详细的系统架构图、数据时序、排障指南与业务交接清单。
- **[系统架构方案 (ARCHITECTURE.md)](./docs/ARCHITECTURE.md)**：深入介绍 429 智能熔断降级池、自适应卡片几何引擎与原地截屏算法。
- **[接口规范文档 (API.md)](./docs/API.md)**：包含全部 RESTful 接口出入参及错误代码对照表。

---

## 📄 开源许可证

本项目基于 MIT License 协议开源。
