import QtQuick
import QtTest

TestCase {
    name: "AccountPanel"
    width: 440
    height: 620
    visible: true
    when: windowShown

    QtObject {
        id: authFixture
        property bool configured: true
        property bool authenticated: false
        property bool busy: false
        property bool hasSavedSession: false
        property string userId: ""
        property string displayName: ""
        property string email: ""
        property string phone: ""
        property string avatarUrl: ""
        property string provider: ""
        property string errorMessage: ""
        property string infoMessage: ""
        property int otpCooldown: 0
        property int loginCalls: 0
        property int registerCalls: 0
        property int codeCalls: 0
        property int verifyCalls: 0
        property int wechatCalls: 0
        property int logoutCalls: 0
        property int resetCalls: 0
        function clearMessages() { errorMessage = ""; infoMessage = "" }
        function loginWithPassword(identifier, password) { loginCalls += 1 }
        function registerWithPassword(identifier, password, name) { registerCalls += 1 }
        function requestPhoneCode(phoneValue, registering) { codeCalls += 1 }
        function verifyPhoneCode(phoneValue, code, name, registering) { verifyCalls += 1 }
        function startWeChatLogin() { wechatCalls += 1 }
        function logout() { logoutCalls += 1 }
        function requestPasswordReset(emailValue) { resetCalls += 1 }
    }

    AccountPanel { id: panel; width: 400; auth: authFixture }

    function init() {
        panel.expanded = false
        panel.registerMode = false
        panel.method = "email"
        authFixture.authenticated = false
        authFixture.loginCalls = 0
        authFixture.registerCalls = 0
        authFixture.codeCalls = 0
        authFixture.verifyCalls = 0
        authFixture.wechatCalls = 0
        authFixture.logoutCalls = 0
        authFixture.resetCalls = 0
        panel.resetSensitiveFields()
        var account = findChild(panel, "accountIdentifierField")
        var name = findChild(panel, "accountNameField")
        account.text = ""
        name.text = ""
    }

    function test_startsCollapsedInsideSettings() {
        verify(!panel.expanded)
        verify(panel.implicitHeight < 100)
    }

    function test_emailLoginSubmitsValidCredentials() {
        mouseClick(findChild(panel, "accountExpandButton"))
        verify(panel.expanded)
        findChild(panel, "accountIdentifierField").text = "user@example.com"
        findChild(panel, "accountPasswordField").text = "correct-password"
        mouseClick(findChild(panel, "accountSubmitButton"))
        compare(authFixture.loginCalls, 1)
    }

    function test_invalidEmailStaysInline() {
        panel.expanded = true
        findChild(panel, "accountIdentifierField").text = "invalid"
        findChild(panel, "accountPasswordField").text = "correct-password"
        mouseClick(findChild(panel, "accountSubmitButton"))
        compare(authFixture.loginCalls, 0)
        verify(panel.accountTouched)
    }

    function test_passwordResetRequiresValidEmail() {
        panel.expanded = true
        findChild(panel, "accountIdentifierField").text = "user@example.com"
        mouseClick(findChild(panel, "accountPasswordResetButton"))
        compare(authFixture.resetCalls, 1)
    }

    function test_phoneCodeAndVerification() {
        panel.expanded = true
        panel.method = "phone"
        findChild(panel, "accountIdentifierField").text = "+8613812345678"
        var code = findChild(panel, "accountCodeField")
        code.text = "123456"
        panel.submit()
        compare(authFixture.verifyCalls, 1)
    }

    function test_wechatAndAuthenticatedCollapse() {
        panel.expanded = true
        mouseClick(findChild(panel, "wechatLoginButton"))
        compare(authFixture.wechatCalls, 1)
        authFixture.authenticated = true
        tryCompare(panel, "expanded", false, 300)
    }
}
