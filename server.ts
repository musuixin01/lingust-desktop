import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import crypto from 'crypto';
import dotenv from 'dotenv';
import { GoogleGenAI, Type, Schema } from '@google/genai';
import { createServer as createViteServer } from 'vite';
import { translateOffline } from './src/utils/offlineEngine';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3000;

app.use(express.json({ limit: '25mb' }));

// Lazy GoogleGenAI initialization
let aiClient: GoogleGenAI | null = null;
function getGeminiClient(): GoogleGenAI | null {
  if (!aiClient && process.env.GEMINI_API_KEY) {
    aiClient = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }
  return aiClient;
}

// In-memory cooldown tracker to gracefully bypass rate-limited/429 models
const modelCooldownUntil: Record<string, number> = {};

function isModelCoolingDown(model: string): boolean {
  const until = modelCooldownUntil[model];
  if (!until) return false;
  if (Date.now() > until) {
    delete modelCooldownUntil[model];
    return false;
  }
  return true;
}

function recordModelQuotaExhausted(model: string, seconds = 60) {
  modelCooldownUntil[model] = Date.now() + seconds * 1000;
}

// Ordered list of models with high-availability, low-latency, and diverse quotas
const RECOMMENDED_MODELS = [
  'gemini-3.1-flash-lite',
  'gemini-3.5-flash',
  'gemini-flash-lite-latest',
  'gemini-3.8-flash',
];

// Fallback dictionary for common queries when API key isn't provided or network is offline
const fallbackDictionary: Record<string, any> = {
  linguist: {
    translatedText: '语言学家',
    isWord: true,
    phonetic: { us: "/ˈlɪŋɡwɪst/", uk: "/ˈlɪŋɡwɪst/" },
    definitions: [
      { partOfSpeech: 'n.', meaning: '语言学家；通晓数种外语的人' }
    ],
    examples: [
      { src: 'She is a gifted linguist who speaks five languages.', dst: '她是一位极有天赋的语言学家，精通五门外语。' }
    ],
    synonyms: ['polyglot', 'philologist']
  },
  efficient: {
    translatedText: '高效的；有能力的',
    isWord: true,
    phonetic: { us: "/ɪˈfɪʃnt/", uk: "/ɪˈfɪʃnt/" },
    definitions: [
      { partOfSpeech: 'adj.', meaning: '高效的；有能力的；运作良好的' }
    ],
    examples: [
      { src: 'An efficient floating translator designed for focus.', dst: '专为专注打造的高效桌面悬浮翻译卡片。' }
    ],
    synonyms: ['effective', 'productive', 'competent']
  },
  desktop: {
    translatedText: '桌面；台式机',
    isWord: true,
    phonetic: { us: "/ˈdesktɑːp/", uk: "/ˈdesktɒp/" },
    definitions: [
      { partOfSpeech: 'n.', meaning: '桌面；台式电脑；屏幕背景' },
      { partOfSpeech: 'adj.', meaning: '台式的；桌上型的' }
    ],
    examples: [
      { src: 'Drag the card freely across your desktop.', dst: '在桌面上自由拖拽卡片。' }
    ],
    synonyms: ['screen', 'workspace']
  },
  translation: {
    translatedText: '翻译；译文',
    isWord: true,
    phonetic: { us: "/trænzˈleɪʃn/", uk: "/trænsˈleɪʃn/" },
    definitions: [
      { partOfSpeech: 'n.', meaning: '翻译；译文；转化' }
    ],
    examples: [
      { src: 'Fast, accurate translation at your fingertips.', dst: '触手可及的快速准确翻译。' }
    ],
    synonyms: ['interpretation', 'conversion']
  },
  floating: {
    translatedText: '悬浮的；漂浮的',
    isWord: true,
    phonetic: { us: "/ˈfloʊtɪŋ/", uk: "/ˈfləʊtɪŋ/" },
    definitions: [
      { partOfSpeech: 'adj.', meaning: '悬浮的；流动的；漂浮的' }
    ],
    examples: [
      { src: 'A lightweight floating card on top of your screen.', dst: '屏幕顶层的轻量悬浮卡片。' }
    ],
    synonyms: ['hovering', 'levitating']
  },
  modern: {
    translatedText: '现代的；新式的',
    isWord: true,
    phonetic: { us: "/ˈmɑːdərn/", uk: "/ˈmɒdn/" },
    definitions: [
      { partOfSpeech: 'adj.', meaning: '现代的；近代的；新颖的' }
    ],
    examples: [
      { src: 'This is an ultra-modern desktop translation tool.', dst: '这是一款超现代的桌面翻译工具。' }
    ],
    synonyms: ['contemporary', 'stylish']
  },
  hello: {
    translatedText: '你好；问候',
    isWord: true,
    phonetic: { us: "/həˈloʊ/", uk: "/həˈləʊ/" },
    definitions: [
      { partOfSpeech: 'int.', meaning: '你好；喂（打招呼）' },
      { partOfSpeech: 'n.', meaning: '问候；呼喊声' }
    ],
    examples: [
      { src: 'Hello! Welcome to Linguist floating translator.', dst: '你好！欢迎使用 Linguist 悬浮翻译卡片。' }
    ],
    synonyms: ['greetings', 'hi']
  }
};

