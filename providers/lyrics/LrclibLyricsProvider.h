#pragma once

#include "ILyricsProvider.h"

#include <QHash>
#include <QPointer>
#include <QVariantMap>

class QNetworkAccessManager;
class QNetworkReply;

class LrclibLyricsProvider : public ILyricsProvider
{
    Q_OBJECT

public:
    explicit LrclibLyricsProvider(QObject *parent = nullptr);
    void requestLyrics(const QString &title, const QString &artist,
                       const QString &album, int durationSeconds) override;

private:
    void issueRequest(bool searchFallback);
    void handleReply(QNetworkReply *reply, bool searchFallback);
    QVariantList parseLyrics(const QVariantMap &record, bool *synchronized) const;
    QString cacheKey(const QString &title, const QString &artist) const;

    QNetworkAccessManager *m_network;
    QPointer<QNetworkReply> m_activeReply;
    QHash<QString, QVariantMap> m_cache;
    QString m_title;
    QString m_artist;
    QString m_album;
    int m_durationSeconds = 0;
    quint64 m_requestGeneration = 0;
};
