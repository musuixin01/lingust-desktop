import { contextBridge, ipcRenderer } from 'electron';

export interface ElectronAPI {
  isElectron: boolean;
  platform: 'win32' | 'darwin' | 'linux';
  minimize: () => void;
  maximize: () => void;
  close: () => void;
  setAlwaysOnTop: (flag: boolean) => void;
  isAlwaysOnTop: () => Promise<boolean>;
  setWindowSize: (width: number, height: number) => void;
  getWindowSize: () => Promise<{ width: number; height: number }>;
  captureDesktopScreen: () => Promise<string | null>;
  openExternal: (url: string) => void;
  onShortcutTriggered: (callback: (action: string) => void) => () => void;
  onTrayAction: (callback: (action: string) => void) => () => void;
  onWindowStateChange: (callback: (state: { isMaximized: boolean; isAlwaysOnTop: boolean }) => void) => () => void;
}

const electronAPI: ElectronAPI = {
  isElectron: true,
  platform: process.platform as 'win32' | 'darwin' | 'linux',
  minimize: () => ipcRenderer.send('window:minimize'),
  maximize: () => ipcRenderer.send('window:maximize'),
  close: () => ipcRenderer.send('window:close'),
  setAlwaysOnTop: (flag: boolean) => ipcRenderer.send('window:setAlwaysOnTop', flag),
  isAlwaysOnTop: () => ipcRenderer.invoke('window:isAlwaysOnTop'),
  setWindowSize: (width: number, height: number) => ipcRenderer.send('window:setSize', { width, height }),
  getWindowSize: () => ipcRenderer.invoke('window:getSize'),
  captureDesktopScreen: () => ipcRenderer.invoke('desktop:captureScreen'),
  openExternal: (url: string) => ipcRenderer.send('app:openExternal', url),
  onShortcutTriggered: (callback: (action: string) => void) => {
    const handler = (_event: any, action: string) => callback(action);
    ipcRenderer.on('shortcut:triggered', handler);
    return () => ipcRenderer.removeListener('shortcut:triggered', handler);
  },
  onTrayAction: (callback: (action: string) => void) => {
    const handler = (_event: any, action: string) => callback(action);
    ipcRenderer.on('tray:action', handler);
    return () => ipcRenderer.removeListener('tray:action', handler);
  },
  onWindowStateChange: (callback: (state: { isMaximized: boolean; isAlwaysOnTop: boolean }) => void) => {
    const handler = (_event: any, state: any) => callback(state);
    ipcRenderer.on('window:stateChange', handler);
    return () => ipcRenderer.removeListener('window:stateChange', handler);
  },
};

contextBridge.exposeInMainWorld('electronAPI', electronAPI);
