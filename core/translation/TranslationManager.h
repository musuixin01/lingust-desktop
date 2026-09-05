#pragma once

#include <QObject>
#include <QVariantMap>
#include "../../providers/ITranslationProvider.h"

class TranslationManager : public QObject
{
    Q_OBJECT
public:
    explicit TranslationManager(QObject *parent = nullptr);

    void setEngine(const QString &engine);
    void setApiKey(const QString &engine, const QString &key);
    void setApiSecret(const QString &engine, const QString &secret);
    void translate(const QString &text, const QString &sourceLang, const QString &targetLang);

signals:
    void translationReady(const QVariantMap &result);
    void translationError(const QString &error);

private:
    QMap<QString, ITranslationProvider*> m_providers;
    QString m_currentEngine;
    ITranslationProvider* getProvider(const QString &engine);
};
