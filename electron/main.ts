import { app, BrowserWindow, ipcMain, Tray, Menu, nativeImage, globalShortcut, desktopCapturer, shell } from 'electron';
import path from 'path';
import { fileURLToPath } from 'url';

// Hardware acceleration & Windows transparency configuration
if (process.platform === 'win32') {
  app.commandLine.appendSwitch('enable-transparent-visuals');
}

const isDev = process.env.NODE_ENV !== 'production' && !app.isPackaged;
const PORT = process.env.PORT || 3000;

let mainWindow: BrowserWindow | null = null;
let tray: Tray | null = null;
let isAlwaysOnTopState = false;
let isAppQuitting = false;

// Force single instance
const gotTheLock = app.requestSingleInstanceLock();
if (!gotTheLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.show();
      mainWindow.focus();
    }
  });
}

function getAssetPath(...paths: string[]) {
  return path.join(app.getAppPath(), ...paths);
}

function createMainWindow() {
  const iconPath = path.join(app.getAppPath(), 'public', 'icon.png');

  mainWindow = new BrowserWindow({
    width: 390,
    height: 520,
    minWidth: 260,
    minHeight: 46,
    frame: false, // Frameless window: removes OS standard titlebar and chrome
    transparent: true, // Transparent window for liquid glass design
    thickFrame: false, // CRITICAL FOR WINDOWS: disables WS_THICKFRAME to completely remove outer OS resize border & wrapper
    roundedCorners: false, // CRITICAL FOR WINDOWS 11: prevents DWM from drawing an external system window border
    backgroundColor: '#00000000', // Explicit transparent background to eliminate opaque grey box
    hasShadow: false, // Prevent Windows DWM from rendering a square grey/black box shadow
    show: false,
    resizable: true,
    alwaysOnTop: isAlwaysOnTopState,
    skipTaskbar: false,
    icon: iconPath,
    // macOS Native Frosted Glass Vibrancy
    vibrancy: process.platform === 'darwin' ? 'under-window' : undefined,
    visualEffectState: 'active',
    webPreferences: {
      preload: path.join(__dirname, 'preload.cjs'),
      contextIsolation: true,
      nodeIntegration: false,
      webSecurity: false, // Allow local file loading with assets
    },
  });

  // URL resolution: Dev server or packaged production build
  const indexPath = path.join(app.getAppPath(), 'dist', 'index.html');

  if (isDev) {
    const devUrl = `http://localhost:${PORT}`;
    console.log(`[Electron] Connecting to dev URL: ${devUrl}`);
    mainWindow.loadURL(devUrl).catch((err) => {
      console.warn(`[Electron] Dev server at ${devUrl} not responding (${err.message}). Loading local build files instead...`);
      mainWindow?.loadFile(indexPath).catch((fileErr) => {
        console.error('[Electron] Could not load local index.html. Please build the project first with "npm run build".', fileErr);
      });
    });
    // Open DevTools in dev mode if requested
    if (process.env.OPEN_DEVTOOLS) {
      mainWindow.webContents.openDevTools({ mode: 'detach' });
    }
  } else {
    // In packaged desktop application, load the built static index.html or local embedded server
    mainWindow.loadFile(indexPath).catch(() => {
      mainWindow?.loadURL(`http://127.0.0.1:${PORT}`);
    });
  }

  // Gracefully show window once ready to avoid white flash
  mainWindow.once('ready-to-show', () => {
    mainWindow?.show();
    mainWindow?.focus();
    emitWindowState();
  });

  // Fallback: ensure window is visible even if ready-to-show is delayed
  setTimeout(() => {
    if (mainWindow && !mainWindow.isVisible()) {
      mainWindow.show();
      mainWindow.focus();
    }
  }, 1200);

  // Hide window instead of destroying on close (minimize to system tray)
  mainWindow.on('close', (event) => {
    if (!isAppQuitting) {
      event.preventDefault();
      mainWindow?.hide();
    }
    return false;
  });

  mainWindow.on('maximize', () => emitWindowState());
  mainWindow.on('unmaximize', () => emitWindowState());
}

function emitWindowState() {
  if (!mainWindow || mainWindow.isDestroyed()) return;
  mainWindow.webContents.send('window:stateChange', {
    isMaximized: mainWindow.isMaximized(),
    isAlwaysOnTop: mainWindow.isAlwaysOnTop(),
  });
}

