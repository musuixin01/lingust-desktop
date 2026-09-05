#include "AppState.h"
#include <QTimer>
#include <QVariantMap>

AppState::AppState(QObject *parent)
    : QObject(parent)
    , m_sourceText("Efficient")
    , m_translatedText("高效的；有能力的")
    , m_phonetic("/ɪˈfɪʃnt/")
    , m_isWord(true)
    , m_isLoading(false)
    , m_sourceLang("EN")
    , m_targetLang("ZH")
    , m_engine("gemini")
    , m_isPinned(true)
    , m_isFavorite(true)
    , m_fontSizePercent(92.0)
    , m_compactMode(false)
    , m_selectionTranslation(true)
{
    loadDemoData();
}

void AppState::loadDemoData()
{
    m_definitions = {
        QVariantMap{{"partOfSpeech", "adj."}, {"meaning", "高效的；有能力的；运作良好的"}},
        QVariantMap{{"partOfSpeech", "adj."}, {"meaning", "（人）有能力的，能胜任的"}},
    };
    m_examples = {
        QVariantMap{{"src", "An efficient floating translator designed for focus."},
                    {"dst", "专为专注打造的高效桌面悬浮翻译卡片。"}},
        QVariantMap{{"src", "She is an efficient manager who gets things done."},
                    {"dst", "她是一位能把事情办好的干练经理。"}},
    };
    m_synonyms = {"effective", "productive", "capable", "competent"};
}

QString AppState::sourceText() const { return m_sourceText; }
void AppState::setSourceText(const QString &text)
{
    if (m_sourceText == text) return;
    m_sourceText = text;
    emit sourceTextChanged();
}

QString AppState::translatedText() const { return m_translatedText; }
QString AppState::phonetic() const { return m_phonetic; }
bool AppState::isWord() const { return m_isWord; }
bool AppState::isLoading() const { return m_isLoading; }
QString AppState::sourceLang() const { return m_sourceLang; }
void AppState::setSourceLang(const QString &lang)
{
    if (m_sourceLang == lang) return;
    m_sourceLang = lang;
    emit sourceLangChanged();
}
QString AppState::targetLang() const { return m_targetLang; }
void AppState::setTargetLang(const QString &lang)
{
    if (m_targetLang == lang) return;
    m_targetLang = lang;
    emit targetLangChanged();
}
QString AppState::engine() const { return m_engine; }
void AppState::setEngine(const QString &e)
{
    if (m_engine == e) return;
    m_engine = e;
    emit engineChanged();
}
bool AppState::isPinned() const { return m_isPinned; }
void AppState::setIsPinned(bool pinned)
{
    if (m_isPinned == pinned) return;
    m_isPinned = pinned;
    emit isPinnedChanged();
}
bool AppState::isFavorite() const { return m_isFavorite; }
void AppState::setIsFavorite(bool fav)
{
    if (m_isFavorite == fav) return;
    m_isFavorite = fav;
    emit isFavoriteChanged();
}
double AppState::fontSizePercent() const { return m_fontSizePercent; }
void AppState::setFontSizePercent(double p)
{
    double clamped = qMax(60.0, qMin(150.0, p));
    if (qFuzzyCompare(m_fontSizePercent, clamped)) return;
    m_fontSizePercent = clamped;
    emit fontSizePercentChanged();
}
bool AppState::compactMode() const { return m_compactMode; }
void AppState::setCompactMode(bool b)
{
    if (m_compactMode == b) return;
    m_compactMode = b;
    emit compactModeChanged();
}
bool AppState::selectionTranslation() const { return m_selectionTranslation; }
void AppState::setSelectionTranslation(bool b)
{
    if (m_selectionTranslation == b) return;
    m_selectionTranslation = b;
    emit selectionTranslationChanged();
}
QVariantList AppState::definitions() const { return m_definitions; }
QVariantList AppState::examples() const { return m_examples; }
QStringList AppState::synonyms() const { return m_synonyms; }

void AppState::translate()
{
    if (m_sourceText.trimmed().isEmpty()) return;
    m_isLoading = true;
    emit isLoadingChanged();

    // 模拟翻译延迟
    QTimer::singleShot(800, this, [this]() {
        m_isLoading = false;
        emit isLoadingChanged();
        // Demo: 保持现有数据
        emit translatedTextChanged();
    });
}

void AppState::swapLanguages()
{
    QString tmp = m_sourceLang;
    m_sourceLang = m_targetLang;
    m_targetLang = tmp;
    emit sourceLangChanged();
    emit targetLangChanged();
}

void AppState::clearText()
{
    setSourceText("");
}

QString AppState::completeTranslation() const
{
    if (m_isWord && !m_definitions.isEmpty()) {
        QStringList parts;
        for (const auto &d : m_definitions) {
            auto map = d.toMap();
            QString pos = map.value("partOfSpeech").toString();
            QString meaning = map.value("meaning").toString();
            parts << (pos.isEmpty() ? meaning : pos + " " + meaning);
        }
        QString result = parts.join("； ");
        if (!m_synonyms.isEmpty()) {
            result += " 【同义: " + m_synonyms.join(", ") + "】";
        }
        return result.trimmed();
    }
    return m_translatedText;
}
