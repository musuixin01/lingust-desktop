#include "TranslationManager.h"
#include "../../providers/gemini/GeminiProvider.h"
#include "../../providers/deepl/DeepLProvider.h"
#include "../../providers/youdao/YoudaoProvider.h"

TranslationManager::TranslationManager(QObject *parent)
    : QObject(parent)
    , m_currentEngine("gemini")
{
    m_providers["gemini"] = new GeminiProvider(this);
    m_providers["deepl"] = new DeepLProvider(this);
    m_providers["youdao"] = new YoudaoProvider(this);

    for (auto *provider : m_providers) {
        connect(provider, &ITranslationProvider::translationReady,
                this, &TranslationManager::translationReady);
        connect(provider, &ITranslationProvider::translationError,
                this, &TranslationManager::translationError);
    }
}

void TranslationManager::setEngine(const QString &engine)
{
    if (m_providers.contains(engine)) {
        m_currentEngine = engine;
    }
}

void TranslationManager::setApiKey(const QString &engine, const QString &key)
{
    if (m_providers.contains(engine)) {
        m_providers[engine]->setApiKey(key);
    }
}

void TranslationManager::setApiSecret(const QString &engine, const QString &secret)
{
    if (m_providers.contains(engine)) {
        m_providers[engine]->setApiSecret(secret);
    }
}

ITranslationProvider* TranslationManager::getProvider(const QString &engine)
{
    return m_providers.value(engine, nullptr);
}

void TranslationManager::translate(const QString &text, const QString &sourceLang, const QString &targetLang)
{
    if (m_currentEngine == "offline") {
        // 离线模式：简单回退
        QVariantMap result;
        result["translatedText"] = text;
        result["isWord"] = false;
        result["engine"] = "offline";
        emit translationReady(result);
        return;
    }

    ITranslationProvider *provider = getProvider(m_currentEngine);
    if (!provider) {
        emit translationError("未知翻译引擎");
        return;
    }

    provider->translate(text, sourceLang, targetLang);
}
