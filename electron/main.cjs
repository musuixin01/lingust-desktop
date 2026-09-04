/**
 * Linguist 桌面客户端 - Electron 主进程
 *
 * 职责：
 *  1. 创建无边框、透明、置顶的悬浮卡片窗口（窗口尺寸跟随卡片，边缘留白放阴影/圆角）
 *  2. 内嵌复用现有 Express 后端（dist/server.cjs）提供翻译/OCR API
 *  3. 系统托盘常驻 + 全局快捷键
 *  4. 通过 IPC 实现卡片拖动窗口、缩放窗口、透明度、置顶等桌面能力
 *
 * 运行方式：
 *  - 开发：npm run dev 起 Vite dev server(3000) 后，npm run desktop（自动复用 3000）
 *  - 生产：npm run build 后，npm run desktop（自动启动内置后端并加载本地 dist）
 */
const { app, BrowserWindow, Tray, Menu, ipcMain, nativeImage, screen, globalShortcut } = require('electron');
const path = require('path');
const http = require('http');

// 透明窗口留白（阴影/圆角安全区），必须与前端 FloatingTranslatorCard 的 WINDOW_EDGE 一致
const WINDOW_EDGE = 8; // 透明留白（窗口背景透明，不显示背景框），给卡片圆角与阴影呼吸空间
const DEFAULT_SIZE = { width: 380, height: 490 };
const DEFAULT_OPACITY = 0.98;

let mainWindow = null;
let tray = null;
let dragState = null;
let appQuitting = false;

// ---------------------------------------------------------------------------
// 内置后端（生产环境：直接 require 已 bundle 的 dist/server.cjs，复用 startServer）
// ---------------------------------------------------------------------------
function startEmbeddedBackend() {
  return new Promise((resolve, reject) => {
    process.env.LINGUIST_EMBEDDED = '1';
    process.env.NODE_ENV = 'production';
    try {
      const serverPath = path.join(__dirname, '..', 'dist', 'server.cjs');
      const { startServer } = require(serverPath);
      const port = 31000 + Math.floor(Math.random() * 5000);
      startServer({
        port,
        host: '127.0.0.1',
        staticDir: path.join(__dirname, '..', 'dist'),
      })
        .then(() => resolve(port))
        .catch(reject);
    } catch (err) {
      reject(err);
    }
  });
}

function httpGet(url) {
  return new Promise((resolve) => {
    const req = http.get(url, (res) => {
      res.resume();
      resolve(res.statusCode);
    });
    req.on('error', () => resolve(null));
    req.setTimeout(1500, () => {
      req.destroy();
      resolve(null);
    });
  });
}

// 决策后端来源：显式 dev URL > 已有 dev server(3000) > 内置后端
async function resolveBackend() {
  if (process.env.LINGUIST_DEV_URL) {
    return { url: process.env.LINGUIST_DEV_URL };
  }
  if (!app.isPackaged) {
    const code = await httpGet('http://127.0.0.1:3000/api/health');
    if (code === 200) {
      return { url: 'http://127.0.0.1:3000' };
    }
  }
  const port = await startEmbeddedBackend();
  return { url: `http://127.0.0.1:${port}` };
}

// ---------------------------------------------------------------------------
// 窗口
// ---------------------------------------------------------------------------
function createWindow(url) {
  mainWindow = new BrowserWindow({
    width: DEFAULT_SIZE.width + WINDOW_EDGE * 2,
    height: DEFAULT_SIZE.height + WINDOW_EDGE * 2,
    frame: false,
    transparent: true,
    resizable: false,
    movable: true,
    minimizable: true,
    maximizable: false,
    fullscreenable: false,
    alwaysOnTop: true,
    skipTaskbar: false,
    hasShadow: false, // Windows 透明窗口下 hasShadow 产生黑色边框，阴影由卡片 CSS box-shadow 提供
    show: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.cjs'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
      spellcheck: false,
    },
  });

  // 默认定位：主屏右上角
  const { workArea } = screen.getPrimaryDisplay();
  const x = workArea.x + workArea.width - DEFAULT_SIZE.width - WINDOW_EDGE * 2 - 28;
  const y = workArea.y + 32;
  mainWindow.setPosition(Math.round(x), Math.round(y));

  mainWindow.loadURL(url);

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  // 关闭 = 隐藏到托盘（悬浮常驻），真正退出走托盘菜单
  mainWindow.on('close', (e) => {
    if (!appQuitting) {
      e.preventDefault();
      mainWindow.hide();
    }
  });

  mainWindow.webContents.setWindowOpenHandler(() => ({ action: 'deny' }));
}

function showMain() {
  if (!mainWindow) return;
  mainWindow.show();
  mainWindow.focus();
}

function toggleMain() {
  if (!mainWindow) return;
  if (mainWindow.isVisible() && mainWindow.isFocused()) {
    mainWindow.hide();
  } else {
    showMain();
  }
}

