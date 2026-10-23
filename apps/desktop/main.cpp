#include "notebook_store.h"

#include <QDirIterator>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include <cstring>

int main(int argc, char* argv[]) {
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
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("notebookStore", &store);
    engine.rootContext()->setContextProperty("startWithGallery", app.arguments().contains("--gallery"));
    engine.loadFromModule("MoreThanANote", "Main");
    if (engine.rootObjects().isEmpty()) return 1;
    return app.exec();
}
