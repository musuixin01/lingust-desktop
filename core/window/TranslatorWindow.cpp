#include "TranslatorWindow.h"

#include <QCoreApplication>
#include <QCursor>
#include <QExposeEvent>
#include <QFocusEvent>
#include <QGuiApplication>
#include <QHoverEvent>
#include <QInputMethod>
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

namespace {
class TranslatorRenderControl final : public QQuickRenderControl
{
public:
    explicit TranslatorRenderControl(QWindow *host)
        : m_host(host)
    {
    }

    QWindow *renderWindow(QPoint *offset) override
    {
        if (offset) *offset = QPoint();
        return m_host;
    }

private:
    QPointer<QWindow> m_host;
};
}

TranslatorWindow::TranslatorWindow(QWindow *parent)
    : QWindow(parent)
    , m_renderControl(std::make_unique<TranslatorRenderControl>(this))
    , m_scene(std::make_unique<QQuickWindow>(m_renderControl.get()))
    , m_sizeAnimation(new QVariantAnimation(this))
{
    m_scene->setColor(Qt::transparent);
    connect(m_scene.get(), &QQuickWindow::focusObjectChanged,
            this, [this](QObject *object) {
        emit focusObjectChanged(object);
        if (isActive() && QGuiApplication::inputMethod())
            QGuiApplication::inputMethod()->update(Qt::ImQueryAll);
    });
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
        target.moveLeft(qRound(m_animationOrigin.center().x() - target.width() / 2.0));
        renderAndPresent(target);
    });
    setupWindow();
}

QObject *TranslatorWindow::focusObject() const
{
    return m_scene && m_scene->focusObject() ? m_scene->focusObject()
                                              : QWindow::focusObject();
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
    // QQuickRenderControl has no native focus window. Establish the initial
    // focus scope so pointer-selected TextFields can become the active item.
    item->forceActiveFocus(Qt::OtherFocusReason);
    scheduleRender();
}

void TranslatorWindow::scheduleRender()
{
    if (m_minimized || windowState() == Qt::WindowMinimized
        || m_renderQueued || !m_resizeSession || !m_rootItem) return;
    m_renderQueued = true;
    QTimer::singleShot(0, this, [this] {
        m_renderQueued = false;
        if (!m_minimized && windowState() != Qt::WindowMinimized
            && !m_rendering && m_resizeSession)
            renderAndPresent(m_resizeSession->nativeGeometry(this));
    });
}

void TranslatorWindow::requestSurfaceFrame()
{
    scheduleRender();
}

void TranslatorWindow::refreshNativeSession()
{
    if (m_resizeSession) m_resizeSession->initialize(this);
}

