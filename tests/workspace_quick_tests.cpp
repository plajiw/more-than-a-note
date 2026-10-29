#include "notebook_store.h"
#include "page_editor_adapter.h"

#include <QGuiApplication>
#include <QDir>
#include <QInputMethodEvent>
#include <QImage>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickStyle>
#include <QQuickItem>
#include <QQuickWindow>
#include <QTemporaryDir>
#include <QWindow>
#include <QWheelEvent>
#include <QtQuickTest/quicktest.h>

#include <memory>

// Sends real input events to a window and inspects its pixels.
class InputDriver final : public QObject {
    Q_OBJECT
public:
    Q_INVOKABLE void keyClick(QWindow* window, int key, int modifiers = 0) {
        window->requestActivate();
        QCoreApplication::processEvents();
        QTest::keyClick(window, static_cast<Qt::Key>(key), Qt::KeyboardModifiers(modifiers));
    }
    Q_INVOKABLE void keyPress(QWindow* window, int key, int modifiers = 0) {
        window->requestActivate();
        QCoreApplication::processEvents();
        QTest::keyPress(window, static_cast<Qt::Key>(key), Qt::KeyboardModifiers(modifiers));
    }
    Q_INVOKABLE void keyRelease(QWindow* window, int key, int modifiers = 0) {
        QTest::keyRelease(window, static_cast<Qt::Key>(key), Qt::KeyboardModifiers(modifiers));
    }
    Q_INVOKABLE void typeText(QWindow* window, const QString& text) {
        window->requestActivate();
        QCoreApplication::processEvents();
        for (QChar character : text)
            QTest::keyClick(window, character.toLatin1());
    }
    Q_INVOKABLE void preeditText(QWindow* window, const QString& text) {
        QInputMethodEvent event(text, {});
        QCoreApplication::sendEvent(window, &event);
    }
    Q_INVOKABLE void commitText(QWindow* window, const QString& text) {
        QInputMethodEvent event;
        event.setCommitString(text);
        QCoreApplication::sendEvent(window, &event);
    }
    Q_INVOKABLE void wheel(QWindow* window, QQuickItem* item, qreal x, qreal y,
                           int angle, int modifiers) {
        window->requestActivate();
        QCoreApplication::processEvents();
        const QPointF local = item->mapToScene(QPointF(x, y));
        const QPointF global = window->mapToGlobal(local.toPoint());
        QWheelEvent event(local, global, {}, QPoint(0, angle), Qt::NoButton,
                          Qt::KeyboardModifiers(modifiers), Qt::NoScrollPhase, false);
        QCoreApplication::sendEvent(window, &event);
    }
    // Scripted evidence: with MTN_CAPTURE_DIR set, every capture point saves
    // <dir>/tests/<name>; without it, captures are no-ops.
    Q_INVOKABLE bool capture(QQuickWindow* window, const QString& name) {
        const QString directory = qEnvironmentVariable("MTN_CAPTURE_DIR");
        if (directory.isEmpty()) return true;
        const QString outputDirectory = directory + "/tests";
        QDir().mkpath(outputDirectory);
        return window->grabWindow().save(outputDirectory + "/" + name);
    }
    Q_INVOKABLE bool isOffscreen() const {
        return QGuiApplication::platformName() == "offscreen";
    }
    Q_INVOKABLE void movePointer(QQuickWindow* window, qreal x, qreal y) {
        QTest::mouseMove(window, QPoint(qRound(x), qRound(y)));
        QCoreApplication::processEvents();
    }
    Q_INVOKABLE bool hasInkInRect(QQuickWindow* window, QQuickItem* item,
                                       qreal x, qreal y, qreal width, qreal height) {
        if (!window || !item) return false;
        const QImage image = window->grabWindow();
        const qreal ratio = image.devicePixelRatio();
        const QRectF sceneRect(item->mapToScene(QPointF(x, y)),
                               item->mapToScene(QPointF(x + width, y + height)));
        const QRect pixels = QRectF(sceneRect.topLeft() * ratio,
                                   sceneRect.bottomRight() * ratio).toAlignedRect()
                                 .intersected(image.rect());
        for (int py = pixels.top(); py <= pixels.bottom(); ++py) {
            for (int px = pixels.left(); px <= pixels.right(); ++px) {
                const QColor color = image.pixelColor(px, py);
                if (std::abs(color.red() - 155) <= 10 &&
                    std::abs(color.green() - 99) <= 10 &&
                    std::abs(color.blue() - 54) <= 10) return true;
            }
        }
        return false;
    }
};

// Each tst_*.qml file gets its own engine and, here, its own profile with
// the same sample notebooks, so files never depend on one another.
class WorkspaceTestSetup final : public QObject {
    Q_OBJECT

public slots:
    void applicationAvailable() {
        QCoreApplication::setOrganizationName("more-than-a-note-tests");
        QCoreApplication::setApplicationName("workspace-quick-tests");
        QQuickStyle::setStyle("Basic");
    }

    void qmlEngineAvailable(QQmlEngine* engine) {
        pageEditorAdapter_.reset();
        store_.reset();
        profile_ = std::make_unique<QTemporaryDir>();
        qputenv("MTN_PROFILE_DIR", profile_->path().toUtf8());
        useIsolatedProfileSettings();
        store_ = std::make_unique<NotebookStore>();
        if (!store_->notebooks().isEmpty()) qFatal("Test profile is not isolated");
        store_->createNotebook("Caderno de teste");
        store_->addSection("Aulas");
        store_->addPage("Página 1");
        store_->addPage("Página com um título bem longo para testar navegação e anúncio");
        store_->addSection("Seção sem páginas");
        store_->closeNotebook();
        store_->createNotebook("Caderno vazio");
        store_->closeNotebook();
        pageEditorAdapter_ = std::make_unique<PageEditorAdapter>(store_.get());
        pageEditorAdapter_->setEnabled(true);

        QQmlContext* context = engine->rootContext();
        context->setContextProperty("notebookStore", store_.get());
        context->setContextProperty("pageEditorAdapter", pageEditorAdapter_.get());
        context->setContextProperty("startWithGallery", false);
        context->setContextProperty("gallerySection", QString());
        context->setContextProperty("galleryCapture", static_cast<QObject*>(nullptr));
        context->setContextProperty("isolatedProfile", true);
        context->setContextProperty("inputDriver", &inputDriver_);
    }

    void cleanupTestCase() {
        pageEditorAdapter_.reset();
        store_.reset();
        profile_.reset();
    }

private:
    std::unique_ptr<QTemporaryDir> profile_;
    std::unique_ptr<NotebookStore> store_;
    std::unique_ptr<PageEditorAdapter> pageEditorAdapter_;
    InputDriver inputDriver_;
};

QUICK_TEST_MAIN_WITH_SETUP(workspace_quick_tests, WorkspaceTestSetup)

#include "workspace_quick_tests.moc"
