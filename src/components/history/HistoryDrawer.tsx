import React, { useState } from 'react';
import { X, Search, Star, Trash2, Clock, Volume2, ArrowRight } from 'lucide-react';
import { TranslationResult } from '../../types';
import { speakText } from '../../utils/speech';

interface HistoryDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  history: TranslationResult[];
  onSelectResult: (result: TranslationResult) => void;
  onToggleFavorite: (id: string) => void;
  onClearHistory: () => void;
  isDark?: boolean;
}

export const HistoryDrawer: React.FC<HistoryDrawerProps> = ({
  isOpen,
  onClose,
  history,
  onSelectResult,
  onToggleFavorite,
  onClearHistory,
  isDark = false,
}) => {
  const [filter, setFilter] = useState<'all' | 'favorites'>('all');
  const [searchQuery, setSearchQuery] = useState('');

  if (!isOpen) return null;

  const filteredHistory = history
    .filter((item) => {
      if (filter === 'favorites' && !item.isFavorite) return false;
      if (!searchQuery.trim()) return true;
      const query = searchQuery.toLowerCase();
      return (
        item.sourceText.toLowerCase().includes(query) ||
        item.translatedText.toLowerCase().includes(query)
      );
    })
    .sort((a, b) => b.timestamp - a.timestamp);

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/30 backdrop-blur-xs animate-in fade-in duration-200">
      <div
        className={`w-full max-w-sm h-full shadow-2xl flex flex-col border-l transition-all ${
          isDark
            ? 'bg-slate-900/95 border-white/15 text-slate-100'
            : 'bg-white/95 border-slate-200 text-slate-800'
        }`}
      >
        {/* Drawer Header */}
        <div className="p-4 border-b border-black/5 dark:border-white/10 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Clock className="w-4 h-4 text-blue-500" />
            <h3 className="font-semibold text-sm">翻译历史与生词本</h3>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-white"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Search & Filter Bar */}
        <div className="p-3 border-b border-black/5 dark:border-white/10 space-y-2">
          <div className="relative">
            <Search className="w-3.5 h-3.5 absolute left-3 top-2.5 text-slate-400" />
            <input
              type="text"
              placeholder="搜索历史词汇与短语..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className={`w-full pl-8 pr-3 py-1.5 text-xs rounded-xl border outline-hidden transition-all ${
                isDark
                  ? 'bg-white/5 border-white/10 text-white placeholder:text-slate-500 focus:border-blue-500'
                  : 'bg-slate-100 border-slate-200 text-slate-800 placeholder:text-slate-400 focus:border-blue-500'
              }`}
            />
          </div>

          <div className="flex items-center justify-between">
            <div className="flex gap-1 p-0.5 rounded-lg bg-black/5 dark:bg-white/5 text-xs">
              <button
                type="button"
                onClick={() => setFilter('all')}
                className={`px-3 py-1 rounded-md transition-all ${
                  filter === 'all'
                    ? 'bg-white dark:bg-slate-800 shadow-xs font-semibold text-blue-600 dark:text-blue-400'
                    : 'text-slate-500 hover:text-slate-800 dark:hover:text-white'
                }`}
              >
                全部 ({history.length})
              </button>
              <button
                type="button"
                onClick={() => setFilter('favorites')}
                className={`px-3 py-1 rounded-md flex items-center gap-1 transition-all ${
                  filter === 'favorites'
                    ? 'bg-white dark:bg-slate-800 shadow-xs font-semibold text-amber-500'
                    : 'text-slate-500 hover:text-slate-800 dark:hover:text-white'
                }`}
              >
                <Star className="w-3 h-3 fill-current" />
                <span>生词本 ({history.filter((i) => i.isFavorite).length})</span>
              </button>
            </div>

            {history.length > 0 && (
              <button
                type="button"
                onClick={onClearHistory}
                className="text-[11px] text-red-500 hover:text-red-600 flex items-center gap-1 px-2 py-1 rounded-md hover:bg-red-500/10"
              >
                <Trash2 className="w-3 h-3" />
                <span>清空</span>
              </button>
            )}
          </div>
        </div>

        {/* History List */}
        <div className="flex-1 overflow-y-auto p-3 space-y-2">
          {filteredHistory.length === 0 ? (
            <div className="text-center py-12 text-slate-400 text-xs">
              {searchQuery ? '没有找到匹配的翻译记录' : '暂无历史记录，去划词或输入查词吧！'}
            </div>
          ) : (
            filteredHistory.map((item) => (
              <div
                key={item.id}
                onClick={() => {
                  onSelectResult(item);
                  onClose();
                }}
                className={`p-3 rounded-xl border text-xs cursor-pointer group transition-all ${
                  isDark
                    ? 'bg-white/5 border-white/10 hover:border-blue-500/50 hover:bg-white/10'
                    : 'bg-white border-slate-200 hover:border-blue-400 hover:shadow-xs'
                }`}
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-baseline gap-1.5">
                      <span className="font-bold truncate">{item.sourceText}</span>
                      {(() => {
                        const raw =
                          typeof item.phonetic === 'string'
                            ? item.phonetic
                            : item.phonetic?.us || item.phonetic?.uk || item.phonetic?.general;
                        if (!raw) return null;
                        const clean = raw.replace(/^\/|\/$/g, '');
                        return (
                          <span className="text-[10px] font-mono text-slate-400">
                            /{clean}/
                          </span>
                        );
                      })()}
                    </div>
                    <div className="text-blue-600 dark:text-blue-400 text-[11px] truncate mt-0.5">
                      {item.translatedText}
                    </div>
                  </div>

                  <div className="flex items-center gap-1 shrink-0" onClick={(e) => e.stopPropagation()}>
                    <button
                      type="button"
                      onClick={() => speakText(item.sourceText, item.sourceLang)}
                      className="p-1 rounded-md text-slate-400 hover:text-blue-500 hover:bg-black/5 dark:hover:bg-white/10"
                      title="朗读"
                    >
                      <Volume2 className="w-3.5 h-3.5" />
                    </button>
                    <button
                      type="button"
                      onClick={() => onToggleFavorite(item.id)}
                      className={`p-1 rounded-md transition-colors ${
                        item.isFavorite
                          ? 'text-amber-500 fill-amber-500'
                          : 'text-slate-400 hover:text-amber-500'
                      }`}
                      title={item.isFavorite ? '移出生词本' : '收藏到生词本'}
                    >
                      <Star className={`w-3.5 h-3.5 ${item.isFavorite ? 'fill-current' : ''}`} />
                    </button>
                  </div>
                </div>

                <div className="flex items-center justify-between text-[10px] text-slate-400 mt-2 pt-1 border-t border-black/5 dark:border-white/5">
                  <span>
                    {item.sourceLang} → {item.targetLang}
                  </span>
                  <span>{new Date(item.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};
