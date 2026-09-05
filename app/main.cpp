#include <QGuiApplication>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QSurfaceFormat>
#include <QDebug>
#include <cstdio>
#include "Application.h"

int main(int argc, char *argv[])
{
    // 必须在创建 QGuiApplication 之前设置表面格式，启用 alpha 通道
    QSurfaceFormat format;
    format.setAlphaBufferSize(8);
    format.setSamples(4);
    QSurfaceFormat::setDefaultFormat(format);

    QGuiApplication app(argc, argv);

    // per-pixel alpha 实现圆角（已验证圆角正常）
    QQuickWindow::setDefaultAlphaBuffer(true);

    QGuiApplication::setApplicationName("Linguist");
    QGuiApplication::setOrganizationName("Linguist");
    QGuiApplication::setApplicationDisplayName("Linguist 桌面悬浮翻译");

    Application application;
    return application.run();
}
