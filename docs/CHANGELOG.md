# Linguist 桌面版更新日志

本项目严格遵循 [Semantic Versioning 2.0.0](https://semver.org/lang/zh-CN/) 语义化版本规范。

---

## [Unreleased] - 开发中

### 2026-09-12 — 任务栏最小化与药丸边缘悬浮

- [Docs] Windows 发布目录同时携带版本说明与全局验证记录，安装后可直接查看交付范围和验证边界。
- [Fixed] `WindowsResizeSession.*`：鼠标按下直接使用消息自带的窗口内坐标做八向边框命中，消除全局指针采样延迟把普通按钮误判为缩放的竞态；悬浮光标仍按真实全局位置更新。
- [Fixed] `TranslatorWindow.*`、`Main.qml`：公开实际原生窗口矩形供外置页面排版面板定位，避免自绘窗口经 `UpdateLayeredWindow` 移动后 Qt 逻辑坐标滞留导致面板漂移。
- [Fixed] `TranslationManager.*`：降级引擎的失败重试绑定当前实际 Provider，不再回跳并重试最初的首选引擎。
- [Fixed] `MusicIslandCard.qml`、`tst_toolbar.qml`：唱片旋转回归改为检查动画器运行状态，移除离屏渲染线程取样造成的偶发失败；完整 QML 套件 144 项全部通过。
- [Docs] `docs/VALIDATION.md`：新增全局功能矩阵、已修复逻辑错误以及需要真实媒体/密钥/桌面环境确认的边界。
- [Changed] `Main.qml`、`LayoutScalePanel.qml`：页面排版面板改为以卡片水平中心为锚点，固定在底边下方 2px；独立窗口在显示期间以 16ms 节奏校准位置，原生移动和缩放期间持续跟随，切回药丸时自动收起。
- [Fixed] `TranslatorWindow.*`：离屏 `QQuickRenderControl` 显式返回真实主窗口作为渲染宿主，主窗口同步暴露 QML 当前焦点对象并刷新输入法查询，恢复 Windows 中文输入法的预编辑、候选窗定位和中文提交。
- [Fixed] `WindowsResizeSession.*`：原生输入处理同时注册 Qt 全局原生事件过滤器，并在窗口显示后重新确认挂接；即使 Qt 在首次显示时替换 HWND 窗口过程，药丸展开、搜索和功能按钮仍能收到真实点击。
- [Fixed] `AppState.*`、`TranslationManager.*`、`GeminiProvider.*`、`DeepLProvider.*`、`YoudaoProvider.*`：语言选择和交换统一触发重译；相同语言自动形成有效方向；所有异步请求加入当前请求隔离，迟到结果、重试和旧引擎结果不能覆盖新语言；仅在目标为中文时用 ECDICT 补中文词典字段。
- [Added] `installer/Linguist.iss`、`scripts/package_windows.ps1`、`resources/app.ico`：新增用户级 Windows 安装包、开始菜单/可选桌面快捷方式、完整卸载、Qt 运行库收集、正式快捷方式图标与 SHA-256 输出。
- [Docs] `README.md`、`docs/RELEASE.md`、`docs/API.md`、`docs/ARCHITECTURE.md`、`docs/DESIGN_SYSTEM.md`、`docs/WINDOW_UI_REBUILD.md`：同步中文输入、语言请求一致性、附着面板、当前 MinGW 构建与安装发布流程。
- [Changed] `Main.qml`：页面排版工具窗固定贴在主卡片底边下方 2px，主卡片移动或缩放时逐帧重算锚点；关闭工具窗自身的拖动区域，避免面板与所属卡片分离。
- [Added] `LanguageSelector.qml`、`CardView.qml`、`AppState.cpp`：语言胶囊加入液态玻璃多语言选择列表，源语言支持自动检测，目标语言支持简中、英、日、韩、法、德、西、葡、意、俄、阿、越、泰；选择后对已有文本立即重新翻译。
- [Fixed] `LanguageSelector.qml`：语言列表收紧为 148px 宽、五行可见高度，并按语言胶囊在窗口中的实时坐标限制到卡片边界内；支持滚轮、触控板和拖动滚动，列表打开期间顶部语言选择保持展开，不再发生左侧文字裁切或状态回缩。
- [Changed] `LanguageSelector.qml`、`CardView.qml`：顶部语言胶囊统一改为 `AUTO / ZH / EN / JA` 等英文标识；右侧功能按钮从连续裁切淡出改为按 26px 完整槽位显隐，任何被遮挡的按钮都整颗隐藏。
- [Fixed] `CardView.qml`、`tst_card.qml`：恢复右侧操作区原有 reveal 计算、宽度动画、悬浮展开和逐项吸入逻辑；完整按钮继续显示，仅在单枚图标处于部分裁切阶段时隐藏该图标。
- [Changed] `CardView.qml`、`tst_card.qml`：空状态提示改为较小的“开始翻译 / 输入文字，或直接划词”，减少大字号口号感并保持静止、居中和低对比层级。
- [Fixed] `FallbackProvider.cpp`、`YoudaoProvider.cpp`：免密翻译兜底不再把 `auto` 固定解释为英语，先按文字脚本和常见词做本地语言判断；有道简体中文代码统一映射为接口要求的 `zh-CHS`。
- [Added] `PillView.qml`、`tst_narrow.qml`：药丸音乐界面补充“上一首”按钮，接通既有 Windows 系统媒体上一曲命令，并与播放、下一首保持相同反馈和空间收缩规则。
- [Fixed] 验证：Qt 6.11.2 / MinGW 完整构建通过；多语言英文标识、紧凑列表、单枚裁切图标隐藏与药丸上一首新增检查通过。通用 QML 套件 143 项通过，仅离屏唱片旋转保留 1 项既有计时偶发失败，本轮未修改对应逻辑。
- [Changed] `ScreenshotTranslationView.qml`、`ScreenshotPreview.qml`、`Main.qml`：截图结果的中英行距收紧为正常正文节奏；原图默认以不超过 82px 的小型缩略图显示在正文上方，眼睛按钮控制显隐，点击缩略图打开独立液态玻璃大图预览。
- [Fixed] `AppState.cpp`：截图 OCR 与历史截图恢复不再写入普通搜索原文和译文，退出截图模式后保留原搜索内容，避免识别文字出现在搜索框。
- [Changed] `IOcrProvider.h`、`OcrManager.*`、`WindowsOcrProvider.*`、`SystemOcrBridge.ps1`：OCR 调用传递当前源语言，Windows 桥优先创建对应识别语言引擎，并在系统最大图像尺寸内对小字号截图做最多 3 倍高质量放大。
- [Fixed] `test_windows_ocr_bridge.py`、`tst_card.qml`：增加深色小字号英文截图、紧凑双语间距、缩略图显隐与放大请求、搜索状态隔离回归检查；小字号 OCR 样例已通过。
- [Changed] `CardView.qml`、`tst_card.qml`：语言选择与引擎状态改为在红绿灯外框右沿和右侧图标区域左沿之间实时居中，缩放及图标逐步隐藏期间持续按两侧边界更新；压缩状态框由 18×22px 收紧为 14×14px。新增 160–480px 连续宽度间隔居中回归检查。
- [Changed] `WindowsResizeSession.*`：卡片原生外壳由普通圆弧升级为 2.6 阶连续曲率轮廓，采样在四角两端自适应加密并保持物理像素对齐；底色、裁剪、细边框、流光与缩放反馈共享同一路径，四角在静止和缩放时更柔顺且完全对称。药丸继续使用标准半圆胶囊轮廓。
- [Changed] `CardView.qml`、`LanguageSelector.qml`：最小与正常卡片复用同一个红绿灯磨砂外框；最小卡片未展开时，左右触发带收紧到顶部 18px，展开后恢复完整操作高度。语言选择与引擎状态统一为 22px 高、9px 字号。
- [Fixed] `CardView.qml`、`tst_card.qml`：顶部四个功能按钮收紧为 24×24px，确保相邻命中框不重叠，避免点击截图翻译时误触置顶；右侧按钮下移靠近分隔线，分隔线到搜索框的既有 5px 间距保持不变。新增顶部触发带、控件等高与命中区隔离检查，本轮 139 项 QML 检查通过。
- [Changed] `CardView.qml`、`SearchInput.qml`：最小卡片左右控件展开时不再隐藏搜索框，改为保留低对比磨砂轮廓并弱化文字；最小搜索框收紧为 24px 高、11px 字号。搜索框聚焦期间暂停角落展开，避免编辑内容被覆盖。
- [Changed] `CardView.qml`：顶部统一为 44px，右侧 28px 图标距顶部 5px、距长分隔线 5px，分隔线到搜索框再留 5px；最小卡片使用 34px 顶部和 24px 搜索框，保持上下各 5px。
- [Fixed] `CardView.qml`、`tst_card.qml`：移除空状态提示持续 3.8 秒循环的透明度与位移动画，只保留首次出现的 700ms 淡入上移，提示稳定后完全静止。
- [Fixed] `WindowsResizeSession.*`、`probe_cursor_zones.py`：原生缩放光标离开边缘后主动恢复默认箭头，修复最后一次尺寸光标残留并覆盖整个正文的问题；四角命中区按窗口短边收敛，药丸左右中段恢复单轴缩放光标。新增真实窗口“左边缘→正文中心”光标探针。
- [Changed] `CardView.qml`、`TrafficLights.qml`：最小卡片左右展开区统一为 24px 高、12px 圆角的轻薄磨砂承载层；搜索框顶部改为 5px，后续进一步收紧为 24px 高并保留弱化磨砂轮廓。
- [Changed] `CardView.qml`：普通卡片分隔线恢复长细线，仅保留左右各 5px 的圆角安全距离；顶部控件到分隔线、分隔线到搜索框均保持 5px 间距，紧凑标题栏提高到 44px 以避开透明圆角。
- [Changed] `CardView.qml`、`TrafficLights.qml`：普通卡片右侧功能区恢复无外框图标排版；轻薄磨砂胶囊只在最小卡片右上角展开时出现。顶部分隔线缩短并在两端淡出，搜索框上下留白收紧；卡片红绿灯常态磨砂进一步降低不透明度。
- [Fixed] `CardView.qml`：最小卡片未展开角落控件时将顶部命中层交给搜索框，修复透明拖动标题层截获点击、输入框无法获得光标的问题；角落控件展开后仍可按原设计覆盖搜索框。
- [Changed] `TrafficLights.qml`、`CardView.qml`：卡片红绿灯改为 27×14px、5px 灯点的轻量磨砂常态，悬浮后恢复到原 34×18px、7px 灯点；右侧功能按钮加入独立磨砂胶囊背景，避免与搜索框视觉混合。
- [Changed] `SearchInput.qml`、`PillView.qml`、`CardView.qml`：移除搜索框顶部单独的白色直线高光；普通卡片顶部控制、分隔线与搜索框之间增加分层留白。
- [Changed] `LayoutScalePanel.qml`、`Main.qml`：页面比例面板收紧为 212×76px，重排标题、比例徽标和缩放控件；窗口显示后按文字排版按钮的屏幕坐标二次定位，空间不足时先上移主卡片并继续从按钮下方打开。
- [Fixed] `tst_card.qml`：新增最小卡片输入焦点、顶部组独立磨砂容器、红绿灯尺寸与分隔线留白检查；本轮 QML 套件 138 项通过，仅保留 1 项既有的离屏唱片旋转时间取样偶发失败。
- [Changed] `CardView.qml`：最小卡片搜索框不再为隐藏标题栏预留高度，最终固定距窗口顶部 5px；左上和右上控件继续作为高层覆盖内容。
- [Fixed] `CardView.qml`、`Main.qml`：紧凑译文显式依赖 `translatedText/definitions` 变化，修复原生 `Q_INVOKABLE` 返回值无法触发 QML 重新求值而导致最小卡片译文不出现；最小状态取消结果淡入等待，结果直接显示。
- [Changed] `LayoutScalePanel.qml`、`Main.qml`、`CMakeLists.txt`：页面排版控件迁入卡片边框外的独立 220×84px 液态玻璃小窗，固定在主卡片下方；屏幕空间不足时先上移主卡片，保证面板仍从下方打开。
- [Changed] `CardView.qml`、`Main.qml`：左上、右上和普通卡片最右侧统一增加 110ms 悬浮意图延迟，再以 190–210ms `OutQuart` 容器展开和 140–150ms `OutCubic` 渐显完成过渡。
- [Fixed] `Main.qml`、`tst_card.qml`：用户已缩至最小的卡片不再被翻译结果触发自动放大，译文直接在当前卡片显示；新增悬浮延迟、向下排版抽屉和最小卡片翻译留驻检查，完整 QML 套件 136 项通过。
- [Changed] `SearchInput.qml`、`CardView.qml`：卡片搜索框统一为药丸同款 26px 高、13px 半径的液态玻璃胶囊，保留卡片可用横向长度；最小卡片搜索框固定距顶部 8px。
- [Fixed] `CardView.qml`、`Main.qml`：最小卡片左上角和右上角新增原生坐标感应区，分别揭示红绿灯与完整功能组；普通窄卡片的最右侧感应区也不再依赖已显示图标，修复隐藏后无法展开。
- [Changed] `CardView.qml`：底部左侧开关与边框至少保持 12px 间距；“文字大小”面板升级为“页面排版”，联动正文、搜索字号、主间距及工具栏密度。
- [Added] `DatabaseManager.*`、`AppState.*`、`HistoryView.qml`：截图翻译完成后持久化原文、逐行译文、记录类型和预览地址；历史窗口增加截图筛选与类型标识，点击记录恢复原卡片逐行对照。
- [Fixed] `tst_card.qml`：新增卡片搜索样式、最小卡片双侧揭示区与底部安全间距回归；完整 QML 套件 135 项通过，仅音乐唱片离屏取样仍有 1 项既有偶发失败。
- [Changed] `PillView.qml`：最小药丸搜索入口从左侧 22px 开始，避开 16px 红绿灯揭示区；空入口改为冷蓝透明底、内层渐变高光、精细描边和居中搜索图标的液态玻璃按钮。
- [Fixed] `PillView.qml`、`SearchInput.qml`：点击窗口其他区域或切换到其他应用后，药丸搜索立即失焦并收回；最小状态停止呼吸并进入流光消散。药丸与卡片输入光标统一为自然亮灭循环。
- [Changed] `CardView.qml`：顶部右侧图标移除额外缩放，改用药丸一致的 100ms `OutCubic` 渐显和共享的按钮点击回弹反馈。
- [Fixed] `tst_narrow.qml`、`tst_card.qml`：覆盖搜索入口与左侧热区间距、液态玻璃层、外部失焦收回、流光停止、双模式光标闪烁和卡片图标动画一致性；相关回归检查通过。
- [Changed] `PillView.qml`、`Main.qml`：药丸搜索入口移除悬浮展开，只在点击后展开并获得输入焦点；无文字时回到 26px 最小入口，有文字时按字体测量在 46–108px 内分配宽度。
- [Changed] `PillView.qml`、`Main.qml`、`WindowsResizeSession.cpp`：药丸搜索聚焦复用卡片的 700ms 唤醒、3.8s 呼吸与 850ms 消散流光生命周期，原生药丸外壳同步合成内向柔光和精细光谱边线。
- [Fixed] `tst_narrow.qml`：新增“悬浮不展开”、点击聚焦流光及空输入失焦收回检查，避免搜索悬浮与最小药丸左侧红绿灯热区争用状态。
- [Refactored] `TranslatorWindow.*`、`WindowResizeSession.h`、`WindowsResizeSession.*`、`Application.cpp`：黄色交通灯改为完整的原生最小化状态机；最小化前停止尺寸动画、缩放捕获和待提交绘制，Windows Platform 使用 `SW_MINIMIZE`，最小化期间拒绝 `UpdateLayeredWindow`，托盘显示统一走恢复入口。
- [Fixed] `PillView.qml`：原生鼠标坐标在离屏 QML 指针分发后最终确认左右边缘状态；有隐藏操作时悬浮最右 32px 稳定展开全部图标，160–220px 最小药丸悬浮最左 16px 稳定显示红绿灯。
- [Fixed] `tst_narrow.qml`：新增最小药丸左边缘红绿灯回归检查，并固定右边缘展开夹具的数据条件；真实 Windows 探针连续观察 4 秒确认窗口持续处于任务栏最小化状态。

### 2026-09-11 — 药丸与卡片切换动效

- [Fixed] `WindowsResizeSession.*`：主窗口原生扩展样式显式启用 `WS_EX_APPWINDOW` 并移除工具窗标记，黄色交通灯最小化后保留可靠的 Windows 任务栏入口。
- [Changed] `CardView.qml`、`Main.qml`、`TranslatorWindow.*`：丰富词典或较多截图内容统一自动展开为 350×420px，替代原 500px 大卡片；空内容与简短结果仍使用 220×200px。
- [Changed] `CardView.qml`：顶部保持即时拖动；空白正文、内容未溢出的正文及外围空白支持 280ms 长按移动，搜索框、功能按钮和可滚动长内容保持原交互。
- [Fixed] `TranslatorWindow.*`、`WindowResizeSession.h`、`WindowsResizeSession.*`：分层窗口原生鼠标链路同步八方向缩放光标，边缘命中带扩大到 10 逻辑像素；悬浮与拖动显示柔和蓝色轮廓反馈，拖动继续使用鼠标捕获直到松开。
- [Fixed] `tst_card.qml`：新增 350×420 丰富内容尺寸和空白正文长按移动检查；完整 QML 套件本轮 126 项通过，右侧悬浮与唱片离屏时间取样仍各有 1 项既有偶发失败。
- [Fixed] `check_desktop_ui.py`：可见窗口检查增加最多 3 秒的启动就绪等待，避免离线词典初始化稍慢时把尚未设置标题误判为启动失败。
- [Fixed] `AppState.*`、`Application.cpp`、`TranslatorWindow.*`：清空搜索原文后同时重置卡片记忆尺寸，并以 180ms 动画恢复 220×200px 初始小卡片；后续自适应高度更新复用已重置宽度，不再停在拉宽后的空卡片。
- [Fixed] `PillView.qml`、`Main.qml`、`tst_narrow.qml`：药丸黄色交通灯改为请求系统任务栏最小化，不再错误展开为卡片；新增信号链路回归检查。
- [Changed] `CardView.qml`、`AuroraBorder.qml`：彩色边缘从点击搜索框获得焦点的瞬间开始，以 10% 初始能量立即响应；输入期间保持柔和活动，提交翻译后提升强度，失焦且翻译结束后才消散。
- [Refactored] `WindowsResizeSession.*`：彩色边缘改为缓存的逐像素圆角距离光场；柔和低饱和色谱使用平滑插值，透明度按高斯与指数曲线向卡片中心衰减，彻底移除短线圆头拼接造成的颗粒、色块和生硬彩虹环。
- [Changed] `AuroraBorder.qml`：光谱完整漂移周期由 7.6s 放缓至 14.8s，保留 3.8s 呼吸节奏；聚焦态与翻译态使用不同呼吸深度。
- [Added] `AuroraBorder.qml`、`TranslatorWindow.*`、`WindowResizeSession.h`、`WindowsResizeSession.cpp`：翻译期间加入 Apple Intelligence 风格的蓝、紫、粉、金、绿流动边缘；原生外壳使用 1.5px 内侧精细描边和约 20px 内向柔光，正文中央保持完全清透。
- [Changed] `AuroraBorder.qml`：QML 只管理 700ms 晨曦唤醒、3.8s 呼吸循环和 850ms 暮光消散；Platform 在既有 GDI+ 整帧外壳中绘制光环，消散完成后停止旋转与提交，避免软件场景纹理破坏透明窗口。
- [Changed] `CardView.qml`：空状态提示改为正文页面水平与垂直居中，加入 700ms 淡入上浮和 3.8s 低幅呼吸动效。
- [Fixed] `tst_card.qml`：新增提示居中、提示呼吸、彩色边缘唤醒/呼吸/消散生命周期检查；完整构建与真实分层窗口强制视觉状态检查通过。
- [Changed] `TranslatorWindow.*`、`CardView.qml`：默认空卡片由 380×260px 收紧为 220×200px；丰富结果仍可按内容展开至 500px，并保留用户手动拉伸后的独立卡片尺寸。
- [Changed] `TrafficLights.qml`、`CardView.qml`：卡片红绿灯使用 34×18px 空闲外框与 7px 灯点，悬浮后平滑恢复可操作尺寸；固定预留 40–44px 区域，使其与语言选择器保持间距。
- [Changed] `Main.qml`：点击卡片音乐图标会收起卡片并直接进入药丸音乐模式；药丸唱片点击仍打开多行歌词面板。
- [Fixed] `SearchInput.qml`、`CardView.qml`：搜索框聚焦时光标正常闪烁，点击卡片搜索框外的正文、顶部或底部会立即退出编辑焦点。
- [Changed] `CardView.qml`：翻译等待改为无文字的三色轻波动；结果返回后使用 180ms 淡入与 220ms、7px 上移归位，避免内容突然出现。
- [Changed] `CardView.qml`、`SearchInput.qml`、`PillView.qml`：空状态精简为“所见，即所译”和“输入、粘贴，或直接划取文字”，输入框与药丸提示同步减少说明感。
- [Fixed] `tst_card.qml`：新增卡片翻译等待、结果入场和搜索失焦检查，并将尺寸及红绿灯断言同步到紧凑布局；通用 QML 套件本轮 123 项通过，右侧悬浮与唱片离屏时间取样仍各有 1 项既有偶发失败。
- [Fixed] `PillView.qml`：移除药丸宽于 440px 时禁用搜索点击的错误限制，任意用户拉伸宽度下都能点开输入框并键入内容。
- [Changed] `SearchInput.qml`、`PillView.qml`、`CardView.qml`：卡片和药丸输入焦点增加清晰的蓝色描边与光标；空状态文案最终统一为“所见，即所译”和简短的输入提示。
- [Fixed] `TranslatorWindow.cpp`：自绘窗口点击搜索区域时重新确认原生窗口激活，再把焦点交给离屏 QML 输入框，提升首次点击及中文输入法的可靠性。
- [Fixed] `tst_narrow.qml`：新增 480px 宽药丸点击、获得焦点与键盘输入回归用例；该用例修复前稳定失败、修复后通过。
- [Fixed] `AppState.cpp`、`SearchInput.qml`、`PillView.qml`：划词文本统一经 `setSourceText()` 写入状态，卡片与药丸搜索框立即同步显示；药丸无需等待译文返回即可展示划词原文。
- [Changed] `AppState::clearText()`：清空原文时同步清除译文、音标、释义、例句、同反义词、词形、错误与加载状态，迟到的空源翻译结果不会重新填回界面。
- [Changed] `PillView.qml`：搜索原文为空时退出编辑并以 150ms 动画收回 26px 最小搜索入口；卡片搜索清除按钮改走统一清理入口。
- [Fixed] `SearchInput.qml`：输入框不再从内部反向覆盖外部文本绑定，解决划词后仍残留上一次手输内容；截图按钮不再同时误触发划词复制流程。
- [Changed] `AppState.cpp`：移除启动时写死的 “Efficient” 演示原文、译文、音标和释义，程序从真实空状态启动，药丸搜索入口默认保持最小。
- [Fixed] 实机验证：Windows 全局划词后，原文会立即出现在药丸搜索区域并正常返回译文；清空后结果不回弹，重新启动保持 26px 最小搜索入口，窗口持续正常响应。
- [Fixed] `tst_card.qml`、`tst_narrow.qml`：覆盖外部划词同步、卡片清除结果、翻译期间药丸显示原文及空药丸自动最小化；通用 QML 套件 122 项通过，唱片旋转离屏时间取样仍有 1 项既有偶发失败。
- [Changed] `CardView.qml`、`Main.qml`、`TranslatorWindow.cpp`：卡片改为内容驱动的两档高度；无数据与短释义使用 260px 紧凑卡片，包含例句、同反义词、词形或较多截图行时平滑展开到 500px 大卡片，保留用户当前宽度。
- [Fixed] `TranslatorWindow.cpp`：自适应高度动画直接复用 QWindow 逻辑宽度，避免 125% 等分数 DPI 下重复换算造成卡片横向缩窄。
- [Fixed] 实机验证：125% DPI 下短结果为 260px、五组截图翻译为 500px，切换前后物理宽度均为 475px；窗口保持响应且正文与底栏正常显示。
- [Fixed] `tst_card.qml`：新增空内容、短词典结果和丰富词典结果的自适应高度回归检查；通用 QML 套件 119 项通过，唱片旋转的离屏时间取样仍有 1 项既有偶发失败。
- [Docs] `README.md`、`docs/ARCHITECTURE.md`、`docs/DESIGN_SYSTEM.md`：同步卡片尺寸状态、判定依据与动画边界。
- [Changed] `AppState.*`：截图翻译改用独立 TranslationManager 按 OCR 行顺序逐条翻译并渐进回填，保证每条原文紧跟自己的中文译文，不再依赖整段译文的换行数量。
- [Changed] `ScreenshotTranslationView.qml`：对齐参考图改为连续阅读排版；英文使用较粗白字，下一行中文使用灰白字，移除序号、卡片框和彩色分隔线。
- [Fixed] `ScreenshotTranslationView.qml`：双语文本宽度明确跟随卡片正文，在窄卡片中按可用宽度换行，不再被长句固有宽度撑开后从右侧裁掉。
- [Changed] `Main.qml`、`CardView.qml`、`ScreenshotTranslationView.qml`：截图结果不再创建额外工具窗口；框选结束后复用现有 TranslatorWindow 并展开为卡片，在原正文区域按原文一行、译文一行连续显示。
- [Changed] `AppState.*`：新增 `screenshotMode` 与退出方法，截图识别、翻译、失败和完成均保持在同一卡片状态；重新框选继续复用该卡片。
- [Fixed] `tst_card.qml`：验证截图状态隐藏普通搜索/结果并在同一个 CardView 正文中显示双语对照。
- [Docs] `README.md`、`docs/ARCHITECTURE.md`、`docs/API.md`、`docs/DESIGN_SYSTEM.md`：将截图结果交互修正为现有卡片内展示。
- [Fixed] `Application.cpp`：截图开始时隐藏主卡片不再触发 Qt“最后窗口关闭”退出，托盘进程会在主卡片与框选层交接期间保持运行。
- [Added] `ScreenCaptureOverlay.qml`、`CaptureManager.cpp`：加入当前鼠标所在屏幕的真实截图、全屏暗色框选层、选区裁剪、Escape 取消与原图预览。
- [Added] `WindowsOcrProvider.cpp`、`SystemOcrBridge.ps1`：通过 Windows 内置 `Windows.Media.Ocr` 异步识别选区，不要求额外安装 OCR 模型。
- [Changed] `AppState.cpp`、`ScreenshotTranslationView.qml`：截图文字接入当前翻译引擎，显示“识别中/翻译中/失败/完成”状态；删除会伪装成功的演示数据。
- [Fixed] `Application.cpp`、`Main.qml`：卡片、药丸、托盘和 `Ctrl+Shift+S` 统一进入截图流程，重新截图不再误触发划词翻译。
- [Added] `test_windows_ocr_bridge.py`、`probe_screenshot_entry.py`：分别验证真实 Windows OCR 结果和快捷键打开/取消选区层的窗口生命周期。
- [Fixed] 验证：Qt/MinGW 完整构建通过；生成图片的 Windows OCR 集成检查通过；真实进程框选后恢复现有翻译卡片且未创建第二个结果窗口。通用 QML 套件 118 项通过，唱片旋转的离屏时间取样检查仍有 1 项既有偶发失败，与截图链路无关。
- [Docs] `README.md`、`docs/ARCHITECTURE.md`、`docs/API.md`、`docs/DESIGN_SYSTEM.md`：同步真实截图翻译能力、边界和交互规范。
- [Changed] `MediaSessionService.cpp`：同步歌词切换点统一提前 650ms，让药丸和音乐卡片先显示下一句、随后接近人声开唱；普通无时间戳歌词保持原行为。
- [Docs] `docs/API.md`、`docs/DESIGN_SYSTEM.md`：记录歌词预读偏移及适用边界。
- [Added] `SystemMediaBridge.ps1`、`WindowsMediaManager.*`、`MediaSessionService.*`：读取 GSMTC 媒体缩略图并转换为圆形 PNG 数据源；药丸与音乐卡片使用真实封面旋转，静止外环实时绘制播放进度。
- [Added] `ILyricsProvider.h`、`LrclibLyricsProvider.*`：新增可替换歌词 Provider 接口和 LRCLIB 实现，按歌名、歌手、专辑及可用时长顺序请求同步歌词，精确匹配失败后延迟 300ms 搜索回退，并缓存当前会话结果。
- [Changed] `PillView.qml`：音乐药丸第一行合并显示歌名与歌手，第二行显示当前歌词；封面唱片、音柱和歌词跟随真实播放状态。
- [Changed] `MusicIslandCard.qml`：歌词区改为可使用鼠标滚轮、触控板及拖动浏览的多行列表，同步歌词自动居中当前行并用绿色强调；封面外环和时间轴共享同一进度。
- [Changed] `MediaSessionService.*`：播放器公开 GSMTC 时间轴时使用系统位置；未公开时间轴时采用歌词匹配时长，并从检测到曲目后本地递增，以维持歌词与进度反馈。
- [Fixed] `tests/qml/tst_toolbar.qml`、`tests/qml/tst_narrow.qml`、`tests/qml/tst_card.qml`：覆盖多行歌词模型、当前行、滚动能力、封面旋转和进度环比例；117 项 QML 回归检查通过。
- [Docs] `README.md`、`docs/API.md`、`docs/ARCHITECTURE.md`、`docs/DESIGN_SYSTEM.md`：同步媒体封面、进度环、歌词 Provider、联网边界和时间轴降级规则。
- [Fixed] `HoverScrollText.qml`、`PillView.qml`：药丸核心结果强制将词性与第一条重要释义放在同一行，窄宽度仅裁切或悬浮滚动，不再上下分行。
- [Fixed] `MediaSessionService.*`、`WindowsMediaManager.*`、`SystemMediaBridge.ps1`、`AppState.*`、`Application.*`：删除写死的演示歌单和伪连接状态，接入 Windows GSMTC 当前媒体会话，实时同步播放器连接、播放状态、歌曲、歌手、专辑和可用进度，并把播放暂停、上下曲与进度操作转发给当前系统播放器。
- [Changed] `MusicIslandCard.qml`：未连接、播放和暂停状态使用真实媒体状态；播放器未提供时间轴时显示不可用进度，不再伪造 180 秒进度或演示歌词。
- [Fixed] `tests/qml/tst_narrow.qml`：增加词性与核心释义单行垂直对齐回归检查；桌面构建与 116 项 QML 回归检查通过。
- [Docs] `README.md`、`docs/API.md`、`docs/ARCHITECTURE.md`、`docs/DESIGN_SYSTEM.md`：同步真实系统媒体桥接边界、界面降级状态和药丸单行释义规范。
- [Changed] `PillView.qml`：右侧完整操作组展开时，普通宽度药丸继续保留红绿灯及安全间距；最小药丸仍遵循左边缘悬浮显示规则。
- [Changed] `PillView.qml`：翻译等待状态移除“翻译中”文字，改为蓝、紫、绿色三点波浪动效；结果返回后立即切换为词性与核心释义。
- [Changed] `IconButton.qml`：所有图标操作增加即时按压、回弹和 280ms 蓝色执行环反馈；复制进一步使用 `justCopied` 业务状态显示完成反馈，无有效内容的复制与朗读入口明确禁用。
- [Fixed] `PillView.qml`、`Main.qml`：药丸“截图翻译”从误接的划词复制流程改为发出 `screenshotRequested` 并打开独立截图窗口。
- [Fixed] `tests/qml/tst_narrow.qml`、`tests/qml/tst_toolbar.qml`：逐项验证复制、截图、音乐、设置、朗读与展开入口，覆盖加载动效运行、红绿灯在右侧展开时保留及图标执行反馈。
- [Docs] `README.md`、`docs/ARCHITECTURE.md`：明确截图入口已接通，但框选捕获、OCR Provider 与真实逐行翻译尚未完成，演示数据不作为功能可用证据。
- [Changed] `TrafficLights.qml`、`PillView.qml`：药丸红绿灯外框由静止 34×18px 随悬浮平滑放大到 44×22px，正文左边距跟随实际外框宽度让位，静止时释放横向空间。
- [Changed] `PillView.qml`：搜索框使用实际字体测量按当前单词长度在 46–108px 内分配宽度；编辑状态同样随输入增长，长词到达正常搜索框上限后改用局部悬浮滚动。
- [Changed] `PillView.qml`：药丸只展示第一条核心释义，词性使用主题蓝、正文使用主文本色；译文按测量宽度优先占位，右侧次要操作按剩余空间逐项收起，悬浮真实最右侧后完整展开并推动搜索和译文让位。
- [Fixed] `tests/qml/tst_narrow.qml`：增加红绿灯外框整体缩放、单词驱动搜索宽度上限、核心释义裁剪与词性颜色、内容优先隐藏操作的回归验证。
- [Fixed] `PillView.qml`、`HoverScrollText.qml`、`TrafficLights.qml`、`TranslatorWindow.cpp`：增加窗口级指针状态；原生离开事件直接关闭搜索/右侧展开并禁用滚动与悬浮动画，解决离屏 HoverHandler 未及时复位的问题。
- [Changed] `PillView.qml`：搜索获得焦点后自动全选当前原词，直接键入即可替换并回车翻译。
- [Fixed] `Main.qml`、`PillView.qml`、`TranslatorWindow.cpp`：每个真实鼠标移动都同步窗口级指针状态，并由药丸直接计算最右 32px 命中；搜索预览必须同时满足“指针仍在窗口内”，消除 Qt 离屏悬浮残留导致的假展开。
- [Fixed] `Main.qml`、`PillView.qml`、`TranslatorWindow.cpp`：药丸搜索加入原生点击前焦点准备，分层窗口收到点击时直接定位搜索框并激活编辑器，修复只能展开却无法稳定输入和回车提交的问题。
- [Fixed] `WindowsResizeSession.cpp`、`WindowsResizeSession.h`、`TranslatorWindow.cpp`：Windows 原生层开始跟踪并转发 `WM_MOUSELEAVE`，鼠标离开窗口后清除所有 QML 悬浮状态，译文滚动、搜索展开和右侧操作不会继续滞留。
- [Changed] `PillView.qml`、`TrafficLights.qml`：最右展开热区改为贴边 32×30px 悬浮点击区；药丸红绿灯静止为 7px 小点，悬浮后以 140ms 展开到 9px。
- [Fixed] `tests/qml/tst_narrow.qml`：同步验证红绿灯静止/悬浮尺寸、搜索焦点、真实最右边缘触发及离开后的滚动复位。
- [Fixed] `ui/pill/PillView.qml`：搜索入口由覆盖式 `MouseArea` 改为明确的轻触处理，避免与输入框焦点竞争；隐藏操作的悬浮感应区贴合窗口真实最右边缘，不再留下 10px 无响应区。
- [Changed] `ui/pill/PillView.qml`：翻译完成且鼠标不在药丸上时自动退出搜索编辑；紧凑搜索框保留原词，长原词仅在自身悬浮时滚动并在移开后复位。
- [Fixed] `tests/qml/tst_narrow.qml`：增加真实点击聚焦、窗口最右侧展开、译文悬浮滚动/移出归零，以及翻译完成后搜索收起并保留原词的交互回归。
- [Fixed] `ui/pill/PillView.qml`：重整药丸状态逻辑；仅当右侧确有功能被收起时开放最右边缘展开，正常宽度六项功能齐全时悬浮不再改变布局。
- [Fixed] `ui/pill/PillView.qml`：搜索编辑不再隐藏译文或整个功能区；输入框按当前宽度限制在 64–108px，译文保留最低可读空间，右侧功能按剩余空间逐项调整。
- [Fixed] `tests/qml/tst_narrow.qml`：覆盖正常宽度右侧悬浮无副作用、搜索编辑期间译文持续可见、极窄宽度仍保留译文和至少一个操作。
- [Fixed] `ui/pill/PillView.qml`：修正普通 380px 药丸过早隐藏右侧功能的问题；默认状态同时保留可读译文和六项紧凑操作，只有继续缩窄时才按实际剩余空间逐项收起。
- [Fixed] `ui/pill/PillView.qml`：最右悬浮展开改为边缘触发的显式状态，消除展开区域覆盖鼠标后自锁的问题；展开期间先推走红绿灯与搜索入口，译文继续优先使用剩余空间，右侧边缘保持固定。
- [Changed] `ui/pill/PillView.qml`：搜索入口缩为 26px 初始药丸，悬浮自动展开至 96px 并显示输入内容，移出自动复位；点击后保持药丸模式并进入编辑。
- [Fixed] `tests/qml/tst_narrow.qml`：新增普通宽度完整六操作、译文最低可读宽度、搜索悬浮展开与复位测试，并等待右侧展开动画稳定后再检查固定边缘。
- [Changed] `ui/pill/PillView.qml`、`ui/components/TrafficLights.qml`：翻译药丸改为内容优先的流式布局；红绿灯使用 44×22 紧凑规格，搜索保持在左侧，右侧六项操作固定右边缘并按可用宽度从左向右逐项裁入。
- [Changed] `ui/pill/PillView.qml`：悬浮最右 28px 热区时，操作组以 160ms `OutQuart` 向左展开，译文同步让出空间；移出后恢复当前宽度对应的按钮数量，搜索展开和红绿灯展开状态互斥以避免重叠。
- [Changed] `TranslatorWindow.cpp`、`WindowsResizeSession.cpp`：药丸开放原生四边与四角缩放，高度限制为 38–72px；分别记忆药丸和卡片尺寸，切换模式后恢复各自上次大小。
- [Changed] `WindowsResizeSession.cpp`：原生玻璃外壳增加随高度渐变的冷色高光层，保持单一玻璃层和文字对比度。
- [Fixed] `tests/qml/tst_narrow.qml`：覆盖右侧操作展开、右边缘固定、译文动态让位及搜索/译文/操作区互不重叠。
- [Docs] `README.md`、`docs/DESIGN_SYSTEM.md`、`docs/ARCHITECTURE.md`：同步药丸缩放、内容优先布局与玻璃材质边界。
- [Changed] `ui/pill/PillView.qml`：药丸搜索入口恢复为 28px 小药丸；宽度低于 440px 时点击会在当前药丸内平滑展开输入框并立即获得光标，不再切换到卡片，最窄状态会临时收起次要操作为输入让位。
- [Fixed] `tests/qml/tst_narrow.qml`：验证最窄药丸点击搜索后仍处于药丸模式、输入框展开并获得键盘焦点，Escape 可收回。
- [Changed] `ui/Main.qml`、`core/window/TranslatorWindow.cpp`：药丸与卡片内容改为可中断的交叉淡入，窗口以顶部水平中心为锚点做 200ms 展开和约 170ms 收起，快速反向操作从当前几何继续。
- [Changed] `WindowResizeSession.h`、`WindowsResizeSession.cpp`：切换期间按当前高度连续计算外壳圆角，避免卡片收起时提前变成高胶囊造成轮廓突变。
- [Changed] `ui/pill/PillView.qml`：普通药丸常显红绿灯；宽度不超过 220px 的最小状态默认隐藏，鼠标进入最左侧后淡入并平滑为控制区让出空间，移出后恢复。
- [Changed] `ui/card/SearchInput.qml`：卡片搜索框由接近胶囊的圆角改为 8–10px 方圆角；药丸搜索入口仍保留半高圆角的小药丸轮廓。
- [Fixed] `tests/qml/tst_narrow.qml`：增加普通药丸红绿灯常显、最小状态隐藏、左侧悬浮展开及内容让位的回归验证。
- [Fixed] `scripts/check_desktop_ui.py`：兼容 Windows 为独立设置窗追加父窗口标题，继续验证设置入口和 Escape 关闭交互。
- [Docs] `docs/DESIGN_SYSTEM.md`、`docs/ARCHITECTURE.md`：同步模式过渡、红绿灯断点、搜索框圆角和原生外壳圆角策略。

### 2026-09-10 — 桌面界面与 Web 主题统一

- [Changed] `WordDetailView.qml`：取消固定 420px 三栏断点，按可用宽度、当前区块数量和每栏最低可读宽度实时计算 1–3 栏。
- [Added] `CardView.qml`：正文区增加鼠标滚轮与触控板滚动处理；滚轮档位使用 110ms 短动画，触控板像素滚动直接跟手，并在交互期间显示滚动条。
- [Fixed] `tests/qml/tst_card.qml`、`tests/qml/tst_narrow.qml`：覆盖无需拖动滑块的滚轮滚动，以及 1/2/3 栏随宽度自动切换。
- [Changed] `WordDetailView.qml`：宽卡片把词形、同义词和反义词按实际存在的区块自动分栏，窄卡片继续纵向排列，减少短内容集中在左侧造成的大块留白。
- [Changed] `CardView.qml`：内容滚动条静止时完全隐藏，仅在滚动或直接悬浮滚动条时以 110ms 淡入；继续保留溢出范围与最小卡片圆角保护。
- [Fixed] `tests/qml/tst_card.qml`、`tests/qml/tst_narrow.qml`：新增静止滚动条隐藏与宽卡片横向空间利用验证。
- [Changed] `ui/card/WordDetailView.qml`：删除单词下方的考试标签；词形变化移动到双语例句之后，内容顺序改为主释义、例句、词形、同义词、反义词。
- [Fixed] `ui/card/SearchInput.qml`、`ui/card/CardView.qml`：输入框显式支持点击聚焦、鼠标选区和持久选择；内容溢出时显示低干扰圆角滚动条，滚动时增强，最小卡片不侵入圆角。
- [Changed] `DesignTokens.qml` 及各 QML 界面：简体中文界面统一使用系统自带 `Microsoft YaHei UI`，音标和数值使用 `Cascadia Mono`；短反馈、常规动效及工具窗开关缩短为 110/180/160/100ms。
- [Fixed] `tests/qml/tst_card.qml`、`tests/qml/tst_narrow.qml`：增加鼠标点击输入、内容滚动条和“例句后显示词形”的回归验证。
- [Docs] `docs/DESIGN_SYSTEM.md`：同步字体、内容顺序、滚动条和动效时序。
- [Fixed] `SearchInput.qml`、`Main.qml`、`CardView.qml`、`TranslatorWindow.*`、`WindowsResizeSession.cpp`：点击输入框时显式建立离屏 QML 焦点与原生宿主键盘焦点，回车现在会从输入框提交一次翻译。
- [Added] `providers/fallback/FallbackProvider.*`：新增实现 `ITranslationProvider` 的免密在线兜底，组合 MyMemory 文本翻译、Tatoeba 双语例句以及 Datamuse 同义词/反义词，并由本地 ECDICT 补齐词典信息。
- [Changed] `TranslationManager.cpp`、`AppState.cpp`、`GeminiProvider.cpp`：在线引擎不再被本地词典提前截断；在线丰富字段返回后再用 ECDICT 补足中文释义、音标和词形；Gemini 结果同时要求同义词与反义词。
- [Fixed] `tests/qml/tst_card.qml`、`tests/qml/tst_narrow.qml`：新增输入、状态同步、回车提交以及双语例句/同反义词渲染回归测试。
- [Docs] `README.md`、`docs/API.md`、`docs/ARCHITECTURE.md`：记录免密降级顺序、数据来源、限制与隐私边界。
- [Changed] `ui/card/WordDetailView.qml`：单词、音标和美/英发音改为按内容实际宽度自适应；三者可容纳时保持同一行，确实放不下时才安全分行。
- [Changed] `ui/card/CardView.qml`：底部功能栏从固定断点改为按剩余宽度分配按钮，竖向空间足够时继续显示；优先保留当前可用功能，避免仍有空间却提前隐藏。
- [Fixed] `tests/qml/tst_narrow.qml`、`tests/qml/tst_card.qml`：增加单行词头对齐和 220×180 紧凑卡片完整底栏回归验证。
- [Changed] `ui/card/CardView.qml`：移除卡片最下方的语言方向与窗口尺寸状态行，底部只保留一层功能栏；文字大小入口移入底栏并改为向上展开，顶部原位置替换为音乐控制入口。
- [Fixed] `ui/card/CardView.qml`、`tests/qml/tst_card.qml`：按宽度逐步收起复制、朗读、收藏与历史按钮，保证最窄宽度下 Smart-Select 与文字大小入口不重叠；新增音乐入口及底部文字调节交互回归测试。
- [Changed] `ui/card/CardView.qml`：恢复稳定边框重建前的顶部布局。红绿灯固定 48px 保留区；语言和引擎分别悬浮展开；中间压到 58px 后，右侧截图、置顶、音乐从左侧依次裁入，保留最右设置热区。
- [Changed] `ui/card/CardView.qml`：右侧工具固定右边缘，以 160ms `OutQuart` 向左展开，并按可见比例同步淡入与缩放；底部使用 Smart-Select、复制、朗读、收藏、历史及文字大小组成的单层功能栏。
- [Fixed] `tests/qml/tst_card.qml`：验证各宽度下工具组互不遮挡；语言与引擎不会同时展开；三种悬浮状态下红绿灯的位置和宽度均不变化；移出后恢复当前宽度布局。
- [Changed] `ui/card/CardView.qml`、`ui/pill/PillView.qml`：主卡片与药丸沿用 Web 端深色玻璃主题；药丸窄屏入口直接打开设置，不再显示快捷操作菜单。
- [Refactored] `ui/Main.qml`：删除重复的快捷操作窗口，原入口改为偏好设置；设置、历史、音乐和截图窗口共享 190ms 打开、120ms 关闭的缩放淡入动效。
- [Changed] `DesignTokens.qml`、`SettingsView.qml`、`HistoryView.qml`、`MusicIslandCard.qml`：统一 Web 端深色玻璃表面、26px 工具窗圆角、边框、顶部层级和 120ms 控件反馈。
- [Fixed] `tests/qml/tst_card.qml`：窄尺寸始终检查设置入口，并验证点击后直接触发偏好设置，防止删除快捷操作后丢失核心配置入口。
- [Fixed] `WindowsResizeSession.cpp`：Qt 首次显示主窗口后重新确认原生窗口过程挂接，保证内容点击与稳定边框继续走同一输入路径。
- [Docs] `README.md`、`docs/DESIGN_SYSTEM.md`、`docs/ARCHITECTURE.md`、`docs/WINDOW_UI_REBUILD.md`：同步统一主题、窗口入口和动效约束。

### 2026-09-09 — 原生内容输入与测试边框统一

- [Fixed] `WindowsResizeSession.*`：主窗口过程统一接收边框拖动和内容区鼠标输入，避免离屏 QML 窗口漏收点击。
- [Changed] `WindowResizeSession.h`、`TranslatorWindow.*`：平台层将物理窗口坐标换算为逻辑坐标后，经 Core 接口投递给离屏界面；QML 不接触 Win32 API。
- [Docs] `docs/API.md`、`docs/ARCHITECTURE.md`、`docs/WINDOW_UI_REBUILD.md`：同步原生输入转发职责与发布前证据边界。
- [Changed] `.gitignore`：排除本地 Web 开发构建目录 `dev-dist/` 和 Python 缓存，避免将生成文件上传到仓库。

### 2026-09-09 — 复用已验收测试边框，重建内部界面

- [Refactored] `WindowsResizeSession.*`、`WindowResizeSession.h`、`CMakeLists.txt`：移入独立测试框的四圆弧路径、GDI+ AntiAlias/PixelOffsetHalf、内描边、DIB 与 UpdateLayeredWindow 路径，新增 GDI+ 生命周期管理。Windows 原生鼠标消息直接驱动拖动，使用同款 8px 边缘 / 34px 圆角范围命中及捕获流程。
- [Refactored] `TranslatorWindow.*`：移除临时 QPainter 外壳与 8ms 轮询，持久 QML 画布仅提供内容。由平台对外壳和内容统一提交；输入位置根据物理矩形换算，尺寸动画从当前物理尺寸起步，避免缓存几何导致反向跳变。外部窗口尺寸/DPI 变更触发重绘。
- [Changed] `Main.qml`、`CardView.qml`：固定顶部与底部、单一纵向内容滚动区；移除双重缩放/淡入、工具栏横向滚动及多组弹性间距。设置、历史、音乐、截图和更多操作采用独立紧凑窗口，首次打开才加载。
- [Changed] `PillView.qml`、`IconButton.qml`、`DesignTokens.qml`：窄药丸更多按钮打开独立操作面板；图标支持 Tab/空格/回车与辅助名称、禁用状态；提高辅助文字对比度。保留现有词典、例句、发音、收藏、复制功能。
- [Changed] `tests/qml/tst_card.qml` 针对重建后的实际分区验证防重叠；`tst_toolbar.qml` 增加键盘及禁用行为检查；屏幕探针验证实际鼠标目标窗口并匹配测试框圆弧命中规则。
- [Docs] `WINDOW_UI_REBUILD.md` 记录架构选择、职责、验收方法与恢复包。同步 README、API、DESIGN_SYSTEM、ARCHITECTURE。

### 2026-09-09 — 缩放微跳：外壳按物理像素绘制

- [Refactored] `TranslatorWindow.h/.cpp`：QML 内容保留精确 QSizeF 逻辑尺寸，外壳背景、圆角遮罩和描边按最终物理像素矩形绘制，再与内容整帧提交。保留持久内容画布，防止透明帧回归。
- [Changed] `Main.qml` 向宿主提供背景颜色、透明度；`GlassSurface.qml` 在宿主接管外壳时停止重复绘制，独立 QML 预览仍保留原外观。
- [Fixed] `scripts/probe_resize_stability.py` 在定位鼠标后等待事件处理再按下，避免测量时尚未到达目标边缘便开始按键。
- 对照：改前原生固定边漂移为 0，部分有效拖动的截图圆角切入偏差为 5px；仅保留 QSizeF 未消除此偏差。外壳重绘后的验证记录追加于本节。

### 2026-09-09 — 修复启动后窗口全透明

- [Fixed] `core/window/TranslatorWindow.h/.cpp`：软件渲染使用持久 QImage 画布，只在尺寸或 DPI 改变时重建并重新绑定目标。旧实现每帧创建透明图片，而场景只重绘变化区域，导致首帧之后整窗透明；原生窗口响应正常不能证明可见。
- [Docs] ARCHITECTURE、DESIGN_SYSTEM 同步画布生命周期和实际可见性验收要求。
- 验证：修改前采样 12 帧，第 2–12 帧 alpha 全为 0；修改后 12 帧均有非透明内容且提交成功。实际桌面截图已确认卡片、单词、音标、顶部与底部控件可见。临时采样代码验证后移除。

### 2026-09-09 — 分层窗口整帧提交（开发中）

- [Refactored] `TranslatorWindow` 从直接显示的 QQuickWindow 改为普通 QWindow 宿主，并以 QQuickRenderControl 软件后端把现有 QML 场景渲染到 ARGB 预乘图像。鼠标、滚轮、键盘、输入法和焦点事件转发到离屏场景。
- [Refactored] `WindowResizeSession` / `WindowsResizeSession`：Windows 适配器先计算目标物理像素矩形，再通过 UpdateLayeredWindow 一次提交目标位置、尺寸和完整画面；不再先 SetWindowPos 再等待 QML 交换链。未使用 SetWindowRgn，也没有新增透明辅助窗口。
- [Changed] 药丸/卡片尺寸动画也通过同一整帧提交路径，交互缩放使用同步渲染后的最新指针位置。
- [Fixed] 原生屏幕探针发现并修复松手时 `applyInteractiveResize/endInteractiveResize` 相互调用导致的递归退出；结束路径现在只提交一次最终几何再清理捕获状态。
- [Fixed] 移除交互缩放期间对全局鼠标按键状态的轮询，避免合成输入或高频拖动时会话被错误提前结束；缩放现在只由真实松手或鼠标捕获丢失收尾。
- [Fixed] 鼠标捕获统一交给 Windows 缩放会话管理，避免 Qt 鼠标抓取与分层窗口原生捕获相互切换造成上边和圆角拖动偶发失效。
- [Changed] Qt Quick Controls 固定使用 `Basic` 样式，减少原生样式覆写警告并保证离屏渲染下控件外观一致。
- [Fixed] 药丸音乐详情从窗口外悬浮项改为 `360 × 300` 独立紧凑窗口，完整显示歌词、进度和播放控制，不再被药丸原生边界裁切。
- [Changed] 移除主界面 400–500ms 的首帧缩放淡入，启动后立即响应鼠标输入。
- [Changed] `scripts/probe_resize_stability.py` 支持用 `--edges` 单独复测指定边或圆角，便于隔离桌面合成输入造成的连续探针干扰。
- [Refactored] 八向缩放命中与光标移入 TranslatorWindow，按 32px 可见圆弧带和 6px 边缘计算；删除 Main.qml 八套重复 MouseArea，避免离屏事件转发后指针抓取状态不一致，并修复无效 containmentMask 警告。
- [Fixed] 边缘命中宽高取自 Platform 返回的当前物理窗口矩形并按 DPI 换算，不依赖外部恢复尺寸后可能尚未同步的 QWindow 逻辑宽高。
- [Verified] 项目外单文件空框 `D:/AI Lab/AI Library/Doubao Workspace/lingust-border-drag-test/border_drag_test.cpp` 已由用户确认右边和下边不跳动；正式项目 Qt 6.11.2 / MinGW 构建成功，91 项 QML 布局、窄宽、圆角和即时反馈检查全部通过。正式窗口已启动供人工拖动验收；连续八向合成输入探针仍存在偶发未起拖，不能替代本轮人工结论。
- [Docs] README、DESIGN_SYSTEM、API、ARCHITECTURE 同步新的窗口职责和验证边界。

### 2026-09-09 — 固定像素锚点与取消圆角跳变

- [Fixed] `ui/components/GlassSurface.qml`、`DesignTokens.qml`：卡片按下、拖动、松手均保持 32 逻辑像素圆角，删除 32→40→32 补偿。`tests/qml/tst_corners.qml` 逐像素比较右下角按下和松手前后的轮廓；旧版该测试失败。
- [Refactored] `core/window/WindowResizeSession.h`、`platform/windows/window/WindowsResizeSession.h/.cpp`、`app/Application.cpp`、`CMakeLists.txt`：注入 Windows 缩放适配器，起始矩形、指针增量、固定边全部采用物理像素，一次 SetWindowPos 更新位置和尺寸，避免高 DPI 逻辑坐标分别取整造成对侧漂移。无 SetWindowRgn、无额外透明窗口。
- [Fixed] `core/window/TranslatorWindow.h/.cpp`：待提交帧期间合并输入，frameSwapped 回到界面线程后继续应用最新位置；定时器仅负责静止时轮询，不称为显示器同步。模式切换结束拉伸，拉伸时阻止内容高度动画竞争。
- [Fixed] `ui/Main.qml`：四角命中区域改为可见圆弧上的 6px 宽环带，修复原 8×8 热区落在圆角透明区的问题；顶部最窄时仍保留有效缩放区域。
- [Added] `scripts/probe_resize_stability.py`：同一张截图提取可见边界与四角，分别记录原生坐标；覆盖八向拖动及按下/松手，对侧漂移要求 0 物理像素，轮廓偏差双向检查。
- [Docs] DESIGN_SYSTEM、ARCHITECTURE、API 同步。下方上一轮旧探针的几何与截图不在同一时刻，且只检查曲线变浅；其数字不能证明圆角稳定，也不能据此确认 DWM 根因。以本节及新的实测记录为准。
- 验证：Qt 6.11.2 / MinGW 构建成功；91 项 QML 检查通过（旧圆角切换实现为 90 通过、1 失败）；新版已启动。原生八向探针尚未完成：当前桌面报告 640×480，截图出现黑区及 screen grab failed，脚本拒绝将无效画面判为通过。真实拖动时的视觉稳定性仍待可用桌面复测；不宣称已达到绝对零跳动。探针增加运行前可用桌面检查及结束时窗口位置限界，README 同步固定圆角说明。

### 2026-09-09 — 缩小时右边/底边圆角连续性重写

- [Refactored] \`core/window/TranslatorWindow.h/.cpp\`、\`ui/Main.qml\`：八向拉伸从无限频率的 \`startSystemResize\` 改为与当前屏幕刷新率同步的可中断合并更新，同一帧只应用最新指针位置，松手/取消立即结束；保持对侧锚定及最小尺寸。删除未使用的 Win32 Acrylic/SetWindowRgn 死代码。
- [Fixed] \`ui/components/GlassSurface.qml\`、\`DesignTokens.qml\`、\`CardView.qml\`：新增缩放态圆角补偿，拉伸时从 32px 增至 40px，抵消 Windows 对透明旧帧的瞬时压缩；松手后立即恢复 32px，不改变内容布局或窗口命中区。初始药丸最大高度同步限制为 60px。
- [Added] \`scripts/probe_corner_continuity.py\`：在纯色背景上快速向内缩小右边和底边，直接测量两个相邻圆角的曲线切入深度。旧实现右角 26→21px、底角 25→21px，能稳定复现“变直角”；新实现右角最低 29/32px、底角最低 30/33px。
- [Verified] 四边各移动 224–225 物理像素，对侧漂移最多 1px，绘制边界误差 0px；Qt 6.11.2 / MinGW 构建通过，91 项 QML 检查通过。旧二进制：\`build/bin/lingust.before-paced-resize.exe\`。
- [Docs] README、DESIGN_SYSTEM、API、ARCHITECTURE 同步新的缩放节奏、圆角补偿和验证边界。

### 2026-09-08 — 右边/底边透明窗口缩放后端对照

- [Fixed] `app/main.cpp`：撤销 Windows 强制 `QSG_RENDER_LOOP=basic`，恢复 Qt 在 D3D11 上的默认 threaded 渲染，避免绘制与缩放输入共占界面线程。关闭整窗 4× MSAA；大圆角继续使用 QML Rectangle 抗锯齿。
- [Research] Qt 6 Windows 默认 D3D11，threaded 在专用线程渲染；Microsoft 对同类透明 D3D 窗口的说明表明，窗口几何可能先于新交换链帧进入桌面合成，会短暂显示拉伸旧帧。
- [Verified] 同机 125% DPI 对照：软件栅格与 OpenGL 在右边采样出现最多 4px 绘制边界误差，OpenGL 一次左边拖动未持续；D3D11/threaded 四边各移动 225px 时对侧漂移与采样误差均为 0px。这个探针能检测边界滞后，但仍不等于高速摄像。
- [Docs] ARCHITECTURE 与 DESIGN_SYSTEM 同步渲染循环、抗锯齿及验证边界。参考 Qt 官方渲染循环/Windows 图形文档和 Microsoft DWM/DirectComposition 资料。

### 2026-09-08 — 统一大圆角轮廓与四边缩放检查

- [Fixed] `ui/components/GlassSurface.qml`：背景改为两层同尺寸、同半径、抗锯齿圆角；保留卡片 32px 大圆角、药丸半高圆角，移除越界 800×800 漫游柔光及圆角不一致的短条高光/阴影，修正渐变方向枚举。取消背景持续漫游和多重描边，减少无操作时的重绘。
- [Fixed] `ui/card/CardView.qml`：底栏使用透明底色，由完整圆角背景统一绘制，修复底角外微弱方形残留。
- [Added] `tests/qml/tst_corners.qml`、`tst_card.qml`：检查四角透出背景、完整卡片曲线外像素及最小尺寸；`scripts/test_toolbars.py --ui-root` 支持使用构建前 QML 对照。QtTest grabImage 返回合成 RGB，测试对比背景颜色而非 alpha。
- [Added] `scripts/probe_all_edges.py`：四边原生拖动，比较对侧坐标与实际绘制边界；临时背景显式触发绘制，并取背景实测颜色，避免误将桌面或系统主题底色当成窗口边界。
- 验证：旧 QML 在七种宽度的完整卡片底角检查失败，新版 90 项 QML 检查通过；Qt 6.11.2 / MinGW 构建通过。旧运行版四边各移动 225 物理像素时对侧漂移 0px、绘制边界采样误差最多 1px；未复现用户所见瞬间闪动，因此本轮没有凭猜测切换图形后端，保留已有 basic 渲染循环。
- [Docs] DESIGN_SYSTEM、ARCHITECTURE 更新圆角绘制约束及验证边界。旧二进制：`build/bin/lingust.before-corners.exe`。
- 运行验证：新版已启动且窗口响应正常；实际四边拖动采样中对侧漂移与绘制边界误差均为 0px，已检查原生窗口截图的四角轮廓。采样不是高速录像，仍不能证明瞬间闪动完全消失。原有设置/输入控件的原生样式自定义警告仍存在，不影响本轮主窗口加载。

### 2026-09-08 — 窄卡片重叠、药丸图标与左侧缩放

- [Fixed] `ui/card/WordDetailView.qml`：单词/音标分别换行，文字最小宽度为 0；窄窗口把美/英发音按钮放到独立行，长单词和 150% 字号不再覆盖按钮。修正无效的 SemiBold 枚举。
- [Fixed] `ui/components/HoverScrollText.qml`：音标与译文采用独立限宽区域，窄且有足够高度时分行；仅译文在自己的裁剪视口内往返滚动，重新计算宽度后重置偏移。
- [Fixed] `ui/pill/PillView.qml`：动作组按真实宽度布局，展开按钮始终显示；宽度小于 340 时复制/截图/音乐收进“更多”独立菜单。去掉覆盖按钮的悬停区、无实际行为的拉伸热区和 200ms 宽度动画；修正截图动作到已有 Core 方法。
- [Fixed] `ui/components/MarqueeText.qml`：将悬停观察移出 Row 布局，避免布局内 anchors.fill 导致排布失效。
- [Changed] `core/window/TranslatorWindow.h/.cpp`、`ui/Main.qml`：统一 beginSystemResize，用户接管缩放时停止尺寸动画，保留 Qt 原生八向缩放及对侧锚定。
- [Changed] `app/main.cpp`：Windows 未显式指定时默认 QSG_RENDER_LOOP=basic，尝试减少透明窗口左侧缩放时几何与绘制不同步；允许环境变量覆盖。
- [Changed] `CMakeLists.txt`：最低 Qt 版本明确为 6.8（独立 Popup.Window 菜单及已有 QTP0004 所需）。
- [Added] `tests/qml/tst_narrow.qml`、`scripts/probe_native_resize.py`：文字/音标/按钮边界、药丸最小高度、字号及 Windows 原生左侧拖动检查。
- 验证：QML 回归 81 项通过（包括初始化/清理）；覆盖 128–600 内容宽度、70/100/150% 字号、160–600 药丸宽度和 38/46/60 高度。原生缩放在 125% DPI 下对侧坐标无漂移；旧版采样也未捕获视觉跳动，因此绘制策略调整属于缓解措施，不能据此声称所有机器视觉抖动已消除。
- 本轮交付：Qt 6.11.2 / MinGW 构建及实际启动通过；125% DPI 下从 500 逻辑宽度拖到最小 160，右边界坐标及采样画面边缘变化均为 0px。已核对实际窄卡片截图；旧二进制保留于 `build/bin/lingust.before-narrow-fix.exe`。
- [Docs] README、DESIGN_SYSTEM、API、ARCHITECTURE 同步交互、接口、依赖及验证边界。


### 2026-09-08 — 桌面端顶部/底部即时响应

- [Fixed] `ui/card/CardView.qml`：移除顶部双侧间距、引擎/设置宽度、底部间距的追赶动画；加载状态改为已有的 `isTranslating`，解决无效属性绑定。
- [Fixed] `ui/components/LanguageSelector.qml`、`TrafficLights.qml`：移除覆盖子按钮的 MouseArea，改为 HoverHandler；语言断点宽度立即更新，红绿灯固定占位，避免悬停引起重排。
- [Changed] `ui/components/IconButton.qml`、`DesignTokens.qml`：按钮命中区域保持固定，仅图标按下即时缩小，颜色回落使用 60ms 共享时长。
- [Changed] `ui/card/CardView.qml`：窄窗口滚动条使用 Basic 的 3px 灰蓝样式，修正卡片字体权重枚举；设置入口保留；极窄时工具栏横向滚动保留全部操作，底部按宽度减少辅助文字；滑块位置即时更新。
- [Fixed] `ui/Main.qml`：交互内容层高于背景拖动区域，缩放热区收至外沿，减少鼠标拦截。
- [Added] `tests/qml/tst_toolbar.qml`、`tests/qml/tst_card.qml`、`scripts/test_toolbars.py`：真实 QML 组件回归检查，7 种宽度 × 3 种状态及即时反馈/点击，共 30 项通过（包含套件初始化/清理）。测试使用 UI 状态夹具，不调用真实翻译服务。
- [Fixed] `ui/pill/MusicIslandCard.qml`、`PillView.qml`：实际启动暴露音乐面板引用不存在的 GlassSurface/按钮属性；改用等色圆角 Rectangle 和 width/height，修正资源路径、媒体状态自引用及药丸加载绑定，恢复主 QML 加载。增加音乐组件加载回归检查。
- [Docs] `docs/DESIGN_SYSTEM.md`、`docs/API.md`、`README.md` 同步桌面交互规则、加载状态与验证入口。Web/PWA 本轮未改动。
- 验证：Qt 6.11.2 / MinGW 增量构建通过；30 项 QML 检查通过，已检查标准/极窄截图及实际主窗口启动。旧二进制保留于 `build/bin/lingust.before-toolbar.exe`。
- 验证边界：仍有原有 WordDetailView 字重、GlassSurface 渐变方向及设置页原生样式的非致命警告，未扩展整页重构；未测量系统端到端输入延迟，不将无动画补间等同于物理 0ms。


### [Changed]
- **翻译完成后流光消散全面自然化，引入三阶段潮汐缓退消融状态机 (Tri-phase Organic Dissolve & Seamless Decay Transition)**：
  - **根除退场断崖式暗淡与硬切**：
    - 剖析翻译完成时单纯依赖 Ease-Out 曲线与无延迟 `visibility: hidden` 导致的光芒突然“塌陷一大截”、被浏览器提前隐匿的生硬体验；
    - 在 `<AppleAIBreathingGlow />` 中设计三阶段生命周期状态机：`'idle'`（静止休眠） ➔ `'active'`（晨曦唤醒） ➔ `'dissolving'`（优雅消融）；
  - **850ms 正弦缓降余晖退潮 (`.is-dissolving`)**：
    - 翻译完成（`loading: false`）瞬间，光芒绝不断崖式熄灭，而是保持温润余晖；
    - 采用符合自然光衰减规律的 **Ease-In-Out 正弦缓降曲线**（`cubic-bezier(0.37, 0, 0.63, 1)`），前段柔和释怀，中后段如水墨散入毛玻璃底色般自然蒸发；
    - 边缘高精细线（`.apple-ai-edge-line`）同步轻度柔焦弥散（`filter: blur(2px)`），内向呼吸光幕（`.apple-ai-inward-bloom`）扩展漫散至 `blur(16px)`，双层复合消融；
    - 退场全程 850ms 严格锁定 `visibility: visible`，直至完全消融隐入底色后才平滑切回 `'idle'` 休眠，实现与刚生成的译文呈现无缝视觉交接；
  - **涉及文件**：
    - `src/components/common/AppleAIBreathingGlow.tsx`
    - `src/index.css`
    - `docs/CHANGELOG.md`
    - `docs/DESIGN_SYSTEM.md`

- **解决点击翻译瞬间动效生硬问题，重构为常驻合成层与柔焦破晓唤醒通道 (Organic Pre-cached Wake-up Bloom & Frictionless Activation)**：
  - **根除 DOM 挂载引发的跳帧与硬切**：
    - 剖析动态 `setShouldRender` 卸载/挂载导致浏览器渲染引擎丢失过渡、触发 Transition Cancellation 导致光晕突兀跳出的根本原因；
    - 采用**预缓存 GPU 合成层架构（Pre-cached GPU Compositor Layer）**，光效节点常驻 DOM 树，配合 `will-change: opacity, transform, filter, visibility`；
    - **非激活态**：`opacity: 0; visibility: hidden; filter: blur(12px) brightness(0.6); transform: scale(0.992);`，由 CSS `visibility: hidden` 在零开销下实现 100% 物理隐形，彻底杜绝任何漏光与点击阻挡；
  - **750ms 晨曦柔焦破晓对焦唤醒（Soft-Focus Wake Bloom）**：
    - 点击翻译瞬间，触发 Apple 阻尼缓动曲线（`cubic-bezier(0.22, 1, 0.36, 1)`）；
    - 光线并非瞬间高亮跳出，而是从深层朦胧微光（`blur(12px)`、低亮度）在 750ms 内自然平稳升温、舒展对焦至晶莹剔透的高精琉璃光晕，无缝融入 3.8s 静息呼吸节奏；
    - 翻译完成隐退同样以 750ms 舒缓退出，过渡如丝绸般连贯顺畅；
  - **消除卡片容器边框色彩突变**：
    - 去除卡片与药丸在 `loading` 时将边框生硬切换为 `border-transparent` 的类名跳变，保留恒定精致的磨砂玻璃边框底色，由流光层在上方自然绽放，消除任何底色突褪；
  - **涉及文件**：
    - `src/components/common/AppleAIBreathingGlow.tsx`
    - `src/index.css`
    - `src/components/translator/FloatingTranslatorCard.tsx`
    - `src/components/screenshot/InPlaceScreenshotCard.tsx`
    - `docs/CHANGELOG.md`
    - `docs/DESIGN_SYSTEM.md`

- **流光呼吸严格受控仅在翻译时出现，过渡体验全面自然化 (Strict Translation-Only Lifecycle & Fluid Organic Transitions)**：
  - **根除误显隐患（生命周期严格受控）**：
    - 针对原生 CSS 关键帧动画 `opacity` 会无视并覆盖 Tailwind `opacity-0` 从而导致非翻译状态偶发微光的底层机制缺陷，专门重构封装独立受控组件 `<AppleAIBreathingGlow active={loading} />`；
    - **非翻译状态**：彻底从 DOM 树卸载（`return null`），确保在未发起翻译时 100% 纯净无残留，绝不漏出一丝光芒；
    - **翻译发起时**：通过 `requestAnimationFrame` 在 600ms 内以 Apple 人体工学贝塞尔曲线（`cubic-bezier(0.16, 1, 0.3, 1)`）平滑由 0 渐进至 100% 晨曦般苏醒漫射；
    - **翻译完成时**：触发 600ms 舒缓退出过渡，光晕柔和隐退后干净卸载 DOM，彻底消除生硬截断；
  - **呼吸律动物理曲线自然化**：
    - 将呼吸周期由急促的 2.8s 拉长至悠扬舒适的 **3.8s 人体静息正弦周期**（`cubic-bezier(0.37, 0, 0.63, 1)`），流光周期同步调整为 4.8s；
    - 向内收聚幅度由生硬的 `scale(0.965)` 优化为极为细腻轻柔的 `scale(0.982)` 配合 `14px` 柔光漫射，使光芒向内轻抚卡片内壁的吸气动效如同丝绸般顺滑自然；
  - **涉及文件**：
    - `src/components/common/AppleAIBreathingGlow.tsx` (新建)
    - `src/index.css`
    - `src/components/translator/FloatingTranslatorCard.tsx`
    - `src/components/screenshot/InPlaceScreenshotCard.tsx`
    - `docs/CHANGELOG.md`
    - `docs/DESIGN_SYSTEM.md`

- **翻译中流光呼吸动效重构为 Apple AI 风格向内呼吸体系 (Apple Intelligence Inward Breathing Bloom)**：
  - **由外向内呼吸流转**：彻底消除向外膨胀的 `scale(1.002)` 和刺眼的外向 `drop-shadow` / 紫色向外发光阴影，将呼吸光效全面重构为类似 Apple Intelligence（Siri 响应态）的向内弥散光幕（`apple-ai-inward-bloom`）；
  - **向内呼吸物理曲线**：
    - 平静态（0%/100%）：光芒收束在贴近边缘处，向内渗透深度较浅，中心 60%+ 彻底通透保护正文阅读；
    - 呼吸吸气态（50%）：动画触发向内收缩聚拢（`transform: scale(0.965)` + `filter: blur(14px)`），宛如智能内核向内吸入能量，光雾柔和轻抚卡片内壁，产生极为逼真的内向渗透呼吸流体感；
  - **双层精细结构**：
    - 外轮廓：`.apple-ai-edge-line` 紧贴 `inset: 0` 勾勒 1.5px 高精七彩边框，伴随 9 色色相平滑流转，绝不向外突出生硬边角；
    - 内侧光幕：`.apple-ai-inward-bloom` 使用径向遮罩（`radial-gradient ellipse 96% 90%`）实现从外边框向内部平滑衰减的流光弥散；
  - **多形态完美贴合**：药丸模式（`rounded-full`）、卡片模式（`rounded-[32px]` / `rounded-2xl`）与截屏对照卡（`rounded-2xl`）均添加 `overflow-hidden`，保证内边缘光幕精准贴合圆角且外部阴影保持原生深色沉稳投影；
  - **涉及文件**：
    - `src/index.css`
    - `src/components/translator/FloatingTranslatorCard.tsx`
    - `src/components/screenshot/InPlaceScreenshotCard.tsx`
    - `docs/CHANGELOG.md`
    - `docs/DESIGN_SYSTEM.md`

### [Added]
- **全应用自然动画与丝滑交互微过渡体系 (Natural Fluid Animation & Smooth Micro-Transitions)**：
  - **七彩流光呼吸边框自然淡入淡出 (Organic Fade In/Out for Rainbow Aura)**：
    - 消除请求开始/结束时七彩流光的突兀断崖式闪烁，引入 `transition-opacity duration-500 ease-out` 渐变通道；
    - 翻译开始时如黎明朝霞般柔和绽放，翻译结束或取消时平滑淡出并回归通透毛玻璃边缘；
    - 优化呼吸与流动物理曲线为 Apple 人体工学贝塞尔曲线（`4.2s ease-in-out` 流光 + `2.6s cubic-bezier(0.4, 0, 0.2, 1)` 呼吸），并开启 GPU `will-change: opacity, transform, filter` 硬件加速；
  - **内容与页面切换轻微微缩放过渡 (Subtle View & Content Micro-Transitions)**：
    - 新增 `.animate-view-scale`（`cubic-bezier(0.16, 1, 0.3, 1)`，从 0.985 缩放与 3px 轻位移丝滑落定）与 `.animate-soft-fade`；
    - 翻译卡片结果生成时平滑展开展现，替换原有突兀的内容替换；
    - 模拟桌面 Reader 切换选项卡（经典双语、前沿科技、双语散文、高频词汇）时，内容区增加轻量过渡与按键触觉弹性反馈；
    - 设置独立窗口与历史记录窗口在切换标签页、搜索筛选及列表悬浮时，均应用自然缓动微交互与点击轻量回弹（`active:scale-[0.965]`）；
    - 桌面壁纸切换时引入 `duration-700 ease-in-out` 背景色阶柔和渐变；
  - **涉及文件**：
    - `src/index.css`
    - `src/components/translator/FloatingTranslatorCard.tsx`
    - `src/components/screenshot/InPlaceScreenshotCard.tsx`
    - `src/components/desktop/DesktopSimulator.tsx`
    - `src/components/settings/SettingsWindow.tsx`
    - `src/components/history/HistoryWindow.tsx`
    - `src/components/common/PWAInstallModal.tsx`
    - `src/App.tsx`
    - `docs/CHANGELOG.md`
    - `docs/DESIGN_SYSTEM.md`

- **翻译中七彩流光呼吸边框与环境光晕动效 (Rainbow Breathing Border & Aura Effect)**：
  - **视觉呈现**：在文本翻译请求与截屏 OCR 翻译过程中（`loading === true`），窗口边框自动激活炫彩流动呼吸特效；
  - **色彩构成**：精准应用苹果 Apple Intelligence / macOS 顶级色彩阵列（Coral Red `#ff3b30`、Orange `#ff9500`、Gold `#ffcc00`、Emerald `#34c759`、Teal `#00c7be`、Azure `#007aff`、Indigo `#5856d6`、Violet `#af52de`、Pink `#ff2d55`）；
  - **双层光晕架构 (Dual-Layer Bloom Architecture)**：
    - **内层高精流光线 (`.rainbow-breathing-border`)**：采用 CSS 遮罩内容盒排除技术（`-webkit-mask-composite: xor` / `mask-composite: exclude`），形成锐利清澈的 2px 七彩外框，中心绝对镂空透明，0 遮挡内部文字与控件；
    - **外层漫反射呼吸光环 (`.rainbow-breathing-aura`)**：3.5px 软化微光晕配合 2.2s 人体静息呼吸节奏律动，伴随多层 `drop-shadow` 产生向外辐射的通透霓虹光雾；
  - **全形态自适应覆盖**：
    - **药丸模式 (`FloatingTranslatorCard` - Pill Mode)**：无缝契合 `rounded-full` 胶囊曲线，消除旧容器截断；
    - **完整卡片模式 (`FloatingTranslatorCard` - Card Mode)**：自适应匹配 `rounded-[32px]` / `rounded-2xl`，提供奢华呼吸光圈；
    - **原地截屏对照卡 (`InPlaceScreenshotCard`)**：在 OCR 与排版对照生成中同步呼吸，给予强有力的操作反馈；
  - **涉及文件**：
    - `src/index.css`
    - `src/components/translator/FloatingTranslatorCard.tsx`
    - `src/components/screenshot/InPlaceScreenshotCard.tsx`
    - `docs/CHANGELOG.md`
    - `docs/DESIGN_SYSTEM.md`

### [Fixed]
- **修复 React Hook 顺序引发的 Internal React error (Expected static flag was missing)**：
  - **根本原因**：`SettingsWindow` 与 `HistoryWindow` 组件在挂载时首行存在 `if (!isOpen) return null;` 提前退出逻辑，导致未打开时调用 0 个 Hook、打开时调用多个 Hook，违反了 React Hook 调用顺序铁律（Rules of Hooks），触发 React 19 Fiber 协调器抛出 `Internal React error: Expected static flag was missing`；
  - **解决方案**：
    - 将 `SettingsWindow.tsx` 与 `HistoryWindow.tsx` 内部的所有 `useState`、`useRef`、`useEffect` 无条件置于函数顶层统一调用，确保每次渲染 Hook 调用链绝对一致；
    - 在 `App.tsx` 中对独立浮动窗口实施按需挂载渲染 (`{isSettingsOpen && <SettingsWindow ... />}`, `{isHistoryOpen && <HistoryWindow ... />}`)，彻底根除 Hook 计数器失配与无意义的后台监听消耗；
  - **涉及文件**：
    - `src/components/settings/SettingsWindow.tsx`
    - `src/components/history/HistoryWindow.tsx`
    - `src/App.tsx`
    - `docs/CHANGELOG.md`

### [Changed]
- **设置与历史记录独立窗口化重构与全界面主题统一 (Settings & History Standalone Floating Windows & Global Theme Unification)**：
  - **设置独立窗口化 (Settings Standalone Window)**：
    - 将原有的全屏阻塞式模态抽屉重构为符合 Windows/macOS 桌面规范的**独立浮动窗口 (`SettingsWindow`)**；
    - 配备标准的 macOS 三色红绿灯控制（红灯关闭、黄灯收缩为浮动药丸、绿灯居中复位）；
    - 顶部支持流畅鼠标拖拽平移，取消背景遮罩层，允许用户在边看文档/使用翻译卡片的同时并列开启设置进行调试；
    - 支持一键最小化为轻量桌面胶囊药丸，需要时随时还原；
    - 全面规整五大分类选项卡：🤖 翻译引擎与专属密钥、⚡ 划词交互与触发方式、🎨 视觉排版与字号调节、🎵 灵动岛音乐与歌词律动、💻 独立桌面端与全局快捷键；
  - **历史记录与生词本独立窗口化 (History Standalone Window)**：
    - 将右侧固定抽屉升级为**独立浮动桌面窗口 (`HistoryWindow`)**，遵循 `设置/截图/历史记录使用独立窗口` 规范；
    - 支持自由挪动、最小化收纳、实时搜索、生词本收藏筛选与一键清空；
    - 摒弃旧版浅色背景类名，全面应用深邃星空磨砂玻璃（Deep Midnight Frosted Acrylic）质感；
  - **全界面视觉主题 100% 统一度强化**：
    - 重构 `PWAInstallModal` 桌面安装弹窗，全面适配红绿灯标题栏、磨砂玻璃高光阴影与精致发光按钮；
    - 统一 `SelectionTooltip` 划词翻译悬浮气泡，彻底消除浅色模式下的突兀白底，始终保持深色通透毛玻璃与发光指示灯质感；
    - 消除所有界面在深色 Sonoma / 极光壁纸下的样式反差，确保全局一致的奢华质感。
  - **涉及文件**：
    - `src/components/settings/SettingsWindow.tsx`
    - `src/components/settings/SettingsModal.tsx`
    - `src/components/settings/index.ts`
    - `src/components/history/HistoryWindow.tsx`
    - `src/components/history/HistoryDrawer.tsx`
    - `src/components/history/index.ts`
    - `src/components/common/PWAInstallModal.tsx`
    - `src/components/translator/SelectionTooltip.tsx`
    - `src/App.tsx`
    - `docs/CHANGELOG.md`
    - `docs/DESIGN_SYSTEM.md`
    - `docs/ARCHITECTURE.md`

### [Added]
- **桌面独立客户端免下载即用模式 (PWA Standalone Desktop Integration)**：
  - 集成 `vite-plugin-pwa` 规范化 Service Worker 与 Web App Manifest；
  - 自动注册 `display: standalone` 桌面无边框窗口模式；
  - 生成 `192x192`、`512x512`、`maskable` 高清品牌图标及 `apple-touch-icon`；
  - 新增 `usePWAInstall` 桌面安装响应机制与 `PWAInstallModal` 引导弹窗；
  - 在顶部模拟菜单栏、系统状态栏、快捷操作条及偏好设置中提供一键安装入口；
  - 彻底解决传统桌面应用“改动一次需重新下载打包一次”的痛点，支持云端代码修改全自动热重载与实时生效。

### [Fixed]
- **浏览器 PWA 安装协议链修复与离线 Service Worker 就绪 (PWA Installability & Service Worker Activation)**：
  - 修复 `index.html` 缺失 `<link rel="manifest" href="/manifest.webmanifest">` 导致浏览器无法识别渐进式 Web 应用的问题；
  - 在 `server.ts` 补充 `express.static('public')` 静态文件服务中间件及 `application/manifest+json`、`application/javascript`（`Service-Worker-Allowed: /`）响应头，解决请求 `/manifest.webmanifest` 与 `/sw.js` 时错误回退为 HTML 的问题；
  - 补全持久化静态 Web App Manifest 配置与完整缓存策略的 `public/sw.js` Service Worker，并在 `src/main.tsx` 完成自启动注册，彻底满足 Chromium / Edge 的标准 PWA 安装门槛；
  - 将顶部模拟器状态栏的「安装桌面版」按钮优化为全尺寸可见，并在 `PWAInstallModal` 中补充 Chrome / Edge 浏览器菜单「保存并共享 / 应用 ➔ 安装 Linguist」多通路引导。
  - **涉及文件**：`index.html`, `server.ts`, `src/main.tsx`, `public/manifest.webmanifest`, `public/sw.js`, `src/components/desktop/DesktopSimulator.tsx`, `src/components/common/PWAInstallModal.tsx`。

- **Vite 客户端 HMR WebSocket 错误与 PWA 资产补齐 (Vite Client Error & PWA Assets Fix)**：
  - 针对沙箱容器与禁用 HMR 环境下 `vite-plugin-pwa` 在开发模式下注入 `registerDevSW` 并通过已断开的 WebSocket 发送 `vite-plugin-pwa:dev-ready` 导致浏览器抛出 `[vite]` 控制台异常的问题，优化 `vite.config.ts` 中的 `devOptions.enabled: false`，彻底消除前端运行时错误；
  - 运行 `scripts/generate_icons.py` 完整生成缺失的 PWA 图标资源（`pwa-192x192.png`、`pwa-512x512.png`、`pwa-maskable-512x512.png`、`apple-touch-icon.png`），避免网页引用不存在的图标导致 404/HTML 回退；
  - 清理 `server.ts` 中未使用的 `fileURLToPath` 与 `__filename`/`__dirname` 声明，消除 esbuild 编译为 CommonJS 格式时的警告。
  - **涉及文件**：`vite.config.ts`, `server.ts`, `public/apple-touch-icon.png`, `public/pwa-*.png`。

- **开发服务依赖完整性修复与热重载恢复 (Dev Server Dependency & Service Restoration)**：
  - 修复开发容器环境内 `node_modules` 依赖包同步缺失的问题，完成完整依赖重新拉取与链接；
  - 成功重启并恢复本地 3000 端口全栈服务（Express 后端 API + Vite 中间件），经验证 `/api/health` 探针及静态页面路由均已恢复 200 正常响应。

### [Changed]
- **顶部栏与底部栏布局重构与极致视觉优化 (Top Bar & Bottom Bar Layout Refactoring & UI Polish)**：
  - **顶部栏瘦身降噪 (Top Bar Cleanliness)**：
    - 移除顶部栏生词本/历史记录按钮，消除与底部动作栏中已有历史入口的重复冗余，释放顶部标题栏呼吸感与横向空间；
    - 顶部栏精简为核心操作群：图钉置顶（Pin）、灵动岛音乐（Music）、设置（Settings），彻底告别图标拥挤；
  - **文本大小调节迁移至底部栏 (Font Size Adjuster Relocation to Bottom Bar)**：
    - 将字体字号调节按钮从顶部工具栏下移至底部工具条，紧随翻译结果操作动作组，排布更符合自上而下阅读、自下而上调控的直觉动线；
    - 弹窗改为自底向上平滑展开动效（`BottomRight` 变换原点，向上弹出），不遮挡核心原文与主译文展示区；
    - 完整保留直接数值输入、百分比步进（60%~150%）、四档快捷预设（紧凑 80%、默认 92%、标准 100%、大字 115%）以及动态紧凑布局切换开关；
  - **跨端 100% 同步实现**：
    - Web 端：`src/components/translator/FloatingTranslatorCard.tsx`；
    - 桌面端：`ui/card/CardView.qml`。

### [Added]
- **药丸集成灵动岛音乐与系统音频媒体总线监听 (Dynamic Island Music & Windows GSMTC Media Integration)**：
  - **灵动岛胶囊交互模式 (Pill Dynamic Island Mode)**：
    - 在药丸模式右侧工具条新增绿色音乐图标（🎵），点击即可无缝在“极简翻译模式”与“灵动岛音乐模式”之间自由切换；
    - **极小胶囊形态 (Compact Pill State)**：
      - 360° 匀速旋转黑胶唱片微缩唱盘（播放时转动、暂停时驻留）；
      - 动态跳动 3 柱音频均衡器跳律动（带随机平滑缓动阻尼）；
      - 歌曲标题、演唱者与当前行实时双语歌词跑马灯展示；
      - 即时播放/暂停、下一首切歌与一键快速切回翻译；
    - **展开大卡片形态 (Expanded Island Popover)**：
      - 点击胶囊或卡片顶部音乐按钮，向上平滑呼出磨砂玻璃大卡片 `MusicIslandCard`；
      - 展示高分辨率黑胶唱片唱针转动视效、歌曲名、艺术家、所属专辑；
      - 沉浸式双语实时歌词卡片（中英对照同步滚动高亮）；
      - 交互式播放进度条（支持鼠标任意拖动 Seek 跳进度与实时时长倒计时）；
      - 全套播放控制按钮（上一曲、播放/暂停、下一曲）；
  - **核心系统服务与 Windows 原生适配 (Core & Platform Layers)**：
    - **Core 层**：新增 `core/media/MediaSessionService.h/.cpp`，负责媒体播放状态机、内置预设歌单（Lofi Rain & Coffee、Midnight Coding Flow 等）、歌词解析匹配与进度定时器；
    - **Platform 层**：新增 `platform/windows/media/WindowsMediaManager.h/.cpp`，封装 Windows GSMTC (`GlobalSystemMediaTransportControlsSessionManager`)，监听系统活跃播放器（网易云音乐、QQ音乐、Spotify、Apple Music 与 Chrome/Edge 网页音频等）的播放状态与音轨元数据；
    - **状态总线打通**：在 `AppState` 扩展 `musicPlaying`, `trackTitle`, `trackArtist`, `trackAlbum`, `trackDuration`, `trackPosition`, `currentLyric`, `currentLyricTranslation`, `pillMusicMode`，并提供 QML `Q_INVOKABLE` 控制接口；
  - **Web 端与桌面端 100% 同步交付**：
    - Web 端新增 `src/components/music/MusicIslandView.tsx`，与 `FloatingTranslatorCard.tsx` 完美集成；
    - 桌面端新增 `ui/pill/MusicIslandCard.qml`，与 `PillView.qml` 和 `CardView.qml` 深度打通，并引入 `music.svg`, `play.svg`, `pause.svg`, `skip-back.svg`, `skip-forward.svg`, `disc.svg` 6 组矢量图标资源。

### [Changed]
- **顶部与底部栏 UI 动效与交互体验深度重构与对齐 (Top & Bottom Bar UI Animation & Interaction Polish)**：
  - **顶部栏 (Top Bar)**：
    - **统一动效缓动标准**：全面推行 120ms~150ms `Easing.OutCubic`，彻底取代原线性 `Easing.Linear`，带来丝滑物理惯性阻尼感；
    - **翻译引擎胶囊 (Engine Indicator)**：
      - 增加动态呼吸指示灯（翻译时加载闪烁、离线模式琥珀色、在线模式薄荷绿）；
      - 悬停平滑高亮微缩放，支持鼠标点击直接顺次循环切换引擎（Gemini ➔ DeepL ➔ 有道 ➔ 离线）；
    - **语言选择胶囊 (Language Selector)**：
      - 双向互换按钮（`ArrowLeftRight`）支持 180° 平滑旋转动效与触控手型反馈；
      - 语言下拉触发与切换增加微光反馈；
    - **功能图标组 (Top Actions)**：
      - 全平台顶部栏新增 **生词本/历史记录快捷入口**（History 图标），一键呼出历史抽屉；
      - 设置齿轮按钮增加悬停旋转微动效，带来灵动的桌面级质感；
    - **基础控件精修**：`IconButton.qml`、`TrafficLights.qml` 均标配手型光标（`Qt.PointingHandCursor`）、`scale: 1.08` 弹性悬停放大与激活光晕；
  - **底部栏 (Unified Bottom Bar)**：
    - **重构为单层一体化磨砂玻璃工具条**：将原分散的操作工具栏与尺寸底部栏合并为高度 36px 的统一轻量化栏目，消除双层边框堆叠割裂感；
    - **Smart-Select 划词感知开关**：配置平滑缓动滑块与手型光标，开启/暂停状态实时色彩反馈；
    - **右侧智能自适应功能组**：
      - 翻译完成状态下：平滑展开复制（带绿色对勾成功反馈）、即时发音、生词本收藏、历史抽屉；
      - 空状态下：自适应展现 `划词即翻 · Alt+Q` 极简热键提示；
      - 窗口尺寸规格微标（如 `340×420`）以等宽字体低对比度雅致融入；
  - **跨平台双端 100% 对齐**：Qt QML 桌面端（`CardView.qml`, `IconButton.qml`, `LanguageSelector.qml`, `TrafficLights.qml`）与 Web 端（`FloatingTranslatorCard.tsx`, `LanguageSelector.tsx`）全线同步交付。

### [Added]
- **鼠标点击句子即时朗读发音 (Click-to-Speak Sentences)**：
  - **长句翻译面板**：
    - 点击译文句子：自动触发对应目标语言（如中文）即时朗读；
    - 点击原文句子：自动触发对应源语言（如英文）即时朗读；
    - 交互视觉反馈：鼠标悬停显示轻微微透卡片光晕、手型指针与音量小喇叭渐显，带来直观灵敏的听音体验；
  - **单词深度视图 (WordDetailView)**：
    - 双语例句（Bilingual Examples）卡片支持鼠标直接点击整句朗读，右侧常驻/悬停提示音量图标，方便随时跟读例句；
  - **双端 100% 对齐**：Qt QML 桌面端（`CardView.qml`、`WordDetailView.qml`）与 Web 端（`FloatingTranslatorCard.tsx`、`WordDetailView.tsx`）全线同步支持。
- **划词模式支持独立关气泡直达卡片 (SelectionTriggerMode)**：
  - `AppState` 扩展 `selectionTriggerMode` 属性（支持 `"auto"` 与 `"icon"` 两种模式）；
  - 设置面板与状态彻底打通：用户选择 **“立即弹出卡片”** 时，即可彻底关闭悬浮微型小气泡，鼠标划词直接呼出主翻译卡片，流畅无阻；
  - 划词翻译功能与小气泡解耦：关闭气泡后划词翻译完全可用，满足用户“只要划词翻译、不要中间小气泡遮挡”的需求。
- **生词本与历史抽屉新增单项一键发音**：
  - 在 `HistoryView.qml` 每条历史记录卡片右上角增加发音小喇叭按钮，点击即可直接听取历史单词/短语的原声发音。

### [Fixed]
- **全面排查并修复 Windows 桌面端发音异常 (AppState::speak)**：
  - **参数签名自适应**：为 `speak(text, lang, accent)` 提供默认实参，支持 QML 侧直接无参调用 `appState.speak()`（自动提取当前译文或源词朗读，修复 `PillView.qml` 药丸模式下因缺省实参导致的方法匹配失败）；
  - **VBScript 语法死锁修复**：修复原 VBScript 单行 `If ... Then ... : End If` 导致的语法解析异常；
  - **升级为 Windows 原生 PowerShell + SAPI 双引擎发音系统**：
    - 优先采用 Windows .NET 原生 `System.Speech.Synthesis.SpeechSynthesizer`，全面支持英式发音（Hazel / George 等 `en-GB`）与美式发音（Zira / David 等 `en-US`）以及中文（Huihui / Yaoyao 等 `zh-CN`）；
    - 文本传输全面采用 **Base64** 编解码穿透，彻底根治多行文本换行截断、双引号转义冲突以及中文字符集乱码问题；
    - 在极端或受限 Windows 权限环境下自动回退到 `SAPI.SpVoice` COM 接口，保证 100% 发音成功率；
    - 保持全异步无黑框后台运行（`-WindowStyle Hidden -NoProfile`），绝不阻塞 QML 界面渲染与动效。
- **Web 端 1:1 复刻 - 截图框选逐行中英对照翻译 (ScreenshotTranslationView.qml)**：
  - 深度对齐 Web 端 `ScreenshotTranslationView`，实现全屏/区域截图后的逐行双语对照展示；
  - 顶部状态横幅：显示识别行数与语言方向（如 `共识别 3 行文本 · EN ➔ ZH`），附带 `逐行中英对照` 胶囊徽章；
  - 原图缩略图预览：支持查看原截图与一键收起折叠；
  - 逐行双语卡片结构：每一行独立卡片展示，包含上方原文（带蓝色序号圆点、发音朗读与复制按钮）与下方译文（带薄荷绿圆点、发音朗读与复制按钮）；
  - 底部操作栏：支持 `一键复制全部对照`（带对勾反馈状态）、`朗读全部` 与 `返回文本` 快速切换回常规翻译。
- **Web 端 1:1 复刻 - 完整偏好设置面板 (SettingsView.qml)**：
  - **4-Grid 引擎选择卡片**：Gemini AI（深度语境）、DeepL（高自然度）、有道智云（考试词典）、100% 离线脱机词典（零网络依赖），带激活蓝圈与动态高亮；
  - **动态 API 密钥配置与连通性测试**：
    - Gemini/DeepL/有道专属密钥输入框，配备眼睛图标（Eye/EyeOff）密码明密文切换；
    - 各引擎官方获取密钥外部超链接（支持一键调起默认浏览器访问官方控制台）；
    - API 连通性测试按钮，内置旋转动画与成功/失败实时状态横幅；
    - 离线引擎专属免配置绿色就绪提示；
  - **划词与交互偏好**：全局划词翻译（Smart-Select）开关、划词触发方式（立即弹出卡片 / 显示悬浮快捷图标）选项卡、翻译完成自动发音开关、紧凑布局模式开关；
  - **外观与排版**：悬浮卡片透明度调节滑块（60%~100% 带百分比实时读数）、全局排版字号比例调节滑块（70%~150%）及 80%/100%/120% 快速预设按钮；
  - **快捷键速查指引**：Alt+Q（唤起/隐藏主卡片）、Alt+W（截图框选翻译）、Alt+E（选中文本翻译）、Esc（折叠极简药丸）；
  - **底部控制**：支持一键恢复默认偏好设置，以及平滑关闭设置浮层。
- **新增 Lucide 矢量图标资源**：
  - `resources/icons/camera.svg`（相机图标）
  - `resources/icons/sliders.svg`（偏好设置滑块图标）
  - `resources/icons/eye.svg` 与 `eye-off.svg`（密码显隐图标）
  - `resources/icons/external-link.svg`（外部链接跳转图标）
  - `resources/icons/rotate-ccw.svg`（重载与测试刷新图标）
- **Web 端对齐 - 字体缩放面板 (Font Scaling Popover)**：在 CardView 顶部栏集成与 Web 端相同的动态字号排版弹出层，支持 70%~150% 步进调节（±5%）与 80%/100%/120% 快捷预设标签，支持全局动态字号缩放。
- **Web 端对齐 - 生词本与历史抽屉 (HistoryView.qml)**：桌面端新增仿 Web 端 `HistoryDrawer` 的半透明玻璃抽屉层，支持按关键词实时过滤、全部与生词本标签快速切换、历史单项快速删除、清空全部历史，以及点击历史记录一键装载并发起即时翻译。
- **AppState 动态字号与历史管理 API**：
  - `fontSizePercent` (int, 70~150)：通知全局 QML 计算字号阶梯；
  - `setFontSizePercent(int)`：设置并持久化字号偏好；
  - `deleteHistory(int id)`：根据记录唯一 ID 删除对应项；
  - `clearText()`：便捷清空当前源词与翻译缓冲。

### [Changed]
- **CardView 主卡片多模态整合**：
  - 引入 `showScreenshotView` 状态，实现常规单词/句子翻译与截图逐行对照翻译之间的平滑无缝切换；
  - 搜索栏右侧截图按钮直通截图逐行视图；
  - 工具栏和滚动视图在截图翻译激活时自动优化隐匿，避免遮挡。
- **SearchInput 交互升级**：
  - 新增 `screenshotClicked` 信号，点击截图按钮即刻触发截图逐行对照展示及选区识别逻辑。
- **CMakeLists.txt 构建配置同步**：
  - 在 `QML_FILES` 中注册 `ScreenshotTranslationView.qml`；
  - 在 `RESOURCES` 中注册所有新增 SVG 矢量图资源，确保跨平台部署无遗漏。

### [Changed]
- **DesignTokens 视觉 Token 全面对齐 Web 端**：
  - 玻璃材质色谱：更新为 `#0c0d18` / `#16192a` / `#1e2238` 配合漫反射高光与 macOS 物理倒角刻痕；
  - 动态字号比例因子：引入 `fontScale: (appState ? appState.fontSizePercent : 100) / 100.0`；
  - 边框与输入态 Token：重构为 `borderSubtle` (`#14ffffff`)、`borderNormal` (`#26ffffff`)、`borderInput` (`#26ffffff`)、`borderInputFocus` (`#60a5fa`)。
- **WordDetailView 词汇卡片深度对齐 Web 端**：
  - 顶部标题行：新增高对比度单词粗体标题（`font.bold: true`）与淡蓝音标，整合美/英（US/UK）发音胶囊按钮；
  - 多词性释义支持：对齐 Web 端 `definitions.slice(1)` 展开次要词性与释义；
  - 交互增强：同义词与反义词点击直接触发当前词汇查询与翻译；
  - 动态字号适配：所有字号使用 `DesignTokens.fontScale` 动态联动。
- **SearchInput 交互优化**：
  - 支持双向文本绑定与输入清空（Clear）；
  - 截图按钮与清空按钮指针手势规范化（`cursorShape: Qt.PointingHandCursor`）；
  - 截图按钮直连 `appState.triggerSelectionTranslation()`。
- **CardView 主卡片整合**：
  - 顶部截图按钮与字体调节按钮完整连通；
  - 底部栏历史记录图标与生词收藏高亮状态精准同步；
  - 动态挂载 `HistoryView` 抽屉与 `fontPopover` 浮层。

### [Refactored]
- 规范化 QML 资源表 `CMakeLists.txt`：加入 `ui/card/HistoryView.qml`，确保构建与资源打包顺利通过。
- 退出动画：缩放 0.95 + 淡出 0.0（250-300ms InQuad），动画完成后退出
- 最小化到任务栏：`minimizeToTaskbar()`，先移除 AlwaysOnTop 再 showMinimized，恢复时重新设置置顶
- 右上角图标逐个吸入动画：窗口缩小时图标从右到左依次收缩宽度+淡出，250ms InOutCubic
- TrafficLights macOS 风格：悬停显示功能图标（×/−/⤢），150ms 淡入，原生配色
- 底部 Smart-Select 开关：替换原 en➔zh 语言对，蓝色滑块 + SMART-SELECT/PAUSED 状态文字
- isPinned 属性：窗口固定状态，QML 可绑定

### [Changed]
- 左上角按钮功能重定义：红色=退出应用，黄色=最小化到任务栏，绿色=缩小到药丸
- UI 整体边距优化：内容区左右 20px/上下 18px，顶部栏左右 18px，元素间距 14px
- 顶部分割线：添加左右边距（与内容对齐）
- 底部栏：合并操作工具栏和底部栏，左边 Smart-Select 开关，右边操作按钮
- 右上角图标：右边距 10px，图标容器 26×26，吸入阈值 430/390/350px
- 操作按钮图标：13px，40% 透明度白，悬停提亮

### [Fixed]
- 搜索框与音标行重叠：移除 WordDetailView 和句子翻译的手动 `y` 属性（ColumnLayout 中手动设 y 导致偏移）
- QML 调用 C++ 方法失败：`setSourceText`/`setSelectionTranslation`/`setSourceLang`/`setTargetLang`/`setIsFavorite`/`setCompactMode`/`setAutoSpeak`/`setCardOpacity` 添加 `Q_INVOKABLE` 标记
- 最小化到任务栏崩溃：frameless + AlwaysOnTop 窗口直接 showMinimized() 崩溃，改为先移除置顶再最小化
- 右上角图标缩小被裁切：移除 `clip: true`，增加右边距，调整吸入阈值
- 音标行高度不稳定：添加 `Layout.preferredHeight: 24`
- 顶部栏布局重构：去掉第二个弹簧，图标组固定在右边（12px边距）；按钮先缩小（13→11→10px）再逐个吸走；中间组先缩小再隐藏（<300px）
- 顶部栏布局二次优化：去掉中间组整体隐藏动画（避免弹簧跳动），语言选择器<250px隐藏、引擎状态<280px隐藏；图标按钮先缩小（13→11→9px，容器26→24→20px）再逐个吸走（截图>450/固定>410/字体>370）；图标组绝对固定右边
- 顶部栏布局三次优化：按钮先跟随窗口缩小到最小（13→11→9→8px，容器26→24→20→18px），缩到最小后才逐个隐藏（截图>300/固定>270/字体>240）；语言选择器<220px隐藏、引擎状态<240px隐藏
- 顶部栏布局四次优化：从 RowLayout 改为绝对定位，TrafficLights 左对齐、中间组居中、图标组右对齐（12px边距），彻底消除弹簧跳动；所有元素大小/宽度变化带 Behavior 动画，丝滑流畅
- 顶部栏布局五次优化：增加顶部栏高度（34/36/42px）避免与内容重叠；图标缩小范围调整为13→11→10px（缩到中等程度即开始隐藏）；按钮隐藏阈值调整为截图>360/固定>330/字体>300
- 顶部栏布局六次优化（全面重构）：LanguageSelector 合并 EN/Zh 到一个胶囊；顶部栏高度增至40/44/50px；引擎状态默认小绿点（居中+发光），悬浮展开显示名称；截图/固定按钮始终显示，字体/设置按钮 hover 弹出；内容区域边距间距更紧凑；所有动画丝滑流畅
- 顶部栏布局七次优化：正常状态全部按钮显示；缩小到<380px进入compactMode，字体/设置按钮隐藏；hover检测范围缩小到一个图标大小(26px)，仅在compactMode时启用；鼠标移到最右边图标位置自动弹出隐藏按钮
- 顶部栏布局八次优化：引擎状态默认展开（小绿点+名称），不再默认小绿点；图标按钮缩小后一个一个被吸进去（设置>400px先吸，字体>360px后吸，截图+固定始终显示）；hover弹出所有隐藏按钮
- 顶部栏布局九次优化（动画丝滑化）：图标大小改为连续线性插值（10-13px）避免离散跳动；按钮隐藏用宽度收缩+clip而非位移；动画时长增至300ms InOutCubic；窗口根据内容自动变换大小（adjustHeightToContent，200-800px范围，300ms延迟防抖）
- 顶部栏布局十次优化：撤销整体窗口自动大小（用户要求）；引擎状态框宽度根据内容自动变化（engineContent.width + 16px左右边距），内部Row布局小绿点+文字居中，200ms宽度动画
- 顶部栏布局十一次优化：修复引擎状态框文字未被包裹问题（发光效果Rectangle占了Row宽度）；将发光效果放入小绿点Item内部，Row宽度只算小绿点+间距+文字
- 顶部栏布局十二次优化（全面恢复先缩小再隐藏逻辑）：引擎状态框正常展开，窗口<380px缩小为18px圆点，悬浮自动展开；语言选择器添加iconOnly模式，窗口<320px缩小为交换图标，悬浮展开；图标按钮保持先缩小（10-13px连续插值）再隐藏（宽度收缩）逻辑；所有动画250ms InOutCubic丝滑流畅
- 顶部栏布局十三次优化：状态框和选择器最后不隐藏；语言选择器最终变为文字->单向（EN->ZH），窗口<300px触发textOnly模式，悬浮展开为完整模式；状态框保持圆点模式不隐藏
- 顶部栏布局十四次优化：修复缩到最窄中间组消失问题（middleGroup opacity改为始终1）；语言选择器textOnly模式改为蓝色无边框（#60a5fa，EN➔ZH），使用➔符号替代->
- 顶部栏布局十五次优化：中间组间距从8px增至10px，添加spacing动画；确保展开时其他元素自动让步（Row布局自动调整位置）；所有动画丝滑流畅
- 顶部栏布局十六次优化：TrafficLights默认小紧凑（10px按钮+4px间距），hover后变正常（12px+6px间距）；中间组间距动态调整（<280px=4px,<340px=6px,其他=10px）；TrafficLights与中间组重叠时自动隐藏，谁也不遮挡谁
- 顶部栏布局十七次优化：TrafficLights改为胶囊框（Rectangle根元素，圆角半透明背景+边框）；只有两种状态：紧凑（9px按钮+4px间距+16px高）和宽松（11px+6px+20px高）；左上角三个按钮固定显示不隐藏；其他元素根据展开情况隐藏确保不重叠；全部动画200ms OutCubic丝滑流畅
- 顶部栏布局十八次优化：修复TrafficLights不显示问题（根元素id从lightsContainer改为lights，修复属性和信号引用错误）；中间组与红绿灯或图标组重叠时自动隐藏，确保谁也不遮挡谁
- 药丸视图优化：红绿灯换成TrafficLights胶囊框（和卡片一致），hover自动放大；降低显示阈值（左侧280px/右侧360px）；音量和复制按钮添加点击事件；翻译结果正常显示
- 顶部栏逻辑重构（按用户要求）：红绿灯去掉compact，初始最小状态不变，只有hover才变大；选择器和状态框始终显示不隐藏；调整缩小阈值（先缩小尺寸，缩到没空间再继续缩小，然后才隐藏）；展开时三个元素互相让步
- 顶部栏动画优化（按用户要求）：红绿灯初始更小（8px按钮+3px间距+14px高），hover线性放大（10px+5px+18px）；宽度直接计算不依赖子元素，确保宽高同时线性变化；所有动画统一为Linear缓动，时长180ms，消除弹簧感；缩小同时收紧间距
- 方向感知缩放（按用户要求）：检测窗口缩放方向（左/右边缘），从左边缩小就左边先变紧凑，从右边缩小就右边先变紧凑；动态调整左右边距，留出最小空隙6px；放大时反向恢复；全部线性动画，过渡自然丝滑流畅
- 顶部栏紧凑优化（按用户要求）：缩到最小时状态框和选择器间距更紧凑（最小0px）；右边工具页面缩小时也变紧凑（图标9-13px/按钮22-26px线性插值）；状态框圆点模式去掉外面的边框
- 顶部栏逻辑优化（按用户要求）：选择器各模式宽度更紧凑（textOnly 44px/minimal 64px/compact 78px/完整 90px）；图标组隐藏阈值调整（设置360px/字体320px），确保先整体缩小紧凑到最小再隐藏；全部线性动画丝滑流畅
- 顶部栏紧凑度再优化（按用户要求）：选择器和状态框间距再小一点（<240=0/<300=1/<360=2/<420=4/其他=8px）；右边功能图标缩小同时更紧凑（图标8-13px/按钮20-26px，缩小更快）；放大时边上的先出来然后放大，左右边同理
- 右边图标固定大小（按用户要求）：右边的图标在页面放大缩小时都保持正常大小（图标13px/按钮26px固定），不随窗口缩放；隐藏逻辑保留（设置>360px/字体>320px）
- 选择器边距再优化（按用户要求）：页面最小时选择器两边边距再小一点，各模式宽度收紧（textOnly 40px/minimal 60px/compact 74px/完整 86px）
- 顶部间距+底部栏统一逻辑（按用户要求）：状态框和选择器间距再小一点（<260=0/<320=1/<380=2/<440=3/其他=6px）；底部栏图标采用和顶部一样的逻辑（固定大小13px/26px，宽度收缩隐藏，180ms Linear动画，hover弹出，放大时边上的先出来）；复制+音量始终显示，收藏>340px，历史>380px
- 顶部/底部逻辑再调整（按用户要求）：页面最小时选择器更紧凑（textOnly 36px/minimal 56px/compact 70px/完整 82px）；顶部逻辑中间先缩小然后两边隐藏（选择器textOnly<260/状态框圆点<300/字体隐藏<260/设置隐藏<300）；底部只要有空间就不隐藏没空间再一一隐藏（收藏<260/历史<300），确保不被遮挡
- 顶部栏动态空间分配（按用户要求）：实现智能空间分配算法，中间组检查两边空间，有空间就不动，没空间再缩小；缩小后两边有空间了再继续缩小；中间缩到最小后没空间了右边图标才开始隐藏；在状态框右边设置一道墙，右边图标不能超过；全部线性动画丝滑流畅
- 顶部栏三盒子逻辑重构（按用户要求）：给红绿灯/中间组/图标组都加盒子，谁都不能超过谁；页面缩小时先同时减小盒子间空间，没空间就先给中间盒子缩小，又有空间就继续缩小空间，还没空间就右边盒子缩小（隐藏按钮），左边盒子一直不变；全部线性动画丝滑流畅
- 三盒子重叠修复（按用户要求）：右边宽度用全部按钮宽度计算而非当前显示宽度，确保中间先缩到最小；右边在中间没变到最小前绝对不变（去掉iconOverWall提前隐藏）；middleNaturalWidth改回硬编码避免绑定循环；确保盒子不能越过盒子
- 永远不重叠修复（按用户要求）：middleNaturalWidth用安全最大值(90+80+8=178)覆盖状态框展开最大宽度；调整缩小阈值(compactWidth/minimalWidth/textOnlyWidth逐级判断)，确保每个模式下都不重叠；整个逻辑全部线性动画，右边和中间无论什么状态都不重叠
- 顶部栏三盒子空间分配算法重构（按用户要求，联网搜索最佳实践后）：删除旧逻辑，用清晰的统一空间分配算法重新实现；固定宽度定义(leftWidth/rightFullWidth/rightMinWidth/middleNatural/middleCompact/middleMinimal/middleMin)；第一步计算间距(有空间就同时减小)，第二步计算中间盒子宽度(间距缩到0后没空间就缩小中间)，第三步计算右边盒子宽度(中间缩到最小还不够才缩小右边)；右边按钮平滑收缩隐藏(settingsBtnW/fontBtnW)；永远不重叠，全部线性动画
- 顶部栏墙碰撞检测重构（按用户要求的新思路）：删除宽度计算逻辑，改用墙碰撞检测；左墙=红绿灯右边+间隙，右墙=图标左边+间隙(用右边全部显示宽度)；中间盒子在两墙之间，碰到墙就缩小(compact/minimal/textOnly)；中间缩到最小还被墙推→右边开始隐藏；右边按钮平滑收缩隐藏；永远不重叠，全部线性动画
- 不重叠最高优先级修复（按用户要求）：右边在中间没变到最小前正常不变，但不变会导致重叠时也要隐藏；添加重叠检测(middleRightEdge vs rightLeftEdge)；rightShouldShrink = 中间缩到最小还被推 || 检测到重叠；重叠时右边收缩量增加重叠部分+4px；确保不重叠是最高优先级
- 稳定重叠逻辑修复（避免绑定循环）：右墙用右边全部显示时的宽度计算(rightWallFull)，不依赖当前rightWidth；重叠检测用"假设右边全部显示时中间右边界是否超过右墙"；右边宽度=中间没缩到最小则不重叠保持full/重叠则收缩到不重叠，中间缩到最小则根据空间收缩；不重叠最高优先级，右边在中间没变到最小前正常不变但不变会重叠时也要隐藏
- 直接计算不重叠修复（按用户要求）：右边宽度直接根据中间实际宽度计算，maxRightWidthNoOverlap = width - rightMargin - (width+middleGroup.width)/2 - wallGap，rightWidth = max(52, min(104, maxRightWidthNoOverlap))；确保右边图标不会超过状态框；缩小页面优先减小空间(间距)再缩小盒子，spacing=空间>自然宽度时从6px减小，空间<=自然宽度时间距为0盒子开始缩小
- 顶部栏Row+弹簧重构（按用户建议）：整个顶部用Row+弹簧结构，红绿灯|左弹簧|中间组|右弹簧|右边图标；Row自动排列天然不重叠；弹簧先减小(间距)减到0后盒子再缩小；左右弹簧一样宽保持中间居中；简化属性计算；优先减小空间再缩小盒子；不重叠最高优先级
- 动画全面优化（按用户要求）：去掉弹簧改用绝对定位；所有动画统一为150ms Linear缓动；IconButton点击缩放150ms Linear(0.90)、悬停透明度150ms Linear、背景色150ms Linear；顶部栏所有宽度/间距/透明度动画统一150ms Linear；底部栏开关动画150ms Linear；整体交互动画丝滑流畅线性
- 顶部栏Row框架重构（按用户要求）：改用Row框架+左右弹簧；所有动画缩短到100ms，变化更及时无延迟；右边图标组改用Row排列，隐藏时一个一个被吸进去（宽度收缩+clip）；右边图标组添加clip:true确保不超过圆角边框；图标透明度阈值改为10更平滑；整体交互动画丝滑流畅
- 图标隐藏动画增强（按用户要求）：字体按钮和设置按钮隐藏时添加scale缩放动画（1.0→0.0）；同时保持opacity淡出动画（1→0）；容器宽度收缩动画（26→0）；三个动画同时进行100ms Linear，形成"被吸进去"的视觉效果
- 顶部栏去弹簧绝对定位（按用户要求）：去掉leftSpring/rightSpring弹簧元素，改用绝对定位；红绿灯anchors.left+leftMargin；中间组anchors.horizontalCenter居中；右边图标anchors.right+rightMargin；右边图标组width=min(childrenRect.width,可用空间)双重保障不超出边框；所有动画保持100ms Linear及时响应；无弹簧结构，变化丝滑流畅
- 顶部栏Row+线性弹簧（按用户要求解决重叠问题）：改回Row结构，Row自动排列元素不会重叠；红绿灯+左弹簧+中间组+右弹簧+右边图标；弹簧动画用线性100ms Linear，无弹簧感；右边图标组clip:true确保不超出边框；解决绝对定位导致的右边图标覆盖状态框问题；所有动画保持100ms Linear及时响应
- 底部栏Row结构（按用户要求）：操作工具栏和底部栏从RowLayout改为Row结构，和顶部栏保持一致；操作工具栏：语言方向+弹簧+操作按钮组（复制/音量/收藏/历史）；底部栏：Smart-Select开关+弹簧+窗口尺寸；所有动画保持100ms Linear；底部切换按钮正常显示
- 底部栏布局修正（按用户要求）：操作工具栏左边改为Smart-Select切换按钮（不是EN➔ZH），右边操作图标在最右边；底部栏左边改为EN➔ZH，右边窗口尺寸；避免smartSelectGroup重名；操作图标固定在最右边；切换按钮正确显示Smart-Select开关
- 离线翻译修复（按用户反馈）：修复选择offline引擎时离线翻译用不了的问题；之前只有源语言为英文时才查离线词库，选择offline引擎时直接返回原文；现在选择offline引擎时始终使用离线词库查询；命中返回完整单词详情（音标/释义/词形变化/考试标签）；未命中或不支持该语言返回原文；不调用在线翻译；离线词库811.9MB ECDICT 340万词条正常加载

### 项目骨架初始化：CMake + Qt 6 Quick + C++20
- 透明窗口实现：Frameless + per-pixel alpha 圆角
- TranslatorWindow 窗口管理类：药丸/卡片状态机、窗口几何管理、尺寸动画
- AppState 状态管理：翻译结果、设置、收藏、字号等 QML 上下文属性
- QML 设计系统：DesignTokens 单例（颜色/间距/圆角/字号/动画 Token）
- GlassSurface 毛玻璃表面组件：半透明背景 + 圆角 + 边框 + 投影 + 自动漫游高光
- TrafficLights 红绿灯组件：清空/最小化/刷新
- HoverScrollText 悬停滚动文本组件：溢出检测 + 双向平滑滚动
- MarqueeText 循环跑马灯组件：药丸模式译文无限滚动
- IconButton 圆形图标按钮组件
- LanguageSelector 语言选择器组件
- SearchInput 搜索输入框组件
- WordDetailView 单词详情组件：音标/词性/释义/例句/同反义词/美英发音
- PillView 药丸视图：全圆角纯黑 + 搜索框 + 原文|译文跑马灯 + 操作按钮
- CardView 卡片视图：顶部栏 + Flickable 内容区 + 操作工具栏 + 底部栏 + 8向拉伸手柄
- SettingsView 设置页面：引擎选择/API密钥/划词开关/自动发音/紧凑模式/透明度/字体大小
- Main.qml 状态机：pill ↔ card 视图切换过渡动画 + 尺寸动画
- 16 个 SVG 图标资源（lucide 风格描边图标）
- Demo 翻译数据：Efficient 单词完整释义

### 翻译引擎
- TranslationManager 翻译管理器：统一 Provider 接口，可插拔引擎
- GeminiProvider：Gemini 2.0 Flash API，支持单词详情 JSON 解析
- DeepLProvider：DeepL API（Free/Pro 自动识别）
- YoudaoProvider：有道翻译 API，SHA256 签名，单词详情解析
- 离线模式：原文回退

### 数据持久化
- DatabaseManager：SQLite 数据库管理
- 历史记录表：自动保存翻译记录，支持查询/清空/删除
- 收藏表：生词收藏，支持添加/删除/查询
- 数据库路径：%APPDATA%/Linguist/lingust.db

### 全局划词
- SelectionManager：Clipboard 方案全局划词翻译
- 模拟 Ctrl+C 复制选中文本
- GetClipboardSequenceNumber 安全恢复剪贴板
- 异步等待剪贴板变化（短超时轮询）

### TTS 发音
- SAPI.SpVoice 语音合成（mshta vbscript 调用，启动快）
- 美式英语：Microsoft Zira Desktop
- 英式英语：Microsoft Hazel Desktop
- 中文：Microsoft Huihui Desktop
- 美音/英音按钮切换

### 系统集成
- TrayManager：系统托盘图标 + 右键菜单
- 托盘菜单：显示主窗口/截图翻译/设置/退出
- 开机启动：注册表 HKCU\...\Run
- QApplication 替代 QGuiApplication（支持 Widgets/托盘）
- setQuitOnLastWindowClosed(false)：关窗不退出

### 截图 OCR 框架
- CaptureManager：全屏截图（QScreen::grabWindow）
- OcrManager：OCR 引擎管理
- IOcrProvider：OCR Provider 接口（可插拔）
- 待实现：截图覆盖层、区域选择、Windows OCR / PaddleOCR

### [Fixed]
- GlassSurface.qml: `Qt5Compat.GraphicalEffects` → `QtQuick.Effects`（Qt 6.11 内置，无需 5Compat 模块）
- CMakeLists.txt: 移除 `Qt6::5Compat` 依赖（用户未安装该模块）
- TranslatorWindow.cpp: 移除 `setAttribute(Qt::WA_TranslucentBackground)`（QWindow 无此方法，改用 `setColor(Qt::transparent)`）
- TranslatorWindow.cpp: 手动定义 Windows 11 DWM 常量（`DWMWA_SYSTEMBACKDROP_TYPE`/`DWMSBT_TRANSIENTWINDOW` 等），兼容 MinGW 旧版头文件
- Application.cpp: 添加 `#include <QQuickItem>`（修复 qobject_cast 不完全类型错误）
- CMakeLists.txt: 添加 MSVC `/utf-8` 编译选项、输出目录配置
- 全部 QML 文件: Row/Column → RowLayout/ColumnLayout，修复布局属性误用
- 窗口圆角：放弃系统级毛玻璃（DWM Acrylic 与 per-pixel alpha 冲突），改用 QML 模拟毛玻璃质感
- QML 颜色：全部改用十六进制 `#aarrggbb`（Qt 6.11 rgba() 字符串解析报错）
- Singleton 注册：C++ qmlRegisterSingletonType 手动注册（QTP0004 自动识别漏识别 pragma Singleton）
- moc 崩溃：SelectionManager.h 移除 Windows 特定类型声明（HWND/DWORD 导致 moc 访问冲突）
- include 路径：统一相对路径，修复跨目录引用

### [Docs]
- README.md 项目说明与构建指南（含 MSVC/MinGW 双路径）
- docs/ARCHITECTURE.md 系统架构设计
- docs/CHANGELOG.md 更新日志
- AGENTS.md 项目规约

### [Build]
- Qt 6.11.2 + MinGW 13.1 + Ninja，输出 `build/bin/lingust.exe`
- 依赖模块：Core/Gui/Qml/Quick/QuickControls2/Network/Sql/Widgets
- 编译参数：-j 2（避免 cc1plus out of memory）

---

## 版本说明

- **v0.1.x**：UI 预览阶段，实现药丸/卡片视觉效果与状态切换
- **v0.2.x**：接入翻译引擎（Gemini/DeepL/有道/离线）✅
- **v0.3.x**：全局划词（UIA + Clipboard + OCR）✅（Clipboard 方案）
- **v0.4.x**：截图 OCR 与原地对照（框架已搭，待完善）
- **v0.5.x**：生词本、历史记录、TTS 发音 ✅
- **v0.6.x**：音乐控制（GSMTC）（待实现）
- **v1.0.0**：托盘、开机启动、自动更新、崩溃恢复，正式发布（托盘/开机启动 ✅）
