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
#include <array>
#include <cmath>
#include <cstring>
#include <vector>

namespace {
// Keep the exponent close to a circle so the 32 px corners stay visibly round;
// values near an app-icon squircle make a compact desktop card look too square.
constexpr float continuousCornerExponent = 2.6f;

void addCircularRoundedPath(Gdiplus::GraphicsPath &path, int width, int height, int radius) {
    const int diameter = std::min(radius * 2, std::min(width, height));
    const int right = width - diameter - 1;
    const int bottom = height - diameter - 1;
    path.AddArc(0, 0, diameter, diameter, 180, 90);
    path.AddArc(right, 0, diameter, diameter, 270, 90);
    path.AddArc(right, bottom, diameter, diameter, 0, 90);
    path.AddArc(0, bottom, diameter, diameter, 90, 90);
    path.CloseFigure();
}

// A sampled superellipse gives the card a continuous shoulder: the straight
// edges flow into each corner without the abrupt curvature change of a circle.
// Every shell layer consumes this one physical-pixel path, so clipping, rim and
// resize feedback remain perfectly registered while the window changes size.
void addContinuousRoundedPath(Gdiplus::GraphicsPath &path, int width, int height, int radius) {
    const float right = float(std::max(0, width - 1));
    const float bottom = float(std::max(0, height - 1));
    const float roundedRadius = std::min(float(std::max(0, radius)),
                                         std::min(right, bottom) * 0.5f);
    if (roundedRadius <= 0.5f) {
        path.AddRectangle(Gdiplus::RectF(0.0f, 0.0f, right, bottom));
        return;
    }

    const int segments = std::clamp(int(std::ceil(roundedRadius)), 24, 48);
    const float power = 2.0f / continuousCornerExponent;
    constexpr float halfPi = 1.5707963267948966192f;
    std::vector<Gdiplus::PointF> points;
    points.reserve(size_t(segments * 4 + 4));
    points.emplace_back(roundedRadius, 0.0f);
    points.emplace_back(right - roundedRadius, 0.0f);

    const auto appendCorner = [&](float centerX, float centerY, float startAngle) {
        for (int step = 1; step <= segments; ++step) {
            const float progress = float(step) / float(segments);
            const float easedProgress = progress * progress * (3.0f - 2.0f * progress);
            const float angle = startAngle + halfPi * easedProgress;
            const float cosine = std::cos(angle);
            const float sine = std::sin(angle);
            const float x = centerX + std::copysign(
                roundedRadius * std::pow(std::abs(cosine), power), cosine);
            const float y = centerY + std::copysign(
                roundedRadius * std::pow(std::abs(sine), power), sine);
            points.emplace_back(x, y);
        }
    };

    appendCorner(right - roundedRadius, roundedRadius, -halfPi);
    points.emplace_back(right, bottom - roundedRadius);
    appendCorner(right - roundedRadius, bottom - roundedRadius, 0.0f);
    points.emplace_back(roundedRadius, bottom);
    appendCorner(roundedRadius, bottom - roundedRadius, halfPi);
    points.emplace_back(0.0f, roundedRadius);
    appendCorner(roundedRadius, roundedRadius, 2.0f * halfPi);
    path.AddLines(points.data(), int(points.size()));
    path.CloseFigure();
}

void addRoundedPath(Gdiplus::GraphicsPath &path, int width, int height, int radius,
                    bool continuousCorners) {
    if (continuousCorners)
        addContinuousRoundedPath(path, width, height, radius);
    else
        addCircularRoundedPath(path, width, height, radius);
}

}

