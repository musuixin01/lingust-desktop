#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

class ILyricsProvider : public QObject
{
    Q_OBJECT

public:
    explicit ILyricsProvider(QObject *parent = nullptr) : QObject(parent) {}
    ~ILyricsProvider() override = default;

    virtual void requestLyrics(const QString &title, const QString &artist,
                               const QString &album, int durationSeconds) = 0;

signals:
    void lyricsReady(const QString &title, const QString &artist,
                     const QVariantList &lines, bool synchronized, int durationSeconds);
    void lyricsUnavailable(const QString &title, const QString &artist);
};