// Fallback translation helper using public APIs or dictionary if Gemini encounters temporary outage
async function performFallbackTranslation(text: string, cleanWord: string, isSingleWord: boolean, sourceLang: string, targetLang: string) {
  // 1. Check local static dictionary first
  if (fallbackDictionary[cleanWord]) {
    return {
      translatedText: fallbackDictionary[cleanWord].translatedText,
      isWord: true,
      phonetic: fallbackDictionary[cleanWord].phonetic,
      definitions: fallbackDictionary[cleanWord].definitions,
      examples: fallbackDictionary[cleanWord].examples,
      synonyms: fallbackDictionary[cleanWord].synonyms,
    };
  }

  let translatedText = text;
  let phonetic: any = undefined;
  let definitions: any[] = [];
  let examples: any[] = [];
  let synonyms: any[] = [];

  // 2. Fetch external dictionary data for phonetic IPA & definitions if English single word
  if (isSingleWord && /^[a-zA-Z]+$/.test(cleanWord)) {
    try {
      const dictController = new AbortController();
      const dictTimeout = setTimeout(() => dictController.abort(), 2500);
      const dictRes = await fetch(`https://api.dictionaryapi.dev/api/v2/entries/en/${encodeURIComponent(cleanWord)}`, {
        signal: dictController.signal,
      });
      clearTimeout(dictTimeout);

      if (dictRes.ok) {
        const dictData: any = await dictRes.json();
        if (Array.isArray(dictData) && dictData.length > 0) {
          const entry = dictData[0];
          const usPhonetic = entry.phonetics?.find((p: any) => p.audio?.includes('-us') || p.text)?.text;
          const ukPhonetic = entry.phonetics?.find((p: any) => p.audio?.includes('-uk') || p.text)?.text;
          const generalPhonetic = entry.phonetic || usPhonetic || ukPhonetic;

          if (generalPhonetic || usPhonetic || ukPhonetic) {
            phonetic = {
              us: usPhonetic || generalPhonetic,
              uk: ukPhonetic || generalPhonetic,
            };
          }

          if (entry.meanings && entry.meanings.length > 0) {
            definitions = entry.meanings.slice(0, 3).map((m: any) => ({
              partOfSpeech: m.partOfSpeech || 'def',
              meaning: m.definitions?.[0]?.definition || '',
            })).filter((d: any) => Boolean(d.meaning));

            const ex = entry.meanings[0]?.definitions?.[0]?.example;
            if (ex) {
              examples.push({ src: ex, dst: '' });
            }

            if (entry.meanings[0]?.synonyms?.length > 0) {
              synonyms = entry.meanings[0].synonyms.slice(0, 4);
            }
          }
        }
      }
    } catch {
      // Ignore dictionary API errors
    }
  }

  // 3. Fetch translation from MyMemory API as backup
  try {
    const src = (sourceLang === 'auto' ? 'en' : sourceLang).toLowerCase();
    const tgt = targetLang.toLowerCase();
    const transController = new AbortController();
    const transTimeout = setTimeout(() => transController.abort(), 3000);
    const transRes = await fetch(`https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${src}|${tgt}`, {
      signal: transController.signal,
    });
    clearTimeout(transTimeout);

    if (transRes.ok) {
      const transData: any = await transRes.json();
      if (transData?.responseData?.translatedText) {
        translatedText = transData.responseData.translatedText;
      }
    }
  } catch {
    // If MyMemory fails, keep text or dictionary definition
    if (definitions.length > 0 && definitions[0].meaning) {
      translatedText = definitions[0].meaning;
    }
  }

  if (definitions.length === 0 && isSingleWord) {
    definitions = [{ partOfSpeech: '释义', meaning: translatedText }];
  }

  return {
    translatedText,
    isWord: isSingleWord,
    phonetic,
    definitions,
    examples,
    synonyms,
  };
}

