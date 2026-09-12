#include "FallbackProvider.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QUrlQuery>

namespace {
QString detectLanguage(const QString &text)
{
    if (text.contains(QRegularExpression("[\\x{3040}-\\x{30ff}]"))) return "ja";
    if (text.contains(QRegularExpression("[\\x{ac00}-\\x{d7af}]"))) return "ko";
    if (text.contains(QRegularExpression("[\\x{4e00}-\\x{9fff}]"))) return "zh-CN";
    if (text.contains(QRegularExpression("[\\x{0400}-\\x{04ff}]"))) return "ru";
    if (text.contains(QRegularExpression("[\\x{0600}-\\x{06ff}]"))) return "ar";
    if (text.contains(QRegularExpression("[\\x{0e00}-\\x{0e7f}]"))) return "th";

    const QString lower = text.toLower();
    if (lower.contains(QRegularExpression("\\b(le|la|les|des|une|est|avec)\\b"))) return "fr";
    if (lower.contains(QRegularExpression("\\b(der|die|das|und|ist|mit)\\b"))) return "de";
    if (lower.contains(QRegularExpression("\\b(el|los|las|una|es|con)\\b"))) return "es";
    if (lower.contains(QRegularExpression("\\b(o|os|uma|não|com|que)\\b"))) return "pt";
    if (lower.contains(QRegularExpression("\\b(il|lo|gli|una|con|che)\\b"))) return "it";
    return "en";
}

QString apiLanguage(QString language)
{
    language = language.trimmed().toLower();
    if (language == "zh" || language.startsWith("zh-")) return "zh-CN";
    if (language == "auto" || language.isEmpty()) return "en";
    return language;
}

QString tatoebaLanguage(QString language)
{
    language = language.trimmed().toLower();
    if (language == "zh" || language.startsWith("zh-")) return "cmn";
    if (language == "en" || language == "auto") return "eng";
    if (language == "ja") return "jpn";
    if (language == "ko") return "kor";
    if (language == "fr") return "fra";
    if (language == "de") return "deu";
    if (language == "es") return "spa";
    if (language == "ru") return "rus";
    return {};
}

QVariantList relatedWords(const QByteArray &payload)
{
    QVariantList words;
    const QJsonArray entries = QJsonDocument::fromJson(payload).array();
    for (const QJsonValue &entry : entries) {
        const QString word = entry.toObject().value("word").toString().trimmed();
        if (!word.isEmpty() && !words.contains(word)) words.append(word);
        if (words.size() >= 5) break;
    }
    return words;
}
}

FallbackProvider::FallbackProvider(QObject *parent)
    : ITranslationProvider(parent)
    , m_network(new QNetworkAccessManager(this))
{
}

void FallbackProvider::translate(const QString &text, const QString &sourceLang,
                                 const QString &targetLang)
{
    ++m_requestId;
    m_pending = 0;
    m_sourceText = text.trimmed();
    m_sourceLang = sourceLang.compare("auto", Qt::CaseInsensitive) == 0
                       ? detectLanguage(m_sourceText) : sourceLang;
    m_targetLang = targetLang;
    m_examples.clear();
    m_result.clear();
    m_result["translatedText"] = m_sourceText;
    m_result["isWord"] = false;
    m_result["engine"] = "fallback";
    m_result["definitions"] = QVariantList();
    m_result["examples"] = QVariantList();
    m_result["synonyms"] = QVariantList();
    m_result["antonyms"] = QVariantList();

    requestTranslation(m_sourceText, m_sourceLang, targetLang, "translation");

    static const QRegularExpression englishWord("^[A-Za-z][A-Za-z'-]{0,63}$");
    if (apiLanguage(m_sourceLang) == "en" && englishWord.match(m_sourceText).hasMatch()) {
        m_result["isWord"] = true;
        requestExamples(m_sourceText.toLower(), targetLang);
        requestRelatedWords(m_sourceText.toLower(), "syn");
        requestRelatedWords(m_sourceText.toLower(), "ant");
    }
}

