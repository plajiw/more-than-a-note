#include "notebook_store.h"
#include "page_test_adapter.h"

#include <QGuiApplication>
#include <QDir>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickStyle>
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
    Q_INVOKABLE bool capture(QQuickWindow* window, const QString& name) {
        const QByteArray directory = qgetenv("MTN_E2_CAPTURE_DIR");
        if (directory.isEmpty()) return true;
        const QString outputDirectory = QString::fromLocal8Bit(directory);
        QDir().mkpath(outputDirectory);
        return window->grabWindow().save(outputDirectory + "/" + name);
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
    void finish() { pageTestAdapter_.reset(); store_.reset(); }
    void applicationAvailable() {
        QCoreApplication::setOrganizationName("more-than-a-note-tests");
        QCoreApplication::setApplicationName("workspace-quick-tests");
        QQuickStyle::setStyle("Basic");
        store_ = std::make_unique<NotebookStore>();
        if (!store_->notebooks().isEmpty()) qFatal("E2 test profile is not isolated");
        connect(QCoreApplication::instance(), &QCoreApplication::aboutToQuit,
                this, [this] { pageTestAdapter_.reset(); store_.reset(); });
        store_->createNotebook("Caderno E2");
        store_->addSection("Aulas");
        store_->addPage("Página 1");
        store_->addPage("Página com um título bem longo para testar navegação e anúncio");
        store_->addSection("Seção sem páginas");
        store_->closeNotebook();
        store_->createNotebook("Caderno vazio");
        store_->closeNotebook();
        pageTestAdapter_ = std::make_unique<PageTestAdapter>(store_.get());
    }

    void qmlEngineAvailable(QQmlEngine* engine) {
        engine->rootContext()->setContextProperty("notebookStore", store_.get());
        engine->rootContext()->setContextProperty("pageTestAdapter", pageTestAdapter_.get());
        engine->rootContext()->setContextProperty("startWithGallery", false);
        engine->rootContext()->setContextProperty("startWithIndexGallery", false);
        engine->rootContext()->setContextProperty("keyboardDriver", &keyboardDriver_);
        engine->rootContext()->setContextProperty("testSetup", this);
    }

private:
    QTemporaryDir temporaryData_;
    std::unique_ptr<NotebookStore> store_;
    std::unique_ptr<PageTestAdapter> pageTestAdapter_;
    WorkspaceKeyboardDriver keyboardDriver_;
};

QUICK_TEST_MAIN_WITH_SETUP(workspace_quick_tests, WorkspaceTestSetup)

#include "workspace_quick_tests.moc"
