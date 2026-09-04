import express from 'express';
import path from 'path';
import { pathToFileURL } from 'url';
import { SERVER_CONFIG } from './server/config';
import apiRoutes from './server/routes';

export interface StartServerOptions {
  port?: number;
  host?: string;
  staticDir?: string;
}

/**
 * 启动 Linguist 内置服务（Express + API 路由 + 前端静态资源）。
 * - 直接运行（npm run dev / node dist/server.cjs）时自动调用；
 * - Electron 桌面端通过 require 本模块调用 startServer() 复用同一后端。
 */
export async function startServer(opts: StartServerOptions = {}) {
  const app = express();
  const PORT = opts.port ?? (Number(process.env.PORT) || SERVER_CONFIG.PORT);
  const HOST = opts.host ?? SERVER_CONFIG.HOST;

  // Request body parsers with generous limits for screenshot image uploads
  app.use(express.json({ limit: SERVER_CONFIG.BODY_LIMIT }));
  app.use(express.urlencoded({ extended: true, limit: SERVER_CONFIG.BODY_LIMIT }));

  // Health check endpoint
  app.get('/api/health', (req, res) => {
    res.json({
      status: 'ok',
      timestamp: Date.now(),
      hasGeminiKey: Boolean(process.env.GEMINI_API_KEY),
      nodeEnv: process.env.NODE_ENV || 'development',
    });
  });

  // Mount enterprise modular API routes
  app.use(apiRoutes);

  const isProd = opts.staticDir !== undefined || process.env.NODE_ENV === 'production';
  if (!isProd) {
    const { createServer: createViteServer } = await import('vite');
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = opts.staticDir ?? path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  return new Promise<void>((resolve) => {
    app.listen(PORT, HOST, () => {
      console.log(`[Linguist] Enterprise server running on http://${HOST}:${PORT}`);
      resolve();
    });
  });
}

// 仅当作为主入口直接运行（npm run dev / node dist/server.cjs）时自启动；
// Electron 桌面端 require 本模块前会置 LINGUIST_EMBEDDED=1，避免重复启动。
const isMainEntry =
  process.env.LINGUIST_EMBEDDED !== '1' &&
  ((typeof import.meta !== 'undefined' &&
    import.meta.url &&
    Boolean(process.argv[1]) &&
    import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) ||
    (typeof require !== 'undefined' && require.main === module));
if (isMainEntry) {
  startServer();
}