void WindowsResizeSession::ensureAuroraField(int width, int height, int radius,
                                             bool continuousCorners)
{
    if (m_auroraFieldSize == QSize(width, height) && m_auroraFieldRadius == radius
        && m_auroraContinuousCorners == continuousCorners
        && m_auroraDistance.size() == size_t(width * height)) {
        return;
    }

    m_auroraFieldSize = QSize(width, height);
    m_auroraFieldRadius = radius;
    m_auroraContinuousCorners = continuousCorners;
    m_auroraDistance.resize(size_t(width * height));
    m_auroraPosition.resize(size_t(width * height));

    const float centerX = (width - 1) * 0.5f;
    const float centerY = (height - 1) * 0.5f;
    const float halfWidth = std::max(0.5f, centerX);
    const float halfHeight = std::max(0.5f, centerY);
    const float roundedRadius = std::min<float>(radius, std::min(halfWidth, halfHeight));
    constexpr float twoPi = 6.2831853071795864769f;

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            const float localX = x - centerX;
            const float localY = y - centerY;
            const float qx = std::abs(localX) - (halfWidth - roundedRadius);
            const float qy = std::abs(localY) - (halfHeight - roundedRadius);
            const float positiveX = std::max(qx, 0.0f);
            const float positiveY = std::max(qy, 0.0f);
            const float outside = continuousCorners
                ? std::pow(std::pow(positiveX, continuousCornerExponent)
                               + std::pow(positiveY, continuousCornerExponent),
                           1.0f / continuousCornerExponent)
                : std::hypot(positiveX, positiveY);
            const float inside = std::min(std::max(qx, qy), 0.0f);
            const size_t index = size_t(y) * width + x;
            m_auroraDistance[index] = -(outside + inside - roundedRadius);
            float angle = std::atan2(localY, localX) / twoPi;
            if (angle < 0.0f) angle += 1.0f;
            m_auroraPosition[index] = angle;
        }
    }
}

QImage WindowsResizeSession::createAuroraOverlay(qreal phase, qreal opacity, qreal bloom,
                                                  qreal pixelScale, bool rimOnly) const
{
    const int width = m_auroraFieldSize.width();
    const int height = m_auroraFieldSize.height();
    QImage overlay(width, height, QImage::Format_ARGB32_Premultiplied);
    overlay.fill(Qt::transparent);
    if (width <= 0 || height <= 0 || opacity <= 0.003) return overlay;

    struct Rgb { float r; float g; float b; };
    constexpr std::array<Rgb, 6> palette{{
        {91, 151, 255}, {166, 128, 255}, {244, 139, 205},
        {250, 197, 126}, {103, 220, 190}, {91, 151, 255}
    }};
    constexpr float twoPi = 6.2831853071795864769f;
    const float scale = std::max(0.75f, float(pixelScale));
    const float spread = (18.0f + float(bloom) * 16.0f) * scale;
    const float tail = (8.5f + float(bloom) * 7.0f) * scale;
    const float phaseValue = float(phase);

    for (int y = 0; y < height; ++y) {
        auto *line = reinterpret_cast<QRgb *>(overlay.scanLine(y));
        for (int x = 0; x < width; ++x) {
            const size_t index = size_t(y) * width + x;
            const float distance = m_auroraDistance[index];
            if (distance < -0.75f || (!rimOnly && distance > spread)
                || (rimOnly && distance > 5.0f * scale)) {
                continue;
            }

            const float position = m_auroraPosition[index];
            float colorPosition = position + phaseValue * 0.26f
                + std::sin((position * 3.0f + phaseValue * 0.32f) * twoPi) * 0.022f;
            colorPosition -= std::floor(colorPosition);
            const float scaledColor = colorPosition * float(palette.size() - 1);
            const int colorIndex = std::min<int>(palette.size() - 2,
                                                  int(std::floor(scaledColor)));
            float amount = scaledColor - colorIndex;
            amount = amount * amount * (3.0f - 2.0f * amount);
            const auto mix = [amount](float a, float b) { return a + (b - a) * amount; };
            float red = mix(palette[colorIndex].r, palette[colorIndex + 1].r);
            float green = mix(palette[colorIndex].g, palette[colorIndex + 1].g);
            float blue = mix(palette[colorIndex].b, palette[colorIndex + 1].b);

            const float whiteMix = rimOnly ? 0.30f : 0.20f;
            red += (255.0f - red) * whiteMix;
            green += (255.0f - green) * whiteMix;
            blue += (255.0f - blue) * whiteMix;
            const float modulation = 0.88f
                + 0.065f * std::sin((position * 2.0f - phaseValue * 0.22f) * twoPi)
                + 0.035f * std::sin((position * 5.0f + phaseValue * 0.13f) * twoPi);

            float alpha = 0.0f;
            if (rimOnly) {
                const float rimCenter = 0.9f * scale;
                const float rimSigma = 0.72f * scale;
                const float rimDistance = (distance - rimCenter) / rimSigma;
                alpha = float(opacity) * modulation
                    * (0.38f * std::exp(-0.5f * rimDistance * rimDistance)
                       + 0.035f * std::exp(-std::max(distance, 0.0f) / (2.8f * scale)));
            } else {
                const float coreSigma = 4.2f * scale;
                alpha = float(opacity) * modulation
                    * (0.075f * std::exp(-(distance * distance)
                                         / (2.0f * coreSigma * coreSigma))
                       + 0.105f * std::exp(-std::max(distance, 0.0f) / tail));
                const float edgeFade = std::clamp((spread - distance) / (5.0f * scale), 0.0f, 1.0f);
                alpha *= edgeFade * edgeFade * (3.0f - 2.0f * edgeFade);
            }

            const int a = std::clamp(qRound(alpha * 255.0f), 0, 255);
            const int r = std::clamp(qRound(red * a / 255.0f), 0, 255);
            const int g = std::clamp(qRound(green * a / 255.0f), 0, 255);
            const int b = std::clamp(qRound(blue * a / 255.0f), 0, 255);
            line[x] = qRgba(r, g, b, a);
        }
    }
    return overlay;
}

