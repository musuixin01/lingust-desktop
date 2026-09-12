#include "WindowsOcrProvider.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>
#include <QUuid>
#include <QtConcurrent>

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

WindowsOcrProvider::WindowsOcrProvider(QObject *parent)
    : IOcrProvider(parent)
{
}

QString WindowsOcrProvider::bridgePath() const
{
    const QString appPath = QDir(QCoreApplication::applicationDirPath()).filePath("SystemOcrBridge.ps1");
    if (QFileInfo::exists(appPath))
        return appPath;
    return QDir(QCoreApplication::applicationDirPath())
        .absoluteFilePath("../../../platform/windows/ocr/SystemOcrBridge.ps1");
}

void WindowsOcrProvider::recognize(const QImage &image, const QString &language)
{
    if (image.isNull()) {
        emit recognitionError(QStringLiteral("没有截取到有效图像"));
        return;
    }
    if (!QFileInfo::exists(bridgePath())) {
        emit recognitionError(QStringLiteral("Windows OCR 组件缺失"));
        return;
    }

    const QString path = QDir(QStandardPaths::writableLocation(QStandardPaths::TempLocation))
        .filePath("lingust-ocr-" + QUuid::createUuid().toString(QUuid::WithoutBraces) + ".png");
    auto *watcher = new QFutureWatcher<bool>(this);
    connect(watcher, &QFutureWatcher<bool>::finished, this, [this, watcher, path, language] {
        const bool saved = watcher->result();
        watcher->deleteLater();
        if (!saved) {
            emit recognitionError(QStringLiteral("无法准备截图识别文件"));
            return;
        }
        launchBridge(path, language);
    });
    watcher->setFuture(QtConcurrent::run([image, path] { return image.save(path, "PNG"); }));
}

void WindowsOcrProvider::launchBridge(const QString &imagePath, const QString &language)
{
    auto *process = new QProcess(this);
    hideProcessWindow(process);
    process->setProgram("powershell.exe");
    QString languageTag;
    if (language.compare(QStringLiteral("en"), Qt::CaseInsensitive) == 0)
        languageTag = QStringLiteral("en-US");
    else if (language.compare(QStringLiteral("zh"), Qt::CaseInsensitive) == 0)
        languageTag = QStringLiteral("zh-Hans");
    QStringList arguments{"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
                          "-File", QDir::toNativeSeparators(bridgePath()),
                          "-ImagePath", QDir::toNativeSeparators(imagePath)};
    if (!languageTag.isEmpty())
        arguments.append({QStringLiteral("-LanguageTag"), languageTag});
    process->setArguments(arguments);
    connect(process, &QProcess::finished, this,
            [this, process, imagePath](int exitCode, QProcess::ExitStatus exitStatus) {
        const QByteArray output = process->readAllStandardOutput().trimmed();
        const QString processError = QString::fromLocal8Bit(process->readAllStandardError()).trimmed();
        QFile::remove(imagePath);
        process->deleteLater();

        QJsonParseError parseError;
        const QJsonDocument document = QJsonDocument::fromJson(output, &parseError);
        if (exitStatus != QProcess::NormalExit || exitCode != 0 ||
            parseError.error != QJsonParseError::NoError || !document.isObject()) {
            emit recognitionError(processError.isEmpty()
                ? QStringLiteral("Windows OCR 识别失败") : processError);
            return;
        }
        const QJsonObject result = document.object();
        const QString text = result.value("text").toString().trimmed();
        if (!result.value("ok").toBool() || text.isEmpty()) {
            emit recognitionError(result.value("error").toString(
                QStringLiteral("选区中没有识别到文字")));
            return;
        }
        emit recognitionReady(text);
    });
    process->start();
}
