#include "MediaSessionService.h"

#include <QtGlobal>

namespace {
constexpr qint64 kLyricLeadTimeMs = 650;
}

MediaSessionService::MediaSessionService(QObject *parent)
    : QObject(parent)
{
    m_estimatedTimelineTimer.setInterval(1000);
    connect(&m_estimatedTimelineTimer, &QTimer::timeout, this, [this] {
        if (!m_isPlaying || m_hasSystemTimeline || m_durationSeconds <= 0)
            return;
        m_positionSeconds = qMin(m_positionSeconds + 1, m_durationSeconds);
        emit positionChanged(m_positionSeconds);
        updateActiveLyric();
        if (m_positionSeconds >= m_durationSeconds)
            m_estimatedTimelineTimer.stop();
    });
}

void MediaSessionService::applySystemSnapshot(bool connected, bool playing,
                                              const QString &title, const QString &artist,
                                              const QString &album, const QString &coverDataUrl,
                                              int durationSeconds,
                                              int positionSeconds)
{
    const bool mediaIdentityChanged = m_title != title || m_artist != artist;
    const bool connectionChanged = m_isSystemMediaConnected != connected;
    const bool playbackChanged = m_isPlaying != (connected && playing);
    const bool hasSystemTimeline = durationSeconds > 0;
    const int effectiveDuration = hasSystemTimeline ? durationSeconds
                                                     : (mediaIdentityChanged ? 0 : m_durationSeconds);
    const int boundedPosition = hasSystemTimeline
        ? qBound(0, positionSeconds, effectiveDuration)
        : (mediaIdentityChanged ? 0 : m_positionSeconds);
    const bool trackWasChanged = m_title != title || m_artist != artist ||
                                 m_album != album || m_coverDataUrl != coverDataUrl ||
                                 m_durationSeconds != effectiveDuration;
    const bool positionWasChanged = m_positionSeconds != boundedPosition;

    m_isSystemMediaConnected = connected;
    m_isPlaying = connected && playing;
    m_title = connected ? title : QString();
    m_artist = connected ? artist : QString();
    m_album = connected ? album : QString();
    m_coverDataUrl = connected ? coverDataUrl : QString();
    m_durationSeconds = connected ? qMax(0, effectiveDuration) : 0;
    m_positionSeconds = connected ? boundedPosition : 0;
    m_hasSystemTimeline = connected && hasSystemTimeline;
    if (m_isPlaying && !m_hasSystemTimeline)
        m_estimatedTimelineTimer.start();
    else
        m_estimatedTimelineTimer.stop();

    if (connectionChanged)
        emit systemMediaStateChanged(m_isSystemMediaConnected);
    if (playbackChanged)
        emit playbackStateChanged(m_isPlaying);
    if (trackWasChanged || connectionChanged)
        emit trackChanged(m_title, m_artist);
    if (mediaIdentityChanged || !connected)
        clearLyrics();
    if (positionWasChanged || connectionChanged) {
        emit positionChanged(m_positionSeconds);
        updateActiveLyric();
    }
}

QString MediaSessionService::currentLyric() const
{
    if (m_currentLyricIndex < 0 || m_currentLyricIndex >= m_lyrics.size())
        return {};
    return m_lyrics.at(m_currentLyricIndex).toMap().value("text").toString();
}

void MediaSessionService::setLyrics(const QVariantList &lines, bool synchronized, int matchedDurationSeconds)
{
    m_lyrics = lines;
    m_lyricsSynchronized = synchronized;
    m_currentLyricIndex = m_lyrics.isEmpty() ? -1 : 0;
    if (!m_hasSystemTimeline && m_durationSeconds <= 0 && matchedDurationSeconds > 0) {
        m_durationSeconds = matchedDurationSeconds;
        emit trackChanged(m_title, m_artist);
        if (m_isPlaying)
            m_estimatedTimelineTimer.start();
    }
    updateActiveLyric();
    emit lyricsListChanged();
    emit lyricChanged(currentLyric(), {});
}

void MediaSessionService::clearLyrics()
{
    if (m_lyrics.isEmpty() && m_currentLyricIndex == -1)
        return;
    m_lyrics.clear();
    m_currentLyricIndex = -1;
    m_lyricsSynchronized = false;
    emit lyricsListChanged();
    emit lyricChanged({}, {});
}

void MediaSessionService::updateActiveLyric()
{
    if (m_lyrics.isEmpty())
        return;
    int nextIndex = 0;
    if (m_lyricsSynchronized) {
        // 视觉先于听觉少量出现，让用户能在演唱开始前读到下一句。
        const qint64 positionMs = static_cast<qint64>(m_positionSeconds) * 1000
                                + kLyricLeadTimeMs;
        for (int index = 0; index < m_lyrics.size(); ++index) {
            if (m_lyrics.at(index).toMap().value("timeMs").toLongLong() <= positionMs)
                nextIndex = index;
            else
                break;
        }
    }
    if (nextIndex != m_currentLyricIndex) {
        m_currentLyricIndex = nextIndex;
        emit lyricChanged(currentLyric(), {});
    }
}
