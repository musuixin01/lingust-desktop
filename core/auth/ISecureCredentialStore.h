#pragma once

#include <QString>

class ISecureCredentialStore
{
public:
    virtual ~ISecureCredentialStore() = default;

    virtual bool writeSecret(const QString &key, const QString &value) = 0;
    virtual QString readSecret(const QString &key) const = 0;
    virtual bool removeSecret(const QString &key) = 0;
};
