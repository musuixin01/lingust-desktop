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
| 📚 **生词本与历史管理** | 生词本独立持久化（清空历史不误删收藏），多维度关键词检索、双语一键发音、JSON 导入导出与剪贴板备份。 |
| 🎙️ **双语真声发音** | 原生 Web Speech 引擎支持美音、英音、中文等多种自然发音与音调调节。 |
| 🖥️ **Electron 桌面客户端** | 透明无边框置顶悬浮窗 + 系统托盘 + 全局快捷键（Ctrl+Shift+L）+ 内置 Express 后端，Windows 安装包/便携版，macOS 配置预留。 |

---

## 🏗️ 项目架构与工程目录

```text
/
├── server.ts                       # 服务端装配入口 (Express + Vite 中间件)
├── server/                         # 服务端模块化目录
│   ├── config.ts                   # 服务端口与模型配置
│   ├── routes/                     # 路由分发 (/api/translate, /api/ocr-translate, etc.)
│   └── services/                   # 引擎调度适配层 (Gemini, DeepL, 有道, 离线字典)
├── electron/                       # Electron 桌面客户端
│   ├── main.cjs                    # 主进程（透明悬浮窗/内置后端/托盘/快捷键/IPC）
│   └── preload.cjs                 # 预加载脚本（暴露 window.electronAPI）
├── assets/                         # 静态资源
│   └── icon.png                    # 应用图标（512×512，electron-builder 自动转 ico/icns）
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
```bash
npm install
npm run dev
```
访问：`http://localhost:3000`

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

---

## 🖥️ 桌面客户端运行与打包 (Electron)

### 开发模式运行
```bash
# 方式一：自动检测（无 3000 dev server 时自动启动内置后端）
npm run desktop

# 方式二：复用外部 dev server（先 npm run dev，再启动桌面端）
npm run desktop:dev
```

### 打包 Windows 安装包
```bash
# 国内网络建议先设置镜像
$env:ELECTRON_MIRROR='https://npmmirror.com/mirrors/electron/'
$env:ELECTRON_BUILDER_BINARIES_MIRROR='https://npmmirror.com/mirrors/electron-builder-binaries/'

# 打包（NSIS 安装包 + Portable 便携版，输出至 release/）
npm run desktop:pack
```

### 打包 macOS 版（需在 macOS 环境执行）
```bash
npm run desktop:pack:mac
```

### 全局快捷键
| 快捷键 | 功能 |
| :--- | :--- |
| `Ctrl+Shift+L`（macOS `Cmd+Shift+L`） | 切换悬浮卡片显示/隐藏 |
| `Alt+S` | 触发截图翻译 |

### 系统托盘
右下角托盘图标支持「显示/隐藏悬浮卡片」「退出」，左键单击切换显示状态。关闭窗口 = 隐藏到托盘（悬浮常驻），右键托盘「退出」才真正退出。

