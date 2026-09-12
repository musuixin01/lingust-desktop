#include "AuthManager.h"

#include "ISecureCredentialStore.h"

#include <QCoreApplication>
#include <QDesktopServices>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QUuid>
#include <QUrlQuery>

namespace {
constexpr auto kRefreshTokenKey = "Linguist/Auth/refresh-token";

QString field(const QVariantMap &map, const QString &snake, const QString &camel = {})
{
    const QString value = map.value(snake).toString();
    return value.isEmpty() && !camel.isEmpty() ? map.value(camel).toString() : value;
}
}

AuthManager::AuthManager(std::unique_ptr<ISecureCredentialStore> secureStore, QObject *parent)
    : QObject(parent)
    , m_secureStore(std::move(secureStore))
{
    m_baseUrl = qEnvironmentVariable("LINGUIST_AUTH_BASE_URL").trimmed();
    if (m_baseUrl.isEmpty())
        m_baseUrl = m_settings.value("auth/baseUrl").toString().trimmed();
    while (m_baseUrl.endsWith('/'))
        m_baseUrl.chop(1);

    m_otpTimer.setInterval(1000);
    connect(&m_otpTimer, &QTimer::timeout, this, [this]() {
        if (m_otpCooldown > 0) {
            --m_otpCooldown;
            emit otpCooldownChanged();
        }
        if (m_otpCooldown <= 0)
            m_otpTimer.stop();
    });

    m_weChatPollTimer.setInterval(1500);
    connect(&m_weChatPollTimer, &QTimer::timeout, this, [this]() {
        if (m_weChatTransaction.isEmpty() || m_activeReply)
            return;
        if (++m_weChatPollCount >= 120) {
            m_weChatPollTimer.stop();
            m_weChatTransaction.clear();
            setBusy(false);
            setError(QStringLiteral("微信登录已超时，请重新发起"));
            return;
        }
        QUrlQuery query;
        query.addQueryItem("transaction_id", m_weChatTransaction);
        sendJson(RequestKind::WeChatStatus,
                 QStringLiteral("/v1/auth/wechat/status?") + query.toString(QUrl::FullyEncoded), {});
    });

    const QString saved = m_secureStore ? m_secureStore->readSecret(kRefreshTokenKey) : QString();
    m_hasSavedSession = !saved.isEmpty();
    if (m_hasSavedSession && configured())
        QTimer::singleShot(0, this, &AuthManager::restoreSession);
}

AuthManager::~AuthManager() = default;

bool AuthManager::configured() const
{
    const QUrl url(m_baseUrl);
    const bool localDevelopment = qEnvironmentVariableIntValue("LINGUIST_AUTH_ALLOW_INSECURE_LOCALHOST") == 1
        && (url.host() == QStringLiteral("127.0.0.1") || url.host() == QStringLiteral("localhost"));
    return url.isValid() && !url.host().isEmpty()
        && (url.scheme() == QStringLiteral("https")
            || (localDevelopment && url.scheme() == QStringLiteral("http")));
}

void AuthManager::loginWithPassword(const QString &identifier, const QString &password)
{
    const QString account = identifier.trimmed();
    clearMessages();
    if (!configured()) {
        setError(QStringLiteral("账号服务尚未配置，请联系管理员"));
        return;
    }
    if (!validIdentifier(account)) {
        setError(QStringLiteral("请输入有效的邮箱或手机号"));
        return;
    }
    if (password.size() < 8) {
        setError(QStringLiteral("密码至少需要 8 个字符"));
        return;
    }
    sendJson(RequestKind::Login, QStringLiteral("/v1/auth/login/password"),
             {{"identifier", account}, {"password", password},
              {"device_name", QCoreApplication::applicationName()}, {"platform", "windows"}});
}

void AuthManager::registerWithPassword(const QString &identifier, const QString &password,
                                       const QString &displayName)
{
    const QString account = identifier.trimmed();
    clearMessages();
    if (!configured()) {
        setError(QStringLiteral("账号服务尚未配置，请联系管理员"));
        return;
    }
    if (!validIdentifier(account)) {
        setError(QStringLiteral("请输入有效的邮箱或手机号"));
        return;
    }
    if (displayName.trimmed().size() < 2) {
        setError(QStringLiteral("昵称至少需要 2 个字符"));
        return;
    }
    if (password.size() < 8) {
        setError(QStringLiteral("密码至少需要 8 个字符"));
        return;
    }
    sendJson(RequestKind::Register, QStringLiteral("/v1/auth/register/password"),
             {{"identifier", account}, {"password", password},
              {"display_name", displayName.trimmed()}, {"locale", "zh-CN"},
              {"platform", "windows"}});
}

