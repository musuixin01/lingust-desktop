# Linguist RESTful API 接口规范

翻译请求一致性：语言切换会创建新的请求代次。AppState、TranslationManager 与各在线 Provider 都会忽略旧代次的迟到结果；重试始终发送给当前实际工作的 Provider，降级后不会回跳到首选引擎。离线 ECDICT 词典补充只应用于英语到简体中文方向。

窗口内部接口（本轮）：`WindowSurface` 传递 pill/color/opacity；`WindowResizeSession` 提供原生 hitTest/pointerPosition，以及 resizeStarted/resizeMoved/resizeEnded/contentInvalidated/pointerInput 回调。平台层把物理指针坐标换算为逻辑坐标，Core 将事件投递给离屏 QML 场景。Win32 调用只在 Platform。此契约不新增任何 HTTP 接口。

窗口内部能力补充：`TranslatorWindow.usesNativeSurface` 为恒定只读布尔值，指示宿主统一绘制外壳；Main.qml 的 `shellColor`、`shellOpacity` 传递主题值。此项是 C++/QML 内部契约，不是 HTTP 接口。

文本状态内部接口：`AppState.sourceText` 是卡片搜索、药丸搜索与划词原文的统一数据源。`setSourceText(text)` 接收非空输入；空白输入转入 `clearText()`。`clearText()` 同步终止界面加载态并清除译文及全部词典派生字段。翻译回调在原文为空时丢弃迟到结果，避免清空后内容回弹。此项不新增 HTTP 接口。

所有接口均通过 HTTP POST / GET 调用，响应体统一采用 JSON 格式，字符集编码为 UTF-8。

## 账户认证 API（v1）

桌面端读取 `LINGUIST_AUTH_BASE_URL` 并仅接受 HTTPS 地址。认证服务可以用 `{ ... }` 或 `{ "data": { ... } }` 包装成功响应；错误建议统一返回 `{ "error": { "code": "...", "message": "..." } }`。所有接口应接受 `X-Request-Id` 和 `X-Client-Version`，敏感接口由服务端实施 IP、设备、账号多维限流。

### 会话响应

完成登录的接口统一返回：

```json
{
  "access_token": "short-lived-token",
  "refresh_token": "rotating-token",
  "expires_in": 900,
  "user": {
    "id": "opaque-random-id",
    "display_name": "用户昵称",
    "email": "user@example.com",
    "phone": "+86138****5678",
    "avatar_url": "https://cdn.example.com/avatar",
    "provider": "password"
  }
}
```

`access_token` 建议不超过 15 分钟；每次刷新都轮换 `refresh_token`，服务端需检测旧令牌重用并撤销整个令牌族。

### `POST /v1/auth/login/password`

请求：`identifier`、`password`、`device_name`、`platform`。`identifier` 可以是已验证邮箱或手机号。失败响应不得暴露账号是否存在。

### `POST /v1/auth/register/password`

请求：`identifier`、`password`、`display_name`、`locale`、`platform`。若要求邮箱验证，可以返回：

```json
{ "verification_required": true }
```

验证完成后用户从登录入口建立会话；服务端不得返回密码或密码摘要。

### `POST /v1/auth/password/reset`

请求：`email`、`locale`。无论邮箱是否存在均返回 202，避免账号枚举；邮件中的一次性令牌应短期有效且只能使用一次。

### `POST /v1/auth/phone/code`

请求：`phone`、`purpose`（`login` 或 `register`）、`locale`。成功返回 `{ "retry_after": 60 }`。验证码必须在 Redis 等短期存储中保存摘要、限制错误次数并在验证后立即销毁。

### `POST /v1/auth/phone/verify`

请求：`phone`、`code`、`purpose`、`display_name`、`platform`。验证成功返回统一会话响应。

### `POST /v1/auth/wechat/start`

请求：`platform`、`locale`。服务端创建随机 state 与一次性事务，返回：

```json
{
  "transaction_id": "opaque-one-time-id",
  "authorize_url": "https://open.weixin.qq.com/connect/qrconnect?..."
}
```

微信 AppSecret 只能存在于服务端。桌面端使用系统浏览器打开 `authorize_url`。

### `GET /v1/auth/wechat/status?transaction_id=...`

等待时返回 HTTP 202 或 `{ "status": "pending" }`；完成后返回统一会话响应。事务应在 3 分钟内过期且成功后不可再次兑换。

### `POST /v1/auth/token/refresh`

请求：`refresh_token`、`platform`。成功返回新的统一会话响应并轮换刷新令牌；401/403 表示本机会话必须清除，临时 5xx 或断网不得让客户端丢失已保存凭据。

