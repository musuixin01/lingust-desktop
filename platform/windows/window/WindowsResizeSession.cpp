#include "WindowsResizeSession.h"

#include <QWindow>
#include <QCoreApplication>
#include <QImage>
#include <QDebug>
#include <windows.h>
#include <windowsx.h>
#include <objidl.h>
#include <gdiplus.h>
#include <algorithm>
#include <cstring>

namespace {
// Copied from the user-approved standalone border_drag_test.cpp.
// Keep arc endpoints and pixel offsets identical to that reference.
void addRoundedPath(Gdiplus::GraphicsPath &path, int width, int height, int radius) {
    const int diameter = std::min(radius * 2, std::min(width, height));
    const int right = width - diameter - 1;
    const int bottom = height - diameter - 1;
    path.AddArc(0, 0, diameter, diameter, 180, 90);
    path.AddArc(right, 0, diameter, diameter, 270, 90);
    path.AddArc(right, bottom, diameter, diameter, 0, 90);
    path.AddArc(0, bottom, diameter, diameter, 90, 90);
    path.CloseFigure();
}
}

WindowsResizeSession::~WindowsResizeSession()
{
    if (m_hwnd && IsWindow(m_hwnd)) {
        if (m_originalWindowProc)
            SetWindowLongPtrW(m_hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(m_originalWindowProc));
        RemovePropW(m_hwnd, L"LinguistResizeSession");
    }
    if (m_gdiplusToken) Gdiplus::GdiplusShutdown(m_gdiplusToken);
}

bool WindowsResizeSession::initialize(QWindow *window)
{
    Gdiplus::GdiplusStartupInput input;
    if (!m_gdiplusToken && Gdiplus::GdiplusStartup(&m_gdiplusToken, &input, nullptr) != Gdiplus::Ok)
        return false;
    const auto hwnd = reinterpret_cast<HWND>(window->winId());
    const LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
    SetLastError(ERROR_SUCCESS);
    const LONG_PTR previous = SetWindowLongPtrW(hwnd, GWL_EXSTYLE, style | WS_EX_LAYERED);
    if (!previous && GetLastError() != ERROR_SUCCESS) return false;
    m_window = window;
    m_hwnd = hwnd;
    SetPropW(hwnd, L"LinguistResizeSession", this);
    SetLastError(ERROR_SUCCESS);
    m_originalWindowProc = reinterpret_cast<WNDPROC>(
        SetWindowLongPtrW(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(&WindowsResizeSession::windowProc)));
    if (!m_originalWindowProc && GetLastError() != ERROR_SUCCESS) {
        RemovePropW(hwnd, L"LinguistResizeSession");
        m_hwnd = nullptr;
        return false;
    }
    return true;
}

LRESULT CALLBACK WindowsResizeSession::windowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    auto *session = static_cast<WindowsResizeSession *>(GetPropW(hwnd, L"LinguistResizeSession"));
    if (!session) return DefWindowProcW(hwnd, message, wParam, lParam);
    MSG msg{};
    msg.hwnd = hwnd;
    msg.message = message;
    msg.wParam = wParam;
    msg.lParam = lParam;
    qintptr result = 0;
    if (session->nativeEventFilter({}, &msg, &result)) return LRESULT(result);
    return CallWindowProcW(session->m_originalWindowProc, hwnd, message, wParam, lParam);
}

bool WindowsResizeSession::nativeEventFilter(const QByteArray &, void *message, qintptr *result)
{
    const auto *msg = static_cast<MSG *>(message);
    if (!m_window || msg->hwnd != reinterpret_cast<HWND>(m_window->winId())) return false;
    switch (msg->message) {
    case WM_WINDOWPOSCHANGED:
    case WM_DPICHANGED:
        if (!m_submitting && !m_dragging && contentInvalidated
            && (msg->message == WM_DPICHANGED || nativeGeometry(m_window) != m_presentedGeometry))
            contentInvalidated();
        break;
    case WM_LBUTTONDOWN:
    case WM_LBUTTONDBLCLK:
        if (!m_pill) {
            const Qt::Edges zone = hitTest(m_window);
            if (zone && resizeStarted) {
                resizeStarted(zone);
                if (result) *result = 0;
                return true;
            }
        }
        if (pointerInput) {
            const qreal scale = scaleFactor(m_window);
            pointerInput(msg->message == WM_LBUTTONDBLCLK ? QEvent::MouseButtonDblClick
                                                          : QEvent::MouseButtonPress,
                         QPointF(GET_X_LPARAM(msg->lParam) / scale,
                                 GET_Y_LPARAM(msg->lParam) / scale),
                         Qt::LeftButton, Qt::LeftButton);
            if (result) *result = 0;
            return true;
        }
        break;
    case WM_MOUSEMOVE:
        if (m_dragging && GetCapture() == msg->hwnd && resizeMoved) {
            resizeMoved();
            if (result) *result = 0;
            return true;
        }
        if (pointerInput) {
            const qreal scale = scaleFactor(m_window);
            Qt::MouseButtons buttons;
            if (msg->wParam & MK_LBUTTON) buttons |= Qt::LeftButton;
            if (msg->wParam & MK_RBUTTON) buttons |= Qt::RightButton;
            if (msg->wParam & MK_MBUTTON) buttons |= Qt::MiddleButton;
            pointerInput(QEvent::MouseMove,
                         QPointF(GET_X_LPARAM(msg->lParam) / scale,
                                 GET_Y_LPARAM(msg->lParam) / scale),
                         Qt::NoButton, buttons);
            if (result) *result = 0;
            return true;
        }
        break;
    case WM_LBUTTONUP:
    case WM_CAPTURECHANGED:
        if (m_dragging && resizeEnded) {
            resizeEnded();
            if (result) *result = 0;
            return true;
        }
        if (msg->message == WM_LBUTTONUP && pointerInput) {
            const qreal scale = scaleFactor(m_window);
            pointerInput(QEvent::MouseButtonRelease,
                         QPointF(GET_X_LPARAM(msg->lParam) / scale,
                                 GET_Y_LPARAM(msg->lParam) / scale),
                         Qt::LeftButton, Qt::NoButton);
            if (result) *result = 0;
            return true;
        }
        break;
    default: break;
    }
    return false;
}

