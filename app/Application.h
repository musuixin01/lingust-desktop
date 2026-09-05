#pragma once

#include <QObject>
#include <memory>

class QQmlApplicationEngine;
class AppState;
class TranslatorWindow;

class Application : public QObject
{
    Q_OBJECT
public:
    explicit Application(QObject *parent = nullptr);
    ~Application() override;

    int run();

private:
    std::unique_ptr<QQmlApplicationEngine> m_engine;
    std::unique_ptr<AppState> m_appState;
    std::unique_ptr<TranslatorWindow> m_window;
};