bool TranslatorWindow::renderAndPresent(const QRect &nativeGeometry)
{
    if (m_minimized || windowState() == Qt::WindowMinimized
        || m_rendering || !m_resizeSession || !m_rootItem || !nativeGeometry.isValid()) return false;
    m_rendering = true;
    if (m_nativeFrameGeometry != nativeGeometry) {
        m_nativeFrameGeometry = nativeGeometry;
        emit nativeFrameGeometryChanged();
    }
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
    surface.cornerRadius = qMin(nativeGeometry.height() / 2, qRound(32 * scale));
    surface.color = m_rootItem->property("shellColor").value<QColor>();
    surface.opacity = m_rootItem->property("shellOpacity").toReal();
    surface.auroraOpacity = m_rootItem->property("auroraOpacity").toReal();
    surface.auroraBloom = m_rootItem->property("auroraBloom").toReal();
    surface.auroraPhase = m_rootItem->property("auroraPhase").toReal();
    surface.resizeEdges = int(m_resizeHoverEdges);
    surface.resizing = m_isResizing;
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
    QRect finalGeometry;
    if (m_resizeSession) {
        finalGeometry = m_resizeSession->targetGeometry(this);
        if (finalGeometry.isValid() && finalGeometry != m_resizeSession->nativeGeometry(this))
            renderAndPresent(finalGeometry);
        if (!finalGeometry.isValid()) finalGeometry = m_resizeSession->nativeGeometry(this);
        if (finalGeometry.isValid()) {
            const qreal scale = m_resizeSession->scaleFactor(this);
            const int logicalWidth = qRound(finalGeometry.width() / scale);
            const int logicalHeight = qRound(finalGeometry.height() / scale);
            if (m_currentMode == "pill") {
                setPillWidth(logicalWidth);
                setPillHeight(logicalHeight);
            } else {
                setCardWidth(logicalWidth);
                setCardHeight(logicalHeight);
            }
        }
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
    if (m_currentMode == "card" && m_sizeAnimation->state() != QAbstractAnimation::Running) return;
    const int targetWidth = qMax(m_cardWidth, DefaultCardWidth);
    m_cardWidth = targetWidth;
    // Opening without a result starts as the compact reference card. The QML
    // content measurement grows it after rich translation data is rendered.
    m_cardHeight = DefaultCardHeight;
    setCurrentMode("card");
    animateSize(targetWidth, m_cardHeight, 200);
}

void TranslatorWindow::collapseToPill()
{
    if (m_currentMode == "pill" && m_sizeAnimation->state() != QAbstractAnimation::Running) return;
    const int targetWidth = qMax(m_pillWidth, 160);
    const int targetHeight = qBound(38, m_pillHeight, 72);
    setCurrentMode("pill");
    animateSize(targetWidth, targetHeight, 165);
}

void TranslatorWindow::minimizeToTaskbar()
{
    if (m_minimized || windowState() == Qt::WindowMinimized) return;
    m_sizeAnimation->stop();
    endInteractiveResize();
    m_minimized = true;
    m_renderQueued = false;
    m_resizeHoverEdges = {};
    unsetCursor();
    emit resizeHoverEdgesChanged();
    if (!m_resizeSession || !m_resizeSession->minimize(this))
        setWindowState(Qt::WindowMinimized);
}

void TranslatorWindow::restoreFromTaskbar()
{
    m_minimized = false;
    setWindowState(Qt::WindowNoState);
    showNormal();
    raise();
    requestActivate();
    scheduleRender();
}

void TranslatorWindow::resetCardToDefault()
{
    setCardWidth(DefaultCardWidth);
    setCardHeight(DefaultCardHeight);
    if (m_currentMode == "card")
        animateSize(DefaultCardWidth, DefaultCardHeight, 180);
}

void TranslatorWindow::adjustSizeToContent(int contentWidth, int contentHeight)
{
    if (m_currentMode != "card" || m_isResizing || contentWidth <= 0 || contentHeight <= 0) return;
    const int targetWidth = qBound(DefaultCardWidth, contentWidth, 350);
    const int targetHeight = qBound(DefaultCardHeight, contentHeight, 500);
    const int currentWidth = width();
    const int currentHeight = height();
    setCardWidth(targetWidth);
    setCardHeight(targetHeight);
    if (qAbs(currentWidth - targetWidth) >= 6 || qAbs(currentHeight - targetHeight) >= 6)
        animateSize(targetWidth, targetHeight, 180);
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
        if (source->type() == QEvent::MouseButtonPress && source->button() == Qt::LeftButton)
            prepareKeyboardFocus(local);
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
    if (type == QEvent::Leave) {
        if (m_resizeHoverEdges) {
            m_resizeHoverEdges = {};
            unsetCursor();
            emit resizeHoverEdgesChanged();
            scheduleRender();
        }
        if (m_rootItem)
            QMetaObject::invokeMethod(m_rootItem, "handlePointerLeave", Qt::DirectConnection);
        QMouseEvent outsideMove(QEvent::MouseMove, QPointF(-10000, -10000),
                                QPointF(-10000, -10000), QCursor::pos(),
                                Qt::NoButton, Qt::NoButton, QGuiApplication::keyboardModifiers());
        QCoreApplication::sendEvent(m_scene.get(), &outsideMove);
        QEvent leaveEvent(QEvent::Leave);
        QCoreApplication::sendEvent(m_scene.get(), &leaveEvent);
        return;
    }
    if (type == QEvent::MouseMove)
        updateResizeCursor(local);
    if (type == QEvent::MouseButtonPress && button == Qt::LeftButton)
        prepareKeyboardFocus(local);
    const QPointF global = QCursor::pos();
    QMouseEvent forwarded(type, local, local, global, button, buttons,
                          QGuiApplication::keyboardModifiers());
    QCoreApplication::sendEvent(m_scene.get(), &forwarded);
    // QML hover handlers may update while the offscreen scene receives the
    // synthetic move. Apply the native position last so edge reveal state is
    // deterministic for the visible layered window.
    if (type == QEvent::MouseMove && m_rootItem)
        QMetaObject::invokeMethod(m_rootItem, "handlePointerMove", Qt::DirectConnection,
                                  Q_ARG(QVariant, local.x()), Q_ARG(QVariant, local.y()));
}

void TranslatorWindow::prepareKeyboardFocus(const QPointF &local)
{
    if (!m_rootItem) return;
    // The visible host owns the native focus while the QML scene is rendered
    // offscreen. Re-assert activation on the first content click so key and IME
    // events can be forwarded to the TextField selected below.
    requestActivate();
    QMetaObject::invokeMethod(m_rootItem, "prepareKeyboardFocus", Qt::DirectConnection,
                              Q_ARG(QVariant, local.x()), Q_ARG(QVariant, local.y()));
    // The platform input context queries QGuiApplication::focusObject(). The
    // visible layered host now exposes the offscreen scene's focused TextInput;
    // refresh all query values so IME preedit text and its candidate window use
    // the correct editor and cursor rectangle immediately after the click.
    if (QGuiApplication::inputMethod())
        QGuiApplication::inputMethod()->update(Qt::ImQueryAll);
}

Qt::Edges TranslatorWindow::resizeEdgesAt(const QPointF &position)
{
    Q_UNUSED(position)
    return m_resizeSession ? m_resizeSession->hitTest(this) : Qt::Edges{};
}

void TranslatorWindow::updateResizeCursor(const QPointF &position)
{
    const Qt::Edges edges = resizeEdgesAt(position);
    if (m_resizeHoverEdges != edges) {
        m_resizeHoverEdges = edges;
        emit resizeHoverEdgesChanged();
        scheduleRender();
    }
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
    if (event->type() == QEvent::WindowStateChange) {
        const bool isNowMinimized = windowState() == Qt::WindowMinimized;
        if (!isNowMinimized && m_minimized) {
            m_minimized = false;
            scheduleRender();
        } else if (isNowMinimized) {
            m_minimized = true;
        }
    }
    if (forwardInputEvent(event)) return true;
    return QWindow::event(event);
}

void TranslatorWindow::exposeEvent(QExposeEvent *event)
{
    QWindow::exposeEvent(event);
    if (isExposed() && m_resizeSession) m_resizeSession->initialize(this);
    scheduleRender();
}

void TranslatorWindow::resizeEvent(QResizeEvent *event)
{
    QWindow::resizeEvent(event);
    if (!m_presenting && !m_isResizing && m_sizeAnimation->state() != QAbstractAnimation::Running)
        scheduleRender();
}