QRect WindowsResizeSession::nativeGeometry(QWindow *window) const
{
    RECT rect{};
    if (!GetWindowRect(reinterpret_cast<HWND>(window->winId()), &rect)) return {};
    return QRect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
}

qreal WindowsResizeSession::scaleFactor(QWindow *window) const
{
    return GetDpiForWindow(reinterpret_cast<HWND>(window->winId())) / 96.0;
}

bool WindowsResizeSession::begin(QWindow *window, Qt::Edges edges)
{
    RECT rect;
    POINT cursor;
    if (!GetWindowRect(reinterpret_cast<HWND>(window->winId()), &rect)
        || !GetCursorPos(&cursor)) return false;
    m_start = QRect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
    m_cursor = QPoint(cursor.x, cursor.y);
    m_edges = edges;
    SetForegroundWindow(reinterpret_cast<HWND>(window->winId()));
    SetFocus(reinterpret_cast<HWND>(window->winId()));
    SetCapture(reinterpret_cast<HWND>(window->winId()));
    m_dragging = GetCapture() == reinterpret_cast<HWND>(window->winId());
    return m_dragging;
}

QPointF WindowsResizeSession::pointerPosition(QWindow *window) const
{
    POINT cursor{};
    GetCursorPos(&cursor);
    const QRect rect = nativeGeometry(window);
    const qreal scale = scaleFactor(window);
    return QPointF((cursor.x - rect.x()) / scale, (cursor.y - rect.y()) / scale);
}

Qt::Edges WindowsResizeSession::hitTest(QWindow *window) const
{
    // Same eight zones as the approved test, measured in physical pixels.
    POINT point{};
    GetCursorPos(&point);
    const QRect rect = nativeGeometry(window);
    point.x -= rect.x(); point.y -= rect.y();
    const UINT dpi = GetDpiForWindow(reinterpret_cast<HWND>(window->winId()));
    const int edge = MulDiv(8, dpi, 96), corner = MulDiv(34, dpi, 96);
    const bool left = point.x < edge, right = point.x >= rect.width() - edge;
    const bool top = point.y < edge, bottom = point.y >= rect.height() - edge;
    const bool nearLeft = point.x < corner, nearRight = point.x >= rect.width() - corner;
    const bool nearTop = point.y < corner, nearBottom = point.y >= rect.height() - corner;
    if ((left && nearTop) || (top && nearLeft)) return Qt::TopEdge | Qt::LeftEdge;
    if ((right && nearTop) || (top && nearRight)) return Qt::TopEdge | Qt::RightEdge;
    if ((left && nearBottom) || (bottom && nearLeft)) return Qt::BottomEdge | Qt::LeftEdge;
    if ((right && nearBottom) || (bottom && nearRight)) return Qt::BottomEdge | Qt::RightEdge;
    if (left) return Qt::LeftEdge;
    if (right) return Qt::RightEdge;
    if (top) return Qt::TopEdge;
    if (bottom) return Qt::BottomEdge;
    return {};
}

