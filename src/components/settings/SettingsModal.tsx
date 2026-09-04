import React, { useState } from 'react';
import {
  X,
  Sliders,
  Volume2,
  MousePointerClick,
  Eye,
  Monitor,
  Minimize2,
  Sparkles,
  Globe,
  BookOpen,
  WifiOff,
  Key,
  CheckCircle2,
  AlertCircle,
  EyeOff,
  ExternalLink,
  RotateCw,
  Cpu,
  Type,
} from 'lucide-react';
import { AppSettings, TranslationEngine, EngineApiKeys } from '../../types';

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  settings: AppSettings;
  onUpdateSettings: (newSettings: Partial<AppSettings>) => void;
  isDark?: boolean;
}

export const SettingsModal: React.FC<SettingsModalProps> = ({
  isOpen,
  onClose,
  settings,
  onUpdateSettings,
  isDark = false,
}) => {
  if (!isOpen) return null;

  // Local state for password visibility
  const [showGeminiKey, setShowGeminiKey] = useState(false);
  const [showDeeplKey, setShowDeeplKey] = useState(false);
  const [showYoudaoSecret, setShowYoudaoSecret] = useState(false);

  // Test connection state
  const [testingEngine, setTestingEngine] = useState<TranslationEngine | null>(null);
  const [testResult, setTestResult] = useState<{
    engine: TranslationEngine;
    success: boolean;
    message: string;
  } | null>(null);

  const currentEngine = settings.translationEngine || 'gemini';
  const engineKeys = settings.engineKeys || {};

  const handleKeyChange = (keyField: keyof EngineApiKeys, value: string) => {
    onUpdateSettings({
      engineKeys: {
        ...engineKeys,
        [keyField]: value,
      },
    });
    // Clear test result when typing new key
    if (testResult) setTestResult(null);
  };

  const handleTestConnection = async (engine: TranslationEngine) => {
    setTestingEngine(engine);
    setTestResult(null);
    try {
      const res = await fetch('/api/test-engine', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          engine,
          keys: engineKeys,
        }),
      });
      const data = await res.json();
      setTestResult({
        engine,
        success: Boolean(data.success),
        message: data.message || (data.success ? '连接成功！' : '连接失败'),
      });
    } catch (err: any) {
      setTestResult({
        engine,
        success: false,
        message: `测试异常: ${err.message || '网络连接失败'}`,
      });
    } finally {
      setTestingEngine(null);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in duration-200">
      <div
        className={`w-full max-w-lg max-h-[90vh] flex flex-col rounded-2xl shadow-2xl border transition-all ${
          isDark
            ? 'bg-slate-900/95 border-white/15 text-slate-100'
            : 'bg-white/95 border-slate-200 text-slate-800'
        }`}
      >
        {/* Modal Header */}
        <div className="flex items-center justify-between px-5 py-3.5 border-b border-black/5 dark:border-white/10 shrink-0">
          <div className="flex items-center gap-2 font-semibold text-sm">
            <Sliders className="w-4 h-4 text-blue-500" />
            <span>Linguist 偏好设置</span>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-white transition-colors cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Modal Body (Scrollable) */}
        <div className="flex-1 overflow-y-auto p-5 space-y-5 text-xs">
          {/* Section 1: Translation Engines & API Keys */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <div className="font-semibold text-slate-900 dark:text-white flex items-center gap-1.5">
                <Cpu className="w-4 h-4 text-blue-500" />
                <span>翻译引擎与 API 配置</span>
              </div>
              <span className="text-[11px] text-slate-400">
                当前活跃: <strong className="text-blue-500 uppercase">{currentEngine}</strong>
              </span>
            </div>

            {/* Engine Selection Grid (4 Engines) */}
            <div className="grid grid-cols-2 gap-2">
              {/* 1. Gemini */}
              <button
                type="button"
                onClick={() => onUpdateSettings({ translationEngine: 'gemini' })}
                className={`p-3 rounded-xl border text-left transition-all cursor-pointer relative ${
                  currentEngine === 'gemini'
                    ? 'border-blue-500 bg-blue-500/10 text-slate-900 dark:text-white ring-1 ring-blue-500/40'
                    : 'border-black/5 dark:border-white/10 bg-black/5 dark:bg-white/5 text-slate-600 dark:text-slate-300 hover:border-blue-500/30'
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-1.5 font-semibold text-xs">
                    <Sparkles className="w-3.5 h-3.5 text-blue-400" />
                    <span>Gemini AI</span>
                  </div>
                  <span className="text-[9px] px-1.5 py-0.5 rounded-full bg-blue-500/20 text-blue-600 dark:text-blue-300 font-medium">
                    深度语境
                  </span>
                </div>
                <p className="text-[10px] text-slate-500 dark:text-slate-400 leading-snug">
                  Google Gemini 深度理解，详实音标、词性与双语例句
                </p>
              </button>

              {/* 2. DeepL */}
              <button
                type="button"
                onClick={() => onUpdateSettings({ translationEngine: 'deepl' })}
                className={`p-3 rounded-xl border text-left transition-all cursor-pointer relative ${
                  currentEngine === 'deepl'
                    ? 'border-blue-500 bg-blue-500/10 text-slate-900 dark:text-white ring-1 ring-blue-500/40'
                    : 'border-black/5 dark:border-white/10 bg-black/5 dark:bg-white/5 text-slate-600 dark:text-slate-300 hover:border-blue-500/30'
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-1.5 font-semibold text-xs">
                    <Globe className="w-3.5 h-3.5 text-indigo-400" />
                    <span>DeepL 翻译</span>
                  </div>
                  <span className="text-[9px] px-1.5 py-0.5 rounded-full bg-indigo-500/20 text-indigo-600 dark:text-indigo-300 font-medium">
                    神经自然
                  </span>
                </div>
                <p className="text-[10px] text-slate-500 dark:text-slate-400 leading-snug">
                  业界顶级流利度，支持 DeepL Free 与 Pro 官方密钥
                </p>
              </button>

              {/* 3. Youdao */}
              <button
                type="button"
                onClick={() => onUpdateSettings({ translationEngine: 'youdao' })}
                className={`p-3 rounded-xl border text-left transition-all cursor-pointer relative ${
                  currentEngine === 'youdao'
                    ? 'border-blue-500 bg-blue-500/10 text-slate-900 dark:text-white ring-1 ring-blue-500/40'
                    : 'border-black/5 dark:border-white/10 bg-black/5 dark:bg-white/5 text-slate-600 dark:text-slate-300 hover:border-blue-500/30'
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-1.5 font-semibold text-xs">
                    <BookOpen className="w-3.5 h-3.5 text-emerald-400" />
                    <span>有道词典 / 翻译</span>
                  </div>
                  <span className="text-[9px] px-1.5 py-0.5 rounded-full bg-emerald-500/20 text-emerald-600 dark:text-emerald-300 font-medium">
                    权威汉英
                  </span>
                </div>
                <p className="text-[10px] text-slate-500 dark:text-slate-400 leading-snug">
                  有道智云权威中英词典、真题释义与全面词性拆解
                </p>
              </button>

              {/* 4. Offline */}
              <button
                type="button"
                onClick={() => onUpdateSettings({ translationEngine: 'offline' })}
                className={`p-3 rounded-xl border text-left transition-all cursor-pointer relative ${
                  currentEngine === 'offline'
                    ? 'border-emerald-500 bg-emerald-500/10 text-slate-900 dark:text-white ring-1 ring-emerald-500/40'
                    : 'border-black/5 dark:border-white/10 bg-black/5 dark:bg-white/5 text-slate-600 dark:text-slate-300 hover:border-emerald-500/30'
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-1.5 font-semibold text-xs">
                    <WifiOff className="w-3.5 h-3.5 text-amber-400" />
                    <span>离线词库 / 翻译</span>
                  </div>
                  <span className="text-[9px] px-1.5 py-0.5 rounded-full bg-amber-500/20 text-amber-600 dark:text-amber-300 font-medium">
                    零延迟 · 离线
                  </span>
                </div>
                <p className="text-[10px] text-slate-500 dark:text-slate-400 leading-snug">
                  100% 脱机工作，内置高频词汇与形态识别，无网络依赖
                </p>
              </button>
            </div>

            {/* Selected Engine API Key Configuration Form */}
            <div className="p-3.5 rounded-xl border border-black/5 dark:border-white/10 bg-black/5 dark:bg-white/5 space-y-3">
              {currentEngine === 'gemini' && (
                <div className="space-y-2.5">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5 font-semibold text-slate-800 dark:text-slate-200">
                      <Key className="w-3.5 h-3.5 text-blue-500" />
                      <span>Gemini API Key 配置</span>
                    </div>
                    <span className="text-[10px] text-emerald-500 font-medium">
                      {engineKeys.geminiKey ? '● 自定义密钥生效中' : '● 系统默认密钥生效中'}
                    </span>
                  </div>
                  <div className="relative flex items-center">
                    <input
                      type={showGeminiKey ? 'text' : 'password'}
                      value={engineKeys.geminiKey || ''}
                      onChange={(e) => handleKeyChange('geminiKey', e.target.value)}
                      placeholder="留空则自动使用系统内置 Gemini 密钥"
                      className="w-full pr-16 pl-3 py-1.5 bg-black/5 dark:bg-black/30 border border-black/10 dark:border-white/15 rounded-lg text-xs font-mono focus:outline-hidden focus:border-blue-500"
                    />
                    <div className="absolute right-1.5 flex items-center gap-1">
                      <button
                        type="button"
                        onClick={() => setShowGeminiKey(!showGeminiKey)}
                        className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
                        title={showGeminiKey ? '隐藏密钥' : '显示密钥'}
                      >
                        {showGeminiKey ? <EyeOff className="w-3.5 h-3.5" /> : <Eye className="w-3.5 h-3.5" />}
                      </button>
                    </div>
                  </div>
                  <div className="flex items-center justify-between text-[11px] text-slate-500 dark:text-slate-400">
                    <span>支持输入个人专属密钥，独享个人 Quota 配额与高速通道</span>
                    <button
                      type="button"
                      disabled={testingEngine === 'gemini'}
                      onClick={() => handleTestConnection('gemini')}
                      className="px-2.5 py-1 rounded-md text-[10px] font-medium bg-blue-600 hover:bg-blue-500 text-white disabled:opacity-50 transition-colors cursor-pointer flex items-center gap-1"
                    >
                      {testingEngine === 'gemini' && <RotateCw className="w-2.5 h-2.5 animate-spin" />}
                      测试连通性
                    </button>
                  </div>
                </div>
              )}

              {currentEngine === 'deepl' && (
                <div className="space-y-2.5">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5 font-semibold text-slate-800 dark:text-slate-200">
                      <Key className="w-3.5 h-3.5 text-indigo-500" />
                      <span>DeepL API Key 配置</span>
                    </div>
                    <span className="text-[10px] text-slate-400">
                      支持 DeepL Free (:fx) 与 DeepL Pro
                    </span>
                  </div>
                  <div className="relative flex items-center">
                    <input
                      type={showDeeplKey ? 'text' : 'password'}
                      value={engineKeys.deeplKey || ''}
                      onChange={(e) => handleKeyChange('deeplKey', e.target.value)}
                      placeholder="输入 DeepL 官方 API 密钥 (如 12345678-xxxx-...:fx)"
                      className="w-full pr-16 pl-3 py-1.5 bg-black/5 dark:bg-black/30 border border-black/10 dark:border-white/15 rounded-lg text-xs font-mono focus:outline-hidden focus:border-indigo-500"
                    />
                    <div className="absolute right-1.5 flex items-center gap-1">
                      <button
                        type="button"
                        onClick={() => setShowDeeplKey(!showDeeplKey)}
                        className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
                        title={showDeeplKey ? '隐藏密钥' : '显示密钥'}
                      >
                        {showDeeplKey ? <EyeOff className="w-3.5 h-3.5" /> : <Eye className="w-3.5 h-3.5" />}
                      </button>
                    </div>
                  </div>
                  <div className="flex items-center justify-between text-[11px] text-slate-500 dark:text-slate-400">
                    <span>前往 deepl.com/pro-api 获取免费或专业版密钥</span>
                    <button
                      type="button"
                      disabled={testingEngine === 'deepl'}
                      onClick={() => handleTestConnection('deepl')}
                      className="px-2.5 py-1 rounded-md text-[10px] font-medium bg-indigo-600 hover:bg-indigo-500 text-white disabled:opacity-50 transition-colors cursor-pointer flex items-center gap-1"
                    >
                      {testingEngine === 'deepl' && <RotateCw className="w-2.5 h-2.5 animate-spin" />}
                      测试连通性
                    </button>
                  </div>
                </div>
              )}

              {currentEngine === 'youdao' && (
                <div className="space-y-2.5">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5 font-semibold text-slate-800 dark:text-slate-200">
                      <Key className="w-3.5 h-3.5 text-emerald-500" />
                      <span>有道智云 API 凭证配置</span>
                    </div>
                    <span className="text-[10px] text-slate-400">
                      openapi.youdao.com
                    </span>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                    <div>
                      <label className="text-[10px] text-slate-500 mb-1 block">应用 ID (AppKey)</label>
                      <input
                        type="text"
                        value={engineKeys.youdaoAppKey || ''}
                        onChange={(e) => handleKeyChange('youdaoAppKey', e.target.value)}
                        placeholder="有道智云 AppKey"
                        className="w-full px-3 py-1.5 bg-black/5 dark:bg-black/30 border border-black/10 dark:border-white/15 rounded-lg text-xs font-mono focus:outline-hidden focus:border-emerald-500"
                      />
                    </div>
                    <div>
                      <label className="text-[10px] text-slate-500 mb-1 block">应用密钥 (AppSecret)</label>
                      <div className="relative flex items-center">
                        <input
                          type={showYoudaoSecret ? 'text' : 'password'}
                          value={engineKeys.youdaoAppSecret || ''}
                          onChange={(e) => handleKeyChange('youdaoAppSecret', e.target.value)}
                          placeholder="有道智云 AppSecret"
                          className="w-full pr-8 px-3 py-1.5 bg-black/5 dark:bg-black/30 border border-black/10 dark:border-white/15 rounded-lg text-xs font-mono focus:outline-hidden focus:border-emerald-500"
                        />
                        <button
                          type="button"
                          onClick={() => setShowYoudaoSecret(!showYoudaoSecret)}
                          className="absolute right-1.5 p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
                          title={showYoudaoSecret ? '隐藏密钥' : '显示密钥'}
                        >
                          {showYoudaoSecret ? <EyeOff className="w-3.5 h-3.5" /> : <Eye className="w-3.5 h-3.5" />}
                        </button>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center justify-between text-[11px] text-slate-500 dark:text-slate-400 pt-0.5">
                    <span>登录有道智云控制台创建“文本翻译”应用获取</span>
                    <button
                      type="button"
                      disabled={testingEngine === 'youdao'}
                      onClick={() => handleTestConnection('youdao')}
                      className="px-2.5 py-1 rounded-md text-[10px] font-medium bg-emerald-600 hover:bg-emerald-500 text-white disabled:opacity-50 transition-colors cursor-pointer flex items-center gap-1"
                    >
                      {testingEngine === 'youdao' && <RotateCw className="w-2.5 h-2.5 animate-spin" />}
                      测试连通性
                    </button>
                  </div>
                </div>
              )}

              {currentEngine === 'offline' && (
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5 font-semibold text-emerald-600 dark:text-emerald-400">
                      <CheckCircle2 className="w-4 h-4" />
                      <span>纯离线词典引擎已就绪 (100% 离线)</span>
                    </div>
                    <span className="text-[10px] px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 font-medium">
                      无需 API Key
                    </span>
                  </div>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400 leading-relaxed">
                    已内置海量高频常用中英词典、国际音标、语法形态词形还原（自动识别复数、过去式、进行时态与副词形式）及日常习惯用语短句。在无网络环境下完全脱机运行，零延迟瞬时响应。
                  </p>
                  <div className="flex justify-end pt-1">
                    <button
                      type="button"
                      disabled={testingEngine === 'offline'}
                      onClick={() => handleTestConnection('offline')}
                      className="px-2.5 py-1 rounded-md text-[10px] font-medium bg-emerald-600 hover:bg-emerald-500 text-white disabled:opacity-50 transition-colors cursor-pointer flex items-center gap-1"
                    >
                      {testingEngine === 'offline' && <RotateCw className="w-2.5 h-2.5 animate-spin" />}
                      测试离线引擎响应
                    </button>
                  </div>
                </div>
              )}

              {/* Test Result Feedback Banner */}
              {testResult && (
                <div
                  className={`p-2.5 rounded-lg text-xs flex items-start gap-2 animate-in fade-in duration-150 ${
                    testResult.success
                      ? 'bg-emerald-500/10 border border-emerald-500/30 text-emerald-600 dark:text-emerald-300'
                      : 'bg-rose-500/10 border border-rose-500/30 text-rose-600 dark:text-rose-300'
                  }`}
                >
                  {testResult.success ? (
                    <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5 text-emerald-500" />
                  ) : (
                    <AlertCircle className="w-4 h-4 shrink-0 mt-0.5 text-rose-500" />
                  )}
                  <div className="flex-1 text-[11px] leading-snug break-words">
                    {testResult.message}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Section 2: 划词翻译 与 触发方式 */}
          <div className="space-y-3 pt-2 border-t border-black/5 dark:border-white/10">
            <div className="font-semibold text-slate-900 dark:text-white flex items-center gap-1.5">
              <MousePointerClick className="w-3.5 h-3.5 text-blue-500" />
              <span>鼠标划词翻译交互</span>
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-black/5 dark:bg-white/5">
              <div className="space-y-0.5">
                <div className="font-semibold">开启即时划词翻译</div>
                <p className="text-[11px] text-slate-500 dark:text-slate-400">
                  在页面中划词选中，自动或通过气泡触发卡片翻译
                </p>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  checked={settings.selectionTranslation}
                  onChange={(e) => onUpdateSettings({ selectionTranslation: e.target.checked })}
                  className="sr-only peer"
                />
                <div className="w-9 h-5 bg-slate-300 peer-focus:outline-hidden rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-blue-600"></div>
              </label>
            </div>

            {settings.selectionTranslation && (
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => onUpdateSettings({ selectionTriggerMode: 'auto' })}
                  className={`p-2.5 rounded-lg border text-left transition-all cursor-pointer ${
                    settings.selectionTriggerMode === 'auto'
                      ? 'border-blue-500 bg-blue-500/10 text-blue-600 dark:text-blue-400 font-medium'
                      : 'border-transparent bg-black/5 dark:bg-white/5 text-slate-500'
                  }`}
                >
                  <div className="font-semibold">⚡ 自动填入卡片</div>
                  <div className="text-[10px] mt-0.5 opacity-80">划词松开即刻翻译</div>
                </button>
                <button
                  type="button"
                  onClick={() => onUpdateSettings({ selectionTriggerMode: 'icon' })}
                  className={`p-2.5 rounded-lg border text-left transition-all cursor-pointer ${
                    settings.selectionTriggerMode === 'icon'
                      ? 'border-blue-500 bg-blue-500/10 text-blue-600 dark:text-blue-400 font-medium'
                      : 'border-transparent bg-black/5 dark:bg-white/5 text-slate-500'
                  }`}
                >
                  <div className="font-semibold">🎈 鼠标旁气泡图标</div>
                  <div className="text-[10px] mt-0.5 opacity-80">点击图标再翻译，防误触</div>
                </button>
              </div>
            )}
          </div>

          {/* Section 3: 自动朗读发音 */}
          <div className="flex items-center justify-between p-3 rounded-xl bg-black/5 dark:bg-white/5">
            <div className="space-y-0.5">
              <div className="font-semibold flex items-center gap-1.5">
                <Volume2 className="w-3.5 h-3.5 text-blue-500" />
                <span>查询单字后自动朗读发音</span>
              </div>
              <p className="text-[11px] text-slate-500 dark:text-slate-400">
                查词成功后自动播放该单词英美真人纯正发音
              </p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={settings.autoSpeak}
                onChange={(e) => onUpdateSettings({ autoSpeak: e.target.checked })}
                className="sr-only peer"
              />
              <div className="w-9 h-5 bg-slate-300 peer-focus:outline-hidden rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
          </div>

          {/* Section 4: 卡片透明度调节 */}
          <div className="p-3 rounded-xl bg-black/5 dark:bg-white/5 space-y-2">
            <div className="flex items-center justify-between">
              <div className="font-semibold flex items-center gap-1.5">
                <Eye className="w-3.5 h-3.5 text-blue-500" />
                <span>悬浮卡片透明度 (防遮挡)</span>
              </div>
              <span className="font-mono text-xs text-blue-600 dark:text-blue-400">
                {Math.round(settings.cardOpacity * 100)}%
              </span>
            </div>
            <input
              type="range"
              min="0.55"
              max="1.0"
              step="0.05"
              value={settings.cardOpacity}
              onChange={(e) => onUpdateSettings({ cardOpacity: parseFloat(e.target.value) })}
              className="w-full accent-blue-500 cursor-pointer h-1.5 bg-slate-200 dark:bg-slate-700 rounded-lg"
            />
            <div className="flex justify-between text-[10px] text-slate-400">
              <span>半透明轻量</span>
              <span>清晰毛玻璃</span>
              <span>高对比实体</span>
            </div>
          </div>

          {/* Section 5: 界面字体自定义大小 (支持直接数值输入与预设) */}
          <div className="p-3 rounded-xl bg-black/5 dark:bg-white/5 space-y-2.5">
            <div className="flex items-center justify-between">
              <div className="font-semibold flex items-center gap-1.5">
                <Type className="w-3.5 h-3.5 text-blue-500" />
                <span>悬浮卡片字体大小与排版</span>
              </div>
              <span className="font-mono text-xs text-blue-600 dark:text-blue-400 font-semibold">
                {settings.customFontSize
                  ? `${settings.customFontSize}%`
                  : settings.fontSize === 'small'
                  ? '紧凑 (82%)'
                  : settings.fontSize === 'large'
                  ? '大号 (108%)'
                  : settings.fontSize === 'huge'
                  ? '特大 (125%)'
                  : '默认 (92%)'}
              </span>
            </div>

            {/* Direct Input Field */}
            <div className="flex items-center justify-between gap-2 p-2 rounded-lg bg-black/5 dark:bg-white/5 border border-black/5 dark:border-white/10">
              <div className="space-y-0.5 min-w-0">
                <div className="text-xs font-medium text-slate-700 dark:text-slate-200">
                  支持直接输入字号百分比
                </div>
                <div className="text-[10px] text-slate-400">
                  默认 92% 更精致和谐，支持范围 60% ~ 150%
                </div>
              </div>
              <div className="relative w-24 shrink-0">
                <input
                  type="number"
                  min={60}
                  max={150}
                  step={1}
                  value={
                    settings.customFontSize ??
                    (settings.fontSize === 'small'
                      ? 82
                      : settings.fontSize === 'large'
                      ? 108
                      : settings.fontSize === 'huge'
                      ? 125
                      : 92)
                  }
                  onChange={(e) => {
                    const val = parseInt(e.target.value, 10);
                    if (!isNaN(val)) {
                      onUpdateSettings({
                        customFontSize: Math.max(60, Math.min(150, val)),
                        fontSize: 'custom',
                      });
                    }
                  }}
                  className="w-full px-2 py-1 text-center font-mono font-semibold text-xs rounded-lg bg-white dark:bg-black/40 border border-slate-300 dark:border-white/20 text-slate-900 dark:text-white focus:outline-hidden focus:border-blue-500 pr-6"
                />
                <span className="absolute right-2 top-1/2 -translate-y-1/2 text-[10px] text-slate-400 font-mono pointer-events-none">
                  %
                </span>
              </div>
            </div>

            <div className="grid grid-cols-4 gap-1.5">
              {[
                { id: 'small', percent: 82, label: '小号', scale: '82%', desc: '紧凑自适应' },
                { id: 'medium', percent: 92, label: '默认', scale: '92%', desc: '精致协调' },
                { id: 'standard', percent: 100, label: '标准', scale: '100%', desc: '平衡阅读' },
                { id: 'large', percent: 108, label: '大号', scale: '108%', desc: '舒缓清晰' },
              ].map((f) => (
                <button
                  key={f.id}
                  type="button"
                  onClick={() =>
                    onUpdateSettings({
                      customFontSize: f.percent,
                      fontSize: f.id === 'medium' ? 'medium' : f.id === 'small' ? 'small' : 'custom',
                    })
                  }
                  className={`py-2 px-1.5 rounded-xl border text-center transition-all cursor-pointer ${
                    (settings.customFontSize === f.percent ||
                      (!settings.customFontSize &&
                        ((f.id === 'medium' && (!settings.fontSize || settings.fontSize === 'medium')) ||
                          settings.fontSize === f.id)))
                      ? 'border-blue-500 bg-blue-500/10 text-blue-600 dark:text-blue-400 font-semibold shadow-xs ring-1 ring-blue-500/20'
                      : 'border-transparent bg-black/5 dark:bg-white/5 hover:border-slate-300 dark:hover:border-white/20 text-slate-600 dark:text-slate-300'
                  }`}
                >
                  <div className="text-xs font-semibold">{f.label}</div>
                  <div className="text-[10px] text-blue-500/80 font-mono mt-0.5">{f.scale}</div>
                  <div className="text-[9px] text-slate-400 mt-0.5">{f.desc}</div>
                </button>
              ))}
            </div>

            {/* Compact Mode Switch */}
            <div className="flex items-center justify-between pt-1 text-xs">
              <span className="text-slate-600 dark:text-slate-400 text-[11px]">
                动态紧凑排版 (卡片缩小或手动开启时减少行间距与外边距)
              </span>
              <button
                type="button"
                onClick={() => onUpdateSettings({ compactMode: !settings.compactMode })}
                className={`px-2.5 py-1 rounded-full text-xs font-medium border transition-colors cursor-pointer ${
                  settings.compactMode
                    ? 'bg-blue-600 text-white border-blue-600'
                    : 'bg-black/5 dark:bg-white/5 text-slate-500 border-black/10 dark:border-white/10'
                }`}
              >
                {settings.compactMode ? '已开启' : '跟随卡片尺寸'}
              </button>
            </div>
          </div>

          {/* Section 6: 桌面壁纸风格 */}
          <div className="p-3 rounded-xl bg-black/5 dark:bg-white/5 space-y-2">
            <div className="font-semibold flex items-center gap-1.5">
              <Monitor className="w-3.5 h-3.5 text-blue-500" />
              <span>模拟桌面壁纸环境</span>
            </div>
            <div className="grid grid-cols-5 gap-1.5">
              {[
                { id: 'frosted-glass', label: '极光夜空', color: 'bg-gradient-to-br from-[#1c1340] via-[#09153a] to-[#0a0a1a]' },
                { id: 'sonoma-dark', label: '深色 Sonoma', color: 'bg-gradient-to-br from-[#1a1c29] to-[#0d0f18]' },
                { id: 'monterey', label: 'Monterey 紫晶', color: 'bg-gradient-to-br from-[#2b1055] to-[#7597de]' },
                { id: 'graphite', label: '石墨深空', color: 'bg-gradient-to-br from-[#121217] to-[#1f222e]' },
                { id: 'minimal-light', label: '极简白昼', color: 'bg-gradient-to-br from-[#e0e7ff] to-[#f8fafc]' },
              ].map((wp) => (
                <button
                  key={wp.id}
                  type="button"
                  onClick={() => onUpdateSettings({ desktopWallpaper: wp.id as any })}
                  className={`flex flex-col items-center gap-1.5 p-1 rounded-xl border transition-all cursor-pointer ${
                    settings.desktopWallpaper === wp.id
                      ? 'border-blue-500 ring-2 ring-blue-500/20'
                      : 'border-transparent hover:border-slate-300'
                  }`}
                >
                  <div className={`w-full h-7 rounded-lg ${wp.color} shadow-xs`} />
                  <span className="text-[9px] truncate max-w-full">{wp.label}</span>
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Modal Footer */}
        <div className="px-5 py-3 border-t border-black/5 dark:border-white/10 flex items-center justify-between shrink-0">
          <div className="text-[11px] text-slate-400">
            设置将自动保存于本地浏览器存储
          </div>
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-1.5 rounded-xl text-xs font-semibold bg-blue-600 hover:bg-blue-500 text-white shadow-sm transition-colors cursor-pointer"
          >
            完成
          </button>
        </div>
      </div>
    </div>
  );
};