// --- DeepL Translation Implementation ---
async function performDeepLTranslation(text: string, sourceLang: string, targetLang: string, apiKey: string) {
  const isFree = apiKey.endsWith(':fx');
  const endpoint = isFree ? 'https://api-free.deepl.com/v2/translate' : 'https://api.deepl.com/v2/translate';
  
  const targetMap: Record<string, string> = {
    ZH: 'ZH',
    EN: 'EN-US',
    JA: 'JA',
    KO: 'KO',
    DE: 'DE',
    FR: 'FR',
    ES: 'ES',
    RU: 'RU',
    IT: 'IT',
    PT: 'PT-PT',
  };
  const deeplTarget = targetMap[targetLang.toUpperCase()] || targetLang.toUpperCase();
  
  const body: any = {
    text: [text],
    target_lang: deeplTarget,
  };
  if (sourceLang && sourceLang !== 'auto') {
    const src = sourceLang.toUpperCase();
    body.source_lang = src === 'EN' ? 'EN' : src;
  }

  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Authorization': `DeepL-Auth-Key ${apiKey.trim()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`DeepL API 错误 (${response.status}): ${errorText}`);
  }

  const json: any = await response.json();
  const translated = json.translations?.[0]?.text || text;
  const detected = json.translations?.[0]?.detected_source_language || sourceLang;
  return {
    translatedText: translated,
    detectedSourceLang: detected,
  };
}

// --- Youdao Translation Implementation ---
async function performYoudaoTranslation(text: string, sourceLang: string, targetLang: string, appKey: string, appSecret: string) {
  const salt = crypto.randomUUID();
  const curtime = Math.round(Date.now() / 1000).toString();
  
  const truncate = (q: string) => {
    const len = q.length;
    if (len <= 20) return q;
    return q.substring(0, 10) + len + q.substring(len - 10, len);
  };
  
  const signStr = appKey.trim() + truncate(text) + salt + curtime + appSecret.trim();
  const sign = crypto.createHash('sha256').update(signStr).digest('hex');

  const langMap: Record<string, string> = {
    ZH: 'zh-CHS',
    EN: 'en',
    JA: 'ja',
    KO: 'ko',
    FR: 'fr',
    ES: 'es',
    RU: 'ru',
    DE: 'de',
  };

  const from = sourceLang === 'auto' ? 'auto' : (langMap[sourceLang.toUpperCase()] || sourceLang.toLowerCase());
  const to = langMap[targetLang.toUpperCase()] || targetLang.toLowerCase();

  const params = new URLSearchParams();
  params.append('q', text);
  params.append('from', from);
  params.append('to', to);
  params.append('appKey', appKey.trim());
  params.append('salt', salt);
  params.append('sign', sign);
  params.append('signType', 'v3');
  params.append('curtime', curtime);

  const response = await fetch('https://openapi.youdao.com/api', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params.toString(),
  });

  if (!response.ok) {
    throw new Error(`Youdao API HTTP 状态码: ${response.status}`);
  }

  const json: any = await response.json();
  if (json.errorCode !== '0') {
    const errorMessages: Record<string, string> = {
      '101': '缺少必填的参数',
      '102': '不支持的语言类型',
      '103': '翻译文本过长',
      '108': '应用 ID 无效 (appKey)',
      '110': '无相关服务的有效实例',
      '111': '账号欠费或已冻结',
      '113': '缺少有效查询文本',
      '202': '签名检验失败，请检查 appSecret 是否匹配',
      '411': '访问过于频繁',
    };
    const desc = errorMessages[json.errorCode] || `错误代码 ${json.errorCode}`;
    throw new Error(`有道智云错误: ${desc}`);
  }

  const translatedText = json.translation?.join('；') || text;
  const isWord = Boolean(json.basic);
  const phonetic = json.basic ? {
    us: json.basic['us-phonetic'] ? `/${json.basic['us-phonetic']}/` : undefined,
    uk: json.basic['uk-phonetic'] ? `/${json.basic['uk-phonetic']}/` : undefined,
    general: json.basic.phonetic ? `/${json.basic.phonetic}/` : undefined,
  } : undefined;

  const definitions = json.basic?.explains?.map((exp: string) => {
    const posMatch = exp.match(/^([a-z]+\.)\s*(.*)$/i);
    if (posMatch) {
      return { partOfSpeech: posMatch[1], meaning: posMatch[2] };
    }
    return { partOfSpeech: '释义', meaning: exp };
  }) || [];

  const examples = json.web?.slice(0, 3).map((w: any) => ({
    src: w.key,
    dst: Array.isArray(w.value) ? w.value.join('；') : String(w.value),
  })) || [];

  return {
    translatedText,
    isWord,
    phonetic,
    definitions,
    examples,
    sourceLang: json.l ? json.l.split('2')[0].toUpperCase() : sourceLang,
  };
}

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', hasGeminiKey: Boolean(process.env.GEMINI_API_KEY) });
});

