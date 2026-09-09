#include "TranslatorWindow.h"

#include <QCoreApplication>
#include <QCursor>
#include <QExposeEvent>
#include <QFocusEvent>
#include <QGuiApplication>
#include <QHoverEvent>
#include <QInputMethodEvent>
#include <QKeyEvent>
#include <QMouseEvent>
#include <QQuickItem>
#include <QQuickRenderControl>
#include <QQuickRenderTarget>
#include <QQuickWindow>
#include <QResizeEvent>
#include <QScreen>
#include <QTimer>
#include <QVariantAnimation>
#include <QWheelEvent>
#include <cmath>

TranslatorWindow::TranslatorWindow(QWindow *parent)
    : QWindow(parent)
    , m_renderControl(std::make_unique<QQuickRenderControl>())
    , m_scene(std::make_unique<QQuickWindow>(m_renderControl.get()))
    , m_sizeAnimation(new QVariantAnimation(this))
{
    m_scene->setColor(Qt::transparent);
    connect(m_renderControl.get(), &QQuickRenderControl::renderRequested,
            this, &TranslatorWindow::scheduleRender);
    connect(m_renderControl.get(), &QQuickRenderControl::sceneChanged,
            this, &TranslatorWindow::scheduleRender);
    connect(m_sizeAnimation, &QVariantAnimation::valueChanged, this, [this](const QVariant &value) {
        if (!m_resizeSession || !m_animationOrigin.isValid()) return;
        const QSize logicalSize = value.toSize();
        const qreal scale = m_resizeSession->scaleFactor(this);
        QRect target = m_animationOrigin;
        target.setSize(QSize(qRound(logicalSize.width() * scale),
                             qRound(logicalSize.height() * scale)));
        renderAndPresent(target);
    });
    setupWindow();
}

TranslatorWindow::~TranslatorWindow()
{
    if (m_renderControl) m_renderControl->invalidate();
}

void TranslatorWindow::setupWindow()
{
    setFlag(Qt::FramelessWindowHint);
    setFlag(Qt::WindowStaysOnTopHint);
    setFlag(Qt::WindowDoesNotAcceptFocus, false);
    resize(m_pillWidth, m_pillHeight);
    setMinimumSize(QSize(160, 38));
    centerWindow();
}

void TranslatorWindow::centerWindow()
{
    QScreen *targetScreen = QGuiApplication::primaryScreen();
    if (!targetScreen) return;
    const QRect available = targetScreen->availableGeometry();
    setPosition(available.center().x() - m_pillWidth / 2, available.center().y() - 200);
}

QString TranslatorWindow::currentMode() const { return m_currentMode; }
bool TranslatorWindow::isDragging() const { return m_isDragging; }
bool TranslatorWindow::isResizing() const { return m_isResizing; }
int TranslatorWindow::pillWidth() const { return m_pillWidth; }
int TranslatorWindow::pillHeight() const { return m_pillHeight; }
int TranslatorWindow::cardWidth() const { return m_cardWidth; }
int TranslatorWindow::cardHeight() const { return m_cardHeight; }

void TranslatorWindow::setCurrentMode(const QString &mode)
{
    if (m_currentMode == mode) return;
    endInteractiveResize();
    m_currentMode = mode;
    emit currentModeChanged();
    scheduleRender();
}

void TranslatorWindow::setPillWidth(int value)
{
    if (m_pillWidth == value) return;
    m_pillWidth = value;
    emit pillWidthChanged();
}

void TranslatorWindow::setPillHeight(int value)
{
    if (m_pillHeight == value) return;
    m_pillHeight = value;
    emit pillHeightChanged();
}

void TranslatorWindow::setCardWidth(int value)
{
    if (m_cardWidth == value) return;
    m_cardWidth = value;
    emit cardWidthChanged();
}

void TranslatorWindow::setCardHeight(int value)
{
    if (m_cardHeight == value) return;
    m_cardHeight = value;
    emit cardHeightChanged();
}

