#include "notebook_store.h"
#include "page_editor_adapter.h"
#include "page_test_adapter.h"

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
#include <QtQuickTest/quicktest.h>

#include <memory>

class WorkspaceKeyboardDriver final : public QObject {
    Q_OBJECT
public:
    Q_INVOKABLE void keyClick(QWindow* window, int key, int modifiers = 0) {
        window->requestActivate();
        QCoreApplication::processEvents();
        QTest::keyClick(window, static_cast<Qt::Key>(key), Qt::KeyboardModifiers(modifiers));
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
    Q_INVOKABLE bool capture(QQuickWindow* window, const QString& name) {
        const QByteArray directory = qgetenv("MTN_E2_CAPTURE_DIR");
        if (directory.isEmpty()) return true;
        const QString outputDirectory = QString::fromLocal8Bit(directory);
        QDir().mkpath(outputDirectory);
        return window->grabWindow().save(outputDirectory + "/" + name);
    }
    Q_INVOKABLE bool isOffscreen() const {
        return QGuiApplication::platformName() == "offscreen";
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

class WorkspaceTestSetup final : public QObject {
    Q_OBJECT

public:
    WorkspaceTestSetup() {
        qputenv("XDG_DATA_HOME", temporaryData_.path().toUtf8());
        qputenv("XDG_CONFIG_HOME", temporaryData_.path().toUtf8());
    }

public slots:
    void finish() { pageEditorAdapter_.reset(); pageTestAdapter_.reset(); store_.reset(); }
    void applicationAvailable() {
        QCoreApplication::setOrganizationName("more-than-a-note-tests");
        QCoreApplication::setApplicationName("workspace-quick-tests");
        QQuickStyle::setStyle("Basic");
        store_ = std::make_unique<NotebookStore>();
        if (!store_->notebooks().isEmpty()) qFatal("E2 test profile is not isolated");
        connect(QCoreApplication::instance(), &QCoreApplication::aboutToQuit,
                this, [this] { pageEditorAdapter_.reset(); pageTestAdapter_.reset(); store_.reset(); });
        store_->createNotebook("Caderno E2");
        store_->addSection("Aulas");
        store_->addPage("Página 1");
        store_->addPage("Página com um título bem longo para testar navegação e anúncio");
        store_->addSection("Seção sem páginas");
        store_->closeNotebook();
        store_->createNotebook("Caderno vazio");
        store_->closeNotebook();
        pageTestAdapter_ = std::make_unique<PageTestAdapter>(store_.get());
        pageEditorAdapter_ = std::make_unique<PageEditorAdapter>(store_.get());
    }

    void qmlEngineAvailable(QQmlEngine* engine) {
        engine->rootContext()->setContextProperty("notebookStore", store_.get());
        engine->rootContext()->setContextProperty("pageTestAdapter", pageTestAdapter_.get());
        engine->rootContext()->setContextProperty("pageEditorAdapter", pageEditorAdapter_.get());
        engine->rootContext()->setContextProperty("startWithEditorProbe", false);
        engine->rootContext()->setContextProperty("startWithEditorModelDemo", false);
        engine->rootContext()->setContextProperty("startWithGallery", false);
        engine->rootContext()->setContextProperty("startWithIndexGallery", false);
        engine->rootContext()->setContextProperty("keyboardDriver", &keyboardDriver_);
        engine->rootContext()->setContextProperty("testSetup", this);
    }

private:
    QTemporaryDir temporaryData_;
    std::unique_ptr<NotebookStore> store_;
    std::unique_ptr<PageTestAdapter> pageTestAdapter_;
    std::unique_ptr<PageEditorAdapter> pageEditorAdapter_;
    WorkspaceKeyboardDriver keyboardDriver_;
};

QUICK_TEST_MAIN_WITH_SETUP(workspace_quick_tests, WorkspaceTestSetup)

#include "workspace_quick_tests.moc"
