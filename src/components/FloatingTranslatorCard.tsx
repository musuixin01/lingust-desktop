import React, { useState, useRef, useEffect } from 'react';
import {
  Pin,
  Copy,
  Volume2,
  Heart,
  RotateCcw,
  Sparkles,
  Sliders,
  History,
  Check,
  Minimize2,
  Maximize2,
  X,
  Languages,
  Crop,
  Camera,
  Search,
} from 'lucide-react';
import { TranslationResult, AppSettings } from '../types';
import { LanguageSelector } from './LanguageSelector';
import { WordDetailView } from './WordDetailView';
import { ScreenshotTranslationView } from './ScreenshotTranslationView';
import { speakText } from '../utils/speech';
import { HoverScrollText } from './HoverScrollText';

// Helper to construct complete translation text (把单词的音标、所有词性及全部释义完整翻译)
export const getCompleteTranslation = (res: TranslationResult | null): string => {
  if (!res) return '';
  if (res.isWord && res.definitions && res.definitions.length > 0) {
    const phonetic = res.phonetic?.us || res.phonetic?.uk || res.phonetic?.general;
    const phoneticPrefix = phonetic ? `[${phonetic.replace(/^\/|\/$/g, '')}] ` : '';
    const defs = res.definitions
      .map((d) => `${d.partOfSpeech ? `${d.partOfSpeech} ` : ''}${d.meaning}`)
      .join('； ');
    const syns =
      res.synonyms && res.synonyms.length > 0
        ? ` 【同义: ${res.synonyms.join(', ')}】`
        : '';
    return `${phoneticPrefix}${defs}${syns}`.trim();
  }
  return res.translatedText;
};

// Continuous looping marquee component for pill mode (循环自动滚动跑马灯)
interface MarqueeTextProps {
  text: string;
  className?: string;
  pillWidth: number;
  onOverflowChange?: (isOverflowing: boolean) => void;
}

const MarqueeText: React.FC<MarqueeTextProps> = ({ text, className = '', pillWidth, onOverflowChange }) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const measureRef = useRef<HTMLSpanElement>(null);
  const [shouldScroll, setShouldScroll] = useState(false);

  useEffect(() => {
    const checkOverflow = () => {
      if (containerRef.current && measureRef.current) {
        const containerW = containerRef.current.clientWidth;
        const textW = measureRef.current.scrollWidth;
        const isOverflow = textW > containerW + 4;
        setShouldScroll(isOverflow);
        onOverflowChange?.(isOverflow);
      }
    };

    checkOverflow();
    const ro = new ResizeObserver(checkOverflow);
    if (containerRef.current) ro.observe(containerRef.current);
    return () => ro.disconnect();
  }, [text, pillWidth, onOverflowChange]);

  // Duration scales dynamically with text length for optimal reading pacing
  const duration = Math.max(10, Math.min(36, text.length * 0.42));

  return (
    <div
      ref={containerRef}
      className="relative overflow-hidden whitespace-nowrap min-w-0 flex-1 mask-pill-marquee select-text"
      title={text}
    >
      {/* Off-screen unconstrained span to measure natural text width */}
      <span
        ref={measureRef}
        className="absolute -top-[9999px] -left-[9999px] opacity-0 pointer-events-none whitespace-nowrap text-xs font-semibold"
      >
        {text}
      </span>

      {shouldScroll ? (
        <div
          className="animate-marquee-scroll inline-flex items-center"
          style={{ animationDuration: `${duration}s` }}
        >
          <span className={className}>{text}</span>
          <span className="mx-4 text-emerald-400/50 text-[10px] select-none shrink-0">✦</span>
          <span className={className}>{text}</span>
          <span className="mx-4 text-emerald-400/50 text-[10px] select-none shrink-0">✦</span>
        </div>
      ) : (
        <span className={className}>{text}</span>
      )}
    </div>
  );
};

interface FloatingTranslatorCardProps {
  sourceText: string;
  onSourceTextChange: (text: string) => void;
  onTranslate: (text: string, src?: string, tgt?: string) => void;
  result: TranslationResult | null;
  loading: boolean;
  sourceLang: string;
  targetLang: string;
  onSourceLangChange: (lang: string) => void;
  onTargetLangChange: (lang: string) => void;
  onSwapLanguages: () => void;
  settings: AppSettings;
  onOpenSettings: () => void;
  onOpenHistory: () => void;
  onToggleFavorite: (id: string) => void;
  onSelectWord: (word: string) => void;
  onToggleSmartSelect?: () => void;
  onOpenSnipper?: () => void;
  onClearOcr?: () => void;
}

