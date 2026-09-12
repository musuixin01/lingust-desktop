#pragma once

#include "../../../providers/ocr/IOcrProvider.h"

class WindowsOcrProvider : public IOcrProvider
{
    Q_OBJECT

public:
    explicit WindowsOcrProvider(QObject *parent = nullptr);

    QString name() const override { return "windows-ocr"; }
    void recognize(const QImage &image, const QString &language = QString()) override;

private:
    QString bridgePath() const;
    void launchBridge(const QString &imagePath, const QString &language);
};
