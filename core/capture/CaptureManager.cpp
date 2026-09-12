#include "CaptureManager.h"
#include <QGuiApplication>
#include <QScreen>
#include <QPixmap>
#include <QCursor>
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QUuid>
#include <QUrl>

CaptureManager::CaptureManager(QObject *parent)
    : QObject(parent)
{
}

CaptureManager::~CaptureManager()
{
    removePreviewFiles();
}

QImage CaptureManager::captureFullScreen()
{
    QScreen *screen = QGuiApplication::screenAt(QCursor::pos());
    if (!screen)
        screen = QGuiApplication::primaryScreen();
    if (!screen) return QImage();

    QPixmap pixmap = screen->grabWindow(0);
    m_screenGeometry = screen->geometry();
    m_devicePixelRatio = qMax<qreal>(1.0, pixmap.devicePixelRatio());
    m_fullScreen = pixmap.toImage();
    return m_fullScreen;
}

QImage CaptureManager::captureScreen(const QRect &rect)
{
    if (m_fullScreen.isNull()) {
        captureFullScreen();
    }
    const QRect pixelRect(qRound(rect.x() * m_devicePixelRatio),
                          qRound(rect.y() * m_devicePixelRatio),
                          qRound(rect.width() * m_devicePixelRatio),
                          qRound(rect.height() * m_devicePixelRatio));
    return m_fullScreen.copy(pixelRect.intersected(m_fullScreen.rect()));
}

bool CaptureManager::startScreenshotMode()
{
    removePreviewFiles();
    if (captureFullScreen().isNull()) {
        emit captureFailed(QStringLiteral("无法读取当前屏幕"));
        return false;
    }

    m_previewPath = QDir(QStandardPaths::writableLocation(QStandardPaths::TempLocation))
        .filePath("lingust-capture-" + QUuid::createUuid().toString(QUuid::WithoutBraces) + ".bmp");
    if (!m_fullScreen.save(m_previewPath, "BMP")) {
        emit captureFailed(QStringLiteral("无法生成截图预览"));
        return false;
    }
    m_previewUrl = QUrl::fromLocalFile(m_previewPath).toString();
    emit capturePrepared();
    return true;
}

void CaptureManager::confirmSelection(qreal x, qreal y, qreal width, qreal height)
{
    const QRect logicalRect = QRectF(x, y, width, height).normalized().toAlignedRect();
    if (logicalRect.width() < 8 || logicalRect.height() < 8) {
        emit captureFailed(QStringLiteral("截图区域太小，请重新框选"));
        return;
    }
    const QImage selected = captureScreen(logicalRect);
    if (selected.isNull()) {
        emit captureFailed(QStringLiteral("无法裁剪所选区域"));
        return;
    }

    m_selectionPreviewPath = QDir(QStandardPaths::writableLocation(QStandardPaths::TempLocation))
        .filePath("lingust-selection-" + QUuid::createUuid().toString(QUuid::WithoutBraces) + ".png");
    if (!selected.save(m_selectionPreviewPath, "PNG")) {
        emit captureFailed(QStringLiteral("无法保存所选区域"));
        return;
    }
    m_selectionPreviewUrl = QUrl::fromLocalFile(m_selectionPreviewPath).toString();
    emit regionSelected(logicalRect.translated(m_screenGeometry.topLeft()));
    emit screenshotCaptured(selected);
}

void CaptureManager::cancelScreenshot()
{
    emit screenshotCancelled();
}

void CaptureManager::removePreviewFiles()
{
    if (!m_previewPath.isEmpty())
        QFile::remove(m_previewPath);
    if (!m_selectionPreviewPath.isEmpty())
        QFile::remove(m_selectionPreviewPath);
    m_previewPath.clear();
    m_previewUrl.clear();
    m_selectionPreviewPath.clear();
    m_selectionPreviewUrl.clear();
}