void TranslatorWindow::setResizeSession(std::unique_ptr<WindowResizeSession> session)
{
    endInteractiveResize();
    m_resizeSession = std::move(session);
    create();
    if (m_resizeSession) {
        m_resizeSession->resizeStarted = [this](Qt::Edges edges) { beginInteractiveResize(int(edges)); };
        m_resizeSession->resizeMoved = [this] { applyInteractiveResize(); };
        m_resizeSession->resizeEnded = [this] { endInteractiveResize(); };
        m_resizeSession->contentInvalidated = [this] { scheduleRender(); };
        m_resizeSession->pointerInput = [this](QEvent::Type type, const QPointF &local,
                                               Qt::MouseButton button, Qt::MouseButtons buttons) {
            forwardNativePointer(type, local, button, buttons);
        };
        m_resizeSession->initialize(this);
    }
}

void TranslatorWindow::setContentItem(QQuickItem *item)
{
    if (!item) return;
    m_rootItem = item;
    item->setParentItem(m_scene->contentItem());
    scheduleRender();
}

void TranslatorWindow::scheduleRender()
{
    if (m_renderQueued || !m_resizeSession || !m_rootItem) return;
    m_renderQueued = true;
    QTimer::singleShot(0, this, [this] {
        m_renderQueued = false;
        if (!m_rendering && m_resizeSession)
            renderAndPresent(m_resizeSession->nativeGeometry(this));
    });
}

bool TranslatorWindow::renderAndPresent(const QRect &nativeGeometry)
{
    if (m_rendering || !m_resizeSession || !m_rootItem || !nativeGeometry.isValid()) return false;
    m_rendering = true;
    const qreal scale = qMax<qreal>(1.0, m_resizeSession->scaleFactor(this));
    // QWindow geometry is integral, but QML bounds must retain the fractional
    // logical size so their right/bottom edges land on the exact physical pixel.
    const QSizeF logicalSize(nativeGeometry.width() / scale,
                             nativeGeometry.height() / scale);
    m_scene->setGeometry(0, 0, qCeil(logicalSize.width()), qCeil(logicalSize.height()));
    m_scene->contentItem()->setSize(logicalSize);
    m_rootItem->setSize(logicalSize);

    // The software scene graph only repaints dirty regions. Retain the paint
    // device and its unchanged pixels across frames; a fresh transparent image
    // each time makes idle frames erase the visible layered window.
    if (m_frame.size() != nativeGeometry.size() || m_frame.devicePixelRatio() != scale) {
        m_scene->setRenderTarget(QQuickRenderTarget());
        m_frame = QImage(nativeGeometry.size(), QImage::Format_ARGB32_Premultiplied);
        m_frame.fill(Qt::transparent);
        m_frame.setDevicePixelRatio(scale);
        QQuickRenderTarget target = QQuickRenderTarget::fromPaintDevice(&m_frame);
        target.setDevicePixelRatio(scale);
        m_scene->setRenderTarget(target);
    }
    m_renderControl->polishItems();
    m_renderControl->sync();
    m_renderControl->render();

    WindowSurface surface;
    surface.pill = m_currentMode == "pill";
    surface.color = m_rootItem->property("shellColor").value<QColor>();
    surface.opacity = m_rootItem->property("shellOpacity").toReal();
    m_presenting = true;
    const bool result = m_resizeSession->present(this, m_frame, nativeGeometry, surface);
    m_presenting = false;
    m_rendering = false;
    return result;
}

void TranslatorWindow::beginInteractiveResize(int edges)
{
    const Qt::Edges requested(edges);
    if (!m_resizeSession || !requested
        || (requested.testFlag(Qt::LeftEdge) && requested.testFlag(Qt::RightEdge))
        || (requested.testFlag(Qt::TopEdge) && requested.testFlag(Qt::BottomEdge))) return;
    m_sizeAnimation->stop();
    m_resizeEdges = requested;
    if (!m_resizeSession->begin(this, requested)) return;
    if (!m_isResizing) {
        m_isResizing = true;
        emit isResizingChanged();
    }
}

void TranslatorWindow::applyInteractiveResize()
{
    if (!m_isResizing || !m_resizeSession) return;
    const QRect target = m_resizeSession->targetGeometry(this);
    if (target.isValid() && target != m_resizeSession->nativeGeometry(this))
        renderAndPresent(target);
}

