import { SUPPORTED_LANGUAGES } from '../constants/languages';
import { OFFLINE_DICTIONARY } from './offlineEngine';

export interface LanguageDetectionResult {
  detectedLang: string; // 'ZH' | 'EN' | 'JA' | 'KO' | 'FR' | 'DE' | 'ES' | 'RU' | 'IT' | 'PT'
  confidence: number;   // 0.0 ~ 1.0
  langName: string;     // e.g. '中文 (简体)'
  shortLabel: string;   // e.g. 'ZH'
  flag: string;         // e.g. '🇨🇳'
}

// 1. Specific non-Latin script regexes
const HIRAGANA_KATAKANA_REGEX = /[\u3040-\u309F\u30A0-\u30FF\u31F0-\u31FF]/;
const HANGUL_REGEX = /[\uAC00-\uD7AF\u1100-\u11FF\u3130-\u318F]/;
const CYRILLIC_REGEX = /[\u0400-\u04FF]/;
const CJK_IDEOGRAPH_REGEX = /[\u4E00-\u9FFF\u3400-\u4DBF\uF900-\uFAFF]/;
const CHINESE_PUNCTUATION_REGEX = /[，。！？；：“”‘’【】《》（）]/;

// 2. High-confidence distinctive markers for Latin-based languages
const GERMAN_UNIQUE_REGEX = /[ßẞ]/;
const GERMAN_CHAR_REGEX = /[äöüÄÖÜ]/;
const SPANISH_UNIQUE_REGEX = /[ñÑ¿¡]/;
const PORTUGUESE_UNIQUE_REGEX = /[ãõÃÕ]|ão\b|ões\b|ães\b/i;
const FRENCH_UNIQUE_REGEX = /[œŒæÆ]|c'est|d'un|d'une|l'un|l'une|qu'il|n'est|j'ai|s'il|jusqu'à|aujourd'hui/i;

// 3. Common characteristic word sets (lowercased)
const GERMAN_WORDS = new Set([
  'der', 'die', 'das', 'ein', 'eine', 'einer', 'eines', 'einem', 'einen', 'und',
  'in', 'zu', 'den', 'dem', 'nicht', 'mit', 'auch', 'auf', 'für', 'von', 'als',
  'ist', 'sind', 'war', 'werden', 'sich', 'aber', 'wie', 'du', 'ich', 'sie',
  'wir', 'ihr', 'haben', 'hat', 'hatte', 'ja', 'nein', 'danke', 'bitte', 'morgen',
  'hallo', 'guten', 'tag', 'abend', 'nacht', 'alles', 'sehr', 'gern', 'wieder',
  'warum', 'wenn', 'wo', 'wer', 'was', 'immer', 'hier', 'da', 'dort', 'jetzt',
  'heute', 'gestern', 'schön', 'tschüss', 'auf wiedersehen', 'gut', 'schlecht',
]);

const SPANISH_WORDS = new Set([
  'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas', 'de', 'del', 'y', 'en',
  'que', 'por', 'para', 'con', 'no', 'es', 'son', 'se', 'como', 'más', 'pero',
  'su', 'sus', 'yo', 'tú', 'él', 'ella', 'nosotros', 'vosotros', 'ellos', 'ellas',
  'qué', 'quién', 'cuándo', 'dónde', 'cómo', 'por qué', 'hola', 'gracias',
  'adiós', 'amigo', 'amiga', 'buenos', 'buenas', 'días', 'noches', 'tarde', 'por favor',
  'mucho', 'poco', 'todo', 'todos', 'nada', 'siempre', 'nunca', 'hoy', 'mañana', 'ayer',
  'bien', 'mal',
]);

const PORTUGUESE_WORDS = new Set([
  'o', 'os', 'a', 'as', 'um', 'uma', 'uns', 'umas', 'de', 'do', 'da', 'dos', 'das',
  'e', 'em', 'no', 'na', 'nos', 'nas', 'que', 'por', 'para', 'com', 'não', 'é',
  'são', 'se', 'como', 'mais', 'mas', 'seu', 'sua', 'seus', 'suas', 'eu', 'você',
  'vocês', 'nós', 'eles', 'elas', 'obrigado', 'obrigada', 'olá', 'bom', 'dia',
  'boa', 'tarde', 'noite', 'tudo', 'todos', 'bem', 'muito', 'pouco', 'nada', 'sempre',
  'nunca', 'hoje', 'amanhã', 'ontem', 'fazer', 'estar', 'ter', 'pode', 'pela', 'pelo',
]);