function createTray() {
  const iconPath = path.join(app.getAppPath(), 'public', 'icon.png');
  let trayIcon = nativeImage.createFromPath(iconPath);
  if (process.platform === 'darwin') {
    trayIcon = trayIcon.resize({ width: 18, height: 18 });
    trayIcon.setTemplateImage(true);
  } else {
    trayIcon = trayIcon.resize({ width: 20, height: 20 });
  }

  tray = new Tray(trayIcon);
  tray.setToolTip('Linguist 桌面悬浮翻译卡片');

  const contextMenu = Menu.buildFromTemplate([
    {
      label: '显示悬浮卡片 (Show Card)',
      accelerator: 'Alt+Space',
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.focus();
        }
      },
    },
    {
      label: '屏幕截图翻译 (Capture & Translate)',
      accelerator: 'Alt+S',
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.webContents.send('shortcut:triggered', 'screenshot');
        }
      },
    },
    { type: 'separator' },
    {
      label: '窗口总在最前 (Always on Top)',
      type: 'checkbox',
      checked: isAlwaysOnTopState,
      click: (item) => {
        isAlwaysOnTopState = item.checked;
        mainWindow?.setAlwaysOnTop(isAlwaysOnTopState);
        emitWindowState();
      },
    },
    {
      label: '开机自动启动 (Launch at Startup)',
      type: 'checkbox',
      checked: app.getLoginItemSettings().openAtLogin,
      click: (item) => {
        app.setLoginItemSettings({
          openAtLogin: item.checked,
        });
      },
    },
    { type: 'separator' },
    {
      label: '偏好设置 (Preferences...)',
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.webContents.send('tray:action', 'open-settings');
        }
      },
    },
    {
      label: '生词本与历史 (History & Vocabulary)',
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.webContents.send('tray:action', 'open-history');
        }
      },
    },
    { type: 'separator' },
    {
      label: '退出 Linguist (Quit)',
      click: () => {
        isAppQuitting = true;
        app.quit();
      },
    },
  ]);

  tray.setContextMenu(contextMenu);

  tray.on('click', () => {
    if (!mainWindow) return;
    if (mainWindow.isVisible()) {
      mainWindow.hide();
    } else {
      mainWindow.show();
      mainWindow.focus();
    }
  });

  tray.on('double-click', () => {
    if (mainWindow) {
      mainWindow.show();
      mainWindow.focus();
    }
  });
}

function registerGlobalShortcuts() {
  // Alt+Space: Toggle main translator window
  try {
    globalShortcut.register('Alt+Space', () => {
      if (!mainWindow) return;
      if (mainWindow.isVisible() && mainWindow.isFocused()) {
        mainWindow.hide();
      } else {
        mainWindow.show();
        mainWindow.focus();
      }
    });
  } catch (e) {
    console.warn('[Shortcuts] Failed to register Alt+Space', e);
  }

  // Alt+S: Trigger OCR screenshot translate
  try {
    globalShortcut.register('Alt+S', () => {
      if (mainWindow) {
        mainWindow.show();
        mainWindow.webContents.send('shortcut:triggered', 'screenshot');
      }
    });
  } catch (e) {
    console.warn('[Shortcuts] Failed to register Alt+S', e);
  }
}

// IPC Handlers
function setupIpcHandlers() {
  ipcMain.on('window:minimize', () => {
    mainWindow?.minimize();
  });

  ipcMain.on('window:maximize', () => {
    if (!mainWindow) return;
    if (mainWindow.isMaximized()) {
      mainWindow.unmaximize();
    } else {
      mainWindow.maximize();
    }
  });

  ipcMain.on('window:close', () => {
    mainWindow?.hide();
  });

  ipcMain.on('window:setAlwaysOnTop', (_event, flag: boolean) => {
    isAlwaysOnTopState = flag;
    mainWindow?.setAlwaysOnTop(flag);
    emitWindowState();
  });

  ipcMain.handle('window:isAlwaysOnTop', () => {
    return mainWindow?.isAlwaysOnTop() ?? false;
  });

  ipcMain.on('window:setSize', (_event, { width, height }: { width: number; height: number }) => {
    if (!mainWindow) return;
    const [currW, currH] = mainWindow.getSize();
    const newW = Math.max(260, Math.round(width));
    const newH = Math.max(46, Math.round(height));
    if (currW !== newW || currH !== newH) {
      mainWindow.setSize(newW, newH, true);
    }
  });

  ipcMain.handle('window:getSize', () => {
    if (!mainWindow) return { width: 440, height: 620 };
    const [w, h] = mainWindow.getSize();
    return { width: w, height: h };
  });

  ipcMain.handle('desktop:captureScreen', async () => {
    try {
      const sources = await desktopCapturer.getSources({
        types: ['screen'],
        thumbnailSize: { width: 1920, height: 1080 },
      });
      if (sources.length > 0) {
        return sources[0].thumbnail.toDataURL();
      }
      return null;
    } catch (e) {
      console.error('[Electron] captureScreen error:', e);
      return null;
    }
  });

  ipcMain.on('app:openExternal', (_event, url: string) => {
    if (url && (url.startsWith('http://') || url.startsWith('https://'))) {
      shell.openExternal(url);
    }
  });
}

// Embedded Express server starter for desktop client
function startEmbeddedServerIfNeeded() {
  try {
    const fs = require('fs');
    const serverPath = path.join(app.getAppPath(), 'dist', 'server.cjs');
    if (fs.existsSync(serverPath)) {
      require(serverPath);
      console.log('[Electron] Embedded server started from', serverPath);
    }
  } catch (e) {
    console.warn('[Electron] Could not start embedded server:', e);
  }
}

// App lifecycle
app.whenReady().then(async () => {
  startEmbeddedServerIfNeeded();
  setupIpcHandlers();
  createMainWindow();
  createTray();
  registerGlobalShortcuts();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    } else {
      mainWindow?.show();
    }
  });
});

app.on('will-quit', () => {
  globalShortcut.unregisterAll();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
