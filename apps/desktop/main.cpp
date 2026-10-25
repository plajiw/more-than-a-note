#include "notebook_store.h"
#include "page_test_adapter.h"

#include <QDirIterator>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>

#include <cstring>
#include <cstdio>

namespace {
FILE* diagnosticLog = nullptr;
void writeQtMessage(QtMsgType, const QMessageLogContext&, const QString& message) {
    if (!diagnosticLog) return;
    std::fprintf(diagnosticLog, "%s\n", message.toUtf8().constData());
    std::fflush(diagnosticLog);
}
}

int main(int argc, char* argv[]) {
    const QByteArray logPath = qgetenv("MTN_QT_LOG");
    if (!logPath.isEmpty()) {
        diagnosticLog = std::fopen(logPath.constData(), "w");
        if (diagnosticLog) qInstallMessageHandler(writeQtMessage);
    }
    // --scale=1.25 simulates another display scale when evaluating the UI.
    for (int i = 1; i < argc; ++i)
        if (std::strncmp(argv[i], "--scale=", 8) == 0) qputenv("QT_SCALE_FACTOR", argv[i] + 8);

    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName("more-than-a-note");
    QCoreApplication::setApplicationName("more-than-a-note");

    // Bundled fonts are registered before QML loads so the first frame uses them.
    QDirIterator fonts(":/fonts", {"*.ttf"}, QDir::Files);
    while (fonts.hasNext()) QFontDatabase::addApplicationFont(fonts.next());

    // Our components draw themselves from Theme; Basic is the only built-in
    // style whose colors follow the palette (native styles ignore it).
    QQuickStyle::setStyle("Basic");

    NotebookStore store;
    PageTestAdapter pageTestAdapter(&store);
    const bool editorProbe = app.arguments().contains("--editor-probe");
    pageTestAdapter.setDemoEnabled(!editorProbe && app.arguments().contains("--page-model-demo"));
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("notebookStore", &store);
    engine.rootContext()->setContextProperty("pageTestAdapter", &pageTestAdapter);
    engine.rootContext()->setContextProperty("startWithEditorProbe", editorProbe);
    const bool indexGallery = app.arguments().contains("--gallery-index");
    engine.rootContext()->setContextProperty("startWithGallery", app.arguments().contains("--gallery") || indexGallery);
    engine.rootContext()->setContextProperty("startWithIndexGallery", indexGallery);
    engine.loadFromModule("MoreThanANote", "Main");
    if (engine.rootObjects().isEmpty()) return 1;
    const QByteArray capturePath = qgetenv("MTN_CAPTURE");
    if (!capturePath.isEmpty()) {
        const bool galleryCapture = app.arguments().contains("--gallery") || indexGallery;
        QTimer::singleShot(1500, &app, [capturePath, galleryCapture, &app]() {
            for (QWindow* window : QGuiApplication::topLevelWindows()) {
                if (!window->isVisible()) continue;
                if (galleryCapture && !window->title().contains("Galeria")) continue;
                if (auto* quick = qobject_cast<QQuickWindow*>(window)) {
                    if (quick->grabWindow().save(QString::fromLocal8Bit(capturePath))) break;
                }
            }
            app.quit();
        });
    }
    return app.exec();
}