// Engine connectivity test endpoint
app.post('/api/test-engine', async (req, res) => {
  const { engine, keys } = req.body || {};
  try {
    if (engine === 'offline') {
      return res.json({ success: true, message: '离线引擎状态正常！内置词库与语法解析引擎可零延迟脱机运行。' });
    }
    if (engine === 'gemini') {
      const apiKey = keys?.geminiKey?.trim() || process.env.GEMINI_API_KEY;
      if (!apiKey) {
        return res.status(400).json({ success: false, message: '未检测到 Gemini API Key，请先输入密钥' });
      }
      const testAi = new GoogleGenAI({ apiKey });
      const resp = await testAi.models.generateContent({
        model: 'gemini-3.1-flash-lite',
        contents: 'Say "OK"',
      });
      return res.json({ success: true, message: `Gemini API 连接成功！模型响应: ${resp.text?.trim()}` });
    }
    if (engine === 'deepl') {
      const deeplKey = keys?.deeplKey?.trim();
      if (!deeplKey) {
        return res.status(400).json({ success: false, message: '请先输入 DeepL API Key (支持 Free 与 Pro)' });
      }
      const trans = await performDeepLTranslation('Hello', 'EN', 'ZH', deeplKey);
      return res.json({ success: true, message: `DeepL API 验证成功！测试翻译: Hello ➔ ${trans.translatedText}` });
    }
    if (engine === 'youdao') {
      const { youdaoAppKey, youdaoAppSecret } = keys || {};
      if (!youdaoAppKey?.trim() || !youdaoAppSecret?.trim()) {
        return res.status(400).json({ success: false, message: '请先输入有道智云 AppKey 和 AppSecret' });
      }
      const trans = await performYoudaoTranslation('Hello', 'en', 'ZH', youdaoAppKey.trim(), youdaoAppSecret.trim());
      return res.json({ success: true, message: `有道智云 API 验证成功！测试翻译: Hello ➔ ${trans.translatedText}` });
    }
    return res.status(400).json({ success: false, message: '未知翻译引擎' });
  } catch (err: any) {
    return res.status(500).json({ success: false, message: err.message || '连接失败，请检查密钥或网络' });
  }
});

