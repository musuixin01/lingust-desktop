#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QPointer>
#include <QSettings>
#include <QTimer>
#include <QVariantMap>
#include <memory>

class ISecureCredentialStore;
class QNetworkReply;

class AuthManager final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool configured READ configured NOTIFY configuredChanged)
    Q_PROPERTY(bool authenticated READ authenticated NOTIFY authenticatedChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool hasSavedSession READ hasSavedSession NOTIFY hasSavedSessionChanged)
    Q_PROPERTY(QString userId READ userId NOTIFY profileChanged)
    Q_PROPERTY(QString displayName READ displayName NOTIFY profileChanged)
    Q_PROPERTY(QString email READ email NOTIFY profileChanged)
    Q_PROPERTY(QString phone READ phone NOTIFY profileChanged)
    Q_PROPERTY(QString avatarUrl READ avatarUrl NOTIFY profileChanged)
    Q_PROPERTY(QString provider READ provider NOTIFY profileChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY messageChanged)
    Q_PROPERTY(QString infoMessage READ infoMessage NOTIFY messageChanged)
    Q_PROPERTY(int otpCooldown READ otpCooldown NOTIFY otpCooldownChanged)

public:
    explicit AuthManager(std::unique_ptr<ISecureCredentialStore> secureStore,
                         QObject *parent = nullptr);
    ~AuthManager() override;

    bool configured() const;
    bool authenticated() const { return m_authenticated; }
    bool busy() const { return m_busy; }
    bool hasSavedSession() const { return m_hasSavedSession; }
    QString userId() const { return m_profile.value("id").toString(); }
    QString displayName() const { return m_profile.value("displayName").toString(); }
    QString email() const { return m_profile.value("email").toString(); }
    QString phone() const { return m_profile.value("phone").toString(); }
    QString avatarUrl() const { return m_profile.value("avatarUrl").toString(); }
    QString provider() const { return m_profile.value("provider").toString(); }
    QString errorMessage() const { return m_errorMessage; }
    QString infoMessage() const { return m_infoMessage; }
    int otpCooldown() const { return m_otpCooldown; }

    Q_INVOKABLE void loginWithPassword(const QString &identifier, const QString &password);
    Q_INVOKABLE void registerWithPassword(const QString &identifier, const QString &password,
                                           const QString &displayName);
    Q_INVOKABLE void requestPhoneCode(const QString &phone, bool registering);
    Q_INVOKABLE void verifyPhoneCode(const QString &phone, const QString &code,
                                     const QString &displayName, bool registering);
    Q_INVOKABLE void startWeChatLogin();
    Q_INVOKABLE void requestPasswordReset(const QString &email);
    Q_INVOKABLE void cancelCurrentRequest();
    Q_INVOKABLE void logout();
    Q_INVOKABLE void restoreSession();
    Q_INVOKABLE void clearMessages();

signals:
    void configuredChanged();
    void authenticatedChanged();
    void busyChanged();
    void hasSavedSessionChanged();
    void profileChanged();
    void messageChanged();
    void otpCooldownChanged();
    void accountChanged(const QString &userId);

private:
    enum class RequestKind {
        None,
        Login,
        Register,
        PhoneCode,
        PhoneVerify,
        PasswordReset,
        WeChatStart,
        WeChatStatus,
        Refresh,
        Logout
    };

    void sendJson(RequestKind kind, const QString &path, const QVariantMap &body,
                  bool authorized = false);
    void handleReply(QNetworkReply *reply, RequestKind kind);
    void applySession(const QVariantMap &payload);
    void clearSession(bool clearProfile);
    void setBusy(bool busy);
    void setError(const QString &message);
    void setInfo(const QString &message);
    QVariantMap normalizedUser(const QVariantMap &user) const;
    QString endpoint(const QString &path) const;
    QString friendlyError(int status, const QVariantMap &payload) const;
    static bool validIdentifier(const QString &value);
    static bool validPhone(const QString &value);

    std::unique_ptr<ISecureCredentialStore> m_secureStore;
    QNetworkAccessManager m_network;
    QSettings m_settings;
    QPointer<QNetworkReply> m_activeReply;
    QTimer m_otpTimer;
    QTimer m_weChatPollTimer;
    QString m_baseUrl;
    QString m_accessToken;
    QString m_weChatTransaction;
    QVariantMap m_profile;
    bool m_authenticated = false;
    bool m_busy = false;
    bool m_hasSavedSession = false;
    int m_otpCooldown = 0;
    int m_weChatPollCount = 0;
    QString m_errorMessage;
    QString m_infoMessage;
};
