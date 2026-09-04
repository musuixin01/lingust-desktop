/**
 * Helper utilities for Electron Desktop Native integration
 */

export function isElectron(): boolean {
  return typeof window !== 'undefined' && Boolean(window.electronAPI?.isElectron);
}

export function getPlatform(): 'win32' | 'darwin' | 'linux' | 'web' {
  if (!isElectron() || !window.electronAPI) return 'web';
  return window.electronAPI.platform;
}

export function minimizeWindow() {
  if (isElectron() && window.electronAPI) {
    window.electronAPI.minimize();
  }
}

export function maximizeWindow() {
  if (isElectron() && window.electronAPI) {
    window.electronAPI.maximize();
  }
}

export function closeWindow() {
  if (isElectron() && window.electronAPI) {
    window.electronAPI.close();
  }
}

export function setAlwaysOnTop(flag: boolean) {
  if (isElectron() && window.electronAPI) {
    window.electronAPI.setAlwaysOnTop(flag);
  }
}

export async function isAlwaysOnTop(): Promise<boolean> {
  if (isElectron() && window.electronAPI) {
    return window.electronAPI.isAlwaysOnTop();
  }
  return false;
}

export function syncWindowSize(width: number, height: number) {
  if (isElectron() && window.electronAPI) {
    window.electronAPI.setWindowSize(width, height);
  }
}

export async function captureDesktopScreen(): Promise<string | null> {
  if (isElectron() && window.electronAPI) {
    return window.electronAPI.captureDesktopScreen();
  }
  return null;
}

export function openExternalUrl(url: string) {
  if (isElectron() && window.electronAPI) {
    window.electronAPI.openExternal(url);
  } else {
    window.open(url, '_blank', 'noopener,noreferrer');
  }
}