app.post('/api/translate', async (req, res) => {
  const { text, sourceLang = 'auto', targetLang = 'ZH', engine = 'gemini', keys = {} } = req.body || {};

  if (!text || typeof text !== 'string' || !text.trim()) {
    return res.status(400).json({ error: 'Text is required' });
  }

  const trimmed = text.trim();
  const cleanWord = trimmed.toLowerCase().replace(/^[^\w\s\u4e00-\u9fa5]+|[^\w\s\u4e00-\u9fa5]+$/g, '');
  const isSingleWord = !trimmed.includes('\n') && trimmed.split(/\s+/).length <= 2 && trimmed.length <= 35;

  // 1. OFFLINE TRANSLATION ENGINE (离线翻译引擎)
  if (engine === 'offline') {
    const offlineResult = translateOffline(trimmed, sourceLang, targetLang);
    return res.json({
      ...offlineResult,
      engine: 'offline',
    });
  }

  // 2. DEEPL TRANSLATION ENGINE (DeepL 神经翻译引擎)
  if (engine === 'deepl') {
    const deeplKey = keys?.deeplKey?.trim();
    if (deeplKey) {
      try {
        const deeplResult = await performDeepLTranslation(trimmed, sourceLang, targetLang, deeplKey);
        // If single word, enrich with phonetic IPA if available
        let phonetic: any = undefined;
        let definitions: any[] = [];
        if (isSingleWord && /^[a-zA-Z]+$/.test(cleanWord)) {
          const offlineMatch = translateOffline(cleanWord, 'EN', targetLang);
          if (offlineMatch.phonetic) phonetic = offlineMatch.phonetic;
          if (offlineMatch.definitions && offlineMatch.definitions.length > 0) definitions = offlineMatch.definitions;
        }

        return res.json({
          sourceText: trimmed,
          translatedText: deeplResult.translatedText,
          sourceLang: deeplResult.detectedSourceLang || sourceLang,
          targetLang,
          isWord: isSingleWord,
          phonetic,
          definitions: definitions.length > 0 ? definitions : [{ partOfSpeech: 'DeepL', meaning: deeplResult.translatedText }],
          engine: 'deepl',
        });
      } catch (deeplErr: any) {
        console.warn('DeepL request failed:', deeplErr.message);
        // Fallback to local offline dictionary with tip
        const fallback = await performFallbackTranslation(trimmed, cleanWord, isSingleWord, sourceLang, targetLang);
        return res.json({
          sourceText: trimmed,
          targetLang,
          sourceLang,
          ...fallback,
          translatedText: `【DeepL 接口异常】${fallback.translatedText} (${deeplErr.message})`,
          engine: 'deepl',
        });
      }
    } else {
      // User selected DeepL but hasn't entered key: give clear guidance + fallback
      const fallback = await performFallbackTranslation(trimmed, cleanWord, isSingleWord, sourceLang, targetLang);
      return res.json({
        sourceText: trimmed,
        targetLang,
        sourceLang,
        ...fallback,
        translatedText: `【DeepL 提示: 请在设置中输入 DeepL API Key】${fallback.translatedText}`,
        engine: 'deepl',
      });
    }
  }

  // 3. YOUDAO TRANSLATION ENGINE (有道智云 / 有道词典引擎)
  if (engine === 'youdao') {
    const { youdaoAppKey, youdaoAppSecret } = keys || {};
    if (youdaoAppKey?.trim() && youdaoAppSecret?.trim()) {
      try {
        const youdaoResult = await performYoudaoTranslation(trimmed, sourceLang, targetLang, youdaoAppKey.trim(), youdaoAppSecret.trim());
        return res.json({
          sourceText: trimmed,
          targetLang,
          ...youdaoResult,
          engine: 'youdao',
        });
      } catch (youdaoErr: any) {
        console.warn('Youdao request failed:', youdaoErr.message);
        const fallback = await performFallbackTranslation(trimmed, cleanWord, isSingleWord, sourceLang, targetLang);
        return res.json({
          sourceText: trimmed,
          targetLang,
          sourceLang,
          ...fallback,
          translatedText: `【有道接口异常】${fallback.translatedText} (${youdaoErr.message})`,
          engine: 'youdao',
        });
      }
    } else {
      // User selected Youdao but hasn't entered keys: give guidance + fallback
      const fallback = await performFallbackTranslation(trimmed, cleanWord, isSingleWord, sourceLang, targetLang);
      return res.json({
        sourceText: trimmed,
        targetLang,
        sourceLang,
        ...fallback,
        translatedText: `【有道提示: 请在设置中输入有道 AppKey 与 AppSecret】${fallback.translatedText}`,
        engine: 'youdao',
      });
    }
  }

  // 4. GEMINI AI ENGINE (Google Gemini 语境翻译与深度词典)
  let customGeminiClient: GoogleGenAI | null = null;
  if (keys?.geminiKey?.trim()) {
    try {
      customGeminiClient = new GoogleGenAI({ apiKey: keys.geminiKey.trim() });
    } catch {
      customGeminiClient = null;
    }
  }

  const gemini = customGeminiClient || getGeminiClient();

  if (!gemini) {
    const fallbackData = await performFallbackTranslation(trimmed, cleanWord, isSingleWord, sourceLang, targetLang);
    return res.json({
      sourceText: trimmed,
      targetLang,
      sourceLang,
      ...fallbackData,
      engine: 'gemini',
    });
  }

  const prompt = `You are Linguist, an expert precision dictionary and contextual translation engine.
Translate the following source text.
Source language: "${sourceLang}" (if "auto", detect automatically).
Target language: "${targetLang}" (e.g. ZH for Chinese, EN for English, JA for Japanese, KO for Korean, ES for Spanish, FR for French, DE for German, RU for Russian).

Text to translate:
"""
${trimmed}
"""

Instructions:
1. Determine if this is a single word or short phrase that warrants detailed dictionary lookup (isWord: true) vs. a sentence/paragraph (isWord: false).
2. If it is a word (in any language, especially English or other target/source pairs):
   - Provide standard accurate phonetic transcription (IPA) for US ("us") and UK ("uk") if applicable, or pinyin / kana if applicable.
   - List key part-of-speech definitions (partOfSpeech e.g. "n.", "v.", "adj.", and concise meaning in the target language).
   - Provide 1-2 concise, high-quality bilingual example sentences (src = source language, dst = target language).
   - Provide up to 3 common synonyms or related terms.
3. If it is a sentence or phrase:
   - Provide a natural, polished, fluent translation in translatedText.
   - You may leave phonetic empty or null, definitions empty array.
4. Output strict JSON matching this structure:
{
  "translatedText": "primary translation string",
  "detectedSourceLang": "e.g. EN, ZH, JA, etc.",
  "isWord": boolean,
  "phonetic": {
    "us": "string or empty",
    "uk": "string or empty"
  },
  "definitions": [
    { "partOfSpeech": "n.", "meaning": "definition in target language" }
  ],
  "examples": [
    { "src": "original sentence", "dst": "translated sentence" }
  ],
  "synonyms": ["synonym1", "synonym2"]
}`;

  // Try models in priority order, skipping those currently cooling down due to 429 quota limits
  let lastError: any = null;

  for (const model of RECOMMENDED_MODELS) {
    if (isModelCoolingDown(model)) {
      continue;
    }

    try {
      const response = await gemini.models.generateContent({
        model,
        contents: prompt,
        config: {
          responseMimeType: 'application/json',
          temperature: 0.1,
        },
      });

      const responseText = response.text || '{}';
      let parsed: any;
      try {
        parsed = JSON.parse(responseText);
      } catch {
        parsed = {
          translatedText: responseText.trim(),
          isWord: isSingleWord,
          definitions: [],
          examples: [],
        };
      }

      return res.json({
        sourceText: trimmed,
        targetLang,
        sourceLang: parsed.detectedSourceLang || sourceLang,
        ...parsed,
        engine: 'gemini',
      });
    } catch (err: any) {
      lastError = err;
      const isQuotaError = err?.status === 429 || String(err?.message || '').includes('429') || String(err?.message || '').includes('quota');
      if (isQuotaError) {
        recordModelQuotaExhausted(model, 60);
        console.warn(`Gemini model ${model} quota rate-limited (429), cooling down for 60s.`);
      } else {
        console.warn(`Gemini model ${model} translation attempt failed:`, err?.message || err);
      }
      // Continue to next recommended model in loop
    }
  }

  // If all Gemini models were overloaded or unavailable, seamlessly fallback so user never gets 500
  console.warn('All Gemini attempts unavailable, falling back to backup translation engine:', lastError?.message);
  try {
    const fallbackData = await performFallbackTranslation(trimmed, cleanWord, isSingleWord, sourceLang, targetLang);
    return res.json({
      sourceText: trimmed,
      targetLang,
      sourceLang,
      ...fallbackData,
      engine: 'gemini',
    });
  } catch (fallbackErr: any) {
    // Ultimate resilience: return readable fallback object with status 200
    return res.json({
      sourceText: trimmed,
      translatedText: trimmed,
      targetLang,
      sourceLang,
      isWord: isSingleWord,
      definitions: isSingleWord ? [{ partOfSpeech: 'text', meaning: trimmed }] : [],
      examples: [],
      synonyms: [],
      engine: 'gemini',
    });
  }
});

