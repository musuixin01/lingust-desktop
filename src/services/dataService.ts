import { TranslationResult } from '../types';
import { STORAGE_KEYS, STORAGE_LIMITS } from '../constants';

/**
 * 生词本独立持久化服务 (Wordbook / Favorites)
 *
 * 生词本与翻译历史完全解耦：
 * - 收藏数据独立存储于 `linguist_favorites`，清空历史（`linguist_history`）绝不会误删生词本；
 * - 以「原文（忽略大小写）」作为生词唯一身份标识，同一词条重复查询不会产生重复收藏；
 * - 收藏快照保留完整词条详情（音标、词性释义、双语例句、同反义词），离线可完整回放。
 */
export const favoritesService = {
  /** 从本地存储读取生词本 */
  loadFavorites(): TranslationResult[] {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.FAVORITES);
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  },

  /** 将生词本写入本地存储（按上限裁剪） */
  saveFavorites(favorites: TranslationResult[]): void {
    try {
      const trimmed = favorites.slice(0, STORAGE_LIMITS.MAX_HISTORY_ITEMS);
      localStorage.setItem(STORAGE_KEYS.FAVORITES, JSON.stringify(trimmed));
    } catch (e) {
      console.warn('Failed to save favorites:', e);
    }
  },

  /** 清空生词本 */
  clearFavorites(): void {
    try {
      localStorage.removeItem(STORAGE_KEYS.FAVORITES);
    } catch (e) {
      console.warn('Failed to clear favorites:', e);
    }
  },

  /** 依据原文（忽略大小写）判断某文本是否已收录生词本 */
  isFavoriteByText(favorites: TranslationResult[], text: string): boolean {
    const key = text.trim().toLowerCase();
    if (!key) return false;
    return favorites.some((f) => f.sourceText.trim().toLowerCase() === key);
  },

  /** 切换收藏：已收藏则移除，未收藏则插入快照到顶部 */
  toggleFavoriteByItem(favorites: TranslationResult[], item: TranslationResult): TranslationResult[] {
    const key = item.sourceText.trim().toLowerCase();
    const exists = favorites.some((f) => f.sourceText.trim().toLowerCase() === key);
    if (exists) {
      return favorites.filter((f) => f.sourceText.trim().toLowerCase() !== key);
    }
    return [{ ...item, isFavorite: true, timestamp: Date.now() }, ...favorites].slice(
      0,
      STORAGE_LIMITS.MAX_HISTORY_ITEMS
    );
  },
};

/**
 * 历史 / 生词本数据导入导出服务 (Data Exchange)
 *
 * 导出采用带元信息的包裹结构，同时兼容裸数组（import 时自动识别）：
 * ```json
 * {
 *   "app": "Linguist",
 *   "type": "favorites" | "history",
 *   "version": 1,
 *   "exportedAt": "2026-09-03T00:00:00.000Z",
 *   "items": [ ...TranslationResult ]
 * }
 * ```
 */
export const dataExchangeService = {
  /** 将数据导出为本地 JSON 文件下载 */
  exportToFile(data: TranslationResult[], type: 'history' | 'favorites', filename: string): void {
    const payload = {
      app: 'Linguist',
      type,
      version: 1,
      exportedAt: new Date().toISOString(),
      items: data,
    };
    const blob = new Blob([JSON.stringify(payload, null, 2)], {
      type: 'application/json;charset=utf-8',
    });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = filename;
    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
    URL.revokeObjectURL(url);
  },

  /** 将数据以 JSON 文本复制到剪贴板 */
  async copyToClipboard(data: TranslationResult[]): Promise<void> {
    await navigator.clipboard.writeText(JSON.stringify(data, null, 2));
  },

  /** 从 File 读取并解析 JSON，兼容包裹结构与裸数组，返回规范化翻译记录 */
  importFromFile(file: File): Promise<TranslationResult[]> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => {
        try {
          const parsed = JSON.parse(String(reader.result));
          let list: any[] = [];
          if (Array.isArray(parsed)) {
            list = parsed;
          } else if (parsed && Array.isArray(parsed.items)) {
            list = parsed.items;
          }
          const normalized: TranslationResult[] = list
            .filter(
              (item) =>
                item &&
                typeof item.sourceText === 'string' &&
                typeof item.translatedText === 'string'
            )
            .map((item, index) => ({
              ...item,
              id: item.id || `import-${Date.now()}-${index}`,
              timestamp: typeof item.timestamp === 'number' ? item.timestamp : Date.now(),
              isFavorite: Boolean(item.isFavorite),
            }));
          resolve(normalized);
        } catch {
          reject(new Error('导入失败：文件不是有效的 Linguist JSON 数据'));
        }
      };
      reader.onerror = () => reject(new Error('导入失败：无法读取所选文件'));
      reader.readAsText(file);
    });
  },
};
