#include "AppState.h"

#include <QGuiApplication>
#include <QClipboard>
#include <QProcess>
#include <QDebug>

AppState::AppState(QObject *parent)
    : QObject(parent)
    , m_sourceText("Efficient")
    , m_translatedText("高效的")
    , m_sourceLang("en")
    , m_targetLang("zh")
    , m_isTranslating(false)
    , m_isWord(true)
    , m_phoneticUs("/ɪˈfɪʃnt/")
    , m_phoneticUk("/ɪˈfɪʃ(ə)nt/")
    , m_isFavorite(false)
    , m_engine("gemini")
    , m_justCopied(false)
    , m_compactMode(false)
    , m_selectionTranslation(true)
    , m_autoSpeak(false)
    , m_cardOpacity(0.95)
    , m_translationManager(new TranslationManager(this))
    , m_database(new DatabaseManager(this))
    , m_selectionManager(new SelectionManager(this))
{
    m_definitions = {
        QVariantMap{{"partOfSpeech", "adj."}, {"meaning", "高效的；效率高的"}},
        QVariantMap{{"partOfSpeech", "adj."}, {"meaning", "有能力的；能胜任的"}}
    };
    m_examples = {
        QVariantMap{{"src", "She is an efficient worker."}, {"dst", "她是个高效的员工。"}},
        QVariantMap{{"src", "This method is more efficient."}, {"dst", "这种方法更高效。"}}
    };
    m_synonyms = {"effective", "productive", "capable"};

    connect(m_translationManager, &TranslationManager::translationReady,
            this, &AppState::onTranslationReady);
    connect(m_translationManager, &TranslationManager::translationError,
            this, &AppState::onTranslationError);

    m_copyTimer.setSingleShot(true);
    m_copyTimer.setInterval(1200);
    connect(&m_copyTimer, &QTimer::timeout, this, &AppState::resetJustCopied);

    if (m_database->init()) {
        m_history = m_database->getHistory();
        m_favorites = m_database->getFavorites();
        emit historyChanged();
        emit favoritesChanged();
    }

    connect(m_selectionManager, &SelectionManager::textSelected, this, [this](const QString &text) {
        if (!text.isEmpty()) {
            m_sourceText = text;
            emit sourceTextChanged();
            translate();
        }
    });
}

QString AppState::sourceText() const { return m_sourceText; }
void AppState::setSourceText(const QString &text)
{
    if (m_sourceText == text) return;
    m_sourceText = text;
    emit sourceTextChanged();
}

QString AppState::translatedText() const { return m_translatedText; }
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

bool AppState::isTranslating() const { return m_isTranslating; }
bool AppState::isWord() const { return m_isWord; }
QString AppState::phoneticUs() const { return m_phoneticUs; }
QString AppState::phoneticUk() const { return m_phoneticUk; }
bool AppState::isFavorite() const { return m_isFavorite; }
void AppState::setIsFavorite(bool fav)
{
    if (m_isFavorite == fav) return;
    m_isFavorite = fav;
    emit isFavoriteChanged();
}

QString AppState::engine() const { return m_engine; }
void AppState::setEngine(const QString &e)
{
    if (m_engine == e) return;
    m_engine = e;
    m_translationManager->setEngine(e);
    emit engineChanged();
}

bool AppState::justCopied() const { return m_justCopied; }
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

bool AppState::autoSpeak() const { return m_autoSpeak; }
void AppState::setAutoSpeak(bool b)
{
    if (m_autoSpeak == b) return;
    m_autoSpeak = b;
    emit autoSpeakChanged();
}

double AppState::cardOpacity() const { return m_cardOpacity; }
void AppState::setCardOpacity(double v)
{
    double clamped = qMax(0.6, qMin(1.0, v));
    if (qFuzzyCompare(m_cardOpacity, clamped)) return;
    m_cardOpacity = clamped;
    emit cardOpacityChanged();
}

QVariantList AppState::definitions() const { return m_definitions; }
QVariantList AppState::examples() const { return m_examples; }
QVariantList AppState::synonyms() const { return m_synonyms; }
QVariantList AppState::history() const { return m_history; }
QVariantList AppState::favorites() const { return m_favorites; }

void AppState::translate()
{
    if (m_sourceText.trimmed().isEmpty()) return;

    m_isTranslating = true;
    emit isTranslatingChanged();
    clearResult();

    m_translationManager->translate(m_sourceText, m_sourceLang, m_targetLang);
}

