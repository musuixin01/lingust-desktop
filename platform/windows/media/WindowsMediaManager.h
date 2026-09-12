#pragma once

#include <QObject>
#include <QByteArray>
#include <QString>

class QProcess;

class WindowsMediaManager : public QObject
{
    Q_OBJECT

public:
    explicit WindowsMediaManager(QObject *parent = nullptr);
    ~WindowsMediaManager() override;

    bool isSupported() const;
    void start();

public slots:
    void sendPlay();
    void sendPause();
    void sendToggle();
    void sendNext();
    void sendPrevious();
    void sendSeek(int seconds);

signals:
    void snapshotChanged(bool connected, bool playing,
                         const QString &title, const QString &artist,
                         const QString &album, const QString &coverDataUrl,
                         int durationSeconds,
                         int positionSeconds);

private:
    QString bridgePath() const;
    void launchAction(const QString &action, int positionSeconds = 0);
    void processOutput();
    void scheduleRestart();

    QProcess *m_watcher = nullptr;
    QByteArray m_stdoutBuffer;
    bool m_stopping = false;
};
