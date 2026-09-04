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

declare global {
  interface Window {
    electronAPI?: ElectronAPI;
  }
}