void FallbackProvider::requestExamples(const QString &word, const QString &targetLang)
{
    const QString target = tatoebaLanguage(targetLang);
    if (target.isEmpty()) return;

    QUrl url("https://api.tatoeba.org/v1/sentences");
    QUrlQuery query;
    query.addQueryItem("q", word);
    query.addQueryItem("lang", "eng");
    query.addQueryItem("trans:lang", target);
    query.addQueryItem("word_count", "4-14");
    query.addQueryItem("sort", "relevance");
    query.addQueryItem("limit", "2");
    url.setQuery(query);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader, "LinguistDesktop/0.1");
    request.setTransferTimeout(5000);
    QNetworkReply *reply = m_network->get(request);
    reply->setProperty("requestId", QVariant::fromValue<qulonglong>(m_requestId));
    reply->setProperty("kind", "examples");
    ++m_pending;
    connect(reply, &QNetworkReply::finished, this, [this, reply] { handleReply(reply); });
}

void FallbackProvider::requestTranslation(const QString &text, const QString &sourceLang,
                                          const QString &targetLang, const QString &kind)
{
    QUrl url("https://api.mymemory.translated.net/get");
    QUrlQuery query;
    // MyMemory limits q to 500 UTF-8 bytes. 120 UTF-16 code units stay below
    // that ceiling even when every character needs four UTF-8 bytes.
    query.addQueryItem("q", text.left(120));
    query.addQueryItem("langpair", apiLanguage(sourceLang) + "|" + apiLanguage(targetLang));
    query.addQueryItem("mt", "1");
    url.setQuery(query);

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader, "LinguistDesktop/0.1");
    request.setTransferTimeout(5000);
    QNetworkReply *reply = m_network->get(request);
    reply->setProperty("requestId", QVariant::fromValue<qulonglong>(m_requestId));
    reply->setProperty("kind", kind);
    ++m_pending;
    connect(reply, &QNetworkReply::finished, this, [this, reply] { handleReply(reply); });
}

void FallbackProvider::requestRelatedWords(const QString &word, const QString &relation)
{
    QUrl url("https://api.datamuse.com/words");
    QUrlQuery query;
    query.addQueryItem("rel_" + relation, word);
    query.addQueryItem("max", "5");
    url.setQuery(query);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader, "LinguistDesktop/0.1");
    request.setTransferTimeout(5000);
    QNetworkReply *reply = m_network->get(request);
    reply->setProperty("requestId", QVariant::fromValue<qulonglong>(m_requestId));
    reply->setProperty("kind", relation == "syn" ? "synonyms" : "antonyms");
    ++m_pending;
    connect(reply, &QNetworkReply::finished, this, [this, reply] { handleReply(reply); });
}

void FallbackProvider::handleReply(QNetworkReply *reply)
{
    const quint64 requestId = reply->property("requestId").toULongLong();
    const QString kind = reply->property("kind").toString();
    const bool current = requestId == m_requestId;
    const bool succeeded = reply->error() == QNetworkReply::NoError;
    const QByteArray payload = succeeded ? reply->readAll() : QByteArray();
    reply->deleteLater();
    if (!current) return;

    if (kind == "translation" && succeeded) {
        const QJsonObject response = QJsonDocument::fromJson(payload).object()
                                         .value("responseData").toObject();
        const QString translated = response.value("translatedText").toString().trimmed();
        if (!translated.isEmpty()) m_result["translatedText"] = translated;
    } else if (kind == "examples" && succeeded) {
        const QJsonArray entries = QJsonDocument::fromJson(payload).object().value("data").toArray();
        QVariantList examples;
        for (const QJsonValue &entryValue : entries) {
            const QJsonObject entry = entryValue.toObject();
            const QString source = entry.value("text").toString().trimmed();
            QString translated;
            for (const QJsonValue &translationValue : entry.value("translations").toArray()) {
                translated = translationValue.toObject().value("text").toString().trimmed();
                if (!translated.isEmpty()) break;
            }
            if (!source.isEmpty() && !translated.isEmpty())
                examples.append(QVariantMap{{"src", source}, {"dst", translated}});
            if (examples.size() >= 2) break;
        }
        if (!examples.isEmpty()) m_examples = examples;
    } else if (kind == "synonyms" && succeeded) {
        m_result["synonyms"] = relatedWords(payload);
    } else if (kind == "antonyms" && succeeded) {
        m_result["antonyms"] = relatedWords(payload);
    }
    finishOne();
}

void FallbackProvider::finishOne()
{
    --m_pending;
    if (m_pending == 0) complete();
}

void FallbackProvider::complete()
{
    m_result["examples"] = m_examples;
    emit translationReady(m_result);
}