void TranslatorWindow::endInteractiveResize()
{
    if (!m_isResizing) return;
    if (m_resizeSession) {
        const QRect finalGeometry = m_resizeSession->targetGeometry(this);
        if (finalGeometry.isValid() && finalGeometry != m_resizeSession->nativeGeometry(this))
            renderAndPresent(finalGeometry);
    }
    m_resizeEdges = {};
    m_isResizing = false;
    if (m_resizeSession) m_resizeSession->end(this);
    emit isResizingChanged();
    scheduleRender();
}

void TranslatorWindow::animateSize(int targetWidth, int targetHeight, int duration)
{
    if (m_isResizing || !m_resizeSession) return;
    m_sizeAnimation->stop();
    m_animationOrigin = m_resizeSession->nativeGeometry(this);
    m_sizeAnimation->setDuration(duration);
    m_sizeAnimation->setEasingCurve(QEasingCurve::OutCubic);
    const qreal scale = m_resizeSession->scaleFactor(this);
    m_sizeAnimation->setStartValue(QSize(qRound(m_animationOrigin.width() / scale),
                                       qRound(m_animationOrigin.height() / scale)));
    m_sizeAnimation->setEndValue(QSize(targetWidth, targetHeight));
    m_sizeAnimation->start();
}

void TranslatorWindow::toggleMode()
{
    m_currentMode == "pill" ? expandToCard() : collapseToPill();
}

void TranslatorWindow::expandToCard()
{
    const int targetWidth = qMax(width(), 380);
    m_cardWidth = targetWidth;
    m_cardHeight = 490;
    setCurrentMode("card");
    animateSize(targetWidth, m_cardHeight, 220);
}

void TranslatorWindow::collapseToPill()
{
    const int targetWidth = qMax(width(), 160);
    m_pillWidth = targetWidth;
    m_pillHeight = 46;
    setCurrentMode("pill");
    animateSize(targetWidth, m_pillHeight, 180);
}

void TranslatorWindow::minimizeToTaskbar()
{
    showMinimized();
}

void TranslatorWindow::adjustHeightToContent(int contentHeight)
{
    if (m_currentMode != "card" || m_isResizing || contentHeight <= 0) return;
    const int targetHeight = qBound(200, contentHeight, 800);
    if (qAbs(height() - targetHeight) >= 10) animateSize(width(), targetHeight, 180);
}