QRect WindowsResizeSession::targetGeometry(QWindow *window) const
{
    const auto hwnd = reinterpret_cast<HWND>(window->winId());
    POINT cursor;
    RECT current;
    if (!GetCursorPos(&cursor) || !GetWindowRect(hwnd, &current)) return {};
    const qreal scale = GetDpiForWindow(hwnd) / 96.0;
    const int minW = qCeil(window->minimumWidth() * scale);
    const int minH = qCeil(qMax(window->minimumHeight(), m_pill ? 38 : 95) * scale);
    const int maxW = qFloor(window->maximumWidth() * scale);
    const int maxH = qFloor(window->maximumHeight() * scale);
    int left = m_start.x(), top = m_start.y();
    int right = left + m_start.width(), bottom = top + m_start.height();
    const int dx = cursor.x - m_cursor.x(), dy = cursor.y - m_cursor.y();
    if (m_edges.testFlag(Qt::LeftEdge)) left = qBound(right - maxW, left + dx, right - minW);
    if (m_edges.testFlag(Qt::RightEdge)) right = qBound(left + minW, right + dx, left + maxW);
    if (m_edges.testFlag(Qt::TopEdge)) top = qBound(bottom - maxH, top + dy, bottom - minH);
    if (m_edges.testFlag(Qt::BottomEdge)) bottom = qBound(top + minH, bottom + dy, top + maxH);
    return QRect(left, top, right - left, bottom - top);
}

bool WindowsResizeSession::present(QWindow *window, const QImage &source, const QRect &geometry,
                                   const WindowSurface &surface)
{
    if (!geometry.isValid() || source.size() != geometry.size()) return false;
    m_pill = surface.pill;
    const QImage frame = source.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    const auto hwnd = reinterpret_cast<HWND>(window->winId());
    HDC screen = GetDC(nullptr);
    HDC memory = CreateCompatibleDC(screen);
    BITMAPINFO info{};
    info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    info.bmiHeader.biWidth = frame.width();
    info.bmiHeader.biHeight = -frame.height();
    info.bmiHeader.biPlanes = 1;
    info.bmiHeader.biBitCount = 32;
    info.bmiHeader.biCompression = BI_RGB;
    void *pixels = nullptr;
    HBITMAP bitmap = CreateDIBSection(screen, &info, DIB_RGB_COLORS, &pixels, nullptr, 0);
    if (!screen || !memory || !bitmap || !pixels) {
        if (bitmap) DeleteObject(bitmap);
        if (memory) DeleteDC(memory);
        if (screen) ReleaseDC(nullptr, screen);
        return false;
    }
    const HGDIOBJ oldBitmap = SelectObject(memory, bitmap);
    {
        const int width = frame.width(), height = frame.height();
        const UINT dpi = GetDpiForWindow(hwnd);
        Gdiplus::Bitmap canvas(width, height, width * 4, PixelFormat32bppPARGB,
                              static_cast<BYTE *>(pixels));
        Gdiplus::Graphics graphics(&canvas);
        graphics.SetCompositingMode(Gdiplus::CompositingModeSourceCopy);
        graphics.Clear(Gdiplus::Color(0, 0, 0, 0));
        graphics.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
        graphics.SetPixelOffsetMode(Gdiplus::PixelOffsetModeHalf);
        Gdiplus::GraphicsPath path;
        addRoundedPath(path, width, height, surface.pill ? height / 2 : MulDiv(32, dpi, 96));
        const QColor color = surface.color;
        Gdiplus::SolidBrush fill(Gdiplus::Color(qRound(color.alpha() * qBound(0.0, surface.opacity, 1.0)),
                                              color.red(), color.green(), color.blue()));
        graphics.FillPath(&fill, &path);

        // The reference shell is unchanged. Compose the separate QML content
        // into its interior, then draw the reference inset border last.
        graphics.SetCompositingMode(Gdiplus::CompositingModeSourceOver);
        graphics.SetClip(&path);
        Gdiplus::Bitmap content(width, height, frame.bytesPerLine(), PixelFormat32bppPARGB,
                               const_cast<BYTE *>(frame.constBits()));
        graphics.DrawImage(&content, 0, 0, width, height);
        graphics.ResetClip();
        graphics.SetCompositingMode(Gdiplus::CompositingModeSourceCopy);
        Gdiplus::Pen border(Gdiplus::Color(105, 255, 255, 255),
                            static_cast<Gdiplus::REAL>(std::max(1, MulDiv(1, dpi, 96))));
        border.SetAlignment(Gdiplus::PenAlignmentInset);
        graphics.DrawPath(&border, &path);
    }
    POINT destination{geometry.x(), geometry.y()};
    SIZE size{geometry.width(), geometry.height()};
    POINT origin{0, 0};
    BLENDFUNCTION blend{AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
    m_submitting = true;
    const BOOL result = UpdateLayeredWindow(hwnd, screen, &destination, &size,
                                             memory, &origin, 0, &blend, ULW_ALPHA);
    m_submitting = false;
    if (result) m_presentedGeometry = geometry;
    SelectObject(memory, oldBitmap);
    DeleteObject(bitmap);
    DeleteDC(memory);
    ReleaseDC(nullptr, screen);
    return result != FALSE;
}

void WindowsResizeSession::end(QWindow *window)
{
    m_dragging = false;
    const auto hwnd = reinterpret_cast<HWND>(window->winId());
    if (GetCapture() == hwnd) ReleaseCapture();
}