export const FloatingTranslatorCard: React.FC<FloatingTranslatorCardProps> = ({
  sourceText,
  onSourceTextChange,
  onTranslate,
  result,
  loading,
  sourceLang,
  targetLang,
  onSourceLangChange,
  onTargetLangChange,
  onSwapLanguages,
  settings,
  onOpenSettings,
  onOpenHistory,
  onToggleFavorite,
  onSelectWord,
  onToggleSmartSelect,
  onOpenSnipper,
  onClearOcr,
}) => {
  // Position & size state
  const [position, setPosition] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [size, setSize] = useState<{ width: number; height: number }>({ width: 380, height: 490 });
  const [isPinned, setIsPinned] = useState(true);
  const [isMinimized, setIsMinimized] = useState(false);
  const [copied, setCopied] = useState(false);
  const [isRightHovered, setIsRightHovered] = useState(false);
  const [isLeftHovered, setIsLeftHovered] = useState(false);
  const [isSearchFocused, setIsSearchFocused] = useState(false);
  const [activeTooltip, setActiveTooltip] = useState<'source' | 'target' | null>(null);
  const tooltipTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const rightHoverTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const leftHoverTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const pillInputRef = useRef<HTMLInputElement>(null);
  const cardInputRef = useRef<HTMLInputElement>(null);
  const [isCardInputFocused, setIsCardInputFocused] = useState(false);
  const [isCardSearchHovered, setIsCardSearchHovered] = useState(false);
  const [isTranslationHovered, setIsTranslationHovered] = useState(false);

  // Dynamic scale tiers based on dynamic card dimensions
  // Pill capsule is ONLY shown when explicitly minimized
  const isPill = isMinimized;
  // Minimal card mode: when shrunk to minimum, keep ONLY the search box and the translation
  const isMinimal = !isPill && (size.height <= 145 || (size.width <= 240 && size.height <= 190));
  const isStreamlined = !isPill && !isMinimal && size.height < 210;
  const isUltraCompact = !isPill && !isMinimal && (size.width < 270 || size.height < 250);
  const isVeryCompact = !isPill && !isMinimal && (size.width < 340 || size.height < 320);
  const isCompact = !isPill && !isMinimal && (size.width < 420 || size.height < 390);

  // Font scale based on settings - card font stays consistent across all sizes
  const fontScale =
    settings.fontSize === 'small'
      ? 0.88
      : settings.fontSize === 'large'
      ? 1.15
      : settings.fontSize === 'huge'
      ? 1.3
      : 1.0;

  const [isDragging, setIsDragging] = useState(false);
  const [isResizing, setIsResizing] = useState(false);

  const dragStartRef = useRef<{ mouseX: number; mouseY: number; startX: number; startY: number }>({
    mouseX: 0,
    mouseY: 0,
    startX: 0,
    startY: 0,
  });

  const resizeStartRef = useRef<{
    direction: 'n' | 's' | 'e' | 'w' | 'ne' | 'nw' | 'se' | 'sw';
    mouseX: number;
    mouseY: number;
    startWidth: number;
    startHeight: number;
    startX: number;
    startY: number;
  }>({
    direction: 'se',
    mouseX: 0,
    mouseY: 0,
    startWidth: 380,
    startHeight: 490,
    startX: 0,
    startY: 0,
  });

  // Set initial position centered or right-docked on mount
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const initialX = Math.max(20, Math.min(window.innerWidth - 410, window.innerWidth / 2 - 190));
      const initialY = Math.max(50, window.innerHeight / 2 - 250);
      setPosition({ x: initialX, y: initialY });
    }
  }, []);

  // Window resize handler: keeps card strictly within bounds and avoids viewport overflow
  useEffect(() => {
    const handleWindowResize = () => {
      setPosition((prev) => {
        const maxLeft = Math.max(0, window.innerWidth - size.width - 10);
        const maxTop = Math.max(0, window.innerHeight - size.height - 10);
        return {
          x: Math.min(Math.max(10, prev.x), maxLeft),
          y: Math.min(Math.max(10, prev.y), maxTop),
        };
      });
      setSize((prev) => {
        const maxW = Math.max(180, Math.min(840, window.innerWidth - 20));
        const maxH = Math.max(48, Math.min(900, window.innerHeight - 30));
        return {
          width: Math.min(prev.width, maxW),
          height: Math.min(prev.height, maxH),
        };
      });
    };
    window.addEventListener('resize', handleWindowResize);
    return () => window.removeEventListener('resize', handleWindowResize);
  }, [size.width, size.height]);

  // Window drag handlers
  const handleMouseDown = (e: React.MouseEvent) => {
    const target = e.target as HTMLElement;
    if (
      target.closest('button') ||
      target.closest('input') ||
      target.closest('textarea') ||
      target.closest('.no-drag') ||
      target.closest('.resize-handle')
    ) {
      return;
    }

    setIsDragging(true);
    dragStartRef.current = {
      mouseX: e.clientX,
      mouseY: e.clientY,
      startX: position.x,
      startY: position.y,
    };
  };

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!isDragging) return;
      const dx = e.clientX - dragStartRef.current.mouseX;
      const dy = e.clientY - dragStartRef.current.mouseY;

      const cardWidth = isMinimized ? 220 : size.width;
      const cardHeight = isMinimized ? 50 : size.height;
      const newX = Math.max(10, Math.min(window.innerWidth - cardWidth - 10, dragStartRef.current.startX + dx));
      const newY = Math.max(35, Math.min(window.innerHeight - cardHeight - 10, dragStartRef.current.startY + dy));

      setPosition({ x: newX, y: newY });
    };

    const handleMouseUp = () => {
      if (isDragging) {
        setIsDragging(false);
      }
    };

    if (isDragging) {
      document.body.style.userSelect = 'none';
      document.body.style.cursor = 'grabbing';
      window.addEventListener('mousemove', handleMouseMove);
      window.addEventListener('mouseup', handleMouseUp);
    }
    return () => {
      document.body.style.userSelect = '';
      document.body.style.cursor = '';
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isDragging, isMinimized, size]);

  // Edge & corner resize handlers (8 directions)
  const handleResizeMouseDown = (
    e: React.MouseEvent,
    direction: 'n' | 's' | 'e' | 'w' | 'ne' | 'nw' | 'se' | 'sw'
  ) => {
    e.stopPropagation();
    e.preventDefault();
    setIsResizing(true);
    resizeStartRef.current = {
      direction,
      mouseX: e.clientX,
      mouseY: e.clientY,
      startWidth: size.width,
      startHeight: size.height,
      startX: position.x,
      startY: position.y,
    };
  };

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!isResizing) return;
      const { direction, mouseX, mouseY, startWidth, startHeight, startX, startY } = resizeStartRef.current;
      const dx = e.clientX - mouseX;
      const dy = e.clientY - mouseY;

      const minW = 160;
      const minH = 75;
      const maxWidth = Math.min(780, window.innerWidth - 20);
      const maxHeight = Math.min(900, window.innerHeight - 30);

      let targetWidth = startWidth;
      let targetHeight = startHeight;
      let targetX = startX;
      let targetY = startY;

      // Handle horizontal scaling
      if (direction.includes('e')) {
        targetWidth = Math.max(minW, Math.min(maxWidth, startWidth + dx));
      } else if (direction.includes('w')) {
        const potentialW = startWidth - dx;
        const clampedW = Math.max(minW, Math.min(maxWidth, potentialW));
        targetWidth = clampedW;
        targetX = startX + (startWidth - clampedW);
      }

      // Handle vertical scaling
      if (direction.includes('s')) {
        targetHeight = Math.max(minH, Math.min(maxHeight, startHeight + dy));
      } else if (direction.includes('n')) {
        const potentialH = startHeight - dy;
        const clampedH = Math.max(minH, Math.min(maxHeight, potentialH));
        targetHeight = clampedH;
        targetY = startY + (startHeight - clampedH);
      }

      setSize({ width: targetWidth, height: targetHeight });
      setPosition({ x: Math.max(0, targetX), y: Math.max(0, targetY) });
    };

    const handleMouseUp = () => {
      if (isResizing) {
        setIsResizing(false);
      }
    };

    if (isResizing) {
      window.addEventListener('mousemove', handleMouseMove);
      window.addEventListener('mouseup', handleMouseUp);
    }
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isResizing]);

  // Copy handler (复制完整释义与全部翻译)
  const fullTranslationText = getCompleteTranslation(result);
  const handleCopy = () => {
    const textToCopy = fullTranslationText || result?.translatedText;
    if (!textToCopy) return;
    navigator.clipboard.writeText(textToCopy);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  };

  // Speak handler
  const handleSpeak = () => {
    if (!result?.translatedText) return;
    speakText(result.translatedText, result.targetLang || targetLang);
  };

  const isDark = settings.themeMode === 'dark';

  // 1. Minimized / Dynamic Pill State (药丸胶囊状态：随尺寸全响应式自适应，各部件流式伸缩，翻译循环滚动)
  if (isPill) {
    const pillHeight = Math.max(46, Math.min(74, size.height <= 85 ? size.height : 52));
    const pillWidth = Math.max(160, size.width);
    const fullTranslation = getCompleteTranslation(result);

    // 最左侧圆角区域：宽度较窄(<320)时收缩隐藏为翻译让位；鼠标移到最左侧圆角区域自动弹出
    const isLeftVisible = pillWidth >= 320 ? true : isLeftHovered;

    // 最右侧圆角区域：宽度较窄(<440)时完全收缩隐藏为翻译让位；鼠标移到最右侧圆角区域自动弹出，左侧给它让位置
    const isRightVisible = pillWidth >= 440 ? true : isRightHovered;

    // 搜索框图标与尺寸：当药丸变小(<280)且未获得焦点时隐藏搜索图标，不占位置；仅留点击焦点区域
    const showSearchIcon = isSearchFocused || pillWidth >= 280;

    return (
      <div
        style={{
          position: 'fixed',
          left: `${position.x}px`,
          top: `${position.y}px`,
          width: `${pillWidth}px`,
          height: `${pillHeight}px`,
          zIndex: isPinned ? 9999 : 50,
          opacity: settings.cardOpacity,
        }}
        onMouseDown={handleMouseDown}
        className={`select-none animate-in zoom-in-95 duration-150 rounded-full backdrop-blur-3xl bg-slate-950/85 border text-white flex items-center px-2 sm:px-2.5 gap-1.5 relative overflow-hidden group transition-[transform,box-shadow,border-color] duration-300 ease-out ${
          isDragging
            ? 'scale-[1.03] shadow-[0_38px_85px_rgba(0,0,0,0.85),0_15px_30px_rgba(0,0,0,0.5),0_0_28px_rgba(59,130,246,0.35)] border-white/40 ring-1 ring-blue-400/40 cursor-grabbing'
            : 'scale-100 shadow-[0_20px_50px_rgba(0,0,0,0.6)] border-white/20 cursor-grab hover:shadow-[0_25px_60px_rgba(0,0,0,0.65)]'
        }`}
      >
        {/* 最左侧圆角区域：悬停最左侧圆角区域自动弹出来，左边收缩为翻译让位 */}
        <div
          onMouseEnter={() => {
            if (leftHoverTimeoutRef.current) clearTimeout(leftHoverTimeoutRef.current);
            setIsLeftHovered(true);
          }}
          onMouseLeave={() => {
            leftHoverTimeoutRef.current = setTimeout(() => {
              setIsLeftHovered(false);
            }, 250);
          }}
          className="relative flex items-center shrink-0 h-full z-20"
        >
          {/* 最左侧边缘触发感知热区：确保在0宽时移动至左侧圆角也能瞬间灵敏触发 */}
          <div className="absolute -left-2.5 top-0 bottom-0 w-8.5 cursor-pointer z-10" />
          <div
            className={`flex items-center gap-1.5 overflow-hidden transition-all duration-200 ease-out shrink-0 ${
              isLeftVisible ? 'opacity-100 mr-0.5' : 'opacity-0 -mr-1'
            }`}
            style={{
              width: isLeftVisible ? 'auto' : 0,
            }}
          >
            <button
              type="button"
              onClick={() => onSourceTextChange('')}
              className="w-2.5 h-2.5 rounded-full bg-red-400/80 hover:opacity-100 opacity-70 transition-opacity cursor-pointer shrink-0"
              title="清空内容"
            />
            <button
              type="button"
              onClick={() => {
                setIsMinimized(false);
                setSize({ width: Math.max(size.width, 380), height: 490 });
              }}
              className="w-2.5 h-2.5 rounded-full bg-emerald-400/80 hover:opacity-100 opacity-70 transition-opacity cursor-pointer shrink-0"
              title="展开为完整卡片"
            />
          </div>
        </div>

        {/* 动态自适应搜索框：变小至极窄时隐藏搜索图标，仅保留紧凑焦点区域；点击聚焦后平滑展开 */}
        <div
          onClick={() => pillInputRef.current?.focus()}
          style={{
            flex: isSearchFocused
              ? '0 0 auto'
              : pillWidth < 240
              ? '0 0 14px'
              : pillWidth < 280
              ? '0 0 22px'
              : '1 1 0%',
            width: isSearchFocused
              ? `${Math.min(180, Math.max(120, Math.floor(pillWidth * 0.45)))}px`
              : pillWidth < 240
              ? '14px'
              : pillWidth < 280
              ? '22px'
              : undefined,
            minWidth: isSearchFocused ? '120px' : pillWidth < 240 ? '14px' : '22px',
            maxWidth: isSearchFocused ? '180px' : '140px',
          }}
          className={`relative flex items-center bg-white/10 hover:bg-white/15 focus-within:bg-white/20 border border-white/15 rounded-full h-7 transition-all duration-150 overflow-hidden cursor-text shrink-0 ${
            isSearchFocused
              ? 'ring-1 ring-blue-400/50 px-1.5 gap-1'
              : pillWidth < 280
              ? 'px-0 justify-center'
              : 'px-1.5 gap-1'
          }`}
          title="搜索或翻译"
        >
          {showSearchIcon && (
            <Search className="w-3 h-3 text-blue-400 shrink-0 pointer-events-none select-none ml-0.5" />
          )}
          <input
            ref={pillInputRef}
            type="text"
            value={sourceText}
            onChange={(e) => onSourceTextChange(e.target.value)}
            onFocus={() => setIsSearchFocused(true)}
            onBlur={() => setIsSearchFocused(false)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault();
                onTranslate(sourceText);
              }
            }}
            placeholder={isSearchFocused ? '搜索/翻译...' : pillWidth >= 300 ? '搜索/翻译...' : ''}
            className={`text-xs text-white placeholder-white/35 bg-transparent focus:outline-hidden select-text ${
              !isSearchFocused && pillWidth < 280
                ? 'w-full h-full opacity-0 cursor-text absolute inset-0'
                : 'w-full flex-1 min-w-0'
            }`}
          />
          {sourceText && isSearchFocused && (
            <button
              type="button"
              onMouseDown={(e) => {
                e.preventDefault();
                onSourceTextChange('');
              }}
              className="text-white/40 hover:text-white p-0.5 shrink-0"
            >
              <X className="w-3 h-3" />
            </button>
          )}
        </div>

        {/* 原文和译文：基于 flex 与 grid 始终按比例分配剩余空间，缩至极小尺寸下支持多行悬停展开 Tooltip */}
        <div
          style={{ flex: isSearchFocused ? '1 1 0%' : '2.4 1 0%' }}
          className="min-w-0 flex items-center px-0.5 select-text overflow-hidden"
        >
          {result ? (
            <div className="w-full grid grid-cols-[minmax(0,1.1fr)_auto_minmax(0,1.7fr)] items-center gap-1 min-w-0 overflow-hidden">
              {/* 原文英语：在极小尺寸下依然稳定显示，支持悬停展开 Tooltip */}
              <div
                className="min-w-0 overflow-hidden flex items-center cursor-help"
                onMouseEnter={() => {
                  if (pillWidth < 460) {
                    if (tooltipTimeoutRef.current) clearTimeout(tooltipTimeoutRef.current);
                    setActiveTooltip('source');
                  }
                }}
                onMouseLeave={() => {
                  tooltipTimeoutRef.current = setTimeout(() => {
                    setActiveTooltip(null);
                  }, 200);
                }}
              >
                <span
                  className="text-xs text-white/85 font-medium truncate block w-full"
                  title={`原文: ${result.sourceText}`}
                >
                  {result.sourceText}
                </span>
              </div>

              {/* 分隔符：紧凑或最小状态下变成树杠 |，节省宝贵横向空间 */}
              {pillWidth < 300 ? (
                <span className="text-white/30 text-[11px] font-mono shrink-0 px-0.5 select-none leading-none">
                  |
                </span>
              ) : (
                <span className="text-blue-400 text-xs font-bold shrink-0 select-none px-0.5">
                  ➔
                </span>
              )}

              {/* 译文：无缝自适应跑马灯循环滚动，缩窄时支持多行悬停展开 Tooltip 防止内容不可读 */}
              <div
                className="min-w-0 overflow-hidden flex items-center cursor-help"
                onMouseEnter={() => {
                  if (pillWidth < 460) {
                    if (tooltipTimeoutRef.current) clearTimeout(tooltipTimeoutRef.current);
                    setActiveTooltip('target');
                  }
                }}
                onMouseLeave={() => {
                  tooltipTimeoutRef.current = setTimeout(() => {
                    setActiveTooltip(null);
                  }, 200);
                }}
              >
                <MarqueeText
                  text={fullTranslation}
                  className="text-xs text-emerald-300 font-semibold"
                  pillWidth={pillWidth}
                />
              </div>
            </div>
          ) : sourceText ? (
            <div className="flex-1 min-w-0 truncate text-xs text-white/50 italic">
              {loading ? (pillWidth < 220 ? '翻译中...' : '正在翻译...') : pillWidth < 220 ? '回车翻译' : '按回车翻译...'}
            </div>
          ) : (
            <div className="flex-1 min-w-0 truncate text-[11px] text-white/40 italic">
              {pillWidth < 220 ? '划词翻译' : '输入或划词翻译'}
            </div>
          )}
        </div>

        {/* 最右侧圆角区域：在处理请求时，暂时替换为纤细的线性加载指示器；请求完成后恢复图标区域 */}
        {loading ? (
          <div
            className="flex items-center shrink-0 h-full px-1 sm:px-1.5 z-20 animate-in fade-in duration-150"
            title="正在翻译..."
          >
            {/* 纤细优雅的线性加载指示器（极细 2.5px，带有微光动画，不占用过多空间） */}
            <div
              style={{
                width: pillWidth < 220 ? '20px' : pillWidth < 280 ? '26px' : '34px',
              }}
              className="relative h-[2.5px] bg-white/10 rounded-full overflow-hidden shadow-inner"
            >
              <div className="absolute inset-y-0 w-3/5 rounded-full bg-gradient-to-r from-blue-400 via-cyan-300 to-emerald-400 animate-linear-loading shadow-[0_0_6px_rgba(56,189,248,0.7)]" />
            </div>
          </div>
        ) : (
          <div
            onMouseEnter={() => {
              if (rightHoverTimeoutRef.current) clearTimeout(rightHoverTimeoutRef.current);
              setIsRightHovered(true);
            }}
            onMouseLeave={() => {
              rightHoverTimeoutRef.current = setTimeout(() => {
                setIsRightHovered(false);
              }, 250);
            }}
            className="relative flex items-center shrink-0 h-full z-20"
          >
            {/* 最右侧边缘触发感知热区：确保即使图标收缩为0宽，鼠标移动到最右侧圆角时也能灵敏触发 */}
            <div className="absolute -right-2.5 top-0 bottom-0 w-8.5 cursor-pointer z-10" />

            {/* 在 flex 流中平滑展开，收缩时宽度为0且完全隐去，绝不额外增加图标，左侧自然让位 */}
            <div
              className={`flex items-center gap-1 overflow-hidden transition-all duration-200 ease-out shrink-0 ${
                isRightVisible ? 'opacity-100 ml-0.5' : 'opacity-0 -ml-1'
              }`}
              style={{
                width: isRightVisible ? 'auto' : 0,
              }}
            >
              {result && (
                <button
                  type="button"
                  onClick={handleSpeak}
                  className="p-1 rounded-full text-white/60 hover:text-white hover:bg-white/10 transition-colors cursor-pointer shrink-0"
                  title="朗读发音"
                >
                  <Volume2 className="w-3.5 h-3.5" />
                </button>
              )}
              {result && (
                <button
                  type="button"
                  onClick={handleCopy}
                  className="p-1 rounded-full text-white/60 hover:text-white hover:bg-white/10 transition-colors cursor-pointer shrink-0"
                  title={copied ? '已复制' : '复制完整释义'}
                >
                  {copied ? (
                    <Check className="w-3.5 h-3.5 text-emerald-400" />
                  ) : (
                    <Copy className="w-3.5 h-3.5" />
                  )}
                </button>
              )}
              <button
                type="button"
                onClick={onOpenSnipper}
                className="p-1 rounded-full text-blue-300 hover:text-white hover:bg-white/10 transition-colors cursor-pointer shrink-0"
                title="截图翻译"
              >
                <Crop className="w-3.5 h-3.5" />
              </button>
              <button
                type="button"
                onClick={() => {
                  setIsMinimized(false);
                  setSize({ width: Math.max(size.width, 380), height: 490 });
                }}
                className="p-1 rounded-full text-white/60 hover:text-white hover:bg-white/10 transition-colors cursor-pointer shrink-0"
                title="展开为完整卡片"
              >
                <Maximize2 className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        )}

        {/* 悬停多行展开 Tooltip：当药丸宽度缩小时，原文或译文悬停可多行展开完整内容，防止极限尺寸下内容不可读 */}
        {activeTooltip && result && (
          <div
            onMouseEnter={() => {
              if (tooltipTimeoutRef.current) clearTimeout(tooltipTimeoutRef.current);
            }}
            onMouseLeave={() => {
              tooltipTimeoutRef.current = setTimeout(() => {
                setActiveTooltip(null);
              }, 200);
            }}
            className="absolute left-1/2 -translate-x-1/2 bottom-[calc(100%+8px)] w-[min(320px,90vw)] max-h-52 overflow-y-auto p-3 rounded-xl bg-slate-900/95 backdrop-blur-xl border border-white/20 shadow-[0_15px_35px_rgba(0,0,0,0.6)] text-xs text-white z-50 animate-in fade-in zoom-in-95 duration-150 select-text"
          >
            {activeTooltip === 'source' ? (
              <div className="space-y-1">
                <div className="flex items-center justify-between text-[10px] text-blue-400 font-semibold uppercase tracking-wider">
                  <span>原文内容</span>
                  <button
                    type="button"
                    onClick={() => {
                      navigator.clipboard.writeText(result.sourceText);
                      setCopied(true);
                      setTimeout(() => setCopied(false), 1500);
                    }}
                    className="text-white/60 hover:text-white transition-colors cursor-pointer"
                  >
                    复制
                  </button>
                </div>
                <div className="text-white/95 font-medium leading-relaxed break-words whitespace-pre-wrap">
                  {result.sourceText}
                </div>
              </div>
            ) : (
              <div className="space-y-1.5">
                <div className="flex items-center justify-between text-[10px] text-emerald-400 font-semibold uppercase tracking-wider">
                  <span>完整翻译释义</span>
                  <button
                    type="button"
                    onClick={() => {
                      navigator.clipboard.writeText(fullTranslation);
                      setCopied(true);
                      setTimeout(() => setCopied(false), 1500);
                    }}
                    className="text-white/60 hover:text-white transition-colors cursor-pointer"
                  >
                    复制
                  </button>
                </div>
                <div className="text-emerald-200 font-medium leading-relaxed break-words whitespace-pre-wrap">
                  {fullTranslation}
                </div>
                {result.isWord && result.definitions && result.definitions.length > 0 && (
                  <div className="pt-1.5 border-t border-white/10 space-y-1">
                    {result.definitions.map((def, idx) => (
                      <div key={idx} className="flex gap-1.5 text-[11px] leading-snug">
                        {def.partOfSpeech && (
                          <span className="text-blue-300 font-mono italic shrink-0">
                            {def.partOfSpeech}
                          </span>
                        )}
                        <span className="text-white/80">{def.meaning}</span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
            {/* 倒三角小箭头指向药丸 */}
            <div className="absolute left-1/2 -translate-x-1/2 -bottom-1.5 w-3 h-3 bg-slate-900 border-r border-b border-white/20 rotate-45" />
          </div>
        )}

        {/* 边缘拉伸：向下拖拽直接拉伸展开回卡片，左右拖拽调整宽度 */}
        <div
          onMouseDown={(e) => {
            handleResizeMouseDown(e, 's');
            setIsMinimized(false);
          }}
          className="resize-handle absolute left-8 right-8 -bottom-1 h-3 cursor-ns-resize hover:bg-blue-400/20 active:bg-blue-400/40 rounded-b-full transition-colors z-30"
          title="向下拖动拉伸展开为卡片"
        />
        <div
          onMouseDown={(e) => handleResizeMouseDown(e, 'e')}
          className="resize-handle absolute -right-1 top-2 bottom-2 w-3 cursor-ew-resize hover:bg-blue-400/20 active:bg-blue-400/40 rounded-r-full transition-colors z-30"
          title="左右拖动调整药丸宽度"
        />
        <div
          onMouseDown={(e) => handleResizeMouseDown(e, 'w')}
          className="resize-handle absolute -left-1 top-2 bottom-2 w-3 cursor-ew-resize hover:bg-blue-400/20 active:bg-blue-400/40 rounded-l-full transition-colors z-30"
          title="左右拖动调整药丸宽度"
        />
      </div>
    );
  }

  // 2. Full Floating Translator Card with Dynamic Resizing
  return (
    <div
      style={{
        position: 'fixed',
        left: `${position.x}px`,
        top: `${position.y}px`,
        width: `${size.width}px`,
        height: `${size.height}px`,
        maxWidth: 'calc(100vw - 20px)',
        maxHeight: 'calc(100vh - 35px)',
        zIndex: isPinned ? 9999 : 40,
        opacity: settings.cardOpacity,
      }}
      className={`bg-white/10 backdrop-blur-3xl border rounded-[32px] flex flex-col relative z-10 select-none transition-[transform,box-shadow,border-color,opacity] duration-300 ease-out ${
        isDragging
          ? 'scale-[1.018] shadow-[0_55px_120px_-15px_rgba(0,0,0,0.85),0_30px_60px_-10px_rgba(0,0,0,0.5),0_0_35px_rgba(59,130,246,0.25)] border-white/35 ring-1 ring-blue-400/30'
          : 'scale-100 shadow-[0_28px_65px_-15px_rgba(0,0,0,0.58),0_10px_25px_-5px_rgba(0,0,0,0.3)] border-white/20'
      }`}
    >
      {/* Top Header Bar */}
      <div
        onMouseDown={handleMouseDown}
        className={`w-full max-w-full overflow-hidden ${
          isStreamlined
            ? 'px-2 py-1'
            : isUltraCompact
            ? 'px-2 py-1'
            : isVeryCompact
            ? 'px-2.5 py-1.5'
            : 'px-3.5 py-2.5'
        } flex items-center justify-between border-b border-white/10 ${
          isDragging ? 'cursor-grabbing' : 'cursor-grab'
        } rounded-t-[32px] shrink-0 gap-1`}
      >
        {/* Traffic Light Dots */}
        <div className={`flex items-center shrink-0 ${isUltraCompact ? 'gap-1' : 'gap-1.5'}`}>
          <button
            type="button"
            onClick={() => onSourceTextChange('')}
            className={`${isUltraCompact ? 'w-2 h-2' : isVeryCompact ? 'w-2.5 h-2.5' : 'w-3 h-3'} rounded-full bg-red-400/80 shadow-xs hover:opacity-100 opacity-80 transition-opacity cursor-pointer`}
            title="清空内容"
          />
          <button
            type="button"
            onClick={() => setIsMinimized(true)}
            className={`${isUltraCompact ? 'w-2 h-2' : isVeryCompact ? 'w-2.5 h-2.5' : 'w-3 h-3'} rounded-full bg-amber-400/80 shadow-xs hover:opacity-100 opacity-80 transition-opacity cursor-pointer`}
            title="收起为药丸形状"
          />
          {size.width >= 240 && (
            <button
              type="button"
              onClick={() => onTranslate(sourceText || 'Efficient')}
              className={`${isUltraCompact ? 'w-2 h-2' : isVeryCompact ? 'w-2.5 h-2.5' : 'w-3 h-3'} rounded-full bg-emerald-400/80 shadow-xs hover:opacity-100 opacity-80 transition-opacity cursor-pointer`}
              title="刷新翻译"
            />
          )}
        </div>

        {/* Center: Language Switcher Pill */}
        <div className="no-drag flex items-center min-w-0 shrink justify-center gap-1">
          <LanguageSelector
            sourceLang={sourceLang}
            targetLang={targetLang}
            onSourceChange={onSourceLangChange}
            onTargetChange={onTargetLangChange}
            onSwap={onSwapLanguages}
            isDark={isDark}
            compact={size.width < 380}
            minimal={size.width < 290}
          />

          {/* Engine indicator pill with click-to-settings */}
          {size.width >= 300 && (
            <button
              type="button"
              onClick={onOpenSettings}
              className={`flex items-center rounded-full font-medium bg-white/10 hover:bg-white/15 text-blue-300 border border-white/10 transition-colors cursor-pointer shrink-0 ${
                size.width < 420 ? 'p-1' : 'gap-1 px-1.5 py-0.5 text-[10px]'
              }`}
              title={`当前翻译引擎: ${settings.translationEngine || 'gemini'} (点击在设置中切换引擎或配置 API Key)`}
            >
              <span className={`w-1.5 h-1.5 rounded-full ${settings.translationEngine === 'offline' ? 'bg-amber-400' : 'bg-emerald-400'} shrink-0`} />
              {size.width >= 420 && (
                <span className="truncate max-w-[60px]">
                  {settings.translationEngine === 'gemini'
                    ? 'Gemini'
                    : settings.translationEngine === 'deepl'
                    ? 'DeepL'
                    : settings.translationEngine === 'youdao'
                    ? '有道'
                    : '离线'}
                </span>
              )}
            </button>
          )}
        </div>

        {/* Right action buttons: Screenshot, Pin & Settings */}
        <div className="flex items-center shrink-0 gap-0.5 sm:gap-1">
          {/* Screenshot Translation Trigger */}
          {size.width >= 270 && (
            <button
              type="button"
              onClick={onOpenSnipper}
              className={`${isVeryCompact ? 'p-1' : 'p-1.5'} rounded-full text-blue-400/80 hover:text-blue-300 hover:bg-white/10 transition-colors cursor-pointer shrink-0`}
              title="截图翻译 (支持逐行中英对照)"
            >
              <Crop className={isVeryCompact ? 'w-3 h-3' : 'w-3.5 h-3.5'} />
            </button>
          )}

          <button
            type="button"
            onClick={() => setIsPinned(!isPinned)}
            aria-label="Pin Window"
            className={`${isVeryCompact ? 'p-1' : 'p-1.5'} rounded-full transition-colors cursor-pointer shrink-0 ${
              isPinned
                ? 'text-blue-400 bg-white/10'
                : 'text-white/40 hover:text-white/80'
            }`}
            title={isPinned ? '已置顶固定' : '置顶窗口'}
          >
            <Pin className={`${isVeryCompact ? 'w-3 h-3' : 'w-3.5 h-3.5'} ${isPinned ? 'fill-current' : ''}`} />
          </button>

          {size.width >= 350 && !isStreamlined && (
            <button
              type="button"
              onClick={onOpenSettings}
              className="text-white/40 hover:text-white/80 p-1.5 rounded-full transition-colors cursor-pointer shrink-0"
              title="偏好设置"
            >
              <Sliders className="w-3.5 h-3.5" />
            </button>
          )}
        </div>
      </div>

      {/* Main Content Area */}
      <div
        style={{ fontSize: `${fontScale * 100}%` }}
        className={`${
          isStreamlined
            ? 'p-2.5 space-y-1.5'
            : isUltraCompact
            ? 'p-2.5 space-y-2'
            : isVeryCompact
            ? 'p-3 space-y-2.5'
            : isCompact
            ? 'p-4 space-y-3'
            : 'p-5 space-y-3.5'
        } overflow-y-auto flex-1 flex flex-col`}
      >
        {/* Source Text Input Box (随着卡片高度自适应由多行缩小为单行胶囊搜索框) */}
        {isStreamlined || isUltraCompact ? (
          <div className="relative flex items-center bg-white/5 border border-white/10 rounded-xl px-2 py-1 focus-within:border-white/25 focus-within:bg-white/10 transition-all shrink-0">
            <Search className="w-3 h-3 text-blue-400 shrink-0 mr-1" />
            <input
              value={sourceText}
              onChange={(e) => onSourceTextChange(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  onTranslate(sourceText);
                }
              }}
              placeholder="搜索或输入..."
              className="w-full text-xs glass-input focus:outline-hidden text-white placeholder-white/30 bg-transparent select-text min-w-0"
            />
            {sourceText && (
              <button
                type="button"
                onClick={() => onSourceTextChange('')}
                className="p-0.5 text-white/40 hover:text-white rounded-full transition-colors cursor-pointer shrink-0"
              >
                <X className="w-2.5 h-2.5" />
              </button>
            )}
          </div>
        ) : (
          <div className="relative flex items-center bg-white/5 border border-white/10 rounded-2xl px-3 py-2 focus-within:border-white/25 focus-within:bg-white/10 transition-all shrink-0">
            <textarea
              value={sourceText}
              onChange={(e) => {
                onSourceTextChange(e.target.value);
              }}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault();
                  onTranslate(sourceText);
                }
              }}
              placeholder="输入单词句子或截图翻译..."
              spellCheck={false}
              rows={sourceText.length > 40 && size.height >= 340 ? 2 : 1}
              className="w-full text-xs sm:text-sm leading-relaxed glass-input resize-none focus:outline-hidden select-text text-white placeholder-white/30 min-w-0"
            />

            <div className="flex items-center gap-1 shrink-0 ml-1">
              {sourceText && (
                <button
                  type="button"
                  onClick={() => onSourceTextChange('')}
                  className="p-1 text-white/40 hover:text-white rounded-full transition-colors cursor-pointer"
                  title="清空"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              )}
              {size.width >= 280 && (
                <button
                  type="button"
                  onClick={onOpenSnipper}
                  className="p-1 text-blue-400/80 hover:text-blue-300 rounded-full transition-colors cursor-pointer"
                  title="截图框选翻译"
                >
                  <Crop className="w-3.5 h-3.5" />
                </button>
              )}
            </div>
          </div>
        )}

        {/* Translation Content */}
        {loading ? (
          <div className="py-4 flex flex-col items-center justify-center gap-2 text-white/50">
            <Sparkles className="w-5 h-5 text-blue-400 animate-spin" />
            <span className="text-xs tracking-wide">正在翻译中...</span>
          </div>
        ) : result ? (
          isStreamlined ? (
            /* Streamlined Content for compact card: clean original and translated text */
            <div className="space-y-1 select-text">
              <div className="text-xs text-white/60 italic truncate">
                {result.sourceText}
              </div>
              <div className="text-sm font-semibold text-emerald-300 line-clamp-2 leading-snug">
                {fullTranslationText || result.translatedText}
              </div>
              <div className="flex items-center justify-between pt-1 border-t border-white/10 text-[10px]">
                <span className="text-blue-400/80 font-mono">
                  {sourceLang}➔{targetLang}
                </span>
                <div className="flex items-center gap-1">
                  <button
                    type="button"
                    onClick={handleCopy}
                    className={`p-1 rounded text-white/40 hover:text-white transition-colors cursor-pointer ${
                      copied ? 'text-emerald-400' : ''
                    }`}
                    title={copied ? '已复制' : '复制译文'}
                  >
                    {copied ? <Check className="w-3 h-3 text-emerald-400" /> : <Copy className="w-3 h-3" />}
                  </button>
                  <button
                    type="button"
                    onClick={handleSpeak}
                    className="p-1 rounded text-white/40 hover:text-white transition-colors cursor-pointer"
                    title="朗读发音"
                  >
                    <Volume2 className="w-3 h-3" />
                  </button>
                </div>
              </div>
            </div>
          ) : (
            <div className={isUltraCompact ? 'space-y-1.5' : isVeryCompact ? 'space-y-2' : 'space-y-3.5'}>
              {result.isWord ? (
                /* Rich Word Details with responsive adaptive scaling */
                <WordDetailView
                  result={result}
                  isDark={isDark}
                  onSelectWord={onSelectWord}
                  isCompact={isCompact}
                  isVeryCompact={isVeryCompact}
                  isUltraCompact={isUltraCompact}
                  fontSize={settings.fontSize}
                />
              ) : (
                /* Sentence / Paragraph Translation */
                <div className="space-y-1.5 select-text">
                  <div
                    className={`font-semibold text-white/95 leading-snug break-words ${
                      isUltraCompact
                        ? 'text-xs'
                        : isVeryCompact
                        ? 'text-sm'
                        : isCompact
                        ? 'text-base'
                        : 'text-lg sm:text-xl'
                    }`}
                  >
                    {result.translatedText}
                  </div>
                  <div className="h-px bg-white/10 w-full" />
                  <div
                    className={`text-white/50 leading-relaxed italic break-words ${
                      isUltraCompact ? 'text-[10px]' : isVeryCompact ? 'text-xs' : 'text-sm'
                    }`}
                  >
                    {result.sourceText}
                  </div>
                </div>
              )}

              {/* Translation Action Toolbar */}
              <div className="flex items-center justify-between pt-1.5 border-t border-white/10">
                {!isVeryCompact && !isUltraCompact ? (
                  <div className="text-[10px] text-white/30 font-bold uppercase tracking-wider">
                    {result.isWord ? 'Word Analysis' : 'Translation'}
                  </div>
                ) : (
                  <div className="text-[10px] text-blue-400/80 font-mono">
                    {sourceLang}➔{targetLang}
                  </div>
                )}

                <div className="flex gap-1 items-center">
                  <button
                    type="button"
                    onClick={handleCopy}
                    className={`p-1.5 rounded-lg text-white/40 hover:text-white hover:bg-white/5 transition-colors cursor-pointer ${
                      copied ? 'text-emerald-400' : ''
                    }`}
                    title={copied ? '已复制' : '复制译文'}
                  >
                    {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                  </button>
                  <button
                    type="button"
                    onClick={handleSpeak}
                    className="p-1.5 rounded-lg text-white/40 hover:text-white hover:bg-white/5 transition-colors cursor-pointer"
                    title="朗读发音"
                  >
                    <Volume2 className="w-3.5 h-3.5" />
                  </button>
                  {!isVeryCompact && !isUltraCompact && (
                    <>
                      <button
                        type="button"
                        onClick={() => result.id && onToggleFavorite(result.id)}
                        className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                          result.isFavorite
                            ? 'text-amber-400 fill-amber-400'
                            : 'text-white/40 hover:text-amber-400 hover:bg-white/5'
                        }`}
                        title={result.isFavorite ? '移出生词本' : '收藏到生词本'}
                      >
                        <Heart className={`w-3.5 h-3.5 ${result.isFavorite ? 'fill-current' : ''}`} />
                      </button>
                      <button
                        type="button"
                        onClick={onOpenHistory}
                        className="p-1.5 rounded-lg text-white/40 hover:text-white hover:bg-white/5 transition-colors cursor-pointer"
                        title="查看生词历史"
                      >
                        <History className="w-3.5 h-3.5" />
                      </button>
                    </>
                  )}
                </div>
              </div>
            </div>
          )
        ) : (
          <div className="py-3 px-1 text-center text-white/40 text-xs flex-1 flex flex-col justify-center items-center gap-2">
            <span className="text-[11px] leading-relaxed">
              输入文本或在桌面文档中划词即刻精准翻译
            </span>
            {!isUltraCompact && !isStreamlined && (
              <div className="flex items-center justify-center gap-1.5 flex-wrap pt-1">
                {['Efficient', 'Serendipity', 'Resilient', 'AI 神经翻译'].map((w) => (
                  <button
                    key={w}
                    type="button"
                    onClick={() => {
                      onSourceTextChange(w);
                      onTranslate(w);
                    }}
                    className="px-2 py-0.5 rounded-full text-[10px] bg-white/5 hover:bg-white/15 text-blue-300 border border-white/10 transition-colors cursor-pointer"
                  >
                    {w}
                  </button>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Card Footer matching Frosted Glass Design (仅在高度和宽度充足时自适应展示) */}
      {!isStreamlined && size.height >= 240 && size.width >= 240 && (
        <div className={`mt-auto ${isVeryCompact ? 'p-2 px-3' : 'p-3 px-4'} bg-white/5 flex items-center justify-between rounded-b-[32px] border-t border-white/10 shrink-0`}>
          <div
            className="flex items-center gap-1.5 sm:gap-2 cursor-pointer select-none group"
            onClick={() => {
              if (onToggleSmartSelect) {
                onToggleSmartSelect();
              }
            }}
            title="点击开启/关闭划词智能翻译"
          >
            <div
              className={`relative w-7 h-3.5 sm:w-8 sm:h-4 rounded-full border border-white/10 transition-colors duration-200 ${
                settings.selectionTranslation ? 'bg-blue-500/80' : 'bg-white/15'
              }`}
            >
              <div
                className={`absolute top-0.5 w-2.5 h-2.5 sm:w-3 sm:h-3 bg-white rounded-full shadow-md transition-transform duration-200 ${
                  settings.selectionTranslation ? 'right-0.5' : 'left-0.5'
                }`}
              />
            </div>
            <span className="text-[10px] text-white/70 font-semibold tracking-wide uppercase group-hover:text-white transition-colors">
              {settings.selectionTranslation ? 'Smart-Select' : 'Paused'}
            </span>
          </div>

          <div className="flex items-center gap-1.5 sm:gap-2">
            {!isVeryCompact && !isUltraCompact && <span className="text-[9px] text-white/30 hidden sm:inline">四角可缩放</span>}
            <div className="text-[9px] text-white/30 font-black tracking-widest font-mono">
              {Math.round(size.width)}×{Math.round(size.height)}
            </div>
          </div>
        </div>
      )}

      {/* =========================================================================
          8 方向全角度拉伸与四角缩放手柄（高灵敏拖动调节尺寸）
          四角的小尖尖均已彻底隐藏，纯净简约玻璃外观，仍支持平滑拉伸手柄交互
          ========================================================================= */}
      {/* 1. 四个角 (NW, NE, SW, SE) 无视觉尖尖标记，纯净拖拽 */}
      {/* 右下角 (SE) */}
      <div
        onMouseDown={(e) => handleResizeMouseDown(e, 'se')}
        className="resize-handle absolute -right-1 -bottom-1 w-6 h-6 cursor-nwse-resize rounded-br-[32px] transition-colors z-40"
        title="拖动右下角调节大小"
      />

      {/* 左下角 (SW) */}
      <div
        onMouseDown={(e) => handleResizeMouseDown(e, 'sw')}
        className="resize-handle absolute -left-1 -bottom-1 w-6 h-6 cursor-nesw-resize rounded-bl-[32px] transition-colors z-40"
        title="拖动左下角调节大小"
      />

      {/* 右上角 (NE) */}
      <div
        onMouseDown={(e) => handleResizeMouseDown(e, 'ne')}
        className="resize-handle absolute -right-1 -top-1 w-6 h-6 cursor-nesw-resize rounded-tr-[32px] transition-colors z-40"
        title="拖动右上角调节大小"
      />

      {/* 左上角 (NW) */}
      <div
        onMouseDown={(e) => handleResizeMouseDown(e, 'nw')}
        className="resize-handle absolute -left-1 -top-1 w-6 h-6 cursor-nwse-resize rounded-tl-[32px] transition-colors z-40"
        title="拖动左上角调节大小"
      />

      {/* 2. 四条边 (E, W, S, N) */}
      {/* 右侧边 (E) */}
      <div
        onMouseDown={(e) => handleResizeMouseDown(e, 'e')}
        className="resize-handle absolute -right-1.5 top-8 bottom-8 w-3 cursor-ew-resize hover:bg-blue-400/25 active:bg-blue-400/40 rounded-r-full transition-colors z-30"
        title="向左右拉伸调节宽度"
      />
      {/* 底部边 (S) */}
      <div
        onMouseDown={(e) => handleResizeMouseDown(e, 's')}
        className="resize-handle absolute left-8 right-8 -bottom-1.5 h-3 cursor-ns-resize hover:bg-blue-400/25 active:bg-blue-400/40 rounded-b-full transition-colors z-30"
        title="向上下拉伸调节高度"
      />
      {/* 左侧边 (W) */}
      <div
        onMouseDown={(e) => handleResizeMouseDown(e, 'w')}
        className="resize-handle absolute -left-1.5 top-8 bottom-8 w-3 cursor-ew-resize hover:bg-blue-400/25 active:bg-blue-400/40 rounded-l-full transition-colors z-30"
        title="向左右拉伸调节宽度"
      />
      {/* 顶部边 (N) */}
      <div
        onMouseDown={(e) => handleResizeMouseDown(e, 'n')}
        className="resize-handle absolute left-8 right-8 -top-1.5 h-3 cursor-ns-resize hover:bg-blue-400/25 active:bg-blue-400/40 rounded-t-full transition-colors z-30"
        title="向上下拉伸调节高度"
      />
    </div>
  );
};
