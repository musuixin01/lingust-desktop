#pragma once

#include "../../../core/auth/ISecureCredentialStore.h"

class WindowsCredentialStore final : public ISecureCredentialStore
{
public:
    bool writeSecret(const QString &key, const QString &value) override;
    QString readSecret(const QString &key) const override;
    bool removeSecret(const QString &key) override;
};
