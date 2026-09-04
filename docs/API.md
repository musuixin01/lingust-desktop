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

## 5. Electron 原生 IPC 接口规范 (Desktop IPC Bridge)

在桌面端环境下，渲染进程通过 `window.electronAPI`（由 `/electron/preload.ts` 注入）与主进程进行类型安全的双向异步交互：

| 接口方法 / 属性 | 参数签名 | 功能说明 |
| :--- | :--- | :--- |
| `isElectron` | `boolean` (只读) | 当前是否处于 Electron 原生桌面客户端环境 |
| `platform` | `'win32' \| 'darwin' \| 'linux'` | 操作系统平台标识 |
| `minimizeWindow()` | `() => Promise<void>` | 最小化窗口至任务栏 |
| `maximizeWindow()` | `() => Promise<void>` | 切换窗口最大化 / 还原 |
| `closeWindow()` | `() => Promise<void>` | 隐藏窗口至系统托盘 (Tray) 或退出 |
| `setAlwaysOnTop(flag)` | `(flag: boolean) => Promise<void>` | 设置窗口是否永远处于最前端顶层 |
| `syncWindowSize(w, h)` | `(w: number, h: number) => Promise<void>` | 动态同步调整宿主原生无边框窗口像素尺寸 |
| `captureDesktopScreen()` | `() => Promise<string>` | 调用底层 `desktopCapturer` 返回主屏幕截图 Base64 DataURL |
| `onShortcutTriggered(cb)`| `(cb: (action: string) => void) => () => void` | 监听全局快捷键触发事件（如 `'screenshot'`） |
| `onTrayAction(cb)` | `(cb: (action: string) => void) => () => void` | 监听系统托盘点击菜单指令（如 `'open-settings'`） |

---

## 6. Windows 客户端下载与分片传输接口规范

针对 Google Cloud Run 容器代理 32MB 单次响应上限，后端与前端设计了**内存安全流式分片传输体系**：

### 6.1 查询打包状态与分片元数据

`GET /api/download/status`

**响应示例**：
```json
{
  "available": true,
  "filename": "Linguist-Windows-v1.3.0-x64.zip",
  "sizeBytes": 196949910,
  "sizeMb": "187.8 MB",
  "chunkSize": 15728640,
  "totalChunks": 13,
  "updatedAt": "2026-09-04T10:22:15.114Z",
  "downloadUrl": "/api/download/windows"
}
```

### 6.2 获取二进制数据分片

`GET /api/download/chunk/:index`

- **参数**：`:index` 分片下标（0 到 `totalChunks - 1`）
- **响应头**：
  - `Content-Type`: `application/octet-stream`
  - `Content-Length`: 当前分片字节数（通常 15MB，末尾分片自适应截断）
  - `X-Chunk-Index`: 分片索引
  - `X-Total-Chunks`: 总分片数
  - `X-Total-Size`: 总文件字节数
- **客户端行为**：前端通过 `fetch()` 逐片请求并记录进度条，完成后在浏览器内存中组装为 `Blob`，并通过 `URL.createObjectURL(blob)` 触发无损保存。

### 6.3 传统直链下载

`GET /api/download/windows`

- 用于本地开发或直连无响应上限的容器环境，直接流式下载完整 ZIP 压缩包。