void AppState::onTranslationReady(const QVariantMap &result)
{
    m_isTranslating = false;
    emit isTranslatingChanged();

    m_translatedText = result.value("translatedText").toString();
    m_isWord = result.value("isWord", false).toBool();

    if (result.contains("phonetic")) {
        QVariantMap phonetic = result.value("phonetic").toMap();
        m_phoneticUs = phonetic.value("us").toString();
        m_phoneticUk = phonetic.value("uk").toString();
    } else {
        m_phoneticUs.clear();
        m_phoneticUk.clear();
    }

    if (result.contains("definitions")) {
        m_definitions = result.value("definitions").toList();
    }
    if (result.contains("examples")) {
        m_examples = result.value("examples").toList();
    }
    if (result.contains("synonyms")) {
        m_synonyms = result.value("synonyms").toList();
    }

    emit translatedTextChanged();
    emit isWordChanged();
    emit phoneticUsChanged();
    emit phoneticUkChanged();
    emit definitionsChanged();
    emit examplesChanged();
    emit synonymsChanged();

    // 保存到历史记录
    m_database->addHistory(m_sourceText, m_translatedText, m_sourceLang, m_targetLang,
                           result.value("engine", m_engine).toString());
    m_history = m_database->getHistory();
    emit historyChanged();

    // 更新收藏状态
    m_isFavorite = m_database->isFavorite(m_sourceText);
    emit isFavoriteChanged();

    if (m_autoSpeak && !m_translatedText.isEmpty()) {
        speak(m_translatedText, m_targetLang);
    }
}

void AppState::onTranslationError(const QString &error)
{
    m_isTranslating = false;
    emit isTranslatingChanged();
    m_translatedText = "翻译失败: " + error;
    emit translatedTextChanged();
    qWarning() << "Translation error:" << error;
}

void AppState::clearResult()
{
    m_translatedText.clear();
    m_isWord = false;
    m_phoneticUs.clear();
    m_phoneticUk.clear();
    m_definitions.clear();
    m_examples.clear();
    m_synonyms.clear();
    emit translatedTextChanged();
    emit isWordChanged();
    emit phoneticUsChanged();
    emit phoneticUkChanged();
    emit definitionsChanged();
    emit examplesChanged();
    emit synonymsChanged();
}

void AppState::swapLanguages()
{
    QString tmp = m_sourceLang;
    m_sourceLang = m_targetLang;
    m_targetLang = tmp;
    emit sourceLangChanged();
    emit targetLangChanged();
}

void AppState::copyTranslation()
{
    QGuiApplication::clipboard()->setText(m_translatedText);
    m_justCopied = true;
    emit justCopiedChanged();
    m_copyTimer.start();
}

void AppState::copySourceText()
{
    QGuiApplication::clipboard()->setText(m_sourceText);
}

void AppState::resetJustCopied()
{
    m_justCopied = false;
    emit justCopiedChanged();
}

void AppState::speak(const QString &text, const QString &lang, const QString &accent)
{
    if (text.isEmpty()) return;

    QString voiceName;
    if (lang == "zh" || lang == "zh-CN") {
        voiceName = "Microsoft Huihui Desktop";
    } else if (lang == "en") {
        if (accent == "uk") {
            voiceName = "Microsoft Hazel Desktop";  // 英式英语
        } else {
            voiceName = "Microsoft Zira Desktop";   // 美式英语
        }
    } else {
        voiceName = "Microsoft Zira Desktop";
    }

    QString escapedText = text;
    escapedText.replace("\"", "\"\"");

    // 使用 SAPI.SpVoice 并设置语音
    QString script = QString(
        "Set voice = CreateObject(\"SAPI.SpVoice\")"
        ": Set voice.Voice = voice.GetVoices.Item(0)"
        ": For Each v In voice.GetVoices"
        ": If InStr(v.GetDescription, \"%1\") > 0 Then Set voice.Voice = v : Exit For"
        ": End If"
        ": Next"
        ": voice.Speak \"%2\""
    ).arg(voiceName, escapedText).replace("\n", " ");

    QProcess::startDetached("mshta", QStringList() << "vbscript:" + script + "close()");
}

void AppState::setApiKey(const QString &engine, const QString &key)
{
    m_translationManager->setApiKey(engine, key);
}

void AppState::setApiSecret(const QString &engine, const QString &secret)
{
    m_translationManager->setApiSecret(engine, secret);
}

void AppState::toggleFavorite()
{
    if (m_sourceText.isEmpty()) return;

    if (m_isFavorite) {
        // 取消收藏：找到并删除
        for (const QVariant &fav : m_favorites) {
            QVariantMap map = fav.toMap();
            if (map.value("sourceText").toString() == m_sourceText) {
                m_database->removeFavorite(map.value("id").toInt());
                break;
            }
        }
        m_isFavorite = false;
    } else {
        QString defs;
        for (const QVariant &def : m_definitions) {
            QVariantMap d = def.toMap();
            defs += d.value("partOfSpeech").toString() + " " + d.value("meaning").toString() + "; ";
        }
        m_database->addFavorite(m_sourceText, m_translatedText, m_sourceLang, m_targetLang,
                                m_phoneticUs, defs);
        m_isFavorite = true;
    }
    emit isFavoriteChanged();
    m_favorites = m_database->getFavorites();
    emit favoritesChanged();
}

void AppState::clearHistory()
{
    m_database->clearHistory();
    m_history.clear();
    emit historyChanged();
}

void AppState::refreshHistory()
{
    m_history = m_database->getHistory();
    emit historyChanged();
}

void AppState::refreshFavorites()
{
    m_favorites = m_database->getFavorites();
    emit favoritesChanged();
}

void AppState::triggerSelectionTranslation()
{
    m_selectionManager->setEnabled(m_selectionTranslation);
    m_selectionManager->triggerSelectionTranslation();
}
