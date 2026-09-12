#include "core/window/TranslatorWindow.h"

#include <QGuiApplication>
#include <QInputMethodEvent>
#include <QFile>
#include <QElapsedTimer>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQuickItem>
#include <QTextStream>

int main(int argc, char *argv[])
{
    QFile report("input-method-smoke.log");
    if (!report.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) return 10;
    QTextStream output(&report);
    QGuiApplication app(argc, argv);
    QQmlEngine engine;
    QQmlComponent component(&engine);
    component.setData(R"QML(
        import QtQuick
        Item {
            width: 220; height: 80
            function prepareKeyboardFocus(localX, localY) {
                editor.forceActiveFocus(Qt.MouseFocusReason)
                return true
            }
            TextInput { id: editor; objectName: "imeEditor" }
        }
    )QML", QUrl("inmemory:/InputMethodProbe.qml"));
    QElapsedTimer loadTimer;
    loadTimer.start();
    while (component.status() == QQmlComponent::Loading && loadTimer.elapsed() < 2000)
        QCoreApplication::processEvents(QEventLoop::AllEvents, 20);

    std::unique_ptr<QObject> object(component.create());
    auto *root = qobject_cast<QQuickItem *>(object.get());
    if (!root) {
        output << "QML creation failed: " << component.errorString();
        output.flush();
        return 1;
    }

    TranslatorWindow window;
    window.setContentItem(root);
    QMetaObject::invokeMethod(root, "prepareKeyboardFocus", Qt::DirectConnection,
                              Q_ARG(QVariant, 20), Q_ARG(QVariant, 20));
    QCoreApplication::processEvents();

    QObject *editor = root->findChild<QObject *>("imeEditor");
    if (!editor || window.focusObject() != editor) {
        output << "Visible host does not expose the offscreen text focus\n";
        output.flush();
        object.release();
        return 2;
    }

    QInputMethodEvent preedit(QStringLiteral("ni"), {});
    QCoreApplication::sendEvent(&window, &preedit);
    QInputMethodEvent commit;
    commit.setCommitString(QString::fromUtf8("\xE4\xBD\xA0"));
    QCoreApplication::sendEvent(&window, &commit);
    QCoreApplication::processEvents();

    if (editor->property("text").toString() != QString::fromUtf8("\xE4\xBD\xA0")) {
        output << "IME commit did not reach the focused QML editor: ";
        output << editor->property("text").toString() << "\n";
        output.flush();
        object.release();
        return 3;
    }

    root->setParentItem(nullptr);
    object.release();
    output << "PASS: offscreen QML focus and Chinese IME commit\n";
    output.flush();
    return 0;
}
