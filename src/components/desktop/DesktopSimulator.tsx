import React, { useState } from 'react';
import {
  Globe,
  FileText,
  Search,
  Wifi,
  Sparkles,
  Bookmark,
  ExternalLink,
  HelpCircle,
  Lightbulb,
  MousePointer,
  ChevronRight,
  Zap,
  Crop,
  Code2,
  Monitor,
  Laptop,
  Check,
  Copy,
  Terminal,
  X,
  Layers,
  Sparkle,
  Download,
} from 'lucide-react';
import { AppSettings } from '../../types';
import { DownloadModal } from '../common/DownloadModal';

interface DesktopSimulatorProps {
  settings: AppSettings;
  onQuickSelectWord: (text: string) => void;
  onOpenSnipper?: () => void;
  isDark?: boolean;
}

export const DesktopSimulator: React.FC<DesktopSimulatorProps> = ({
  settings,
  onQuickSelectWord,
  onOpenSnipper,
  isDark = true,
}) => {
  const [activeTab, setActiveTab] = useState<'tech' | 'story' | 'vocab' | 'bilingual'>('bilingual');
  const [workspaceScene, setWorkspaceScene] = useState<'reader' | 'vscode' | 'pure'>('reader');
  const [showDesktopGuide, setShowDesktopGuide] = useState(false);
  const [showDownloadModal, setShowDownloadModal] = useState(false);
  const [copiedCmd, setCopiedCmd] = useState<string | null>(null);

  const handleCopy = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedCmd(id);
    setTimeout(() => setCopiedCmd(null), 2000);
  };

  return (
    <div
      id="desktop-simulator-workspace"
      className="w-full h-full flex flex-col relative overflow-hidden select-text"
    >
      {/* macOS / Windows Desktop Top Menu Bar */}
      <header className="h-8 w-full bg-black/50 backdrop-blur-xl border-b border-white/10 px-3.5 flex items-center justify-between text-xs text-slate-200 z-20 select-none">
        <div className="flex items-center gap-3 sm:gap-4">
          <div className="font-bold text-[13px] flex items-center gap-1.5 text-white">
            <span className="text-sm"></span>
            <span className="font-semibold text-xs tracking-tight">Linguist</span>
          </div>

          {/* Workspace scene selector */}
          <div className="flex items-center p-0.5 rounded-lg bg-white/10 border border-white/10 text-[11px]">
            <button
              type="button"
              onClick={() => setWorkspaceScene('reader')}
              className={`px-2 py-0.5 rounded-md flex items-center gap-1 transition-colors cursor-pointer ${
                workspaceScene === 'reader'
                  ? 'bg-blue-600 text-white font-medium shadow-xs'
                  : 'text-slate-300 hover:text-white'
              }`}
              title="切换至双语阅读器工作区"
            >
              <Globe className="w-3 h-3" />
              <span className="hidden xs:inline">双语阅读</span>
            </button>
            <button
              type="button"
              onClick={() => setWorkspaceScene('vscode')}
              className={`px-2 py-0.5 rounded-md flex items-center gap-1 transition-colors cursor-pointer ${
                workspaceScene === 'vscode'
                  ? 'bg-blue-600 text-white font-medium shadow-xs'
                  : 'text-slate-300 hover:text-white'
              }`}
              title="切换至 VS Code 编程工作区 (划词测试代码)"
            >
              <Code2 className="w-3 h-3" />
              <span className="hidden xs:inline">VS Code</span>
            </button>
            <button
              type="button"
              onClick={() => setWorkspaceScene('pure')}
              className={`px-2 py-0.5 rounded-md flex items-center gap-1 transition-colors cursor-pointer ${
                workspaceScene === 'pure'
                  ? 'bg-blue-600 text-white font-medium shadow-xs'
                  : 'text-slate-300 hover:text-white'
              }`}
              title="切换至纯净桌面壁纸 (无遮挡悬浮测试)"
            >
              <Monitor className="w-3 h-3" />
              <span className="hidden xs:inline">纯净桌面</span>
            </button>
          </div>
        </div>

        {/* Right status bar */}
        <div className="flex items-center gap-2 sm:gap-3 text-[11px] text-slate-300">
          <button
            type="button"
            onClick={() => setShowDownloadModal(true)}
            className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-linear-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white font-medium text-[11px] shadow-sm transition-all cursor-pointer"
            title="下载已为您在云端完整打包好的 Windows 绿色便携版 (解压双击即可运行)"
          >
            <Download className="w-3.5 h-3.5" />
            <span>📥 下载 Windows 打包版 (197MB)</span>
          </button>

          <button
            type="button"
            onClick={() => setShowDesktopGuide(true)}
            className="hidden md:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-blue-500/20 hover:bg-blue-500/30 text-blue-300 border border-blue-400/30 transition-all cursor-pointer font-medium text-[11px]"
            title="查看桌面端运行与打包指南"
          >
            <Laptop className="w-3.5 h-3.5 text-blue-400" />
            <span>桌面端指南</span>
          </button>

          <button
            type="button"
            onClick={onOpenSnipper}
            className="hidden sm:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white/10 hover:bg-white/20 text-[11px] text-slate-200 border border-white/20 transition-all cursor-pointer"
            title="点击启动截图/框选翻译"
          >
            <Crop className="w-3 h-3 text-blue-400 animate-pulse" />
            <span>截图翻译</span>
          </button>

          <Wifi className="w-3.5 h-3.5 text-slate-300 hidden xs:block" />
          <span className="font-mono text-[11px]">
            {new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </span>
        </div>
      </header>

      {/* Main Desktop Area with Mock Browser / Article Reader Window */}
      <div className="flex-1 p-2 sm:p-4 md:p-6 lg:p-8 flex flex-col items-center justify-start overflow-y-auto z-10 pb-20 w-full max-w-5xl mx-auto">
        {/* Floating guidance banner */}
        <div className="w-full mb-3 p-2.5 sm:p-3 rounded-2xl bg-white/10 backdrop-blur-md border border-white/15 text-slate-100 flex items-center justify-between gap-2.5 shadow-lg">
          <div className="flex items-center gap-2 text-xs min-w-0">
            <div className="w-6 h-6 rounded-lg bg-blue-500/20 text-blue-300 flex items-center justify-center shrink-0">
              <MousePointer className="w-3.5 h-3.5" />
            </div>
            <div className="truncate sm:whitespace-normal">
              <span className="font-semibold text-white">使用指南：</span>
              <span className="text-slate-200 text-[11px] sm:text-xs">
                在文档中划词直接翻译，点击「截图翻译」框选文字逐行对照；拖动卡片边缘可自由拉伸缩小直至药丸胶囊！
              </span>
            </div>
          </div>
          <div className="flex items-center gap-1.5 shrink-0">
            <button
              type="button"
              onClick={onOpenSnipper}
              className="text-[11px] px-2.5 py-1 rounded-lg bg-blue-600 hover:bg-blue-500 text-white font-medium transition-colors flex items-center gap-1 cursor-pointer shadow-md"
            >
              <Crop className="w-3 h-3" />
              <span className="hidden xs:inline">截屏识字</span>
            </button>
          </div>
        </div>

        {/* Mock Application Window (Safari / Notes / Literature Reader) */}
        {workspaceScene === 'reader' && (
          <div
            id="mock-browser-document"
            className="w-full rounded-2xl bg-slate-900/60 backdrop-blur-xl border border-white/15 shadow-2xl overflow-hidden text-slate-200 flex flex-col"
          >
          {/* Mock Browser Header */}
          <div className="px-3 sm:px-4 py-2 border-b border-white/10 bg-slate-950/40 flex items-center justify-between gap-2 flex-wrap sm:flex-nowrap">
            <div className="flex items-center gap-2 min-w-0">
              <div className="flex gap-1.5 shrink-0">
                <span className="w-2.5 h-2.5 rounded-full bg-rose-500/80 inline-block" />
                <span className="w-2.5 h-2.5 rounded-full bg-amber-500/80 inline-block" />
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500/80 inline-block" />
              </div>
              <div className="ml-1 sm:ml-3 px-2 sm:px-3 py-1 rounded-lg bg-white/5 border border-white/10 text-[11px] text-slate-300 flex items-center gap-1.5 max-w-[180px] sm:max-w-xs truncate">
                <Globe className="w-3 h-3 text-slate-400 shrink-0" />
                <span className="truncate">reader.digest/daily</span>
              </div>
            </div>

            {/* Switch tabs */}
            <div className="flex items-center gap-1 text-xs overflow-x-auto max-w-full py-0.5 no-scrollbar">
              <button
                type="button"
                onClick={() => setActiveTab('bilingual')}
                className={`px-2 py-1 rounded-lg transition-colors whitespace-nowrap ${
                  activeTab === 'bilingual' ? 'bg-white/15 text-white font-medium' : 'text-slate-400 hover:text-white'
                }`}
              >
                经典双语
              </button>
              <button
                type="button"
                onClick={() => setActiveTab('tech')}
                className={`px-2 py-1 rounded-lg transition-colors whitespace-nowrap ${
                  activeTab === 'tech' ? 'bg-white/15 text-white font-medium' : 'text-slate-400 hover:text-white'
                }`}
              >
                前沿科技
              </button>
              <button
                type="button"
                onClick={() => setActiveTab('story')}
                className={`px-2 py-1 rounded-lg transition-colors whitespace-nowrap ${
                  activeTab === 'story' ? 'bg-white/15 text-white font-medium' : 'text-slate-400 hover:text-white'
                }`}
              >
                双语散文
              </button>
              <button
                type="button"
                onClick={() => setActiveTab('vocab')}
                className={`px-2 py-1 rounded-lg transition-colors whitespace-nowrap ${
                  activeTab === 'vocab' ? 'bg-white/15 text-white font-medium' : 'text-slate-400 hover:text-white'
                }`}
              >
                高频词汇
              </button>
            </div>
          </div>

          {/* Article Content with rich selectable text */}
          <div className="p-6 md:p-8 space-y-6 text-sm leading-relaxed">
            {activeTab === 'bilingual' && (
              <>
                <div className="border-b border-white/10 pb-4 flex items-center justify-between">
                  <div>
                    <div className="text-xs uppercase tracking-wider text-blue-400 font-semibold mb-1 flex items-center gap-1.5">
                      <Sparkles className="w-3 h-3" /> Literature Reader • Interleaved Bilingual Demo
                    </div>
                    <h1 className="text-xl md:text-2xl font-bold text-white tracking-tight">
                      Morning Reflections & Dreams
                    </h1>
                  </div>
                  {onOpenSnipper && (
                    <button
                      type="button"
                      onClick={onOpenSnipper}
                      className="px-3 py-1.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white text-xs font-medium flex items-center gap-1.5 cursor-pointer shadow-md transition-colors"
                      title="截取下方段落体验一句一对照"
                    >
                      <Crop className="w-3.5 h-3.5" />
                      <span>截此区域</span>
                    </button>
                  )}
                </div>

                {/* The exact passage from user's image */}
                <div className="space-y-4 font-sans text-base leading-relaxed text-slate-100">
                  <p>
                    <strong>The sun rises every morning, bringing a brand new day.</strong>
                  </p>
                  <p>
                    <strong>We all have dreams in our hearts.</strong>
                  </p>
                  <p>
                    <strong>However, big dreams do not come true overnight.</strong>
                  </p>
                  <p>
                    <strong>They need our time, patience, and hard work.</strong>
                  </p>
                  <p>
                    <strong>Do not be afraid of small steps.</strong>
                  </p>
                  <p>
                    <strong>When you read one page of a book today, you learn something new.</strong>
                  </p>
                </div>
              </>
            )}
            {activeTab === 'tech' && (
              <>
                <div className="border-b border-white/10 pb-4">
                  <div className="text-xs uppercase tracking-wider text-blue-400 font-semibold mb-1 flex items-center gap-1.5">
                    <Sparkles className="w-3 h-3" /> Tech Digest • Next-Gen AI & Computational Linguistics
                  </div>
                  <h1 className="text-xl md:text-2xl font-bold text-white tracking-tight">
                    The Modern Architectures of Real-Time Desktop Translation
                  </h1>
                  <p className="text-xs text-slate-400 mt-1">
                    Published by AI Systems Review • 5 min read • Try highlighting any phrase below
                  </p>
                </div>

                <p className="text-slate-200">
                  In computational linguistics, an intelligent floating assistant allows researchers and polyglots to
                  read foreign documentation effortlessly. The <mark className="bg-blue-500/30 text-white rounded px-1">linguist</mark> card
                  hovers gently on top of the workspace without obstructing the viewport, granting ubiquitous access to contextual translations.
                </p>

                <p className="text-slate-300">
                  Historically, desktop tools were clunky and intrusive. Contemporary interface design prioritizes
                  translucency, fluid animations, and immediate mouse selection translation. When an engineer selects an unfamiliar keyword like
                  <span className="font-semibold text-blue-300 mx-1">phenomenon</span>,
                  <span className="font-semibold text-blue-300 mx-1">ubiquitous</span>, or
                  <span className="font-semibold text-blue-300 mx-1">serendipity</span>,
                  the desktop translator automatically parses the word, retrieves accurate IPA phonetic symbols, and generates nuanced grammatical definitions.
                </p>

                <div className="p-4 rounded-xl bg-white/5 border border-white/10 text-xs italic text-slate-300">
                  "The limits of my language mean the limits of my world." — Ludwig Wittgenstein
                </div>
              </>
            )}

            {activeTab === 'story' && (
              <>
                <div className="border-b border-white/10 pb-4">
                  <div className="text-xs uppercase tracking-wider text-amber-400 font-semibold mb-1 flex items-center gap-1.5">
                    <Bookmark className="w-3 h-3" /> Literature & Prose • The Poetics of Space
                  </div>
                  <h1 className="text-xl md:text-2xl font-bold text-white tracking-tight">
                    An Ode to Ephemeral Moments and Morning Light
                  </h1>
                </div>

                <p className="text-slate-200">
                  There is an undeniable <span className="underline decoration-amber-400/50 underline-offset-4">elegance</span> in quiet contemplation.
                  As dawn breaks across the horizon, the golden light filters through translucent panes of glass, casting delicate reflections upon the wooden desk.
                </p>

                <p className="text-slate-300">
                  Words are vessels of human sentiment. The word <span className="font-semibold text-amber-300">nostalgia</span> evokes bittersweet memories of places once cherished,
                  while <span className="font-semibold text-amber-300">wanderlust</span> ignites the irresistible urge to venture beyond familiar boundaries.
                  Translating literature requires not merely lexical substitution, but capturing the poetic resonance between souls.
                </p>
              </>
            )}

            {activeTab === 'vocab' && (
              <>
                <div className="border-b border-white/10 pb-4">
                  <div className="text-xs uppercase tracking-wider text-emerald-400 font-semibold mb-1 flex items-center gap-1.5">
                    <Zap className="w-3 h-3" /> Vocabulary Cards • High Frequency Word Bank
                  </div>
                  <h1 className="text-xl md:text-2xl font-bold text-white tracking-tight">
                    Core Academic & Literary Vocabulary
                  </h1>
                  <p className="text-xs text-slate-400 mt-1">
                    点击或划词选择任意词条，查看卡片精准音标及多重词义
                  </p>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {[
                    { word: 'eloquent', meaning: '雄辩的，有说服力的', sample: 'She delivered an eloquent defense of human rights.' },
                    { word: 'meticulous', meaning: '一丝不苟的，缜密的', sample: 'He was meticulous about keeping his records clean.' },
                    { word: 'resilience', meaning: '恢复力，坚韧不拔', sample: 'The team showed tremendous resilience under pressure.' },
                    { word: 'ephemeral', meaning: '短暂的，瞬息即逝的', sample: 'Fame in the digital age is often ephemeral.' },
                  ].map((item) => (
                    <div
                      key={item.word}
                      className="p-3.5 rounded-xl bg-white/5 border border-white/10 hover:border-blue-400/40 transition-colors"
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-bold text-white text-base">{item.word}</span>
                        <button
                          type="button"
                          onClick={() => onQuickSelectWord(item.word)}
                          className="text-[11px] text-blue-400 hover:text-blue-300 flex items-center gap-0.5"
                        >
                          <span>查词</span>
                          <ChevronRight className="w-3 h-3" />
                        </button>
                      </div>
                      <p className="text-xs text-slate-300 mt-1">{item.meaning}</p>
                      <p className="text-[11px] text-slate-400 mt-1.5 italic">"{item.sample}"</p>
                    </div>
                  ))}
                </div>
              </>
            )}
          </div>
        </div>
      )}

        {/* Workspace Scene 2: VS Code Developer IDE (划词测试代码注释与英文报错) */}
        {workspaceScene === 'vscode' && (
          <div
            id="mock-vscode-window"
            className="w-full rounded-2xl bg-[#1e1e1e] border border-white/15 shadow-2xl overflow-hidden text-slate-300 flex flex-col font-mono text-xs"
          >
            {/* VS Code Title Bar */}
            <div className="px-3 py-2 bg-[#252526] border-b border-white/10 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="flex gap-1.5 shrink-0">
                  <span className="w-2.5 h-2.5 rounded-full bg-rose-500/80 inline-block" />
                  <span className="w-2.5 h-2.5 rounded-full bg-amber-500/80 inline-block" />
                  <span className="w-2.5 h-2.5 rounded-full bg-emerald-500/80 inline-block" />
                </div>
                <span className="text-[11px] text-slate-400 font-sans ml-2">Visual Studio Code - LinguistCore</span>
              </div>
              <div className="flex items-center gap-1.5 text-[10px] text-slate-400 font-sans">
                <span className="px-1.5 py-0.5 bg-blue-500/20 text-blue-300 rounded border border-blue-400/30">TypeScript</span>
                <span>UTF-8</span>
              </div>
            </div>

            {/* Editor Tabs */}
            <div className="flex items-center bg-[#2d2d2d] border-b border-white/10 overflow-x-auto text-[11px]">
              <div className="px-3 py-1.5 bg-[#1e1e1e] border-t-2 border-blue-500 text-white flex items-center gap-1.5">
                <Code2 className="w-3 h-3 text-blue-400" />
                <span>translator.ts</span>
              </div>
              <div className="px-3 py-1.5 text-slate-400 hover:text-slate-200 flex items-center gap-1.5 cursor-pointer">
                <span>electron-main.ts</span>
              </div>
            </div>

            {/* Code Content */}
            <div className="p-4 sm:p-5 max-h-[60vh] overflow-y-auto space-y-1.5 leading-relaxed selection:bg-blue-600 selection:text-white">
              <p className="text-slate-500">// 提示：鼠标划选任意英文术语或报错信息，即可直接唤醒悬浮翻译：</p>
              <p>
                <span className="text-pink-400">interface</span> <span className="text-yellow-300">TranslationEngineOptions</span> &#123;
              </p>
              <p className="pl-4">
                <span className="text-blue-300">concurrencyLimit</span>: <span className="text-emerald-400">number</span>;
                <span className="text-slate-500 ml-3">// High-throughput asynchronous dispatch</span>
              </p>
              <p className="pl-4">
                <span className="text-blue-300">cacheStrategy</span>: <span className="text-amber-300">'immutable-offline'</span> | <span className="text-amber-300">'stale-while-revalidate'</span>;
              </p>
              <p className="pl-4">
                <span className="text-blue-300">fallbackEngine</span>: <span className="text-yellow-300">OfflineLocalDictionary</span>;
              </p>
              <p>&#125;</p>
              <p className="text-slate-500 pt-2">// Runtime exception handler example:</p>
              <p>
                <span className="text-purple-400">export async function</span> <span className="text-blue-400">executeInference</span>(prompt: <span className="text-emerald-400">string</span>) &#123;
              </p>
              <p className="pl-4">
                <span className="text-purple-400">try</span> &#123;
              </p>
              <p className="pl-8 text-slate-300">
                <span className="text-purple-400">const</span> response = <span className="text-purple-400">await</span> geminiClient.<span className="text-blue-300">generateContent</span>(prompt);
              </p>
              <p className="pl-8 text-slate-300">
                <span className="text-purple-400">return</span> response.text;
              </p>
              <p className="pl-4">
                &#125; <span className="text-purple-400">catch</span> (err) &#123;
              </p>
              <p className="pl-8 text-rose-400">
                <span className="text-slate-500">//</span> Error: Connection pool exhausted. Upstream gateway returned 504 Gateway Timeout.
              </p>
              <p className="pl-8 text-slate-300">
                console.<span className="text-blue-300">warn</span>(<span className="text-amber-300">"Gracefully degrading to offline dictionary model"</span>);
              </p>
              <p className="pl-4">&#125;</p>
              <p>&#125;</p>
            </div>
          </div>
        )}

        {/* Workspace Scene 3: Pure Clean Desktop (无遮挡桌面图标，呈现极致悬浮) */}
        {workspaceScene === 'pure' && (
          <div className="w-full flex-1 flex flex-col justify-between py-6">
            <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6 gap-6 max-w-2xl">
              {[
                { name: 'Finder', icon: '📁' },
                { name: 'Terminal', icon: '💻' },
                { name: 'Visual Studio', icon: '⚡' },
                { name: 'Paper_Draft.pdf', icon: '📄' },
                { name: 'Research_Notes', icon: '📝' },
                { name: 'Trash', icon: '🗑️' },
              ].map((item) => (
                <div
                  key={item.name}
                  className="flex flex-col items-center gap-1.5 p-2 rounded-xl hover:bg-white/10 transition-colors cursor-pointer group"
                >
                  <span className="text-3xl filter drop-shadow-md group-hover:scale-110 transition-transform">{item.icon}</span>
                  <span className="text-[11px] text-white/90 drop-shadow-sm font-medium tracking-tight text-center truncate w-full">
                    {item.name}
                  </span>
                </div>
              ))}
            </div>

            <div className="p-4 rounded-2xl bg-black/40 backdrop-blur-md border border-white/10 text-center max-w-md mx-auto text-slate-300 text-xs mt-8">
              <p className="font-semibold text-white mb-1">🌌 纯净桌面悬浮视图</p>
              <p className="text-slate-400 text-[11px]">
                您可以拖动翻译卡片至任意位置，缩放为药丸胶囊，体验纯粹的桌面磨砂与亚克力透光质感。
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Desktop Native Running Guide Modal (本地桌面端一键运行指南) */}
      {showDesktopGuide && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-md flex items-center justify-center p-4">
          <div className="w-full max-w-xl bg-[#0e111a] border border-white/20 rounded-2xl shadow-2xl p-5 space-y-4 text-slate-200 animate-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between border-b border-white/10 pb-3">
              <div className="flex items-center gap-2">
                <div className="w-7 h-7 rounded-lg bg-emerald-500/20 text-emerald-400 flex items-center justify-center">
                  <Laptop className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="font-bold text-white text-base">如何在本地电脑运行桌面端？</h3>
                  <p className="text-[11px] text-slate-400">Windows 11 亚克力磨砂 & macOS 原生悬浮客户端</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setShowDesktopGuide(false)}
                className="w-7 h-7 rounded-lg bg-white/5 hover:bg-white/10 text-slate-400 hover:text-white flex items-center justify-center cursor-pointer transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              {/* Ready-to-download Windows Client Card */}
              <div className="p-3.5 rounded-xl bg-linear-to-r from-emerald-950/80 via-slate-900 to-teal-950/80 border border-emerald-500/40 space-y-2.5">
                <div className="flex items-center justify-between gap-3 flex-wrap sm:flex-nowrap">
                  <div className="flex items-start gap-2.5 min-w-0">
                    <div className="w-8 h-8 rounded-lg bg-emerald-500/20 border border-emerald-500/30 text-emerald-400 flex items-center justify-center shrink-0 mt-0.5">
                      <Download className="w-4 h-4" />
                    </div>
                    <div>
                      <div className="font-bold text-white text-xs flex items-center gap-1.5">
                        <span>已为您在云端打包好 Windows 客户端！</span>
                        <span className="px-1.5 py-0.2 rounded bg-emerald-500/20 text-emerald-300 font-mono text-[9px] border border-emerald-500/30">197 MB</span>
                      </div>
                      <p className="text-[11px] text-slate-300 mt-0.5">
                        免安装绿色便携版，内含完整 Chromium 内核、亚克力毛玻璃窗口与快捷键支持。
                      </p>
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => setShowDownloadModal(true)}
                    className="px-3.5 py-1.5 rounded-xl bg-linear-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white font-semibold text-xs shadow-md flex items-center gap-1.5 transition-all cursor-pointer shrink-0"
                  >
                    <Download className="w-3.5 h-3.5" />
                    <span>立即下载 Windows 包 (.zip)</span>
                  </button>
                </div>
                <div className="text-[11px] text-emerald-200/90 bg-emerald-500/10 border border-emerald-500/20 px-2.5 py-1.5 rounded-lg flex items-center gap-1.5">
                  <Sparkles className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
                  <span><strong>使用方法：</strong>点击上方按钮下载 ZIP 压缩包，解压后双击运行 <strong>Linguist.exe</strong> 即可开箱即用！无需配置任何 Node.js 命令行环境。</span>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-blue-500/10 border border-blue-500/20 text-blue-200 space-y-1">
                <div className="font-semibold flex items-center gap-1.5">
                  <Sparkles className="w-3.5 h-3.5 text-blue-400" />
                  <span>为什么需要本地运行？</span>
                </div>
                <p className="text-[11px] text-blue-200/80 leading-relaxed">
                  当前您所在的 AI Studio 是运行在 Google Cloud 云端的无头 Linux 容器中（通过网页流式预览）。真正的 Windows 亚克力无边框窗口和全局快捷键（<code className="text-white">Alt+Space</code> / <code className="text-white">Alt+S</code>）需要在您本地计算机中直接运行。
                </p>
              </div>

              {/* Step 1 */}
              <div className="space-y-1.5">
                <div className="font-medium text-white flex items-center gap-1.5">
                  <span className="w-4 h-4 rounded-full bg-blue-600 text-[10px] flex items-center justify-center font-bold">1</span>
                  <span>导出代码并在本地安装依赖</span>
                </div>
                <p className="text-[11px] text-slate-400 pl-5">
                  点击 AI Studio 右上角「Export to GitHub」或下载 ZIP 解压到本地，在项目根目录打开终端执行：
                </p>
                <div className="ml-5 p-2 rounded-lg bg-black/50 border border-white/10 font-mono text-[11px] flex items-center justify-between">
                  <code>npm install</code>
                  <button
                    type="button"
                    onClick={() => handleCopy('npm install', 'install')}
                    className="text-slate-400 hover:text-white cursor-pointer"
                  >
                    {copiedCmd === 'install' ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                  </button>
                </div>
              </div>

              {/* Step 2 */}
              <div className="space-y-1.5">
                <div className="font-medium text-white flex items-center gap-1.5">
                  <span className="w-4 h-4 rounded-full bg-blue-600 text-[10px] flex items-center justify-center font-bold">2</span>
                  <span>一键启动原生透明桌面悬浮窗 (本地调试)</span>
                </div>
                <div className="ml-5 p-2 rounded-lg bg-black/50 border border-white/10 font-mono text-[11px] flex items-center justify-between">
                  <code className="text-emerald-400">npm run electron:dev</code>
                  <button
                    type="button"
                    onClick={() => handleCopy('npm run electron:dev', 'dev')}
                    className="text-slate-400 hover:text-white cursor-pointer"
                  >
                    {copiedCmd === 'dev' ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                  </button>
                </div>
              </div>

              {/* Step 3 */}
              <div className="space-y-1.5">
                <div className="font-medium text-white flex items-center gap-1.5">
                  <span className="w-4 h-4 rounded-full bg-blue-600 text-[10px] flex items-center justify-center font-bold">3</span>
                  <span>打包 Windows / macOS 独立客户端安装包</span>
                </div>
                <div className="ml-5 space-y-1.5">
                  <div className="p-2 rounded-lg bg-black/50 border border-white/10 font-mono text-[11px] flex items-center justify-between">
                    <div>
                      <span className="text-blue-400">Windows (.exe 安装包 & 便携版): </span>
                      <code>npm run electron:build:win</code>
                    </div>
                    <button
                      type="button"
                      onClick={() => handleCopy('npm run electron:build:win', 'win')}
                      className="text-slate-400 hover:text-white cursor-pointer"
                    >
                      {copiedCmd === 'win' ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                    </button>
                  </div>

                  <div className="p-2 rounded-lg bg-black/50 border border-white/10 font-mono text-[11px] flex items-center justify-between">
                    <div>
                      <span className="text-pink-400">macOS (.dmg 镜像): </span>
                      <code>npm run electron:build:mac</code>
                    </div>
                    <button
                      type="button"
                      onClick={() => handleCopy('npm run electron:build:mac', 'mac')}
                      className="text-slate-400 hover:text-white cursor-pointer"
                    >
                      {copiedCmd === 'mac' ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div className="pt-2 border-t border-white/10 flex justify-end">
              <button
                type="button"
                onClick={() => setShowDesktopGuide(false)}
                className="px-4 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-500 text-white font-medium text-xs transition-colors cursor-pointer"
              >
                我知道了，在 Web 仿真环境中继续体验
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Chunked Safe Download Modal */}
      <DownloadModal
        isOpen={showDownloadModal}
        onClose={() => setShowDownloadModal(false)}
      />
    </div>
  );
};