void AuthManager::requestPhoneCode(const QString &phone, bool registering)
{
    const QString normalized = phone.trimmed();
    clearMessages();
    if (!configured()) {
        setError(QStringLiteral("账号服务尚未配置，请联系管理员"));
        return;
    }
    if (!validPhone(normalized)) {
        setError(QStringLiteral("请输入有效的手机号，国际号码请包含国家代码"));
        return;
    }
    if (m_otpCooldown > 0)
        return;
    sendJson(RequestKind::PhoneCode, QStringLiteral("/v1/auth/phone/code"),
             {{"phone", normalized}, {"purpose", registering ? "register" : "login"},
              {"locale", "zh-CN"}});
}

void AuthManager::verifyPhoneCode(const QString &phone, const QString &code,
                                  const QString &displayName, bool registering)
{
    const QString normalized = phone.trimmed();
    const QString otp = code.trimmed();
    clearMessages();
    if (!configured()) {
        setError(QStringLiteral("账号服务尚未配置，请联系管理员"));
        return;
    }
    if (!validPhone(normalized) || otp.size() < 4 || otp.size() > 8) {
        setError(QStringLiteral("请检查手机号和验证码"));
        return;
    }
    if (registering && displayName.trimmed().size() < 2) {
        setError(QStringLiteral("昵称至少需要 2 个字符"));
        return;
    }
    sendJson(RequestKind::PhoneVerify, QStringLiteral("/v1/auth/phone/verify"),
             {{"phone", normalized}, {"code", otp},
              {"purpose", registering ? "register" : "login"},
              {"display_name", displayName.trimmed()}, {"platform", "windows"}});
}

void AuthManager::startWeChatLogin()
{
    clearMessages();
    if (!configured()) {
        setError(QStringLiteral("账号服务尚未配置，请联系管理员"));
        return;
    }
    m_weChatPollTimer.stop();
    m_weChatTransaction.clear();
    m_weChatPollCount = 0;
    sendJson(RequestKind::WeChatStart, QStringLiteral("/v1/auth/wechat/start"),
             {{"platform", "windows"}, {"locale", "zh-CN"}});
}

void AuthManager::requestPasswordReset(const QString &email)
{
    const QString normalized = email.trimmed();
    clearMessages();
    static const QRegularExpression emailPattern(
        QStringLiteral(R"(^[^\s@]+@[^\s@]+\.[^\s@]+$)"),
        QRegularExpression::CaseInsensitiveOption);
    if (!configured()) {
        setError(QStringLiteral("账号服务尚未配置，请联系管理员"));
        return;
    }
    if (!emailPattern.match(normalized).hasMatch()) {
        setError(QStringLiteral("请先输入有效的邮箱地址"));
        return;
    }
    sendJson(RequestKind::PasswordReset, QStringLiteral("/v1/auth/password/reset"),
             {{"email", normalized}, {"locale", "zh-CN"}});
}

void AuthManager::cancelCurrentRequest()
{
    if (m_activeReply)
        m_activeReply->abort();
    m_weChatPollTimer.stop();
    m_weChatTransaction.clear();
    setBusy(false);
    setInfo(QStringLiteral("已取消登录"));
}

void AuthManager::logout()
{
    clearMessages();
    m_weChatPollTimer.stop();
    if (configured() && !m_accessToken.isEmpty()) {
        sendJson(RequestKind::Logout, QStringLiteral("/v1/auth/logout"), {}, true);
        clearSession(true);
    } else {
        clearSession(true);
    }
    setBusy(false);
    setInfo(QStringLiteral("已安全退出"));
}

void AuthManager::restoreSession()
{
    if (!configured() || !m_secureStore || m_busy)
        return;
    const QString refreshToken = m_secureStore->readSecret(kRefreshTokenKey);
    if ((refreshToken.isEmpty())) {
        if (m_hasSavedSession) {
            m_hasSavedSession = false;
            emit hasSavedSessionChanged();
        }
        return;
    }
    sendJson(RequestKind::Refresh, QStringLiteral("/v1/auth/token/refresh"),
             {{"refresh_token", refreshToken}, {"platform", "windows"}});
}

void AuthManager::clearMessages()
{
    if (m_errorMessage.isEmpty() && m_infoMessage.isEmpty())
        return;
    m_errorMessage.clear();
    m_infoMessage.clear();
    emit messageChanged();
}

