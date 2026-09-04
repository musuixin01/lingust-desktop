import { Router, Request, Response } from 'express';
import path from 'path';
import fs from 'fs';

const router = Router();

const ZIP_NAME = 'Linguist-Windows-v1.3.0-x64.zip';
const ZIP_PATH = path.join(process.cwd(), 'release', ZIP_NAME);
const CHUNK_SIZE = 15 * 1024 * 1024; // 15MB 规避 Cloud Run 32MB 单请求响应上限

// GET /api/download/status - 获取 Windows 打包状态与文件信息
router.get('/api/download/status', (req: Request, res: Response) => {
  if (fs.existsSync(ZIP_PATH)) {
    const stats = fs.statSync(ZIP_PATH);
    const sizeMb = (stats.size / (1024 * 1024)).toFixed(1);
    const totalChunks = Math.ceil(stats.size / CHUNK_SIZE);
    return res.json({
      available: true,
      filename: ZIP_NAME,
      sizeBytes: stats.size,
      sizeMb: `${sizeMb} MB`,
      chunkSize: CHUNK_SIZE,
      totalChunks,
      updatedAt: stats.mtime,
      downloadUrl: '/api/download/windows',
    });
  }

  return res.json({
    available: false,
    message: 'Windows 桌面打包正在准备中或未生成',
  });
});

// GET /api/download/chunk/:index - 获取第 N 个分片（0-indexed）
router.get('/api/download/chunk/:index', (req: Request, res: Response) => {
  if (!fs.existsSync(ZIP_PATH)) {
    return res.status(404).json({ error: 'FILE_NOT_FOUND', message: '安装包不存在' });
  }

  const chunkIndex = parseInt(req.params.index, 10);
  if (isNaN(chunkIndex) || chunkIndex < 0) {
    return res.status(400).json({ error: 'INVALID_CHUNK_INDEX', message: '无效的分片序号' });
  }

  const stats = fs.statSync(ZIP_PATH);
  const totalChunks = Math.ceil(stats.size / CHUNK_SIZE);

  if (chunkIndex >= totalChunks) {
    return res.status(404).json({ error: 'CHUNK_OUT_OF_BOUNDS', message: '分片超出范围' });
  }

  const start = chunkIndex * CHUNK_SIZE;
  const end = Math.min(start + CHUNK_SIZE - 1, stats.size - 1);
  const contentLength = end - start + 1;

  res.writeHead(200, {
    'Content-Type': 'application/octet-stream',
    'Content-Length': contentLength,
    'Content-Disposition': `attachment; filename="${ZIP_NAME}.part${chunkIndex}"`,
    'X-Chunk-Index': String(chunkIndex),
    'X-Total-Chunks': String(totalChunks),
    'X-Total-Size': String(stats.size),
  });

  const stream = fs.createReadStream(ZIP_PATH, { start, end });
  stream.pipe(res);
});

// GET /api/download/windows - 浏览器一键直接下载 Windows 免安装绿色版
router.get('/api/download/windows', (req: Request, res: Response) => {
  if (!fs.existsSync(ZIP_PATH)) {
    return res.status(404).json({
      error: 'FILE_NOT_FOUND',
      message: 'Windows 客户端包尚未生成，请稍候再试',
    });
  }

  res.setHeader('Content-Type', 'application/zip');
  res.setHeader('Content-Disposition', `attachment; filename="${ZIP_NAME}"`);
  return res.download(ZIP_PATH, ZIP_NAME);
});

export default router;

