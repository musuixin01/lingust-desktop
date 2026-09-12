#include "LrclibLyricsProvider.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QTimer>
#include <QUrlQuery>

LrclibLyricsProvider::LrclibLyricsProvider(QObject *parent)
    : ILyricsProvider(parent)
    , m_network(new QNetworkAccessManager(this))
{
}

QString LrclibLyricsProvider::cacheKey(const QString &title, const QString &artist) const
{
    return title.trimmed().toCaseFolded() + QChar(0x1f) + artist.trimmed().toCaseFolded();
}

void LrclibLyricsProvider::requestLyrics(const QString &title, const QString &artist,
                                         const QString &album, int durationSeconds)
{
    ++m_requestGeneration;
    if (m_activeReply)
        m_activeReply->abort();

    m_title = title.trimmed();
    m_artist = artist.trimmed();
    m_album = album.trimmed();
    m_durationSeconds = durationSeconds;
    if (m_title.isEmpty() || m_artist.isEmpty()) {
        emit lyricsUnavailable(m_title, m_artist);
        return;
    }

    const QString key = cacheKey(m_title, m_artist);
    if (m_cache.contains(key)) {
        const QVariantMap cached = m_cache.value(key);
        emit lyricsReady(m_title, m_artist, cached.value("lines").toList(),
                         cached.value("synchronized").toBool(),
                         cached.value("durationSeconds").toInt());
        return;
    }
    issueRequest(false);
}

void LrclibLyricsProvider::issueRequest(bool searchFallback)
{
    QUrl url(searchFallback ? "https://lrclib.net/api/search" : "https://lrclib.net/api/get");
    QUrlQuery query;
    query.addQueryItem("track_name", m_title);
    query.addQueryItem("artist_name", m_artist);
    if (!searchFallback && !m_album.isEmpty())
        query.addQueryItem("album_name", m_album);
    if (!searchFallback && m_durationSeconds > 0)
        query.addQueryItem("duration", QString::number(m_durationSeconds));
    url.setQuery(query);

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader, "Linguist/0.1 (desktop lyrics client)");
    request.setRawHeader("Lrclib-Client", "Linguist/0.1");
    request.setTransferTimeout(8000);
    const quint64 generation = m_requestGeneration;
    m_activeReply = m_network->get(request);
    connect(m_activeReply, &QNetworkReply::finished, this, [this, generation, searchFallback] {
        QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
        if (!reply)
            return;
        if (generation == m_requestGeneration)
            handleReply(reply, searchFallback);
        reply->deleteLater();
        if (m_activeReply == reply)
            m_activeReply = nullptr;
    });
}

void LrclibLyricsProvider::handleReply(QNetworkReply *reply, bool searchFallback)
{
    const QByteArray payload = reply->readAll();
    const QJsonDocument document = QJsonDocument::fromJson(payload);
    QVariantMap record;
    if (!searchFallback && document.isObject()) {
        record = document.object().toVariantMap();
    } else if (searchFallback && document.isArray() && !document.array().isEmpty()) {
        record = document.array().first().toObject().toVariantMap();
    }

    bool synchronized = false;
    const QVariantList lines = parseLyrics(record, &synchronized);
    if (!lines.isEmpty()) {
        const int matchedDuration = qRound(record.value("duration").toDouble());
        m_cache.insert(cacheKey(m_title, m_artist),
                       {{"lines", lines}, {"synchronized", synchronized},
                        {"durationSeconds", matchedDuration}});
        emit lyricsReady(m_title, m_artist, lines, synchronized, matchedDuration);
        return;
    }

    if (!searchFallback && reply->error() != QNetworkReply::OperationCanceledError) {
        const quint64 generation = m_requestGeneration;
        QTimer::singleShot(300, this, [this, generation] {
            if (generation == m_requestGeneration)
                issueRequest(true);
        });
        return;
    }
    emit lyricsUnavailable(m_title, m_artist);
}

QVariantList LrclibLyricsProvider::parseLyrics(const QVariantMap &record, bool *synchronized) const
{
    QVariantList lines;
    const QString syncedText = record.value("syncedLyrics").toString();
    static const QRegularExpression timestamp(
        QStringLiteral("^\\[(\\d{1,3}):(\\d{2}(?:\\.\\d{1,3})?)\\]\\s*(.*)$"));
    if (!syncedText.trimmed().isEmpty()) {
        const QStringList rawLines = syncedText.split(QRegularExpression("[\\r\\n]+"), Qt::SkipEmptyParts);
        for (const QString &rawLine : rawLines) {
            const QRegularExpressionMatch match = timestamp.match(rawLine.trimmed());
            if (!match.hasMatch() || match.captured(3).trimmed().isEmpty())
                continue;
            const double seconds = match.captured(1).toInt() * 60.0 + match.captured(2).toDouble();
            lines.append(QVariantMap{{"timeMs", qRound64(seconds * 1000.0)},
                                     {"text", match.captured(3).trimmed()}});
        }
        if (!lines.isEmpty()) {
            *synchronized = true;
            return lines;
        }
    }

    const QString plainText = record.value("plainLyrics").toString();
    for (const QString &line : plainText.split(QRegularExpression("[\\r\\n]+"), Qt::SkipEmptyParts)) {
        if (!line.trimmed().isEmpty())
            lines.append(QVariantMap{{"timeMs", -1}, {"text", line.trimmed()}});
    }
    *synchronized = false;
    return lines;
}
