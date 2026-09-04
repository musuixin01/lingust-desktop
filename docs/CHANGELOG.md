# Linguist 更新变更日志 (Changelog)

本项目严格遵循 [Semantic Versioning 2.0.0](https://semver.org/lang/zh-CN/) 语义化版本规范，以及 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/) 编写原则。
**规约：所有功能变更、代码重构与缺陷修复均会在此文档中实时更新记录。**

---

## [Unreleased] - 待发布 / 进行中

---

## [v1.4.0] - 2026-09-04

### [Added] Electron 桌面客户端封装：真正的桌面悬浮翻译卡片 (Electron Desktop Client)
- **透明无边框置顶悬浮窗**：Electron `BrowserWindow` 配置 `frame:false, transparent:true, resizable:false, alwaysOnTop:true, hasShadow:true`，窗口即悬浮卡片，四周 12px 透明留白（`WINDOW_EDGE`）用于阴影与圆角呼吸空间，卡片在窗口内固定定位于 `(12, 12)`；
- **内置 Express 后端**：Electron 主进程启动时自动启动内嵌后端（`LINGUIST_EMBEDDED=1` + `NODE_ENV=production`），端口在 31000~35999 随机选取，host 绑定 `127.0.0.1`，静态资源指向 `dist/`；开发模式下若检测到 3000 端口有 dev server 则自动复用，否则启动内置后端；
- **系统托盘**：右下角托盘图标（`assets/icon.png`，缺失时 SVG dataURL 兜底），菜单含「显示/隐藏悬浮卡片」「退出」，托盘左键单击切换显示状态；
- **全局快捷键**：`Ctrl+Shift+L`（macOS `Command+Shift+L`）切换悬浮卡片显示/隐藏；`Alt+S` 触发截图翻译（渲染进程 `trigger:screenshot` 事件）；
- **IPC 桌面能力**：`window.electronAPI` 暴露 `startDrag/dragMove/endDrag`（窗口整体拖动，主进程以原始位置为锚 `setPosition` 并 clamp 到工作区）、`resizeWindow`（卡片尺寸→窗口尺寸，自动加 `WINDOW_EDGE*2`）、`setAlwaysOnTop/setOpacity/hideWindow/minimizeWindow/quitApp`；
- **前端桌面模式适配**：`App.tsx` 检测 `window.electronAPI?.isDesktop`，桌面模式下不渲染 `DesktopSimulator` 模拟桌面、根容器背景透明；`FloatingTranslatorCard.tsx` 桌面模式下卡片固定定位于窗口边缘、拖动走 IPC `dragMove`（不再更新本地 position state）、尺寸变化通过 `useEffect` 同步 IPC `resizeWindow`（含药丸/极简形态）；
- **electron-builder 跨平台打包**：Windows 输出 NSIS 安装包（`Linguist Setup 0.0.0.exe`，oneClick:false 可选安装目录 + 桌面快捷方式）+ Portable 便携版（`Linguist 0.0.0.exe`）；macOS 配置预留（dmg + zip，`public.app-category.productivity`，darkModeSupport）；手机端待定；
- **应用图标**：`assets/icon.png`（512×512 蓝色圆角方块 + 白色 L，electron-builder 自动转 ico/icns）。

### [Changed] server.ts 改造为可编程式启动 (Programmatic Server Startup)
- `server.ts` 导出 `startServer(opts?: {port?, host?, staticDir?})` 返回 `Promise<number>`（实际监听端口），支持外部调用方（Electron 主进程）控制启动时机与参数；
- `isProd = opts.staticDir !== undefined || NODE_ENV==='production'`，生产模式 `express.static(opts.staticDir ?? path.join(process.cwd(),'dist'))` + SPA fallback；开发模式走 Vite middleware；
- 仅当作为主入口直接运行且 `LINGUIST_EMBEDDED!=='1'` 时自启动，主入口判断兼容 ESM（tsx，`import.meta.url`）与 CJS（node dist/server.cjs，`require.main === module`）双模式；
- `server/config.ts` 的 `PORT` 支持 `process.env.PORT` 覆盖。

### [Fixed] 桌面客户端透明窗口大黑框 (Transparent Window Black Background)
- **问题根因**：Electron 透明窗口下，`html/body/#root` 未设置透明背景，页面默认背景（白色/黑色）填充整个窗口，导致卡片周围出现大黑框；同时 `hasShadow: true` 在 Windows 透明窗口上会产生黑色边框阴影；
- **修复方案**：
  - `src/index.css` 新增 `html, body, #root { background: transparent !important; }`，确保页面根背景完全透明；
  - `electron/main.cjs` 将 `hasShadow: true` 改为 `false`（Windows 透明窗口下系统阴影会产生黑边），阴影由卡片自身 CSS `box-shadow` 提供；
  - 移除 `backgroundColor: '#00000000'`（透明窗口无需额外设置背景色）。

### [Fixed] 桌面客户端窗口拖动错乱 (Window Drag Jitter)
- **问题根因**：原拖动逻辑用渲染进程传入的 `clientX/clientY`（鼠标在窗口内的坐标）计算窗口位移 `dx = currentClientX - startClientX`，但窗口移动后鼠标相对窗口的坐标参考系发生变化，导致 `dx` 计算错误、窗口拖动时跳动/错位；
- **修复方案**：主进程 `window:dragMove` 改用 `screen.getCursorScreenPoint()` 获取鼠标**屏幕绝对坐标**，`startDrag` 时记录鼠标在窗口内的偏移量（`offsetX = clientX, offsetY = clientY`），拖动时 `窗口位置 = 鼠标屏幕坐标 - 偏移量`，彻底消除参考系错乱。

### [Fixed] 桌面客户端卡片缩小逻辑异常 (Desktop Resize Restriction)
- **问题根因**：桌面模式下卡片固定定位于窗口内 `(WINDOW_EDGE, WINDOW_EDGE)`，从左/上边缘缩放时渲染进程的 `setPosition` 无效（卡片不随窗口左/上边缘移动），导致缩放时卡片位置跳动、视觉异常；
- **修复方案**：桌面模式下仅允许**右下角（se）**缩放，禁用其他 7 个方向的缩放手柄（`handleResizeMouseDown` 中 `isWindowMode && direction !== 'se'` 时直接 return）；右下角缩放时窗口位置不变、卡片固定在窗口左上角，缩放体验稳定。

### [Fixed] 打包后 exe 启动即崩溃：vite 为 devDependency 未打包 (MODULE_NOT_FOUND: vite)
- **问题根因**：`server.ts` 顶层 `import { createServer } from 'vite'`，esbuild `--packages=external` 将 vite 标记为外部依赖未打包进 `dist/server.cjs`；electron-builder 默认不打包 devDependencies，打包后 asar 内无 vite，Electron production 模式加载 server.cjs 时顶层 require('vite') 即抛 `MODULE_NOT_FOUND`，exe 启动后立即退出；
- **修复方案**：vite 改为**动态 `await import('vite')`**，仅在开发分支（`!isProd`）需要 Vite middleware 时才加载；Electron production 模式走 `express.static` 分支，永不触发 vite 加载，彻底消除对 devDependency 的运行时依赖；
- **验证**：打包后 `Linguist.exe` 正常启动（4 进程，窗口标题「Linguist 桌面悬浮翻译卡片」），后端 health `nodeEnv=production`，透明悬浮卡片正常渲染。

### [Reverted] 回退透明窗口修复，恢复初始桌面客户端状态 (Restore Initial Desktop State)
- **回退原因**：用户确认希望恢复到"刚打包好时"的初始桌面客户端状态——窗口使用深色壁纸背景（存在深色背景框，即用户所称"大黑框"），卡片使用原生 `bg-white/10 + backdrop-blur-3xl` 毛玻璃效果，毛玻璃模糊后面的深色壁纸背景，呈现深色毛玻璃质感，文字清晰可见；
- **回退内容**：
  1. `src/App.tsx`：桌面模式根 div 恢复 `wallpaperClass` 深色壁纸背景（移除 `bg-transparent`）；
  2. `src/index.css`：移除 `html, body, #root { background: transparent !important }`；
  3. `electron/main.cjs`：`hasShadow` 恢复 `true`，恢复 `backgroundColor: '#00000000'`；
  4. `src/components/translator/FloatingTranslatorCard.tsx`：移除桌面模式深色半透明底（`rgba(15,23,42,0.65)` / `rgba(2,6,23,0.7)`），标准卡片恢复 `bg-white/10 backdrop-blur-3xl`，药丸恢复 `bg-slate-950/85 backdrop-blur-3xl`；
- **当前状态**：桌面客户端 = 初始版本（深色壁纸背景窗口 + 原生毛玻璃卡片 + 深色背景框），拖动/缩放逻辑保持 IPC 实现（主进程屏幕坐标拖动 + 仅右下角缩放）；
- **备选主题预留**：不透明纯色深色（标准 `#0f172a` / 药丸 `#020617`）与透明窗口方案（html/body transparent + hasShadow:false）均已在代码历史中验证，后续可作为设置中的主题切换选项供用户选择。

### [Changed] 完全删除桌面客户端背景框，窗口紧贴卡片 + 卡片深色半透明毛玻璃 (Remove Window Frame, Frosted Card)
- **变更原因**：用户要求完全删除深色背景框（"它在那也没用"），同时卡片保持深色毛玻璃效果、主题色不变、文字可见；
- **变更内容**：
  1. **WINDOW_EDGE 从 12 改为 0**（`electron/main.cjs` 与 `src/components/translator/FloatingTranslatorCard.tsx` 同步）：窗口尺寸 = 卡片尺寸，卡片在窗口内定位于 `(0, 0)`，完全删除四周留白背景框；
  2. **窗口透明**：`src/index.css` 新增 `html, body, #root { background: transparent !important }`；`electron/main.cjs` `hasShadow: false`（Windows 透明窗口下系统阴影产生黑边）、移除 `backgroundColor`；`src/App.tsx` 桌面模式根 div `bg-transparent`；
  3. **卡片深色半透明底 + 毛玻璃**：桌面模式下标准卡片 `backgroundColor: 'rgba(15, 23, 42, 0.55)'`（slate-900 55% 不透明）+ `backdrop-blur-3xl`；药丸 `backgroundColor: 'rgba(2, 6, 23, 0.6)'`（slate-950 60% 不透明）+ `backdrop-blur-3xl`；深色半透明底保证主题色与文字可读性，backdrop-blur 保留毛玻璃质感；浏览器模式保持原 `bg-white/10` / `bg-slate-950/85` 不变；
- **验证**：`npm run desktop` 实测，窗口紧贴卡片无背景框，卡片深色毛玻璃效果，文字（Efficient/音标/释义/例句/同反义词）清晰可见，拖动/缩放正常；
- **阴影说明**：WINDOW_EDGE=0 后窗口紧贴卡片，卡片 `box-shadow` 外侧空间减小，阴影可能被轻微裁剪；当前效果可接受，后续如需完整阴影可恢复少量 WINDOW_EDGE（如 4-6px）或改用内阴影。

### [Fixed-历史] 桌面客户端透明窗口大黑框与卡片变白文字不可见（已回退，见上方 [Reverted]）
- **问题根因**：
  1. **大黑框**：`html/body/#root` 未设置透明背景，页面默认背景填充整个透明窗口；`hasShadow: true` 在 Windows 透明窗口上产生黑色边框阴影；
  2. **卡片变白文字不可见**：原卡片用 `bg-white/10`（白色 10% 半透明）+ `backdrop-filter: blur(3xl)` 毛玻璃效果，在浏览器里后面是深色壁纸所以看起来深色；但在 Electron 透明窗口下，`backdrop-filter` 无法模糊窗口外的桌面内容，白色 10% 叠加在透明上就变成了白色，白色文字在白色背景上完全不可见；
- **修复方案**：
  1. `src/index.css` 新增 `html, body, #root { background: transparent !important; }`，确保页面根背景完全透明；
  2. `electron/main.cjs` 将 `hasShadow: true` 改为 `false`（Windows 透明窗口下系统阴影产生黑边），阴影由卡片自身 CSS `box-shadow` 提供；
  3. 桌面模式下卡片采用**深色半透明底 + `backdrop-blur-3xl` 毛玻璃**模拟原效果：标准卡片 `rgba(15, 23, 42, 0.65)`（slate-900 65% 不透明），药丸 `rgba(2, 6, 23, 0.7)`（slate-950 70% 不透明）；`backdrop-filter` 模糊深色半透明底，呈现与原浏览器版一致的深色毛玻璃质感；
  4. **备选纯色主题**：不透明深色（标准 `#0f172a` / 药丸 `#020617`）作为备选主题保留在代码注释中，后续可在设置中增加主题切换供用户选择；
- **验证**：打包后 `Linguist.exe` 实测运行，卡片为深色毛玻璃效果，文字（Efficient/音标/释义/例句/同反义词）清晰可见，窗口周围无大黑框。

### [Docs] 文档实时同步
- `docs/CHANGELOG.md`：本文档（v1.4.0）；
- `docs/ARCHITECTURE.md`：新增第 3 节「桌面客户端架构（Electron）」；
- `docs/HANDOVER.md`：排障表新增「打包后 exe 启动即退出（MODULE_NOT_FOUND: vite）」「Electron 二进制下载慢」条目；
- `README.md`：项目架构目录新增 `electron/`，特性矩阵新增「桌面客户端」行，新增「桌面客户端运行与打包」章节。

---

## [v1.3.1] - 2026-09-03

### [Changed] 字体调节面板重构：滑条调节 + Portal 渲染根治遮挡 (Font Size Slider Panel)
- **调节方式升级**：字体大小与排版面板由「数字输入 + 预设」升级为「**滑条滑动** + 加减按钮 + 数字输入 + 快速预设」四重自由调节，自定义程度更高：
  - 滑条范围 60% ~ 150%、step 1，拖拽/点击实时联动整体字号，拖动过程所见即所得；
  - **整体缩放实现**：字号调节采用浏览器级 **`zoom`** 属性（`zoom: effectiveFontScale`）应用到卡片内容根容器，字体、间距、图标、圆角等**全部元素等比整体缩放**，效果等同浏览器放大缩小，彻底解决此前仅 `fontSize` 百分比对固定像素 Tailwind 文本类无效、拖动无反应的问题；
- **药丸模式译文滚动改为悬停滚动 + 移出平滑复位**：`MarqueeText`（药丸胶囊核心释义）由「溢出即自动循环滚动」改为「**默认静止，鼠标悬停时才滚动**」——改用 **JS 驱动 `transform`**（`requestAnimationFrame` 无缝循环推进，阅读节奏与原 CSS 动画同源）；**鼠标移出后以 `cubic-bezier(0.16,1,0.3,1)` 0.45s 平滑复位至原始位置（0 位）**，再移入从开头继续；同时清理不再使用的 `@keyframes marquee-scroll` 与 `.animate-marquee-scroll`；
  - 左右「− / +」按钮按 5% 步进微调，点击带 `active:scale-90` 按压反馈；
  - 当前值以大号等宽数字（`text-xl font-mono tabular-nums`）实时展示，并保留直接输入框（聚焦编辑 + 失焦自动钳制 60~150）；
  - 保留「紧凑 80% / 默认 92% / 标准 100% / 大字 115%」四档一键预设，选中态带蓝色高亮。
- **遮挡缺陷根治（Portal 渲染）**：
  - **修复问题**：原字体面板为卡片 header 内 `absolute top-full` 弹出层（`z-50`），受卡片层叠上下文与 `card-header-bar` 的 `overflow-hidden` 影响，面板会被渲染到视口顶部并被「使用指南」提示框遮挡，仅露出底部预设按钮；
  - **修复方案**：面板改用 React `createPortal` 渲染到 `document.body` 顶层，`position: fixed` 基于触发按钮视口坐标精确定位（右对齐按钮下方 8px，自动避让视口右/下边缘），`z-index: 999999` 恒为全局最顶层，任何情况下不被卡片、抽屉、「使用指南」等遮挡；
  - **影响范围**：`src/components/translator/FloatingTranslatorCard.tsx`（新增 `fontBtnRef` / `fontPanelPos` 定位逻辑 + Portal 面板）、`src/index.css`（新增 `.font-range` 滑条样式与 `.font-panel-enter` 入场动画）。
- **动画与动效**：
  - 面板入场：`font-panel-in`（fade + 上移 6px + scale 0.95→1），180ms `cubic-bezier(0.16, 1, 0.3, 1)` 丝滑曲线，锚点右上；
  - 滑条：自定义渐变轨道（蓝色已选段 + 微白未选段），白色圆形手柄带蓝色描边与光晕，hover 放大 + 光圈，拖动实时跟手。

### [Fixed] 滑条调节卡片内容无反应（固定像素类不随 fontSize 缩放）
- **修复问题**：v1.3.1 初版仍沿用旧版 `fontSize: effectiveFontScale * 100%` 方案，但标准卡片大量使用 Tailwind 固定像素文本类（`text-[9px]` / `text-xs` / `text-sm` 等），且 `WordDetailView` 虽接收 `effectiveFontScale` 却未实际应用，导致拖动滑条字号数字在变化、卡片内容却纹丝不动；
- **修复方案**：标准卡片内容容器与 minimal 容器改用 **`zoom`** 属性整体缩放（`src/components/translator/FloatingTranslatorCard.tsx` 两处 `style`），任何像素级尺寸均被等比缩放，实现浏览器放大缩小般的整体缩放体验。

### [Docs] 文档实时同步
- `docs/CHANGELOG.md`：本文档（v1.3.1）；
- `docs/HANDOVER.md`：排障表新增「字体调节面板被使用指南遮挡」条目；
- `docs/DESIGN_SYSTEM.md`：新增 6.7 字体调节面板与滑条规范、7 动效表补充面板/滑条动画行。

---

## [v1.3.0] - 2026-09-03

### [Added] 生词本独立持久化与历史完全解耦 (Independent Wordbook Persistence)
- **生词本独立存储**：
  - 启用长期已声明但未使用的本地存储键 `linguist_favorites`（`STORAGE_KEYS.FAVORITES`），生词本数据独立持久化，与翻译历史（`linguist_history`）彻底解耦；
  - 新增 `src/services/dataService.ts` 中的 `favoritesService`：提供 `loadFavorites` / `saveFavorites` / `clearFavorites` / `isFavoriteByText` / `toggleFavoriteByItem` 等完整生词本管理 API；
  - 以「原文（忽略大小写）」作为生词唯一身份标识，同一词条重复查询或重新翻译不会产生重复收藏；
  - 收藏快照完整保留词条详情（英美双音、词性释义、双语例句、同反义词），离线亦可完整回放。
- **清空历史不再误删生词本**：
  - 修复此前「收藏角标内嵌于历史记录、清空历史会连同生词本一起删除」的缺陷；
  - 历史抽屉「全部」Tab 的清空仅作用于历史列表，生词本 Tab 独立清空入口（`onClearFavorites`）互不影响；
  - 卡片收藏按钮、历史列表星标与生词本数据三方状态实时联动（`App.tsx` 的 `handleToggleFavorite`）。

### [Added] 历史 / 生词本数据导入导出与备份恢复 (Data Export & Import)
- **JSON 导出**：
  - 历史抽屉顶栏与偏好设置「数据与备份管理」区块均支持一键导出当前列表为本地 JSON 文件（带元信息包裹结构：`app` / `type` / `version` / `exportedAt` / `items`）；
  - 导出文件名自动携带日期（如 `linguist-favorites-2026-09-03.json`）。
- **JSON 导入**：
  - 支持从文件导入并自动分流：带「收藏标记」（`isFavorite: true`）的条目归入生词本，其余归入翻译历史；
  - 兼容包裹结构与裸数组两种格式，自动校验字段完整性并按「原文」去重，导入上限 50 条。
- **剪贴板复制**：历史抽屉提供「复制当前列表为 JSON」，偏好设置提供「复制生词本 JSON」，方便临时迁移与分享。
- **新增服务**：`src/services/dataService.ts` 中的 `dataExchangeService`（`exportToFile` / `copyToClipboard` / `importFromFile`）。

### [Added] 生词本双语一键发音 (Bilingual One-Click Pronunciation)
- 补齐 README 声明但此前缺失的「双语一键发音」能力：生词本每条目配备**原文发音**（蓝色图标）与**译文发音**（翡翠绿图标）两个独立触控靶标；
- 原文按 `sourceLang`、译文按 `targetLang` 调用 Web Speech 引擎，支持美音/英音/中文等自然发音；
- 历史 Tab 保持单语发音布局不变，生词本 Tab 自动启用双语发音模式。

### [Changed] 历史抽屉生词本 Tab 数据源切换为独立生词本
- 历史抽屉（`HistoryDrawer`）「生词本」Tab 从「历史记录中筛选 isFavorite」改为直接读取独立 `favorites` 列表，数据语义更准确、清空互不影响；
- 历史 Tab 条目星标高亮改为依据独立生词本匹配（按原文忽略大小写），与卡片收藏状态保持一致；
- 生词本条目底部补充展示翻译引擎标识（`engine`）。

### [Fixed] 历史抽屉 / 设置弹窗被置顶卡片遮挡 (Z-Index Layering)
- **修复问题**：悬浮卡片默认置顶（`isPinned` 默认 `true`，`z-index: 9999`），而历史抽屉与设置弹窗仅为 `z-50`，导致抽屉/弹窗打开时被卡片压在下方——重叠区域（如「生词本」Tab 按钮）的点击会误触到卡片的字号/截图按钮，视觉上卡片也未被遮罩变暗；
- **修复方案**：将 `HistoryDrawer` 与 `SettingsModal` 的容器层级由 `z-50` 提升为 `z-[10000]`（高于置顶卡片 9999），保证任何弹层永远浮于卡片之上；
- **影响范围**：`src/components/history/HistoryDrawer.tsx`、`src/components/settings/SettingsModal.tsx` 各一处容器 className；不涉及逻辑与数据流。

### [Docs] 文档实时同步
- `README.md`：新增「生词本独立化」「数据导入导出与备份」能力说明；
- `docs/CHANGELOG.md`：本文档（v1.3.0）；
- `docs/ARCHITECTURE.md`：新增前端服务层 `dataService` 的职责说明；
- `docs/HANDOVER.md`：更新目录拓扑（`src/services/dataService.ts`）、数据流向说明与排障手册、待办路线（生词本云端同步）；
- `docs/API.md`：补充数据导入导出的本地数据格式（Data Exchange Format）规范；
- `docs/DESIGN_SYSTEM.md`：补充数据管理按钮与双语发音靶标的组件规范。

---

## [v1.2.4] - 2026-09-03

### [Fixed] 悬浮翻译卡片拖拽与左上/右上交互区域优先级解耦 (Drag Precedence & Control Protection)
- **左上与右上工具区域点击绝不触发窗口移动**：
  - 在 `FloatingTranslatorCard` 中建立严格的交互层级与几何范围优先级机制，杜绝点击左上（红绿灯、清空、药丸收起、刷新）及右上（截图翻译、固定置顶、字号微调胶囊及浮层、偏好设置）功能按钮时产生的意外移动；
  - 扩展 `handleMouseDown` 过滤逻辑，多维侦测 `button`、`input`、`textarea`、`select`、`[role="button"]`、`.no-drag`、`.resize-handle`、`.top-left-zone`、`.top-right-zone`、`.top-left-sensor`、`.top-right-sensor`、`.font-popover-container` 等所有交互载体；
  - 引入几何坐标保底机制：对顶栏左上（卡片左边缘 68px 范围内）与右上（卡片右边缘 95~145px 范围内）操作集群赋予绝对交互优先级，即使点击在按钮间隙或微小内边距上也坚决不启动移动；
  - 提升移动判定阈值从 4px 至 7px，从底层过滤快速点击或触控板按压时的微小光学抖动。
- **左上与右上角缩放手柄（NW / NE）交互修复**：
  - 将四个边角拉伸手柄（NW、NE、SW、SE）的 `z-index` 从被顶栏遮挡的 `z-20` 提升至顶层 `z-50`，并将交互热区扩展至 24px×24px（`w-6 h-6`）；
  - 缩放手柄点击时主动清除待机拖拽状态并阻断冒泡，解决用户尝试拉伸左上角或右上角时因顶栏层级覆盖而误判为拖拽卡片的缺陷。
- **极简模式与药丸模式同步强化**：
  - 极简卡片模式（Minimal Mode）的左上角与右上角感知传感器（Sensor）及展开胶囊全面绑定 `onMouseDown={(e) => e.stopPropagation()}`，并标记 `.no-drag`；
  - 药丸模式（Pill Mode）两侧展开感知区与控制集全面接入优先级阻断，保证胶囊交互与拖拽平稳共存。

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
