/**
 * Linguist 桌面客户端 - preload 脚本
 * 通过 contextBridge 向渲染进程暴露最小桌面能力（window.electronAPI）
 */
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  isDesktop: true,

  // 窗口拖动
  startDrag: (mouseX, mouseY) => ipcRenderer.send('window:startDrag', mouseX, mouseY),
  dragMove: (mouseX, mouseY) => ipcRenderer.send('window:dragMove', mouseX, mouseY),
  endDrag: () => ipcRenderer.send('window:endDrag'),

  // 窗口缩放（卡片尺寸 -> 窗口尺寸）
  resizeWindow: (w, h) => ipcRenderer.send('window:resize', w, h),

  // 窗口行为
  setAlwaysOnTop: (flag) => ipcRenderer.send('window:setAlwaysOnTop', flag),
  setOpacity: (val) => ipcRenderer.send('window:setOpacity', val),
  hideWindow: () => ipcRenderer.send('window:hide'),
  minimizeWindow: () => ipcRenderer.send('window:minimize'),
  quitApp: () => ipcRenderer.send('app:quit'),

  // 主进程 -> 渲染进程事件
  onTriggerScreenshot: (cb) => {
    ipcRenderer.on('trigger:screenshot', () => cb && cb());
  },
});