bool TranslatorWindow::forwardInputEvent(QEvent *event)
{
    if (!m_scene) return false;
    switch (event->type()) {
    case QEvent::MouseButtonPress:
    case QEvent::MouseButtonRelease:
    case QEvent::MouseButtonDblClick:
    case QEvent::MouseMove: {
        const auto *source = static_cast<QMouseEvent *>(event);
        if ((source->type() == QEvent::MouseButtonPress || source->type() == QEvent::MouseButtonDblClick)
            && source->button() == Qt::LeftButton) {
            const Qt::Edges edges = resizeEdgesAt(source->position());
            if (edges) {
                beginInteractiveResize(edges);
                return true;
            }
        }
        if (m_isResizing) {
            if (source->type() == QEvent::MouseMove) applyInteractiveResize();
            if (source->type() == QEvent::MouseButtonRelease) endInteractiveResize();
            return true;
        }
        if (source->type() == QEvent::MouseMove) updateResizeCursor(source->position());
        const QPointF local = m_resizeSession ? m_resizeSession->pointerPosition(this) : source->position();
        QMouseEvent forwarded(source->type(), local, local,
                              source->globalPosition(), source->button(), source->buttons(),
                              source->modifiers(), source->pointingDevice());
        QCoreApplication::sendEvent(m_scene.get(), &forwarded);
        return forwarded.isAccepted();
    }
    case QEvent::Wheel: {
        const auto *source = static_cast<QWheelEvent *>(event);
        QWheelEvent forwarded(source->position(), source->globalPosition(), source->pixelDelta(),
                              source->angleDelta(), source->buttons(), source->modifiers(),
                              source->phase(), source->inverted(), source->source(), source->pointingDevice());
        QCoreApplication::sendEvent(m_scene.get(), &forwarded);
        return forwarded.isAccepted();
    }
    case QEvent::KeyPress:
    case QEvent::KeyRelease: {
        const auto *source = static_cast<QKeyEvent *>(event);
        QKeyEvent forwarded(source->type(), source->key(), source->modifiers(),
                            source->nativeScanCode(), source->nativeVirtualKey(),
                            source->nativeModifiers(), source->text(), source->isAutoRepeat(),
                            source->count(), source->device());
        QCoreApplication::sendEvent(m_scene.get(), &forwarded);
        return forwarded.isAccepted();
    }
    case QEvent::InputMethod: {
        const auto *source = static_cast<QInputMethodEvent *>(event);
        QInputMethodEvent forwarded(source->preeditString(), source->attributes());
        forwarded.setCommitString(source->commitString(), source->replacementStart(), source->replacementLength());
        QCoreApplication::sendEvent(m_scene.get(), &forwarded);
        return forwarded.isAccepted();
    }
    case QEvent::InputMethodQuery: {
        auto *queryEvent = static_cast<QInputMethodQueryEvent *>(event);
        QInputMethodQueryEvent forwarded(queryEvent->queries());
        QCoreApplication::sendEvent(m_scene.get(), &forwarded);
        const Qt::InputMethodQuery values[] = {
            Qt::ImEnabled, Qt::ImCursorRectangle, Qt::ImFont, Qt::ImCursorPosition,
            Qt::ImSurroundingText, Qt::ImCurrentSelection, Qt::ImAnchorPosition,
            Qt::ImHints, Qt::ImPreferredLanguage, Qt::ImAbsolutePosition,
            Qt::ImTextBeforeCursor, Qt::ImTextAfterCursor
        };
        for (Qt::InputMethodQuery query : values)
            if (queryEvent->queries().testFlag(query))
                queryEvent->setValue(query, forwarded.value(query));
        queryEvent->accept();
        return true;
    }
    case QEvent::FocusIn:
    case QEvent::FocusOut: {
        const auto *source = static_cast<QFocusEvent *>(event);
        QFocusEvent forwarded(source->type(), source->reason());
        QCoreApplication::sendEvent(m_scene.get(), &forwarded);
        return forwarded.isAccepted();
    }
    case QEvent::UngrabMouse:
        if (m_isResizing) {
            endInteractiveResize();
            return true;
        }
        return false;
    default:
        return false;
    }
}

void TranslatorWindow::forwardNativePointer(QEvent::Type type, const QPointF &local,
                                            Qt::MouseButton button, Qt::MouseButtons buttons)
{
    if (!m_scene || m_isResizing) return;
    const QPointF global = QCursor::pos();
    QMouseEvent forwarded(type, local, local, global, button, buttons,
                          QGuiApplication::keyboardModifiers());
    QCoreApplication::sendEvent(m_scene.get(), &forwarded);
}

Qt::Edges TranslatorWindow::resizeEdgesAt(const QPointF &position)
{
    Q_UNUSED(position)
    return m_currentMode == "card" && m_resizeSession ? m_resizeSession->hitTest(this) : Qt::Edges{};
}

void TranslatorWindow::updateResizeCursor(const QPointF &position)
{
    const Qt::Edges edges = resizeEdgesAt(position);
    if (edges == (Qt::LeftEdge | Qt::TopEdge) || edges == (Qt::RightEdge | Qt::BottomEdge))
        setCursor(Qt::SizeFDiagCursor);
    else if (edges == (Qt::RightEdge | Qt::TopEdge) || edges == (Qt::LeftEdge | Qt::BottomEdge))
        setCursor(Qt::SizeBDiagCursor);
    else if (edges.testFlag(Qt::LeftEdge) || edges.testFlag(Qt::RightEdge))
        setCursor(Qt::SizeHorCursor);
    else if (edges.testFlag(Qt::TopEdge) || edges.testFlag(Qt::BottomEdge))
        setCursor(Qt::SizeVerCursor);
    else
        unsetCursor();
}

bool TranslatorWindow::event(QEvent *event)
{
    if (forwardInputEvent(event)) return true;
    return QWindow::event(event);
}

void TranslatorWindow::exposeEvent(QExposeEvent *event)
{
    QWindow::exposeEvent(event);
    scheduleRender();
}

void TranslatorWindow::resizeEvent(QResizeEvent *event)
{
    QWindow::resizeEvent(event);
    if (!m_presenting && !m_isResizing && m_sizeAnimation->state() != QAbstractAnimation::Running)
        scheduleRender();
}
