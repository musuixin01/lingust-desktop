import React, { useState, useEffect } from 'react';
import {
  Download,
  CheckCircle2,
  AlertCircle,
  X,
  Laptop,
  FolderArchive,
  RefreshCw,
  Sparkles,
  ExternalLink,
} from 'lucide-react';

interface DownloadModalProps {
  isOpen: boolean;
  onClose: () => void;
}

interface FileInfo {
  available: boolean;
  filename: string;
  sizeMb: string;
  sizeBytes: number;
  chunkSize: number;
  totalChunks: number;
  message?: string;
}

export const DownloadModal: React.FC<DownloadModalProps> = ({ isOpen, onClose }) => {
  const [fileInfo, setFileInfo] = useState<FileInfo | null>(null);
  const [loadingInfo, setLoadingInfo] = useState(true);
  const [downloading, setDownloading] = useState(false);
  const [currentChunk, setCurrentChunk] = useState(0);
  const [totalChunks, setTotalChunks] = useState(1);
  const [progressPercent, setProgressPercent] = useState(0);
  const [downloadedMb, setDownloadedMb] = useState('0.0');
  const [downloadSuccess, setDownloadSuccess] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;

    // 获取文件状态
    const fetchStatus = async () => {
      setLoadingInfo(true);
      setErrorMessage(null);
      try {
        const res = await fetch('/api/download/status');
        if (!res.ok) throw new Error('无法连接下载服务器');
        const data: FileInfo = await res.json();
        setFileInfo(data);
        if (data.totalChunks) {
          setTotalChunks(data.totalChunks);
        }
      } catch (err: any) {
        setErrorMessage(err.message || '获取打包信息失败');
      } finally {
        setLoadingInfo(false);
      }
    };

    fetchStatus();
  }, [isOpen]);

  const handleStartDownload = async () => {
    if (downloading) return;
    setDownloading(true);
    setDownloadSuccess(false);
    setErrorMessage(null);
    setCurrentChunk(0);
    setProgressPercent(0);
    setDownloadedMb('0.0');

    try {
      // 1. 获取最新状态与总分片数
      const statusRes = await fetch('/api/download/status');
      if (!statusRes.ok) throw new Error('获取文件元信息失败');
      const meta: FileInfo = await statusRes.json();
      if (!meta.available) {
        throw new Error(meta.message || '安装包准备中，请稍候');
      }

      const total = meta.totalChunks || 13;
      setTotalChunks(total);
      const chunks: ArrayBuffer[] = [];
      let totalReceivedBytes = 0;

      // 2. 逐片下载 (每片 15MB，彻底突破云端代理 32MB 单请求响应限制)
      for (let i = 0; i < total; i++) {
        setCurrentChunk(i + 1);
        const chunkRes = await fetch(`/api/download/chunk/${i}`);
        if (!chunkRes.ok) {
          throw new Error(`分片 ${i + 1}/${total} 下载失败 (HTTP ${chunkRes.status})`);
        }

        const buffer = await chunkRes.arrayBuffer();
        chunks.push(buffer);
        totalReceivedBytes += buffer.byteLength;

        const percent = Math.round(((i + 1) / total) * 100);
        setProgressPercent(percent);
        setDownloadedMb((totalReceivedBytes / (1024 * 1024)).toFixed(1));
      }

      // 3. 在浏览器内存中组装为完整 ZIP
      const blob = new Blob(chunks, { type: 'application/zip' });
      const downloadUrl = URL.createObjectURL(blob);

      // 4. 触发本地浏览器保存对话框
      const a = document.createElement('a');
      a.href = downloadUrl;
      a.download = meta.filename || 'Linguist-Windows-v1.3.0-x64.zip';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);

      setTimeout(() => {
        URL.revokeObjectURL(downloadUrl);
      }, 10000);

      setDownloadSuccess(true);
    } catch (err: any) {
      console.error('[Download] 分片下载出错:', err);
      setErrorMessage(err.message || '下载中断，请点击重试');
    } finally {
      setDownloading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-xs animate-in fade-in duration-200">
      <div className="relative w-full max-w-lg overflow-hidden rounded-2xl border border-slate-700 bg-slate-900 shadow-2xl">
        {/* Modal Header */}
        <div className="flex items-center justify-between border-b border-slate-800 px-6 py-4 bg-slate-900/60">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              <Download className="h-5 w-5" />
            </div>
            <div>
              <h2 className="text-base font-semibold text-slate-100 flex items-center gap-2">
                下载 Windows 原生打包客户端
                <span className="text-[11px] px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 font-normal">
                  v1.3.0 免安装
                </span>
              </h2>
              <p className="text-xs text-slate-400">
                云端自动分片流式传输，已规避单次请求大小限制
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-800 hover:text-slate-200 transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Modal Content */}
        <div className="p-6 space-y-5">
          {/* File Card info */}
          <div className="rounded-xl border border-slate-800 bg-slate-950/60 p-4 space-y-3">
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <FolderArchive className="h-8 w-8 text-emerald-400 shrink-0" />
                <div>
                  <div className="font-medium text-slate-200 text-sm">
                    {fileInfo?.filename || 'Linguist-Windows-v1.3.0-x64.zip'}
                  </div>
                  <div className="text-xs text-slate-400 flex items-center gap-2 mt-0.5">
                    <span>📦 体积: {fileInfo?.sizeMb || '187.8 MB'}</span>
                    <span>•</span>
                    <span>分片数: {totalChunks} 片 (每片 15MB)</span>
                  </div>
                </div>
              </div>
              <span className="text-[11px] px-2 py-0.5 rounded-full bg-blue-500/10 text-blue-400 border border-blue-500/20">
                绿色免安装
              </span>
            </div>

            {/* Feature Badges */}
            <div className="pt-2 border-t border-slate-800/80 grid grid-cols-2 gap-2 text-xs text-slate-300">
              <div className="flex items-center gap-1.5 text-slate-400">
                <span className="text-emerald-400">✓</span> 内置 Chromium + Electron 内核
              </div>
              <div className="flex items-center gap-1.5 text-slate-400">
                <span className="text-emerald-400">✓</span> 解压后双击 Linguist.exe 即用
              </div>
              <div className="flex items-center gap-1.5 text-slate-400">
                <span className="text-emerald-400">✓</span> 全局快捷键 Alt+Space 随处呼出
              </div>
              <div className="flex items-center gap-1.5 text-slate-400">
                <span className="text-emerald-400">✓</span> 截图框选逐行原地对照翻译
              </div>
            </div>
          </div>

          {/* Download Progress or Action */}
          {downloading ? (
            <div className="space-y-3 rounded-xl border border-emerald-500/30 bg-emerald-950/20 p-4">
              <div className="flex items-center justify-between text-xs">
                <span className="font-medium text-emerald-300 flex items-center gap-2">
                  <RefreshCw className="h-3.5 w-3.5 animate-spin" />
                  正在传输分片 ({currentChunk}/{totalChunks})...
                </span>
                <span className="font-semibold text-emerald-400">{progressPercent}%</span>
              </div>

              {/* Progress Bar */}
              <div className="h-2 w-full overflow-hidden rounded-full bg-slate-800">
                <div
                  className="h-full bg-linear-to-r from-emerald-500 to-teal-400 transition-all duration-300 ease-out"
                  style={{ width: `${progressPercent}%` }}
                />
              </div>

              <div className="flex justify-between text-[11px] text-slate-400">
                <span>已传输: {downloadedMb} MB / {fileInfo?.sizeMb || '187.8 MB'}</span>
                <span>传输安全: 内存无缝自动合成</span>
              </div>
            </div>
          ) : downloadSuccess ? (
            <div className="space-y-3 rounded-xl border border-emerald-500/40 bg-emerald-950/30 p-4">
              <div className="flex items-center gap-2.5 text-emerald-300 text-sm font-medium">
                <CheckCircle2 className="h-5 w-5 text-emerald-400 shrink-0" />
                <span>下载成功！文件已存入您的本地下载目录</span>
              </div>
              <div className="text-xs text-slate-300 leading-relaxed bg-slate-900/80 p-3 rounded-lg border border-slate-800 space-y-1.5">
                <p className="font-medium text-slate-200">🚀 接下来怎么运行：</p>
                <ol className="list-decimal list-inside space-y-1 text-slate-400">
                  <li>在您的电脑中找到刚下载的 <span className="text-emerald-300 font-mono">Linguist-Windows-v1.3.0-x64.zip</span>；</li>
                  <li>右键点击它并选择“全部解压缩”；</li>
                  <li>打开解压出来的文件夹，直接双击运行 <span className="text-emerald-300 font-semibold font-mono">Linguist.exe</span>！</li>
                </ol>
              </div>
            </div>
          ) : errorMessage ? (
            <div className="space-y-3 rounded-xl border border-rose-500/30 bg-rose-950/20 p-4">
              <div className="flex items-center gap-2 text-rose-300 text-xs">
                <AlertCircle className="h-4 w-4 shrink-0 text-rose-400" />
                <span>{errorMessage}</span>
              </div>
              <button
                type="button"
                onClick={handleStartDownload}
                className="w-full flex items-center justify-center gap-2 py-2 px-4 rounded-lg bg-rose-600 hover:bg-rose-500 text-white text-xs font-medium transition-colors cursor-pointer"
              >
                <RefreshCw className="h-3.5 w-3.5" />
                <span>重新尝试分片下载</span>
              </button>
            </div>
          ) : (
            <button
              type="button"
              onClick={handleStartDownload}
              disabled={loadingInfo}
              className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-linear-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white text-sm font-medium shadow-lg shadow-emerald-950/50 transition-all cursor-pointer disabled:opacity-50"
            >
              <Download className="h-4 w-4" />
              <span>立即开始高速分片下载 (自动拼装)</span>
            </button>
          )}

          {/* Tips on GitHub Releases */}
          <div className="rounded-xl border border-slate-800 bg-slate-900/40 p-3.5 text-xs text-slate-400 space-y-1.5">
            <div className="flex items-center gap-1.5 font-medium text-slate-300">
              <Sparkles className="h-3.5 w-3.5 text-amber-400" />
              <span>想要在 GitHub 上也有直接下载链接？</span>
            </div>
            <p className="leading-relaxed text-[11px]">
              项目已为您配置好了完整的 <span className="text-slate-200">GitHub Actions CI/CD</span> 脚本。只要您点击界面右上角的「Export to GitHub」，并在 GitHub 上打一个版本标签（如 <span className="text-emerald-400 font-mono">v1.3.0</span>），GitHub 就会全自动在云端编译出专属 Release 安装包，永久托管供所有人下载！
            </p>
          </div>
        </div>

        {/* Modal Footer */}
        <div className="flex items-center justify-end border-t border-slate-800 px-6 py-3 bg-slate-950/80">
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg px-4 py-1.5 text-xs font-medium text-slate-400 hover:bg-slate-800 hover:text-slate-200 transition-colors"
          >
            关闭窗口
          </button>
        </div>
      </div>
    </div>
  );
};
