# Linguist RESTful API 接口规范

所有接口均通过 HTTP POST / GET 调用，响应体统一采用 JSON 格式，字符集编码为 UTF-8。

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
