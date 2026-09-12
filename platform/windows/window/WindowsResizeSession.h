#pragma once

#include "core/window/WindowResizeSession.h"
#include <QRect>
#include <QPoint>
#include <QAbstractNativeEventFilter>
#include <vector>
#include <windows.h>

class WindowsResizeSession final : public WindowResizeSession, public QAbstractNativeEventFilter
{
public:
    ~WindowsResizeSession() override;
    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override;
    bool initialize(QWindow *window) override;
    QRect nativeGeometry(QWindow *window) const override;
    qreal scaleFactor(QWindow *window) const override;
    QPointF pointerPosition(QWindow *window) const override;
    Qt::Edges hitTest(QWindow *window) const override;
    bool begin(QWindow *window, Qt::Edges edges) override;
    bool minimize(QWindow *window) override;
    QRect targetGeometry(QWindow *window) const override;
    bool present(QWindow *window, const QImage &frame, const QRect &nativeGeometry,
                 const WindowSurface &surface) override;
    void end(QWindow *window) override;

private:
    static LRESULT CALLBACK windowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    bool applyNativeResizeCursor();
    Qt::Edges hitTestAt(QWindow *window, const QPoint &nativePoint) const;
    void ensureAuroraField(int width, int height, int radius, bool continuousCorners);
    QImage createAuroraOverlay(qreal phase, qreal opacity, qreal bloom,
                               qreal pixelScale, bool rimOnly) const;
    quintptr m_gdiplusToken = 0;
    HWND m_hwnd = nullptr;
    WNDPROC m_originalWindowProc = nullptr;
    QWindow *m_window = nullptr;
    bool m_dragging = false;
    bool m_pill = true;
    bool m_trackingMouseLeave = false;
    bool m_resizeCursorActive = false;
    bool m_submitting = false;
    bool m_nativeFilterInstalled = false;
    QRect m_presentedGeometry;
    QRect m_start;
    QPoint m_cursor;
    Qt::Edges m_edges;
    QSize m_auroraFieldSize;
    int m_auroraFieldRadius = -1;
    bool m_auroraContinuousCorners = false;
    std::vector<float> m_auroraDistance;
    std::vector<float> m_auroraPosition;
};
