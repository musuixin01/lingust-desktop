#include <QtTest>

#include "core/auth/AuthManager.h"
#include "core/auth/ISecureCredentialStore.h"
#include "infrastructure/database/DatabaseManager.h"

#include <QHash>
#include <QSignalSpy>
#include <QTcpServer>
#include <QTcpSocket>

class MemoryCredentialStore final : public ISecureCredentialStore
{
public:
    bool writeSecret(const QString &key, const QString &value) override
    {
        values.insert(key, value);
        return true;
    }
    QString readSecret(const QString &key) const override { return values.value(key); }
    bool removeSecret(const QString &key) override { values.remove(key); return true; }
    QHash<QString, QString> values;
};

class AuthManagerSmoke final : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase()
    {
        QCoreApplication::setOrganizationName("LinguistTests");
        QCoreApplication::setApplicationName("AuthManagerSmoke");
        QStandardPaths::setTestModeEnabled(true);
        QSettings().clear();

        QVERIFY(m_server.listen(QHostAddress::LocalHost));
        qputenv("LINGUIST_AUTH_ALLOW_INSECURE_LOCALHOST", "1");
        qputenv("LINGUIST_AUTH_BASE_URL",
                QString("http://127.0.0.1:%1").arg(m_server.serverPort()).toUtf8());
        connect(&m_server, &QTcpServer::newConnection, this, [this]() {
            while (QTcpSocket *socket = m_server.nextPendingConnection()) {
                connect(socket, &QTcpSocket::readyRead, socket, [this, socket]() {
                    const QByteArray request = socket->readAll();
                    if (!request.contains("\r\n\r\n"))
                        return;
                    QByteArray body;
                    QByteArray status = "200 OK";
                    if (request.startsWith("POST /v1/auth/logout")) {
                        body = R"({"ok":true})";
                    } else if (request.startsWith("POST /v1/auth/phone/code")) {
                        body = R"({"retry_after":60})";
                    } else if (request.startsWith("POST /v1/auth/password/reset")) {
                        status = "202 Accepted";
                        body = R"({"accepted":true})";
                    } else if (request.startsWith("POST /v1/auth/register/password")) {
                        status = "202 Accepted";
                        body = R"({"verification_required":true})";
                    } else {
                        body = R"({"access_token":"access-value","refresh_token":"refresh-value","user":{"id":"user-42","display_name":"木汐","email":"user@example.com","provider":"password"}})";
                    }
                    const QByteArray response = "HTTP/1.1 " + status
                        + "\r\nContent-Type: application/json\r\nConnection: close\r\nContent-Length: "
                        + QByteArray::number(body.size()) + "\r\n\r\n" + body;
                    socket->write(response);
                    socket->disconnectFromHost();
                });
            }
        });
    }

    void passwordSessionPersistsAndLogsOut()
    {
        auto store = std::make_unique<MemoryCredentialStore>();
        auto *storeView = store.get();
        AuthManager manager(std::move(store));
        QVERIFY(manager.configured());
        QVERIFY(!manager.authenticated());

        QSignalSpy loginSpy(&manager, &AuthManager::authenticatedChanged);
        manager.loginWithPassword("user@example.com", "long-enough-password");
        QTRY_VERIFY_WITH_TIMEOUT(manager.authenticated(), 2000);
        QCOMPARE(loginSpy.count(), 1);
        QCOMPARE(manager.userId(), QString("user-42"));
        QCOMPARE(manager.displayName(), QString::fromUtf8("木汐"));
        QCOMPARE(storeView->values.value("Linguist/Auth/refresh-token"), QString("refresh-value"));

        manager.logout();
        QTRY_VERIFY_WITH_TIMEOUT(!manager.authenticated(), 2000);
        QVERIFY(storeView->values.isEmpty());
    }

    void invalidIdentifierNeverStartsRequest()
    {
        auto store = std::make_unique<MemoryCredentialStore>();
        AuthManager manager(std::move(store));
        manager.loginWithPassword("not-an-account", "long-enough-password");
        QVERIFY(!manager.busy());
        QVERIFY(!manager.errorMessage().isEmpty());
    }

    void phoneAndEmailRecoveryFlows()
    {
        auto store = std::make_unique<MemoryCredentialStore>();
        AuthManager manager(std::move(store));

        manager.requestPhoneCode("+8613812345678", false);
        QTRY_COMPARE_WITH_TIMEOUT(manager.otpCooldown(), 60, 2000);
        QVERIFY(manager.infoMessage().contains(QString::fromUtf8("验证码")));

        manager.verifyPhoneCode("+8613812345678", "123456", "", false);
        QTRY_VERIFY_WITH_TIMEOUT(manager.authenticated(), 2000);
        manager.logout();

        manager.requestPasswordReset("user@example.com");
        QTRY_VERIFY_WITH_TIMEOUT(manager.infoMessage().contains(QString::fromUtf8("重置邮件")), 2000);

        manager.registerWithPassword("new@example.com", "long-enough-password", QString::fromUtf8("新用户"));
        QTRY_VERIFY_WITH_TIMEOUT(manager.infoMessage().contains(QString::fromUtf8("验证邮件")), 2000);
        QVERIFY(!manager.authenticated());
    }

    void databaseSeparatesLocalAndAccountData()
    {
        DatabaseManager database;
        QVERIFY(database.init());
        database.setOwnerId("local");
        database.clearHistory();
        database.addHistory("local text", "本地", "en", "zh-CN", "test");
        QCOMPARE(database.getHistory().size(), 1);

        database.setOwnerId("user-42");
        database.clearHistory();
        QCOMPARE(database.getHistory().size(), 0);
        database.addHistory("account text", "账户", "en", "zh-CN", "test");
        QCOMPARE(database.getHistory().size(), 1);

        database.setOwnerId("local");
        QCOMPARE(database.getHistory().size(), 1);
        QCOMPARE(database.getHistory().first().toMap().value("sourceText").toString(),
                 QString("local text"));
    }

private:
    QTcpServer m_server;
};

QTEST_MAIN(AuthManagerSmoke)
#include "auth_manager_smoke.moc"
