#include "notebook_store.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName("more-than-a-note");
    QCoreApplication::setApplicationName("more-than-a-note");

    NotebookStore store;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("notebookStore", &store);
    engine.loadFromModule("MoreThanANote", "Main");
    if (engine.rootObjects().isEmpty()) return 1;
    return app.exec();
}
