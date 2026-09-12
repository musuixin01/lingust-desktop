#include "Application.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlError>
#include <QQuickWindow>
#include <QQuickItem>
#include <QTimer>
#include <cstdio>

#include "core/state/AppState.h"
#include "core/window/TranslatorWindow.h"
#ifdef Q_OS_WIN
#include "platform/windows/window/WindowsResizeSession.h"
#endif
#include "core/window/TrayManager.h"
#include "platform/windows/hotkey/HotkeyManager.h"
#include "platform/windows/mousehook/MouseHookManager.h"
#include "platform/windows/media/WindowsMediaManager.h"
#include "core/capture/CaptureManager.h"
#include "core/ocr/OcrManager.h"
#include "platform/windows/ocr/WindowsOcrProvider.h"

Application::Application(QObject *parent)
    : QObject(parent)
{
}

Application::~Application() = default;

int Application::run()
{
    // The translator and capture overlay intentionally hand visibility to each
    // other. Keep the tray process alive during the short interval with no window.
    QGuiApplication::setQuitOnLastWindowClosed(false);

    m_appState = std::make_unique<AppState>();
    m_window = std::make_unique<TranslatorWindow>();
#ifdef Q_OS_WIN
    m_window->setResizeSession(std::make_unique<WindowsResizeSession>());
#endif
    m_tray = std::make_unique<TrayManager>();
    m_hotkey = std::make_unique<HotkeyManager>();
    m_mouseHook = std::make_unique<MouseHookManager>();
    m_windowsMedia = std::make_unique<WindowsMediaManager>();
    m_captureManager = std::make_unique<CaptureManager>();
    m_ocrManager = std::make_unique<OcrManager>();
    m_windowsOcr = std::make_unique<WindowsOcrProvider>();
    m_ocrManager->setProvider(m_windowsOcr.get());

    QObject::connect(m_appState.get(), &AppState::textCleared,
                     m_window.get(), &TranslatorWindow::resetCardToDefault);

    QObject::connect(m_captureManager.get(), &CaptureManager::screenshotCaptured,
                     m_appState.get(), [this](const QImage &image) {
        m_appState->beginScreenshotTranslation(m_captureManager->selectionPreviewUrl());
        m_ocrManager->recognize(image, m_appState->sourceLang());
    });
    QObject::connect(m_captureManager.get(), &CaptureManager::captureFailed,
                     m_appState.get(), &AppState::setOcrError);
    QObject::connect(m_ocrManager.get(), &OcrManager::recognitionReady,
                     m_appState.get(), &AppState::submitOcrText);
    QObject::connect(m_ocrManager.get(), &OcrManager::recognitionError,
                     m_appState.get(), &AppState::setOcrError);

    QObject::connect(m_windowsMedia.get(), &WindowsMediaManager::snapshotChanged,
                     m_appState.get(), &AppState::updateSystemMediaSession);
    QObject::connect(m_appState.get(), &AppState::musicToggleRequested,
                     m_windowsMedia.get(), &WindowsMediaManager::sendToggle);
    QObject::connect(m_appState.get(), &AppState::musicNextRequested,
                     m_windowsMedia.get(), &WindowsMediaManager::sendNext);
    QObject::connect(m_appState.get(), &AppState::musicPreviousRequested,
                     m_windowsMedia.get(), &WindowsMediaManager::sendPrevious);
    QObject::connect(m_appState.get(), &AppState::musicSeekRequested,
                     m_windowsMedia.get(), &WindowsMediaManager::sendSeek);
    m_windowsMedia->start();

    m_engine = std::make_unique<QQmlApplicationEngine>();
    m_engine->rootContext()->setContextProperty("appState", m_appState.get());
    m_engine->rootContext()->setContextProperty("translatorWindow", m_window.get());
    m_engine->rootContext()->setContextProperty("trayManager", m_tray.get());
    m_engine->rootContext()->setContextProperty("captureManager", m_captureManager.get());

    QObject::connect(
        m_engine.get(), &QQmlApplicationEngine::objectCreationFailed,
        QGuiApplication::instance(), []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    // 手动注册 DesignTokens 为 QML 单例（QTP0004 自动生成 qmldir 漏识别 pragma Singleton）
    qmlRegisterSingletonType(
        QUrl("qrc:/qt/qml/Linguist/ui/components/DesignTokens.qml"),
        "Linguist", 1, 0, "DesignTokens"
    );

    // 托盘菜单信号连接
    QObject::connect(m_tray.get(), &TrayManager::showRequested,
                     m_window.get(), &TranslatorWindow::restoreFromTaskbar);
    QObject::connect(m_tray.get(), &TrayManager::hideRequested, m_window.get(), &TranslatorWindow::hide);
    QObject::connect(m_tray.get(), &TrayManager::quitRequested, QGuiApplication::instance(), &QGuiApplication::quit);
    QObject::connect(m_tray.get(), &TrayManager::screenshotRequested,
                     m_appState.get(), &AppState::requestScreenshot);

    // 全局快捷键
    // Ctrl+Shift+T: 划词翻译
    m_hotkey->registerHotkey(1, Qt::Key_T, Qt::ControlModifier | Qt::ShiftModifier);
    // Ctrl+Shift+S: 截图翻译
    m_hotkey->registerHotkey(2, Qt::Key_S, Qt::ControlModifier | Qt::ShiftModifier);
    QObject::connect(m_hotkey.get(), &HotkeyManager::hotkeyTriggered, m_appState.get(), [this](int id) {
        if (id == 1) {
            m_window->show();
            m_appState->triggerSelectionTranslation();
        } else if (id == 2) {
            m_appState->requestScreenshot();
        }
    });

    // 全局鼠标 Hook：选中文字后自动翻译
    m_mouseHook->setDelay(300);
    QObject::connect(m_mouseHook.get(), &MouseHookManager::selectionFinished, m_appState.get(), [this]() {
        if (m_appState->selectionTranslation()) {
            m_window->show();
            m_appState->triggerSelectionTranslation();
        }
    });
    m_mouseHook->setEnabled(m_appState->selectionTranslation());

    // 监听设置变化，动态启用/禁用鼠标 Hook
    QObject::connect(m_appState.get(), &AppState::selectionTranslationChanged, m_mouseHook.get(), [this]() {
        m_mouseHook->setEnabled(m_appState->selectionTranslation());
    });

    // 加载主 QML 到 TranslatorWindow
    fprintf(stderr, "[DEBUG] Loading QML module...\n");
    fflush(stderr);

    QObject::connect(
        m_engine.get(), &QQmlApplicationEngine::warnings,
        [](const QList<QQmlError> &warnings) {
            for (const auto &w : warnings) {
                fprintf(stderr, "[QML WARNING] %s\n", w.toString().toUtf8().constData());
            }
        });

    m_engine->loadFromModule("Linguist", "Main");

    fprintf(stderr, "[DEBUG] QML load called, rootObjects count: %d\n", m_engine->rootObjects().size());
    fflush(stderr);

    auto rootObjects = m_engine->rootObjects();
    if (!rootObjects.isEmpty()) {
        if (auto *item = qobject_cast<QQuickItem *>(rootObjects.first())) {
            fprintf(stderr, "[DEBUG] Setting content item...\n");
            fflush(stderr);
            m_window->setContentItem(item);
        }
    } else {
        fprintf(stderr, "[ERROR] No root objects created! QML load failed.\n");
        fflush(stderr);
    }

    m_window->show();
    // Qt can finalize the HWND procedure while showing the window. Reattach
    // the platform input/resize session after that native transition.
    QTimer::singleShot(0, m_window.get(), &TranslatorWindow::refreshNativeSession);
    QTimer::singleShot(120, m_window.get(), &TranslatorWindow::refreshNativeSession);
    m_tray->show();
    return QGuiApplication::exec();
}
