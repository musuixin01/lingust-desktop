#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QTimer>
#include "../translation/TranslationManager.h"
#include "../translation/OfflineDictionary.h"
#include "../../infrastructure/database/DatabaseManager.h"
#include "../selection/SelectionManager.h"
#include "../media/MediaSessionService.h"
#include "../../providers/lyrics/LrclibLyricsProvider.h"

class AppState : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString sourceText READ sourceText WRITE setSourceText NOTIFY sourceTextChanged)
    Q_PROPERTY(QString translatedText READ translatedText NOTIFY translatedTextChanged)
    Q_PROPERTY(QString sourceLang READ sourceLang WRITE setSourceLang NOTIFY sourceLangChanged)
    Q_PROPERTY(QString targetLang READ targetLang WRITE setTargetLang NOTIFY targetLangChanged)
    Q_PROPERTY(bool isTranslating READ isTranslating NOTIFY isTranslatingChanged)
    Q_PROPERTY(bool isWord READ isWord NOTIFY isWordChanged)
    Q_PROPERTY(QString phoneticUs READ phoneticUs NOTIFY phoneticUsChanged)
    Q_PROPERTY(QString phoneticUk READ phoneticUk NOTIFY phoneticUkChanged)
    Q_PROPERTY(bool isFavorite READ isFavorite WRITE setIsFavorite NOTIFY isFavoriteChanged)
    Q_PROPERTY(QString engine READ engine WRITE setEngine NOTIFY engineChanged)
    Q_PROPERTY(bool justCopied READ justCopied NOTIFY justCopiedChanged)
    Q_PROPERTY(bool isPinned READ isPinned WRITE setIsPinned NOTIFY isPinnedChanged)
    Q_PROPERTY(bool compactMode READ compactMode WRITE setCompactMode NOTIFY compactModeChanged)
    Q_PROPERTY(bool selectionTranslation READ selectionTranslation WRITE setSelectionTranslation NOTIFY selectionTranslationChanged)
    Q_PROPERTY(QString selectionTriggerMode READ selectionTriggerMode WRITE setSelectionTriggerMode NOTIFY selectionTriggerModeChanged)
    Q_PROPERTY(bool autoSpeak READ autoSpeak WRITE setAutoSpeak NOTIFY autoSpeakChanged)
    Q_PROPERTY(double cardOpacity READ cardOpacity WRITE setCardOpacity NOTIFY cardOpacityChanged)
    Q_PROPERTY(int fontSizePercent READ fontSizePercent WRITE setFontSizePercent NOTIFY fontSizePercentChanged)
    Q_PROPERTY(QVariantList definitions READ definitions NOTIFY definitionsChanged)
    Q_PROPERTY(QVariantList examples READ examples NOTIFY examplesChanged)
    Q_PROPERTY(QVariantList synonyms READ synonyms NOTIFY synonymsChanged)
    Q_PROPERTY(QVariantList antonyms READ antonyms NOTIFY antonymsChanged)
    Q_PROPERTY(QVariantList wordForms READ wordForms NOTIFY wordFormsChanged)
    Q_PROPERTY(QVariantList tags READ tags NOTIFY tagsChanged)
    Q_PROPERTY(QString englishDefinition READ englishDefinition NOTIFY englishDefinitionChanged)
    Q_PROPERTY(QVariantList history READ history NOTIFY historyChanged)
    Q_PROPERTY(QVariantList favorites READ favorites NOTIFY favoritesChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(bool hasError READ hasError NOTIFY errorMessageChanged)
    Q_PROPERTY(bool didCrashLastRun READ didCrashLastRun NOTIFY crashInfoChanged)
    Q_PROPERTY(QString lastCrashInfo READ lastCrashInfo NOTIFY crashInfoChanged)
    // 灵动岛音乐与系统媒体总线
    Q_PROPERTY(bool musicPlaying READ musicPlaying NOTIFY musicPlayingChanged)
    Q_PROPERTY(QString trackTitle READ trackTitle NOTIFY musicTrackChanged)
    Q_PROPERTY(QString trackArtist READ trackArtist NOTIFY musicTrackChanged)
    Q_PROPERTY(QString trackAlbum READ trackAlbum NOTIFY musicTrackChanged)
    Q_PROPERTY(int trackDuration READ trackDuration NOTIFY musicTrackChanged)
    Q_PROPERTY(int trackPosition READ trackPosition NOTIFY musicPositionChanged)
    Q_PROPERTY(QString currentLyric READ currentLyric NOTIFY musicLyricChanged)
    Q_PROPERTY(QString currentLyricTranslation READ currentLyricTranslation NOTIFY musicLyricChanged)
    Q_PROPERTY(QString coverArtUrl READ coverArtUrl NOTIFY musicTrackChanged)
    Q_PROPERTY(QVariantList musicLyrics READ musicLyrics NOTIFY musicLyricsChanged)
    Q_PROPERTY(int currentLyricIndex READ currentLyricIndex NOTIFY musicLyricChanged)
    Q_PROPERTY(bool lyricsSynchronized READ lyricsSynchronized NOTIFY musicLyricsChanged)
    Q_PROPERTY(bool systemMediaConnected READ systemMediaConnected NOTIFY systemMediaConnectedChanged)
    Q_PROPERTY(bool pillMusicMode READ pillMusicMode WRITE setPillMusicMode NOTIFY pillMusicModeChanged)
    Q_PROPERTY(QVariantList ocrLines READ ocrLines NOTIFY ocrStateChanged)
    Q_PROPERTY(QString ocrImagePreview READ ocrImagePreview NOTIFY ocrStateChanged)
    Q_PROPERTY(bool isOcrProcessing READ isOcrProcessing NOTIFY ocrStateChanged)
    Q_PROPERTY(QString ocrStatus READ ocrStatus NOTIFY ocrStateChanged)
    Q_PROPERTY(bool screenshotMode READ screenshotMode NOTIFY ocrStateChanged)

public:
    explicit AppState(QObject *parent = nullptr);

    QString sourceText() const;
    Q_INVOKABLE void setSourceText(const QString &text);
    QString translatedText() const;
    QString sourceLang() const;
    Q_INVOKABLE void setSourceLang(const QString &lang);
    QString targetLang() const;
    Q_INVOKABLE void setTargetLang(const QString &lang);
    bool isTranslating() const;
    bool isWord() const;
    QString phoneticUs() const;
    QString phoneticUk() const;
    bool isFavorite() const;
    Q_INVOKABLE void setIsFavorite(bool fav);
    QString engine() const;
    Q_INVOKABLE void setEngine(const QString &e);
    bool justCopied() const;
    bool isPinned() const;
    Q_INVOKABLE void setIsPinned(bool p);
    bool compactMode() const;
    Q_INVOKABLE void setCompactMode(bool b);
    bool selectionTranslation() const;
    Q_INVOKABLE void setSelectionTranslation(bool b);
    QString selectionTriggerMode() const;
    Q_INVOKABLE void setSelectionTriggerMode(const QString &mode);
    bool autoSpeak() const;
    Q_INVOKABLE void setAutoSpeak(bool b);
    double cardOpacity() const;
    Q_INVOKABLE void setCardOpacity(double v);
    int fontSizePercent() const;
    Q_INVOKABLE void setFontSizePercent(int p);
    Q_INVOKABLE void resetFontSize();
    Q_INVOKABLE void clearText();
    QVariantList definitions() const;
    QVariantList examples() const;
    QVariantList synonyms() const;
    QVariantList antonyms() const;
    QVariantList wordForms() const;
    QVariantList tags() const;
    QString englishDefinition() const;
    QVariantList history() const;
    QVariantList favorites() const;
    QString errorMessage() const { return m_errorMessage; }
    bool hasError() const { return !m_errorMessage.isEmpty(); }
    Q_INVOKABLE void clearError();
    bool didCrashLastRun() const;
    QString lastCrashInfo() const;
    Q_INVOKABLE void dismissCrashWarning();

    Q_INVOKABLE void translate();
    Q_INVOKABLE void swapLanguages();
    Q_INVOKABLE void copyTranslation();
    Q_INVOKABLE void copySourceText();
    Q_INVOKABLE void speak(const QString &text = QString(), const QString &lang = QString(), const QString &accent = "us");
    Q_INVOKABLE void setApiKey(const QString &engine, const QString &key);
    Q_INVOKABLE void setApiSecret(const QString &engine, const QString &secret);
    Q_INVOKABLE void toggleFavorite();
    Q_INVOKABLE void clearHistory();
    Q_INVOKABLE void deleteHistory(int id);
    Q_INVOKABLE void refreshHistory();
    Q_INVOKABLE void openHistoryItem(const QVariantMap &item);
    Q_INVOKABLE void refreshFavorites();
    Q_INVOKABLE void triggerSelectionTranslation();
    Q_INVOKABLE void requestScreenshot();
    Q_INVOKABLE void exitScreenshotMode();
    Q_INVOKABLE QString completeTranslation() const;

    QVariantList ocrLines() const { return m_ocrLines; }
    QString ocrImagePreview() const { return m_ocrImagePreview; }
    bool isOcrProcessing() const { return m_isOcrProcessing; }
    QString ocrStatus() const { return m_ocrStatus; }
    bool screenshotMode() const { return m_screenshotMode; }

    // 灵动岛音乐与媒体操作
    bool musicPlaying() const;
    QString trackTitle() const;
    QString trackArtist() const;
    QString trackAlbum() const;
    int trackDuration() const;
    int trackPosition() const;
    QString currentLyric() const;
    QString currentLyricTranslation() const;
    QString coverArtUrl() const;
    QVariantList musicLyrics() const;
    int currentLyricIndex() const;
    bool lyricsSynchronized() const;
    bool systemMediaConnected() const;
    bool pillMusicMode() const { return m_pillMusicMode; }
    Q_INVOKABLE void setPillMusicMode(bool enabled);
    Q_INVOKABLE void togglePillMusicMode();
    Q_INVOKABLE void toggleMusicPlay();
    Q_INVOKABLE void nextTrack();
    Q_INVOKABLE void prevTrack();
    Q_INVOKABLE void seekTrack(int seconds);

public slots:
    void beginScreenshotTranslation(const QString &previewUrl);
    void submitOcrText(const QString &text);
    void setOcrError(const QString &message);
    void updateSystemMediaSession(bool connected, bool playing,
                                  const QString &title, const QString &artist,
                                  const QString &album, const QString &coverDataUrl,
                                  int durationSeconds,
                                  int positionSeconds);

signals:
    void sourceTextChanged();
    void textCleared();
    void translatedTextChanged();
    void sourceLangChanged();
    void targetLangChanged();
    void isTranslatingChanged();
    void isWordChanged();
    void phoneticUsChanged();
    void phoneticUkChanged();
    void isFavoriteChanged();
    void engineChanged();
    void justCopiedChanged();
    void isPinnedChanged();
    void compactModeChanged();
    void selectionTranslationChanged();
    void selectionTriggerModeChanged();
    void autoSpeakChanged();
    void cardOpacityChanged();
    void fontSizePercentChanged();
    void definitionsChanged();
    void examplesChanged();
    void synonymsChanged();
    void antonymsChanged();
    void wordFormsChanged();
    void tagsChanged();
    void englishDefinitionChanged();
    void historyChanged();
    void favoritesChanged();
    void errorMessageChanged();
    void crashInfoChanged();
    void musicPlayingChanged();
    void musicTrackChanged();
    void musicPositionChanged();
    void musicLyricChanged();
    void musicLyricsChanged();
    void systemMediaConnectedChanged();
    void pillMusicModeChanged();
    void screenshotRequested();
    void ocrStateChanged();
    void musicToggleRequested();
    void musicNextRequested();
    void musicPreviousRequested();
    void musicSeekRequested(int seconds);

private slots:
    void onTranslationReady(const QVariantMap &result);
    void onTranslationError(const QString &error);
    void onOcrLineTranslationReady(const QVariantMap &result);
    void onOcrLineTranslationError(const QString &error);
    void resetJustCopied();
    void applyPendingResult();

private:
    void clearResult();
    void translateNextOcrLine();
    void finishOcrLineTranslation();

    QString m_sourceText;
    QString m_translatedText;
    QString m_sourceLang;
    QString m_targetLang;
    bool m_isTranslating;
    bool m_isWord;
    QString m_phoneticUs;
    QString m_phoneticUk;
    bool m_isFavorite;
    QString m_engine;
    bool m_justCopied;
    bool m_isPinned;
    bool m_compactMode;
    bool m_selectionTranslation;
    QString m_selectionTriggerMode;
    bool m_autoSpeak;
    double m_cardOpacity;
    int m_fontSizePercent;
    QVariantList m_definitions;
    QVariantList m_examples;
    QVariantList m_synonyms;
    QVariantList m_antonyms;
    QVariantList m_wordForms;
    QVariantList m_tags;
    QString m_englishDefinition;
    QVariantList m_history;
    QVariantList m_favorites;
    QString m_errorMessage;
    QTimer m_copyTimer;
    QTimer m_minLoadTimer;
    qint64 m_translateStartTime;
    quint64 m_translationRevision = 0;
    QVariantMap m_pendingResult;
    QString m_pendingError;
    TranslationManager *m_translationManager;
    TranslationManager *m_ocrTranslationManager;
    OfflineDictionary *m_offlineDict;
    DatabaseManager *m_database;
    SelectionManager *m_selectionManager;
    MediaSessionService *m_mediaSession;
    LrclibLyricsProvider *m_lyricsProvider;
    bool m_pillMusicMode = false;
    QVariantList m_ocrLines;
    QString m_ocrImagePreview;
    QString m_ocrOriginalText;
    QStringList m_ocrSourceLines;
    QStringList m_ocrTranslatedLines;
    QString m_ocrStatus;
    bool m_isOcrProcessing = false;
    int m_ocrLineIndex = 0;
    bool m_screenshotMode = false;
};
