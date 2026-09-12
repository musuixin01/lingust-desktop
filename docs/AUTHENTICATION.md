# 账户与认证架构

> 版本：v0.2.0-dev  
> 更新日期：2026-09-13

## 当前交付边界

桌面端账户功能已经完成：登录和注册只显示在设置窗口；支持邮箱密码、手机号验证码、微信扫码三种入口；刷新令牌保存到 Windows 凭据管理器；应用重启后自动刷新会话；退出时立即清除本机令牌；历史记录和收藏按账户 ID 隔离并继续保存在 SQLite。

真实邮箱、短信和微信登录需要部署认证服务并配置供应商凭据。桌面程序不内置服务端密钥，也不会用本地模拟账号冒充在线账号。设置 `LINGUIST_AUTH_BASE_URL=https://accounts.example.com` 后，桌面端才启用真实提交。跨设备云同步尚未实现，当前“长期保存”指当前 Windows 用户目录中的账户隔离数据；卸载程序默认不会清除该目录。

## 架构决定

```text
SettingsView / AccountPanel (QML)
              ↓ 仅调用语义方法
AuthManager (Core, HTTPS JSON、会话状态、请求校验)
              ↓                     ↓
认证服务 API                    ISecureCredentialStore
              ↓                     ↓
PostgreSQL / Redis / Provider    Windows Credential Manager
              ↓
邮件 / 短信 / 微信开放平台
```

- 桌面端属于公开客户端，不能保存数据库密码、短信密钥、微信 AppSecret 或 JWT 签名密钥。
- 访问令牌只保存在进程内存；可撤销的刷新令牌由 `WindowsCredentialStore` 调用 CredWrite/CredRead/CredDelete 保存。
- 邮箱、手机号和用户资料不写入普通设置文件；重启后由刷新接口重新取得。
- 所有正式认证接口必须使用 HTTPS。仅自动化测试可同时设置 `LINGUIST_AUTH_ALLOW_INSECURE_LOCALHOST=1` 使用本机 HTTP。
- 邮箱密码只通过 TLS 发送给认证服务，服务端应使用 Argon2id 保存密码摘要并完成邮箱验证、撞库防护和速率限制。
- 微信扫码由服务端生成授权地址并保管 AppSecret；桌面端使用系统浏览器完成授权，再轮询一次性事务，不嵌入网页，也不接触微信密钥。
- 服务端以随机且不可推测的用户 ID 作为数据归属键。客户端不会使用邮箱或手机号作为数据库主键。

Qt 官方建议原生桌面授权使用外部浏览器、PKCE 和随机 state；Windows Credential Manager 提供与当前 Windows 登录会话关联的凭据集。安全原则参考 [Qt Network Authorization 安全说明](https://doc.qt.io/qt-6/qtnetworkauth-security.html)、[Microsoft CredWriteW](https://learn.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credwritew) 与 [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)。

## 认证服务建议拓扑

- API：无状态 HTTPS 服务，支持水平扩容；反向代理负责 TLS、请求大小限制和基础限流。
- PostgreSQL：用户、身份绑定、刷新会话、审计事件的事实来源。
- Redis：验证码、微信一次性事务、分布式速率限制和短期风控状态；验证码只保存带过期时间的摘要。
- 异步队列：发送邮件和短信，避免第三方延迟阻塞登录接口。
- Provider 适配器：EmailProvider、SmsProvider、WeChatProvider；业务层不依赖具体供应商 SDK。
- 可观测性：请求 ID、匿名化安全事件、失败率和延迟；日志不得记录密码、验证码、访问令牌或刷新令牌。

## 会话与数据生命周期

1. 登录成功返回短期访问令牌、轮换刷新令牌和用户资料。
2. `AuthManager` 先把刷新令牌写入 Windows 凭据管理器，成功后才宣布登录完成。
3. 重启时使用刷新令牌换取新令牌；临时断网保留已保存会话，401/403 才清除失效凭据。
4. 退出时先清除本机凭据和账户状态，再尽力通知服务端撤销会话，保证离线时也能退出本机。
5. `DatabaseManager.owner_id` 将历史和收藏分为 `local` 与服务端用户 ID 命名空间，切换账号不会互相看到数据。

## 上线前必须完成

- 部署认证服务并将正式 HTTPS 地址写入发布环境。
- 配置邮件域名、退信处理、短信签名/模板和微信网站应用审核信息。
- 服务端实现 Argon2id、刷新令牌轮换与重用检测、验证码次数/频率限制、通用错误提示和安全审计。
- 补充隐私政策、用户协议、账号注销、数据导出与删除流程。
- 完成跨设备数据同步协议后，才能在界面中宣传“云同步”。
- 对真实邮件、短信、微信回调、弱网、时钟偏差、会话撤销和多设备退出做预发布验收。
