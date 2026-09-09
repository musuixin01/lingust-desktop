#pragma once

#include <Qt>
#include <QRect>
#include <QColor>
#include <QEvent>
#include <QPointF>
#include <functional>

struct WindowSurface {
    bool pill = false;
    QColor color = QColor(28, 32, 42, 238);
    qreal opacity = 1.0;
};

class QWindow;
class QImage;

// Platform adapters preserve native pixel anchors without exposing OS calls to QML.
class WindowResizeSession
{
public:
    std::function<void(Qt::Edges)> resizeStarted;
    std::function<void()> resizeMoved;
    std::function<void()> resizeEnded;
    std::function<void()> contentInvalidated;
    std::function<void(QEvent::Type, const QPointF &, Qt::MouseButton, Qt::MouseButtons)> pointerInput;
    virtual ~WindowResizeSession() = default;
    virtual bool initialize(QWindow *window) = 0;
    virtual QRect nativeGeometry(QWindow *window) const = 0;
    virtual qreal scaleFactor(QWindow *window) const = 0;
    virtual QPointF pointerPosition(QWindow *window) const = 0;
    virtual Qt::Edges hitTest(QWindow *window) const = 0;
    virtual bool begin(QWindow *window, Qt::Edges edges) = 0;
    virtual QRect targetGeometry(QWindow *window) const = 0;
    virtual bool present(QWindow *window, const QImage &frame, const QRect &nativeGeometry,
                         const WindowSurface &surface) = 0;
    virtual void end(QWindow *window) = 0;
};
