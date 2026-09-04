var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// electron/preload.ts
var preload_exports = {};
module.exports = __toCommonJS(preload_exports);
var import_electron = require("electron");
var electronAPI = {
  isElectron: true,
  platform: process.platform,
  minimize: () => import_electron.ipcRenderer.send("window:minimize"),
  maximize: () => import_electron.ipcRenderer.send("window:maximize"),
  close: () => import_electron.ipcRenderer.send("window:close"),
  setAlwaysOnTop: (flag) => import_electron.ipcRenderer.send("window:setAlwaysOnTop", flag),
  isAlwaysOnTop: () => import_electron.ipcRenderer.invoke("window:isAlwaysOnTop"),
  setWindowSize: (width, height) => import_electron.ipcRenderer.send("window:setSize", { width, height }),
  getWindowSize: () => import_electron.ipcRenderer.invoke("window:getSize"),
  captureDesktopScreen: () => import_electron.ipcRenderer.invoke("desktop:captureScreen"),
  openExternal: (url) => import_electron.ipcRenderer.send("app:openExternal", url),
  onShortcutTriggered: (callback) => {
    const handler = (_event, action) => callback(action);
    import_electron.ipcRenderer.on("shortcut:triggered", handler);
    return () => import_electron.ipcRenderer.removeListener("shortcut:triggered", handler);
  },
  onTrayAction: (callback) => {
    const handler = (_event, action) => callback(action);
    import_electron.ipcRenderer.on("tray:action", handler);
    return () => import_electron.ipcRenderer.removeListener("tray:action", handler);
  },
  onWindowStateChange: (callback) => {
    const handler = (_event, state) => callback(state);
    import_electron.ipcRenderer.on("window:stateChange", handler);
    return () => import_electron.ipcRenderer.removeListener("window:stateChange", handler);
  }
};
import_electron.contextBridge.exposeInMainWorld("electronAPI", electronAPI);
