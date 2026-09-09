# Linguist RESTful API 接口规范

窗口内部接口（本轮）：`WindowSurface` 传递 pill/color/opacity；`WindowResizeSession` 提供原生 hitTest/pointerPosition，以及 resizeStarted/resizeMoved/resizeEnded/contentInvalidated/pointerInput 回调。平台层把物理指针坐标换算为逻辑坐标，Core 将事件投递给离屏 QML 场景。Win32 调用只在 Platform。此契约不新增任何 HTTP 接口。

窗口内部能力补充：`TranslatorWindow.usesNativeSurface` 为恒定只读布尔值，指示宿主统一绘制外壳；Main.qml 的 `shellColor`、`shellOpacity` 传递主题值。此项是 C++/QML 内部契约，不是 HTTP 接口。

所有接口均通过 HTTP POST / GET 调用，响应体统一采用 JSON 格式，字符集编码为 UTF-8。

---

## TranslatorWindow 交互缩放（桌面内部接口，2026-09-09）

TranslatorWindow 对 QML 的方法名保持不变，内部窗口宿主已改为 QWindow + 离屏 QQuickWindow。`WindowResizeSession` 新增 `initialize/nativeGeometry/scaleFactor/targetGeometry/present/end`，Windows 实现在 Platform 层一次提交物理几何和 ARGB 帧。

- `beginInteractiveResize(int edges)`：由 QML 缩放手柄启动一次可中断缩放。`edges` 使用 `Qt::Edges` 位组合；方法停止模式尺寸动画，保存起始窗口/指针几何，待提交帧期间合并高频位置。Windows 通过注入的 WindowResizeSession 使用物理像素固定对侧边界。
- `endInteractiveResize()`：松手或取消时应用最后一个位置并结束缩放态。所有边/角手柄必须在 `released` 和 `canceled` 路径调用。
- `isResizing`（只读）：交互拉伸状态，不改变圆角，不属于业务状态。
- `setResizeSession(std::unique_ptr<WindowResizeSession>)`：仅 C++ 装配接口，由 Application 注入 Windows 实现；Core 与 QML 不调用 Win32。未注入时保留 Qt 逻辑坐标回退。
- 原 `beginSystemResize` 已移除。以上为 QML/C++ 内部桥接接口，不是 REST API。

---

## 1. 健康检查与环境变量探测

### `GET /api/health`

**请求参数**：无

**成功响应**：
```json
{
  "status": "ok",
  "timestamp": 1725321600000,
  "hasGeminiKey": true,
  "nodeEnv": "production"
}
```

---

## 2. 核心文本翻译与多引擎分发

### `POST /api/translate`

**请求体（Request Body）**：
```json
{
  "text": "Efficient",
  "sourceLang": "auto",
  "targetLang": "ZH",
  "engine": "gemini",
  "keys": {
    "geminiKey": "可选自定义Key",
    "deeplKey": "可选DeepL Key",
    "youdaoAppKey": "可选有道AppKey",
    "youdaoAppSecret": "可选有道AppSecret"
  }
}
```

**成功响应（Word 模式）**：
```json
{
  "id": "res-1725321600000",
  "sourceText": "Efficient",
  "translatedText": "高效的；有能力的",
  "sourceLang": "EN",
  "targetLang": "ZH",
  "isWord": true,
  "phonetic": {
    "us": "/ɪˈfɪʃnt/",
    "uk": "/ɪˈfɪʃnt/"
  },
  "definitions": [
    {
      "partOfSpeech": "adj.",
      "meaning": "高效的；有能力的；运作良好的"
    }
  ],
  "examples": [
    {
      "src": "An efficient floating translator designed for focus.",
      "dst": "专为专注打造的高效桌面悬浮翻译卡片。"
    }
  ],
  "synonyms": ["effective", "productive"],
  "engine": "gemini"
}
```

---

## 3. 屏幕截图视觉识别与中英逐行对照

### `POST /api/ocr-translate`

**请求体（Request Body）**：
```json
{
  "image": "data:image/png;base64,iVBORw0KGgoAAAANS...",
  "extractedText": "可选的本地DOM预提取文本",
  "sourceLang": "auto",
  "targetLang": "ZH"
}
```

**成功响应**：
```json
{
  "detectedSourceLang": "EN",
  "targetLang": "ZH",
  "fullOriginalText": "The sun rises every morning, bringing a brand new day.\nWe all have dreams in our hearts.",
  "fullTranslatedText": "太阳每天早晨升起，带来崭新的一天。\n我们的心中都有梦想。",
  "lines": [
    {
      "src": "The sun rises every morning, bringing a brand new day.",
      "dst": "太阳每天早晨升起，带来崭新的一天。"
    },
    {
      "src": "We all have dreams in our hearts.",
      "dst": "我们的心中都有梦想。"
    }
  ]
}
```

---

