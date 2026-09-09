#pragma once

#include <QImage>
#include <QPointer>
#include <QRect>
#include <QWindow>
#include <memory>

#include "WindowResizeSession.h"

class QExposeEvent;
class QInputMethodEvent;
class QQuickItem;
class QQuickRenderControl;
class QQuickWindow;
class QResizeEvent;
class QTimer;
class QVariantAnimation;

class TranslatorWindow : public QWindow
{
    Q_OBJECT
    Q_PROPERTY(bool usesNativeSurface READ usesNativeSurface CONSTANT)
    Q_PROPERTY(QString currentMode READ currentMode WRITE setCurrentMode NOTIFY currentModeChanged)
    Q_PROPERTY(bool isDragging READ isDragging NOTIFY isDraggingChanged)
    Q_PROPERTY(bool isResizing READ isResizing NOTIFY isResizingChanged)
    Q_PROPERTY(int pillWidth READ pillWidth WRITE setPillWidth NOTIFY pillWidthChanged)
    Q_PROPERTY(int pillHeight READ pillHeight WRITE setPillHeight NOTIFY pillHeightChanged)
    Q_PROPERTY(int cardWidth READ cardWidth WRITE setCardWidth NOTIFY cardWidthChanged)
    Q_PROPERTY(int cardHeight READ cardHeight WRITE setCardHeight NOTIFY cardHeightChanged)

public:
    bool usesNativeSurface() const { return true; }
    explicit TranslatorWindow(QWindow *parent = nullptr);
    ~TranslatorWindow() override;

    QString currentMode() const;
    void setCurrentMode(const QString &mode);
    bool isDragging() const;
    bool isResizing() const;
    int pillWidth() const;
    void setPillWidth(int width);
    int pillHeight() const;
    void setPillHeight(int height);
    int cardWidth() const;
    void setCardWidth(int width);
    int cardHeight() const;
    void setCardHeight(int height);

    void setResizeSession(std::unique_ptr<WindowResizeSession> session);
    Q_INVOKABLE void beginInteractiveResize(int edges);
    Q_INVOKABLE void endInteractiveResize();
    Q_INVOKABLE void toggleMode();
    Q_INVOKABLE void expandToCard();
    Q_INVOKABLE void collapseToPill();
    Q_INVOKABLE void minimizeToTaskbar();
    Q_INVOKABLE void setContentItem(QQuickItem *item);
    Q_INVOKABLE void animateSize(int width, int height, int duration = 250);
    Q_INVOKABLE void adjustHeightToContent(int contentHeight);

signals:
    void currentModeChanged();
    void isDraggingChanged();
    void isResizingChanged();
    void pillWidthChanged();
    void pillHeightChanged();
    void cardWidthChanged();
    void cardHeightChanged();

protected:
    bool event(QEvent *event) override;
    void exposeEvent(QExposeEvent *event) override;
    void resizeEvent(QResizeEvent *event) override;

private:
    void setupWindow();
    void centerWindow();
    void scheduleRender();
    bool renderAndPresent(const QRect &nativeGeometry);
    void applyInteractiveResize();
    bool forwardInputEvent(QEvent *event);
    void forwardNativePointer(QEvent::Type type, const QPointF &local,
                              Qt::MouseButton button, Qt::MouseButtons buttons);
    Qt::Edges resizeEdgesAt(const QPointF &position);
    void updateResizeCursor(const QPointF &position);

    QString m_currentMode = "pill";
    bool m_isDragging = false;
    bool m_isResizing = false;
    int m_pillWidth = 380;
    int m_pillHeight = 46;
    int m_cardWidth = 380;
    int m_cardHeight = 490;
    std::unique_ptr<QQuickRenderControl> m_renderControl;
    std::unique_ptr<QQuickWindow> m_scene;
    QPointer<QQuickItem> m_rootItem;
    QImage m_frame;
    std::unique_ptr<WindowResizeSession> m_resizeSession;
    QVariantAnimation *m_sizeAnimation = nullptr;
    bool m_renderQueued = false;
    bool m_rendering = false;
    bool m_presenting = false;
    Qt::Edges m_resizeEdges;
    QRect m_animationOrigin;
};
