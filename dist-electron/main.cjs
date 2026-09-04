var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// electron/main.ts
var import_electron = require("electron");
var import_path = __toESM(require("path"), 1);
var isDev = process.env.NODE_ENV !== "production" && !import_electron.app.isPackaged;
var PORT = process.env.PORT || 3e3;
var mainWindow = null;
var tray = null;
var isAlwaysOnTopState = false;
var isAppQuitting = false;
var gotTheLock = import_electron.app.requestSingleInstanceLock();
if (!gotTheLock) {
  import_electron.app.quit();
} else {
  import_electron.app.on("second-instance", () => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.show();
      mainWindow.focus();
    }
  });
}
function createMainWindow() {
  const iconPath = import_path.default.join(import_electron.app.getAppPath(), "public", "icon.png");
  mainWindow = new import_electron.BrowserWindow({
    width: 440,
    height: 620,
    minWidth: 260,
    minHeight: 46,
    frame: false,
    // Frameless window
    transparent: true,
    // Transparent for Apple/Windows Liquid Glass & rounded corners
    hasShadow: true,
    show: false,
    resizable: true,
    alwaysOnTop: isAlwaysOnTopState,
    skipTaskbar: false,
    icon: iconPath,
    // Windows 11 Native Acrylic & Mica Effects + Rounded Corners
    backgroundMaterial: "acrylic",
    // 'acrylic' | 'mica'
    roundedCorners: true,
    // macOS Native Frosted Glass Vibrancy
    vibrancy: "under-window",
    visualEffectState: "active",
    webPreferences: {
      preload: import_path.default.join(__dirname, "preload.cjs"),
      contextIsolation: true,
      nodeIntegration: false,
      webSecurity: true
    }
  });
  if (isDev) {
    const devUrl = `http://localhost:${PORT}`;
    console.log(`[Electron] Loading dev URL: ${devUrl}`);
    mainWindow.loadURL(devUrl);
    if (process.env.OPEN_DEVTOOLS) {
      mainWindow.webContents.openDevTools({ mode: "detach" });
    }
  } else {
    const indexPath = import_path.default.join(import_electron.app.getAppPath(), "dist", "index.html");
    mainWindow.loadFile(indexPath).catch(() => {
      mainWindow?.loadURL(`http://127.0.0.1:${PORT}`);
    });
  }
  mainWindow.once("ready-to-show", () => {
    mainWindow?.show();
    mainWindow?.focus();
    emitWindowState();
  });
  mainWindow.on("close", (event) => {
    if (!isAppQuitting) {
      event.preventDefault();
      mainWindow?.hide();
    }
    return false;
  });
  mainWindow.on("maximize", () => emitWindowState());
  mainWindow.on("unmaximize", () => emitWindowState());
}
function emitWindowState() {
  if (!mainWindow || mainWindow.isDestroyed()) return;
  mainWindow.webContents.send("window:stateChange", {
    isMaximized: mainWindow.isMaximized(),
    isAlwaysOnTop: mainWindow.isAlwaysOnTop()
  });
}
function createTray() {
  const iconPath = import_path.default.join(import_electron.app.getAppPath(), "public", "icon.png");
  let trayIcon = import_electron.nativeImage.createFromPath(iconPath);
  if (process.platform === "darwin") {
    trayIcon = trayIcon.resize({ width: 18, height: 18 });
    trayIcon.setTemplateImage(true);
  } else {
    trayIcon = trayIcon.resize({ width: 20, height: 20 });
  }
  tray = new import_electron.Tray(trayIcon);
  tray.setToolTip("Linguist \u684C\u9762\u60AC\u6D6E\u7FFB\u8BD1\u5361\u7247");
  const contextMenu = import_electron.Menu.buildFromTemplate([
    {
      label: "\u663E\u793A\u60AC\u6D6E\u5361\u7247 (Show Card)",
      accelerator: "Alt+Space",
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.focus();
        }
      }
    },
    {
      label: "\u5C4F\u5E55\u622A\u56FE\u7FFB\u8BD1 (Capture & Translate)",
      accelerator: "Alt+S",
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.webContents.send("shortcut:triggered", "screenshot");
        }
      }
    },
    { type: "separator" },
    {
      label: "\u7A97\u53E3\u603B\u5728\u6700\u524D (Always on Top)",
      type: "checkbox",
      checked: isAlwaysOnTopState,
      click: (item) => {
        isAlwaysOnTopState = item.checked;
        mainWindow?.setAlwaysOnTop(isAlwaysOnTopState);
        emitWindowState();
      }
    },
    {
      label: "\u5F00\u673A\u81EA\u52A8\u542F\u52A8 (Launch at Startup)",
      type: "checkbox",
      checked: import_electron.app.getLoginItemSettings().openAtLogin,
      click: (item) => {
        import_electron.app.setLoginItemSettings({
          openAtLogin: item.checked
        });
      }
    },
    { type: "separator" },
    {
      label: "\u504F\u597D\u8BBE\u7F6E (Preferences...)",
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.webContents.send("tray:action", "open-settings");
        }
      }
    },
    {
      label: "\u751F\u8BCD\u672C\u4E0E\u5386\u53F2 (History & Vocabulary)",
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.webContents.send("tray:action", "open-history");
        }
      }
    },
    { type: "separator" },
    {
      label: "\u9000\u51FA Linguist (Quit)",
      click: () => {
        isAppQuitting = true;
        import_electron.app.quit();
      }
    }
  ]);
  tray.setContextMenu(contextMenu);
  tray.on("click", () => {
    if (!mainWindow) return;
    if (mainWindow.isVisible()) {
      mainWindow.hide();
    } else {
      mainWindow.show();
      mainWindow.focus();
    }
  });
  tray.on("double-click", () => {
    if (mainWindow) {
      mainWindow.show();
      mainWindow.focus();
    }
  });
}
function registerGlobalShortcuts() {
  try {
    import_electron.globalShortcut.register("Alt+Space", () => {
      if (!mainWindow) return;
      if (mainWindow.isVisible() && mainWindow.isFocused()) {
        mainWindow.hide();
      } else {
        mainWindow.show();
        mainWindow.focus();
      }
    });
  } catch (e) {
    console.warn("[Shortcuts] Failed to register Alt+Space", e);
  }
  try {
    import_electron.globalShortcut.register("Alt+S", () => {
      if (mainWindow) {
        mainWindow.show();
        mainWindow.webContents.send("shortcut:triggered", "screenshot");
      }
    });
  } catch (e) {
    console.warn("[Shortcuts] Failed to register Alt+S", e);
  }
}
function setupIpcHandlers() {
  import_electron.ipcMain.on("window:minimize", () => {
    mainWindow?.minimize();
  });
  import_electron.ipcMain.on("window:maximize", () => {
    if (!mainWindow) return;
    if (mainWindow.isMaximized()) {
      mainWindow.unmaximize();
    } else {
      mainWindow.maximize();
    }
  });
  import_electron.ipcMain.on("window:close", () => {
    mainWindow?.hide();
  });
  import_electron.ipcMain.on("window:setAlwaysOnTop", (_event, flag) => {
    isAlwaysOnTopState = flag;
    mainWindow?.setAlwaysOnTop(flag);
    emitWindowState();
  });
  import_electron.ipcMain.handle("window:isAlwaysOnTop", () => {
    return mainWindow?.isAlwaysOnTop() ?? false;
  });
  import_electron.ipcMain.on("window:setSize", (_event, { width, height }) => {
    if (!mainWindow) return;
    const [currW, currH] = mainWindow.getSize();
    const newW = Math.max(260, Math.round(width));
    const newH = Math.max(46, Math.round(height));
    if (currW !== newW || currH !== newH) {
      mainWindow.setSize(newW, newH, true);
    }
  });
  import_electron.ipcMain.handle("window:getSize", () => {
    if (!mainWindow) return { width: 440, height: 620 };
    const [w, h] = mainWindow.getSize();
    return { width: w, height: h };
  });
  import_electron.ipcMain.handle("desktop:captureScreen", async () => {
    try {
      const sources = await import_electron.desktopCapturer.getSources({
        types: ["screen"],
        thumbnailSize: { width: 1920, height: 1080 }
      });
      if (sources.length > 0) {
        return sources[0].thumbnail.toDataURL();
      }
      return null;
    } catch (e) {
      console.error("[Electron] captureScreen error:", e);
      return null;
    }
  });
  import_electron.ipcMain.on("app:openExternal", (_event, url) => {
    if (url && (url.startsWith("http://") || url.startsWith("https://"))) {
      import_electron.shell.openExternal(url);
    }
  });
}
import_electron.app.whenReady().then(async () => {
  setupIpcHandlers();
  createMainWindow();
  createTray();
  registerGlobalShortcuts();
  import_electron.app.on("activate", () => {
    if (import_electron.BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    } else {
      mainWindow?.show();
    }
  });
});
import_electron.app.on("will-quit", () => {
  import_electron.globalShortcut.unregisterAll();
});
import_electron.app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    import_electron.app.quit();
  }
});
