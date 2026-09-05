#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QTimer>
#include "../translation/TranslationManager.h"
#include "../../infrastructure/database/DatabaseManager.h"
#include "../selection/SelectionManager.h"

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
    Q_PROPERTY(bool compactMode READ compactMode WRITE setCompactMode NOTIFY compactModeChanged)
    Q_PROPERTY(bool selectionTranslation READ selectionTranslation WRITE setSelectionTranslation NOTIFY selectionTranslationChanged)
    Q_PROPERTY(bool autoSpeak READ autoSpeak WRITE setAutoSpeak NOTIFY autoSpeakChanged)
    Q_PROPERTY(double cardOpacity READ cardOpacity WRITE setCardOpacity NOTIFY cardOpacityChanged)
    Q_PROPERTY(QVariantList definitions READ definitions NOTIFY definitionsChanged)
    Q_PROPERTY(QVariantList examples READ examples NOTIFY examplesChanged)
    Q_PROPERTY(QVariantList synonyms READ synonyms NOTIFY synonymsChanged)
    Q_PROPERTY(QVariantList history READ history NOTIFY historyChanged)
    Q_PROPERTY(QVariantList favorites READ favorites NOTIFY favoritesChanged)

public:
    explicit AppState(QObject *parent = nullptr);

    QString sourceText() const;
    void setSourceText(const QString &text);
    QString translatedText() const;
    QString sourceLang() const;
    void setSourceLang(const QString &lang);
    QString targetLang() const;
    void setTargetLang(const QString &lang);
    bool isTranslating() const;
    bool isWord() const;
    QString phoneticUs() const;
    QString phoneticUk() const;
    bool isFavorite() const;
    void setIsFavorite(bool fav);
    QString engine() const;
    void setEngine(const QString &e);
    bool justCopied() const;
    bool compactMode() const;
    void setCompactMode(bool b);
    bool selectionTranslation() const;
    void setSelectionTranslation(bool b);
    bool autoSpeak() const;
    void setAutoSpeak(bool b);
    double cardOpacity() const;
    void setCardOpacity(double v);
    QVariantList definitions() const;
    QVariantList examples() const;
    QVariantList synonyms() const;
    QVariantList history() const;
    QVariantList favorites() const;

    Q_INVOKABLE void translate();
    Q_INVOKABLE void swapLanguages();
    Q_INVOKABLE void copyTranslation();
    Q_INVOKABLE void copySourceText();
    Q_INVOKABLE void speak(const QString &text, const QString &lang = "en", const QString &accent = "us");
    Q_INVOKABLE void setApiKey(const QString &engine, const QString &key);
    Q_INVOKABLE void setApiSecret(const QString &engine, const QString &secret);
    Q_INVOKABLE void toggleFavorite();
    Q_INVOKABLE void clearHistory();
    Q_INVOKABLE void refreshHistory();
    Q_INVOKABLE void refreshFavorites();
    Q_INVOKABLE void triggerSelectionTranslation();

signals:
    void sourceTextChanged();
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
    void compactModeChanged();
    void selectionTranslationChanged();
    void autoSpeakChanged();
    void cardOpacityChanged();
    void definitionsChanged();
    void examplesChanged();
    void synonymsChanged();
    void historyChanged();
    void favoritesChanged();

private slots:
    void onTranslationReady(const QVariantMap &result);
    void onTranslationError(const QString &error);
    void resetJustCopied();

private:
    void clearResult();

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
    bool m_compactMode;
    bool m_selectionTranslation;
    bool m_autoSpeak;
    double m_cardOpacity;
    QVariantList m_definitions;
    QVariantList m_examples;
    QVariantList m_synonyms;
    QVariantList m_history;
    QVariantList m_favorites;
    QTimer m_copyTimer;
    TranslationManager *m_translationManager;
    DatabaseManager *m_database;
    SelectionManager *m_selectionManager;
};
