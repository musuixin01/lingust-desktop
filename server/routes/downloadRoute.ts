import { Router, Request, Response } from 'express';
import path from 'path';
import fs from 'fs';

const router = Router();

const ZIP_NAME = 'Linguist-Windows-v1.3.0-x64.zip';
const ZIP_PATH = path.join(process.cwd(), 'release', ZIP_NAME);

// GET /api/download/status - 获取 Windows 打包状态与文件信息
router.get('/api/download/status', (req: Request, res: Response) => {
  if (fs.existsSync(ZIP_PATH)) {
    const stats = fs.statSync(ZIP_PATH);
    const sizeMb = (stats.size / (1024 * 1024)).toFixed(1);
    return res.json({
      available: true,
      filename: ZIP_NAME,
      sizeMb: `${sizeMb} MB`,
      updatedAt: stats.mtime,
      downloadUrl: '/api/download/windows',
    });
  }

  return res.json({
    available: false,
    message: 'Windows 桌面打包正在准备中或未生成',
  });
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