void AuthManager::sendJson(RequestKind kind, const QString &path, const QVariantMap &body,
                           bool authorized)
{
    if (m_activeReply && kind != RequestKind::WeChatStatus)
        m_activeReply->abort();

    QNetworkRequest request{QUrl(endpoint(path))};
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setTransferTimeout(15000);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("X-Request-Id", QUuid::createUuid().toString(QUuid::WithoutBraces).toUtf8());
    request.setRawHeader("X-Client-Version", QCoreApplication::applicationVersion().toUtf8());
    if (authorized && !m_accessToken.isEmpty())
        request.setRawHeader("Authorization", QByteArrayLiteral("Bearer ") + m_accessToken.toUtf8());

    QNetworkReply *reply = nullptr;
    if (kind == RequestKind::WeChatStatus)
        reply = m_network.get(request);
    else
        reply = m_network.post(request, QJsonDocument::fromVariant(body).toJson(QJsonDocument::Compact));

    m_activeReply = reply;
    if (kind != RequestKind::WeChatStatus || !m_busy)
        setBusy(true);
    connect(reply, &QNetworkReply::finished, this, [this, reply, kind]() {
        handleReply(reply, kind);
    });
}

void AuthManager::handleReply(QNetworkReply *reply, RequestKind kind)
{
    if (!reply)
        return;
    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    const QByteArray bytes = reply->readAll();
    if (bytes.size() > 64 * 1024) {
        if (m_activeReply == reply)
            m_activeReply.clear();
        reply->deleteLater();
        setBusy(false);
        setError(QStringLiteral("账号服务响应异常，请稍后重试"));
        return;
    }
    QVariantMap payload = QJsonDocument::fromJson(bytes).object().toVariantMap();
    if (payload.value("data").canConvert<QVariantMap>()) {
        const QVariantMap envelope = payload;
        payload = payload.value("data").toMap();
        if (!payload.contains("message") && envelope.contains("message"))
            payload.insert("message", envelope.value("message"));
    }
    const bool success = reply->error() == QNetworkReply::NoError && status >= 200 && status < 300;
    if (m_activeReply == reply)
        m_activeReply.clear();
    reply->deleteLater();

    if (!success) {
        if (reply->error() == QNetworkReply::OperationCanceledError)
            return;
        if (kind == RequestKind::WeChatStatus && (status == 0 || status >= 500))
            return;
        if (kind == RequestKind::WeChatStatus) {
            m_weChatPollTimer.stop();
            m_weChatTransaction.clear();
        }
        setBusy(false);
        if (kind == RequestKind::Logout) {
            setInfo(QStringLiteral("已退出本机，远端会话将在令牌到期后失效"));
            return;
        }
        if (kind == RequestKind::Refresh && (status == 401 || status == 403))
            clearSession(false);
        setError(friendlyError(status, payload));
        return;
    }

    switch (kind) {
    case RequestKind::PhoneCode:
        m_otpCooldown = qBound(30, payload.value("retry_after", 60).toInt(), 300);
        emit otpCooldownChanged();
        m_otpTimer.start();
        setBusy(false);
        setInfo(QStringLiteral("验证码已发送，请留意短信"));
        break;
    case RequestKind::PasswordReset:
        setBusy(false);
        setInfo(QStringLiteral("如果该邮箱已注册，重置邮件会很快送达"));
        break;
    case RequestKind::WeChatStart: {
        const QString url = field(payload, "authorize_url", "authorizeUrl");
        m_weChatTransaction = field(payload, "transaction_id", "transactionId");
        if (url.isEmpty() || m_weChatTransaction.isEmpty()) {
            setBusy(false);
            setError(QStringLiteral("微信登录响应不完整，请稍后重试"));
            break;
        }
        QDesktopServices::openUrl(QUrl(url));
        m_weChatPollCount = 0;
        m_weChatPollTimer.start();
        setInfo(QStringLiteral("请在浏览器中使用微信完成确认"));
        break;
    }
    case RequestKind::WeChatStatus:
        if (status == 202 || payload.value("status").toString() == QStringLiteral("pending"))
            break;
        m_weChatPollTimer.stop();
        m_weChatTransaction.clear();
        applySession(payload);
        break;
    case RequestKind::Login:
        applySession(payload);
        break;
    case RequestKind::Register:
        if (field(payload, "access_token", "accessToken").isEmpty()
            && payload.value("verification_required").toBool()) {
            setBusy(false);
            setInfo(QStringLiteral("验证邮件已发送，完成验证后即可登录"));
            break;
        }
        applySession(payload);
        break;
    case RequestKind::PhoneVerify:
    case RequestKind::Refresh:
        applySession(payload);
        break;
    case RequestKind::Logout:
        setBusy(false);
        setInfo(QStringLiteral("已安全退出"));
        break;
    default:
        setBusy(false);
        break;
    }
}

