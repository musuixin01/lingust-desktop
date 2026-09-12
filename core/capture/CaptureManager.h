#pragma once

#include <QObject>
#include <QImage>
#include <QRect>
#include <QString>

class CaptureManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString previewUrl READ previewUrl NOTIFY capturePrepared)
    Q_PROPERTY(int screenX READ screenX NOTIFY capturePrepared)
    Q_PROPERTY(int screenY READ screenY NOTIFY capturePrepared)
    Q_PROPERTY(int screenWidth READ screenWidth NOTIFY capturePrepared)
    Q_PROPERTY(int screenHeight READ screenHeight NOTIFY capturePrepared)
public:
    explicit CaptureManager(QObject *parent = nullptr);
    ~CaptureManager() override;

    Q_INVOKABLE QImage captureFullScreen();
    Q_INVOKABLE QImage captureScreen(const QRect &rect);
    Q_INVOKABLE bool startScreenshotMode();
    Q_INVOKABLE void confirmSelection(qreal x, qreal y, qreal width, qreal height);
    Q_INVOKABLE void cancelScreenshot();

    QString previewUrl() const { return m_previewUrl; }
    QString selectionPreviewUrl() const { return m_selectionPreviewUrl; }
    int screenX() const { return m_screenGeometry.x(); }
    int screenY() const { return m_screenGeometry.y(); }
    int screenWidth() const { return m_screenGeometry.width(); }
    int screenHeight() const { return m_screenGeometry.height(); }

signals:
    void capturePrepared();
    void captureFailed(const QString &message);
    void screenshotCaptured(const QImage &image);
    void screenshotCancelled();
    void regionSelected(const QRect &rect);

private:
    void removePreviewFiles();

    QImage m_fullScreen;
    QRect m_screenGeometry;
    qreal m_devicePixelRatio = 1.0;
    QString m_previewPath;
    QString m_previewUrl;
    QString m_selectionPreviewPath;
    QString m_selectionPreviewUrl;
};