## 4. 引擎连通性与 API 密钥测试

### `POST /api/test-engine` 或 `POST /api/test-connection`

**请求体（Request Body）**：
```json
{
  "engine": "gemini",
  "keys": {
    "geminiKey": "AIzaSy..."
  }
}
```

**成功响应**：
```json
{
  "success": true,
  "message": "Gemini API 连接成功！模型响应: OK"
}
```

**失败响应（HTTP 400/500）**：
```json
{
  "success": false,
  "message": "未检测到 Gemini API Key，请先输入密钥"
}
```

---

## 5. C++ / QML 状态与发音控制 (AppState Bridge)

### 桌面翻译加载状态
- **`isTranslating`** (`bool`, READ)：Core 已有的翻译进行中状态。卡片工具栏及加载提示使用此属性，`AppState` 未暴露 `isLoading`。本次仅修正 UI 绑定，不新增接口。

### 划词交互控制
- **`selectionTranslation`** (`bool`): 控制是否监听 Windows 全局鼠标划词事件（`WH_MOUSE_LL` 钩子开关）。
- **`selectionTriggerMode`** (`QString`):
  - `"auto"`（默认）：**关气泡，划词直出**。选中文本直接弹出主翻译卡片，跳过悬浮小气泡。
  - `"icon"`：**微气泡模式**。选中文本在光标右上方仅浮现微型快捷胶囊，点击后再展开完整卡片。

### 语音合成与发音 (TTS)
- **`speak(text, lang, accent)`**:
  - `text` (`QString`, 可选)：朗读文本。若为空自动按优先级选取 `translatedText` 或 `sourceText`；
  - `lang` (`QString`, 可选)：语言代码（`"en"`、`"zh"` 等）。默认自动适配当前目标语言；
  - `accent` (`QString`, 默认 `"us"`)：口音控制。支持 `"us"`（美音，Zira/David）与 `"uk"`（英音，Hazel/George）；
  - **实现架构**：基于 Windows 原生 PowerShell `System.Speech.Synthesis` + `SAPI.SpVoice` 双引擎降级，文本经 Base64 编码穿透，异步无窗口闪烁运行。

---

## 6. 灵动岛音乐与系统媒体接口 (`MediaSessionService & AppState`)

### QML 属性接口 (AppState Properties)
- **`musicPlaying`** (`bool`, READ): 当前系统/内置播放器是否处于播放状态。
- **`trackTitle`** (`QString`, READ): 当前曲目标题（支持系统媒体歌曲名）。
- **`trackArtist`** (`QString`, READ): 当前艺术家/歌手姓名。
- **`trackAlbum`** (`QString`, READ): 所属专辑名称。
- **`trackDuration`** (`int`, READ): 总时长（单位：秒）。
- **`trackPosition`** (`int`, READ): 当前播放进度（单位：秒）。
- **`currentLyric`** (`QString`, READ): 当前时间戳激活的歌词原文字符串。
- **`currentLyricTranslation`** (`QString`, READ): 当前时间戳激活的歌词中译文字符串。
- **`pillMusicMode`** (`bool`, READ/WRITE): 药丸当前是否处于灵动岛音乐模式。

### Q_INVOKABLE 操作方法 (AppState Invokables)
- **`toggleMusicPlay()`**: 切换播放/暂停。
- **`nextTrack()`**: 切换至下一曲。
- **`prevTrack()`**: 切换至上一曲。
- **`seekTrack(int seconds)`**: 跳转播放进度至指定秒数。
- **`setPillMusicMode(bool enabled)`**: 设定药丸是否切为灵动岛音乐模式。
- **`togglePillMusicMode()`**: 快速在翻译胶囊与音乐胶囊之间切换。

### Platform 底层接口 (WindowsMediaManager)
- **`WindowsMediaManager::instance().sendPlay()`**: 调用 Windows GSMTC API `TryPlayAsync()`。
- **`WindowsMediaManager::instance().sendPause()`**: 调用 Windows GSMTC API `TryPauseAsync()`。
- **`WindowsMediaManager::instance().sendToggle()`**: 调用 Windows GSMTC API `TryTogglePlayPauseAsync()`。
- **`WindowsMediaManager::instance().sendNext()`**: 调用 Windows GSMTC API `TrySkipNextAsync()`。
- **`WindowsMediaManager::instance().sendPrevious()`**: 调用 Windows GSMTC API `TrySkipPreviousAsync()`。



## 7. 桌面窗口缩放入口（2026-09-09）

桌面缩放以文档顶部的 `beginInteractiveResize/endInteractiveResize/isResizing` 为准。参数仍沿用 Qt.LeftEdge/RightEdge/TopEdge/BottomEdge 位组合；QML 不直接调用 Win32 API。

`WordDetailView.fontScale`：默认绑定 DesignTokens.fontScale 的可配置排版比例，用于同一组件在不同字号下验证换行边界。
