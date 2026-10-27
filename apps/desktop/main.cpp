#include "notebook_store.h"
#include "page_editor_adapter.h"
#include "page_test_adapter.h"

#include <QDirIterator>
#include <QFont>
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

    // Interface text uses the platform rasterizer (Core Text, DirectWrite,
    // FreeType), crisper at 11–14 px than distance fields. Vertical-only hinting
    // keeps baselines sharp without widening lines. Paper text opts back into
    // Qt rendering with no hinting so it measures the same everywhere.
    QQuickWindow::setTextRenderType(QQuickWindow::NativeTextRendering);
    QFont uiFont = QGuiApplication::font();
    uiFont.setHintingPreference(QFont::PreferVerticalHinting);
    QGuiApplication::setFont(uiFont);

    // Our components draw themselves from Theme; Basic is the only built-in
    // style whose colors follow the palette (native styles ignore it).
    QQuickStyle::setStyle("Basic");

    NotebookStore store;
    PageEditorAdapter pageEditorAdapter(&store);
    PageTestAdapter pageTestAdapter(&store);
    const bool editorProbe = app.arguments().contains("--editor-probe");
    const bool editorModelDemo = app.arguments().contains("--editor-model-demo");
    pageEditorAdapter.setEnabled(editorModelDemo);
    pageTestAdapter.setDemoEnabled(!editorProbe && !editorModelDemo && app.arguments().contains("--page-model-demo"));
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("notebookStore", &store);
    engine.rootContext()->setContextProperty("pageTestAdapter", &pageTestAdapter);
    engine.rootContext()->setContextProperty("pageEditorAdapter", &pageEditorAdapter);
    engine.rootContext()->setContextProperty("startWithEditorProbe", editorProbe);
    engine.rootContext()->setContextProperty("startWithEditorModelDemo", editorModelDemo);
    const bool indexGallery = app.arguments().contains("--gallery-index");
    const bool textCardGallery = app.arguments().contains("--gallery-text-card");
    const bool reviewGallery = app.arguments().contains("--gallery-review");
    const bool galleryRequested = app.arguments().contains("--gallery") || indexGallery || textCardGallery || reviewGallery;
    engine.rootContext()->setContextProperty("startWithGallery", galleryRequested);
    engine.rootContext()->setContextProperty("startWithIndexGallery", indexGallery);
    engine.rootContext()->setContextProperty("startWithTextCardGallery", textCardGallery);
    engine.rootContext()->setContextProperty("startWithReviewGallery", reviewGallery);
    engine.loadFromModule("MoreThanANote", "Main");
    if (engine.rootObjects().isEmpty()) return 1;
    const QByteArray capturePath = qgetenv("MTN_CAPTURE");
    if (!capturePath.isEmpty()) {
        const bool galleryCapture = galleryRequested;
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
