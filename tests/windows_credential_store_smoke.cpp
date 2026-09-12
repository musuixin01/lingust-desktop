#include <QtTest>

#include "platform/windows/auth/WindowsCredentialStore.h"

#include <QUuid>

class WindowsCredentialStoreSmoke final : public QObject
{
    Q_OBJECT

private slots:
    void roundTripAndDelete()
    {
        WindowsCredentialStore store;
        const QString key = QStringLiteral("Linguist/Test/")
            + QUuid::createUuid().toString(QUuid::WithoutBraces);
        const QString secret = QStringLiteral("refresh-token-测试-") + key.right(8);

        QVERIFY(store.writeSecret(key, secret));
        QCOMPARE(store.readSecret(key), secret);
        QVERIFY(store.removeSecret(key));
        QVERIFY(store.readSecret(key).isEmpty());
    }
};

QTEST_MAIN(WindowsCredentialStoreSmoke)
#include "windows_credential_store_smoke.moc"
