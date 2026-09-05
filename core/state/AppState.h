#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

class AppState : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString sourceText READ sourceText WRITE setSourceText NOTIFY sourceTextChanged)
    Q_PROPERTY(QString translatedText READ translatedText NOTIFY translatedTextChanged)
    Q_PROPERTY(QString phonetic READ phonetic NOTIFY phoneticChanged)
    Q_PROPERTY(bool isWord READ isWord NOTIFY isWordChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(QString sourceLang READ sourceLang WRITE setSourceLang NOTIFY sourceLangChanged)
    Q_PROPERTY(QString targetLang READ targetLang WRITE setTargetLang NOTIFY targetLangChanged)
    Q_PROPERTY(QString engine READ engine WRITE setEngine NOTIFY engineChanged)
    Q_PROPERTY(bool isPinned READ isPinned WRITE setIsPinned NOTIFY isPinnedChanged)
    Q_PROPERTY(bool isFavorite READ isFavorite WRITE setIsFavorite NOTIFY isFavoriteChanged)
    Q_PROPERTY(double fontSizePercent READ fontSizePercent WRITE setFontSizePercent NOTIFY fontSizePercentChanged)
    Q_PROPERTY(bool compactMode READ compactMode WRITE setCompactMode NOTIFY compactModeChanged)
    Q_PROPERTY(bool selectionTranslation READ selectionTranslation WRITE setSelectionTranslation NOTIFY selectionTranslationChanged)
    Q_PROPERTY(QVariantList definitions READ definitions NOTIFY definitionsChanged)
    Q_PROPERTY(QVariantList examples READ examples NOTIFY examplesChanged)
    Q_PROPERTY(QStringList synonyms READ synonyms NOTIFY synonymsChanged)

public:
    explicit AppState(QObject *parent = nullptr);

    QString sourceText() const;
    void setSourceText(const QString &text);
    QString translatedText() const;
    QString phonetic() const;
    bool isWord() const;
    bool isLoading() const;
    QString sourceLang() const;
    void setSourceLang(const QString &lang);
    QString targetLang() const;
    void setTargetLang(const QString &lang);
    QString engine() const;
    void setEngine(const QString &e);
    bool isPinned() const;
    void setIsPinned(bool pinned);
    bool isFavorite() const;
    void setIsFavorite(bool fav);
    double fontSizePercent() const;
    void setFontSizePercent(double p);
    bool compactMode() const;
    void setCompactMode(bool b);
    bool selectionTranslation() const;
    void setSelectionTranslation(bool b);
    QVariantList definitions() const;
    QVariantList examples() const;
    QStringList synonyms() const;

    Q_INVOKABLE void translate();
    Q_INVOKABLE void swapLanguages();
    Q_INVOKABLE void clearText();
    Q_INVOKABLE QString completeTranslation() const;

signals:
    void sourceTextChanged();
    void translatedTextChanged();
    void phoneticChanged();
    void isWordChanged();
    void isLoadingChanged();
    void sourceLangChanged();
    void targetLangChanged();
    void engineChanged();
    void isPinnedChanged();
    void isFavoriteChanged();
    void fontSizePercentChanged();
    void compactModeChanged();
    void selectionTranslationChanged();
    void definitionsChanged();
    void examplesChanged();
    void synonymsChanged();

private:
    void loadDemoData();

    QString m_sourceText;
    QString m_translatedText;
    QString m_phonetic;
    bool m_isWord;
    bool m_isLoading;
    QString m_sourceLang;
    QString m_targetLang;
    QString m_engine;
    bool m_isPinned;
    bool m_isFavorite;
    double m_fontSizePercent;
    bool m_compactMode;
    bool m_selectionTranslation;
    QVariantList m_definitions;
    QVariantList m_examples;
    QStringList m_synonyms;
};
