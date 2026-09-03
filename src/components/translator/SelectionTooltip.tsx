import React from 'react';
import { Languages } from 'lucide-react';

export interface SelectionTooltipProps {
  position: { x: number; y: number } | null;
  onTranslate: () => void;
  isDark?: boolean;
}

export const SelectionTooltip: React.FC<SelectionTooltipProps> = ({
  position,
  onTranslate,
  isDark = false,
}) => {
  if (!position) return null;

  return (
    <div
      style={{
        position: 'fixed',
        left: `${position.x}px`,
        top: `${position.y}px`,
        transform: 'translate(-50%, -100%) translateY(-10px)',
        zIndex: 9999,
      }}
      className="pointer-events-auto select-none"
    >
      <button
        type="button"
        onMouseDown={(e) => {
          e.preventDefault(); // prevent losing text selection immediately
          onTranslate();
        }}
        className={`flex items-center gap-1 px-2.5 py-1 rounded-full shadow-lg border backdrop-blur-md text-xs font-semibold transition-all duration-200 hover:scale-105 active:scale-95 animate-in zoom-in-75 ${
          isDark
            ? 'bg-slate-800/90 border-white/20 text-blue-400 shadow-blue-500/10'
            : 'bg-white/95 border-slate-200 text-blue-600 shadow-slate-400/20'
        }`}
      >
        <Languages className="w-3.5 h-3.5 text-blue-500" />
        <span>Linguist 翻译</span>
      </button>
    </div>
  );
};
