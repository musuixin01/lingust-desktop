#include "WindowsMediaManager.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QTimer>
#include <QDebug>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

namespace {
void hideProcessWindow(QProcess *process)
{
#ifdef Q_OS_WIN
    process->setCreateProcessArgumentsModifier([](QProcess::CreateProcessArguments *args) {
        args->flags |= CREATE_NO_WINDOW;
    });
#else
    Q_UNUSED(process)
#endif
}
}

WindowsMediaManager::WindowsMediaManager(QObject *parent)
    : QObject(parent)
    , m_watcher(new QProcess(this))
{
    hideProcessWindow(m_watcher);
    connect(m_watcher, &QProcess::readyReadStandardOutput,
            this, &WindowsMediaManager::processOutput);
    connect(m_watcher, &QProcess::readyReadStandardError, this, [this] {
        const QByteArray error = m_watcher->readAllStandardError().trimmed();
        if (!error.isEmpty())
            qWarning().noquote() << "[SystemMedia]" << QString::fromLocal8Bit(error);
    });
    connect(m_watcher, &QProcess::finished, this, [this](int, QProcess::ExitStatus) {
        if (!m_stopping)
            scheduleRestart();
    });
}

WindowsMediaManager::~WindowsMediaManager()
{
    m_stopping = true;
    if (m_watcher->state() != QProcess::NotRunning) {
        m_watcher->terminate();
        if (!m_watcher->waitForFinished(600))
            m_watcher->kill();
    }
}

bool WindowsMediaManager::isSupported() const
{
#ifdef Q_OS_WIN
    return QFileInfo::exists(bridgePath());
#else
    return false;
#endif
}

QString WindowsMediaManager::bridgePath() const
{
    const QString appPath = QDir(QCoreApplication::applicationDirPath()).filePath("SystemMediaBridge.ps1");
    if (QFileInfo::exists(appPath))
        return appPath;

    const QString sourcePath = QDir(QCoreApplication::applicationDirPath())
                                   .absoluteFilePath("../../../platform/windows/media/SystemMediaBridge.ps1");
    return QDir::cleanPath(sourcePath);
}

void WindowsMediaManager::start()
{
    if (!isSupported() || m_watcher->state() != QProcess::NotRunning)
        return;

    m_stdoutBuffer.clear();
    m_watcher->setProgram("powershell.exe");
    m_watcher->setArguments({"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
                             "-File", QDir::toNativeSeparators(bridgePath()), "-Action", "Watch"});
    m_watcher->start();
}

void WindowsMediaManager::processOutput()
{
    m_stdoutBuffer += m_watcher->readAllStandardOutput();
    while (true) {
        const qsizetype newline = m_stdoutBuffer.indexOf('\n');
        if (newline < 0)
            break;
        const QByteArray line = m_stdoutBuffer.left(newline).trimmed();
        m_stdoutBuffer.remove(0, newline + 1);
        if (line.isEmpty())
            continue;

        QJsonParseError parseError;
        const QJsonDocument document = QJsonDocument::fromJson(line, &parseError);
        if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
            qWarning() << "[SystemMedia] Invalid bridge output:" << line;
            continue;
        }
        const QJsonObject value = document.object();
        emit snapshotChanged(value.value("connected").toBool(),
                             value.value("playing").toBool(),
                             value.value("title").toString(),
                             value.value("artist").toString(),
                             value.value("album").toString(),
                             value.value("coverDataUrl").toString(),
                             value.value("durationSeconds").toInt(),
                             value.value("positionSeconds").toInt());
    }
}

void WindowsMediaManager::scheduleRestart()
{
    emit snapshotChanged(false, false, {}, {}, {}, {}, 0, 0);
    QTimer::singleShot(1800, this, [this] {
        if (!m_stopping)
            start();
    });
}

void WindowsMediaManager::launchAction(const QString &action, int positionSeconds)
{
    if (!isSupported())
        return;

    auto *process = new QProcess(this);
    hideProcessWindow(process);
    connect(process, &QProcess::finished, process, &QObject::deleteLater);
    QStringList arguments{"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
                          "-File", QDir::toNativeSeparators(bridgePath()), "-Action", action};
    if (action == "Seek")
        arguments << "-PositionSeconds" << QString::number(qMax(0, positionSeconds));
    process->start("powershell.exe", arguments);
}

void WindowsMediaManager::sendPlay() { launchAction("Play"); }
void WindowsMediaManager::sendPause() { launchAction("Pause"); }
void WindowsMediaManager::sendToggle() { launchAction("Toggle"); }
void WindowsMediaManager::sendNext() { launchAction("Next"); }
void WindowsMediaManager::sendPrevious() { launchAction("Previous"); }
void WindowsMediaManager::sendSeek(int seconds) { launchAction("Seek", seconds); }
