#include "notebook_store.h"
#include "page_editor_adapter.h"

#include <QDir>
#include <QDirIterator>
#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QImage>
#include <QPainter>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickItemGrabResult>
#include <QQuickStyle>
#include <QQuickWindow>

#include <cstdio>
#include <cstring>
#include <memory>

namespace {
FILE* diagnosticLog = nullptr;

// Where the scripted gallery capture (MTN_CAPTURE_DIR) saves its images.
class CaptureSink final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString directory READ directory CONSTANT)
public:
    explicit CaptureSink(QString directory) : directory_(std::move(directory)) {
        QDir().mkpath(directory_);
    }
    QString directory() const { return directory_; }
    // Saves an Item.grabToImage() result over the window background, since a
    // section has no background of its own.
    Q_INVOKABLE bool save(QQuickItemGrabResult* result, const QString& name, const QColor& background) const {
        if (!result) return false;
        QImage section = result->image();
        // The software renderer labels some grabs RGB32 although the bytes
        // are premultiplied ARGB with empty areas left at zero.
        if (section.format() == QImage::Format_RGB32)
            section.reinterpretAsFormat(QImage::Format_ARGB32_Premultiplied);
        QImage image(section.size(), QImage::Format_ARGB32_Premultiplied);
        image.setDevicePixelRatio(section.devicePixelRatio());
        image.fill(background);
        QPainter(&image).drawImage(0, 0, section);
        return image.save(directory_ + "/" + name + ".png");
    }
private:
    QString directory_;
};

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

    useIsolatedProfileSettings();
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

    // The only command-line options are --gallery[=<section>] and --scale=;
    // the environment variables are listed in BUILDING.md.
    bool gallery = false;
    QString gallerySection;
    for (const QString& argument : app.arguments()) {
        if (argument == "--gallery") gallery = true;
        if (argument.startsWith("--gallery=")) {
            gallery = true;
            gallerySection = argument.mid(10);
        }
    }
    const QString captureDirectory = qEnvironmentVariable("MTN_CAPTURE_DIR");
    std::unique_ptr<CaptureSink> capture;
    if (gallery && !captureDirectory.isEmpty())
        capture = std::make_unique<CaptureSink>(captureDirectory + "/gallery");

    NotebookStore store;
    PageEditorAdapter pageEditorAdapter(&store);
    pageEditorAdapter.setEnabled(true);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("notebookStore", &store);
    engine.rootContext()->setContextProperty("pageEditorAdapter", &pageEditorAdapter);
    engine.rootContext()->setContextProperty("startWithGallery", gallery);
    engine.rootContext()->setContextProperty("gallerySection", gallerySection);
    engine.rootContext()->setContextProperty("galleryCapture", static_cast<QObject*>(capture.get()));
    engine.rootContext()->setContextProperty("isolatedProfile", !qEnvironmentVariableIsEmpty("MTN_PROFILE_DIR"));
    engine.loadFromModule("MoreThanANote", "Main");
    if (engine.rootObjects().isEmpty()) return 1;
    return app.exec();
}

#include "main.moc"