### `POST /v1/auth/logout`

请求头：`Authorization: Bearer <access_token>`。服务端撤销当前刷新会话。客户端会先清除本机凭据，因此网络失败不会阻止用户退出本机。

### 桌面内部接口

`AuthManager` 向 QML 暴露 `configured/authenticated/busy`、脱敏用户资料、验证码冷却时间和单一状态消息。QML 只能调用登录、注册、验证码、微信、重置密码、恢复和退出等语义方法，不能读取访问令牌或刷新令牌。`DatabaseManager::setOwnerId()` 只接受认证服务返回的用户 ID，并将历史与收藏查询限制在对应命名空间。

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
  "antonyms": ["inefficient", "unproductive"],
  "engine": "gemini"
}
```

### 桌面端免密在线兜底（2026-09-10）

`TranslationManager` 仍通过 `ITranslationProvider` 分发请求。所选引擎因未配置密钥或服务错误而不可用时，最后切换到 `FallbackProvider`，并行组合下列公开接口：

- MyMemory `GET /get?q=...&langpair=...`：生成主翻译；请求文本限制在 500 UTF-8 字节以内。
- Tatoeba `GET /v1/sentences`：带目标语言译文的双语例句，优先 4–14 词的完整句子。
- Datamuse `GET /words?rel_syn=...` / `rel_ant=...`：最多各 5 个同义词和反义词。

各请求独立超时并汇总，单项失败不会丢弃其他已成功字段。本地 ECDICT 在在线结果返回后补足中文释义、音标、词形和标签。以上接口会接收用户查询的文本或英文单词；参考 [MyMemory 规范](https://mymemory.translated.net/doc/spec.php)、[Tatoeba API](https://api.tatoeba.org/) 与 [Datamuse API](https://www.datamuse.com/api/)。

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

### 翻译语言

- `sourceLang` / `setSourceLang(code)`：接受 `auto`、`zh`、`en`、`ja`、`ko`、`fr`、`de`、`es`、`pt`、`it`、`ru`、`ar`、`vi`、`th`；常见中文地区代码会归一化。已有普通文本时，设置成功后立即按新方向重译；若与目标语言相同，则把旧源语言移到目标侧形成有效方向。
- `targetLang` / `setTargetLang(code)`：接受同一组实际语言，不接受 `auto`。已有普通文本时立即重译；若与明确源语言相同，则把旧目标语言移到源侧。有道 Provider 将内部 `zh` 转换为接口要求的 `zh-CHS`；DeepL 在源语言为 `auto` 时省略 `source_lang`。
- `swapLanguages()`：普通语言直接交换；源语言为 `auto` 时，将当前目标语言移到源语言，并选择中文或英文作为新目标。已有普通文本时交换完成后立即重译。
- 翻译请求采用“最新请求生效”规则：Provider 丢弃自身旧回复，`TranslationManager` 忽略旧引擎结果与过期重试，`AppState` 忽略旧的延迟展示回调。切换语言后不会被先前方向的迟到结果覆盖。

### 桌面截图翻译状态

- `AppState::requestScreenshot()`：请求 QML 进入真实屏幕框选；卡片、药丸、托盘和 `Ctrl+Shift+S` 共用此入口。
- `CaptureManager::startScreenshotMode()`：抓取鼠标所在显示器并发布预览 URL 与屏幕几何。
- `CaptureManager::confirmSelection(x, y, width, height)`：按 DPI 裁剪选区并发出 `screenshotCaptured(QImage)`。
- `OcrManager::recognize(image, language)` / `IOcrProvider::recognize(image, language)`：识别调用同时传入当前源语言；Provider 可以据此选择对应语言模型。
- `WindowsOcrProvider`：实现 `IOcrProvider`，调用 Windows 内置 OCR；优先按 `en-US` / `zh-Hans` 创建识别引擎，对小图在系统最大尺寸内放大后识别，结果通过 `recognitionReady(text)` 返回。
- `ocrLines`、`ocrImagePreview`、`isOcrProcessing`、`ocrStatus`：供现有卡片显示逐行内容、原图以及识别/翻译状态。OCR 行由独立 TranslationManager 串行翻译，数组中每个 `{src, dst}` 始终是一组真实对应关系。
- `screenshotMode`、`exitScreenshotMode()`：控制现有 `CardView` 在普通翻译正文与截图双语正文之间切换；OCR 原文和译文只写入 `ocrLines`，不会覆盖普通搜索框的 `sourceText/translatedText`。
- `openHistoryItem(item)`：普通历史项重新进入文本翻译；`kind=screenshot` 时从持久化原文、译文和预览地址恢复 `ocrLines`，在同一主卡片中重新显示逐行对照。
- `DatabaseManager::addHistory(..., kind, previewUrl)`：`kind` 默认为 `text`；截图翻译完成时写入 `screenshot`。旧数据库启动时以增量迁移补充 `kind` 和 `preview_url` 列。

### 系统媒体控制

- `prevTrack()` / `nextTrack()`：分别发出 `musicPreviousRequested` / `musicNextRequested`，由 Windows Platform 层调用当前 GSMTC 会话的上一首或下一首操作。药丸与音乐卡片共用同一控制链路。

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
- **`musicPlaying`** (`bool`, READ): 当前系统播放器是否处于播放状态。
- **`trackTitle`** (`QString`, READ): 当前曲目标题（支持系统媒体歌曲名）。
- **`trackArtist`** (`QString`, READ): 当前艺术家/歌手姓名。
- **`trackAlbum`** (`QString`, READ): 所属专辑名称。
- **`trackDuration`** (`int`, READ): 总时长（单位：秒）。
- **`trackPosition`** (`int`, READ): 当前播放进度（单位：秒）。
- **`currentLyric` / `currentLyricTranslation`** (`QString`, READ): 保留的歌词扩展接口；GSMTC 不提供歌词，当前系统媒体实现返回空字符串。
- **`systemMediaConnected`** (`bool`, READ): 是否检测到 Windows 当前系统媒体会话。
- **`coverArtUrl`** (`QString`, READ): GSMTC 当前媒体缩略图转换后的圆形 PNG Data URL；不可用时为空。
- **`musicLyrics`** (`QVariantList`, READ): 歌词行列表，每项包含 `timeMs` 和 `text`。
- **`currentLyricIndex`** (`int`, READ): 当前同步歌词行下标；无歌词时为 `-1`。
- **`lyricsSynchronized`** (`bool`, READ): 当前歌词是否包含可用于进度定位的时间戳。
- **`pillMusicMode`** (`bool`, READ/WRITE): 药丸当前是否处于灵动岛音乐模式。

### Q_INVOKABLE 操作方法 (AppState Invokables)
- **`toggleMusicPlay()`**: 切换播放/暂停。
- **`nextTrack()`**: 切换至下一曲。
- **`prevTrack()`**: 切换至上一曲。
- **`seekTrack(int seconds)`**: 跳转播放进度至指定秒数。
- **`setPillMusicMode(bool enabled)`**: 设定药丸是否切为灵动岛音乐模式。
- **`togglePillMusicMode()`**: 快速在翻译胶囊与音乐胶囊之间切换。

### Platform 底层接口 (WindowsMediaManager)
- **`start()`**：启动常驻 `SystemMediaBridge.ps1`，每 500ms 读取当前 GSMTC 会话，仅在快照变化时向 Core 推送状态。
- **`sendPlay()` / `sendPause()` / `sendToggle()`**：向当前系统媒体会话发送对应播放操作。
- **`sendNext()` / `sendPrevious()`**：向当前系统媒体会话发送上下曲操作。
- **`sendSeek(int seconds)`**：播放器提供时间轴时请求跳转到指定秒数。
- 桥接脚本使用 Windows PowerShell 5.1 的 Windows Runtime 投影；脚本随桌面可执行文件复制，子进程以无窗口方式运行。

### 歌词 Provider (`ILyricsProvider` / `LrclibLyricsProvider`)
- `requestLyrics(title, artist, album, durationSeconds)`：向 LRCLIB `/api/get` 顺序请求歌词，缺失时等待 300ms 后调用 `/api/search`，避免并行请求触发公共服务限流。
- `lyricsReady(...)`：返回解析后的同步或普通歌词、匹配歌曲时长；结果以标准化歌名与歌手作为当前进程缓存键。
- 切歌会中止旧请求；返回结果必须再次匹配当前歌名与歌手后才写入 `MediaSessionService`，避免快速切歌时显示上一首歌词。
- `MediaSessionService` 计算当前同步歌词时对播放位置增加 650ms 预读偏移；该偏移只影响当前行选择，不修改媒体进度、进度环或跳转位置。



## 7. 桌面窗口缩放入口（2026-09-09）

桌面缩放以文档顶部的 `beginInteractiveResize/endInteractiveResize/isResizing` 为准。参数仍沿用 Qt.LeftEdge/RightEdge/TopEdge/BottomEdge 位组合；QML 不直接调用 Win32 API。

`WordDetailView.fontScale`：默认绑定 DesignTokens.fontScale 的可配置排版比例，用于同一组件在不同字号下验证换行边界。