WindowsResizeSession::~WindowsResizeSession()
{
    if (m_nativeFilterInstalled && QCoreApplication::instance())
        QCoreApplication::instance()->removeNativeEventFilter(this);
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
    if (!m_nativeFilterInstalled && QCoreApplication::instance()) {
        QCoreApplication::instance()->installNativeEventFilter(this);
        m_nativeFilterInstalled = true;
    }
    const auto installedProc = reinterpret_cast<WNDPROC>(GetWindowLongPtrW(hwnd, GWLP_WNDPROC));
    if (m_hwnd == hwnd && installedProc == &WindowsResizeSession::windowProc)
        return true;
    const LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
    const LONG_PTR taskbarStyle = (style | WS_EX_LAYERED | WS_EX_APPWINDOW) & ~WS_EX_TOOLWINDOW;
    SetLastError(ERROR_SUCCESS);
    const LONG_PTR previous = SetWindowLongPtrW(hwnd, GWL_EXSTYLE, taskbarStyle);
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
    case WM_LBUTTONDBLCLK: {
        const QPoint nativePoint(GET_X_LPARAM(msg->lParam), GET_Y_LPARAM(msg->lParam));
        const Qt::Edges zone = hitTestAt(m_window, nativePoint);
        if (zone && resizeStarted) {
            resizeStarted(zone);
            if (result) *result = 0;
            return true;
        }
        if (pointerInput) {
            // The custom layered window consumes this message before Qt's native
            // handler. Activate it explicitly so the focused QML TextField keeps
            // receiving keyboard and IME events after a content-area click.
            SetForegroundWindow(msg->hwnd);
            SetFocus(msg->hwnd);
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
    }
    case WM_SETCURSOR:
        if (LOWORD(msg->lParam) == HTCLIENT && applyNativeResizeCursor()) {
            if (result) *result = TRUE;
            return true;
        }
        break;
    case WM_MOUSEMOVE:
        applyNativeResizeCursor();
        if (!m_trackingMouseLeave) {
            TRACKMOUSEEVENT tracking{};
            tracking.cbSize = sizeof(tracking);
            tracking.dwFlags = TME_LEAVE;
            tracking.hwndTrack = msg->hwnd;
            m_trackingMouseLeave = TrackMouseEvent(&tracking) != FALSE;
        }
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
    case WM_MOUSELEAVE:
        m_trackingMouseLeave = false;
        if (pointerInput) {
            pointerInput(QEvent::Leave, QPointF(-1, -1), Qt::NoButton, Qt::NoButton);
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

bool WindowsResizeSession::applyNativeResizeCursor()
{
    const Qt::Edges edges = m_dragging ? m_edges : hitTest(m_window);
    LPCWSTR cursorId = nullptr;
    if (edges == (Qt::LeftEdge | Qt::TopEdge)
        || edges == (Qt::RightEdge | Qt::BottomEdge)) {
        cursorId = IDC_SIZENWSE;
    } else if (edges == (Qt::RightEdge | Qt::TopEdge)
               || edges == (Qt::LeftEdge | Qt::BottomEdge)) {
        cursorId = IDC_SIZENESW;
    } else if (edges.testFlag(Qt::LeftEdge) || edges.testFlag(Qt::RightEdge)) {
        cursorId = IDC_SIZEWE;
    } else if (edges.testFlag(Qt::TopEdge) || edges.testFlag(Qt::BottomEdge)) {
        cursorId = IDC_SIZENS;
    }
    if (!cursorId) {
        // A custom layered window does not reliably receive the default client
        // cursor after our edge handler has set a resize cursor. Clear only our
        // own resize state so normal content never inherits the last edge shape.
        if (m_resizeCursorActive) {
            SetCursor(LoadCursorW(nullptr, IDC_ARROW));
            m_resizeCursorActive = false;
        }
        return false;
    }
    SetCursor(LoadCursorW(nullptr, cursorId));
    m_resizeCursorActive = true;
    return true;
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

bool WindowsResizeSession::minimize(QWindow *window)
{
    if (!window) return false;
    const auto hwnd = reinterpret_cast<HWND>(window->winId());
    if (!hwnd || !IsWindow(hwnd)) return false;

    // Keep the layered translator represented by a normal taskbar button and
    // let Windows own the minimize transition. Qt's generic showMinimized()
    // can be undone by a queued UpdateLayeredWindow submission.
    const LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
    SetWindowLongPtrW(hwnd, GWL_EXSTYLE,
                      (style | WS_EX_APPWINDOW | WS_EX_LAYERED) & ~WS_EX_TOOLWINDOW);
    if (GetCapture() == hwnd) ReleaseCapture();
    m_dragging = false;
    if (m_resizeCursorActive) SetCursor(LoadCursorW(nullptr, IDC_ARROW));
    m_resizeCursorActive = false;
    ShowWindow(hwnd, SW_MINIMIZE);
    return IsIconic(hwnd) != FALSE;
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
    POINT point{};
    GetCursorPos(&point);
    const QRect rect = nativeGeometry(window);
    point.x -= rect.x(); point.y -= rect.y();
    return hitTestAt(window, QPoint(point.x, point.y));
}

Qt::Edges WindowsResizeSession::hitTestAt(QWindow *window, const QPoint &nativePoint) const
{
    // Keep all eight stable zones, with a forgiving ten-logical-pixel edge.
    const QRect rect = nativeGeometry(window);
    const QPoint point = nativePoint;
    const UINT dpi = GetDpiForWindow(reinterpret_cast<HWND>(window->winId()));
    const int edge = MulDiv(10, dpi, 96), corner = MulDiv(38, dpi, 96);
    // Do not let the generous card corner zone consume an entire short pill.
    // The middle third of every edge remains available for one-axis resizing.
    const int cornerX = std::min(corner, std::max(edge, rect.width() / 3));
    const int cornerY = std::min(corner, std::max(edge, rect.height() / 3));
    const bool left = point.x() < edge, right = point.x() >= rect.width() - edge;
    const bool top = point.y() < edge, bottom = point.y() >= rect.height() - edge;
    const bool nearLeft = point.x() < cornerX, nearRight = point.x() >= rect.width() - cornerX;
    const bool nearTop = point.y() < cornerY, nearBottom = point.y() >= rect.height() - cornerY;
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
    const int maxH = qFloor(qMin(window->maximumHeight(), m_pill ? 72 : window->maximumHeight()) * scale);
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
        const int radius = surface.cornerRadius > 0
            ? surface.cornerRadius
            : (surface.pill ? height / 2 : MulDiv(32, dpi, 96));
        const bool continuousCorners = !surface.pill;
        addRoundedPath(path, width, height, radius, continuousCorners);
        const QColor color = surface.color;
        Gdiplus::SolidBrush fill(Gdiplus::Color(qRound(color.alpha() * qBound(0.0, surface.opacity, 1.0)),
                                               color.red(), color.green(), color.blue()));
        graphics.FillPath(&fill, &path);

        // A restrained optical layer gives the native translucent shell depth
        // without stacking another glass container over the content.
        graphics.SetCompositingMode(Gdiplus::CompositingModeSourceOver);
        const BYTE sheenAlpha = surface.pill ? 44 : 30;
        Gdiplus::LinearGradientBrush sheen(
            Gdiplus::Point(0, 0), Gdiplus::Point(0, std::max(1, height)),
            Gdiplus::Color(sheenAlpha, 255, 255, 255),
            Gdiplus::Color(4, 180, 210, 255));
        graphics.FillPath(&sheen, &path);

        const qreal auroraOpacity = qBound(0.0, surface.auroraOpacity, 1.0);
        const qreal auroraBloom = qBound(0.0, surface.auroraBloom, 1.0);
        const qreal pixelScale = dpi / 96.0;
        if (auroraOpacity > 0.003) {
            ensureAuroraField(width, height, radius, continuousCorners);
            const QImage glow = createAuroraOverlay(surface.auroraPhase, auroraOpacity,
                                                     auroraBloom, pixelScale, false);
            Gdiplus::Bitmap glowBitmap(width, height, glow.bytesPerLine(),
                                       PixelFormat32bppPARGB,
                                       const_cast<BYTE *>(glow.constBits()));
            graphics.SetClip(&path);
            graphics.DrawImage(&glowBitmap, 0, 0, width, height);
            graphics.ResetClip();
        }

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
        border.SetLineJoin(Gdiplus::LineJoinRound);
        graphics.DrawPath(&border, &path);
        if (auroraOpacity > 0.003) {
            graphics.SetCompositingMode(Gdiplus::CompositingModeSourceOver);
            const QImage rim = createAuroraOverlay(surface.auroraPhase, auroraOpacity,
                                                    auroraBloom, pixelScale, true);
            Gdiplus::Bitmap rimBitmap(width, height, rim.bytesPerLine(),
                                      PixelFormat32bppPARGB,
                                      const_cast<BYTE *>(rim.constBits()));
            graphics.SetClip(&path);
            graphics.DrawImage(&rimBitmap, 0, 0, width, height);
            graphics.ResetClip();
        }
        if (surface.resizeEdges != 0 || surface.resizing) {
            graphics.SetCompositingMode(Gdiplus::CompositingModeSourceOver);
            graphics.SetClip(&path);
            const BYTE softAlpha = surface.resizing ? 82 : 44;
            const BYTE crispAlpha = surface.resizing ? 205 : 118;
            Gdiplus::Pen softResizeGlow(Gdiplus::Color(softAlpha, 92, 174, 255),
                                        Gdiplus::REAL(pixelScale * (surface.resizing ? 7.0 : 5.0)));
            softResizeGlow.SetLineJoin(Gdiplus::LineJoinRound);
            graphics.DrawPath(&softResizeGlow, &path);
            Gdiplus::Pen resizeRim(Gdiplus::Color(crispAlpha, 185, 222, 255),
                                   Gdiplus::REAL(pixelScale * 1.35));
            resizeRim.SetLineJoin(Gdiplus::LineJoinRound);
            graphics.DrawPath(&resizeRim, &path);
            graphics.ResetClip();
        }
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
    // Showing or resizing a previously hidden Qt window can replace its native
    // procedure during UpdateLayeredWindow. Attach after the transaction so
    // both border and client input remain on the approved native path.
    const auto currentProc = reinterpret_cast<WNDPROC>(GetWindowLongPtrW(hwnd, GWLP_WNDPROC));
    if (currentProc != &WindowsResizeSession::windowProc) {
        m_originalWindowProc = currentProc;
        SetWindowLongPtrW(hwnd, GWLP_WNDPROC,
                          reinterpret_cast<LONG_PTR>(&WindowsResizeSession::windowProc));
        SetPropW(hwnd, L"LinguistResizeSession", this);
    }
    SelectObject(memory, oldBitmap);
    DeleteObject(bitmap);
    DeleteDC(memory);
    ReleaseDC(nullptr, screen);
    return result != FALSE;
}

void WindowsResizeSession::end(QWindow *window)
{
    m_dragging = false;
    if (m_resizeCursorActive) SetCursor(LoadCursorW(nullptr, IDC_ARROW));
    m_resizeCursorActive = false;
    const auto hwnd = reinterpret_cast<HWND>(window->winId());
    if (GetCapture() == hwnd) ReleaseCapture();
}
