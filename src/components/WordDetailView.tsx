import React from 'react';
import { Volume2 } from 'lucide-react';
import { TranslationResult, FontSizePreference } from '../types';
import { speakText } from '../utils/speech';
import { HoverScrollText } from './HoverScrollText';

interface WordDetailViewProps {
  result: TranslationResult;
  isDark?: boolean;
  onSelectWord?: (word: string) => void;
  isCompact?: boolean;
  isVeryCompact?: boolean;
  isUltraCompact?: boolean;
  fontSize?: FontSizePreference;
}

export const WordDetailView: React.FC<WordDetailViewProps> = ({
  result,
  isDark = true,
  onSelectWord,
  isCompact = false,
  isVeryCompact = false,
  isUltraCompact = false,
  fontSize = 'medium',
}) => {
  const { sourceText, translatedText, phonetic, definitions, examples, synonyms, sourceLang } = result;

  const handleSpeak = (text: string, accent?: 'us' | 'uk') => {
    speakText(text, sourceLang || 'EN', accent);
  };

  const primaryPhonetic = phonetic?.us || phonetic?.uk || phonetic?.general || '';
  const formattedPhonetic = primaryPhonetic
    ? primaryPhonetic.startsWith('/')
      ? primaryPhonetic
      : `/${primaryPhonetic}/`
    : '';

  const primaryDef = definitions && definitions.length > 0 ? definitions[0] : null;
  const partOfSpeech = primaryDef?.partOfSpeech || 'Adj';
  const definitionMeaning = primaryDef?.meaning || translatedText;
  const primaryExample = examples && examples.length > 0 ? examples[0] : null;

  // Font scale multiplier from settings
  const fontMultiplier =
    fontSize === 'small' ? 0.88 : fontSize === 'large' ? 1.15 : fontSize === 'huge' ? 1.3 : 1.0;

  return (
    <div
      style={{ fontSize: `${fontMultiplier * 100}%` }}
      className={`text-left select-text ${
        isUltraCompact ? 'space-y-1.5' : isVeryCompact ? 'space-y-2' : isCompact ? 'space-y-3' : 'space-y-3.5'
      }`}
    >
      {/* Word Header & Pronounce Section */}
      <div className="space-y-0.5">
        <div className="flex items-center justify-between gap-2">
          <h1
            className={`font-semibold text-white tracking-tight leading-tight break-all ${
              isUltraCompact
                ? 'text-base'
                : isVeryCompact
                ? 'text-lg sm:text-xl'
                : isCompact
                ? 'text-xl sm:text-2xl'
                : 'text-2xl sm:text-3xl'
            }`}
          >
            {sourceText}
          </h1>
          <button
            type="button"
            onClick={() => handleSpeak(sourceText)}
            className={`${
              isUltraCompact ? 'w-5 h-5' : 'w-7 h-7'
            } shrink-0 flex items-center justify-center bg-blue-500/20 text-blue-300 hover:bg-blue-500/30 rounded-lg transition-all cursor-pointer`}
            title="朗读发音"
          >
            <Volume2 className={isUltraCompact ? 'w-3 h-3' : 'w-3.5 h-3.5'} />
          </button>
        </div>

        {/* Phonetic Pronunciation in mono blue */}
        {formattedPhonetic && (
          <div className="font-mono text-xs text-blue-400 opacity-85 tracking-wide flex items-center gap-1.5 flex-wrap">
            <span>{formattedPhonetic}</span>
            {!isVeryCompact && !isUltraCompact && phonetic?.uk && phonetic?.us && (
              <span className="text-[10px] text-white/30 font-sans">
                (英/美)
              </span>
            )}
          </div>
        )}
      </div>

      {/* Meaning & Definition Section */}
      <div className={isUltraCompact ? 'space-y-1' : isVeryCompact ? 'space-y-1.5' : 'space-y-2'}>
        <div className="space-y-0.5">
          <div className="flex items-baseline gap-1.5 flex-wrap">
            <span className="text-[9px] font-black uppercase bg-white/10 text-white/60 px-1 py-0.5 rounded tracking-wider">
              {partOfSpeech}
            </span>
            <div className="flex-1 min-w-0 overflow-hidden">
              <HoverScrollText
                text={translatedText || definitionMeaning}
                className={`text-white/95 font-medium leading-snug ${
                  isUltraCompact
                    ? 'text-sm'
                    : isVeryCompact
                    ? 'text-base'
                    : isCompact
                    ? 'text-lg'
                    : 'text-xl'
                }`}
              />
            </div>
          </div>

          {/* Example explanation sentence (hide if ultra/very compact to eliminate clutter) */}
          {!isVeryCompact && !isUltraCompact && (
            <p className="text-xs text-white/50 leading-relaxed italic pt-0.5">
              {primaryExample?.src || (definitionMeaning !== translatedText ? definitionMeaning : 'Working in a well-organized and competent way without waste.')}
            </p>
          )}
        </div>

        {/* Grid cards for Synonyms / Antonyms (only show when sufficient space) */}
        {!isCompact && !isVeryCompact && !isUltraCompact && (
          <>
            <div className="h-px bg-white/10 w-full my-1" />
            <div className="grid grid-cols-2 gap-2">
              <div
                className="p-2.5 bg-white/5 rounded-xl border border-white/5 hover:border-white/15 transition-all cursor-pointer group"
                onClick={() => {
                  const syn = synonyms && synonyms[0] ? synonyms[0] : 'Effective';
                  if (onSelectWord) onSelectWord(syn);
                }}
              >
                <span className="block text-[10px] font-bold text-white/30 uppercase mb-0.5 tracking-wider truncate">
                  {synonyms && synonyms.length > 0 ? synonyms[0] : 'Effective'}
                </span>
                <span className="text-white/70 text-xs font-medium group-hover:text-blue-300 transition-colors">
                  同义词 (Synonym)
                </span>
              </div>

              <div
                className="p-2.5 bg-white/5 rounded-xl border border-white/5 hover:border-white/15 transition-all cursor-pointer group"
                onClick={() => {
                  const ant = synonyms && synonyms[1] ? synonyms[1] : 'Wasteful';
                  if (onSelectWord) onSelectWord(ant.replace(/\s*\(.*?\)/, ''));
                }}
              >
                <span className="block text-[10px] font-bold text-white/30 uppercase mb-0.5 tracking-wider truncate">
                  {synonyms && synonyms.length > 1 ? synonyms[1].replace(/\s*\(.*?\)/, '') : 'Wasteful'}
                </span>
                <span className="text-white/70 text-xs font-medium group-hover:text-amber-300 transition-colors">
                  反义词 (Antonym)
                </span>
              </div>
            </div>
          </>
        )}

        {/* Complete Definitions List */}
        {definitions && definitions.length > 0 ? (
          <div className="pt-0.5 space-y-1">
            {definitions.slice(0, isUltraCompact ? 1 : isVeryCompact ? 2 : definitions.length).map((def, idx) => (
              <div key={idx} className="flex items-start gap-1.5 text-xs text-white/80">
                <span className="text-[9px] font-bold uppercase bg-blue-500/20 text-blue-300 px-1 py-0.5 rounded shrink-0 mt-0.5">
                  {def.partOfSpeech || '释义'}
                </span>
                <span className="leading-snug font-medium">{def.meaning}</span>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-xs text-white/80 leading-snug font-medium">
            {translatedText}
          </div>
        )}

        {/* Engine Attribution (compact, non-intrusive) */}
        {result.engine && !isUltraCompact && (
          <div className="pt-1 flex items-center justify-end">
            <span className="text-[10px] text-white/30 flex items-center gap-1">
              <span>引擎:</span>
              <span className="text-white/60 font-medium">
                {result.engine === 'gemini'
                  ? 'Gemini AI'
                  : result.engine === 'deepl'
                  ? 'DeepL'
                  : result.engine === 'youdao'
                  ? '有道智云'
                  : '离线脱机'}
              </span>
            </span>
          </div>
        )}
      </div>
    </div>
  );
};