void AuthManager::applySession(const QVariantMap &payload)
{
    const QString accessToken = field(payload, "access_token", "accessToken");
    const QString refreshToken = field(payload, "refresh_token", "refreshToken");
    QVariantMap user = payload.value("user").toMap();
    if (user.isEmpty())
        user = payload.value("profile").toMap();
    user = normalizedUser(user);
    if (accessToken.isEmpty() || refreshToken.isEmpty() || user.value("id").toString().isEmpty()) {
        setBusy(false);
        setError(QStringLiteral("登录响应不完整，请联系管理员"));
        return;
    }
    if (!m_secureStore || !m_secureStore->writeSecret(kRefreshTokenKey, refreshToken)) {
        setBusy(false);
        setError(QStringLiteral("无法安全保存登录状态，请检查 Windows 凭据服务"));
        return;
    }

    const bool wasAuthenticated = m_authenticated;
    const bool hadSavedSession = m_hasSavedSession;
    m_accessToken = accessToken;
    m_profile = user;
    m_authenticated = true;
    m_hasSavedSession = true;
    setBusy(false);
    setInfo(QStringLiteral("登录成功，数据将在此账户下持续保存"));
    if (!wasAuthenticated)
        emit authenticatedChanged();
    if (!hadSavedSession)
        emit hasSavedSessionChanged();
    emit profileChanged();
    emit accountChanged(userId());
}

void AuthManager::clearSession(bool clearProfile)
{
    if (m_secureStore)
        m_secureStore->removeSecret(kRefreshTokenKey);
    const bool wasAuthenticated = m_authenticated;
    const bool hadSavedSession = m_hasSavedSession;
    m_authenticated = false;
    m_hasSavedSession = false;
    m_accessToken.clear();
    if (clearProfile) {
        m_profile.clear();
        emit profileChanged();
    }
    if (wasAuthenticated)
        emit authenticatedChanged();
    if (hadSavedSession)
        emit hasSavedSessionChanged();
    emit accountChanged(QStringLiteral("local"));
}

void AuthManager::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged();
}

void AuthManager::setError(const QString &message)
{
    m_errorMessage = message;
    m_infoMessage.clear();
    emit messageChanged();
}

void AuthManager::setInfo(const QString &message)
{
    m_infoMessage = message;
    m_errorMessage.clear();
    emit messageChanged();
}

QVariantMap AuthManager::normalizedUser(const QVariantMap &user) const
{
    return {{"id", field(user, "id", "userId")},
            {"displayName", field(user, "display_name", "displayName")},
            {"email", user.value("email").toString()},
            {"phone", user.value("phone").toString()},
            {"avatarUrl", field(user, "avatar_url", "avatarUrl")},
            {"provider", user.value("provider", QStringLiteral("password")).toString()}};
}

QString AuthManager::endpoint(const QString &path) const
{
    return m_baseUrl + (path.startsWith('/') ? path : QStringLiteral("/") + path);
}

QString AuthManager::friendlyError(int status, const QVariantMap &payload) const
{
    QVariant error = payload.value("error");
    QString message;
    if (error.metaType().id() == QMetaType::QVariantMap)
        message = error.toMap().value("message").toString();
    else
        message = error.toString();
    if (message.isEmpty())
        message = payload.value("message").toString();
    if (!message.isEmpty())
        return message.left(180);
    switch (status) {
    case 400: return QStringLiteral("提交的信息有误，请检查后重试");
    case 401: return QStringLiteral("账号或凭据不正确");
    case 403: return QStringLiteral("当前账号暂时无法执行此操作");
    case 409: return QStringLiteral("该账号已注册，可以直接登录");
    case 429: return QStringLiteral("操作过于频繁，请稍后再试");
    default: return QStringLiteral("账号服务暂时不可用，请稍后重试");
    }
}

bool AuthManager::validIdentifier(const QString &value)
{
    static const QRegularExpression emailPattern(
        QStringLiteral(R"(^[^\s@]+@[^\s@]+\.[^\s@]+$)"),
        QRegularExpression::CaseInsensitiveOption);
    return emailPattern.match(value).hasMatch() || validPhone(value);
}

bool AuthManager::validPhone(const QString &value)
{
    static const QRegularExpression phonePattern(QStringLiteral(R"(^\+?[0-9][0-9\s-]{7,18}$)"));
    return phonePattern.match(value).hasMatch();
}