const FRENCH_WORDS = new Set([
  'le', 'la', 'les', 'un', 'une', 'des', 'du', 'de', 'et', 'en', 'pour', 'dans',
  'sur', 'avec', 'ce', 'cette', 'ces', 'est', 'sont', 'pas', 'plus', 'vous',
  'nous', 'ils', 'elles', 'je', 'tu', 'qu', 'que', 'qui', 'merci', 'bonjour',
  'bonsoir', 'au revoir', 'oui', 'non', 'très', 'bien', 'aussi', 'faire', 'être',
  'avoir', 'mais', 'ou', 'donc', 'mon', 'ma', 'mes', 'ton', 'ta', 'tes', 'son',
  'sa', 'ses', 'salut', 's\'il', 'plaît', 'monde', 'comment', 'allez',
]);

const ITALIAN_WORDS = new Set([
  'il', 'lo', 'la', 'i', 'gli', 'le', 'un', 'uno', 'una', 'di', 'del', 'dello',
  'della', 'dei', 'degli', 'delle', 'e', 'ed', 'in', 'nel', 'nello', 'nella',
  'che', 'per', 'con', 'non', 'è', 'sono', 'si', 'come', 'più', 'ma', 'suo',
  'sua', 'suoi', 'sue', 'io', 'tu', 'lui', 'lei', 'noi', 'voi', 'loro',
  'grazie', 'ciao', 'prego', 'buongiorno', 'buonasera', 'buona', 'buono', 'molto',
  'poco', 'tutto', 'tutti', 'tutte', 'niente', 'sempre', 'mai', 'oggi', 'domani',
  'ieri', 'bene', 'male', 'per favore', 'giorno', 'giornata', 'amico', 'amica',
  'stai', 'sta', 'va', 'bene',
]);

const ENGLISH_WORDS = new Set([
  'the', 'be', 'to', 'of', 'and', 'in', 'that', 'have', 'it', 'for',
  'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at', 'this', 'but', 'his',
  'by', 'from', 'they', 'we', 'say', 'her', 'she', 'or', 'an', 'will', 'my',
  'one', 'all', 'would', 'there', 'their', 'what', 'so', 'up', 'out', 'if',
  'about', 'who', 'get', 'which', 'go', 'me', 'when', 'make', 'can', 'like',
  'time', 'just', 'him', 'know', 'take', 'people', 'into', 'year', 'your',
  'good', 'some', 'could', 'them', 'see', 'other', 'than', 'then', 'now', 'look',
  'only', 'come', 'its', 'over', 'think', 'also', 'back', 'after', 'use', 'two',
  'how', 'our', 'work', 'first', 'well', 'way', 'even', 'new', 'want', 'because',
  'any', 'these', 'give', 'day', 'most', 'us', 'hello', 'hi', 'please', 'thank',
  'thanks', 'yes', 'welcome', 'search', 'translate', 'language', 'efficient',
]);

/**
 * Intelligent Language Detector
 * Fast, accurate, and offline-capable heuristic language detection for 10 supported languages.
 */
