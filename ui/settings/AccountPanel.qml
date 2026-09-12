import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Linguist

Rectangle {
    id: accountPanel
    objectName: "accountPanel"
    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight + 24
    radius: 16
    color: "#16ffffff"
    border.color: expanded ? "#526aa7ff" : DesignTokens.borderSubtle
    border.width: 1

    property var auth: typeof authManager !== "undefined" ? authManager : null
    property bool expanded: false
    property bool registerMode: false
    property string method: "email"
    property bool accountTouched: false
    property bool passwordTouched: false
    property bool confirmTouched: false
    property bool nameTouched: false

    readonly property bool signedIn: auth && auth.authenticated
    readonly property bool serviceReady: auth && auth.configured
    readonly property color fieldBorder: "#30ffffff"

    Behavior on implicitHeight { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

    function resetSensitiveFields() {
        passwordField.text = ""
        confirmField.text = ""
        codeField.text = ""
    }

    function submit() {
        if (!auth || auth.busy)
            return
        auth.clearMessages()
        if (method === "phone") {
            accountTouched = true
            nameTouched = registerMode
            if (!phoneValid() || (registerMode && !nameValid()) || codeField.text.trim().length < 4)
                return
            auth.verifyPhoneCode(accountField.text, codeField.text, nameField.text, registerMode)
            return
        }
        accountTouched = true
        passwordTouched = true
        nameTouched = registerMode
        confirmTouched = registerMode
        if (!accountValid() || !passwordValid() || (registerMode && (!nameValid() || !confirmValid())))
            return
        if (registerMode)
            auth.registerWithPassword(accountField.text, passwordField.text, nameField.text)
        else
            auth.loginWithPassword(accountField.text, passwordField.text)
    }

    function accountValid() {
        var value = accountField.text.trim()
        if (method === "phone") return phoneValid()
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
    }
    function phoneValid() { return /^\+?[0-9][0-9\s-]{7,18}$/.test(accountField.text.trim()) }
    function passwordValid() { return passwordField.text.length >= 8 }
    function confirmValid() { return confirmField.text === passwordField.text && confirmField.text.length >= 8 }
    function nameValid() { return nameField.text.trim().length >= 2 }

    ColumnLayout {
        id: contentColumn
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 38; height: 38; radius: 12
                color: accountPanel.signedIn ? "#2434d399" : "#263b82f6"
                border.color: accountPanel.signedIn ? "#5534d399" : "#4d60a5fa"
                Image {
                    anchors.centerIn: parent
                    source: accountPanel.signedIn
                            ? "qrc:/qt/qml/Linguist/resources/icons/shield-check.svg"
                            : "qrc:/qt/qml/Linguist/resources/icons/user.svg"
                    sourceSize.width: 18; sourceSize.height: 18
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: accountPanel.signedIn
                          ? (accountPanel.auth.displayName || "Linguist 用户")
                          : "Linguist 账户"
                    color: DesignTokens.textPrimary
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: accountPanel.signedIn
                          ? (accountPanel.auth.email || accountPanel.auth.phone || "已安全登录")
                          : "长期保存词库、收藏与使用偏好"
                    color: DesignTokens.textTertiary
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                visible: !accountPanel.signedIn
                width: loginLabel.implicitWidth + 20; height: 30; radius: 10
                color: openArea.pressed ? "#4d60a5fa" : openArea.containsMouse ? "#3d3b82f6" : "#2b3b82f6"
                border.color: "#596aa7ff"
                Text {
                    id: loginLabel
                    anchors.centerIn: parent
                    text: accountPanel.expanded ? "收起" : "登录 / 注册"
                    color: "#f7faff"; font.pixelSize: 11; font.weight: Font.DemiBold
                }
                MouseArea {
                    id: openArea
                    objectName: "accountExpandButton"
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        accountPanel.expanded = !accountPanel.expanded
                        if (accountPanel.auth) accountPanel.auth.clearMessages()
                        if (!accountPanel.expanded) accountPanel.resetSensitiveFields()
                    }
                }
            }

            Rectangle {
                visible: accountPanel.signedIn
                width: 31; height: 31; radius: 10
                color: logoutArea.pressed ? "#32ef4444" : logoutArea.containsMouse ? "#22ffffff" : "#10ffffff"
                border.color: DesignTokens.borderSubtle
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/qt/qml/Linguist/resources/icons/log-out.svg"
                    sourceSize.width: 14; sourceSize.height: 14
                    opacity: 0.8
                }
                MouseArea {
                    id: logoutArea
                    objectName: "accountLogoutButton"
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (accountPanel.auth) accountPanel.auth.logout()
                }
            }
        }

        RowLayout {
            visible: accountPanel.signedIn
            Layout.fillWidth: true
            spacing: 6
            Rectangle { width: 6; height: 6; radius: 3; color: "#34d399" }
            Text {
                text: "登录状态已安全保存 · 本机数据按账户隔离"
                color: "#9de7cd"; font.pixelSize: 10; Layout.fillWidth: true
            }
        }

        ColumnLayout {
            visible: accountPanel.expanded && !accountPanel.signedIn
            Layout.fillWidth: true
            spacing: 10
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: [
                        { key: "login", label: "登录" },
                        { key: "register", label: "注册" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 30; radius: 9
                        readonly property bool selected: accountPanel.registerMode === (modelData.key === "register")
                        color: selected ? "#26ffffff" : "transparent"
                        border.color: selected ? "#38ffffff" : "transparent"
                        Text {
                            anchors.centerIn: parent; text: parent.modelData.label
                            color: parent.selected ? DesignTokens.textPrimary : DesignTokens.textTertiary
                            font.pixelSize: 11; font.weight: parent.selected ? Font.DemiBold : Font.Normal
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                accountPanel.registerMode = parent.modelData.key === "register"
                                accountPanel.resetSensitiveFields()
                                if (accountPanel.auth) accountPanel.auth.clearMessages()
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [
                        { key: "email", label: "邮箱", icon: "mail.svg" },
                        { key: "phone", label: "手机号", icon: "smartphone.svg" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 32; radius: 10
                        readonly property bool selected: accountPanel.method === modelData.key
                        color: selected ? "#273b82f6" : "#0bffffff"
                        border.color: selected ? "#526aa7ff" : DesignTokens.borderSubtle
                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Image {
                                source: "qrc:/qt/qml/Linguist/resources/icons/" + parent.parent.modelData.icon
                                width: 13; height: 13; opacity: parent.parent.selected ? 0.95 : 0.58
                            }
                            Text {
                                text: parent.parent.modelData.label
                                color: parent.parent.selected ? DesignTokens.textPrimary : DesignTokens.textTertiary
                                font.pixelSize: 10
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                accountPanel.method = parent.modelData.key
                                accountField.text = ""
                                accountPanel.resetSensitiveFields()
                                accountPanel.accountTouched = false
                                if (accountPanel.auth) accountPanel.auth.clearMessages()
                            }
                        }
                    }
                }
            }

            TextField {
                id: nameField
                objectName: "accountNameField"
                visible: accountPanel.registerMode
                Layout.fillWidth: true; implicitHeight: 38
                placeholderText: "昵称"
                color: DesignTokens.textPrimary; placeholderTextColor: DesignTokens.textTertiary
                font.pixelSize: 11; selectByMouse: true
                onActiveFocusChanged: if (!activeFocus) accountPanel.nameTouched = true
                background: Rectangle {
                    radius: 11; color: "#14ffffff"
                    border.color: accountPanel.nameTouched && !accountPanel.nameValid() ? "#d96b7a" : nameField.activeFocus ? "#6aa7ff" : accountPanel.fieldBorder
                }
            }

            TextField {
                id: accountField
                objectName: "accountIdentifierField"
                Layout.fillWidth: true; implicitHeight: 38
                placeholderText: accountPanel.method === "email" ? "邮箱地址" : "+86 手机号"
                inputMethodHints: accountPanel.method === "email" ? Qt.ImhEmailCharactersOnly : Qt.ImhDialableCharactersOnly
                color: DesignTokens.textPrimary; placeholderTextColor: DesignTokens.textTertiary
                font.pixelSize: 11; selectByMouse: true
                onActiveFocusChanged: if (!activeFocus) accountPanel.accountTouched = true
                background: Rectangle {
                    radius: 11; color: "#14ffffff"
                    border.color: accountPanel.accountTouched && !accountPanel.accountValid() ? "#d96b7a" : accountField.activeFocus ? "#6aa7ff" : accountPanel.fieldBorder
                }
            }

            RowLayout {
                visible: accountPanel.method === "phone"
                Layout.fillWidth: true
                spacing: 7
                TextField {
                    id: codeField
                    objectName: "accountCodeField"
                    Layout.fillWidth: true; implicitHeight: 38
                    placeholderText: "短信验证码"
                    inputMethodHints: Qt.ImhDigitsOnly
                    maximumLength: 8
                    color: DesignTokens.textPrimary; placeholderTextColor: DesignTokens.textTertiary
                    font.pixelSize: 11; selectByMouse: true
                    background: Rectangle { radius: 11; color: "#14ffffff"; border.color: codeField.activeFocus ? "#6aa7ff" : accountPanel.fieldBorder }
                    Keys.onReturnPressed: accountPanel.submit()
                }
                Rectangle {
                    width: 94; height: 38; radius: 11
                    enabled: accountPanel.auth && !accountPanel.auth.busy && accountPanel.auth.otpCooldown === 0
                    opacity: enabled ? 1 : 0.48
                    color: codeArea.pressed ? "#34ffffff" : codeArea.containsMouse ? "#25ffffff" : "#17ffffff"
                    border.color: DesignTokens.borderSubtle
                    Text {
                        anchors.centerIn: parent
                        text: accountPanel.auth && accountPanel.auth.otpCooldown > 0
                              ? accountPanel.auth.otpCooldown + " 秒"
                              : "发送验证码"
                        color: DesignTokens.textSecondary; font.pixelSize: 10
                    }
                    MouseArea {
                        id: codeArea
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (parent.enabled) {
                            accountPanel.accountTouched = true
                            if (accountPanel.phoneValid()) accountPanel.auth.requestPhoneCode(accountField.text, accountPanel.registerMode)
                        }
                    }
                }
            }

            TextField {
                id: passwordField
                objectName: "accountPasswordField"
                visible: accountPanel.method === "email"
                Layout.fillWidth: true; implicitHeight: 38
                placeholderText: accountPanel.registerMode ? "密码，至少 8 个字符" : "密码"
                echoMode: TextInput.Password
                color: DesignTokens.textPrimary; placeholderTextColor: DesignTokens.textTertiary
                font.pixelSize: 11; selectByMouse: true
                onActiveFocusChanged: if (!activeFocus) accountPanel.passwordTouched = true
                background: Rectangle {
                    radius: 11; color: "#14ffffff"
                    border.color: accountPanel.passwordTouched && !accountPanel.passwordValid() ? "#d96b7a" : passwordField.activeFocus ? "#6aa7ff" : accountPanel.fieldBorder
                }
                Keys.onReturnPressed: if (!accountPanel.registerMode) accountPanel.submit()
            }

            TextField {
                id: confirmField
                objectName: "accountConfirmField"
                visible: accountPanel.method === "email" && accountPanel.registerMode
                Layout.fillWidth: true; implicitHeight: 38
                placeholderText: "再次输入密码"
                echoMode: TextInput.Password
                color: DesignTokens.textPrimary; placeholderTextColor: DesignTokens.textTertiary
                font.pixelSize: 11; selectByMouse: true
                onActiveFocusChanged: if (!activeFocus) accountPanel.confirmTouched = true
                background: Rectangle {
                    radius: 11; color: "#14ffffff"
                    border.color: accountPanel.confirmTouched && !accountPanel.confirmValid() ? "#d96b7a" : confirmField.activeFocus ? "#6aa7ff" : accountPanel.fieldBorder
                }
                Keys.onReturnPressed: accountPanel.submit()
            }

            Text {
                visible: accountPanel.method === "email" && !accountPanel.registerMode
                Layout.alignment: Qt.AlignRight
                text: "忘记密码？"
                color: resetArea.containsMouse ? "#b8d5ff" : "#8bbcff"
                font.pixelSize: 10
                MouseArea {
                    id: resetArea
                    objectName: "accountPasswordResetButton"
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (accountPanel.auth) {
                        accountPanel.accountTouched = true
                        if (accountPanel.accountValid())
                            accountPanel.auth.requestPasswordReset(accountField.text)
                    }
                }
            }

            Text {
                visible: accountPanel.auth && (accountPanel.auth.errorMessage.length > 0 || accountPanel.auth.infoMessage.length > 0)
                Layout.fillWidth: true
                text: accountPanel.auth ? (accountPanel.auth.errorMessage || accountPanel.auth.infoMessage) : ""
                textFormat: Text.PlainText
                color: accountPanel.auth && accountPanel.auth.errorMessage.length > 0 ? "#f3a6b0" : "#9de7cd"
                font.pixelSize: 10; wrapMode: Text.Wrap
            }

            Rectangle {
                objectName: "accountSubmitButton"
                Layout.fillWidth: true; height: 39; radius: 12
                enabled: accountPanel.auth && !accountPanel.auth.busy
                opacity: enabled ? 1 : 0.5
                color: submitArea.pressed ? "#5575b8ff" : submitArea.containsMouse ? "#466aa7ff" : "#386aa7ff"
                border.color: "#667ab7ff"
                Row {
                    anchors.centerIn: parent; spacing: 7
                    BusyIndicator {
                        visible: accountPanel.auth && accountPanel.auth.busy
                        running: visible; width: 15; height: 15
                    }
                    Text {
                        text: accountPanel.auth && accountPanel.auth.busy
                              ? "正在安全连接…"
                              : accountPanel.registerMode ? "创建账户" : "登录"
                        color: "white"; font.pixelSize: 11; font.weight: Font.DemiBold
                    }
                }
                MouseArea {
                    id: submitArea
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: if (parent.enabled) accountPanel.submit()
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Rectangle { Layout.fillWidth: true; height: 1; color: DesignTokens.borderSubtle }
                Text { text: "或"; color: DesignTokens.textTertiary; font.pixelSize: 9 }
                Rectangle { Layout.fillWidth: true; height: 1; color: DesignTokens.borderSubtle }
            }

            Rectangle {
                objectName: "wechatLoginButton"
                Layout.fillWidth: true; height: 39; radius: 12
                enabled: accountPanel.auth && !accountPanel.auth.busy
                opacity: enabled ? 1 : 0.5
                color: wechatArea.pressed ? "#2f27c76f" : wechatArea.containsMouse ? "#2527c76f" : "#1427c76f"
                border.color: "#4d41d984"
                Row {
                    anchors.centerIn: parent; spacing: 7
                    Image { source: "qrc:/qt/qml/Linguist/resources/icons/message-circle.svg"; width: 15; height: 15 }
                    Text { text: "使用微信扫码登录"; color: "#d9fbe8"; font.pixelSize: 11; font.weight: Font.Medium }
                }
                MouseArea {
                    id: wechatArea
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: if (parent.enabled) accountPanel.auth.startWeChatLogin()
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: accountPanel.serviceReady
                      ? "密码不会保存在本机 · 登录状态由 Windows 安全保管"
                      : "账号服务尚未接入，管理员配置后即可使用"
                color: DesignTokens.textTertiary; font.pixelSize: 9; wrapMode: Text.Wrap
            }
        }
    }

    Connections {
        target: accountPanel.auth
        enabled: accountPanel.auth !== null
        function onAuthenticatedChanged() {
            if (accountPanel.auth.authenticated) {
                accountPanel.expanded = false
                accountPanel.resetSensitiveFields()
            }
        }
    }
}
