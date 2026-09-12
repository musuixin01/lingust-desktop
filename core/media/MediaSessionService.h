#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QTimer>

class MediaSessionService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playbackStateChanged)
    Q_PROPERTY(QString title READ title NOTIFY trackChanged)
    Q_PROPERTY(QString artist READ artist NOTIFY trackChanged)
    Q_PROPERTY(QString album READ album NOTIFY trackChanged)
    Q_PROPERTY(int durationSeconds READ durationSeconds NOTIFY trackChanged)
    Q_PROPERTY(int positionSeconds READ positionSeconds NOTIFY positionChanged)
    Q_PROPERTY(QString currentLyric READ currentLyric NOTIFY lyricChanged)
    Q_PROPERTY(QString currentLyricTranslation READ currentLyricTranslation NOTIFY lyricChanged)
    Q_PROPERTY(QString coverDataUrl READ coverDataUrl NOTIFY trackChanged)
    Q_PROPERTY(QVariantList lyrics READ lyrics NOTIFY lyricsListChanged)
    Q_PROPERTY(int currentLyricIndex READ currentLyricIndex NOTIFY lyricChanged)
    Q_PROPERTY(bool lyricsSynchronized READ lyricsSynchronized NOTIFY lyricsListChanged)
    Q_PROPERTY(bool isSystemMediaConnected READ isSystemMediaConnected NOTIFY systemMediaStateChanged)

public:
    explicit MediaSessionService(QObject *parent = nullptr);

    bool isPlaying() const { return m_isPlaying; }
    QString title() const { return m_title; }
    QString artist() const { return m_artist; }
    QString album() const { return m_album; }
    int durationSeconds() const { return m_durationSeconds; }
    int positionSeconds() const { return m_positionSeconds; }
    QString currentLyric() const;
    QString currentLyricTranslation() const { return {}; }
    QString coverDataUrl() const { return m_coverDataUrl; }
    QVariantList lyrics() const { return m_lyrics; }
    int currentLyricIndex() const { return m_currentLyricIndex; }
    bool lyricsSynchronized() const { return m_lyricsSynchronized; }
    bool isSystemMediaConnected() const { return m_isSystemMediaConnected; }

    void applySystemSnapshot(bool connected, bool playing,
                             const QString &title, const QString &artist,
                             const QString &album, const QString &coverDataUrl,
                             int durationSeconds,
                             int positionSeconds);
    void setLyrics(const QVariantList &lines, bool synchronized, int matchedDurationSeconds);
    void clearLyrics();

signals:
    void playbackStateChanged(bool playing);
    void trackChanged(const QString &title, const QString &artist);
    void positionChanged(int seconds);
    void lyricChanged(const QString &lyric, const QString &translation);
    void lyricsListChanged();
    void systemMediaStateChanged(bool connected);

private:
    void updateActiveLyric();

    bool m_isPlaying = false;
    QString m_title;
    QString m_artist;
    QString m_album;
    QString m_coverDataUrl;
    int m_durationSeconds = 0;
    int m_positionSeconds = 0;
    bool m_isSystemMediaConnected = false;
    QVariantList m_lyrics;
    int m_currentLyricIndex = -1;
    bool m_lyricsSynchronized = false;
    bool m_hasSystemTimeline = false;
    QTimer m_estimatedTimelineTimer;
};
