#pragma once

#include "../ITranslationProvider.h"

#include <QNetworkAccessManager>
#include <QVariantList>

class QNetworkReply;

class FallbackProvider final : public ITranslationProvider
{
    Q_OBJECT

public:
    explicit FallbackProvider(QObject *parent = nullptr);

    QString name() const override { return "fallback"; }
    void translate(const QString &text, const QString &sourceLang,
                   const QString &targetLang) override;

private:
    void requestTranslation(const QString &text, const QString &sourceLang,
                            const QString &targetLang, const QString &kind);
    void requestExamples(const QString &word, const QString &targetLang);
    void requestRelatedWords(const QString &word, const QString &relation);
    void handleReply(QNetworkReply *reply);
    void finishOne();
    void complete();

    QNetworkAccessManager *m_network;
    quint64 m_requestId = 0;
    int m_pending = 0;
    QString m_sourceText;
    QString m_sourceLang;
    QString m_targetLang;
    QVariantMap m_result;
    QVariantList m_examples;
};