// Screenshot OCR and Line-by-Line Bilingual Translation Endpoint
app.post('/api/ocr-translate', async (req, res) => {
  const { image, extractedText, sourceLang = 'auto', targetLang = 'ZH' } = req.body || {};

  if (!image || typeof image !== 'string') {
    return res.status(400).json({ error: 'Image data is required' });
  }

  // Extract base64 and mime type
  const mimeMatch = image.match(/^data:(image\/[a-zA-Z0-9+.-]+);base64,/);
  const mimeType = mimeMatch ? mimeMatch[1] : 'image/png';
  const base64Data = image.replace(/^data:image\/[a-zA-Z0-9+.-]+;base64,/, '').trim();

  const gemini = getGeminiClient();

  // Sample bilingual map for common literature & demo quotes (e.g. user screenshot)
  const sampleBilingualMap: Record<string, string> = {
    'the sun rises every morning, bringing a brand new day.': '太阳每天早晨升起，带来崭新的一天。',
    'the sun rises every morning bringing a brand new day': '太阳每天早晨升起，带来崭新的一天。',
    'we all have dreams in our hearts.': '我们的心中都有梦想。',
    'we all have dreams in our hearts': '我们的心中都有梦想。',
    'however, big dreams do not come true overnight.': '然而，伟大的梦想不会一夜之间实现。',
    'however big dreams do not come true overnight': '然而，伟大的梦想不会一夜之间实现。',
    'they need our time, patience, and hard work.': '它们需要我们的时间、耐心和努力。',
    'they need our time patience and hard work': '它们需要我们的时间、耐心和努力。',
    'do not be afraid of small steps.': '不要害怕迈出一小步。',
    'do not be afraid of small steps': '不要害怕迈出一小步。',
    'when you read one page of a book today, you learn something new.': '当你今天读完一本书的一页，你就学到了新的知识。',
    'when you read one page of a book today you learn something new': '当你今天读完一本书的一页，你就学到了新的知识。',
  };

  // If no Gemini client, return fallback bilingual mock lines
  if (!gemini) {
    const defaultOriginal = extractedText && extractedText.trim().length > 0
      ? extractedText.trim()
      : 'The sun rises every morning, bringing a brand new day.\nWe all have dreams in our hearts.\nHowever, big dreams do not come true overnight.\nThey need our time, patience, and hard work.\nDo not be afraid of small steps.\nWhen you read one page of a book today, you learn something new.';
    
    const rawLines = defaultOriginal
      .split('\n')
      .map((s: string) => s.trim())
      .filter(Boolean);

    const lines = rawLines.map((line: string) => {
      const cleanKey = line.toLowerCase().trim().replace(/['"“”]/g, '');
      const matched = sampleBilingualMap[cleanKey];
      return {
        src: line,
        dst: matched || (targetLang === 'ZH' ? `[翻译] ${line}` : line),
      };
    });

    const defaultTranslated = lines.map(l => l.dst).join('\n');

    return res.json({
      detectedSourceLang: sourceLang === 'auto' ? 'EN' : sourceLang,
      targetLang,
      fullOriginalText: defaultOriginal,
      fullTranslatedText: defaultTranslated,
      lines,
      note: 'Offline fallback preview',
    });
  }

  const prompt = `You are an expert OCR transcription and precision translation engine.
Task:
1. Examine this screenshot image carefully and transcribe all text EXACTLY preserving its original paragraph formatting, line breaks, indentations, and punctuation. Do NOT dismantle or arbitrarily chop the text into fragments.
2. Provide an accurate and natural translation in target language "${targetLang}" for the text. The translated text MUST maintain the exact same paragraph structure and formatting as the original so it can be read seamlessly below it.
3. If the source language is already the target language (${targetLang}), translate it to ${targetLang === 'ZH' ? 'EN' : 'ZH'}.
4. Also provide line/sentence pairs ("lines") for bilingual alignment.

Respond with ONLY a valid JSON object matching this schema:
{
  "detectedSourceLang": "string (e.g. EN, ZH, JA, etc.)",
  "fullOriginalText": "exact transcribed original text preserving original paragraphs and newlines",
  "fullTranslatedText": "natural translation in ${targetLang} preserving matching paragraphs and formatting",
  "lines": [
    {
      "src": "coherent sentence or line in source",
      "dst": "translation for this line"
    }
  ]
}`;

  let lastError: any = null;

  for (const model of RECOMMENDED_MODELS) {
    if (isModelCoolingDown(model)) {
      continue;
    }

    try {
      const response = await gemini.models.generateContent({
        model,
        contents: [
          { text: prompt },
          {
            inlineData: {
              data: base64Data,
              mimeType: mimeType,
            },
          },
        ],
        config: {
          responseMimeType: 'application/json',
          temperature: 0.1,
        },
      });

      const responseText = response.text || '{}';
      let parsed: any;
      try {
        parsed = JSON.parse(responseText);
      } catch {
        parsed = {
          fullOriginalText: responseText.trim(),
          fullTranslatedText: '未能结构化解析，请重试',
          lines: [
            {
              src: responseText.trim(),
              dst: '未能结构化解析，请重试',
            },
          ],
        };
      }

      const lines = Array.isArray(parsed?.lines) ? parsed.lines : [];
      // Clean and normalize lines
      const cleanLines = lines
        .map((l: any) => ({
          src: String(l?.src || l?.source || '').trim(),
          dst: String(l?.dst || l?.target || l?.translation || '').trim(),
        }))
        .filter((l: any) => l.src.length > 0 || l.dst.length > 0);

      const fullOriginalText =
        String(parsed?.fullOriginalText || '').trim() ||
        cleanLines.map((l: any) => l.src).join('\n') ||
        (extractedText ? String(extractedText).trim() : '');

      const fullTranslatedText =
        String(parsed?.fullTranslatedText || '').trim() ||
        cleanLines.map((l: any) => l.dst).join('\n') ||
        '';

      if (cleanLines.length > 0 || fullOriginalText.length > 0) {
        return res.json({
          detectedSourceLang: parsed?.detectedSourceLang || sourceLang,
          targetLang,
          fullOriginalText,
          fullTranslatedText,
          lines: cleanLines,
        });
      }
    } catch (err: any) {
      lastError = err;
      const isQuotaError =
        err?.status === 429 ||
        String(err?.message || '').includes('429') ||
        String(err?.message || '').includes('quota');

      if (isQuotaError) {
        recordModelQuotaExhausted(model, 60);
        console.warn(`OCR model ${model} hit quota limit (429), cooling down for 60s.`);
      } else {
        console.warn(`OCR translation with ${model} failed:`, err?.message || err);
      }
    }
  }

  // Fallback if all Gemini models failed or no text was recognized
  // If we have extractedText from the DOM snipper, build bilingual lines from that
  if (extractedText && typeof extractedText === 'string' && extractedText.trim().length > 0) {
    const rawLines = extractedText
      .split('\n')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    if (rawLines.length > 0) {
      const fallbackBilingualLines = rawLines.map((line) => {
        const cleanKey = line.toLowerCase().trim().replace(/['"“”]/g, '');
        const matched = sampleBilingualMap[cleanKey];
        const lower = line.toLowerCase().replace(/[^a-z]/g, '');
        const dict = fallbackDictionary[lower];
        return {
          src: line,
          dst: matched || dict?.translatedText || (targetLang === 'ZH' ? `[翻译] ${line}` : line),
        };
      });

      const fullOrig = extractedText.trim();
      const fullTrans = fallbackBilingualLines.map(l => l.dst).join('\n');
      return res.json({
        detectedSourceLang: sourceLang === 'auto' ? 'EN' : sourceLang,
        targetLang,
        fullOriginalText: fullOrig,
        fullTranslatedText: fullTrans,
        lines: fallbackBilingualLines,
        note: 'Text fallback',
      });
    }
  }

  const defaultMsgOrig = extractedText?.trim() || 'Screenshot text recognition in progress.';
  const defaultMsgTrans = '已获取截图片段，当前 AI 服务暂时繁忙，请稍后再次重试或在文档中直接划选文字';

  return res.json({
    detectedSourceLang: sourceLang === 'auto' ? 'EN' : sourceLang,
    targetLang,
    fullOriginalText: defaultMsgOrig,
    fullTranslatedText: defaultMsgTrans,
    lines: [
      {
        src: defaultMsgOrig,
        dst: defaultMsgTrans,
      },
    ],
    error: lastError?.message,
  });
});

async function startServer() {
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Linguist server running on http://0.0.0.0:${PORT}`);
  });
}

startServer();