export function detectLanguageWithDetails(text: string): LanguageDetectionResult | null {
  if (!text || typeof text !== 'string') return null;
  const trimmed = text.trim();
  if (trimmed.length === 0) return null;

  // 1. Japanese check: Hiragana or Katakana is a definitive indicator
  if (HIRAGANA_KATAKANA_REGEX.test(trimmed)) {
    return createResult('JA', 0.98);
  }

  // 2. Korean check: Hangul
  if (HANGUL_REGEX.test(trimmed)) {
    return createResult('KO', 0.98);
  }

  // 3. Russian check: Cyrillic
  if (CYRILLIC_REGEX.test(trimmed)) {
    return createResult('RU', 0.98);
  }

  // 4. Chinese check: CJK Ideographs or Chinese punctuation without Japanese Kana
  if (CJK_IDEOGRAPH_REGEX.test(trimmed) || CHINESE_PUNCTUATION_REGEX.test(trimmed)) {
    return createResult('ZH', 0.98);
  }

  // 5. Latin scripts (EN, FR, DE, ES, IT, PT)
  // Extract words and analyze specific characters
  const words = trimmed
    .toLowerCase()
    .replace(/[^\p{L}\s'-]/gu, ' ')
    .split(/\s+/)
    .filter((w) => w.length > 0);

  if (words.length === 0) {
    return null;
  }

  // Definite single-marker checks
  if (GERMAN_UNIQUE_REGEX.test(trimmed)) {
    return createResult('DE', 0.95);
  }
  if (SPANISH_UNIQUE_REGEX.test(trimmed)) {
    return createResult('ES', 0.95);
  }
  if (PORTUGUESE_UNIQUE_REGEX.test(trimmed)) {
    return createResult('PT', 0.95);
  }
  if (FRENCH_UNIQUE_REGEX.test(trimmed)) {
    return createResult('FR', 0.95);
  }

  // Score counter for Latin languages
  const scores: Record<'EN' | 'FR' | 'DE' | 'ES' | 'IT' | 'PT', number> = {
    EN: 0,
    FR: 0,
    DE: 0,
    ES: 0,
    IT: 0,
    PT: 0,
  };

  // Character-level heuristics
  if (GERMAN_CHAR_REGEX.test(trimmed)) scores.DE += 6;
  if (/[áéíóú]/i.test(trimmed)) {
    scores.ES += 4;
    scores.PT += 2;
  }
  if (/[éèêëàâùûôîïç]/i.test(trimmed)) {
    scores.FR += 5;
  }
  if (/[àèéìòù]/i.test(trimmed)) {
    scores.IT += 4;
  }
  if (/[ãõâêôç]/i.test(trimmed)) {
    scores.PT += 5;
  }

  // Word-level heuristics
  for (const word of words) {
    if (GERMAN_WORDS.has(word)) scores.DE += 4;
    if (SPANISH_WORDS.has(word)) scores.ES += 4;
    if (PORTUGUESE_WORDS.has(word)) scores.PT += 4;
    if (FRENCH_WORDS.has(word)) scores.FR += 4;
    if (ITALIAN_WORDS.has(word)) scores.IT += 4;
    if (ENGLISH_WORDS.has(word)) scores.EN += 4;

    // Check offline dictionary for English words
    const cleanWord = word.replace(/^['"]|['"]$/g, '');
    if (OFFLINE_DICTIONARY[cleanWord]) {
      scores.EN += 5;
    }
  }

  // If mostly standard English ASCII letters and no strong foreign signals, default to English
  const isAsciiLatin = /^[a-zA-Z\s.,!?'"()\-:;0-9]+$/.test(trimmed);
  if (isAsciiLatin) {
    scores.EN += 2;
  }

  // Find language with highest score
  let maxLang: 'EN' | 'FR' | 'DE' | 'ES' | 'IT' | 'PT' = 'EN';
  let maxScore = scores.EN;

  for (const lang of ['FR', 'DE', 'ES', 'IT', 'PT'] as const) {
    if (scores[lang] > maxScore) {
      maxScore = scores[lang];
      maxLang = lang;
    }
  }

  // Determine confidence
  const confidence = Math.min(0.95, Math.max(0.65, 0.5 + maxScore * 0.08));
  return createResult(maxLang, confidence);
}

/**
 * Convenience helper returning just the language code (e.g. 'ZH' | 'EN')
 */
export function detectLanguage(text: string): string | null {
  const result = detectLanguageWithDetails(text);
  return result ? result.detectedLang : null;
}

function createResult(langCode: string, confidence: number): LanguageDetectionResult {
  const found = SUPPORTED_LANGUAGES.find((l) => l.code === langCode);
  return {
    detectedLang: langCode,
    confidence,
    langName: found ? found.label : langCode,
    shortLabel: found ? found.shortLabel : langCode,
    flag: found ? found.flag : '🌐',
  };
}