// ---------------------------------------------------------------------------
// 托盘
// ---------------------------------------------------------------------------
function createTray() {
  const iconPath = path.join(__dirname, '..', 'assets', 'icon.png');
  let icon = nativeImage.createFromPath(iconPath);
  if (icon.isEmpty()) {
    icon = nativeImage.createFromDataURL(
      'data:image/svg+xml;base64,' +
        Buffer.from(
          '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><rect width="32" height="32" rx="8" fill="#3b82f6"/><text x="16" y="23" font-size="20" font-family="Arial" font-weight="bold" fill="#ffffff" text-anchor="middle">L</text></svg>'
        ).toString('base64')
    );
  }
  tray = new Tray(icon.resize({ width: 18, height: 18 }));
  tray.setToolTip('Linguist 悬浮翻译');
  tray.setContextMenu(
    Menu.buildFromTemplate([
      { label: '显示悬浮卡片', click: showMain },
      { label: '隐藏悬浮卡片', click: () => mainWindow && mainWindow.hide() },
      { type: 'separator' },
      { label: '退出 Linguist', click: () => { appQuitting = true; app.quit(); } },
    ])
  );
  tray.on('click', () => toggleMain());
}

// ---------------------------------------------------------------------------
// 全局快捷键
// ---------------------------------------------------------------------------
function registerShortcuts() {
  globalShortcut.register('CommandOrControl+Shift+L', () => toggleMain());
  globalShortcut.register('Alt+S', () => {
    if (mainWindow && mainWindow.isVisible()) {
      mainWindow.webContents.send('trigger:screenshot');
    } else {
      showMain();
      setTimeout(() => mainWindow && mainWindow.webContents.send('trigger:screenshot'), 300);
    }
  });
}

// ---------------------------------------------------------------------------
// IPC（卡片 <-> 窗口）
// ---------------------------------------------------------------------------
function registerIpc() {
  // 窗口拖动：由卡片把窗口内鼠标坐标交给主进程，主进程以窗口原始位置为锚移动
  ipcMain.on('window:startDrag', (event, mouseX, mouseY) => {
    const win = BrowserWindow.fromWebContents(event.sender);
    if (!win) return;
    // mouseX/mouseY 为鼠标在窗口内的坐标（clientX/clientY），即鼠标相对窗口左上角的偏移
    dragState = { win, offsetX: mouseX, offsetY: mouseY };
  });
  ipcMain.on('window:dragMove', () => {
    if (!dragState) return;
    // 用鼠标屏幕坐标 - 偏移量 计算窗口目标位置，避免窗口移动后 clientX 参考系错乱
    const cursor = screen.getCursorScreenPoint();
    const nx = cursor.x - dragState.offsetX;
    const ny = cursor.y - dragState.offsetY;
    const { workArea } = screen.getDisplayNearestPoint({ x: nx, y: ny });
    const clampedX = Math.max(workArea.x - WINDOW_EDGE, Math.min(workArea.x + workArea.width - 160, nx));
    const clampedY = Math.max(workArea.y - WINDOW_EDGE, Math.min(workArea.y + workArea.height - 40, ny));
    dragState.win.setPosition(Math.round(clampedX), Math.round(clampedY));
  });
  ipcMain.on('window:endDrag', () => {
    dragState = null;
  });

  // 卡片缩放：窗口尺寸 = 卡片尺寸 + 边缘留白
  ipcMain.on('window:resize', (event, w, h) => {
    const win = BrowserWindow.fromWebContents(event.sender);
    if (!win || typeof w !== 'number' || typeof h !== 'number') return;
    win.setSize(Math.round(w) + WINDOW_EDGE * 2, Math.round(h) + WINDOW_EDGE * 2, false);
  });

  ipcMain.on('window:setAlwaysOnTop', (event, flag) => {
    const win = BrowserWindow.fromWebContents(event.sender);
    if (win) win.setAlwaysOnTop(Boolean(flag));
  });
  ipcMain.on('window:setOpacity', (event, val) => {
    const win = BrowserWindow.fromWebContents(event.sender);
    if (win && typeof val === 'number') win.setOpacity(Math.min(1, Math.max(0.3, val)));
  });
  ipcMain.on('window:hide', (event) => {
    const win = BrowserWindow.fromWebContents(event.sender);
    if (win) win.hide();
  });
  ipcMain.on('window:minimize', (event) => {
    const win = BrowserWindow.fromWebContents(event.sender);
    if (win) win.minimize();
  });
  ipcMain.on('app:quit', () => {
    appQuitting = true;
    app.quit();
  });
}

// ---------------------------------------------------------------------------
// 生命周期
// ---------------------------------------------------------------------------
app.whenReady().then(async () => {
  registerIpc();
  let url;
  try {
    url = (await resolveBackend()).url;
  } catch (err) {
    console.error('[Linguist] backend start failed:', err);
    appQuitting = true;
    app.quit();
    return;
  }
  createWindow(url);
  createTray();
  registerShortcuts();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow(url);
    else showMain();
  });
});

app.on('will-quit', () => {
  globalShortcut.unregisterAll();
});

app.on('window-all-closed', (e) => {
  // 悬浮常驻应用：不因窗口关闭而退出（托盘保留）
  e.preventDefault();
});
