#include "WindowsCredentialStore.h"

#include <windows.h>
#include <wincred.h>

#include <QByteArray>

bool WindowsCredentialStore::writeSecret(const QString &key, const QString &value)
{
    const QByteArray secret = value.toUtf8();
    if (key.isEmpty() || secret.isEmpty() || secret.size() > CRED_MAX_CREDENTIAL_BLOB_SIZE)
        return false;

    CREDENTIALW credential{};
    credential.Type = CRED_TYPE_GENERIC;
    credential.TargetName = const_cast<wchar_t *>(reinterpret_cast<const wchar_t *>(key.utf16()));
    credential.CredentialBlobSize = static_cast<DWORD>(secret.size());
    credential.CredentialBlob = reinterpret_cast<LPBYTE>(const_cast<char *>(secret.constData()));
    credential.Persist = CRED_PERSIST_LOCAL_MACHINE;
    const QString userName = QStringLiteral("Linguist desktop session");
    credential.UserName = const_cast<wchar_t *>(reinterpret_cast<const wchar_t *>(userName.utf16()));
    return CredWriteW(&credential, 0) == TRUE;
}

QString WindowsCredentialStore::readSecret(const QString &key) const
{
    PCREDENTIALW credential = nullptr;
    if (!CredReadW(reinterpret_cast<const wchar_t *>(key.utf16()), CRED_TYPE_GENERIC, 0,
                   &credential)) {
        return {};
    }
    const QByteArray bytes(reinterpret_cast<const char *>(credential->CredentialBlob),
                           static_cast<int>(credential->CredentialBlobSize));
    CredFree(credential);
    return QString::fromUtf8(bytes);
}

bool WindowsCredentialStore::removeSecret(const QString &key)
{
    if (CredDeleteW(reinterpret_cast<const wchar_t *>(key.utf16()), CRED_TYPE_GENERIC, 0))
        return true;
    return GetLastError() == ERROR_NOT_FOUND;
}
