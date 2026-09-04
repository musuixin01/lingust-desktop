import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { createServer as createViteServer } from 'vite';
import { SERVER_CONFIG } from './server/config';
import apiRoutes from './server/routes';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = SERVER_CONFIG.PORT;

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

async function startServer() {
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  const server = app.listen(PORT, SERVER_CONFIG.HOST, () => {
    console.log(`[Linguist] Enterprise server running on http://${SERVER_CONFIG.HOST}:${PORT}`);
  });

  server.on('error', (err: any) => {
    if (err.code === 'EADDRINUSE') {
      console.log(`[Linguist] Port ${PORT} is already in use. Reusing existing running server.`);
    } else {
      console.error('[Linguist] Server listen error:', err);
    }
  });
}

startServer();
