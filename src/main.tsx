import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.tsx';
import './index.css';

// Apply transparent background if running inside native Electron desktop app
if (typeof window !== 'undefined' && window.electronAPI?.isElectron) {
  document.documentElement.classList.add('electron-app');
  document.body.classList.add('electron-app');
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);

